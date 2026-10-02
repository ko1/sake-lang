# frozen_string_literal: true

module Sake
  # The typer's evaluation of SakeAST. Checks, sites and results are keyed by each node's Prism origin.
  class Typer
    include AST

    # The variables of a function (own = nil: every slot it reaches is its own) or of a block run
    # (own = the block's parameters and locals; other slots belong to the enclosing levels). A block run's
    # vars may also hold an enclosing variable narrowed (or assigned) on this path only.
    class Env
      attr_reader :vars, :parent, :frame, :own
      attr_accessor :dead # control left via return/next/break; this path does not fall through

      def initialize(parent, frame, own = nil, vars = {})
        @parent = parent
        @frame = frame
        @own = own
        @vars = vars
      end

      def owns?(slot) = @own.nil? || @own.include?(slot)

      def level(slot)
        e = self
        e = e.parent until e.owns?(slot)
        e
      end

      def lookup(slot)
        e = self
        until e.owns?(slot)
          return e.vars[slot] if e.vars.key?(slot)
          e = e.parent
        end
        e.vars[slot]
      end

      # A variable's type on this path when a branch did not touch it.
      def outside(slot) = (owns?(slot) ? nil : parent.lookup(slot)) || ["Nil"].freeze

      def dup_level = Env.new(@parent, @frame, @own, @vars.dup)

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

    LIT_TYPES = { Integer => "Integer", Float => "Float", Rational => "Rational", Complex => "Complex",
                  Symbol => "Symbol", Regexp => "Regexp", TrueClass => "Boolean", FalseClass => "Boolean",
                  NilClass => "Nil" }.freeze

    def ev(n, env)
      case n
      when Lit then n.value.is_a?(Symbol) ? [[:sym, n.value.to_s]].freeze : t(LIT_TYPES.fetch(n.value.class))
      when Str then t("String")
      when Seq
        r = t("Nil")
        n.body.each { r = ev(_1, env) }
        r
      when LVarGet then env.lookup(n.slot) || t("Nil")
      when LVarSet then assign(env, n.slot, ev(n.value, env))
      when MultiWrite then multi_write(n, env)
      when IndexUpdate then index_update(n, env)
      when If then branch(env, n.cond, n.then_, n.else_)
      when While then loop_node(n, env)
      when And, Or
        return or_assign(n, env) if n.origin.is_a?(Prism::LocalVariableOrWriteNode)
        l = ev(n.left, env)
        right_env = env.dup_level
        narrow(right_env, n.left, n.is_a?(And))
        r = ev(n.right, right_env)
        join_into(env, env.dup_level, right_env)
        # `a && b` yields a only when a is falsy; `a || b` yields a only when a is truthy.
        left = n.is_a?(And) ? l & (NILS + ["Boolean"]) : l - NILS
        u(*left.map { [_1] }, r)
      when MakeTuple then tuple(n.elems.map { ev(_1, env) })
      when MakeRecord then record_type(n.keys.zip(n.values.map { ev(_1, env) }))
      when MakePairs then [[:pairs, n.keys.zip(n.values).map { |k, v| [ev(k, env), ev(v, env)] }]].freeze
      when MakeRange
        ends = u(ev(n.left, env), ev(n.right, env))
        [[:range, u(*(ends - ["Nil"]).map { [_1] })]].freeze
      when Interp, MakeRegexp
        n.parts.each { ev(_1, env) }
        t(n.is_a?(Interp) ? "String" : "Regexp")
      when ToS
        v = ev(n.value, env)
        show_types(v, :to_s, n.origin)
        t("String")
      when ToSym
        ev(n.value, env)
        t("Symbol")
      when MatchRecord then match_record(n, env)
      when Begin then typer_begin(n, env)
      when RescueMod then typer_rescue_modifier(n, env)
      when Retry then []
      when MatchP
        m, = match_atoms(ev(n.value, env), n.pattern)
        bind_pattern(env, n.pattern, m)
        t("Boolean")
      when CaseIn then case_match(n, env)
      when Return
        env.frame.ret = u(env.frame.ret, ev(n.value, env))
        env.dead = true
        []
      when Next
        v = ev(n.value, env)
        @next_acc[-1] = u(@next_acc[-1], v) if @next_acc&.any? && !loop_jump(env)
        env.dead = true
        []
      when Break
        v = ev(n.value, env)
        if n.target == :block
          b = (@running_blocks || []).last
          b.breaks = u(b.breaks, v) if b
        else
          loop_jump(env)
        end
        env.dead = true
        []
      when Yield then call_block(env.frame.block, n.args.map { ev(_1, env) })
      when CallBuiltin, CallUser, CallDispatch, CallUnion then call(n, env)
      when BinOp then binop(n.origin, n.op, ev(n.left, env), ev(n.right, env))
      when UnOp then unop(n.origin, n.op, ev(n.value, env))
      when IsNil then binop(n.origin, n.negate ? "!=" : "==", ev(n.value, env), t("Nil"))
      when IndexGet
        r = ev(n.recv, env)
        k = ev(n.key, env)
        index_get(n.origin, r, k, lit_of(n.key), n.extra && ev(n.extra, env))
      when IndexSet
        r = ev(n.recv, env)
        k = ev(n.key, env)
        e = n.extra && ev(n.extra, env)
        index_set(n.origin, r, k, lit_of(n.key), ev(n.value, env), e)
      when FieldGet, FieldSet
        nodes = n.is_a?(FieldSet) ? [n.subject, n.value] : [n.subject]
        args = nodes.map { ev(_1, env) }
        # Written as `T.get_x(s)`, it is a call like any other; `@x` reads the function's subject.
        n.origin.is_a?(Prism::CallNode) ? builtin_call(n, n.fn, nodes, args, nil, env) : call_builtin(n.fn, args, nil, n.origin)
      when Raise, ReRaise then typer_raise(n, env)
      when Unresolved then unknown("unresolved")
      else unknown("node #{n.class}")
      end
    end

    def lit_of(n) = n.is_a?(Lit) && n.value.is_a?(Integer) ? n.value : nil

    # Writes from inside a block to an outer variable are weak (the block may run zero or more times).
    def assign(env, slot, ty)
      lv = env.level(slot)
      return lv.vars[slot] = ty if lv.equal?(env)
      e = env
      until e.equal?(lv) # narrowings of the enclosing levels no longer hold
        e.vars.delete(slot)
        e = e.parent
      end
      lv.vars[slot] = u(lv.vars[slot] || t("Nil"), ty)
      env.vars[slot] = ty
    end

    # `x ||= v`
    def or_assign(n, env)
      slot = n.left.slot
      cur = env.lookup(slot) || t("Nil")
      assign(env, slot, u(*(cur - NILS - ["Boolean"]).map { [_1] }, ev(n.right.value, env)))
    end

    # `x[k] OP= v` / `x[k] ||= v`
    def index_update(n, env)
      recv = ev(n.recv, env)
      key = ev(n.key, env)
      lit = lit_of(n.key)
      cur = index_get(n.origin, recv, key, lit)
      val =
        if n.op == "||"
          u(*(cur - NILS - ["Boolean"]).map { [_1] }, ev(n.value, env))
        else
          binop(n.origin, n.op, cur, ev(n.value, env))
        end
      index_set(n.origin, recv, key, lit, val)
    end

    # Paths that ended in return/next/break do not reach the join point.
    def join_into(env, a, b)
      live = [a, b].reject(&:dead)
      if live.empty?
        env.dead = true
        live = [a, b]
      end
      (a.vars.keys | b.vars.keys).each do |k|
        env.vars[k] = u(*live.map { _1.vars.fetch(k) { env.outside(k) } })
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

    # `break` / `next` in a while loop: the variables at that point reach the loop's exit and its next
    # test. Returns false when the innermost target is a block (its `next` ends the block's run).
    def loop_jump(env)
      jumps = (@jumps ||= []).last or return false
      jumps << env.dup_level
      true
    end

    def loop_node(n, env)
      (@jumps ||= []).push(nil) # placeholder, replaced per iteration
      MAX_LOOP_ITER.times do
        before = env.chain_snapshot
        ev(n.cond, env)
        body = env.dup_level
        narrow(body, n.cond, !n.until_)
        @jumps[-1] = []
        ev(n.body, body)
        join_many(env, [env.dup_level, body, *@jumps[-1]])
        env.dead = false # the loop may not run at all
        return t("Nil") if env.chain_snapshot == before
      end
      env.vars.transform_values! { unknown("loop did not converge") }
      t("Nil")
    ensure
      @jumps.pop
    end

    # Narrows a local variable's type on the path where `pred` is truthy (or falsy).
    # Forms: `x`, `x != nil`, `x == nil`, `x in T`, `a && b`, `a || b`. Field reads are never narrowed
    # (values are mutable, so another alias may change the field between the test and the use).
    def narrow(env, pred, truthy)
      return unless @narrow
      case pred
      when And
        if truthy
          narrow(env, pred.left, true)
          narrow(env, pred.right, true)
        end
      when Or
        unless truthy
          narrow(env, pred.left, false)
          narrow(env, pred.right, false)
        end
      when LVarGet then restrict(env, pred.slot, truthy ? :non_nil : :falsy)
      when MatchP
        var = pred.value
        return unless var.is_a?(LVarGet) && (ty = env.lookup(var.slot))
        m, rest = match_atoms(ty, pred.pattern)
        env.vars[var.slot] = u(*(truthy ? m : rest).map { [_1] })
      when IsNil, BinOp
        return if pred.is_a?(BinOp) && !%w[== !=].include?(pred.op)
        return if pred.origin.receiver.is_a?(Prism::ConstantReadNode) # `Kernel.==(x, nil)` is not a test form
        if pred.is_a?(IsNil)
          var = pred.value
          is_nil = !pred.negate == truthy
        else
          var = [pred.left, pred.right].find { _1.is_a?(LVarGet) }
          return unless [pred.left, pred.right].any? { _1.is_a?(Lit) && _1.value.nil? }
          is_nil = (pred.op == "==") == truthy
        end
        restrict(env, var.slot, is_nil ? :nil : :non_nil) if var.is_a?(LVarGet)
      end
    end

    # [atoms that may match the pattern, atoms that may not]. An unknown atom may be anything: it goes
    # to both sides.
    def match_atoms(ty, pat)
      unk = ty.select { _1.is_a?(Array) && _1[0] == :unknown }
      return [unk, unk] if unk.size == ty.size && !ty.empty?
      m, r = match_known(ty - unk, pat)
      [m + unk, r + unk]
    end

    def match_known(ty, pat)
      case pat
      when PType
        name = pat.name
        ty.partition { |a| name == "Record" ? a.is_a?(Array) && a[0] == :record : atom_type_name(a) == name }
      when PAlt
        m1, r1 = match_atoms(ty, pat.left)
        m2, r2 = match_atoms(r1, pat.right)
        [m1 + m2, r2]
      when PRecord
        ty.partition { |a| a.is_a?(Array) && a[0] == :record && pat.keys.all? { |f| a[1].any? { _1[0] == f } } }
      when PValue
        v = pat.value
        return ty.partition { nil_atom?(_1) } if v.is_a?(Lit) && v.value.nil?
        # A Symbol literal decides a Symbol-literal atom exactly; other literals rule nothing out.
        if v.is_a?(Lit) && v.value.is_a?(Symbol)
          exact = [:sym, v.value.to_s]
          return [ty.select { _1 == exact || _1 == "Symbol" }, ty - [exact]]
        end
        lit = v.is_a?(Str) ? "String" : LIT_TYPES.fetch(v.value.class)
        [ty.select { atom_type_name(_1) == lit }, ty]
      end
    end

    def bind_pattern(env, pat, matched)
      case pat
      when PRecord
        pat.keys.zip(pat.slots) do |f, s|
          assign(env, s, unknown?(matched) ? unknown("pattern") : u(*matched.map { |a| a[1].find { _1[0] == f }[1] }))
        end
      when PAlt
        bind_pattern(env, pat.left, matched)
        bind_pattern(env, pat.right, matched)
      end
    end

    def alternatives(pat) = pat.is_a?(PAlt) ? [*alternatives(pat.left), *alternatives(pat.right)] : [pat]

    # Each `in` sees what earlier branches left; whatever no branch takes is reported (the set is closed).
    def case_match(n, env)
      v = ev(n.subject, env)
      var = n.subject.is_a?(LVarGet) ? n.subject.slot : nil
      remaining = v
      results = []
      envs = []
      n.clauses.each do |pat, body|
        m, remaining = match_atoms(remaining, pat)
        next if m.empty? && !v.empty?
        e = env.dup_level
        e.vars[var] = u(*m.map { [_1] }) if var
        bind_pattern(e, pat, m)
        results << ev(body, e)
        envs << e
      end
      if n.else_
        e = env.dup_level
        e.vars[var] = u(*remaining.map { [_1] }) if var
        results << ev(n.else_, e)
        envs << e
      elsif !remaining.empty? && !unknown?(v)
        # Values a literal pattern may leave (some String, any Symbol not written as a literal) are not
        # a type problem: the type's set of values is open. Both true and false cover Boolean.
        alts = n.clauses.flat_map { |pat, _| alternatives(pat) }
        lits = alts.filter_map { |pat| pat.is_a?(PValue) && pat.value.is_a?(Lit) ? pat.value.value : nil }
        lits += alts.filter_map { |pat| pat.is_a?(PValue) && pat.value.is_a?(Str) ? "" : nil }
        remaining -= ["Boolean"] if lits.include?(true) && lits.include?(false)
        lit_types = lits.map { LIT_TYPES.fetch(_1.class) { "String" } }
        open, closed = remaining.partition { _1.is_a?(String) && lit_types.include?(atom_type_name(_1)) }
        unless closed.empty?
          add_check(n.origin, "case/in", "branch", "a matching `in` branch", v, closed.size == v.size ? :error : :partial, closed)
        end
        add_check(n.origin, "case/in", "value", "a matching `in` branch", v, :partial, open) unless open.empty?
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
      live.flat_map { _1.vars.keys }.uniq.each { |k| env.vars[k] = u(*live.map { _1.vars.fetch(k) { env.outside(k) } }) }
    end

    def restrict(env, slot, how)
      ty = env.lookup(slot) or return
      atoms =
        case how
        when :non_nil then ty - NILS
        when :nil then ty & NILS
        when :falsy then ty & (NILS + ["Boolean"])
        end
      env.vars[slot] = u(*atoms.map { [_1] })
    end

    def match_record(n, env)
      v = ev(n.value, env)
      elements = n.origin.pattern.elements
      n.keys.each_with_index do |field, i|
        has = v.select { |a| a.is_a?(Array) && a[0] == :record && a[1].any? { _1[0] == field } }
        failing = v - has
        verdict = unknown?(v) ? :unknown : (failing.empty? ? :proven : (has.empty? ? :error : :partial))
        add_check(elements[i], "pattern", field, "Record with #{field}", v, verdict, failing) unless v.empty?
        ty = unknown?(v) ? unknown("pattern") : u(*has.map { |a| a[1].find { _1[0] == field }[1] })
        assign(env, n.slots[i], ty)
      end
      t("Nil")
    end

    def multi_write(n, env)
      places = n.targets.map do |t|
        case t
        when TIndex then [ev(t.recv, env), ev(t.key, env)]
        when TField then ev(t.subject, env)
        end
      end
      v = ev(n.value, env)
      record(n.origin, "multiple assignment", 1, %w[Tuple Array], v)
      ri = n.targets.index { _1.is_a?(TRest) }
      spread = ri ? spread_rest_types(v, ri, n.targets.size - ri - 1, n.targets[ri].origin) : spread_types(v, n.targets.size)
      n.targets.each_with_index do |t, i|
        ty = unknown?(v) ? unknown("destructure") : spread[i]
        case t
        when TLocal then assign(env, t.slot, ty)
        when TRest then assign(env, t.slot, ty) if t.slot
        when TIndex then index_set(t.origin, places[i][0], places[i][1], lit_of(t.key), ty)
        when TField then call_builtin(t.fn, [places[i], ty], nil, t.origin)
        end
      end
      v
    end

    # The types of n variables taken from a Tuple or an Array (as Ruby: missing elements are nil). A Tuple's
    # missing positions are nil for certain; an Array's elements may be missing, like `x[k]`'s (IndexNil).
    def spread_types(v, n)
      tuples = v.select { _1.is_a?(Array) && _1[0] == :tuple }
      arrays = v.select { _1.is_a?(Array) && _1[0] == :array }
      from_arrays = arrays.empty? ? [] : u(elem_of(arrays), t("IndexNil"))
      Array.new(n) { |i| u(*tuples.map { |tp| tp[1][i] || t("Nil") }, from_arrays) }
    end

    # `a, *r, z = v`: as spread_types, with r an Array (a site at node) of the elements between.
    def spread_rest_types(v, nleft, npost, node)
      tuples = v.select { _1.is_a?(Array) && _1[0] == :tuple }.map { _1[1] }
      arrays = v.select { _1.is_a?(Array) && _1[0] == :array }
      from_arrays = arrays.empty? ? [] : u(elem_of(arrays), t("IndexNil"))
      lefts = Array.new(nleft) { |i| u(*tuples.map { |tp| tp[i] || t("Nil") }, from_arrays) }
      posts = Array.new(npost) do |j|
        u(*tuples.map { |tp| tp[[nleft, tp.size - npost].max + j] || t("Nil") }, from_arrays)
      end
      middle = u(*tuples.flat_map { |tp| tp[nleft...[nleft, tp.size - npost].max] || [] }, elem_of(arrays))
      [*lefts, new_site(node, "", middle), *posts]
    end

    # The argument types, a splat's spread: a Tuple's positions, or one argument standing for an Array's
    # elements (none when it has no element types).
    def arg_types(nodes, env)
      nodes.flat_map do |a|
        next [ev(a, env)] unless a.is_a?(Splat)
        v = ev(a.value, env)
        record(a.origin, "splat", "value", %w[Tuple Array], v)
        next [v] if unknown?(v)
        tuples = v.select { _1.is_a?(Array) && _1[0] == :tuple }.map { _1[1] }
        arrays = v.select { _1.is_a?(Array) && _1[0] == :array }
        next tuples[0].each_index.map { |i| u(*tuples.map { _1[i] }) } if arrays.empty? && tuples.map(&:size).uniq.size == 1
        elems = u(*tuples.flatten(1), elem_of(arrays))
        elems.empty? ? [] : [elems]
      end
    end

    def call(n, env)
      o = n.origin
      if n.is_a?(CallBuiltin) && %w[[] []=].include?(n.fn.name)
        xs = n.args.map { ev(_1, env) }
        lit = lit_of(n.args[1])
        return n.fn.name == "[]" ? index_get(o, xs[0], xs[1], lit) : index_set(o, xs[0], xs[1], lit, xs[2])
      end
      args = arg_types(n.args, env)
      blk = n.block && BlockCtx.new(n.block, n.block.params, env, [])
      r = call_with(n, env, args, blk)
      return r unless blk && !blk.breaks.empty?
      r = u(r, blk.breaks)
      (@results ||= {}.compare_by_identity)[o] = u(@results[o] || [], r) if n.is_a?(CallBuiltin) # for crosscheck
      r
    end

    def call_with(n, env, args, blk)
      o = n.origin
      case n
      when CallDispatch
        d = n.dispatch
        record(o, "#{d.module}.#{d.name}", "subject", d.table.keys, args[0])
        rs = args[0].filter_map do |a|
          fn = d.table[atom_type_name(a)] or next
          if fn.abstract # the type includes the module but does not define the function
            add_check(o, "#{d.module}.#{d.name}", "required", "a definition", [a].freeze, :error, [a])
            next
          end
          @callers.push(o.location.start_line)
          begin
            call_user(fn, [[a].freeze, *args.drop(1)], blk)
          ensure
            @callers.pop
          end
        end
        u(*rs)
      when CallUnion
        un = n.union
        record(o, un.full_name, "subject", un.types, args[0])
        rs = args[0].filter_map do |a|
          fn = un.table[atom_type_name(a)] or next
          xs = [[a].freeze, *args.drop(1)]
          next call_builtin(fn, xs, blk, o) unless fn.is_a?(UserFunction)
          @callers.push(o.location.start_line)
          begin
            call_user(fn, xs, blk)
          ensure
            @callers.pop
          end
        end
        u(*rs)
      when CallUser
        @callers.push(o.location.start_line)
        begin
          call_user(n.fn, args, blk)
        ensure
          @callers.pop
        end
      when CallBuiltin then builtin_call(n, n.fn, n.args.take_while { !_1.is_a?(Splat) }, args, blk, env)
      end
    end

    def builtin_call(n, fn, arg_nodes, args, blk, env)
      r = call_builtin(fn, args, blk, n.origin)
      (@results ||= {}.compare_by_identity)[n.origin] = u((@results[n.origin] || []), r) # for crosscheck
      narrow_by_call(env, arg_nodes, args.each_index.map { fn.param_type(_1) }) unless fn.name == CTOR
      r
    end

    # A built-in checks its arguments at run time, so after it returns, a local variable passed to it
    # holds a type it accepts (none, when the call always fails).
    def narrow_by_call(env, arg_nodes, wants)
      return unless @narrow
      arg_nodes.each_with_index do |arg, i|
        want = wants[i]
        next if want.nil? || want == "Any"
        next unless arg.is_a?(LVarGet) && (ty = env.lookup(arg.slot))
        next if unknown?(ty)
        kept = ty.select { |a| Array(want).any? { atom_matches?(a, _1) } }
        env.vars[arg.slot] = u(*kept.map { [_1] })
      end
    end

    def typer_raise(n, env)
      types =
        if n.is_a?(ReRaise)
          @handled.last || []
        else
          v = ev(n.args[0], env)
          n.type ? [n.type] : v.filter_map { |a| a == "String" ? "RuntimeError" : (a.is_a?(String) && struct_type(a)&.exception ? a : nil) }
        end
      types.each { merge_raised(_1 => [n.origin]) }
      env.dead = true
      []
    end

    def typer_begin(n, env)
      @raised.push({})
      body_env = env.dup_level
      result = ev(n.body, body_env)
      raised = @raised.pop
      envs = [body_env]
      results = [result]
      n.rescues.each do |clause|
        names = clause.names
        if names.empty?
          caught = raised.keys + Resolver::BUILTIN_EXCEPTIONS
        else
          names.each do |name|
            next if !user_raised?(name) || raised.key?(name)
            add_check(clause.origin, "rescue", name, "raised in the begin body", [], :error, [name])
          end
          caught = names
        end
        e = env.dup_level
        join_into(e, e.dup_level, body_env)
        assign(e, clause.slot, u(*caught.uniq.map { [_1] })) if clause.slot
        # A bare raise in the clause re-raises what was caught; only explicitly raised types are tracked.
        @handled.push(caught.select { raised.key?(_1) })
        results << ev(clause.body, e)
        @handled.pop
        envs << e
        raised = raised.reject { |name, _| names.empty? || names.include?(name) }
      end
      merge_raised(raised)
      results[0] = ev(n.else_, body_env) if n.else_
      join_many(env, envs)
      ev(n.ensure_, env) if n.ensure_
      u(*results)
    end

    def typer_rescue_modifier(n, env)
      @raised.push({})
      r = ev(n.expr, env)
      @raised.pop
      u(r, ev(n.rescue_, env))
    end

    def run_body(fn, args, blk)
      frame = Frame.new(fn, [], blk)
      env = Env.new(nil, frame)
      fn.params.each_index { |i| env.vars[i] = args[i] }
      u(ev(@ast.functions.fetch(fn).body, env), frame.ret)
    end

    def rest_origin(b) = b.origin.parameters.parameters.rest

    def call_block(blk, args)
      return unknown("no block") unless blk
      params = blk.params
      rest = blk.node.rest
      fixed = params.size - (rest ? 1 : 0)
      spread = false
      if (params.size > 1 || (rest && fixed >= 1)) && args.size == 1
        a = args.first
        return unknown("block destructure") if unknown?(a)
        spread = a.any? { _1.is_a?(Array) && %i[tuple array].include?(_1[0]) }
        args = rest ? spread_rest_types(a, rest, fixed - rest, rest_origin(blk.node)) : spread_types(a, params.size) if spread
      end
      if rest && !spread
        npost = fixed - rest
        post = [rest, args.size - npost].max
        args = [*Array.new(rest) { args[_1] || t("Nil") }, new_site(rest_origin(blk.node), "", u(*args[rest...post] || [])),
                *Array.new(npost) { args[post + _1] || t("Nil") }]
      end
      own = (params + blk.node.locals).to_set
      (@next_acc ||= []).push([])
      (@jumps ||= []).push(false)
      (@running_blocks ||= []).push(blk)
      result = []
      MAX_LOOP_ITER.times do
        before = blk.env.chain_snapshot
        env = Env.new(blk.env, blk.env.frame, own)
        params.each_with_index { |s, i| env.vars[s] = args[i] || t("Nil") }
        result = u(result, ev(blk.node.body, env))
        break if blk.env.chain_snapshot == before
      end
      @jumps.pop
      @running_blocks.pop
      u(result, @next_acc.pop)
    end
  end
end
