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

    Site = Struct.new(:id, :node, :label, :declared, :init, :elem)
    Frame = Struct.new(:fn, :ret, :block)
    BlockCtx = Struct.new(:node, :params, :env)
    # via: lines of the calls that led to the first failing instantiation, outermost first.
    Check = Struct.new(:line, :column, :op, :arg, :expected, :actual, :verdict, :failing, :via)

    class Env
      attr_reader :vars, :parent, :frame
      attr_accessor :dead # control left via return/next/break; this path does not fall through

      def initialize(parent, frame, vars = {})
        @parent = parent
        @frame = frame
        @vars = vars
      end

      def up(depth)
        e = self
        depth.times { e = e.parent }
        e
      end

      def dup_level = Env.new(@parent, @frame, @vars.dup)

      def chain_snapshot
        e = self
        snap = []
        while e
          snap << e.vars.dup
          e = e.parent
        end
        snap
      end
    end

    attr_reader :checks, :sites, :fields, :dead_functions, :passes

    # narrow: inside `if x` / `while x` on a local variable, drop nil from x's type.
    def initialize(program, narrow: true)
      @program = program
      @narrow = narrow
      @registry = program.registry
      @site_ids = {}.compare_by_identity
      @sites = {}
      @fields = Hash.new { |h, k| h[k] = {} }
      @nil_writes = Hash.new { |h, k| h[k] = Hash.new { |h2, f| h2[f] = [] } } # dt => field => [line]
      @returns = {}
    end

    def run
      @passes = 0
      loop do
        @passes += 1
        before = snapshot
        @checks = {}
        @done = {}
        @in_progress = {}
        @yield_depth = Hash.new(0)
        @instantiated = {}
        @callers = []
        @raised = [{}]   # stack of {exception type name => [raise nodes]} for the code being analyzed
        @handled = []    # exception type names of the rescue clauses being analyzed (for a bare raise)
        env = Env.new(nil, Frame.new(nil, [], nil))
        @program.toplevel.each { ev(_1, env) }
        @raised.last.each { |name, nodes| nodes.uniq.each { add_check(_1, "raise", name, "a rescue", t(name), :error, [name]) } }
        break if snapshot == before || @passes >= MAX_PASSES
      end
      all_fns = @program.functions.values.flat_map(&:values)
      @dead_functions = all_fns.reject { @instantiated[_1] }
      self
    end

    # --- types ---

    def self.union(*tys)
      atoms = tys.flatten(1).uniq
      tuples, rest = atoms.partition { _1.is_a?(Array) && _1[0] == :tuple }
      merged = tuples.group_by { _1[1].size }.map do |_, ts|
        [:tuple, ts.map { _1[1] }.transpose.map { |es| union(*es) }]
      end
      (rest + merged).uniq.sort_by(&:inspect).freeze
    end

    def u(*tys) = Typer.union(*tys)
    def t(name) = [name].freeze
    def unknown(reason) = [[:unknown, reason]].freeze
    def unknown?(ty) = ty.any? { _1.is_a?(Array) && _1[0] == :unknown }

    def tuple(elems, depth = 0)
      return unknown("tuple depth") if elems.any? { tuple_depth(_1) >= MAX_TUPLE_DEPTH }
      [[:tuple, elems]].freeze
    end

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
      combos = sorted.map { |_, ty| ty }.inject([[]]) { |acc, ty| acc.product(ty).map { |c, a| c + [[a].freeze] } }
      return unknown("record variants") if combos.size > MAX_RECORD_VARIANTS
      u(*combos.map { |c| [[:record, sorted.map(&:first).zip(c)]] })
    end

    # The runtime type name of an atom (Values.type_of).
    NILS = %w[Nil IndexNil].freeze

    def nil_atom?(a) = NILS.include?(a)
    def without_nil(ty) = u(*(ty - NILS).map { [_1] })

    def atom_type_name(a)
      return (a == "IndexNil" ? "Nil" : a) if a.is_a?(String)
      case a[0]
      when :tuple then "Tuple"
      when :array then "Array"
      when :record then "{#{a[1].map { |f, ty| "#{f}: #{atom_type_name(ty.first)}" }.join(", ")}}"
      when :range then "Range"
      when :hash then "Hash"
      when :set then "Set"
      else "?"
      end
    end

    def show(ty)
      return "(none)" if ty.empty?
      ty.map { show_atom(_1) }.join(" | ")
    end

    def show_atom(a)
      case a
      when "Boolean" then "true|false"
      when "Nil", "IndexNil" then "nil"
      when String then a
      else
        case a[0]
        when :tuple then "[#{a[1].map { show(_1) }.join(", ")}]"
        when :record then "{#{a[1].map { |f, ty| "#{f}: #{show(ty)}" }.join(", ")}}"
        when :array
          s = @sites[a[1]]
          s.declared ? "#{s.declared}[]@#{s.label}" : "Array@#{s.label}[#{show(s.elem)}]"
        when :unknown then "?(#{a[1]})"
        when :range then "Range[#{show(a[1])}]"
        when :hash
          s = hash_sites[a[1]]
          "Hash@#{s.label}[#{show(s.key)} => #{show(s.val)}]"
        when :set then "Set@#{set_sites[a[1]].label}[#{show(set_sites[a[1]].elem)}]"
        when :pairs then "pairs"
        end
      end
    end

    def snapshot
      [(@raises ||= {}).transform_values(&:dup), @sites.transform_values { [_1.elem] }, @fields.transform_values(&:dup), @returns.dup,
       hash_sites.transform_values { [_1.key, _1.val] }, set_sites.transform_values { [_1.elem] }]
    end

    # --- array sites and fields ---

    def site_for(node, label_extra = nil, declared: nil, init: [])
      id = (@site_ids[node] ||= @site_ids.size + 1)
      @sites[id] ||= Site.new(id, node, "L#{node.location.start_line}#{label_extra}", declared, init, declared ? t(declared) : init)
      [[:array, id]].freeze
    end

    def array_sites(ty) = ty.select { _1.is_a?(Array) && _1[0] == :array }.map { @sites[_1[1]] }
    def elem_of(ty) = u(*array_sites(ty).map(&:elem))

    def write_elems(ty, xs, node, op)
      array_sites(ty).each do |s|
        if s.declared
          xs.each { |x| record(node, op, "elem", s.declared, x) }
        else
          s.elem = u(s.elem, *xs)
        end
      end
    end

    def field_write(dt, field, ty, node)
      @nil_writes[dt][field] << node.location.start_line if ty.any? { nil_atom?(_1) }
      @fields[dt][field] = u(@fields[dt][field] || [], ty)
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

    def add_check(node, op, arg, expected, actual, verdict, failing = [])
      key = [node.location.start_line, node.location.start_column, op, arg]
      prev = @checks[key]
      if prev
        prev.actual = u(prev.actual, actual)
        prev.verdict = worse(prev.verdict, verdict)
        prev.failing = (prev.failing + failing).uniq
        prev.via ||= @callers.dup unless failing.empty?
      else
        @checks[key] = Check.new(node.location.start_line, node.location.start_column, op, arg, expected, actual, verdict, failing,
                                 failing.empty? ? nil : @callers.dup)
      end
    end

    # [check, item] for every check that may fail, where item is a strict item name:
    # "type" (surely fails, or may fail for a non-nil type), "nil", or "index-nil" (a nil from x[k]).
    def findings
      @checks.values.filter_map do |c|
        next if %i[proven unknown].include?(c.verdict)
        next [c, "rescue"] if c.op == "rescue"
        next [c, "unrescued"] if c.op == "raise"
        next [c, "type"] if c.verdict == :error
        parts = c.failing.map { |f| c.op.start_with?("BinaryOp.") ? f : [f] }
        next [c, "type"] unless parts.all? { |p| p.any? { nil_atom?(_1) } }
        [c, parts.any? { |p| p.include?("Nil") } ? "nil" : "index-nil"]
      end
    end

    def show_failing(c)
      return c.failing.map { |x, y| "(#{show([x])}, #{show([y])})" }.uniq.join(", ") if c.op.start_with?("BinaryOp.")
      c.failing.map { show([_1]) }.uniq.join(" | ")
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

    # An instantiation that surely fails makes the site an error even if other instantiations pass.
    def worse(a, b) = %i[error unknown partial proven].find { [a, b].include?(_1) }

    # --- evaluation ---

    def ev(node, env)
      case node
      when nil then t("Nil")
      when Prism::StatementsNode
        r = t("Nil")
        node.body.each { r = ev(_1, env) }
        r
      when Prism::IntegerNode then t("Integer")
      when Prism::FloatNode then t("Float")
      when Prism::RationalNode then t("Rational")
      when Prism::ImaginaryNode then t("Complex")
      when Prism::StringNode then t("String")
      when Prism::TrueNode, Prism::FalseNode then t("Boolean")
      when Prism::NilNode then t("Nil")
      when Prism::LocalVariableReadNode then env.up(node.depth).vars[node.name] || t("Nil")
      when Prism::ItLocalVariableReadNode then env.vars[:it] || t("Nil")
      when Prism::LocalVariableWriteNode then assign(env, node.depth, node.name, ev(node.value, env))
      when Prism::LocalVariableOperatorWriteNode
        cur = env.up(node.depth).vars[node.name] || t("Nil")
        assign(env, node.depth, node.name, binop(node, node.binary_operator.to_s, cur, ev(node.value, env)))
      when Prism::MultiWriteNode then multi_write(node, env)
      when Prism::LocalVariableOrWriteNode
        cur = env.up(node.depth).vars[node.name] || t("Nil")
        assign(env, node.depth, node.name, u(*(cur - NILS - ["Boolean"]).map { [_1] }, ev(node.value, env)))
      when Prism::IndexOperatorWriteNode, Prism::IndexOrWriteNode
        key_node = node.arguments.arguments.first
        recv = ev(node.receiver, env)
        key = ev(key_node, env)
        cur = index_get(node, recv, key, key_node)
        val =
          if node.is_a?(Prism::IndexOrWriteNode)
            u(*(cur - NILS - ["Boolean"]).map { [_1] }, ev(node.value, env))
          else
            binop(node, node.binary_operator.to_s, cur, ev(node.value, env))
          end
        index_set(node, recv, key, key_node, val)
      when Prism::IfNode then branch(env, node.predicate, node.statements, node.subsequent)
      when Prism::UnlessNode then branch(env, node.predicate, node.else_clause, node.statements)
      when Prism::ElseNode then ev(node.statements, env)
      when Prism::WhileNode, Prism::UntilNode then loop_node(node, env)
      when Prism::AndNode, Prism::OrNode
        l = ev(node.left, env)
        right_env = env.dup_level
        narrow(right_env, node.left, node.is_a?(Prism::AndNode))
        r = ev(node.right, right_env)
        join_into(env, env.dup_level, right_env)
        # `a && b` yields a only when a is falsy; `a || b` yields a only when a is truthy.
        left = node.is_a?(Prism::AndNode) ? l & (NILS + ["Boolean"]) : l - NILS
        u(*left.map { [_1] }, r)
      when Prism::ParenthesesNode then ev(node.body, env)
      when Prism::ArrayNode then tuple(node.elements.map { ev(_1, env) })
      when Prism::HashNode then record_type(node.elements.map { [_1.key.unescaped, ev(_1.value, env)] })
      when Prism::MatchRequiredNode then match_record(node, env)
      when Prism::BeginNode then typer_begin(node, env)
      when Prism::RescueModifierNode then typer_rescue_modifier(node, env)
      when Prism::RetryNode then []
      when Prism::MatchPredicateNode
        m, = match_atoms(ev(node.value, env), node.pattern)
        bind_pattern(env, node.pattern, m)
        t("Boolean")
      when Prism::CaseMatchNode then case_match(node, env)
      when Prism::ReturnNode
        vals = (node.arguments&.arguments || []).map { ev(_1, env) }
        v = vals.size > 1 ? tuple(vals) : (vals.first || t("Nil"))
        env.frame.ret = u(env.frame.ret, v)
        env.dead = true
        []
      when Prism::NextNode
        vals = (node.arguments&.arguments || []).map { ev(_1, env) }
        @next_acc[-1] = u(@next_acc[-1], vals.first || t("Nil")) if @next_acc&.any?
        env.dead = true
        []
      when Prism::BreakNode
        (node.arguments&.arguments || []).each { ev(_1, env) }
        env.dead = true
        []
      when Prism::YieldNode
        args = (node.arguments&.arguments || []).map { ev(_1, env) }
        call_block(env.frame.block, args)
      when Prism::CallNode then call(node, env)
      when Prism::InstanceVariableReadNode
        fa = target_of(node, env)
        call_builtin(fa.getter, [subject(env, fa)], nil, node)
      when Prism::InstanceVariableWriteNode
        fa = target_of(node, env)
        recv = subject(env, fa)
        call_builtin(fa.setter, [recv, ev(node.value, env)], nil, node)
      when Prism::InstanceVariableOperatorWriteNode
        fa = target_of(node, env)
        recv = subject(env, fa)
        cur = call_builtin(fa.getter, [recv], nil, node)
        call_builtin(fa.setter, [recv, binop(node, node.binary_operator.to_s, cur, ev(node.value, env))], nil, node)
      else ev_ext(node, env)
      end
    end

    def target_of(node, env) = @program.calls.fetch(node).fetch(env.frame.fn&.namespace)

    def subject(env, fa)
      env = env.parent while env.parent
      env.vars[fa.param] || t("Nil")
    end

    # Writes from inside a block to an outer variable are weak (the block may run zero or more times).
    def assign(env, depth, name, ty)
      scope = env.up(depth)
      scope.vars[name] = depth.zero? ? ty : u(scope.vars[name] || t("Nil"), ty)
      ty
    end

    # Paths that ended in return/next/break do not reach the join point.
    def join_into(env, a, b)
      live = [a, b].reject(&:dead)
      if live.empty?
        env.dead = true
        live = [a, b]
      end
      (a.vars.keys | b.vars.keys).each do |k|
        env.vars[k] = u(*live.map { _1.vars[k] || t("Nil") })
      end
    end

    def branch(env, pred, then_node, else_node)
      ev(pred, env)
      e1 = env.dup_level
      e2 = env.dup_level
      narrow(e1, pred, true)
      narrow(e2, pred, false)
      r = u(ev(then_node, e1), ev(else_node, e2))
      join_into(env, e1, e2)
      r
    end

    def loop_node(node, env)
      MAX_LOOP_ITER.times do
        before = env.chain_snapshot
        ev(node.predicate, env)
        body = env.dup_level
        narrow(body, node.predicate, node.is_a?(Prism::WhileNode))
        ev(node.statements, body)
        body.dead = false # break/next leave the iteration, not the loop
        join_into(env, env.dup_level, body)
        return t("Nil") if env.chain_snapshot == before
      end
      env.vars.transform_values! { unknown("loop did not converge") }
      t("Nil")
    end

    # Narrows a local variable's type on the path where `pred` is truthy (or falsy).
    # Forms: `x`, `x != nil`, `x == nil`, `a && b`, `a || b`, parentheses. Field reads are never narrowed
    # (values are mutable, so another alias may change the field between the test and the use).
    def narrow(env, pred, truthy)
      return unless @narrow
      case pred
      when Prism::ParenthesesNode
        body = pred.body
        narrow(env, body.body.last, truthy) if body.is_a?(Prism::StatementsNode) && body.body.size == 1
      when Prism::AndNode
        if truthy
          narrow(env, pred.left, true)
          narrow(env, pred.right, true)
        end
      when Prism::OrNode
        unless truthy
          narrow(env, pred.left, false)
          narrow(env, pred.right, false)
        end
      when Prism::LocalVariableReadNode
        restrict(env, pred, truthy ? :non_nil : :falsy)
      when Prism::MatchPredicateNode
        var = pred.value
        return unless var.is_a?(Prism::LocalVariableReadNode) && var.depth.zero? && env.vars[var.name]
        m, rest = match_atoms(env.vars[var.name], pred.pattern)
        env.vars[var.name] = u(*(truthy ? m : rest).map { [_1] })
      when Prism::CallNode
        return unless %i[== !=].include?(pred.name) && pred.call_operator_loc.nil? && pred.arguments&.arguments&.size == 1
        l = pred.receiver
        r = pred.arguments.arguments.first
        var = [l, r].find { _1.is_a?(Prism::LocalVariableReadNode) }
        return unless var && [l, r].any?(Prism::NilNode)
        is_nil = (pred.name == :==) == truthy
        restrict(env, var, is_nil ? :nil : :non_nil)
      end
    end

    # [atoms that may match the pattern, atoms that may not]
    def match_atoms(ty, pat)
      case pat
      when Prism::ConstantReadNode
        name = pat.name.to_s
        ty.partition { |a| name == "Record" ? a.is_a?(Array) && a[0] == :record : atom_type_name(a) == name }
      when Prism::NilNode then ty.partition { nil_atom?(_1) }
      when Prism::AlternationPatternNode
        m1, r1 = match_atoms(ty, pat.left)
        m2, r2 = match_atoms(r1, pat.right)
        [m1 + m2, r2]
      when Prism::HashPatternNode
        fields = pat.elements.map { _1.key.unescaped }
        ty.partition { |a| a.is_a?(Array) && a[0] == :record && fields.all? { |f| a[1].any? { _1[0] == f } } }
      else
        # A literal: values of its type may match, but may also differ, so nothing is ruled out.
        lit = { Prism::TrueNode => "Boolean", Prism::FalseNode => "Boolean", Prism::IntegerNode => "Integer", Prism::FloatNode => "Float",
                Prism::StringNode => "String", Prism::SymbolNode => "Symbol" }.fetch(pat.class)
        [ty.select { atom_type_name(_1) == lit }, ty]
      end
    end

    def bind_pattern(env, pat, matched)
      case pat
      when Prism::HashPatternNode
        pat.elements.each do |el|
          f = el.key.unescaped
          target = el.value.is_a?(Prism::ImplicitNode) ? el.value.value : el.value
          assign(env, target.depth, target.name, u(*matched.map { |a| a[1].find { _1[0] == f }[1] }))
        end
      when Prism::AlternationPatternNode
        bind_pattern(env, pat.left, matched)
        bind_pattern(env, pat.right, matched)
      end
    end

    # Each `in` sees what earlier branches left; whatever no branch takes is reported (the set is closed).
    def case_match(node, env)
      v = ev(node.predicate, env)
      var = node.predicate.is_a?(Prism::LocalVariableReadNode) && node.predicate.depth.zero? ? node.predicate : nil
      remaining = v
      results = []
      envs = []
      node.conditions.each do |c|
        m, remaining = match_atoms(remaining, c.pattern)
        next if m.empty? && !v.empty?
        e = env.dup_level
        e.vars[var.name] = u(*m.map { [_1] }) if var
        bind_pattern(e, c.pattern, m)
        results << ev(c.statements, e)
        envs << e
      end
      if node.else_clause
        e = env.dup_level
        e.vars[var.name] = u(*remaining.map { [_1] }) if var
        results << ev(node.else_clause, e)
        envs << e
      elsif !remaining.empty? && !unknown?(v)
        add_check(node, "case/in", "branch", "a matching `in` branch", v, remaining.size == v.size ? :error : :partial, remaining)
      end
      join_many(env, envs) unless envs.empty?
      u(*results)
    end

    def join_many(env, envs)
      live = envs.reject(&:dead)
      if live.empty?
        env.dead = true
        live = envs
      end
      live.flat_map { _1.vars.keys }.uniq.each { |k| env.vars[k] = u(*live.map { _1.vars[k] || t("Nil") }) }
    end

    def restrict(env, var, how)
      return unless var.depth.zero?
      ty = env.vars[var.name] or return
      atoms =
        case how
        when :non_nil then ty - NILS
        when :nil then ty & NILS
        when :falsy then ty & (NILS + ["Boolean"])
        end
      env.vars[var.name] = u(*atoms.map { [_1] })
    end

    def match_record(node, env)
      v = ev(node.value, env)
      node.pattern.elements.each do |el|
        field = el.key.unescaped
        target = el.value.is_a?(Prism::ImplicitNode) ? el.value.value : el.value
        has = v.select { |a| a.is_a?(Array) && a[0] == :record && a[1].any? { _1[0] == field } }
        failing = v - has
        verdict = unknown?(v) ? :unknown : (failing.empty? ? :proven : (has.empty? ? :error : :partial))
        add_check(el, "pattern", field, "Record with #{field}", v, verdict, failing) unless v.empty?
        ty = unknown?(v) ? unknown("pattern") : u(*has.map { |a| a[1].find { _1[0] == field }[1] })
        assign(env, target.depth, target.name, ty)
      end
      t("Nil")
    end

    def multi_write(node, env)
      v = ev(node.value, env)
      n = node.lefts.size
      tuples = v.select { _1.is_a?(Array) && _1[0] == :tuple && _1[1].size == n }
      record(node, "multiple assignment", 1, "Tuple", v)
      node.lefts.each_with_index do |target, i|
        ty = unknown?(v) ? unknown("destructure") : u(*tuples.map { _1[1][i] })
        assign(env, target.depth, target.name, ty)
      end
      v
    end

    def call(node, env)
      target = target_of(node, env)
      return typer_raise(node, env) if target == :raise
      if target == :binary_op
        return binop(node, node.name.to_s, ev(node.receiver, env), ev(node.arguments.arguments.first, env))
      end

      if target.is_a?(IndexCall)
        keys = node.arguments.arguments
        recv = ev(node.receiver, env)
        args = keys.map { ev(_1, env) }
        return index_get(node, recv, args[0], keys[0]) if target.builtin.name == "[]"
        return index_set(node, recv, args[0], keys[0], args[1])
      end
      if target.is_a?(Builtin) && target.namespace == "Index"
        keys = node.arguments.arguments
        args = keys.map { ev(_1, env) }
        return index_get(node, args[0], args[1], keys[1]) if target.name == "[]"
        return index_set(node, args[0], args[1], keys[1], args[2])
      end

      args = (node.arguments&.arguments || []).map { ev(_1, env) }
      blk = node.block && BlockCtx.new(node.block, @program.blocks.fetch(node.block), env)
      case target
      when UserFunction
        @callers.push(node.location.start_line)
        begin
          call_user(target, args, blk)
        ensure
          @callers.pop
        end
      when Builtin then call_builtin(target, args, blk, node)
      end
    end

    def call_user(fn, args, blk)
      @instantiated[fn] = true
      if fn.yields
        return unknown("recursive yield") if @yield_depth[fn] >= MAX_YIELD_DEPTH
        @yield_depth[fn] += 1
        begin
          return run_body(fn, args, blk)
        ensure
          @yield_depth[fn] -= 1
        end
      end

      key = [fn, args]
      if @in_progress[key] || @done[key]
        merge_raised(@raises[key] || {})
        return @returns[key] || []
      end
      @in_progress[key] = true
      @raised.push({})
      r = run_body(fn, args, nil)
      @raises[key] = merge_into(@raises[key] || {}, @raised.pop)
      merge_raised(@raises[key])
      @in_progress.delete(key)
      @done[key] = true
      @returns[key] = u(@returns[key] || [], r)
    end

    # --- exceptions: which user-raised exception types may leave each piece of code ---

    def merge_into(a, b) = a.merge(b) { |_, x, y| (x + y).uniq }
    def merge_raised(h) = @raised[-1] = merge_into(@raised[-1], h)
    def struct_type(name) = @program.struct_types[name]

    def raise_types(node, env)
      nodes = node.arguments&.arguments || []
      case nodes.size
      when 0 then @handled.last || []
      when 2 then [nodes[0].slice]
      else
        v = ev(nodes[0], env)
        v.filter_map { |a| a == "String" ? "RuntimeError" : (a.is_a?(String) && struct_type(a)&.exception ? a : nil) }
      end
    end

    def typer_raise(node, env)
      (node.arguments&.arguments || []).drop((node.arguments&.arguments || []).size == 2 ? 1 : 0).each { ev(_1, env) }
      raise_types(node, env).each { merge_raised(_1 => [node]) }
      env.dead = true
      []
    end

    # Exception types that only `raise` produces; built-in operations may raise the other kinds anywhere.
    def user_raised?(name) = name == "RuntimeError" || !Resolver::BUILTIN_EXCEPTIONS.include?(name)

    def typer_begin(node, env)
      @raised.push({})
      body_env = env.dup_level
      result = ev(node.statements, body_env)
      raised = @raised.pop
      envs = [body_env]
      results = [result]
      clause = node.rescue_clause
      while clause
        names = clause.exceptions.map(&:slice)
        if names.empty?
          caught = raised.keys + Resolver::BUILTIN_EXCEPTIONS
        else
          names.each do |n|
            next if !user_raised?(n) || raised.key?(n)
            add_check(clause, "rescue", n, "raised in the begin body", [], :error, [n])
          end
          caught = names
        end
        e = env.dup_level
        join_into(e, e.dup_level, body_env)
        if clause.reference
          ty = u(*caught.uniq.map { [_1] })
          assign(e, clause.reference.depth, clause.reference.name, ty)
        end
        # A bare raise in the clause re-raises what was caught; only explicitly raised types are tracked.
        @handled.push(caught.select { raised.key?(_1) })
        results << ev(clause.statements, e)
        @handled.pop
        envs << e
        raised = raised.reject { |n, _| names.empty? || names.include?(n) }
        clause = clause.subsequent
      end
      merge_raised(raised)
      if node.else_clause
        results[0] = ev(node.else_clause, body_env)
      end
      join_many(env, envs)
      ev(node.ensure_clause.statements, env) if node.ensure_clause
      u(*results)
    end

    def typer_rescue_modifier(node, env)
      @raised.push({})
      r = ev(node.expression, env)
      @raised.pop
      u(r, ev(node.rescue_expression, env))
    end

    def run_body(fn, args, blk)
      frame = Frame.new(fn, [], blk)
      env = Env.new(nil, frame)
      fn.params.zip(args) { |name, ty| env.vars[name.to_sym] = ty }
      u(ev(fn.body, env), frame.ret)
    end

    def call_block(blk, args)
      return unknown("no block") unless blk
      params = blk.params
      if params.size > 1 && args.size == 1
        a = args.first
        return unknown("block destructure") if unknown?(a)
        tuples = a.select { _1.is_a?(Array) && _1[0] == :tuple && _1[1].size == params.size }
        args = params.each_index.map { |i| u(*tuples.map { _1[1][i] }) } if tuples.size == a.size
      end
      (@next_acc ||= []).push([])
      result = []
      MAX_LOOP_ITER.times do
        before = blk.env.chain_snapshot
        env = Env.new(blk.env, blk.env.frame)
        params.each_with_index { |name, i| env.vars[name.to_sym] = args[i] || t("Nil") }
        result = u(result, ev(blk.node.body, env))
        break if blk.env.chain_snapshot == before
      end
      u(result, @next_acc.pop)
    end

    # Index.[]: a miss gives nil for Array and String; a Tuple has a fixed length, so a literal index
    # selects one position and any other index gives the union of all positions.
    def index_get(node, recv, key, key_node)
      return [] if recv.empty? || key.empty?
      return unknown("index") if unknown?(recv) || unknown?(key)
      lit = key_node.is_a?(Prism::IntegerNode) ? key_node.value : nil
      results = []
      failing = []
      recv.each do |a|
        if (ext = index_get_ext(node, a, key))
          results << ext
          next
        end
        unless key == ["Integer"] && (a == "String" || (a.is_a?(Array) && %i[array tuple].include?(a[0])))
          failing << a
          next
        end
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
      add_check(node, "Index.[]", "pair", "(Array|String|Tuple, Integer)", recv, verdict, failing)
      u(*results)
    end

    def index_set(node, recv, key, key_node, val)
      return [] if recv.empty? || key.empty? || val.empty?
      lit = key_node.is_a?(Prism::IntegerNode) ? key_node.value : nil
      recv.each do |a|
        next unless a.is_a?(Array)
        if a[0] == :hash
          s = hash_sites[a[1]]
          s.key = u(s.key, key)
          s.val = u(s.val, val)
        elsif a[0] == :array
          write_elems([a], [val], node, "Index.[]=")
        elsif a[0] == :tuple
          want = lit && (-a[1].size...a[1].size).cover?(lit) ? a[1][lit] : u(*a[1])
          record(node, "Index.[]=", "value", want.map { atom_type_name(_1) }, val)
        end
      end
      bad = recv.reject { |a| a.is_a?(Array) && %i[array tuple hash].include?(a[0]) }
      verdict = unknown?(recv) ? :unknown : (bad.empty? ? :proven : (bad.size == recv.size ? :error : :partial))
      add_check(node, "Index.[]=", "pair", "(Array|Tuple, Integer)", recv, verdict, bad)
      val
    end

    def binop(node, op, a, b)
      return [] if a.empty? || b.empty?
      if unknown?(a) || unknown?(b)
        add_check(node, "BinaryOp.#{op}", "pair", "table row", u(a, b), :unknown)
        return unknown("operand")
      end
      rows = @registry.binary_ops[op]
      results = []
      hits = 0
      pairs = a.product(b)
      failing = []
      pairs.each do |x, y|
        key = [x, y].map { atom_type_name(_1) }
        if %w[== !=].include?(op) && key.include?("Nil")
          hits += 1
          results << t("Boolean")
          next
        end
        unless rows.key?(key)
          failing << [x, y]
          next
        end
        hits += 1
        results << binop_result(op, *key)
      end
      verdict = hits == pairs.size ? :proven : (hits.zero? ? :error : :partial)
      actual = pairs.map { |x, y| tuple([[x].freeze, [y].freeze]) }
      add_check(node, "BinaryOp.#{op}", "pair", "table row", u(*actual), verdict, failing)
      u(*results)
    end

    # Result types of the BinaryOp rows (Ruby's numeric tower).
    def binop_result(op, t1, t2)
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
      args.each_with_index { |a, i| record(node, fn.full_name, i + 1, fn.param_type(i), a) }
      return [] if args.any?(&:empty?)

      ns = fn.namespace
      name = fn.name
      if (dt = @program.struct_types[ns]) && name != "[]"
        return data_op(dt, name, args, node)
      end
      if (r = constructor_ext(ns, name, args, node))
        return r
      end
      if name == "[]"
        if ns == "Array"
          return site_for(node, init: u(*args))
        end
        return site_for(node, declared: ns).tap { |ty| write_elems(ty, args, node, "#{ns}[]") }
      end
      if %w[Integer Float String].include?(ns) && @registry.binary_ops[name]&.any?
        return binop_result(name, *fn.params) if fn.params.size == 2 && fn.params.all? { _1.is_a?(String) }
      end
      builtin_result(fn.full_name, args, blk, node)
    end

    def data_op(dt, name, args, node)
      case name
      when "new"
        dt.fields.zip(args) { |f, a| field_write(dt.name, f, a, node) }
        t(dt.name)
      when /\Aget_(.+)\z/ then @fields[dt.name][$1] || []
      when /\Aset_(.+)\z/
        field_write(dt.name, $1, args[1], node)
        args[1]
      end
    end

    def new_site(node, label, elem) = site_for(node, label, init: elem).tap { |ty| write_elems(ty, [elem], node, "") }

    def builtin_result(name, args, blk, node)
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
      when "Array.at", "Array.first", "Array.last", "Array.pop", "Array.shift", "Array.min", "Array.max"
        u(elem_of(a0), t("Nil"))
      when "Array.fetch" then elem_of(a0)
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
      when "Array.sum"
        e = elem_of(a0)
        e = call_block(blk, [e]) if blk && !e.empty?
        record(node, "Array.sum", "elem", Stdlib::NUMERIC, e)
        e.empty? ? t("Integer") : u(*e.select { Stdlib::NUMERIC.include?(_1) }.then { _1.empty? ? [t("Integer")] : [_1] })
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
      else unknown("no signature for #{name}")
      end
    end
  end
end

module Sake
  class Typer
    def summary
      counts = Hash.new(0)
      @checks.each_value { counts[_1.verdict] += 1 }
      counts
    end

    def report
      out = +""
      out << "passes: #{@passes}\n"
      out << "checks: #{%i[proven partial error unknown].map { "#{_1}=#{summary[_1]}" }.join(" ")}\n"
      @checks.values.sort_by { [_1.line, _1.op] }.each do |c|
        next if c.verdict == :proven
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
