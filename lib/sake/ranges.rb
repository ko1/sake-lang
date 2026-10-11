# frozen_string_literal: true

module Sake
  module Rust
    # Value-range analysis for the native backends: which Integer operations cannot overflow and which
    # Array indexes are inside the array, so that their run-time checks can be left out.
    #
    # An abstract interpretation of one instantiation's body. For each Integer variable it keeps lower and
    # upper bounds; a bound is a constant [:c, k] or another variable plus a constant [:s, slot, k]. For
    # each Array variable it keeps lower bounds of the array's length (the same two forms). Conditions
    # refine the facts (`while j <= n` gives j <= n in the body, `return n if n < 2` gives n >= 2 after it),
    # an assignment to a variable drops every bound that mentions it, loops are iterated to a fixed point
    # with widening, and only the final pass of a loop records verdicts. Length facts are used only when no
    # array in the program ever shrinks (Array.pop / Array.shift). Variables assigned inside a block passed
    # to a function can change during any call, so they never get facts.
    class Ranges
      include AST

      MIN = -(2**63)
      MAX = 2**63 - 1
      LEN_MAX = 2**60 # an array this long would not fit in memory
      UNKNOWN = [[].freeze, [].freeze].freeze
      LOOPS = %w[Integer.times Range.each Array.each Array.each_with_index Array.map Array.select Array.filter
                 Array.reject Array.new].freeze

      Env = Struct.new(:int, :len, :dead) do
        def copy = Env.new(int.transform_values { |lo, hi| [lo.dup, hi.dup] }, len.transform_values(&:dup), dead)
      end

      # visited / unsafe: node => {kind => true}. kind: :arith (+ - * and unary -), :div (the divisor of
      # / or % is positive), :plain (also the dividend is not negative), :index (inside the array).
      Result = Struct.new(:visited, :unsafe) do
        def safe?(node, kind) = visited[node]&.[](kind) && !unsafe[node]&.[](kind)
      end

      def initialize(gen, program_shrinks)
        @gen = gen
        @shrinks = program_shrinks
      end

      def analyze(inst)
        @inst = inst
        @visited = {}.compare_by_identity
        @unsafe = {}.compare_by_identity
        @nonfinal = 0
        @ctx = []
        @havoc = closure_assigned(inst.func.body, [], false).to_h { [_1, true] }
        exec(inst.func.body, Env.new({}, {}, false))
        Result.new(@visited, @unsafe)
      end

      # Whether any program text shrinks an array (then no length fact holds).
      def self.shrinks?(ast)
        nodes = [ast.main.body, *ast.functions.values.map(&:body)]
        nodes.any? { shrink_call?(_1) }
      end

      def self.shrink_call?(n)
        return false unless n.is_a?(Struct) && AST::KINDS.value?(n.class)
        return true if n.is_a?(CallBuiltin) && %w[Array.pop Array.shift].include?(n.fn.full_name)
        n.each_pair.any? { |k, v| k != :origin && (v.is_a?(Array) ? v.any? { shrink_call?(_1) } : shrink_call?(v)) }
      end

      private

      def ast_node?(v) = v.is_a?(Struct) && AST::KINDS.value?(v.class)
      def ty(n) = @gen.ty(n, @inst)
      def int?(n) = ty(n) == :int

      def children(n)
        n.each_pair.flat_map { |k, v| k == :origin ? [] : (v.is_a?(Array) ? v.select { ast_node?(_1) } : (ast_node?(v) ? [v] : [])) }
      end

      # Slots assigned inside blocks passed to user functions (inside: within such a block).
      def closure_assigned(n, acc, inside)
        return acc unless ast_node?(n)
        if inside
          case n
          when LVarSet, ArgDefault then acc << n.slot
          when MultiWrite then n.targets.each { acc << _1.slot if _1.respond_to?(:slot) && _1.slot }
          when Block then acc.concat(n.params, n.locals)
          end
        end
        closure = (n.is_a?(CallUser) || n.is_a?(CallDispatch)) && n.block.is_a?(Block)
        children(n).each { closure_assigned(_1, acc, inside || (closure && _1.equal?(n.block))) }
        acc
      end

      def record(node, kind, ok)
        return if @nonfinal.positive?
        (@visited[node] ||= {})[kind] = true
        (@unsafe[node] ||= {})[kind] = true unless ok
      end

      def quiet
        @nonfinal += 1
        yield
      ensure
        @nonfinal -= 1
      end

      # --- bounds ---

      def shift(b, k) = b[0] == :c ? [:c, b[1] + k] : [:s, b[1], b[2] + k]

      def tight(bs, pick)
        cs, ss = bs.partition { _1[0] == :c }
        ss = ss.uniq.reject { @havoc[_1[1]] }.first(8)
        cs.empty? ? ss : [[:c, cs.map(&:last).send(pick)], *ss]
      end

      def norm(lo, hi) = [tight(lo, :max), tight(hi, :min)]

      def bnum(b, env, side, depth)
        return b[1] if b[0] == :c
        return(side == :lo ? MIN : MAX) if depth > 3
        f = env.int[b[1]]
        (f ? fnum(f, env, side, depth + 1) : (side == :lo ? MIN : MAX)) + b[2]
      end

      def fnum(f, env, side, depth = 0)
        lo, hi = f
        side == :lo ? [MIN, *lo.map { bnum(_1, env, :lo, depth) }].max : [MAX, *hi.map { bnum(_1, env, :hi, depth) }].min
      end

      def lt?(h, l, env) = h[0] == :s && l[0] == :s && h[1] == l[1] ? h[2] < l[2] : bnum(h, env, :hi, 0) < bnum(l, env, :lo, 0)

      def without(bs, slot) = bs.reject { _1[0] == :s && _1[1] == slot }

      def kill(env, slot)
        env.int.delete(slot)
        env.len.delete(slot)
        env.int.transform_values! { |lo, hi| [without(lo, slot), without(hi, slot)] }
        env.len.transform_values! { without(_1, slot) }
      end

      def join_fact(f, g)
        lo = (f[0] & g[0]).reject { _1[0] == :c }
        hi = (f[1] & g[1]).reject { _1[0] == :c }
        fl, gl = f[0].find { _1[0] == :c }, g[0].find { _1[0] == :c }
        fh, gh = f[1].find { _1[0] == :c }, g[1].find { _1[0] == :c }
        lo.unshift([:c, [fl[1], gl[1]].min]) if fl && gl
        hi.unshift([:c, [fh[1], gh[1]].max]) if fh && gh
        [lo, hi]
      end

      def join_len(a, b)
        s = (a & b).reject { _1[0] == :c }
        ac, bc = a.find { _1[0] == :c }, b.find { _1[0] == :c }
        ac && bc ? [[:c, [ac[1], bc[1]].min], *s] : s
      end

      def join(envs)
        live = envs.reject(&:dead)
        return Env.new({}, {}, true) if live.empty?
        live.reduce do |a, b|
          int = (a.int.keys & b.int.keys).to_h { [_1, join_fact(a.int[_1], b.int[_1])] }
          len = (a.len.keys & b.len.keys).to_h { [_1, join_len(a.len[_1], b.len[_1])] }
          Env.new(int, len, false)
        end
      end

      # join(old, new), with a constant bound that moved dropped (so a counter's bound does not creep).
      def widen(old, new)
        j = join([old, new])
        return j if old.dead || j.dead
        j.int.each do |s, (lo, hi)|
          o = old.int[s] || UNKNOWN
          lo.reject! { _1[0] == :c && !o[0].include?(_1) }
          hi.reject! { _1[0] == :c && !o[1].include?(_1) }
        end
        j.len.each { |s, ls| ls.reject! { _1[0] == :c && !(old.len[s] || []).include?(_1) } }
        j
      end

      def same_env?(a, b)
        return a.dead == b.dead if a.dead || b.dead
        canon = ->(e) { [e.int.transform_values { |lo, hi| [lo.sort_by(&:to_s), hi.sort_by(&:to_s)] }.sort_by { _1[0] }, e.len.transform_values { _1.sort_by(&:to_s) }.sort_by { _1[0] }] }
        canon[a] == canon[b]
      end

      def replace(env, other)
        env.int = other.int
        env.len = other.len
        env.dead = other.dead
      end

      # --- loops ---

      # Iterates a loop body (the block, given an env, runs one iteration in it) to a fixed point, then runs
      # it once more recording verdicts. Returns [the state at the head, the states at its breaks].
      def run_loop(env, kind)
        ctx = { kind:, conts: [], breaks: [] }
        @ctx.push(ctx)
        head = env.copy
        converged = false
        quiet do
          10.times do
            ctx[:conts].clear
            ctx[:breaks].clear
            b = head.copy
            yield b
            nh = widen(head, join([head, b, *ctx[:conts]]))
            if same_env?(nh, head)
              converged = true
              break
            end
            head = nh
          end
        end
        head = Env.new({}, {}, env.dead) unless converged
        ctx[:conts].clear
        ctx[:breaks].clear
        b = head.copy
        yield b
        [head, ctx[:breaks].dup]
      ensure
        @ctx.pop
      end

      # --- statements ---

      def exec(n, env)
        return if env.dead
        case n
        when Seq then n.body.each { exec(_1, env) }
        when LVarSet then assign(n.slot, n.value, env)
        when If
          iv(n.cond, env)
          et = refine(env.copy, n.cond, true)
          ef = refine(env.copy, n.cond, false)
          exec(n.then_, et)
          exec(n.else_, ef)
          replace(env, join([et, ef]))
        when While
          truth = !n.until_
          head, breaks = run_loop(env, :while) do |b|
            iv(n.cond, b)
            refine(b, n.cond, truth)
            exec(n.body, b)
          end
          replace(env, join([refine(head.copy, n.cond, !truth), *breaks]))
        when Return, Raise
          (n.is_a?(Return) ? [n.value] : n.args).compact.each { iv(_1, env) }
          env.dead = true
        when Retry, ReRaise then env.dead = true
        when Next
          iv(n.value, env) if n.value
          ctx = @ctx.last
          ctx[:conts] << env.copy if ctx && ctx[:kind] != :closure
          env.dead = true
        when Break
          iv(n.value, env) if n.value
          want = n.target == :loop ? :while : :inline
          ctx = @ctx.reverse.find { _1[:kind] == want || _1[:kind] == :closure }
          ctx[:breaks] << env.copy if ctx && ctx[:kind] == want
          env.dead = true
        when CaseIn
          iv(n.subject, env)
          envs = n.clauses.map { |_, body| e = env.copy; exec(body, e); e }
          e = env.copy
          exec(n.else_, e)
          replace(env, join([*envs, e]))
        when MultiWrite
          iv(n.value, env)
          n.targets.each { kill(env, _1.slot) if _1.respond_to?(:slot) && _1.slot }
        when ArgDefault
          iv(n.value, env.copy)
          kill(env, n.slot)
        else iv(n, env)
        end
      end

      def assign(slot, value, env)
        if @havoc[slot]
          iv(value, env)
          kill(env, slot)
          return
        end
        d = @inst.slots[slot]
        if d == :int
          f = iv(value, env)
          kill(env, slot)
          env.int[slot] = norm(without(f[0], slot), without(f[1], slot))
          arr = value.is_a?(CallBuiltin) && %w[Array.length Array.size].include?(value.fn.full_name) && value.args[0]
          (env.len[arr.slot] ||= []) << [:s, slot, 0] if arr.is_a?(LVarGet) && !@havoc[arr.slot] && arr.slot != slot && !@shrinks
        elsif d.is_a?(ArrT) && !@shrinks
          lens = quiet { arr_len(value, env.copy) }
          iv(value, env)
          kill(env, slot)
          env.len[slot] = tight(without(lens, slot), :max)
        else
          iv(value, env)
          kill(env, slot)
        end
      end

      # Lower bounds of the length of the Array that value makes or names.
      def arr_len(value, env)
        case value
        when LVarGet then @havoc[value.slot] ? [] : (env.len[value.slot] || []).dup
        when CallBuiltin
          if value.fn.name == CTOR then [[:c, value.args.size]]
          elsif value.fn.full_name == "Array.new" then iv(value.args[0], env)[0].dup
          else []
          end
        else []
        end
      end

      # --- conditions ---

      NEG = { "<" => ">=", "<=" => ">", ">" => "<=", ">=" => "<", "==" => "!=", "!=" => "==" }.freeze
      FLIP = { "<" => ">", "<=" => ">=", ">" => "<", ">=" => "<=", "==" => "==", "!=" => "!=" }.freeze

      def refine(env, cond, truth)
        return env if env.dead
        quiet do
          case cond
          when BinOp
            if NEG.key?(cond.op) && int?(cond.left) && int?(cond.right)
              op = truth ? cond.op : NEG.fetch(cond.op)
              a = iv(cond.left, env.copy)
              b = iv(cond.right, env.copy)
              constrain(env, cond.left, op, b)
              constrain(env, cond.right, FLIP.fetch(op), a)
            end
          when And
            if truth
              refine(env, cond.left, true)
              refine(env, cond.right, true)
            end
          when Or
            unless truth
              refine(env, cond.left, false)
              refine(env, cond.right, false)
            end
          when If
            refine(env, cond.cond, !truth) if cond.then_.is_a?(Lit) && cond.then_.value == false && cond.else_.is_a?(Lit) && cond.else_.value == true
          end
        end
        env
      end

      def constrain(env, node, op, other)
        return unless node.is_a?(LVarGet) && !@havoc[node.slot]
        s = node.slot
        lo, hi = env.int[s] || UNKNOWN
        lo = lo.dup
        hi = hi.dup
        olo = without(other[0], s)
        ohi = without(other[1], s)
        case op
        when "<" then hi.concat(ohi.map { shift(_1, -1) })
        when "<=" then hi.concat(ohi)
        when ">" then lo.concat(olo.map { shift(_1, 1) })
        when ">=" then lo.concat(olo)
        when "==" then (lo.concat(olo); hi.concat(ohi))
        when "!="
          k = olo.find { _1[0] == :c }
          if k && ohi.include?(k)
            cur = [lo, hi]
            lo << [:c, k[1] + 1] if fnum(cur, env, :lo) == k[1]
            hi << [:c, k[1] - 1] if fnum(cur, env, :hi) == k[1]
          end
        end
        env.int[s] = norm(lo, hi)
        env.dead = true if fnum(env.int[s], env, :lo) > fnum(env.int[s], env, :hi)
      end

      # --- expressions: the facts about an Integer expression's value ---

      def iv(n, env)
        return UNKNOWN if env.dead || !ast_node?(n)
        case n
        when Lit then n.value.is_a?(Integer) ? [[[:c, n.value]], [[:c, n.value]]] : UNKNOWN
        when LVarGet
          return UNKNOWN unless int?(n) && !@havoc[n.slot]
          lo, hi = env.int[n.slot] || UNKNOWN
          [[*lo, [:s, n.slot, 0]], [*hi, [:s, n.slot, 0]]]
        when LVarSet
          assign(n.slot, n.value, env)
          @inst.slots[n.slot] == :int && !@havoc[n.slot] ? (env.int[n.slot] || UNKNOWN) : UNKNOWN
        when Seq
          return UNKNOWN if n.body.empty?
          n.body[0...-1].each { exec(_1, env) }
          iv(n.body.last, env)
        when If
          iv(n.cond, env)
          et = refine(env.copy, n.cond, true)
          ef = refine(env.copy, n.cond, false)
          a = iv(n.then_, et)
          b = iv(n.else_, ef)
          replace(env, join([et, ef]))
          return a if ef.dead
          return b if et.dead
          join_fact(a, b)
        when BinOp then binop(n, env)
        when UnOp
          x = iv(n.value, env)
          return x unless n.op == "-" && int?(n.value)
          record(n, :arith, fnum(x, env, :lo) > MIN)
          lo = x[1].select { _1[0] == :c }.map { [:c, -_1[1]] }
          hi = x[0].select { _1[0] == :c }.map { [:c, -_1[1]] }
          [lo, hi]
        when CallBuiltin then builtin(n, env)
        when CallUser, CallDispatch
          n.args.each { iv(_1, env) }
          closure(n.block, env) if n.block.is_a?(Block)
          UNKNOWN
        when IndexGet
          iv(n.recv, env)
          k = iv(n.key, env)
          record(n, :index, in_bounds?(n.recv, k, env)) if ty(n.recv).is_a?(ArrT)
          UNKNOWN
        when IndexSet
          iv(n.recv, env)
          k = iv(n.key, env)
          v = iv(n.value, env)
          record(n, :index, in_bounds?(n.recv, k, env)) if ty(n.recv).is_a?(ArrT)
          v
        when IndexUpdate
          iv(n.recv, env)
          k = iv(n.key, env)
          iv(n.value, env)
          record(n, :index, in_bounds?(n.recv, k, env))
          UNKNOWN
        when Return, Raise, Next, Break, Retry, ReRaise, While, MultiWrite, ArgDefault, CaseIn
          exec(n, env)
          UNKNOWN
        when Block then UNKNOWN
        else
          children(n).each { iv(_1, env) }
          UNKNOWN
        end
      end

      def in_bounds?(arr, k, env)
        return false unless arr.is_a?(LVarGet) && !@havoc[arr.slot] && !@shrinks
        lens = env.len[arr.slot] || []
        return false if lens.empty? || fnum(k, env, :lo).negative?
        k[1].any? { |h| lens.any? { |l| lt?(h, l, env) } }
      end

      def combos(xs, ys)
        xs.product(ys).filter_map do |x, y|
          if y[0] == :c then shift(x, y[1])
          elsif x[0] == :c then shift(y, x[1])
          end
        end
      end

      def binop(n, env)
        a = iv(n.left, env)
        b = iv(n.right, env)
        return UNKNOWN unless int?(n.left) && int?(n.right)
        alo, ahi = fnum(a, env, :lo), fnum(a, env, :hi)
        blo, bhi = fnum(b, env, :lo), fnum(b, env, :hi)
        case n.op
        when "+"
          lo, hi = alo + blo, ahi + bhi
          record(n, :arith, lo >= MIN && hi <= MAX)
          numeric(combos(a[0], b[0]), combos(a[1], b[1]), lo, hi)
        when "-"
          lo, hi = alo - bhi, ahi - blo
          record(n, :arith, lo >= MIN && hi <= MAX)
          bh = b[1].select { _1[0] == :c }.map { [:c, -_1[1]] }
          bl = b[0].select { _1[0] == :c }.map { [:c, -_1[1]] }
          numeric(combos(a[0], bh), combos(a[1], bl), lo, hi)
        when "*"
          ps = [alo * blo, alo * bhi, ahi * blo, ahi * bhi]
          record(n, :arith, ps.min >= MIN && ps.max <= MAX)
          numeric([], [], ps.min, ps.max)
        when "/", "%"
          record(n, :div, blo >= 1)
          record(n, :plain, blo >= 1 && alo >= 0)
          return UNKNOWN unless blo >= 1
          if n.op == "%"
            hi = [[:c, bhi - 1]]
            hi.concat(a[1]) if alo >= 0
            [[[:c, 0]], hi]
          else
            alo >= 0 ? [[[:c, alo / bhi]], [[:c, ahi / blo]]] : UNKNOWN
          end
        when "**"
          record(n, :arith, false)
          UNKNOWN
        else UNKNOWN
        end
      end

      def numeric(lo, hi, nlo, nhi)
        lo += [[:c, nlo]] if nlo > MIN && nlo <= MAX
        hi += [[:c, nhi]] if nhi < MAX && nhi >= MIN
        norm(lo, hi)
      end

      def builtin(n, env)
        name = n.fn.full_name
        facts = n.args.map { iv(_1.is_a?(MakeRange) ? Lit.new(value: nil) : _1, env) }
        n.args.each { |r| (iv(r.left, env); iv(r.right, env)) if r.is_a?(MakeRange) }
        if n.block.is_a?(Block) && LOOPS.include?(name)
          inline_loop(n, env, facts)
          return UNKNOWN
        end
        case name
        when "Array.length", "Array.size", "String.length", "String.size", "String.bytesize" then [[[:c, 0]], [[:c, LEN_MAX]]]
        when "Kernel.rand"
          f = facts[0]
          return UNKNOWN unless f && int?(n.args[0]) && fnum(f, env, :lo) >= 1
          [[[:c, 0]], f[1].map { shift(_1, -1) }]
        when "Array.fetch"
          record(n, :index, n.args.size == 2 && in_bounds?(n.args[0], facts[1], env))
          UNKNOWN
        else UNKNOWN
        end
      end

      # A block that runs as a loop body (Array.each, Integer.times, ...): its parameters' facts per name.
      def inline_loop(n, env, facts)
        b = n.block
        name = n.fn.full_name
        params = case name
                 when "Integer.times", "Array.new" then [[[[:c, 0]], facts[0][1].map { shift(_1, -1) }]]
                 when "Range.each"
                   r = n.args[0]
                   l = quiet { iv(r.left, env.copy) }
                   h = quiet { iv(r.right, env.copy) }
                   [[l[0], r.exclusive ? h[1].map { shift(_1, -1) } : h[1]]]
                 when "Array.each_with_index" then [UNKNOWN, [[[:c, 0]], [[:c, LEN_MAX - 1]]]]
                 else []
                 end
        head, breaks = run_loop(env, :inline) do |e|
          b.params.each_with_index do |s, k|
            kill(e, s)
            f = params[k]
            e.int[s] = norm(without(f[0], s), without(f[1], s)) if f && @inst.slots[s] == :int && !@havoc[s]
          end
          b.locals.each { kill(e, _1) }
          exec(b.body, e)
        end
        replace(env, join([head, *breaks]))
        (b.params + b.locals).each { kill(env, _1) }
      end

      # A block passed to a user function: it may run any number of times during the call.
      def closure(b, env)
        run_loop(env, :closure) do |e|
          (b.params + b.locals).each { kill(e, _1) }
          exec(b.body, e)
        end
      end
    end
  end
end
