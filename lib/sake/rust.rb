# frozen_string_literal: true

require_relative "lower"

module Sake
  # Compiles a checked program to Rust, for the subset whose types the generator can fix: Integer (as i64,
  # an overflow is an error), Float, true/false, nil (as Option), String, Array, Tuple, classes, blocks.
  # User functions are instantiated per argument types, like the typer does. Anything outside the subset
  # raises Unsupported with the line, so the program can still run on the interpreter.
  module Rust
    class Unsupported < StandardError; end

    def self.generate(program) = Gen.new(program).generate

    # An Array's element type is a cell shared by every value that may be the same array (union-find), so
    # a push anywhere fixes the type everywhere.
    class ArrT
      attr_accessor :elem, :parent
      def initialize(elem) = (@elem = elem)
      def root = parent ? parent.root : self
    end
    TupT = Struct.new(:elems)
    ObjT = Struct.new(:name)
    OptT = Struct.new(:inner)
    UnionT = Struct.new(:names) # two or more classes, sorted; a Rust enum with one variant per class

    # One instantiation of a user function: the argument types it was called with, and what the body did
    # with them. given: which parameter slots the call supplies (the others take their defaults).
    Inst = Struct.new(:fn, :func, :args, :given, :name, :slots, :ret, :types, :block, :blk_params, :blk_ret, :changed, keyword_init: true)

    class Gen
      include AST

      COPY = %i[int float bool nil never].freeze

      def initialize(program)
        @program = program
        @ast = Lower.program(program)
        @insts = {}         # key => Inst
        @order = []         # Insts in discovery order
        @fields = Hash.new { |h, k| h[k] = {} } # struct name => field => type
        @node_cells = {}.compare_by_identity   # array-making node => ArrT (kept across passes)
        @path = program.path
      end

      # --- driver ---

      def generate
        main = Inst.new(fn: nil, func: @ast.main, args: [], given: [], name: "main", slots: [], ret: :nil, types: {})
        10.times do
          @changed = false
          @order.each { _1.types = nil }
          main.types = {}.compare_by_identity
          @cur = main
          main.ret = :nil
          ty(main.func.body, main)
          @order.each { |inst| type_inst(inst) if inst.types.nil? }
          break unless @changed
        end
        raise Unsupported, "types did not settle" if @changed
        fns = @order.map { fn_code(_1) }
        entry = main_code(main)
        structs = structs_code # the Rust types come last: generating the code is what finds the unions
        [prelude, structs, unions_code, *fns, entry].join("\n")
      end

      def unsupported(node, msg)
        line = node&.origin&.location&.start_line
        raise Unsupported, "#{@path}:#{line}: #{msg} (not supported by the Rust backend)"
      end

      # --- types ---

      def unify(a, b, node)
        return b if a.nil? || a == :unknown || a == :never
        return a if b.nil? || b == :unknown || b == :never
        return a if a.equal?(b)
        case [a, b]
        in [Symbol, Symbol] if a == b then a
        in [:nil, _] then b.is_a?(OptT) ? b : OptT.new(b)
        in [_, :nil] then a.is_a?(OptT) ? a : OptT.new(a)
        in [OptT, OptT] then OptT.new(unify(a.inner, b.inner, node))
        in [OptT, _] then OptT.new(unify(a.inner, b, node))
        in [_, OptT] then OptT.new(unify(a, b.inner, node))
        in [ArrT, ArrT]
          ra, rb = a.root, b.root
          return ra if ra.equal?(rb)
          e = unify(ra.elem, rb.elem, node)
          rb.parent = ra
          ra.elem = e
          @changed = true
          ra
        in [TupT, TupT]
          unsupported(node, "Tuples of different lengths meet") if a.elems.size != b.elems.size
          TupT.new(a.elems.zip(b.elems).map { unify(_1, _2, node) })
        in [ObjT, ObjT] then a.name == b.name ? a : UnionT.new([a.name, b.name].sort)
        in [UnionT, ObjT] then a.names.include?(b.name) ? a : UnionT.new((a.names + [b.name]).sort)
        in [ObjT, UnionT] then unify(b, a, node)
        in [UnionT, UnionT] then a.names == b.names ? a : UnionT.new((a.names | b.names).sort)
        else unsupported(node, "a value may be #{show(a)} or #{show(b)}; the Rust backend needs one type")
        end
      end

      def show(t)
        case t
        when Symbol then { int: "Integer", float: "Float", bool: "true|false", str: "String", nil: "nil", unknown: "?", never: "!" }.fetch(t, t.to_s)
        when ArrT then "Array[#{show(t.root.elem)}]"
        when TupT then "[#{t.elems.map { show(_1) }.join(", ")}]"
        when ObjT then t.name
        when OptT then "nil | #{show(t.inner)}"
        when UnionT then t.names.join(" | ")
        end
      end

      def union_name(t) = "U_#{t.names.map { rs_name(_1) }.join("_")}"

      def rt(t, node = nil)
        case t
        when :int then "i64"
        when :float then "f64"
        when :bool then "bool"
        when :str then "String"
        when :nil, :never then "()"
        when ArrT
          e = t.root.elem
          unsupported(node, "the element type of an Array is never fixed") if e == :unknown || e.nil?
          "SArr<#{rt(e, node)}>"
        when TupT then "(#{t.elems.map { rt(_1, node) }.join(", ")},)"
        when ObjT then "SRef<#{rs_name(t.name)}>"
        when OptT then "Option<#{rt(t.inner, node)}>"
        when UnionT then ((@unions ||= {})[t.names] = t; union_name(t))
        else unsupported(node, "a value whose type is not known")
        end
      end

      def copy?(t)
        case t
        when Symbol then COPY.include?(t)
        when OptT then copy?(t.inner)
        when TupT then t.elems.all? { copy?(_1) }
        else false
        end
      end

      def rs_name(n) = n.gsub("::", "_")

      # Types with every Array cell replaced by its root, so that equal types compare equal.
      def norm(t)
        case t
        when ArrT then t.root
        when TupT then TupT.new(t.elems.map { norm(_1) })
        when OptT then OptT.new(norm(t.inner))
        else t
        end
      end

      def same?(a, b) = norm(a) == norm(b)

      def set_slot(inst, slot, t, node)
        old = inst.slots[slot]
        new = unify(old, t, node)
        return if same?(new, old)
        inst.slots[slot] = new
        @changed = true
      end

      def set_ret(inst, t, node)
        new = unify(inst.ret, t, node)
        return if same?(new, inst.ret)
        inst.ret = new
        @changed = true
      end

      # [slot, type] narrowed by a condition on the branch taken when it holds (:then) or fails (:else):
      # `x != nil`, `x == nil`, a bare `x` of type nil | T, and `&&` of those.
      def narrowings(c, i, branch)
        case c
        when IsNil
          return [] unless c.value.is_a?(LVarGet) && ty(c.value, i).is_a?(OptT)
          (c.negate ? branch == :then : branch == :else) ? [[c.value.slot, ty(c.value, i).inner]] : []
        when LVarGet then branch == :then && ty(c, i).is_a?(OptT) ? [[c.slot, ty(c, i).inner]] : []
        when And then branch == :then ? narrowings(c.left, i, :then) + narrowings(c.right, i, :then) : []
        else []
        end
      end

      def with_narrow(i, c, branch)
        pairs = narrowings(c, i, branch)
        @narrow ||= {}
        saved = pairs.map { |s, t| [[i, s], @narrow[[i, s]]] }
        pairs.each { |s, t| @narrow[[i, s]] = t }
        yield
      ensure
        saved&.each { |k, v| v ? @narrow[k] = v : @narrow.delete(k) }
      end

      def truthy(t, node)
        case t
        when :bool, :nil, :unknown then t
        when OptT then t
        else unsupported(node, "a condition of type #{show(t)} (write `x != nil` or a comparison)")
        end
      end

      # The type of node n in instantiation i (memoized for the pass).
      def ty(n, i)
        i.types.fetch(n) { i.types[n] = ty1(n, i) }
      end

      def ty1(n, i)
        case n
        when Lit
          case n.value
          when Integer then :int
          when Float then :float
          when true, false then :bool
          when nil then :nil
          else unsupported(n, "a #{n.value.class} literal")
          end
        when Str then :str
        when Interp then (n.parts.each { ty(_1, i) }; :str)
        when ToS then (ty(n.value, i); :str)
        when LVarGet then (@narrow ||= {})[[i, n.slot]] || i.slots[n.slot] || :unknown
        when LVarSet
          t = ty(n.value, i)
          set_slot(i, n.slot, t, n)
          t
        when Seq
          n.body.map { ty(_1, i) }.last || :nil
        when If
          truthy(ty(n.cond, i), n.cond)
          th = with_narrow(i, n.cond, :then) { ty(n.then_, i) }
          el = with_narrow(i, n.cond, :else) { ty(n.else_, i) }
          unify(th, el, n)
        when While
          truthy(ty(n.cond, i), n.cond)
          ty(n.body, i)
          :nil
        when And, Or
          l = ty(n.left, i)
          r = n.is_a?(And) ? with_narrow(i, n.left, :then) { ty(n.right, i) } : ty(n.right, i)
          unsupported(n, "`#{n.is_a?(And) ? "&&" : "||"}` on #{show(l)} and #{show(r)}") unless l == :bool && r == :bool
          :bool
        when MakeTuple then TupT.new(n.elems.map { ty(_1, i) })
        when MakeRange
          unsupported(n, "a Range whose ends are not Integer") unless ty(n.left, i) == :int && ty(n.right, i) == :int
          :range
        when CallBuiltin then builtin_type(n, i)
        when CallUser then call_user(n, i).ret
        when CallDispatch
          args = n.args.map { ty(_1, i) }
          case (a0 = args[0])
          when :unknown then :unknown
          when ObjT then dispatch_inst(n, i, a0.name, args).ret
          when UnionT then a0.names.map { dispatch_inst(n, i, _1, args).ret }.reduce { unify(_1, _2, n) }
          else unsupported(n, "`#{n.dispatch.module}.#{n.dispatch.name}` on #{show(a0)}")
          end
        when CaseIn
          st = ty(n.subject, i)
          ts = n.clauses.map do |pat, body|
            check_pattern(pat, st, n)
            with_case_narrow(i, n.subject, pat, st) { ty(body, i) }
          end
          ts << ty(n.else_, i)
          ts.reduce { unify(_1, _2, n) }
        when BinOp then binop_type(n, i)
        when IsNil then (ty(n.value, i); :bool)
        when UnOp
          t = ty(n.value, i)
          unsupported(n, "`#{n.op}` on #{show(t)}") unless %i[int float unknown].include?(t) && n.op != "~"
          t
        when FieldGet
          ty(n.subject, i)
          @fields[n.type][n.field] || :unknown
        when FieldSet
          ty(n.subject, i)
          set_field(n.type, n.field, ty(n.value, i), n)
        when IndexGet
          r = ty(n.recv, i)
          unsupported(n, "a second index") if n.extra
          case r
          when TupT
            unsupported(n, "a Tuple index that is not a literal") unless n.key.is_a?(Lit) && n.key.value.is_a?(Integer)
            r.elems.fetch(n.key.value) { unsupported(n, "Tuple index out of range") }
          when ArrT
            ty(n.key, i)
            r.root.elem == :unknown ? :unknown : OptT.new(r.root.elem)
          when :unknown then :unknown
          else unsupported(n, "indexing a #{show(r)}")
          end
        when IndexSet
          r = ty(n.recv, i)
          unsupported(n, "indexing a #{show(r)}") unless r.is_a?(ArrT) && ty(n.key, i) == :int && !n.extra
          v = ty(n.value, i)
          add_elem(r, v, n)
          v
        when IndexUpdate
          r = ty(n.recv, i)
          unsupported(n, "indexing a #{show(r)}") unless r.is_a?(ArrT) && ty(n.key, i) == :int
          e = r.root.elem
          v = ty(n.value, i)
          unsupported(n, "`x[k] #{n.op}= v` on #{show(e)} and #{show(v)}") unless %i[int float].include?(e) && e == v && %w[+ - *].include?(n.op)
          e
        when ArgDefault
          set_slot(i, n.slot, ty(n.value, i), n) unless i.given[n.slot]
          :nil
        when Missing then :missing
        when Yield
          args = n.args.map { ty(_1, i) }
          i.block ? yield_type(i, args, n) : :never # without a block, a yield is a run-time error
        when BlockGiven then :bool
        when Return
          set_ret(i, n.value ? ty(n.value, i) : :nil, n)
          :never
        when Next then (ty(n.value, i) if n.value; :never)
        when Break then (ty(n.value, i) if n.value; :never)
        when Raise then (n.args.each { ty(_1, i) }; :never)
        when MultiWrite
          v = ty(n.value, i)
          unsupported(n, "`a, b = x` where x is not a Tuple of the same length") unless v.is_a?(TupT) && v.elems.size == n.targets.size
          n.targets.zip(v.elems).each do |t, et|
            unsupported(n, "`a, b = ...` with a target that is not a variable") unless t.is_a?(TLocal)
            set_slot(i, t.slot, et, n)
          end
          :nil
        when Block then unsupported(n, "a block here")
        else unsupported(n, kind_words(n))
        end
      end

      KIND_WORDS = { MakePairs: "a Hash literal", MakeRecord: "a Record", MakeRegexp: "a Regexp", Begin: "begin/rescue/ensure",
                     RescueMod: "a rescue modifier", CaseIn: "case/in", MatchP: "pattern matching", MatchRecord: "a Record pattern",
                     CallDispatch: "a mixin call", CallUnion: "a `(A|B).f` call", Splat: "a splat", ToSym: "to_sym", Retry: "retry",
                     ReRaise: "a bare raise", BlockPass: "`&b` here", Unresolved: "an unresolved call" }.freeze

      def kind_words(n) = KIND_WORDS.fetch(AST::KINDS.key(n.class), AST::KINDS.key(n.class).to_s)

      def add_elem(arr, v, node)
        r = arr.root
        new = unify(r.elem, v, node)
        return if same?(new, r.elem)
        r.elem = new
        @changed = true
      end

      def set_field(type, field, t, node)
        old = @fields[type][field]
        new = unify(old, t, node)
        unless same?(new, old)
          @fields[type][field] = new
          @changed = true
        end
        t
      end

      def binop_type(n, i)
        l = ty(n.left, i)
        r = ty(n.right, i)
        op = n.op
        return :unknown if l == :unknown || r == :unknown
        return :never if l == :never || r == :never
        num = ->(t) { %i[int float].include?(t) }
        case op
        when "==", "!="
          unsupported(n, "`#{op}` on #{show(l)} and #{show(r)}") unless l == r || (num[l] && num[r]) || [l, r].any? { _1 == :nil } || (l.is_a?(ArrT) && r.is_a?(ArrT))
          :bool
        when "<", "<=", ">", ">="
          unsupported(n, "`#{op}` on #{show(l)} and #{show(r)}") unless (num[l] && num[r]) || (l == :str && r == :str)
          :bool
        when "+", "-", "*", "/", "%", "**"
          if num[l] && num[r] then (l == :int && r == :int ? :int : :float)
          elsif op == "+" && l == :str && r == :str then :str
          elsif op == "*" && l == :str && r == :int then :str
          else unsupported(n, "`#{op}` on #{show(l)} and #{show(r)}")
          end
        when "<<"
          unsupported(n, "`<<` on #{show(l)}") unless l.is_a?(ArrT) || l == :str
          add_elem(l, r, n) if l.is_a?(ArrT)
          l
        when "&", "|", "^", ">>"
          unsupported(n, "`#{op}` on #{show(l)} and #{show(r)}") unless l == :int && r == :int
          :int
        else unsupported(n, "operator `#{op}`")
        end
      end

      # --- user functions ---

      def inst_key(fn, args, given, block_key)
        [fn, args.map { type_key(_1) }, given, block_key]
      end

      def type_key(t)
        case t
        when ArrT then [:arr, t.root.__id__]
        when TupT then [:tup, t.elems.map { type_key(_1) }]
        when ObjT then [:obj, t.name]
        when OptT then [:opt, type_key(t.inner)]
        when UnionT then [:union, t.names]
        else t
        end
      end

      def call_user(n, i) = instantiate(n, i, n.fn, n.args.map { ty(_1, i) })

      # `M.f(x, ...)` for x of class name: the class's own f (copied from M, or its own definition).
      def dispatch_inst(n, i, name, arg_types)
        impl = n.dispatch.table[name]
        unsupported(n, "`#{n.dispatch.module}.#{n.dispatch.name}` on #{name}, which does not include #{n.dispatch.module}") unless impl
        unsupported(n, "`#{n.dispatch.module}.#{n.dispatch.name}` dispatching to a built-in type") unless impl.is_a?(UserFunction)
        instantiate(n, i, impl, [ObjT.new(name), *arg_types.drop(1)])
      end

      def instantiate(n, i, fn, arg_types)
        func = @ast.functions.fetch(fn)
        given = Array.new(func.nparams, false)
        kept = []
        arg_types.each_with_index do |t, k|
          next if t == :missing
          unsupported(n, "a splat argument") if n.args[k].is_a?(Splat)
          given[k] = true
          kept << t
        end
        block = case n.block
                when nil then nil
                when BlockPass then i.block
                when Block then [i, n.block]
                end
        block_key = block && [block[0].__id__, block[1].__id__]
        key = inst_key(fn, kept, given, block_key)
        inst = @insts[key]
        unless inst
          inst = Inst.new(fn:, func:, args: kept, given:, name: "#{rs_name(fn.full_name).tr(".?!", "_qb")}_#{@order.size}",
                          slots: Array.new(func.nslots), ret: :unknown, types: nil, block:, blk_params: nil, blk_ret: :unknown)
          k = 0
          given.each_with_index do |g, s|
            next unless g
            inst.slots[s] = kept[k]
            k += 1
          end
          @insts[key] = inst
          @order << inst
          @changed = true
        end
        type_inst(inst) if inst.types.nil?
        inst
      end

      def type_inst(inst)
        inst.types = {}.compare_by_identity
        saved = @cur
        @cur = inst
        body = ty(inst.func.body, inst)
        set_ret(inst, body, inst.func.body)
        @cur = saved
      end

      # A `yield` in inst: types the caller's block body with these parameter types, returns its type.
      def yield_type(inst, args, node)
        caller, block = inst.block
        unsupported(node, "a block with a splat parameter") if block.rest
        unsupported(node, "yield with #{args.size} values to a block of #{block.params.size} parameters") if args.size < block.params.size && args.size != block.params.size
        block.params.each_with_index { |slot, k| set_slot(caller, slot, args[k] || :nil, node) }
        inst.blk_params = block.params.map { caller.slots[_1] }
        saved = @cur
        @cur = caller
        t = ty(block.body, caller)
        @cur = saved
        set_blk_ret(inst, t, node)
        inst.blk_ret
      end

      def set_blk_ret(inst, t, node)
        new = unify(inst.blk_ret, t, node)
        return if same?(new, inst.blk_ret)
        inst.blk_ret = new
        @changed = true
      end

      # --- built-ins: types ---

      def cell(n, elem = :unknown)
        @node_cells[n] ||= ArrT.new(elem)
      end

      def block_body_type(n, i, params)
        b = n.block
        unsupported(n, "`#{n.fn.full_name}` needs a block") unless b.is_a?(Block)
        unsupported(n, "a block with a splat parameter") if b.rest
        b.params.each_with_index { |slot, k| set_slot(i, slot, params[k] || :nil, n) }
        ty(b.body, i)
      end

      def builtin_type(n, i)
        name = n.fn.full_name
        args = n.args.map { ty(_1, i) }
        a0 = args[0]
        if n.fn.name == CTOR
          c = cell(n)
          args.each { add_elem(c, _1, n) }
          return c
        end
        if @program.struct_types.key?(n.fn.namespace)
          st = @program.struct_types[n.fn.namespace]
          case n.fn.name
          when "new"
            unsupported(n, "`#{name}` with #{args.size} arguments") if args.size != st.fields.size
            st.fields.each_with_index { |f, k| set_field(st.name, f, args[k], n) }
            return ObjT.new(st.name)
          when *st.fields then return @fields[st.name][n.fn.name] || :unknown
          else
            return (set_field(st.name, n.fn.name.delete_prefix("set_"), args[1], n); args[1]) if n.fn.name.start_with?("set_")
          end
        end
        case name
        when "Kernel.puts", "Kernel.print", "Kernel.p" then :nil
        when "Kernel.ARGV" then cell(n, :str)
        when "Kernel.rand" then args.empty? ? :float : (a0 == :int ? :int : :float)
        when "Kernel.exit", "Kernel.abort" then :never
        when "String.to_i", "String.length", "String.size", "String.bytesize", "Integer.abs", "Float.to_i", "Float.floor", "Float.ceil", "Float.round", "Float.truncate", "Array.length", "Array.size" then :int
        when "String.to_f", "Integer.to_f", "Math.sqrt", "Math.sin", "Math.cos", "Math.tan", "Math.atan", "Math.exp", "Math.log", "Math.log2", "Math.log10", "Math.PI", "Math.E", "Float.abs" then :float
        when "Integer.to_s", "Float.to_s", "String.to_s", "String.upcase", "String.downcase", "String.strip", "String.reverse", "Array.join", "Integer.chr", "String.+" then :str
        when "String.bytes" then cell(n, :int)
        when "String.chars" then cell(n, :str)
        when "String.include?", "String.start_with?", "String.end_with?", "String.empty?", "Integer.even?", "Integer.odd?", "Integer.zero?", "Array.include?", "Array.empty?", "Float.nan?" then :bool
        when "String.==" then :bool
        when "Integer.times"
          block_body_type(n, i, [:int])
          :nil
        when "Range.each"
          unsupported(n, "`Range.each` on a Range that is not written in place") unless n.args[0].is_a?(MakeRange)
          block_body_type(n, i, [:int])
          :nil
        when "Range.to_a"
          unsupported(n, "`Range.to_a` on a Range that is not written in place") unless n.args[0].is_a?(MakeRange)
          cell(n, :int)
        when "Array.new"
          c = cell(n)
          if n.block
            unsupported(n, "`Array.new(n) { }` with #{args.size} arguments") if args.size != 1
            add_elem(c, block_body_type(n, i, [:int]), n)
          else
            unsupported(n, "`Array.new` needs a size and a value (or a block)") if args.size != 2
            add_elem(c, args[1], n)
          end
          c
        when "Array.fetch"
          unsupported(n, "`Array.fetch` with a default") if args.size != 2
          elem_of(a0, n)
        when "Array.push", "Array.<<", "Array.append"
          args.drop(1).each { add_elem(a0, _1, n) }
          a0
        when "Array.each"
          block_body_type(n, i, [elem_of(a0, n)])
          :nil
        when "Array.each_with_index"
          block_body_type(n, i, [elem_of(a0, n), :int])
          :nil
        when "Array.map"
          c = cell(n)
          add_elem(c, block_body_type(n, i, [elem_of(a0, n)]), n)
          c
        when "Array.select", "Array.filter", "Array.reject"
          truthy(block_body_type(n, i, [elem_of(a0, n)]), n)
          a0
        when "Array.sum"
          e = elem_of(a0, n)
          unsupported(n, "`Array.sum` of #{show(e)}") unless %i[int float].include?(e)
          args[1] ? unify(e, args[1], n) : e
        when "Array.first", "Array.last", "Array.pop", "Array.shift", "Array.min", "Array.max" then OptT.new(elem_of(a0, n))
        when "Array.sort", "Array.reverse", "Array.dup", "Array.uniq" then a0
        when "Array.sort_by", "Array.min_by", "Array.max_by" then unsupported(n, "`#{name}`")
        else unsupported(n, "the built-in `#{name}`")
        end
      end

      def elem_of(t, n)
        unsupported(n, "an Array operation on #{show(t)}") unless t.is_a?(ArrT)
        t.root.elem
      end

      # --- code: functions ---

      def main_code(main)
        @cur = main
        @ctx = []
        @label = 0
        body = stmt(main.func.body, main)
        <<~RS
          fn main() {
              std::panic::set_hook(Box::new(|info| {
                  let msg = info.payload().downcast_ref::<&str>().map(|s| s.to_string())
                      .or_else(|| info.payload().downcast_ref::<String>().cloned()).unwrap_or_default();
                  eprintln!("{}: error: {}", FILE, msg);
                  std::process::exit(1);
              }));
          #{decls(main)}
          #{body}
              flush();
          }
        RS
      end

      # The function's own variables (not the given parameters, which are rebound, nor a block's).
      def decls(inst)
        (0...inst.func.nslots).filter_map do |s|
          t = inst.slots[s]
          next if t.nil? || t == :unknown # never assigned: unused
          next if inst.given[s] || block_slot?(inst, s)
          "    let mut v#{s}: #{rt(t)} = Default::default();"
        end.join("\n")
      end

      # Slots that belong to a block (its parameters and locals) are declared by the loop or closure.
      def block_slot?(inst, s)
        (@block_slots ||= {}.compare_by_identity)[inst.func] ||= collect_block_slots(inst.func.body, [])
        @block_slots[inst.func].include?(s)
      end

      def ast_node?(v) = v.is_a?(Struct) && AST::KINDS.value?(v.class)

      def collect_block_slots(n, acc)
        case n
        when Block then acc.concat(n.params, n.locals)
        end
        if ast_node?(n)
          n.each_pair do |k, v|
            next if k == :origin
            case v
            when Array then v.each { collect_block_slots(_1, acc) if ast_node?(_1) }
            else collect_block_slots(v, acc) if ast_node?(v)
            end
          end
        end
        acc
      end

      # The slots a function body assigns (not its parameters' initial values, nor a block's bindings).
      def assigned_slots(func)
        (@assigned ||= {}.compare_by_identity)[func] ||= collect_assigned(func.body, [])
      end

      def collect_assigned(n, acc)
        case n
        when LVarSet, ArgDefault then acc << n.slot
        when MultiWrite then n.targets.each { acc << _1.slot if _1.is_a?(TLocal) && _1.slot }
        end
        if ast_node?(n)
          n.each_pair do |k, v|
            next if k == :origin
            case v
            when Array then v.each { collect_assigned(_1, acc) if ast_node?(_1) }
            else collect_assigned(v, acc) if ast_node?(v)
            end
          end
        end
        acc
      end

      # A parameter is passed by reference (&T) when its value is shared, not copied, and the body never
      # reassigns it: that saves a reference count per call. slot: the parameter's slot.
      def byref?(inst, slot)
        t = inst.slots[slot]
        !copy?(t) && t != :nil && !assigned_slots(inst.func).include?(slot)
      end

      # An argument for a by-reference parameter: a variable is borrowed in place, anything else as a temporary.
      def arg_ref(a, i)
        a.is_a?(LVarGet) && !(@narrow ||= {})[[i, a.slot]] ? "&v#{a.slot}" : "&(#{expr(a, i)})"
      end

      def fn_code(inst)
        @cur = inst
        @ctx = []
        @label = 0
        params = []
        k = 0
        inst.given.each_with_index do |g, s|
          next unless g
          params << "v#{s}: #{byref?(inst, s) ? "&" : ""}#{rt(inst.args[k], inst.func.body)}"
          k += 1
        end
        if inst.block
          ps = (inst.blk_params || []).map { rt(_1, inst.func.body) }.join(", ")
          params << "blk: &mut impl FnMut(#{ps}) -> #{rt(inst.blk_ret, inst.func.body)}"
        end
        ret = inst.ret
        rebind = inst.given.each_with_index.filter_map { |g, s| "    let mut v#{s} = v#{s};" if g && !byref?(inst, s) }.join("\n")
        body = ret == :nil || ret == :never ? stmt(inst.func.body, inst) : "    #{coerce(expr(inst.func.body, inst), ty(inst.func.body, inst), ret, inst.func.body)}"
        sig = "fn #{inst.name}(#{params.join(", ")})#{ret == :nil || ret == :never ? "" : " -> #{rt(ret, inst.func.body)}"}"
        "#{sig} {\n#{rebind}\n#{decls(inst)}\n#{body}\n}\n"
      end

      def structs_code
        @program.struct_types.values.map do |st|
          fields = st.fields.map { |f| "    pub #{f}: #{(t = @fields[st.name][f]).nil? || t == :unknown ? "()" : rt(t)}," }.join("\n")
          names = st.fields.map { |f| "\"#{f}\"" }.join(", ")
          vals = st.fields.map { |f| "self.#{f}.inspect_()" }.join(", ")
          <<~RS
            #[derive(Default, Clone, PartialEq)]
            pub struct #{rs_name(st.name)} {
            #{fields}
            }
            impl Show for #{rs_name(st.name)} {
                fn to_s_(&self) -> String { self.inspect_() }
                fn inspect_(&self) -> String {
                    let names = [#{names}];
                    let vals = [#{vals}];
                    let mut s = String::from("#<struct #{st.name}");
                    for (k, (n, v)) in names.iter().zip(vals.iter()).enumerate() {
                        s.push_str(if k == 0 { " " } else { ", " });
                        s.push_str(n); s.push('='); s.push_str(v);
                    }
                    s.push('>');
                    s
                }
            }
          RS
        end.join("\n")
      end

      # --- code: statements and expressions ---

      def line(n) = n.origin&.location&.start_line || 0

      # code, of type from, where type to is expected: wraps in Some, in a union's variant, or casts.
      def coerce(code, from, to, node)
        return code if from == to || from == :never || to == :never || from == :unknown || to.nil? || same?(from, to)
        case to
        when OptT
          return "{ #{code}; None }" if from == :nil
          if from.is_a?(OptT)
            return code if same?(from.inner, to.inner)
            return "(#{code}).map(|x| #{coerce("x", from.inner, to.inner, node)})"
          end
          "Some(#{coerce(code, from, to.inner, node)})"
        when UnionT
          case from
          when ObjT then "#{rt(to, node)}::#{rs_name(from.name)}(#{code})"
          when UnionT then "match #{code} { #{from.names.map { |nm| "#{rt(from, node)}::#{rs_name(nm)}(x) => #{rt(to, node)}::#{rs_name(nm)}(x)" }.join(", ")} }"
          else unsupported(node, "a #{show(from)} where #{show(to)} is expected")
          end
        when :float then from == :int ? "((#{code}) as f64)" : code
        when :nil then "{ #{code}; }"
        else code
        end
      end

      def stmt(n, i)
        case n
        when Seq then n.body.map { stmt(_1, i) }.join("\n")
        when LVarSet then "    v#{n.slot} = #{coerce(expr(n.value, i), ty(n.value, i), i.slots[n.slot], n)};"
        when If
          c = cond(n.cond, i)
          th = with_narrow(i, n.cond, :then) { stmt(n.then_, i) }
          els = n.else_.is_a?(Lit) && n.else_.value.nil? ? "" : " else {\n#{with_narrow(i, n.cond, :else) { stmt(n.else_, i) }}\n    }"
          "    if #{c} {\n#{th}\n    }#{els}"
        when While
          lab = "'l#{@label += 1}"
          @ctx.push([:while, lab])
          body = stmt(n.body, i)
          @ctx.pop
          head = if n.cond.is_a?(Lit) && n.cond.value == !n.until_ then "loop" else "while #{n.until_ ? "!(#{cond(n.cond, i)})" : cond(n.cond, i)}" end
          "    #{lab}: #{head} {\n#{body}\n    }"
        when Lit then n.value.nil? ? "" : "    let _ = #{expr(n, i)};"
        when Return then "    return#{n.value ? " #{coerce(expr(n.value, i), ty(n.value, i), i.ret, n)}" : ""};"
        when Next, Break then "    #{expr(n, i)};"
        when FieldSet then "    { let t = #{coerce(expr(n.value, i), ty(n.value, i), @fields[n.type][n.field], n)}; #{recv(n.subject, i)}.with(|o| o.#{n.field} = t); }"
        when IndexSet then "    { let t = #{coerce(expr(n.value, i), ty(n.value, i), elem_of(ty(n.recv, i), n), n)}; #{recv(n.recv, i)}.set(#{expr(n.key, i)}, t, #{line(n)}); }"
        when CaseIn then case_code(n, i, false)
        when ArgDefault then i.given[n.slot] ? "" : "    v#{n.slot} = #{expr(n.value, i)};"
        when MultiWrite
          tmp = n.targets.each_index.map { "t#{_1}" }
          "    { let (#{tmp.join(", ")},) = #{expr(n.value, i)}; #{n.targets.zip(tmp).map { |t, x| "v#{t.slot} = #{x};" }.join(" ")} }"
        else "    #{expr(n, i)};"
        end
      end

      def cond(n, i)
        t = ty(n, i)
        e = expr(n, i)
        case t
        when :bool then e
        when :nil then "{ #{e}; false }"
        when OptT then "(#{e}).is_some()"
        end
      end

      # A narrowed variable: the value inside the Option, or the class inside the union. nil when not narrowed.
      def narrowed(slot, i, borrow)
        t = (@narrow ||= {})[[i, slot]]
        return nil unless t
        decl = i.slots[slot]
        case decl
        when OptT then copy?(decl) ? "v#{slot}.unwrap()" : (borrow ? "v#{slot}.as_ref().unwrap()" : "v#{slot}.clone().unwrap()")
        when UnionT then "(match &v#{slot} { #{rt(decl)}::#{rs_name(t.name)}(x) => x.clone(), _ => unreachable!() })"
        else "v#{slot}"
        end
      end

      def get(slot, i) = narrowed(slot, i, false) || (copy?(i.slots[slot]) ? "v#{slot}" : "v#{slot}.clone()")

      # A value in receiver position (`x.f(...)`, `puts_(&x)`): a variable is borrowed, not cloned.
      def recv(n, i)
        return expr(n, i) unless n.is_a?(LVarGet)
        narrowed(n.slot, i, true) || "v#{n.slot}"
      end

      def expr(n, i)
        t = ty(n, i)
        case n
        when Lit
          case n.value
          when Integer then n.value.negative? ? "(#{n.value}i64)" : "#{n.value}i64"
          when Float
            unsupported(n, "a non-finite Float literal") unless n.value.finite?
            n.value.negative? ? "(#{n.value}f64)" : "#{n.value}f64"
          when true, false then n.value.to_s
          when nil then "()"
          end
        when Str then "String::from(#{rs_str(n.string)})"
        when Interp
          parts = n.parts.map { _1.is_a?(Str) ? rs_str(_1.string) : expr(_1, i) }
          "format!(#{(["\"#{"{}" * parts.size}\""] + parts).join(", ")})"
        when ToS then "#{recv(n.value, i)}.to_s_()"
        when LVarGet then get(n.slot, i)
        when LVarSet then "{ v#{n.slot} = #{coerce(expr(n.value, i), ty(n.value, i), i.slots[n.slot], n)}; #{get(n.slot, i)} }"
        when Seq
          return "()" if n.body.empty?
          return "{\n#{stmt(n, i)}\n    }" if t == :nil
          *init, last = n.body
          "{\n#{init.map { stmt(_1, i) }.join("\n")}\n    #{coerce(expr(last, i), ty(last, i), t, last)} }"
        when If
          return stmt(n, i).strip if t == :nil
          th = with_narrow(i, n.cond, :then) { coerce(expr(n.then_, i), ty(n.then_, i), t, n) }
          el = with_narrow(i, n.cond, :else) { coerce(expr(n.else_, i), ty(n.else_, i), t, n) }
          "if #{cond(n.cond, i)} { #{th} } else { #{el} }"
        when While then stmt(n, i).strip
        when And then "(#{expr(n.left, i)} && #{with_narrow(i, n.left, :then) { expr(n.right, i) }})"
        when Or then "(#{expr(n.left, i)} || #{expr(n.right, i)})"
        when MakeTuple then "(#{n.elems.map { expr(_1, i) }.join(", ")},)"
        when CallBuiltin then builtin_code(n, i)
        when CallUser then user_call_code(n, i)
        when CallDispatch then dispatch_code(n, i)
        when CaseIn then case_code(n, i, true)
        when BinOp then binop_code(n, i)
        when IsNil
          v = ty(n.value, i)
          e = expr(n.value, i)
          case v
          when :nil then n.negate ? "{ #{e}; false }" : "{ #{e}; true }"
          when OptT then "(#{e}).is_#{n.negate ? "some" : "none"}()"
          else n.negate ? "{ let _ = #{e}; true }" : "{ let _ = #{e}; false }"
          end
        when UnOp then "(-#{expr(n.value, i)})"
        when FieldGet then "#{recv(n.subject, i)}.with(|o| o.#{n.field}.clone())"
        when FieldSet then "{ let t = #{coerce(expr(n.value, i), ty(n.value, i), @fields[n.type][n.field], n)}; #{recv(n.subject, i)}.with(|o| o.#{n.field} = t.clone()); t }"
        when IndexGet
          r = ty(n.recv, i)
          case r
          when TupT then "#{recv(n.recv, i)}.#{n.key.value}.clone()"
          when ArrT then "#{recv(n.recv, i)}.get(#{expr(n.key, i)})"
          end
        when IndexSet then "{ let t = #{coerce(expr(n.value, i), ty(n.value, i), elem_of(ty(n.recv, i), n), n)}; #{recv(n.recv, i)}.set(#{expr(n.key, i)}, t.clone(), #{line(n)}); t }"
        when IndexUpdate then "#{recv(n.recv, i)}.update(#{expr(n.key, i)}, |x| x #{n.op} #{expr(n.value, i)}, #{line(n)})"
        when ArgDefault then stmt(n, i).strip.chomp(";")
        when Yield then i.block ? "blk(#{n.args.each_with_index.map { |a, k| coerce(expr(a, i), ty(a, i), i.blk_params[k], n) }.join(", ")})" : "fail(#{line(n)}, \"LocalJumpError\", \"no block given (yield)\")"
        when BlockGiven then i.block ? "true" : "false"
        when Return then "return#{n.value ? " #{coerce(expr(n.value, i), ty(n.value, i), i.ret, n)}" : ""}"
        when Next
          kind, lab = @ctx.last
          unsupported(n, "`next` outside a loop or block") unless kind
          kind == :closure ? "return #{n.value ? coerce(expr(n.value, i), ty(n.value, i), lab, n) : "()"}" : "continue #{lab}"
        when Break
          want = n.target == :loop ? :while : :inline
          idx = @ctx.rindex { _1[0] == want }
          unsupported(n, "`break` out of a block passed to a function") if idx.nil? || @ctx[(idx + 1)..].any? { _1[0] == :closure }
          "break #{@ctx[idx][1]}"
        when Raise
          msg = n.args[0] ? "&#{expr(n.args[0], i)}" : "\"#{n.type || "RuntimeError"}\""
          "fail(#{line(n)}, \"#{n.type || "RuntimeError"}\", #{msg})"
        when MultiWrite then "{ #{stmt(n, i).strip} }"
        else unsupported(n, "#{AST::KINDS.key(n.class)}")
        end
      end

      def rs_str(s)
        "\"" + s.each_char.map { |c|
          case c
          when "\\" then "\\\\"
          when "\"" then "\\\""
          when "\n" then "\\n"
          when "\t" then "\\t"
          when "\r" then "\\r"
          when "{" then "{"
          else c.ord < 32 ? "\\u{#{c.ord.to_s(16)}}" : c
          end
        }.join + "\""
      end

      def binop_code(n, i)
        l = ty(n.left, i)
        r = ty(n.right, i)
        a = expr(n.left, i)
        b = expr(n.right, i)
        op = n.op
        if l == :never # an operand that never completes (a raise) takes the other's type
          l = r
          a = "{ #{a}; <#{rt(r, n)} as Default>::default() }"
        end
        if r == :never
          r = l
          b = "{ #{b}; <#{rt(l, n)} as Default>::default() }"
        end
        if l == :int && r == :int
          case op
          when "/" then "idiv(#{a}, #{b}, #{line(n)})"
          when "%" then "imod(#{a}, #{b}, #{line(n)})"
          when "**" then "ipow(#{a}, #{b}, #{line(n)})"
          else "(#{a} #{op} #{b})"
          end
        elsif %i[int float].include?(l) && %i[int float].include?(r)
          a = "(#{a} as f64)" if l == :int
          b = "(#{b} as f64)" if r == :int
          case op
          when "%" then "fmod(#{a}, #{b})"
          when "**" then "#{a}.powf(#{b})"
          else "(#{a} #{op} #{b})"
          end
        elsif l == :str && r == :str
          case op
          when "+" then "[#{a}, #{b}].concat()"
          when "==", "!=", "<", "<=", ">", ">=" then "(#{a} #{op} #{b})"
          end
        elsif l == :str && op == "*" then "#{a}.repeat(nonneg(#{b}, #{line(n)}))"
        elsif l.is_a?(ArrT) && op == "<<" then "#{a}.push(#{b})"
        elsif op == "==" || op == "!="
          if l == :nil || r == :nil
            e = l == :nil ? b : a
            o = l == :nil ? r : l
            o.is_a?(OptT) ? "(#{e}).is_#{op == "==" ? "none" : "some"}()" : "{ let _ = #{e}; #{op == "!="} }"
          else "(#{a} #{op} #{b})"
          end
        else unsupported(n, "`#{op}` on #{show(l)} and #{show(r)}")
        end
      end

      def user_call_code(n, i)
        inst = call_user(n, i)
        slots = inst.given.each_index.select { inst.given[_1] }
        args = n.args.reject { ty(_1, i) == :missing }.each_with_index.map { |a, k| byref?(inst, slots[k]) ? arg_ref(a, i) : expr(a, i) }
        if n.block.is_a?(Block)
          args << closure_code(n.block, i, inst)
        elsif n.block.is_a?(BlockPass)
          args << "&mut *blk"
        end
        "#{inst.name}(#{args.join(", ")})"
      end

      # The caller's block as a closure over its frame; `next` returns from it.
      def closure_code(b, i, callee)
        params = b.params.each_with_index.map { |s, k| "p#{k}: #{rt(callee.blk_params[k], b)}" }
        rebind = b.params.each_with_index.map { |s, k| "let mut v#{s} = p#{k};" }
        locals = b.locals.map { "let mut v#{_1}: #{rt(i.slots[_1], b)} = Default::default();" }
        ret = callee.blk_ret
        @ctx.push([:closure, ret])
        body = ret == :nil || ret == :never ? stmt(b.body, i) : "    #{coerce(expr(b.body, i), ty(b.body, i), ret, b)}"
        @ctx.pop
        "&mut |#{params.join(", ")}| -> #{rt(ret, b)} { #{rebind.join(" ")} #{locals.join(" ")}\n#{body}\n    }"
      end

      # A block inlined as a loop body: its parameters come from the loop's variables p0, p1.
      def inline_body(b, i, lab)
        @ctx.push([:inline, lab])
        rebind = b.params.each_with_index.map { |s, k| "let mut v#{s} = p#{k};" }
        locals = b.locals.map { "let mut v#{_1}: #{rt(i.slots[_1], b)} = Default::default();" }
        body = stmt(b.body, i)
        @ctx.pop
        "#{rebind.join(" ")} #{locals.join(" ")}\n#{body}"
      end

      def inline_value(b, i, lab)
        @ctx.push([:inline, lab])
        rebind = b.params.each_with_index.map { |s, k| "let mut v#{s} = p#{k};" }
        locals = b.locals.map { "let mut v#{_1}: #{rt(i.slots[_1], b)} = Default::default();" }
        body = expr(b.body, i)
        @ctx.pop
        "{ #{rebind.join(" ")} #{locals.join(" ")} #{body} }"
      end

      def builtin_code(n, i)
        name = n.fn.full_name
        args = n.args.map { _1.is_a?(MakeRange) ? nil : expr(_1, i) }
        rargs = n.args.map { _1.is_a?(MakeRange) ? nil : recv(_1, i) }
        a = rargs[0] # the subject, borrowed; args[0] is the same value cloned
        b = args[1]
        ln = line(n)
        if n.fn.name == CTOR
          e = cell(n).root.elem
          return "SArr::new(vec![#{n.args.each_with_index.map { |x, k| coerce(args[k], ty(x, i), e, n) }.join(", ")}])"
        end
        if @program.struct_types.key?(n.fn.namespace)
          st = @program.struct_types[n.fn.namespace]
          case n.fn.name
          when "new" then return "SRef::new(#{rs_name(st.name)} { #{st.fields.each_with_index.map { |f, k| "#{f}: #{coerce(args[k], ty(n.args[k], i), @fields[st.name][f], n)}" }.join(", ")} })"
          when *st.fields then return "#{a}.with(|o| o.#{n.fn.name}.clone())"
          else
            f = n.fn.name.delete_prefix("set_")
            return "{ let t = #{coerce(b, ty(n.args[1], i), @fields[st.name][f], n)}; #{a}.with(|o| o.#{f} = t.clone()); t }"
          end
        end
        case name
        when "Kernel.puts" then args.empty? ? "puts_(&())" : "{ #{rargs.map { "puts_(&#{_1});" }.join(" ")} }"
        when "Kernel.print" then "{ #{rargs.map { "print_(&#{_1});" }.join(" ")} }"
        when "Kernel.p" then "{ #{rargs.map { "p_(&#{_1});" }.join(" ")} }"
        when "Kernel.ARGV" then "argv()"
        when "Kernel.rand" then args.empty? ? "rand_f()" : (ty(n.args[0], i) == :int ? "rand_i(#{a}, #{ln})" : "(rand_f() * #{a})")
        when "Kernel.exit" then "exit_(#{args.empty? ? "0" : a})"
        when "String.to_i" then "str_to_i(&#{a})"
        when "String.to_f" then "str_to_f(&#{a})"
        when "String.length", "String.size" then "(#{a}.chars().count() as i64)"
        when "String.bytesize" then "(#{a}.len() as i64)"
        when "String.bytes" then "SArr::new(#{a}.bytes().map(|x| x as i64).collect())"
        when "String.chars" then "SArr::new(#{a}.chars().map(|x| x.to_string()).collect())"
        when "String.upcase" then "#{a}.to_uppercase()"
        when "String.downcase" then "#{a}.to_lowercase()"
        when "String.strip" then "#{a}.trim().to_string()"
        when "String.reverse" then "#{a}.chars().rev().collect::<String>()"
        when "String.include?" then "#{a}.contains(&#{b})"
        when "String.start_with?" then "#{a}.starts_with(&#{b})"
        when "String.end_with?" then "#{a}.ends_with(&#{b})"
        when "String.empty?" then "#{a}.is_empty()"
        when "String.to_s" then args[0]
        when "String.==" then "(#{a} == #{b})"
        when "String.+" then "[#{args[0]}, #{b}].concat()"
        when "Integer.to_s" then "#{a}.to_string()"
        when "Integer.to_f" then "(#{a} as f64)"
        when "Integer.abs" then "#{a}.abs()"
        when "Integer.chr" then "chr(#{a}, #{ln})"
        when "Integer.even?" then "(#{a} % 2 == 0)"
        when "Integer.odd?" then "(#{a} % 2 != 0)"
        when "Integer.zero?" then "(#{a} == 0)"
        when "Integer.times" then loop_code("0..#{a}", n.block, i)
        when "Float.to_i", "Float.truncate" then "f_to_i(#{a}.trunc(), #{ln})"
        when "Float.floor" then "f_to_i(#{a}.floor(), #{ln})"
        when "Float.ceil" then "f_to_i(#{a}.ceil(), #{ln})"
        when "Float.round" then "f_to_i(#{a}.round(), #{ln})"
        when "Float.to_s" then "#{a}.to_s_()"
        when "Float.abs" then "#{a}.abs()"
        when "Float.nan?" then "#{a}.is_nan()"
        when "Math.sqrt" then "fsqrt(#{num_f(n.args[0], a, i)}, #{ln})"
        when "Math.sin", "Math.cos", "Math.tan", "Math.atan", "Math.exp" then "#{num_f(n.args[0], a, i)}.#{name.split(".")[1]}()"
        when "Math.log" then "#{num_f(n.args[0], a, i)}.ln()"
        when "Math.log2" then "#{num_f(n.args[0], a, i)}.log2()"
        when "Math.log10" then "#{num_f(n.args[0], a, i)}.log10()"
        when "Math.PI" then "std::f64::consts::PI"
        when "Math.E" then "std::f64::consts::E"
        when "Range.each"
          r = n.args[0]
          loop_code("#{expr(r.left, i)}..#{r.exclusive ? "" : "="}#{expr(r.right, i)}", n.block, i)
        when "Range.to_a"
          r = n.args[0]
          "SArr::new((#{expr(r.left, i)}..#{r.exclusive ? "" : "="}#{expr(r.right, i)}).collect())"
        when "Array.new"
          if n.block
            lab = "'b#{@label += 1}"
            "{ let n_ = nonneg(#{a}, #{ln}); let mut t_ = Vec::with_capacity(n_); #{lab}: for p0 in 0..(n_ as i64) { t_.push(#{coerce(inline_value(n.block, i, lab), ty(n.block.body, i), cell(n).root.elem, n)}); } SArr::new(t_) }"
          else
            "SArr::new(vec![#{coerce(b, ty(n.args[1], i), cell(n).root.elem, n)}; nonneg(#{a}, #{ln})])"
          end
        when "Array.fetch" then "#{a}.fetch(#{b}, #{ln})"
        when "Array.length", "Array.size" then "#{a}.len()"
        when "Array.push", "Array.<<", "Array.append"
          e = elem_of(ty(n.args[0], i), n)
          "#{a}.push_all(vec![#{n.args.drop(1).each_with_index.map { |x, k| coerce(args[k + 1], ty(x, i), e, n) }.join(", ")}])"
        when "Array.each"
          lab = "'b#{@label += 1}"
          "{ let a_ = #{args[0]}; let mut k_ = 0i64; #{lab}: while k_ < a_.len() { let p0 = a_.#{elem_fetch(n, i)}(k_); k_ += 1; #{inline_body(n.block, i, lab)} } }"
        when "Array.each_with_index"
          lab = "'b#{@label += 1}"
          "{ let a_ = #{args[0]}; let mut k_ = 0i64; #{lab}: while k_ < a_.len() { let p0 = a_.#{elem_fetch(n, i)}(k_); let p1 = k_; k_ += 1; #{inline_body(n.block, i, lab)} } }"
        when "Array.map"
          lab = "'b#{@label += 1}"
          "{ let a_ = #{args[0]}; let mut t_ = Vec::with_capacity(a_.len() as usize); let mut k_ = 0i64; #{lab}: while k_ < a_.len() { let p0 = a_.at(k_); k_ += 1; t_.push(#{coerce(inline_value(n.block, i, lab), ty(n.block.body, i), cell(n).root.elem, n)}); } SArr::new(t_) }"
        when "Array.select", "Array.filter", "Array.reject"
          lab = "'b#{@label += 1}"
          keep = name == "Array.reject" ? "!" : ""
          "{ let a_ = #{args[0]}; let mut t_ = Vec::new(); let mut k_ = 0i64; #{lab}: while k_ < a_.len() { let p0 = a_.at(k_); k_ += 1; if #{keep}#{inline_cond(n.block, i, lab)} { t_.push(p0); } } SArr::new(t_) }"
        when "Array.sum"
          e = elem_of(ty(n.args[0], i), n)
          init = b || (e == :int ? "0i64" : "0.0f64")
          "#{a}.sum(#{init})"
        when "Array.first" then "#{a}.first()"
        when "Array.last" then "#{a}.last()"
        when "Array.pop" then "#{a}.pop()"
        when "Array.shift" then "#{a}.shift()"
        when "Array.min" then "#{a}.min_()"
        when "Array.max" then "#{a}.max_()"
        when "Array.include?" then "#{a}.includes(&#{b})"
        when "Array.empty?" then "(#{a}.len() == 0)"
        when "Array.join" then "#{a}.join(#{b ? "&#{b}" : "\"\""})"
        when "Array.sort" then "#{a}.sorted()"
        when "Array.reverse" then "#{a}.reversed()"
        when "Array.dup" then "#{a}.dup()"
        when "Array.uniq" then "#{a}.uniq()"
        else unsupported(n, "the built-in `#{name}`")
        end
      end

      def num_f(node, code, i) = ty(node, i) == :int ? "(#{code} as f64)" : code

      def inline_cond(b, i, lab)
        t = ty(b.body, i)
        v = inline_value(b, i, lab)
        case t
        when :bool then v
        when OptT then "#{v}.is_some()"
        else "{ #{v}; false }"
        end
      end

      # How an inlined `Array.each` takes each element: by reference when the element is shared, not copied,
      # and the block never reassigns its parameter (that saves a reference count per element).
      def elem_fetch(n, i)
        e = elem_of(ty(n.args[0], i), n)
        slot = n.block.params[0]
        !copy?(e) && slot && !assigned_slots(i.func).include?(slot) ? "at_ref" : "at"
      end

      def loop_code(range, block, i)
        lab = "'b#{@label += 1}"
        "{ #{lab}: for p0 in #{range} { #{inline_body(block, i, lab)} } }"
      end

      # --- mixin dispatch and case/in ---

      # `M.f(x, ...)`: a direct call when x's class is known, else a match over the union's variants.
      def dispatch_code(n, i)
        a0 = ty(n.args[0], i)
        arg_types = n.args.map { ty(_1, i) }
        rest = ->(inst) { n.args.drop(1).each_with_index.map { |a, k| byref?(inst, k + 1) ? arg_ref(a, i) : expr(a, i) } }
        tail = ->(inst) { n.block.is_a?(Block) ? [closure_code(n.block, i, inst)] : (n.block.is_a?(BlockPass) ? ["&mut *blk"] : []) }
        case a0
        when ObjT
          inst = dispatch_inst(n, i, a0.name, arg_types)
          first = byref?(inst, 0) ? arg_ref(n.args[0], i) : expr(n.args[0], i)
          "#{inst.name}(#{[first, *rest[inst], *tail[inst]].join(", ")})"
        when UnionT
          ret = ty(n, i)
          arms = a0.names.map do |name|
            inst = dispatch_inst(n, i, name, arg_types)
            call = "#{inst.name}(#{[byref?(inst, 0) ? "x" : "x.clone()", *rest[inst], *tail[inst]].join(", ")})"
            "#{rt(a0, n)}::#{rs_name(name)}(x) => #{coerce(call, inst.ret, ret, n)}"
          end
          "match &#{recv(n.args[0], i)} { #{arms.join(", ")} }"
        end
      end

      SCALAR_NAMES = { "Integer" => :int, "Float" => :float, "String" => :str }.freeze

      # The patterns the backend knows: a literal, a type name, and `|` of those.
      def check_pattern(pat, st, n)
        case pat
        when PValue
          v = ty(pat.value, @cur)
          ok = v == st || (v == :nil && st.is_a?(OptT)) || (st.is_a?(OptT) && v == st.inner) || (%i[int float].include?(v) && %i[int float].include?(st))
          unsupported(n, "`in #{show(v)}` against a #{show(st)}") unless ok
        when PType
          case st
          when ObjT, UnionT then unsupported(n, "`in #{pat.name}` against a #{show(st)}") unless @program.struct_types.key?(pat.name)
          when OptT then unsupported(n, "`in #{pat.name}` against a #{show(st)}") unless SCALAR_NAMES.key?(pat.name) || @program.struct_types.key?(pat.name)
          else unsupported(n, "`in #{pat.name}` against a #{show(st)}") unless SCALAR_NAMES.key?(pat.name)
          end
        when PAlt
          check_pattern(pat.left, st, n)
          check_pattern(pat.right, st, n)
        else unsupported(n, "this pattern")
        end
      end

      # A Rust condition on s_, the subject's value.
      def pattern_code(pat, st, i)
        case pat
        when PValue
          v = ty(pat.value, i)
          return "s_.is_none()" if v == :nil
          st.is_a?(OptT) ? "(s_ == Some(#{expr(pat.value, i)}))" : "(s_ == #{expr(pat.value, i)})"
        when PType
          case st
          when UnionT then "matches!(s_, #{rt(st)}::#{rs_name(pat.name)}(_))"
          when ObjT then (st.name == pat.name).to_s
          when OptT then st.inner.is_a?(UnionT) ? "matches!(s_, Some(#{rt(st.inner)}::#{rs_name(pat.name)}(_)))" : "s_.is_some()"
          else (SCALAR_NAMES[pat.name] == st).to_s
          end
        when PAlt then "(#{pattern_code(pat.left, st, i)} || #{pattern_code(pat.right, st, i)})"
        end
      end

      # `case x in C` narrows the variable x to C inside the clause.
      def with_case_narrow(i, subject, pat, st)
        if subject.is_a?(LVarGet) && pat.is_a?(PType) && st.is_a?(UnionT)
          @narrow ||= {}
          key = [i, subject.slot]
          saved = @narrow[key]
          @narrow[key] = ObjT.new(pat.name)
          begin
            yield
          ensure
            saved ? @narrow[key] = saved : @narrow.delete(key)
          end
        else
          yield
        end
      end

      def case_code(n, i, value)
        st = ty(n.subject, i)
        t = ty(n, i)
        branches = n.clauses.map do |pat, body|
          c = pattern_code(pat, st, i)
          b = with_case_narrow(i, n.subject, pat, st) { value ? coerce(expr(body, i), ty(body, i), t, n) : stmt(body, i) }
          "if #{c} {\n#{b}\n    }"
        end
        els = value ? coerce(expr(n.else_, i), ty(n.else_, i), t, n) : stmt(n.else_, i)
        "#{value ? "" : "    "}{ let s_ = #{expr(n.subject, i)}; #{branches.join(" else ")} else {\n#{els}\n    } }"
      end

      def unions_code
        (@unions || {}).values.map do |u|
          name = union_name(u)
          vars = u.names.map { |nm| "#{rs_name(nm)}(SRef<#{rs_name(nm)}>)" }
          arms = ->(m) { u.names.map { |nm| "#{name}::#{rs_name(nm)}(x) => x.#{m}()" }.join(", ") }
          <<~RS
            #[derive(Clone, PartialEq)]
            pub enum #{name} { #{vars.join(", ")} }
            impl Default for #{name} { fn default() -> Self { #{name}::#{rs_name(u.names[0])}(Default::default()) } }
            impl Show for #{name} {
                fn to_s_(&self) -> String { match self { #{arms["to_s_"]} } }
                fn inspect_(&self) -> String { match self { #{arms["inspect_"]} } }
            }
          RS
        end.join("\n")
      end

      # --- the run-time support, in every generated program ---

      def prelude
        <<~RS
          #![allow(unused, non_snake_case, non_camel_case_types, unused_comparisons, unused_must_use, unreachable_code, unused_parens, unused_labels, dead_code, unused_braces)]
          use std::rc::Rc;
          use std::cell::UnsafeCell;
          use std::io::Write;

          const FILE: &str = #{rs_str(File.basename(@path.to_s))};

          thread_local! { static OUT: std::cell::RefCell<std::io::BufWriter<std::io::Stdout>> = std::cell::RefCell::new(std::io::BufWriter::new(std::io::stdout())); }
          fn out(s: &str) { OUT.with(|o| { o.borrow_mut().write_all(s.as_bytes()); }); }
          fn flush() { OUT.with(|o| { o.borrow_mut().flush(); }); }

          fn fail(line: u32, kind: &str, msg: &str) -> ! {
              flush();
              eprintln!("{}:{}: {}: {}", FILE, line, kind, msg);
              std::process::exit(1)
          }
          fn exit_(code: i64) -> ! { flush(); std::process::exit(code as i32) }

          // Values are reference types, as in Sake: an Array or an object is shared by every variable that holds it.
          // No compiled program runs threads, and no reference to the contents outlives one operation.
          pub struct SArr<T>(Rc<UnsafeCell<Vec<T>>>);
          impl<T> Clone for SArr<T> { fn clone(&self) -> Self { SArr(self.0.clone()) } }
          impl<T> Default for SArr<T> { fn default() -> Self { SArr::new(Vec::new()) } }
          impl<T> SArr<T> {
              #[inline] pub fn new(v: Vec<T>) -> Self { SArr(Rc::new(UnsafeCell::new(v))) }
              #[inline] fn v(&self) -> &mut Vec<T> { unsafe { &mut *self.0.get() } }
              #[inline] pub fn len(&self) -> i64 { self.v().len() as i64 }
              #[inline] pub fn at_ref(&self, k: i64) -> &T { &self.v()[k as usize] }
          }
          impl<T: Show + ?Sized> Show for &T {
              fn to_s_(&self) -> String { (**self).to_s_() }
              fn inspect_(&self) -> String { (**self).inspect_() }
              fn puts_lines(&self) { (**self).puts_lines() }
          }
          impl<T: Clone> SArr<T> {
              #[inline] fn pos(&self, i: i64) -> Option<usize> {
                  let n = self.v().len() as i64;
                  let k = if i < 0 { i + n } else { i };
                  if k < 0 || k >= n { None } else { Some(k as usize) }
              }
              #[inline] pub fn at(&self, k: i64) -> T { self.v()[k as usize].clone() }
              #[inline] pub fn fetch(&self, i: i64, line: u32) -> T {
                  match self.pos(i) { Some(k) => self.v()[k].clone(), None => fail(line, "IndexError", &format!("index {} outside of array bounds: {}...{}", i, -self.len(), self.len())) }
              }
              #[inline] pub fn get(&self, i: i64) -> Option<T> { self.pos(i).map(|k| self.v()[k].clone()) }
              #[inline] pub fn set(&self, i: i64, x: T, line: u32) {
                  let v = self.v();
                  let n = v.len() as i64;
                  if i == n { v.push(x); return; }
                  match self.pos(i) { Some(k) => v[k] = x, None => fail(line, "IndexError", &format!("index {} outside of array bounds: {}...{} (the Rust backend cannot fill the gap with nil)", i, -n, n)) }
              }
              #[inline] pub fn update(&self, i: i64, f: impl FnOnce(T) -> T, line: u32) -> T {
                  match self.pos(i) { Some(k) => { let v = self.v(); let x = f(v[k].clone()); v[k] = x.clone(); x }, None => fail(line, "NoMethodError", &format!("x[{}] is nil: index outside of array bounds", i)) }
              }
              #[inline] pub fn push_all(&self, xs: Vec<T>) -> Self { self.v().extend(xs); self.clone() }
              #[inline] pub fn push(&self, x: T) -> Self { self.v().push(x); self.clone() }
              pub fn first(&self) -> Option<T> { self.v().first().cloned() }
              pub fn last(&self) -> Option<T> { self.v().last().cloned() }
              pub fn pop(&self) -> Option<T> { self.v().pop() }
              pub fn shift(&self) -> Option<T> { let v = self.v(); if v.is_empty() { None } else { Some(v.remove(0)) } }
              pub fn dup(&self) -> Self { SArr::new(self.v().clone()) }
              pub fn reversed(&self) -> Self { let mut v = self.v().clone(); v.reverse(); SArr::new(v) }
          }
          impl<T: Clone + PartialEq> SArr<T> {
              pub fn includes(&self, x: &T) -> bool { self.v().contains(x) }
              pub fn uniq(&self) -> Self { let mut r: Vec<T> = Vec::new(); for x in self.v().iter() { if !r.contains(x) { r.push(x.clone()); } } SArr::new(r) }
          }
          impl<T: Clone + PartialEq> PartialEq for SArr<T> { fn eq(&self, o: &Self) -> bool { self.v() == o.v() } }
          impl<T: Clone + PartialOrd> SArr<T> {
              pub fn sorted(&self) -> Self { let mut v = self.v().clone(); v.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal)); SArr::new(v) }
              pub fn min_(&self) -> Option<T> { let mut r: Option<T> = None; for x in self.v().iter() { if r.as_ref().map_or(true, |m| x < m) { r = Some(x.clone()); } } r }
              pub fn max_(&self) -> Option<T> { let mut r: Option<T> = None; for x in self.v().iter() { if r.as_ref().map_or(true, |m| x > m) { r = Some(x.clone()); } } r }
          }
          impl<T: Clone + std::ops::Add<Output = T>> SArr<T> { pub fn sum(&self, init: T) -> T { let mut s = init; for x in self.v().iter() { s = s + x.clone(); } s } }
          impl<T: Clone + Show> SArr<T> { pub fn join(&self, sep: &str) -> String { self.v().iter().map(|x| x.to_s_()).collect::<Vec<_>>().join(sep) } }

          pub struct SRef<T>(Rc<UnsafeCell<T>>);
          impl<T> Clone for SRef<T> { fn clone(&self) -> Self { SRef(self.0.clone()) } }
          impl<T: Default> Default for SRef<T> { fn default() -> Self { SRef::new(T::default()) } }
          impl<T> SRef<T> {
              #[inline] pub fn new(x: T) -> Self { SRef(Rc::new(UnsafeCell::new(x))) }
              #[inline] pub fn with<R>(&self, f: impl FnOnce(&mut T) -> R) -> R { f(unsafe { &mut *self.0.get() }) }
          }
          impl<T: PartialEq> PartialEq for SRef<T> { fn eq(&self, o: &Self) -> bool { unsafe { *self.0.get() == *o.0.get() } } }

          // to_s and inspect, as Kernel.to_s and Kernel.inspect give them.
          pub trait Show {
              fn to_s_(&self) -> String;
              fn inspect_(&self) -> String { self.to_s_() }
              fn puts_lines(&self) { out(&self.to_s_()); out("\\n"); }
          }
          impl Show for i64 { fn to_s_(&self) -> String { self.to_string() } }
          impl Show for bool { fn to_s_(&self) -> String { self.to_string() } }
          impl Show for () { fn to_s_(&self) -> String { String::new() } fn inspect_(&self) -> String { "nil".to_string() } }
          impl Show for String {
              fn to_s_(&self) -> String { self.clone() }
              fn inspect_(&self) -> String {
                  let mut s = String::from("\\"");
                  for c in self.chars() { match c { '"' => s.push_str("\\\\\\""), '\\\\' => s.push_str("\\\\\\\\"), '\\n' => s.push_str("\\\\n"), '\\t' => s.push_str("\\\\t"), '\\r' => s.push_str("\\\\r"), '\\u{1b}' => s.push_str("\\\\e"), '#' => s.push('#'), c if (c as u32) < 32 => s.push_str(&format!("\\\\x{:02X}", c as u32)), c => s.push(c) } }
                  s.push('"');
                  s
              }
          }
          impl Show for f64 {
              fn to_s_(&self) -> String {
                  let x = *self;
                  if x.is_nan() { return "NaN".to_string(); }
                  if x.is_infinite() { return if x > 0.0 { "Infinity" } else { "-Infinity" }.to_string(); }
                  let a = x.abs();
                  if a >= 1e16 || (a != 0.0 && a < 1e-4) {
                      let s = format!("{:e}", x);
                      let (m, e) = s.split_once('e').unwrap();
                      let m = if m.contains('.') { m.to_string() } else { format!("{}.0", m) };
                      let ev: i32 = e.parse().unwrap();
                      return format!("{}e{}{:02}", m, if ev < 0 { "-" } else { "+" }, ev.abs());
                  }
                  if x == x.trunc() { format!("{:.1}", x) } else { format!("{}", x) }
              }
          }
          impl<T: Show> Show for Option<T> {
              fn to_s_(&self) -> String { match self { Some(x) => x.to_s_(), None => String::new() } }
              fn inspect_(&self) -> String { match self { Some(x) => x.inspect_(), None => "nil".to_string() } }
              fn puts_lines(&self) { match self { Some(x) => x.puts_lines(), None => out("\\n") } }
          }
          impl<T: Clone + Show> Show for SArr<T> {
              fn to_s_(&self) -> String { self.inspect_() }
              fn inspect_(&self) -> String { format!("[{}]", self.v().iter().map(|x| x.inspect_()).collect::<Vec<_>>().join(", ")) }
              fn puts_lines(&self) { if self.v().is_empty() { out("\\n"); } for x in self.v().iter() { x.puts_lines(); } }
          }
          impl<T: Show> Show for SRef<T> {
              fn to_s_(&self) -> String { self.with(|o| o.to_s_()) }
              fn inspect_(&self) -> String { self.with(|o| o.inspect_()) }
          }
          macro_rules! tuple_show { ($($i:tt $T:ident),+) => {
              impl<$($T: Show),+> Show for ($($T,)+) {
                  fn to_s_(&self) -> String { self.inspect_() }
                  fn inspect_(&self) -> String { let v: Vec<String> = vec![$(self.$i.inspect_()),+]; format!("[{}]", v.join(", ")) }
                  fn puts_lines(&self) { $(self.$i.puts_lines();)+ }
              }
          } }
          tuple_show!(0 A);
          tuple_show!(0 A, 1 B);
          tuple_show!(0 A, 1 B, 2 C);
          tuple_show!(0 A, 1 B, 2 C, 3 D);
          tuple_show!(0 A, 1 B, 2 C, 3 D, 4 E);

          fn puts_<T: Show>(x: &T) { x.puts_lines(); }
          fn print_<T: Show>(x: &T) { out(&x.to_s_()); }
          fn p_<T: Show>(x: &T) { out(&x.inspect_()); out("\\n"); }

          fn argv() -> SArr<String> { SArr::new(std::env::args().skip(1).collect()) }
          fn nonneg(n: i64, line: u32) -> usize { if n < 0 { fail(line, "ArgumentError", "negative array size") } n as usize }
          #[inline] fn idiv(a: i64, b: i64, line: u32) -> i64 { if b == 0 { fail(line, "ZeroDivisionError", "divided by 0") } let q = a / b; if (a % b != 0) && ((a < 0) != (b < 0)) { q - 1 } else { q } }
          #[inline] fn imod(a: i64, b: i64, line: u32) -> i64 { if b == 0 { fail(line, "ZeroDivisionError", "divided by 0") } let r = a % b; if r != 0 && ((r < 0) != (b < 0)) { r + b } else { r } }
          fn ipow(a: i64, b: i64, line: u32) -> i64 { if b < 0 { fail(line, "ArgumentError", &format!("Integer ** negative Integer ({} ** {}) is an error", a, b)) } a.checked_pow(b as u32).unwrap_or_else(|| fail(line, "RangeError", "Integer overflow in **")) }
          fn fmod(a: f64, b: f64) -> f64 { let r = a % b; if r != 0.0 && ((r < 0.0) != (b < 0.0)) { r + b } else { r } }
          fn fsqrt(x: f64, line: u32) -> f64 { if x < 0.0 { fail(line, "Math::DomainError", "Numerical argument is out of domain - \\"sqrt\\"") } x.sqrt() }
          fn f_to_i(x: f64, line: u32) -> i64 { if x.is_nan() || x.is_infinite() { fail(line, "FloatDomainError", &x.to_s_()) } x as i64 }
          fn chr(x: i64, line: u32) -> String { match u32::try_from(x).ok().and_then(char::from_u32) { Some(c) => c.to_string(), None => fail(line, "RangeError", &format!("{} out of char range", x)) } }
          fn str_to_i(s: &str) -> i64 {
              let t = s.trim_start();
              let (neg, t) = match t.strip_prefix('-') { Some(r) => (true, r), None => (false, t.strip_prefix('+').unwrap_or(t)) };
              let mut v: i64 = 0;
              for c in t.chars() { match c.to_digit(10) { Some(d) => v = v.saturating_mul(10).saturating_add(d as i64), None if c == '_' => continue, None => break } }
              if neg { -v } else { v }
          }
          fn str_to_f(s: &str) -> f64 {
              let t = s.trim_start();
              let end = t.char_indices().take_while(|(_, c)| c.is_ascii_digit() || matches!(c, '-' | '+' | '.' | 'e' | 'E' | '_')).last().map_or(0, |(k, c)| k + c.len_utf8());
              let mut u = t[..end].replace('_', "");
              loop { match u.parse::<f64>() { Ok(v) => return v, Err(_) => { if u.is_empty() { return 0.0; } u.pop(); } } }
          }
          thread_local! { static SEED: std::cell::Cell<u64> = std::cell::Cell::new(0x9E3779B97F4A7C15 ^ (std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).map(|d| d.as_nanos() as u64).unwrap_or(1))); }
          fn rand_u64() -> u64 { SEED.with(|s| { let mut x = s.get(); x ^= x << 13; x ^= x >> 7; x ^= x << 17; s.set(x); x }) }
          fn rand_f() -> f64 { (rand_u64() >> 11) as f64 / (1u64 << 53) as f64 }
          fn rand_i(n: i64, line: u32) -> i64 { if n <= 0 { fail(line, "ArgumentError", &format!("invalid argument - {}", n)) } (rand_u64() % (n as u64)) as i64 }
        RS
      end
    end
  end
end
