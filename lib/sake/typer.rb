# frozen_string_literal: true

module Sake
  # Experimental whole-program type inference (forward abstract interpretation).
  #
  # A type is a canonical union: a sorted, frozen Array of atoms; [] is bottom (no value reaches here).
  # Atoms: "Integer" "Float" "String" "Boolean" "Nil" "<Struct name>",
  #        [:tuple, [type, ...]], [:record, [[field, type], ...]], [:array, site_id], [:unknown, reason].
  # A record atom has one atom per field (the type fixed at creation), sorted by field.
  # "IndexNil" is a nil that came from x[k] (a miss); at run time it is an ordinary nil.
  # User functions are instantiated per argument types (Crystal style); functions that yield are
  # analyzed per call site. Arrays carry an allocation site whose element type is the union of every
  # write; Struct fields are the union of every write per type. The whole program is re-analyzed until
  # these tables stop changing, and only the last pass's observations are reported.
  class Typer
    NUM = %w[Integer Float].freeze
    COMPARE_OPS = %w[< <= > >= == !=].freeze
    MAX_PASSES = 30
    MAX_YIELD_DEPTH = 3
    MAX_LOOP_ITER = 10
    MAX_TUPLE_DEPTH = 3

    # GEN counts the writes that changed what a container or a field holds (types are interned, so
    # identity tells a change): a memo stored at the current GEN needs no further check.
    GEN = [0]
    # The mutable state is cells: a Site/HashSite/SetSite, a type's field (and its whole field table),
    # @once_types, and an instantiation's key (its returns and raises). READS[0] is the read set of the instantiation being
    # evaluated (nil outside one): cell => GEN at its first read; CHANGED_AT: cell => GEN at its last
    # change. A read is still good when the cell did not change after it. See call_user.
    READS = [nil]
    CHANGED_AT = {}.compare_by_identity
    ON_DIRTY = [nil] # a hook told of each changed cell (Typer2's worklist)
    module Tracked
      def self.setter(mod, *names)
        names.each do |n|
          mod.define_method(n) { (r = READS[0]) && (r[self] ||= GEN[0]); self[n] }
          mod.define_method(:"#{n}=") do |v|
            unless v.equal?(self[n])
              CHANGED_AT[self] = (GEN[0] += 1)
              self[n] = v
              (h = ON_DIRTY[0]) && h.call(self)
              next v
            end
            self[n] = v
          end
        end
      end
    end

    def read(cell) = (r = READS[0]) && (r[cell] ||= GEN[0])

    def dirty(cell)
      CHANGED_AT[cell] = (GEN[0] += 1)
      (h = ON_DIRTY[0]) && h.call(cell)
    end
    def field_cell(dt, field) = ((@field_cells ||= {})[dt] ||= {})[field] ||= [dt, field].freeze

    Site = Struct.new(:id, :node, :label, :declared, :init, :elem)
    Tracked.setter(Site, :elem)
    Frame = Struct.new(:fn, :ret, :block)
    # The type of a parameter the call did not give, until the function's prologue types its default.
    MISSING = ["(not given)"].freeze
    # breaks: the types of the block's `break` values, which become results of the call it was given to.
    BlockCtx = Struct.new(:node, :params, :env, :breaks)
    # via: lines of the calls that led to the first failing instantiation, outermost first.
    # file: the check's file (nil for the main file); via: the call sites leading to it, each a line
    # in the main file or "file:line".
    # node: the Prism node of the operation (for messages).
    Check = Struct.new(:line, :column, :op, :arg, :expected, :actual, :verdict, :failing, :via, :file, :node)

    attr_reader :checks, :sites, :fields, :dead_functions, :passes

    # [node, message] of each check given up on (too much to check); shown as warnings.
    def unchecked = (@unchecked || {}).values

    # Inferred result type of each built-in call node (last pass), for validating result types.
    def results = @results || {}

    def add_result(node, ty)
      @results[node] = u(@results[node] || [], ty)
      @cur_inst&.effects&.push([:result, node, ty])
    end

    # narrow: inside `if x` / `while x` on a local variable, drop nil from x's type.
    # ast: the program's SakeAST, when the caller already has it.
    def initialize(program, narrow: true, ast: nil)
      @program = program
      @ast = ast || Lower.program(program)
      @narrow = narrow
      @registry = program.registry
      @site_ids = {}.compare_by_identity
      @sites = {}
      @fields = Hash.new { |h, k| h[k] = {} }
      @nil_writes = Hash.new { |h, k| h[k] = Hash.new { |h2, f| h2[f] = [] } } # dt => field => [line]
      @type_writes = Hash.new { |h, k| h[k] = Hash.new { |h2, f| h2[f] = Hash.new { |h3, n| h3[n] = [] } } } # dt => field => type name => [line]
      @returns = {}.compare_by_identity # instantiation key => its result type (all passes)
      @raises = {}.compare_by_identity  # instantiation key => {exception type => [raise nodes]}
      @insts = {}.compare_by_identity   # instantiation key => Inst (its last evaluation)
    end

    def run
      @passes = 0
      loop do
        @passes += 1
        before = snapshot
        @checks = {}.compare_by_identity   # keyed by the check key objects (one per node, op, arg)
        @check_ctx = {}.compare_by_identity
        @results = {}.compare_by_identity
        @done = {}.compare_by_identity
        @in_progress = {}.compare_by_identity
        @valid = {}.compare_by_identity
        READS[0] = nil
        @cur_inst = nil
        @yield_depth = Hash.new(0).compare_by_identity
        @instantiated = {}.compare_by_identity
        @path = Path.new(nil, nil)
        @raised = [{}]   # stack of {exception type name => [raise nodes]} for the code being analyzed
        @handled = []    # exception type names of the rescue clauses being analyzed (for a bare raise)
        ev(@ast.main.body, Env.new(nil, Frame.new(nil, [], nil)))
        @raised.last.each { |name, nodes| nodes.uniq.each { add_check(_1, "raise", name, "a rescue", t(name), :error, [name]) } }
        break if snapshot == before || @passes >= MAX_PASSES
      end
      READS[0] = nil
      all_fns = @program.functions.values.flat_map(&:values)
      @dead_functions = all_fns.reject { @instantiated[_1] }
      self
    end

    # --- types ---

    # Types are interned: one frozen object per canonical value, kept for the life of the process, so
    # equal types are the same object and object ids never repeat. The tables of the typer key by
    # identity; hashing nested atoms by value was most of the time on large programs.
    CANON = {}                       # value => the canonical object
    CANON_IDS = {}.compare_by_identity
    UNION_MEMO = {}                  # sorted ids of the (interned) arguments => result
    ONE_BY_NAME = {}                 # atom => the type of just that atom
    ONE_BY_ATOM = {}.compare_by_identity

    def self.intern(ty)
      return ty if CANON_IDS.key?(ty)
      return NONE if ty.empty?
      CANON[ty] || begin
        c = union_uncached([ty])
        c = (CANON[c] ||= c)
        CANON_IDS[c] = true
        CANON[ty.frozen? ? ty : ty.dup.freeze] = c
        c
      end
    end

    def self.one(a) = a.is_a?(String) ? (ONE_BY_NAME[a] ||= intern([a].freeze)) : (ONE_BY_ATOM[a] ||= intern([a].freeze))

    # The type made of these atoms (a selection from a canonical type, usually).
    def self.of_atoms(atoms)
      return NONE if atoms.empty?
      return one(atoms[0]) if atoms.size == 1
      union(*atoms.map { one(_1) })
    end

    NONE = [].freeze
    CANON[NONE] = NONE
    CANON_IDS[NONE] = true

    def self.union(*tys)
      return union2(tys[0], tys[1]) if tys.size == 2
      tys.map! { CANON_IDS.key?(_1) ? _1 : intern(_1) }
      return tys[0] if tys.size == 1
      key = tys.map(&:__id__)
      key.sort!
      UNION_MEMO[key] ||= intern(union_uncached(tys))
    end

    # The two-argument case, by far the commonest, keyed by identity in either order.
    UNION2 = {}.compare_by_identity

    def self.union2(a, b)
      a = intern(a) unless CANON_IDS.key?(a)
      b = intern(b) unless CANON_IDS.key?(b)
      return a if a.equal?(b)
      return b if a.empty?
      return a if b.empty?
      (h = UNION2[a]) && (r = h[b]) and return r
      (h = UNION2[b]) && (r = h[a]) and return r
      (UNION2[a] ||= {}.compare_by_identity)[b] = intern(union_uncached([a, b]))
    end

    # Canonical types with neither Tuples nor Symbol literals (nothing to merge or normalize): their union
    # is a merge of two sorted lists.
    PLAIN = {}.compare_by_identity

    def self.plain?(ty) = (PLAIN[ty] ||= (ty.none? { _1.is_a?(Array) && (_1[0] == :tuple || _1[0] == :sym) } ? 1 : 0)) == 1

    def self.merge2(a, b)
      out = []
      i = j = 0
      while i < a.size && j < b.size
        x = a[i]
        y = b[j]
        if x == y
          out << x
          i += 1
          j += 1
        elsif sort_key(x) < sort_key(y)
          out << x
          i += 1
        else
          out << y
          j += 1
        end
      end
      out.concat(a[i..]) if i < a.size
      out.concat(b[j..]) if j < b.size
      out.freeze
    end

    def self.union_uncached(tys)
      return merge2(tys[0], tys[1]) if tys.size == 2 && CANON_IDS.key?(tys[0]) && CANON_IDS.key?(tys[1]) && plain?(tys[0]) && plain?(tys[1])
      atoms = tys.flatten(1).uniq
      tuples, rest = atoms.partition { _1.is_a?(Array) && _1[0] == :tuple }
      # Tuples of one length merge position by position, except that a position holding a single Symbol
      # literal tags its variant (`[:copy, Integer]` and `[:literal, Array]` stay apart).
      merged = tuples.group_by { |tp| [tp[1].size, tp[1].each_with_index.filter_map { |e, i| [i, e[0]] if e.size == 1 && e[0].is_a?(Array) && e[0][0] == :sym }] }.map do |_, ts|
        [:tuple, ts.map { _1[1] }.transpose.map { |es| union(*es) }]
      end
      (normalize_symbols(rest) + merged).uniq.sort_by { sort_key(_1) }.freeze
    end

    # Atoms sort by their inspect text; the text of an atom object is computed once (atoms inside
    # interned types are shared, so most lookups hit).
    SORT_KEYS = {}.compare_by_identity

    SORT_KEYS_BY_NAME = {}

    def self.sort_key(atom) = atom.is_a?(String) ? (SORT_KEYS_BY_NAME[atom] ||= atom.inspect) : (SORT_KEYS[atom] ||= atom.inspect)

    MAX_SYMBOLS = 32

    # A Symbol literal is the atom [:sym, name]; "Symbol" (any Symbol) covers them, and too many become it.
    def self.normalize_symbols(atoms)
      syms = atoms.select { _1.is_a?(Array) && _1[0] == :sym }
      return atoms if syms.empty?
      return atoms - syms if atoms.include?("Symbol")
      syms.size > MAX_SYMBOLS ? atoms - syms + ["Symbol"] : atoms
    end

    def u(*tys) = tys.size == 2 ? Typer.union2(tys[0], tys[1]) : Typer.union(*tys)
    def t(name) = Typer.one(name)
    def one(a) = Typer.one(a)
    def of_atoms(atoms) = Typer.of_atoms(atoms)
    def unknown(reason) = Typer.intern([[:unknown, reason]].freeze)
    def unknown?(ty) = ty.any? { _1.is_a?(Array) && _1[0] == :unknown }

    TUPLE_MEMO = {} # ids of the (interned) element types => the Tuple type

    def tuple(elems, depth = 0)
      return unknown("tuple depth") if elems.any? { tuple_depth(_1) >= MAX_TUPLE_DEPTH }
      elems = elems.map { Typer.intern(_1) }
      TUPLE_MEMO[elems.map(&:__id__)] ||= Typer.intern([[:tuple, elems]].freeze)
    end

    # The type of a container atom, one object per site.
    def site_type(kind, id) = ((@site_types ||= {})[kind] ||= {})[id] ||= Typer.intern([[kind, id]].freeze)

    def tuple_depth(ty)
      ty.map do |a|
        next 0 unless a.is_a?(Array)
        case a[0]
        when :tuple then 1 + (a[1].map { tuple_depth(_1) }.max || 0)
        when :record then 1 + (a[1].map { tuple_depth(_1[1]) }.max || 0)
        else 0
        end
      end.max || 0
    end

    MAX_RECORD_VARIANTS = 16

    # One record atom per combination of field atoms: a record's field types are fixed per value.
    def record_type(pairs)
      sorted = pairs.sort_by(&:first)
      return [] if sorted.any? { _1[1].empty? }
      return unknown("record depth") if sorted.any? { tuple_depth(_1[1]) >= MAX_TUPLE_DEPTH }
      combos = sorted.map { |_, ty| ty }.inject([[]]) { |acc, ty| acc.product(ty).map { |c, a| c + [one(a)] } }
      return unknown("record variants") if combos.size > MAX_RECORD_VARIANTS
      u(*combos.map { |c| [[:record, sorted.map(&:first).zip(c)]] })
    end

    # The runtime type name of an atom (Values.type_of).
    NILS = %w[Nil IndexNil].freeze

    def nil_atom?(a) = NILS.include?(a)
    def without_nil(ty) = of_atoms(ty - NILS)

    def atom_type_name(a)
      return (a == "IndexNil" ? "Nil" : a) if a.is_a?(String)
      case a[0]
      when :tuple then "Tuple"
      when :array then "Array"
      when :record then "{#{a[1].map { |f, ty| "#{f}: #{atom_type_name(ty.first)}" }.join(", ")}}"
      when :range then "Range"
      when :hash then "Hash"
      when :set then "Set"
      when :thread then "Thread"
      when :queue then "Queue"
      when :sym then "Symbol"
      else "?"
      end
    end

    # seen: the sites being shown; a site inside itself (a recursive structure) is shown by its label only.
    SHOW_LIMIT = 400

    # seen: the sites already shown in this text; each is spelled out once, then named by its label,
    # so a type that refers to the same sites many times stays short. Long types are cut.
    def show(ty, seen = nil)
      return "(none)" if ty.empty?
      top = seen.nil?
      s = ty.map { show_atom(_1, seen ||= {}) }.uniq.join(" | ")
      top && s.size > SHOW_LIMIT ? "#{s[0, SHOW_LIMIT]}…" : s
    end

    def show_atom(a, seen = {})
      case a
      when "Boolean" then "true|false"
      when "Nil", "IndexNil" then "nil"
      when String then a
      else
        case a[0]
        when :tuple then "[#{a[1].map { show(_1, seen) }.join(", ")}]"
        when :record then "{#{a[1].map { |f, ty| "#{f}: #{show(ty, seen)}" }.join(", ")}}"
        when :array
          s = @sites[a[1]]
          return "#{s.declared}[]@#{s.label}" if s.declared
          return "Array@#{s.label}" if seen[a]
          "Array@#{s.label}[#{show(s.elem, seen.tap { _1[a] = true })}]"
        when :unknown then "?(#{a[1]})"
        when :range then "Range[#{show(a[1], seen)}]"
        when :hash
          s = hash_sites[a[1]]
          return "Hash@#{s.label}" if seen[a]
          inner = seen.tap { _1[a] = true }
          "Hash@#{s.label}[#{show(s.key, inner)} => #{show(s.val, inner)}]"
        when :set
          s = set_sites[a[1]]
          seen[a] ? "Set@#{s.label}" : "Set@#{s.label}[#{show(s.elem, seen.tap { _1[a] = true })}]"
        when :thread then "Thread@#{thread_sites[a[1]].label}"
        when :queue
          s = queue_sites[a[1]]
          seen[a] ? "Queue@#{s.label}" : "Queue@#{s.label}[#{show(s.elem, seen.tap { _1[a] = true })}]"
        when :pairs then "pairs"
        when :sym then ":#{a[1]}"
        end
      end
    end

    def snapshot

      [@raises.transform_values(&:dup), @sites.transform_values { [_1.elem] }, @fields.transform_values(&:dup), @returns.dup,
       hash_sites.transform_values { [_1.key, _1.val] }, set_sites.transform_values { [_1.elem] },
       thread_sites.transform_values { [_1.elem] }, queue_sites.transform_values { [_1.elem] }, (@once_types || {}).dup]
    end

    # --- array sites and fields ---

    # Declared element types whose atoms carry structure (Tuple[...] of [Float, Float]): the site keeps
    # the written atoms of that type, not just the name.
    STRUCTURED = %w[Tuple Range].freeze

    # A container's site: the place that makes it, per instantiation of the function around it (the
    # function's argument types), as a template is instantiated per type: `def index_by(rows) = Hash[]…`
    # called on Departments and on Employees makes two Hashes. When the instantiation's arguments already
    # hold (anywhere inside) a container made by this same function, or one made in the context of such a
    # container (recursion, or functions passing containers back and forth: f makes xs, g(xs) makes ys,
    # f(ys) makes zs, ...), the place gets one site for all, as before, so sites stay finite. Checking only
    # the function that made the container let the back-and-forth case add sites every pass.
    def site_id(node)
      inst = @inst_stack&.last
      made_by = inst && makers_of_args(*inst)
      ctx = made_by && inst_key(*inst)
      # a pasted copy (class B < A) shares A's nodes but not A's containers
      init, depth = @init_fns&.last
      fn = init && depth == (@inst_stack&.size || 0) ? init : inst&.first
      ctx = [:paste, fn.namespace, ctx] if fn&.pasted
      if ctx
        id = ((@ctx_site_ids ||= {}.compare_by_identity)[node] ||= {})[ctx] ||= begin
          made_by ||= {}.compare_by_identity # a pasted copy's site outside any instantiation, or shared
          made_by[inst.first] = true if inst
          next_site_id(node, ctx).tap { (@site_makers ||= {})[_1] = made_by.keys }
        end
      else
        id = (@site_ids[node] ||= next_site_id(node))
      end
      (@site_fns ||= {})[id] ||= inst&.first # the function whose code made it
      id
    end

    def next_site_id(node, ctx = nil)
      id = (@site_count = (@site_count || 0) + 1)
      (@site_ctx_label ||= {})[id] = ((@ctx_labels ||= {}.compare_by_identity)[node] ||= {})[ctx] ||= (@ctx_labels[node].size + 1) if ctx
      id
    end

    # An instantiation (a function and its argument types) as a cheap hash key: the ids of the function
    # and of the interned types. Hashing [fn, args] by value walks the function's whole body.
    def inst_key(fn, args) = [fn.__id__, *args.map(&:__id__)]

    # The functions whose contexts a site came from: the one whose code made it and, for a site made per
    # instantiation, those of the containers its instantiation's arguments held.
    def makers(id) = @site_makers&.[](id) || [@site_fns&.[](id)]

    # The makers (as a set keyed by identity) of every container the arguments hold, anywhere inside; nil
    # when fn is one of them.
    def makers_of_args(fn, args)
      out = {}.compare_by_identity
      seen = {}.compare_by_identity
      args.all? { |ty| collect_makers(ty, fn, out, seen) } ? out : nil
    end

    CONTAINER_KINDS = { array: true, hash: true, set: true, queue: true, thread: true }.freeze

    def collect_makers(ty, fn, out, seen)
      ty.all? do |a|
        next true unless a.is_a?(Array) && CONTAINER_KINDS[a[0]] && a[1].is_a?(Integer)
        next true if seen[a]
        seen[a] = true
        ms = makers(a[1])
        next false if ms.any? { _1.equal?(fn) }
        ms.each { out[_1] = true }
        inner =
          case a[0]
          when :array then [@sites[a[1]]&.elem]
          when :hash then [hash_sites[a[1]]&.key, hash_sites[a[1]]&.val]
          when :set then [set_sites[a[1]]&.elem]
          when :queue then [queue_sites[a[1]]&.elem]
          else []
          end
        inner.compact.all? { collect_makers(_1, fn, out, seen) }
      end
    end

    def site_label(id, node, extra = nil)
      n = @site_ctx_label&.[](id)
      "L#{node.location.start_line}#{n ? "##{n}" : ""}#{extra}"
    end

    def site_for(node, label_extra = nil, declared: nil, init: [])
      id = site_id(node)
      elem = declared && !STRUCTURED.include?(declared) ? t(declared) : init
      @sites[id] ||= Site.new(id, node, site_label(id, node, label_extra), declared, init, elem)
      site_type(:array, id)
    end

    def array_sites(ty) = ty.select { _1.is_a?(Array) && _1[0] == :array }.map { @sites[_1[1]] }
    def elem_of(ty) = u(*array_sites(ty).map(&:elem))

    def write_elems(ty, xs, node, op)
      array_sites(ty).each do |s|
        if s.declared
          xs.each { |x| record(node, op, "elem", s.declared, x) }
          if STRUCTURED.include?(s.declared)
            s.elem = u(s.elem, *xs.map { |x| x.select { atom_type_name(_1) == s.declared } })
          end
        else
          s.elem = u(s.elem, *xs)
        end
      end
    end

    # A field's type is every type written to it (a default is only the value `new` stores).
    def field_write(dt, field, ty, node)
      @nil_writes[dt][field] << node.location.start_line if ty.any? { nil_atom?(_1) }
      ty.each { |a| @type_writes[dt][field][atom_type_name(a)] << node.location.start_line unless nil_atom?(a) }
      fs = @fields[dt]
      new = u(fs[field] || NONE, ty)
      unless new.equal?(fs[field])
        dirty(field_cell(dt, field))
        dirty(fs) # the table is the cell of a walk over every field
      end
      fs[field] = new
    end

    # --- checks ---

    def atom_matches?(atom, want) = atom_type_name(atom) == want

    def record(node, op, arg, want, actual)
      return if want == "Any" || actual.empty?
      wants = Array(want)
      failing = actual.reject { |a| wants.any? { atom_matches?(a, _1) } }
      verdict =
        if unknown?(actual) then :unknown
        elsif failing.empty? then :proven
        elsif failing.size == actual.size then :error
        else :partial
        end
      add_check(node, op, arg, wants.join("|"), actual, verdict, failing)
    end

    VERDICTS = %i[error unknown partial proven].freeze # worst first

    def add_check(node, op, arg, expected, actual, verdict, failing = [])
      @cur_inst&.effects&.push([:check, node, op, arg, expected, actual, verdict, failing, @path])
      # One key object per (place, op, arg); nodes at the same place (copies of pasted code) share a check.
      key = (((@check_keys ||= {}.compare_by_identity)[node] ||= {})[op] ||= {})[arg] ||= begin
        k = [node.location.start_line, node.location.start_column, op, arg, other_file(node)]
        (@check_key_objs ||= {})[k] ||= k
      end
      prev = @checks[key]
      if prev
        return if op == "rescue" && prev.verdict == :proven
        prev.actual = u(prev.actual, actual)
        # Evaluations along the same calls are loop iterations and passes towards the fixpoint: a check that
        # fails in some and passes in others may fail. Different call paths keep the worse verdict.
        return prev.verdict = :proven if op == "rescue" && verdict == :proven
        ctx, counts = @check_ctx[key] # path => its verdict; counts of each verdict among the paths
        c = ctx[@path]
        v = c.nil? || c == verdict ? verdict : (([c, verdict] & %i[unknown]).empty? ? :partial : :unknown)
        ctx[@path] = v
        counts[c] -= 1 if c
        counts[v] += 1
        prev.verdict = VERDICTS.find { counts[_1].positive? }
        prev.failing = (prev.failing + failing).uniq
        prev.via ||= @path.callers unless failing.empty?
      else
        @check_ctx[key] = [{ @path => verdict }.compare_by_identity, Hash.new(0).tap { _1[verdict] = 1 }]
        @checks[key] = Check.new(key[0], key[1], op, arg, expected, actual, verdict, failing,
                                 failing.empty? ? nil : @path.callers, key[4], node)
      end
    end

    # The call path (@callers) as one object per distinct path, so a check's per-path table keys by identity.
    class Path # a plain class: hashes by identity (a Struct would hash the whole chain)
      attr_reader :parent, :site

      def initialize(parent, site)
        @parent = parent
        @site = site
      end

      def child(site) = (@children ||= {})[site] ||= Path.new(self, site)
      def callers = @callers ||= (parent ? [*parent.callers, site] : []).freeze
    end

    def push_caller(node) = @path = @path.child(call_site(node))
    def pop_caller = @path = @path.parent

    # The file of a node when it is not the main file (the checks of required files say where they are).
    def other_file(node)
      f = @program.sources&.[](node.location.send(:source))
      f == @program.path ? nil : f
    end

    # A call site for `via`: its line, or "file:line" in a required file.
    def call_site(node) = (f = other_file(node)) ? "#{f}:#{node.location.start_line}" : node.location.start_line

    # [check, item] for every check that may fail, where item is a strict item name:
    # "type" (surely fails, or may fail for a non-nil type), "nil", or "index-nil" (a nil from x[k]).
    def findings
      @checks.values.filter_map do |c|
        next if %i[proven unknown].include?(c.verdict)
        next [c, "rescue"] if c.op == "rescue"
        next [c, "unrescued"] if c.op == "raise"
        next [c, "exhaustive"] if c.op == "case/in" && c.arg == "value"
        # `x => T` that may not match is a check at run time (rescuable); one that surely fails is a type error.
        next [c, "exhaustive"] if c.op == "=>" && c.verdict != :error
        next [c, "type"] if c.verdict == :error
        parts = c.failing.map { |f| operand_pair?(c) || c.arg == "elements" ? f : [f] }
        next [c, "type"] unless parts.all? { |p| p.any? { nil_atom?(_1) } }
        [c, parts.any? { |p| p.include?("Nil") } ? "nil" : "index-nil"]
      end
    end

    # A check of an operator's two operands, whose failing entries are [left, right] pairs.
    def operand_pair?(c) = c.arg == "pair" && !c.op.start_with?("Indexable.")

    def show_failing(c)
      seen = {}
      s = if operand_pair?(c) || c.arg == "elements"
            c.failing.map { |x, y| "(#{show([x], seen)}, #{show([y], seen)})" }.uniq.join(", ")
          else
            c.failing.map { show([_1], seen) }.uniq.join(" | ")
          end
      s.size > SHOW_LIMIT ? "#{s[0, SHOW_LIMIT]}…" : s
    end

    # "Struct.field (nil written at line N)" for fields that may hold nil next to a type in `wants`.
    def nil_sources(wants = nil)
      @fields.flat_map do |dt, fs|
        fs.filter_map do |f, ty|
          next unless ty.any? { nil_atom?(_1) }
          next if wants && (ty - NILS).none? { |a| Array(wants).any? { |w| atom_matches?(a, w) } }
          lines = @nil_writes[dt][f].uniq.sort
          "#{dt}.#{f} may be nil (nil is stored at line #{lines.join(", ")})"
        end
      end
    end

    def type_names(atoms) = atoms.map { atom_type_name(_1) }.uniq

    # The element type names of each Array holding two or more non-nil types (rows of mixed values).
    def mixed_arrays
      @mixed_arrays ||= @sites.values.filter_map { |s| (n = type_names(s.elem) - %w[Nil]).size >= 2 ? n : nil }
    end

    # The type names each field holds (and the elements of the containers in it), for fields holding two
    # or more: where values of different types meet (instances of one type used for different values).
    def mixing_fields
      @mixing_fields ||= @fields.flat_map do |_dt, fs|
        fs.filter_map do |_f, ty|
          inner = ty.flat_map do |a|
            next [] unless a.is_a?(Array)
            case a[0]
            when :array then @sites[a[1]]&.elem || []
            when :hash then hash_sites[a[1]]&.val || []
            when :set then set_sites[a[1]]&.elem || []
            else []
            end
          end
          [type_names(ty), type_names(inner)].map { _1 - %w[Nil] }.select { _1.size >= 2 }
        end.flatten(1)
      end
    end

    # "Struct.field holds T (written at line N)" for fields of several types, one of which is in failing.
    def field_sources(failing)
      names = failing.map { atom_type_name(_1) }.uniq - ["Nil"]
      @type_writes.flat_map do |dt, fs|
        fs.filter_map do |f, by_type|
          next if by_type.size < 2
          hit = by_type.keys & names
          next if hit.empty? || hit.size == by_type.size
          "#{dt}.#{f} holds #{hit.join(" and ")} (written at line #{hit.flat_map { by_type[_1] }.uniq.sort.join(", ")}) besides #{(by_type.keys - hit).join(", ")}"
        end
      end
    end

    # An instantiation that surely fails makes the site an error even if other instantiations pass.
    def worse(a, b) = %i[error unknown partial proven].find { [a, b].include?(_1) }

    # --- evaluation ---

    # An instantiation's last evaluation: the cells it read (its own extent: nested instantiations are
    # children), what it did besides writing cells (checks, builtin results, functions marked
    # instantiated), and the instantiations it called (in order, as a set).
    Inst = Struct.new(:key, :reads, :effects, :children)

    def call_user(fn, args, blk)
      mark_instantiated(fn)
      args = args.map { Typer.intern(_1) }
      if fn.yields
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

      key = inst_key(fn, args)
      key = (@inst_keys ||= {})[key] ||= key # one object per instantiation: the cell of its result
      @cur_inst&.children&.store(key, true) # also when cached: a pass that uses the result has its effects
      if @in_progress[key] || @done[key]
        read(key)
        merge_raised(@raises[key] || {})
        return @returns[key] || []
      end
      # Evaluating again would read the same cells and do the same, unless one of them changed since.
      if incremental? && (inst = @insts[key]) && valid?(inst)
        replay(inst)
        return @returns[key] || []
      end
      outer_inst = @cur_inst
      outer_reads = READS[0]
      if incremental?
        inst = @insts[key] = Inst.new(key, {}.compare_by_identity, [], {}.compare_by_identity)
        @cur_inst = inst
        READS[0] = inst.reads
      end
      @in_progress[key] = true
      @raised.push({})
      (@inst_stack ||= []).push([fn, args])
      begin
        r = run_body(fn, args, nil)
      ensure
        @inst_stack.pop
        @cur_inst = outer_inst
        READS[0] = outer_reads
      end
      raised = merge_into(@raises[key] || {}, @raised.pop)
      dirty(key) unless raised == @raises[key]
      @raises[key] = raised
      merge_raised(raised)
      @in_progress.delete(key)
      @done[key] = true
      ret = u(@returns[key] || [], r)
      dirty(key) unless ret.equal?(@returns[key])
      @returns[key] = ret
    end

    # Whether a pass may replay an instantiation's last evaluation instead of evaluating it again; a
    # subclass that records every evaluation (the IDE's) says no.
    def incremental? = true

    def mark_instantiated(fn)
      @instantiated[fn] = true
      @cur_inst&.effects&.push([:inst, fn])
    end

    # Would evaluating the instantiation again do the same as last time? Yes when none of the cells it
    # read changed after it read them and the instantiations it called are valid too; those in a cycle
    # with it are taken as valid while checking.
    def valid?(inst)
      v = @valid[inst.key]
      return v != false unless v.nil?
      @valid[inst.key] = :checking
      ok = inst.reads.all? { |cell, at| (c = CHANGED_AT[cell]).nil? || c <= at } &&
           inst.children.all? { |k, _| (c = @insts[k]) && valid?(c) }
      @valid[inst.key] = ok
    end

    # What the evaluation did, done again: its checks (at their call paths), results and instantiated
    # marks, then those of the instantiations it called, each once per pass.
    def replay(inst)
      @done[inst.key] = true
      merge_raised(@raises[inst.key] || {})
      outer_inst = @cur_inst
      outer_path = @path
      @cur_inst = nil
      begin
        inst.effects.each do |e|
          case e[0]
          when :check
            @path = e[8]
            add_check(e[1], e[2], e[3], e[4], e[5], e[6], e[7])
          when :inst then @instantiated[e[1]] = true
          when :result then @results[e[1]] = u(@results[e[1]] || [], e[2])
          end
        end
      ensure
        @cur_inst = outer_inst
        @path = outer_path
      end
      # The children's raises were merged into this instantiation's frame when it was evaluated (and
      # caught there or not): its own @raises has what escaped, so theirs go to a frame that is dropped.
      @raised.push({})
      begin
        inst.children.each_key { |k| replay(@insts[k]) unless @done[k] || @in_progress[k] }
      ensure
        @raised.pop
      end
    end

    # --- exceptions: which user-raised exception types may leave each piece of code ---

    def merge_into(a, b) = a.merge(b) { |_, x, y| (x + y).uniq }
    def merge_raised(h) = @raised[-1] = merge_into(@raised[-1], h)
    def struct_type(name) = @program.struct_types[name]

    # Exception types that only `raise` produces; built-in operations may raise the other kinds anywhere.
    def user_raised?(name) = name == "RuntimeError" || !Resolver::BUILTIN_EXCEPTIONS.include?(name)

    # Index.[]: a miss gives nil for Array and String; a Tuple has a fixed length, so a literal index
    # selects one position and any other index gives the union of all positions.
    # lit: the index when it is an Integer literal.
    # extra: the type of a second index (`s[i, n]`, `m[r, c]`), or nil.
    def index_get(node, recv, key, lit, extra = nil)
      return [] if recv.empty? || key.empty? || extra&.empty?
      return unknown("index") if unknown?(recv) || unknown?(key) || (extra && unknown?(extra))
      results = []
      failing = []
      recv.each do |a|
        if struct_atom?(a)
          fn = Operators.includes?(@program.includes || {}, a, "Indexable") && @program.functions.dig(a, "[]")
          fn ? results << call_user(fn, [one(a), key, *[extra].compact], nil) : failing << a
          next
        end
        if extra # `s[start, length]` on a String or an Array: a slice, or nil
          if a == "String" then results << t("String") << t("IndexNil")
          elsif a.is_a?(Array) && a[0] == :array then results << one(a) << t("IndexNil")
          else failing << a
          end
          record(node, "Indexable.[]", "length", "Integer", extra) unless struct_atom?(a)
          next
        end
        if (ext = index_get_ext(node, a, key))
          results << ext
          next
        end
        unless a == "String" || (a.is_a?(Array) && %i[array tuple].include?(a[0]))
          failing << a
          next
        end
        next unless key.include?("Integer") # other index types are reported below
        case a
        when "String" then results << t("String") << t("IndexNil")
        else
          if a[0] == :array
            results << elem_of([a]) << t("IndexNil")
          elsif lit && (-a[1].size...a[1].size).cover?(lit)
            results << a[1][lit]
          elsif lit
            failing << a
          else
            results.concat(a[1])
          end
        end
      end
      verdict = failing.empty? ? :proven : (failing.size == recv.size ? :error : :partial)
      add_check(node, "Indexable.[]", "pair", "(Array|String|Tuple, Integer)", recv, verdict, failing)
      if recv.any? { _1 == "String" || (_1.is_a?(Array) && %i[array tuple].include?(_1[0])) }
        bad = key.reject { _1 == "Integer" || (_1.is_a?(Array) && _1[0] == :range) }
        add_check(node, "Indexable.[]", "index", "Integer", key, bad.empty? ? :proven : (bad.size == key.size ? :error : :partial), bad)
      end
      u(*results)
    end

    def index_set(node, recv, key, lit, val, extra = nil)
      return [] if recv.empty? || key.empty? || val.empty? || extra&.empty?
      recv.each do |a|
        if struct_atom?(a) && Operators.includes?(@program.includes || {}, a, "Indexable") && (fn = @program.functions.dig(a, "[]="))
          call_user(fn, [one(a), key, *[extra].compact, val], nil)
          next
        end
        next if extra # built-in types take one index when writing
        next unless a.is_a?(Array)
        if a[0] == :hash
          s = hash_sites[a[1]]
          s.key = u(s.key, key)
          s.val = u(s.val, val)
        elsif a[0] == :array
          write_elems([a], [val], node, "Indexable.[]=")
        elsif a[0] == :tuple
          want = lit && (-a[1].size...a[1].size).cover?(lit) ? a[1][lit] : u(*a[1])
          record(node, "Indexable.[]=", "value", want.map { atom_type_name(_1) }, val)
        end
      end
      bad = recv.reject do |a|
        (a.is_a?(Array) && %i[array tuple hash].include?(a[0])) ||
          (struct_atom?(a) && Operators.includes?(@program.includes || {}, a, "Indexable") && @program.functions.dig(a, "[]="))
      end
      verdict = unknown?(recv) ? :unknown : (bad.empty? ? :proven : (bad.size == recv.size ? :error : :partial))
      add_check(node, "Indexable.[]=", "pair", "(Array|Tuple, Integer)", recv, verdict, bad)
      val
    end

    def op_name(op) = "#{Operators::MODULE_OF.fetch(op)}.#{op}"

    def struct_atom?(a) = a.is_a?(String) && @program.struct_types.key?(a)

    # The result of a Struct type's own operator (or nil when the type cannot do op).
    def user_op_result(op, x, b)
      if %w[== !=].include?(op)
        fn = @program.functions.dig(x, "==")
        fn ||= Operators.includes?(@program.includes || {}, x, "Comparable") && @program.functions.dig(x, "<=>")
        call_user(fn, [one(x), b.include?(x) ? one(x) : b], nil) if fn && (b.include?(x) || @program.functions.dig(x, "=="))
        return t("Boolean")
      end
      mod = Operators::MODULE_OF.fetch(op)
      return nil unless Operators.includes?(@program.includes || {}, x, mod)
      if (fn = @program.functions.dig(x, op))
        return call_user(fn, [one(x), b], nil)
      end
      if mod == "Comparable" && (cmp = @program.functions.dig(x, "<=>"))
        call_user(cmp, [one(x), b], nil)
        return t("Boolean")
      end
      nil
    end

    def binop(node, op, a, b)
      op = op.to_s
      return [] if a.empty? || b.empty?
      if unknown?(a) || unknown?(b)
        add_check(node, op_name(op), "pair", "table row", u(a, b), :unknown)
        return unknown("operand")
      end
      rows = @registry.binary_ops[op]
      results = []
      hits = 0
      pairs = a.product(b)
      failing = []
      a.select { struct_atom?(_1) }.each do |x|
        if (r = user_op_result(op, x, b))
          hits += b.size
          results << r
        else
          b.each { |y| failing << [x, y] }
        end
      end
      pairs.reject { |x, _| struct_atom?(x) }.each do |x, y|
        if %w[== !=].include?(op) # any two values can be compared for equality
          hits += 1
          results << t("Boolean")
          next
        end
        key = [x, y].map { atom_type_name(_1) }
        unless rows.key?(key)
          failing << [x, y]
          next
        end
        hits += 1
        # Set | & - give a new Set: its elements come from the operands (a plain "Set" would have none).
        if key[0] == "Array" && %w[+ - *].include?(op)
          elems = op == "+" ? u(elem_of([x]), elem_of([y])) : elem_of([x])
          results << site_for(node, " Array#{op}").tap { |ty| write_elems(ty, [elems], node, "") }
          next
        end
        results << (key == %w[Set Set] ? set_site(node, " #{op}").tap { |r| set_sites[r[0][1]].elem = u(set_sites[r[0][1]].elem, set_elem([x]), *(op == "|" ? [set_elem([y])] : [])) } : binop_result(op, *key))
      end
      verdict = hits == pairs.size ? :proven : (hits.zero? ? :error : :partial)
      actual = pairs.map { |x, y| tuple([one(x), one(y)]) }
      add_check(node, op_name(op), "pair", "table row", u(*actual), verdict, failing)
      check_ordered_elements(node, op, pairs) if op == "<=>" || COMPARE_OPS.take(4).include?(op)
      u(*results)
    end

    # Tuples and Arrays are ordered by their elements: each pair of element types must be comparable.
    # Element pairs one comparison may visit before its element check is given up (reported as unchecked).
    MAX_ELEMENT_PAIRS = 50_000

    def check_ordered_elements(node, op, pairs)
      elem_pairs = []
      seen = Hash.new { |h, d| h[d] = Hash.new { |h2, x| h2[x] = {}.compare_by_identity }.compare_by_identity }
      budget = [MAX_ELEMENT_PAIRS]
      done = catch(:element_pairs_budget) do
        pairs.each { |x, y| elem_pairs.concat(element_pairs(x, y, 0, seen, budget)) if container_pair?(x, y) }
        true
      end
      unless done
        add_check(node, op_name(op), "elements", "comparable elements", unknown("element pairs"), :unknown)
        (@unchecked ||= {})[[other_file(node), node.location.start_line, node.location.start_column]] ||=
          [node, "#{op_name(op)}: the elements were not checked: their types make more than #{MAX_ELEMENT_PAIRS} pairs to compare"]
        return
      end
      elem_pairs.uniq!
      return if elem_pairs.empty?
      failing = elem_pairs.reject { |ex, ey| comparable_atoms?(ex, ey) }
      verdict = failing.empty? ? :proven : (failing.size == elem_pairs.size ? :error : :partial)
      add_check(node, op_name(op), "elements", "comparable elements", u(*elem_pairs.map { |ex, ey| tuple([one(ex), one(ey)]) }),
                verdict, failing)
    end

    def container_pair?(x, y) = %i[tuple array].any? { |k| [x, y].all? { _1.is_a?(Array) && _1[0] == k } }

    # The pairs of atoms an ordering of x and y compares, through nested Tuples and Arrays (so a nil
    # inside is reported as nil, not as an Array that cannot be compared).
    # A pair already visited at the same depth yields the same pairs again, and the caller drops repeats,
    # so it is skipped: without this, nested element unions multiply into billions of pairs. seen is keyed by
    # depth, then by the atoms' identities (hashing deep atoms by value costs as much as the walk).
    def element_pairs(x, y, depth, seen, budget)
      return [] if seen[depth][x].key?(y)
      seen[depth][x][y] = true
      return [[x, y]] unless depth < 3 && container_pair?(x, y)
      inner = if x[0] == :tuple
                x[1].zip(y[1]).flat_map { |ex, ey| ey ? ex.product(ey) : [] }
              else
                elem_of([x]).product(elem_of([y]))
              end
      throw :element_pairs_budget if (budget[0] -= inner.size).negative?
      inner.flat_map { |a, b| element_pairs(a, b, depth + 1, seen, budget) }
    end

    def comparable_atoms?(x, y, depth = 0)
      ((@comparable_memo ||= {})[[x, y, depth]] ||= [comparable_atoms_uncached?(x, y, depth)])[0]
    end

    def comparable_atoms_uncached?(x, y, depth)
      return true if [x, y].any? { _1.is_a?(Array) && _1[0] == :unknown }
      if struct_atom?(x)
        return Operators.includes?(@program.includes || {}, x, "Comparable") && !!@program.functions.dig(x, "<=>")
      end
      if depth < 3 && [x, y].all? { _1.is_a?(Array) && _1[0] == :tuple }
        return x[1].zip(y[1]).all? { |ex, ey| ey.nil? || ex.product(ey).all? { |a, b| comparable_atoms?(a, b, depth + 1) } }
      end
      if depth < 3 && [x, y].all? { _1.is_a?(Array) && _1[0] == :array }
        return elem_of([x]).product(elem_of([y])).all? { |a, b| comparable_atoms?(a, b, depth + 1) }
      end
      @registry.binary_ops["<=>"].key?([x, y].map { atom_type_name(_1) })
    end

    # `-x` / `+x` / `~x`: a built-in type keeps its type; a Struct type runs its own operator.
    def unop(node, op, a)
      return [] if a.empty?
      if unknown?(a)
        add_check(node, op_name(op), "operand", "a type with #{op}", a, :unknown)
        return unknown("operand")
      end
      results = []
      failing = []
      a.each do |x|
        if struct_atom?(x)
          fn = Operators.includes?(@program.includes || {}, x, Operators::MODULE_OF.fetch(op)) && @program.functions.dig(x, op)
          fn ? results << call_user(fn, [one(x)], nil) : failing << x
        elsif @registry.unary_ops[op].key?(atom_type_name(x))
          results << one(x)
        else
          failing << x
        end
      end
      verdict = failing.empty? ? :proven : (failing.size == a.size ? :error : :partial)
      add_check(node, op_name(op), "operand", @registry.unary_ops[op].keys.join("|"), a, verdict, failing)
      u(*results)
    end

    # `sum(xs[, init])`: an empty collection gives init (default 0, an Integer); otherwise init + the elements.
    def sum_type(init, elems)
      init ||= t("Integer")
      nums = elems.select { Stdlib::NUMERIC.include?(_1) }
      u(init, *init.product(nums).map { |a, b| binop_result("+", a, b) })
    end

    # Result types of the BinaryOp rows (Ruby's numeric tower).
    def binop_result(op, t1, t2)
      return u(t("Integer"), t("Nil")) if op == "<=>"
      return t("Boolean") if COMPARE_OPS.include?(op) || op == "!~"
      return u(t("Integer"), t("Nil")) if op == "=~"
      return t("String") if t1 == "String"
      return t("Set") if t1 == "Set"
      return (t2 == "Time" ? t("Float") : t("Time")) if t1 == "Time"
      types = [t1, t2]
      return t("Complex") if types.include?("Complex")
      return t("Float") if types.include?("Float")
      return t("Rational") if types.include?("Rational")
      t("Integer")
    end

    def call_builtin(fn, args, blk, node)
      if fn.keyword_types.any? && (pairs = args.last&.find { _1.is_a?(Array) && _1[0] == :pairs })
        args = args[0...-1]
        pairs[1].each do |k, v|
          name = k.find { _1.is_a?(Array) && _1[0] == :sym }&.[](1)
          record(node, fn.full_name, "#{name}:", fn.keyword_types[name], v) if fn.keyword_types.key?(name)
        end
      end
      args.each_with_index { |a, i| record(node, fn.full_name, i + 1, fn.param_type(i), a) }
      return [] if args.any?(&:empty?)

      ns = fn.namespace
      name = fn.name
      if (dt = @program.struct_types[ns]) && name != CTOR
        return data_op(dt, name, args, node)
      end
      if (r = constructor_ext(ns, name, args, node))
        return r
      end
      if name == CTOR
        if ns == "Array"
          # Every instantiation adds its element types (the site is made once, by the first).
          return site_for(node, init: u(*args)).tap { |ty| write_elems(ty, args, node, "") }
        end
        return site_for(node, declared: ns).tap { |ty| write_elems(ty, args, node, "#{ns}[]") }
      end
      # `Integer.+(a, b)`: the operator rows whose left operand is the type.
      return binop(node, name, args[0], args[1]) if @registry.binary_ops.key?(name) && fn.params.size == 2 && fn.params[1] == "Any"
      struct_hooks(args, name)
      builtin_result(fn.full_name, args, blk, node)
    end

    # The Ruby methods behind a built-in (sort, max, include?, uniq, Hash keys, ...) call a Struct
    # type's own <=> and ==. Each is analyzed with the values it can be compared with: the arguments and
    # their elements with each other, then, level by level, values at the same place (the same field,
    # Tuple position, Record key, or element of nested collections).
    def struct_hooks(tys, name)
      return if tys.all? { |ty| ty.all? { _1.is_a?(String) && !struct_atom?(_1) } } # built-in atoms only: nothing to compare
      meets = MEETS_ARGUMENTS.include?(name) # an argument against a collection's elements or keys
      # Memoized per argument types; the groups also depend on what the containers the walk read hold.
      key = [meets, *tys.map(&:__id__)]
      memo = (@hooks_memo ||= {})
      hit = memo[key]
      if hit && (hit[2] == GEN[0] || deps_hold?(hit[0]))
        hit[2] = GEN[0]
        groups = hit[1]
      else
        groups = (memo[key] = [*compared_groups_of(tys, meets), GEN[0]])[1]
      end
      groups.each do |g, other|
        g.each do |x|
          %w[<=> ==].each { |op| (fn = @program.functions.dig(x, op)) and call_user(fn, [one(x), other], nil) }
        end
      end
    end

    # deps: what a group walk read, by identity => what it held then (types are interned, so identity
    # tells a change): a Site or SetSite => elem, a HashSite => [key, val], a type's field table => values.
    def deps_hold?(deps)
      deps.all? do |o, v|
        case o
        when HashSite then o.key.equal?(v[0]) && o.val.equal?(v[1])
        when Hash
          vs = o.values
          vs.size == v.size && vs.each_index.all? { vs[_1].equal?(v[_1]) }
        else o.elem.equal?(v)
        end
      end
    end

    # What a canonical type holds besides containers, fixed per type: its Struct atoms, and the types at
    # each Tuple position and Record key; and whether it has containers (whose contents are read at walk time).
    Shape = Struct.new(:structs, :columns, :containers)

    def shape_of(ty)
      (@shapes ||= {}.compare_by_identity)[ty] ||= begin
        tuples = atoms_of(ty, :tuple).map { _1[1] }
        columns = (0...(tuples.map(&:size).max || 0)).map { |i| u(*tuples.filter_map { _1[i] }) }
        records = atoms_of(ty, :record).flat_map { _1[1] }
        columns += records.map(&:first).uniq.map { |k| u(*records.select { _1[0] == k }.map(&:last)) }
        Shape.new(ty.select { struct_atom?(_1) }, columns, ty.any? { _1.is_a?(Array) && %i[array set hash].include?(_1[0]) })
      end
    end

    # Built-ins that compare one argument with another's elements or keys (`Array.include?(xs, x)`).
    MEETS_ARGUMENTS = %w[include? member? index find_index rindex count delete delete? key? has_key? value? has_value? key
                         fetch fetch_values values_at dig [] []= store add add? union difference intersection intersect?
                         subset? superset? disjoint? - + & | ==].freeze

    # The groups under a Struct type's fields (the default == compares them), memoized per Struct type:
    # the groups of the types its fields reach directly, the deps of that walk, and the Struct types met on
    # the way, which are walked (through their own memos) when the memo is used. Each Struct type is
    # walked once per group walk; groups come out Struct by Struct rather than in the interleaved order.
    def struct_groups(a, out, seen, deps)
      fs = @fields[a]
      read(fs)
      if (collect = @sg_collect) # inside a memo computation: defer to the use of the memo
        collect << a unless collect.include?(a)
        return
      end
      return if seen[fs]
      seen[fs] = true
      memo = (@struct_groups ||= {})
      hit = memo[a]
      unless hit && (hit[3] == GEN[0] || deps_hold?(hit[0]))
        d = { fs => fs.values }.compare_by_identity
        g = []
        @sg_collect = reached = []
        begin
          fs.each_value { compared_groups(_1, g, {}.compare_by_identity, d) }
        ensure
          @sg_collect = nil
        end
        hit = memo[a] = [d, g, reached, GEN[0]]
      end
      hit[3] = GEN[0]
      out.concat(hit[1])
      hit[0].each { |o, v| deps[o] = v unless deps.key?(o) }
      hit[2].each { struct_groups(_1, out, seen, deps) }
    end

    # [deps, [[struct names, their union], ...]] (deps: see deps_hold?).
    def compared_groups_of(tys, meets)
      tops = tys.map { |ty| ty.all? { _1.is_a?(String) } ? ty : u(ty, elem_of(ty), set_elem(ty), *hash_kv(ty)) }
      tops = [u(*tops)] if meets
      groups = []
      deps = {}.compare_by_identity
      seen = {}.compare_by_identity
      tops.each { compared_groups(_1, groups, seen, deps) }
      [deps, groups.uniq.map { |g| [g, (@group_types ||= {})[g] ||= of_atoms(g)] }]
    end

    def compared_groups(ty, out, seen, deps)
      return if ty.empty? || seen[ty]
      seen[ty] = true
      shape = shape_of(ty)
      if shape.containers
        ty.each do |a|
          next unless a.is_a?(Array)
          case a[0]
          when :array then (s = @sites[a[1]]) && deps.key?(s) || (deps[s] = s.elem)
          when :set then (s = set_sites[a[1]]) && deps.key?(s) || (deps[s] = s.elem)
          when :hash then (s = hash_sites[a[1]]) && deps.key?(s) || (deps[s] = [s.key, s.val])
          end
        end
      end
      out << shape.structs unless shape.structs.empty?
      shape.structs.each { struct_groups(_1, out, seen, deps) }
      shape.columns.each { compared_groups(_1, out, seen, deps) }
      return unless shape.containers
      compared_groups(u(elem_of(ty), set_elem(ty)), out, seen, deps)
      hash_kv(ty).each { compared_groups(_1, out, seen, deps) }
    end

    # T.initialize(c) after T.new: analyzed for each construction, where `@x` reads the value this `new`
    # gave (the instance is the one just made), so a wrong argument is reported for this call.
    # Returns the fields' types after initialize (field => type), or nil when it cannot finish normally.
    # The fields of the new instance are followed like local variables ([:field, name] in the env), so a
    # field written on some paths only keeps what `new` gave on the others; every exit (the end, and each
    # `return`) adds its types.
    def run_initialize(dt, given, node)
      init = @program.functions.dig(dt.name, "initialize") or return given
      @init_depth ||= Hash.new(0).compare_by_identity
      return given if @init_depth[init] >= 2 # an initialize that constructs its own type
      @init_depth[init] += 1
      mark_instantiated(init)
      push_caller(node)
      (@init_fns ||= []).push([init, @inst_stack&.size || 0])
      frame = Frame.new(init, [], nil)
      env = Env.new(nil, frame)
      env.vars[0] = t(dt.name)
      exits = nil
      if init_overlay?(init)
        given.each { |f, ty| env.vars[[:field, f]] = ty }
        exits = (@init_frames ||= {}.compare_by_identity)[frame] = {}
      end
      begin
        r = ev(@ast.functions.fetch(init).body, env)
        init_exit(env, exits) if exits && !env.dead
        return nil if u(r, frame.ret).empty?
        exits ? given.keys.to_h { |f| [f, exits[f] || given[f]] } : given
      ensure
        @init_frames&.delete(frame)
        @init_fns.pop
        pop_caller
        @init_depth[init] -= 1
      end
    end

    # The new instance's fields where initialize leaves (its end, or a `return`).
    def init_exit(env, exits)
      @program.struct_types.fetch(env.frame.fn.namespace).fields.each do |f|
        (ty = env.lookup([:field, f])) && exits[f] = u(exits[f] || [], ty)
      end
    end

    # The construction's values stand for `@x` only if the instance parameter is never reassigned.
    def init_overlay?(init)
      (@init_overlay_ok ||= {}.compare_by_identity).fetch(init) do
        @init_overlay_ok[init] = !assigns_slot?(@ast.functions.fetch(init).body, 0)
      end
    end

    def assigns_slot?(n, slot)
      return false unless n.is_a?(Struct) && n.class.respond_to?(:fields)
      return true if n.is_a?(AST::LVarSet) && n.slot == slot
      n.class.fields.any? { |f| (v = n[f]).is_a?(Array) ? v.flatten.any? { assigns_slot?(_1, slot) } : assigns_slot?(v, slot) }
    end

    # Every element type of the Tuples in ty (nil for an empty Tuple; unknown for anything else).
    def tuple_elems(ty)
      u(*ty.map do |a|
        next unknown("tuple elements") unless a.is_a?(Array) && a[0] == :tuple
        a[1].empty? ? t("Nil") : u(*a[1])
      end)
    end

    def data_op(dt, name, args, node)
      case name
      when "new"
        given = dt.fields.each_with_index.to_h do |f, i|
          ty = args[i] == MISSING ? nil : args[i]
          ty ||= t("Nil") # left out: nil until initialize sets it
          [f, ty]
        end
        # A construction whose initialize cannot finish (`@port => Integer` on a String) stores nothing;
        # otherwise the fields hold what initialize leaves in them.
        stored = run_initialize(dt, given, node) or return []
        stored.each { |f, ty| field_write(dt.name, f, ty, node) }
        t(dt.name)
      when *dt.fields # the reader `T.x(v)`
        read(field_cell(dt.name, name))
        @fields[dt.name][name] || []
      when /\Aset_(.+)\z/
        field_write(dt.name, $1, args[1], node)
        args[1]
      end
    end

    def new_site(node, label, elem) = site_for(node, label, init: elem).tap { |ty| write_elems(ty, [elem], node, "") }

    RANGE_INT_ONLY = %w[Range.step Range.sum Range.size].freeze

    def builtin_result(name, args, blk, node)
      if Stdlib::RANGE_ITERATING.include?(name)
        record(node, name, "range", RANGE_INT_ONLY.include?(name) ? "Integer" : %w[Integer String], range_elem(args[0]))
      end
      ext = builtin_result_ext(name, args, blk, node)
      return ext unless ext == :none
      a0 = args[0]
      case name
      when "Kernel.puts", "Kernel.print" then t("Nil")
      when "Kernel.p" then a0
      when "Integer.to_s", "Float.to_s", "String.to_s" then t("String")
      when "Integer.to_f", "String.to_f" then t("Float")
      when "Float.to_i", "Float.floor", "Float.ceil", "String.to_i", "String.length", "String.size",
           "String.count", "Array.length", "Array.size", "Tuple.length", "Tuple.size"
        t("Integer")
      when "Float.round" then args.size > 1 ? t("Float") : t("Integer")
      when "Integer.abs", "Integer.succ", "Integer.pred" then t("Integer")
      when "Float.abs" then t("Float")
      when "Integer.even?", "Integer.odd?", "Integer.zero?", "Float.nan?", "String.empty?", "String.include?",
           "String.start_with?", "String.end_with?", "Array.empty?", "Array.include?"
        t("Boolean")
      when /\AString\./
        if %w[String.chars String.lines String.split].include?(name)
          new_site(node, " #{name}", t("String"))
        elsif name == "String.each_char"
          call_block(blk, [t("String")])
          t("String")
        else
          t("String")
        end
      when /\AMath\./ then t("Float")
      when "Integer.times", "Integer.upto", "Integer.downto"
        call_block(blk, [t("Integer")])
        t("Integer")
      when "Array.push", "Array.append"
        write_elems(a0, args.drop(1), node, name)
        a0
      when "Array.concat"
        write_elems(a0, [elem_of(args[1])], node, name)
        a0
      when "Array.join" then t("String")
      when "Array.first", "Array.last"
        args.size == 2 ? new_site(node, " #{name}", elem_of(a0)) : u(elem_of(a0), t("Nil"))
      when "Array.at", "Array.pop", "Array.shift", "Array.min", "Array.max"
        u(elem_of(a0), t("Nil"))
      when "Array.fetch" then args.size == 3 ? u(elem_of(a0), args[2]) : elem_of(a0)
      when "Tuple.max", "Tuple.min", "Tuple.minmax"
        e = tuple_elems(a0)
        name == "Tuple.minmax" ? tuple([e, e]) : e
      when "Array.unshift"
        write_elems(a0, args.drop(1), node, name)
        a0
      when "Array.find", "Array.detect", "Array.min_by", "Array.max_by"
        e = elem_of(a0)
        call_block(blk, [e]) unless e.empty?
        u(e, t("Nil"))
      when "Array.index", "String.index" then u(t("Integer"), t("Nil"))
      when "Array.find_index"
        e = elem_of(a0)
        call_block(blk, [e]) unless e.empty?
        u(t("Integer"), t("Nil"))
      when "Range.sum"
        e = range_elem(a0)
        e = call_block(blk, [e]) if blk && !e.empty?
        record(node, "Range.sum", "elem", Stdlib::NUMERIC, e) if blk
        sum_type(args[1], e)
      when "Array.sum"
        e = elem_of(a0)
        e = call_block(blk, [e]) if blk && !e.empty?
        record(node, "Array.sum", "elem", Stdlib::NUMERIC, e)
        sum_type(args[1], e)
      when "Array.new"
        elem = blk ? call_block(blk, [t("Integer")]) : (args[1] || t("Nil"))
        new_site(node, " #{name}", elem)
      when "Array.reverse", "Array.sort", "Array.take", "Array.drop"
        new_site(node, " #{name}", elem_of(a0))
      when "Array.select", "Array.filter", "Array.reject", "Array.sort_by"
        e = elem_of(a0)
        call_block(blk, [e]) unless e.empty?
        new_site(node, " #{name}", e)
      when "Array.map"
        e = elem_of(a0)
        r = e.empty? ? [] : call_block(blk, [e])
        new_site(node, " #{name}", r)
      when "Array.each"
        e = elem_of(a0)
        call_block(blk, [e]) unless e.empty?
        a0
      when "Array.each_with_index"
        e = elem_of(a0)
        return new_site(node, " #{name}", e.empty? ? [] : tuple([e, t("Integer")])) unless blk
        call_block(blk, [e, t("Integer")]) unless e.empty?
        a0
      when "Array.any?", "Array.all?", "Array.none?"
        e = elem_of(a0)
        call_block(blk, [e]) unless e.empty?
        t("Boolean")
      when "Array.count"
        e = elem_of(a0)
        call_block(blk, [e]) unless e.empty?
        t("Integer")
      when "Array.reduce", "Array.inject"
        e = elem_of(a0)
        acc = args[1]
        return acc if e.empty?
        MAX_LOOP_ITER.times do
          nxt = u(acc, call_block(blk, [acc, e]))
          break if nxt == acc
          acc = nxt
        end
        acc
      when "Exception.message" then t("String")
      else unknown("no signature for #{name}")
      end
    end
  end
end

module Sake
  class Typer
    # Verdicts of the run-time checks; rescue clauses and unrescued raises are not checks of a value.
    def summary
      counts = Hash.new(0)
      @checks.each_value { counts[_1.verdict] += 1 unless %w[raise rescue].include?(_1.op) }
      counts
    end

    def report
      out = +""
      out << "passes: #{@passes}\n"
      out << "checks: #{%i[proven partial error unknown].map { "#{_1}=#{summary[_1]}" }.join(" ")}\n"
      @checks.values.sort_by { [_1.line, _1.op] }.each do |c|
        next if c.verdict == :proven
        if c.op == "raise" # not a failing check: an exception nothing rescues (the `unrescued` item, level 4)
          out << "  unrescued L#{c.line} raise #{c.arg}\n"
          next
        end
        out << "  #{c.verdict.to_s.ljust(7)} L#{c.line} #{c.op} arg #{c.arg}: want #{c.expected}, got #{show(c.actual)}\n"
      end
      out << "arrays:\n"
      @sites.each_value do |s|
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
require_relative "typer_ext"
require_relative "typer_eval"
