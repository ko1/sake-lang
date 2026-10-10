# frozen_string_literal: true

require_relative "typer"

module Sake
  # Typer2: Typer's lattice and built-in tables with another evaluation core (experiments/2026-10-09-typer2/).
  #
  # - Signatures first (local): a function is analyzed once per pattern of its parameters. A parameter the
  #   body only passes on (returns, hands to another function, puts in a Tuple) or only checks against a
  #   scalar type is a type variable α; the body's requirements on it (the checks) are recorded and checked
  #   at each call, with the call's argument substituted. When the body looks at α (narrowing, an operator,
  #   indexing, a field, a dispatch, showing it, storing it in a global cell), the analysis of the body is
  #   abandoned and the parameter is specialized: analyzed per argument type, as Typer does for all.
  # - Whole-program only where needed: fields, containers and the results of instantiations are cells; an
  #   instantiation is re-evaluated from a worklist when a cell it read changes, instead of re-walking the
  #   program in passes. Checks and results are collected at the end by replaying the recorded effects from
  #   main, substituting α per call; containers made inside a polymorphic body are cloned per call.
  class Typer2 < Typer
    Inst2 = Struct.new(:key, :fn, :args, :path, :reads, :effects, :poly, :round)
    MAIN = [:main].freeze
    SPECIALIZE = :typer2_specialize
    MAX_EVALUATIONS = 300_000
    # Built-ins whose scalar parameter is only checked (the result does not depend on it) may take α.
    SCALAR = %w[Integer Float String Symbol Rational Complex Time Regexp Boolean MatchData IO TCPServer Socket Mutex].freeze
    # Built-ins that give an argument back as it is: α passes through.
    ECHO = %w[Kernel.p Kernel.pp].freeze

    attr_reader :evaluations

    # The read set of one evaluation: registers the instantiation as a reader of each cell at its first read.
    class Reads < Hash
      def initialize(typer, key)
        super()
        compare_by_identity
        @typer = typer
        @key = key
      end

      def []=(cell, at)
        @typer.register_reader(cell, @key)
        super
      end
    end

    def run
      @readers = {}.compare_by_identity # cell => {inst key => true}
      @dirty = {}.compare_by_identity   # inst key => true: a cell it read changed; evaluated again when next called
      @cone = {}.compare_by_identity    # inst key => true: a dirty instantiation is below it; visited to reach it
      @callers = {}.compare_by_identity # inst key => {caller's key => true}
      @insts = {}.compare_by_identity
      @returns = {}.compare_by_identity
      @raises = {}.compare_by_identity
      @pattern = {}.compare_by_identity # fn => [:poly | :concrete] per parameter
      @inst_keys = {}
      @in_progress = {}.compare_by_identity
      @yield_depth = Hash.new(0).compare_by_identity
      @instantiated = {}.compare_by_identity
      @results = {}.compare_by_identity
      @checks = {}.compare_by_identity
      @check_ctx = {}.compare_by_identity
      @templates = {} # site id => key of the polymorphic instantiation whose body made it
      @clones = {}    # [kind, template id] => [[clone id, key, args]]
      @clone_ids = {}
      @site_ctx = {}  # site id => [node, ctx] (the label is made when shown)
      @sites_by_owner = {}.compare_by_identity
      @dead_sites = {}
      @fn_by_id = @program.functions.values.flat_map(&:values).to_h { [_1.__id__, _1] }
      @evaluations = 0
      @collecting = false
      @path = Path.new(nil, nil)
      @raised = [{}]
      @handled = []
      @round = 1
      @stats = Hash.new(0) # fresh / again (re-evaluations) / abandoned (attempts a look ended)
      ON_DIRTY[0] = ->(cell) { changed(cell) }
      begin
        main = @insts[MAIN] = Inst2.new(MAIN, nil, nil, @path, nil, [], false, nil)
        attempt(main)
        # Rounds from main, like Typer's passes, but only down the cone of the changed cells: an instantiation
        # whose reads changed is evaluated again when called; one above it only re-issues its calls (visit);
        # the rest just return their results. What nothing calls any more is never evaluated.
        loop do
          @round += 1
          before = @evaluations
          demand = catch(SPECIALIZE) do
            @dirty[MAIN] ? attempt(main) : visit(main)
            nil
          end
          specialize(demand) if demand # a variable whose owner is not on the stack: stale; its callers call again
          break if @evaluations == before || @evaluations > MAX_EVALUATIONS
        end
        collect
      ensure
        ON_DIRTY[0] = nil
        READS[0] = nil
        @cur_inst = nil
      end
      @passes = @evaluations
      @dead_functions = @program.functions.values.flat_map(&:values).reject { @instantiated[_1] || Sake.file_of(@program, _1.node) == Sake::PRELUDE }
      self
    end

    # --- worklist ---

    def register_reader(cell, key) = (@readers[cell] ||= {}.compare_by_identity)[key] = true

    # Evaluates main (or a dirty instantiation) at the top of a round; a look at a variable specializes its owner,
    # and this evaluation, cut short, is dirty again.
    def attempt(inst)
      @dirty.delete(inst.key)
      demand = catch(SPECIALIZE) do
        evaluate(inst)
        nil
      end
      return unless demand
      specialize(demand)
      mark_dirty(inst.key) if @insts[inst.key]
    end

    # Re-issues the calls of an instantiation whose own reads did not change, so that the dirty instantiations
    # below it are reached, and evaluated if still called. Nothing is recorded: its effects stand.
    def visit(inst)
      inst.round = @round
      @cone.delete(inst.key)
      outer = [@cur_inst, READS[0], @raised, @path, @visiting]
      @cur_inst = inst
      READS[0] = inst.reads
      @raised = [{}]
      @path = inst.path
      @visiting = true
      demand = catch(SPECIALIZE) do
        inst.effects.each do |e|
          next unless e[0] == :call
          fn = @fn_by_id[e[1][0]] or next
          call_user(fn, e[2], nil)
        end
        nil
      end
      if demand
        throw SPECIALIZE, demand unless demand[0].equal?(inst.key)
        specialize(demand) # its callers read its key: they are dirty and call again
      end
    ensure
      @cur_inst, READS[0], @raised, @path, @visiting = outer
    end

    # A cell changed: every instantiation that read it is dirty (a template's clones are refreshed).
    def changed(cell)
      refresh_clones(cell) if cell.is_a?(Site) || cell.is_a?(HashSite) || cell.is_a?(SetSite)
      (rs = @readers[cell]) && rs.each_key { |k| mark_dirty(k) }
    end

    def mark_dirty(key)
      return if @dirty[key]
      @dirty[key] = true
      cone_up(key)
    end

    def cone_up(key)
      @callers[key]&.each_key do |c|
        next if @cone[c]
        @cone[c] = true
        cone_up(c)
      end
    end

    def evaluate(inst)
      @evaluations += 1
      @stats[inst.reads ? :again : :fresh] += 1
      inst.round = @round
      @cone.delete(inst.key) # as visit does: a dirty one below it later marks the way up again from here
      inst.reads&.each_key { |cell| @readers[cell]&.delete(inst.key) }
      inst.reads = Reads.new(self, inst.key)
      inst.effects = []
      # The evaluation's own stacks: a fresh set, restored afterwards (an abandoned attempt unwinds through them).
      outer = [@cur_inst, READS[0], @path, @raised, @handled, @inst_stack, @jumps, @next_acc, @running_blocks, @init_frames, @init_fns, @visiting]
      @visiting = false
      @cur_inst = inst
      READS[0] = inst.reads
      @path = inst.path
      @raised = [{}]
      @handled = []
      @inst_stack = inst.fn ? [[inst.fn, inst.args]] : []
      @jumps = []
      @next_acc = []
      @running_blocks = []
      @init_frames = {}.compare_by_identity
      @init_fns = []
      @in_progress[inst.key] = true
      begin
        if inst.key.equal?(MAIN)
          ev(@ast.main.body, Env.new(nil, Frame.new(nil, [], nil)))
          @main_raised = @raised.last
        else
          r = run_body(inst.fn, inst.args, nil)
          raised = merge_into(@raises[inst.key] || {}, @raised.last)
          dirty(inst.key) unless raised == @raises[inst.key]
          @raises[inst.key] = raised
          ret = u(@returns[inst.key] || [], r)
          dirty(inst.key) unless ret.equal?(@returns[inst.key])
          @returns[inst.key] = ret
        end
      ensure
        @in_progress.delete(inst.key)
        @cur_inst, READS[0], @path, @raised, @handled, @inst_stack, @jumps, @next_acc, @running_blocks, @init_frames, @init_fns, @visiting = outer
      end
    end

    def inst_key2(fn, key_args)
      key = [fn.__id__, *key_args.map { _1 == :poly ? :poly : _1.__id__ }]
      @inst_keys[key] ||= key.freeze
    end

    def var_atom(key, i) = Typer.intern([[:var, key, i, nil].freeze].freeze)

    def call_user(fn, args, blk)
      mark_instantiated(fn)
      args = args.map { Typer.intern(_1) }
      if fn.yields # analyzed per call site, inside the caller's evaluation
        return unknown("recursive yield") if @yield_depth[fn] >= MAX_YIELD_DEPTH
        @yield_depth[fn] += 1
        (@inst_stack ||= []).push([fn, args])
        begin
          return run_body(fn, args, blk)
        ensure
          @inst_stack.pop
          @yield_depth[fn] -= 1
        end
      end
      pattern = (@pattern[fn] ||= initial_patterns[fn])
      loop do
        key_args = args.each_with_index.map { |a, i| pattern[i] == :poly && a != MISSING && !a.empty? ? :poly : a }
        key = inst_key2(fn, key_args)
        poly = key_args.include?(:poly)
        @cur_inst.effects.push([:call, key, args]) unless @visiting
        (@callers[key] ||= {}.compare_by_identity)[@cur_inst.key] = true # a visit may reach a fresh key (new pattern)
        if @in_progress[key]
          read(key)
          merge_raised(@raises[key] || {})
          return subst(@returns[key] || [], key, args)
        end
        inst = @insts[key]
        fresh = inst.nil?
        # A dirty instantiation is evaluated when called, once per round (as Typer evaluates it once per pass);
        # one above a dirty one re-issues its calls.
        if fresh || (@dirty[key] && inst.round != @round)
          inst ||= Inst2.new(key, fn, key_args.each_with_index.map { |a, i| a == :poly ? var_atom(key, i) : a }, @path, nil, [], poly, nil)
          @insts[key] = inst
          @dirty.delete(key)
          demand = catch(SPECIALIZE) do
            evaluate(inst)
            nil
          end
          if demand
            unless demand[0].equal?(key)
              # An outer instantiation's variable: its own attempt specializes it. This evaluation was cut
              # short: a fresh instantiation is dropped, an older one is dirty again.
              fresh ? @insts.delete(key) : mark_dirty(key)
              throw SPECIALIZE, demand
            end
            specialize(demand)
            next
          end
        elsif @cone[key] && inst.round != @round
          visit(inst)
        end
        read(key)
        merge_raised(@raises[key] || {})
        return subst(@returns[key] || [], key, args)
      end
    end

    # The local look first, for every function at once: a parameter the body visibly looks at (a condition, an
    # operator, indexing, a field, a dispatch subject, a built-in with a non-scalar parameter, shown, stored)
    # starts concrete; one handed straight to another function's parameter is concrete when that one is (to a
    # fixpoint); the others start as type variables, and a look the scan misses specializes them on demand.
    def initial_patterns
      @initial_patterns ||= begin
        scans = @ast.functions.keys.to_h { |fn| [fn, scan_looks(fn)] }
        if ENV["SAKE_TYPER2_NOPOLY"] # the worklist alone, for measuring
          scans.transform_values { |looked, _| Array.new(looked.size, :concrete) }
        else
          loop do
            changed = false
            scans.each do |_, (looked, flows)|
              flows.each do |i, (g, j)|
                next if looked[i] || !scans[g]&.first&.[](j)
                looked[i] = changed = true
              end
            end
            break unless changed
          end
          scans.transform_values { |looked, _| looked.map { _1 ? :concrete : :poly } }
        end
      end
    end

    # [looked per parameter, [[i, [callee, j]] for each parameter handed straight to a callee's parameter]].
    # `x = param` aliases are followed.
    def scan_looks(fn)
      body = @ast.functions.fetch(fn).body
      n = fn.params.size
      looked = Array.new(n, false)
      flows = []
      aliases = {}
      param_of = ->(slot) { slot < n ? slot : aliases[slot] }
      look = ->(node) { node.is_a?(LVarGet) && (p = param_of.(node.slot)) && (looked[p] = true) }
      walk = lambda do |node|
        case node
        when LVarSet
          if node.value.is_a?(LVarGet) && param_of.(node.value.slot) && node.slot >= n && !aliases.key?(node.slot)
            aliases[node.slot] = param_of.(node.value.slot)
          else
            (p = param_of.(node.slot)) && (looked[p] = true)
            walk.(node.value)
          end
        when If then look.(node.cond); walk.(node.cond); walk.(node.then_); walk.(node.else_)
        when While then look.(node.cond); walk.(node.cond); walk.(node.body)
        when And, Or then look.(node.left); walk.(node.left); walk.(node.right)
        when MatchP, IsNil, UnOp, ToS, MatchRecord, Splat then look.(node.value); walk.(node.value)
        when CaseIn then look.(node.subject); walk.(node.subject); node.clauses.each { walk.(_1[1]) }; walk.(node.else_) if node.else_
        when BinOp then look.(node.left); look.(node.right); walk.(node.left); walk.(node.right)
        when IndexGet, IndexSet, IndexUpdate
          look.(node.recv); look.(node.key)
          node.class.fields.each { |f| (v = node[f]).is_a?(Struct) && walk.(v) }
        when FieldGet, FieldSet
          look.(node.subject); look.(node.value) if node.is_a?(FieldSet)
          walk.(node.subject); walk.(node.value) if node.is_a?(FieldSet)
        when MultiWrite then look.(node.value); walk.(node.value); node.targets.each { walk.(_1) }
        when TIndex then look.(node.recv); walk.(node.recv); walk.(node.key)
        when CallDispatch, CallUnion then look.(node.args[0]); node.args.each { walk.(_1) }; walk.(node.block) if node.block
        when CallUser
          node.args.each_with_index do |a, j|
            if a.is_a?(LVarGet) && (p = param_of.(a.slot)) then flows << [p, [node.fn, j]] else walk.(a) end
          end
          walk.(node.block) if node.block
        when CallBuiltin
          node.args.each_with_index do |a, i|
            want = node.fn.param_type(i)
            look.(a) unless (want.is_a?(String) && SCALAR.include?(want)) || (want == "Any" && ECHO.include?(node.fn.full_name))
            walk.(a)
          end
          walk.(node.block) if node.block
        when Raise then node.args.each { look.(_1); walk.(_1) }
        else
          return unless node.is_a?(Struct) && node.class.respond_to?(:fields)
          node.class.fields.each do |f|
            v = node[f]
            if v.is_a?(Array) then v.flatten.each { walk.(_1) if _1.is_a?(Struct) }
            elsif v.is_a?(Struct) then walk.(v)
            end
          end
        end
      end
      walk.(body)
      [looked, flows]
    end

    # The body of key looked at its parameter i: from now on that parameter is concrete. The instantiation
    # is dropped with the containers its body made, and whoever called it calls again (with the new pattern).
    def specialize(demand)
      key, i = demand
      @stats[:abandoned] += 1
      fn = @fn_by_id.fetch(key[0])
      (@pattern[fn] ||= initial_patterns[fn])[i] = :concrete
      @insts.delete(key)
      @dirty.delete(key)
      @cone.delete(key)
      @callers.delete(key)
      # Its containers stay in the tables (instantiations made under the attempt may still name them) but
      # take no label number and are not reported.
      (@sites_by_owner.delete(key) || []).each { @dead_sites[_1] = true }
      (rs = @readers[key]) && rs.each_key { |k| mark_dirty(k) } # its callers: they call again with the new pattern
    end

    # --- site labels, given when shown: the sites of abandoned attempts do not take a number ---

    class LazyLabel
      def initialize(typer, id, node, extra)
        @typer = typer
        @id = id
        @node = node
        @extra = extra
      end

      def to_s = @typer.label_text(@id, @node, @extra)
      alias inspect to_s
      def +(other) = to_s + other
    end

    def next_site_id(node, ctx = nil)
      id = (@site_count = (@site_count || 0) + 1)
      @site_ctx[id] = [node, ctx]
      id
    end

    def site_label(id, node, extra = nil) = LazyLabel.new(self, id, node, extra)

    def label_text(id, node, extra)
      _, ctx = @site_ctx.fetch(id)
      return "L#{node.location.start_line}#{extra}" unless ctx
      order = (@ctx_order ||= {}.compare_by_identity)[node] ||= @site_ctx.select { |i, (nd, c)| nd.equal?(node) && c && !@dead_sites[i] }.keys.sort
      "L#{node.location.start_line}##{(order.index(id) || order.size) + 1}#{extra}"
    end

    # --- type variables ---

    HAS_VAR = {}.compare_by_identity

    def var?(a) = a.is_a?(Array) && a[0] == :var

    def has_var?(ty)
      return has_var_uncached?(ty) unless CANON_IDS.key?(ty) # a temporary list: not memoized (ids are reused)
      HAS_VAR.fetch(ty) { HAS_VAR[ty] = has_var_uncached?(ty) }
    end

    def has_var_uncached?(ty)
      ty.any? do |a|
        next false unless a.is_a?(Array)
        case a[0]
        when :var then true
        when :tuple then a[1].any? { has_var?(_1) }
        when :record then a[1].any? { has_var?(_1[1]) }
        when :range then has_var?(a[1])
        else false
        end
      end
    end

    # The body looked at a type variable: abandon this analysis; the parameter is specialized.
    def specialize!(*tys)
      tys.each do |ty|
        next if ty.nil? || !has_var?(ty)
        v = first_var(ty)
        throw SPECIALIZE, [v[1], v[2]]
      end
    end

    def first_var(ty)
      ty.each do |a|
        next unless a.is_a?(Array)
        case a[0]
        when :var then return a
        when :tuple then a[1].each { (v = has_var?(_1) && first_var(_1)) && (return v) }
        when :record then a[1].each { (v = has_var?(_1[1]) && first_var(_1[1])) && (return v) }
        when :range then return first_var(a[1]) if has_var?(a[1])
        end
      end
      nil
    end

    def guard(*tys) = specialize!(*tys) unless @collecting

    # ty with the variables of key replaced by args (restricted to the names a check left), and the
    # containers made by key's body replaced by their clones for these args.
    def subst(ty, key, args)
      return ty unless has_var?(ty) || has_template?(ty)
      u(*ty.map do |a|
        next one(a) unless a.is_a?(Array)
        case a[0]
        when :var
          next one(a) unless a[1].equal?(key)
          arg = args[a[2]]
          # The names a check left; as Typer's narrow_by_call, a type with an unknown atom is not narrowed.
          a[3] && !unknown?(arg) ? of_atoms(arg.select { |x| a[3].include?(atom_type_name(x)) }) : arg
        when :tuple then tuple(a[1].map { subst(_1, key, args) })
        when :record then record_type(a[1].map { |f, t| [f, subst(t, key, args)] })
        when :range then Typer.intern([[:range, subst(a[1], key, args)]].freeze)
        when :array, :hash, :set then @templates[a[1]]&.equal?(key) ? clone_site(a[0], a[1], key, args) : one(a)
        else one(a)
        end
      end)
    end

    def subst_all(ty, envs) = envs.reduce(ty) { |t, (k, a)| subst(t, k, a) }

    # --- templates: containers made inside a polymorphic body, one clone per call ---

    # A site made per instantiation (Typer's ctx) in a polymorphic body, or in a body only reached from one (its
    # arguments hold that body's templates), is a template of that polymorphic instantiation, cloned per call.
    # A site Typer shares across instantiations (the recursion guard: an argument holds a container this
    # function made) is shared here too.
    def site_id(node)
      id = super
      return id if @collecting || @cur_inst.nil? || @templates.key?(id) || !@site_ctx[id][1]
      owner = @cur_inst.poly ? @cur_inst.key : @cur_inst.args&.each { |a| (o = template_owner(a)) && (break o) }
      return id unless owner.is_a?(Array)
      @templates[id] = owner
      (@sites_by_owner[owner] ||= []) << id
      id
    end

    CONTAINERS = %i[array hash set].freeze

    def has_template?(ty) = !@templates.empty? && !template_owner(ty).nil?

    # The polymorphic instantiation whose body made a container in ty (inside Tuples, Records and Ranges too).
    def template_owner(ty)
      ty.each do |a|
        next unless a.is_a?(Array)
        case a[0]
        when *CONTAINERS then (o = @templates[a[1]]) && (return o)
        when :tuple then a[1].each { (o = template_owner(_1)) && (return o) }
        when :record then a[1].each { (o = template_owner(_1[1])) && (return o) }
        when :range then (o = template_owner(a[1])) && (return o)
        end
      end
      nil
    end

    # A template stored where other calls would see it (a field, a container of another owner): the owner is
    # specialized (its first polymorphic parameter), so that its body runs per call as Typer's does.
    def no_escape!(ty, into = nil)
      return if @collecting || @templates.empty? || ty.nil?
      owner = template_owner(ty) or return
      return if into && !into.empty? && into.all? { |a| a.is_a?(Array) && CONTAINERS.include?(a[0]) && @templates[a[1]]&.equal?(owner) }
      inst = @insts[owner] or return
      i = inst.args.index { has_var?(_1) } || 0
      throw SPECIALIZE, [owner, i]
    end

    def clone_site(kind, id, key, args)
      ck = [kind, id, key, *args.map(&:__id__)]
      cid = @clone_ids[ck]
      return site_type(kind, cid) if cid
      cid = @clone_ids[ck] = next_site_id(nil)
      (@clones[[kind, id]] ||= []) << [cid, key, args]
      (@site_fns ||= {})[cid] = @site_fns&.[](id)
      (@site_makers ||= {})[cid] = @site_makers&.[](id) if @site_makers&.key?(id)
      case kind
      when :array
        s = @sites[id]
        c = @sites[cid] = Site.new(cid, s.node, "#{s.label}'", s.declared, s.init, [])
        c.elem = subst(s.elem, key, args)
      when :hash
        s = hash_sites[id]
        c = hash_sites[cid] = HashSite.new(cid, "#{s.label}'", [], [], s.default)
        c.key = subst(s.key, key, args)
        c.val = subst(s.val, key, args)
      when :set
        s = set_sites[id]
        c = set_sites[cid] = SetSite.new(cid, "#{s.label}'", [])
        c.elem = subst(s.elem, key, args)
      end
      site_type(kind, cid)
    end

    def refresh_clones(site)
      kind = site.is_a?(Site) ? :array : (site.is_a?(HashSite) ? :hash : :set)
      (@clones[[kind, site.id]] || []).each do |cid, key, args|
        case kind
        when :array then c = @sites[cid]; c.elem = u(c.elem, subst(site.elem, key, args))
        when :hash then c = hash_sites[cid]; c.key = u(c.key, subst(site.key, key, args)); c.val = u(c.val, subst(site.val, key, args))
        when :set then c = set_sites[cid]; c.elem = u(c.elem, subst(site.elem, key, args))
        end
      end
    end

    # --- effects: recorded while evaluating, applied while collecting ---

    def add_check(node, op, arg, expected, actual, verdict, failing = [])
      return super if @collecting
      @cur_inst.effects.push([:check, node, op, arg, expected, actual, verdict, failing, @path])
    end

    def record(node, op, arg, want, actual)
      return super if @collecting || !has_var?(actual)
      return if want == "Any" || actual.empty?
      @cur_inst.effects.push([:record, node, op, arg, want, actual, @path]) # a requirement: checked per call
    end

    def add_result(node, ty)
      return @results[node] = u(@results[node] || [], ty) if @collecting
      @cur_inst.effects.push([:result, node, ty])
    end

    def mark_instantiated(fn)
      @instantiated[fn] = true
      @cur_inst.effects.push([:inst, fn]) unless @collecting || @visiting
    end

    def collect
      @collecting = true
      @checks = {}.compare_by_identity
      @check_ctx = {}.compare_by_identity
      @results = {}.compare_by_identity
      @instantiated = {}.compare_by_identity
      @replayed = {}
      @cur_inst = nil
      READS[0] = nil
      replay2(@insts[MAIN], [])
      (@main_raised || {}).each { |name, nodes| nodes.uniq.each { add_check(_1, "raise", name, "a rescue", t(name), :error, [name]) } }
    end

    def replay2(inst, envs)
      saved = @path
      inst.effects.each do |e|
        case e[0]
        when :check
          @path = e[8]
          failing = e[7]
          failing = subst_all(of_atoms(failing), envs) if has_var_uncached?(failing) # atoms (operand pairs never hold α)
          add_check(e[1], e[2], e[3], e[4], subst_all(e[5], envs), e[6], failing)
        when :record
          @path = e[6]
          record(e[1], e[2], e[3], e[4], subst_all(e[5], envs))
        when :result then @results[e[1]] = u(@results[e[1]] || [], subst_all(e[2], envs))
        when :inst then @instantiated[e[1]] = true
        when :call
          key = e[1]
          child = @insts[key] or next
          args = e[2].map { subst_all(_1, envs) }
          rk = [key, *args.map(&:__id__)]
          next if @replayed[rk]
          @replayed[rk] = true
          replay2(child, child.poly ? [[key, args], *envs] : envs)
        end
      end
      @path = saved
    end

    # --- where the body looks at a value: specialize a variable ---

    def binop(node, op, a, b)
      guard(a, b)
      super
    end

    def unop(node, op, a)
      guard(a)
      super
    end

    def index_get(node, recv, key, lit, extra = nil)
      guard(recv, key, extra)
      super
    end

    def index_set(node, recv, key, lit, val, extra = nil)
      guard(recv, key, extra, val)
      no_escape!(val, recv)
      super
    end

    def data_op(dt, name, args, node)
      guard(*args) # a field of α, α stored in a field, T.new(α)
      super
    end

    def field_write(dt, field, ty, node)
      guard(ty)
      no_escape!(ty)
      super
    end

    def write_elems(ty, xs, node, op)
      guard(*xs)
      xs.each { no_escape!(_1, ty) }
      super
    end

    def restrict(env, slot, how)
      guard(env.lookup(slot))
      super
    end

    def match_atoms(ty, pat)
      guard(ty)
      super
    end

    def narrow_by_position(env, slot, pos, atoms)
      guard(env.lookup(slot))
      super
    end

    def spread_types(v, n)
      guard(v)
      super
    end

    def spread_rest_types(v, nleft, npost, node)
      guard(v)
      super
    end

    def tuple_elems(ty)
      guard(ty)
      super
    end

    def show_types(ty, kind, node)
      guard(ty)
      super
    end

    def show_deep(ty, kind, node, seen = {})
      guard(ty)
      super
    end

    def each_elem(ty)
      guard(ty)
      super
    end

    def arg_types(nodes, env)
      nodes.flat_map do |a|
        next [ev(a, env)] unless a.is_a?(Splat)
        v = ev(a.value, env)
        guard(v)
        record(a.origin, "splat", "value", %w[Tuple Array], v)
        next [v] if unknown?(v)
        tuples = v.select { _1.is_a?(Array) && _1[0] == :tuple }.map { _1[1] }
        arrays = v.select { _1.is_a?(Array) && _1[0] == :array }
        next tuples[0].each_index.map { |i| u(*tuples.map { _1[i] }) } if arrays.empty? && tuples.map(&:size).uniq.size == 1
        elems = u(*tuples.flatten(1), elem_of(arrays))
        elems.empty? ? [] : [elems]
      end
    end

    def typer_raise(n, env)
      types =
        if n.is_a?(ReRaise)
          @handled.last || []
        else
          v = ev(n.args[0], env)
          guard(v)
          n.type ? [n.type] : v.filter_map { |a| a == "String" ? "RuntimeError" : (a.is_a?(String) && struct_type(a)&.exception ? a : nil) }
        end
      types.each { merge_raised(_1 => [n.origin]) }
      env.dead = true
      []
    end

    def call_with(n, env, args, blk)
      guard(args[0]) if (n.is_a?(CallDispatch) || n.is_a?(CallUnion)) && args[0]
      super
    end

    def call_builtin(fn, args, blk, node)
      unless @collecting
        args.each_with_index do |a, i|
          next unless has_var?(a)
          want = fn.param_type(i)
          next if want.is_a?(String) && SCALAR.include?(want)
          next if want == "Any" && ECHO.include?(fn.full_name)
          specialize!(a)
        end
        args.each_with_index { |a, i| no_escape!(a, args[0]) unless i.zero? } # an argument may be stored into the subject
      end
      super
    end

    # After a built-in checked a local, a variable's type keeps only the names the check accepts.
    def narrow_by_call(env, arg_nodes, wants)
      return unless @narrow
      arg_nodes.each_with_index do |arg, i|
        want = wants[i]
        next if want.nil? || want == "Any"
        next unless arg.is_a?(LVarGet) && (ty = env.lookup(arg.slot))
        next if unknown?(ty)
        kept = ty.flat_map do |a|
          if var?(a)
            names = a[3] ? a[3] & Array(want) : Array(want).sort
            names.empty? ? [] : [[:var, a[1], a[2], names.freeze].freeze]
          else
            Array(want).any? { atom_matches?(a, _1) } ? [a] : []
          end
        end
        env.vars[arg.slot] = of_atoms(kept)
      end
    end

    def show_atom(a, seen = {})
      return "α#{a[2]}#{a[3] ? "(#{a[3].join("|")})" : ""}" if var?(a)
      super
    end

# Typer's report, with the evaluation counts in place of passes, and without the sites of abandoned attempts.
    def report
      out = +"evaluations: #{@evaluations} (fresh #{@stats[:fresh]}, again #{@stats[:again]}, abandoned attempts #{@stats[:abandoned]}, rounds #{@round})\n" \
            "instantiations: #{@insts.size} (polymorphic #{@insts.each_value.count(&:poly)})\n"
      out << "checks: #{%i[proven partial error unknown].map { "#{_1}=#{summary[_1]}" }.join(" ")}\n"
      @checks.values.sort_by { [_1.line, _1.op] }.each do |c|
        next if c.verdict == :proven
        if c.op == "raise"
          out << "  unrescued L#{c.line} raise #{c.arg}\n"
          next
        end
        out << "  #{c.verdict.to_s.ljust(7)} L#{c.line} #{c.op} arg #{c.arg}: want #{c.expected}, got #{show(c.actual)}\n"
      end
      out << "arrays:\n"
      @sites.each_value do |s|
        next if @dead_sites[s.id]
        kind = s.declared ? "declared #{s.declared}" : "init #{show(s.init)} -> #{show(s.elem)}#{s.init != s.elem ? " (widened)" : ""}"
        out << "  #{s.label}: #{kind}\n"
      end
      out << "fields:\n"
      @fields.each { |dt, fs| fs.each { |f, ty| out << "  #{dt}.#{f}: #{show(ty)}\n" } }
      out << "dead functions: #{@dead_functions.map(&:full_name).join(", ")}\n" unless @dead_functions.empty?
      out
    end
  end
end
