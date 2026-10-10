# frozen_string_literal: true

require "monitor"
require_relative "lower"

module Sake
  # Runs SakeAST (see ast.rb). Messages report the line of each node's origin.
  class Interpreter
    include AST

    # slots: the function's locals (its blocks' too); block: the block passed to the function.
    Frame = Struct.new(:name, :slots, :block)
    # The value of a parameter the call did not give, until the function's prologue sets its default.
    MISSING = Object.new.freeze

    # A thread's view of a frame: the variables of blocks (parameters and locals) are its own, copied
    # when the thread starts; the function's own variables stay shared with the frame.
    class ThreadSlots
      def initialize(shared, own)
        @shared = shared
        @own = own.to_h { [_1, shared[_1]] }
      end

      def [](i) = @own.key?(i) ? @own[i] : @shared[i]
      def []=(i, v)
        @own.key?(i) ? @own[i] = v : @shared[i] = v
      end
    end
    BlockVal = Struct.new(:node, :frame)

    class ReturnSignal < StandardError
      attr_reader :frame, :value

      def initialize(frame, value)
        @frame = frame
        @value = value
        super()
      end
    end

    class JumpSignal < StandardError
      attr_reader :value

      def initialize(value)
        @value = value
        super()
      end
    end
    class NextSignal < JumpSignal; end
    class BreakSignal < JumpSignal; end

    # `break` in a block: block is the BlockVal it leaves.
    class BlockBreak < JumpSignal
      attr_reader :block

      def initialize(block, value)
        @block = block
        super(value)
      end
    end
    class RetrySignal < StandardError; end

    MAX_DEPTH = 10_000

    attr_reader :ast

    def initialize(program)
      @program = program
      @registry = program.registry
      @ast = Lower.program(program)
      @stack = [] # [function name, call line]
      @handling = [] # errors being handled by rescue clauses, innermost last (for a bare `raise`)
      @running_blocks = [] # blocks being run, innermost last (for `break`)
    end

    def run
      Thread.current[:sake_show_hooks] = method(:show_hook)
      Thread.current[:sake_struct_ops] = method(:struct_ruby_op)
      @program.struct_types.each_value do |dt|
        dt.own_equality = !!own_fn(dt.name, "==") ||
                          (Operators.includes?(@program.includes, dt.name, "Comparable") && !!own_fn(dt.name, "<=>"))
      end
      main = @ast.main
      ev(main.body, Frame.new("<main>", Array.new(main.nslots), nil))
      nil
    end

    private

    def line(node) = node.origin.location.start_line

    # The file of a node when it is not the main file (nil: the main file).
    def where_file(node)
      f = Sake.file_of(@program, node)
      f == @program.path ? nil : f
    end

    def fail_at(node, kind, message, **opts)
      raise RunError.new(kind, message, line(node), @stack.dup, file: where_file(node), **opts)
    end

    # A Ruby exception escaping a built-in becomes the Sake error of the same kind (Ruby's message, with
    # Sake's names for its values). Subclasses come before their superclasses; EOFError and Errno are IOError.
    # Ruby's own RuntimeError (String.undump of a bad string) is an ArgumentError: in Sake, RuntimeError is what
    # `raise "message"` makes, and the checker's rescue check relies on that.
    RUBY_ERRORS = [[::ZeroDivisionError, "ZeroDivisionError"], [::FloatDomainError, "FloatDomainError"],
                   [::RangeError, "RangeError"], [::KeyError, "KeyError"], [::ClosedQueueError, "IOError"],
                   [::IndexError, "IndexError"], [::RegexpError, "RegexpError"], [::Math::DomainError, "Math::DomainError"],
                   [::ArgumentError, "ArgumentError"], [::TypeError, "TypeError"], [::IOError, "IOError"],
                   [::SystemCallError, "IOError"], [::ThreadError, "ThreadError"], [::EncodingError, "EncodingError"],
                   [::NoMatchingPatternError, "NoMatchingPatternError"], [::FrozenError, "TypeError"], [::RuntimeError, "ArgumentError"]].freeze
    RUBY_ERROR_CLASSES = RUBY_ERRORS.map(&:first).freeze

    def ruby_run_error(e, node, op)
      return RunError.new(e.kind, e.message, node.location.start_line, @stack.dup, file: where_file(node), op:) if e.is_a?(Fail)
      raise e if e.is_a?(::ArgumentError) && e.message.start_with?("wrong number of arguments") # the interpreter's own bug
      raise e if e.instance_of?(::RuntimeError) && e.message.start_with?("BUG")
      kind = RUBY_ERRORS.find { |c, _| e.is_a?(c) }&.last or raise e
      return RunError.new(kind, Stdlib::FROZEN_STRING, node.location.start_line, @stack.dup, file: where_file(node), op:) if e.is_a?(::FrozenError) && e.receiver.is_a?(String)
      msg = e.message.gsub("Sake::Tuple", "Tuple").gsub("Sake::RecordValue", "Record").gsub("Sake::StructValue", "Struct value")
      RunError.new(kind, msg, node.location.start_line, @stack.dup, file: where_file(node), op:)
    end

    def ev(n, f)
      case n
      when Lit then n.value
      when Str then n.string.dup
      when LVarGet then f.slots[n.slot]
      when LVarSet then f.slots[n.slot] = ev(n.value, f)
      when Seq
        v = nil
        n.body.each { v = ev(_1, f) }
        v
      when If then Values.truthy?(ev(n.cond, f)) ? ev(n.then_, f) : ev(n.else_, f)
      when While then loop_node(n, f)
      when And
        l = ev(n.left, f)
        Values.truthy?(l) ? ev(n.right, f) : l
      when Or
        l = ev(n.left, f)
        Values.truthy?(l) ? l : ev(n.right, f)
      when CallBuiltin, CallUser, CallDispatch, CallUnion
        # A passed-on block's break ends the call it was written for, so it is not caught here.
        n.block.is_a?(BlockPass) ? call_node(n, f, pass_block(n, f)) : (n.block ? call_catching_break(n, f) : call_node(n, f, nil))
      when BinOp then binary_op(n.origin, n.op, ev(n.left, f), ev(n.right, f))
      when UnOp then unary_op(n.origin, n.op, ev(n.value, f))
      when IsNil
        v = ev(n.value, f)
        # A Struct value goes through its type's own ==, as `x == nil` does.
        v.is_a?(StructValue) ? binary_op(n.origin, n.negate ? "!=" : "==", v, nil) : (n.negate ? !v.nil? : v.nil?)
      when FieldGet then call_builtin(n.fn, [ev(n.subject, f)], nil, n.origin)
      when FieldSet
        s = ev(n.subject, f)
        call_builtin(n.fn, [s, ev(n.value, f)], nil, n.origin)
      when IndexGet
        r = ev(n.recv, f)
        k = ev(n.key, f)
        index_op(n.origin, "[]", [r, k, *(n.extra ? [ev(n.extra, f)] : [])])
      when IndexSet
        r = ev(n.recv, f)
        k = ev(n.key, f)
        e = n.extra ? [ev(n.extra, f)] : []
        index_op(n.origin, "[]=", [r, k, *e, ev(n.value, f)])
      when IndexUpdate then index_update(n, f)
      when Yield then call_block(f.block, n.args.map { ev(_1, f) }, n.origin)
      when Interp then encoding_error(n) { n.parts.map { ev(_1, f) }.join }
      when ArgDefault then f.slots[n.slot].equal?(MISSING) ? f.slots[n.slot] = ev(n.value, f) : nil
      when Missing then MISSING
      when BlockGiven then !f.block.nil?
      when ToS then Values.to_s(ev(n.value, f))
      when ToSym then ev(n.value, f).to_sym
      when MakeTuple then Tuple.new(n.elems.map { ev(_1, f) })
      when MakeRecord then RecordValue.build(n.keys.zip(n.values.map { ev(_1, f) }))
      when MakePairs then HashPairs.new(n.keys.zip(n.values).map { |k, v| [ev(k, f), ev(v, f)] })
      when MakeRange then range(n, f)
      when MakeRegexp
        begin
          Regexp.new(n.parts.map { ev(_1, f) }.join, n.options)
        rescue ::RegexpError => e
          fail_at(n, "RegexpError", e.message)
        end
      when Return then raise ReturnSignal.new(f, ev(n.value, f))
      when Next then raise NextSignal.new(ev(n.value, f))
      when Break
        v = ev(n.value, f)
        raise(n.target == :block ? BlockBreak.new(@running_blocks.last, v) : BreakSignal.new(v))
      when Retry then raise RetrySignal
      when Raise then do_raise(n, f)
      when ReRaise then raise @handling.last
      when Begin then begin_node(n, f)
      when RescueMod
        begin
          ev(n.expr, f)
        rescue RunError => e
          raise unless rescuable?(e)
          ev(n.rescue_, f)
        end
      when MultiWrite then multi_write(n, f)
      when MatchP then pattern_match?(ev(n.value, f), n.pattern, f)
      when CaseIn then case_match(n, f)
      when MatchRecord then match_record(n, f)
      when Unresolved then raise "BUG: #{n.message}"
      else raise "BUG: unknown node #{n.class}"
      end
    end

    def index_update(n, f)
      r = ev(n.recv, f)
      k = ev(n.key, f)
      cur = index_op(n.origin, "[]", [r, k])
      if n.op == "||"
        return cur if Values.truthy?(cur)
        val = ev(n.value, f)
      else
        val = binary_op(n.origin, n.op, cur, ev(n.value, f))
      end
      index_op(n.origin, "[]=", [r, k, val])
    end

    def block_val(b, f) = b && BlockVal.new(b, f)

    # `&b` when the function was called without a block: fine for a callee that checks block_given?.
    def pass_block(n, f)
      return f.block if f.block || !Sake.needs_block?(n)
      raise RunError.new("LocalJumpError", "no block given (#{n.block.origin.slice} passes none)", line(n), @stack.dup, file: where_file(n.origin))
    end

    def call_node(n, f, blk)
      args = n.args.flat_map do |a|
        next [ev(a, f)] unless a.is_a?(Splat)
        v = ev(a.value, f)
        next v.elems if v.is_a?(Tuple)
        next v if v.is_a?(Array)
        fail_at(a, "TypeError", "splat needs a Tuple or an Array, got #{Values.describe(v)}", nil_value: v.nil?)
      end
      case n
      when CallBuiltin then call_builtin(n.fn, args, blk, n.origin)
      when CallUser then call_user(n.fn, args, blk, n.origin)
      when CallDispatch
        d = n.dispatch
        fn = d.table[Values.type_of(args[0])]
        fail_at(n, "TypeError", "#{d.module}.#{d.name}: #{Values.describe(args[0])} does not include #{d.module}") unless fn
        return call_builtin(fn, args, blk, n.origin) unless fn.is_a?(UserFunction) # Enum.map on an Array: Array.map
        call_user(fn, args, blk, n.origin)
      when CallUnion
        un = n.union
        fn = un.table[Values.type_of(args[0])]
        fail_at(n, "TypeError", "argument 1 must be #{un.types.join(" or ")}, got #{Values.describe(args[0])}", nil_value: args[0].nil?, op: un.full_name) unless fn
        return call_builtin(fn, args, blk, n.origin) unless fn.is_a?(UserFunction)
        args = [*args.take(fn.positional), args.drop(fn.positional)] if fn.rest_param # `*rest` is packed per branch
        call_user(fn, args, blk, n.origin)
      end
    end

    # `break` in a block ends the call the block was given to, with the break's value (as Ruby).
    def call_catching_break(n, f)
      blk = block_val(n.block, f)
      call_node(n, f, blk)
    rescue BlockBreak => e
      raise unless e.block.equal?(blk)
      e.value
    end

    NOT_RESCUABLE = Resolver::NOT_RESCUABLE

    def rescuable?(e) = !NOT_RESCUABLE.include?(e.kind)

    def exception_type(name) = @program.struct_types.fetch(name)

    # The exception value of an error, built from its kind and message when an operation raised it.
    def exception_value(e)
      e.value ||= StructValue.new(exception_type(e.kind), [e.message])
    end

    def do_raise(n, f)
      arg = ev(n.args[0], f)
      value =
        if n.type
          fail_at(n, "TypeError", "raise: the message must be String, got #{Values.describe(arg)}") unless arg.is_a?(String)
          StructValue.new(exception_type(n.type), [arg])
        elsif arg.is_a?(String)
          StructValue.new(exception_type("RuntimeError"), [arg])
        elsif arg.is_a?(StructValue) && arg.type.exception
          arg
        else
          fail_at(n, "TypeError", "raise needs a String or an exception, got #{Values.describe(arg)}")
        end
      err = RunError.new(value.type.name, Values.to_s(value.values[0]), line(n), @stack.dup, file: where_file(n))
      err.value = value
      raise err
    end

    # `retry` in a rescue clause runs the begin body again; ensure runs once, when leaving.
    def begin_node(n, f)
      loop do
        return run_begin(n, f)
      rescue RetrySignal
        next
      end
    ensure
      ev(n.ensure_, f) if n.ensure_
    end

    def run_begin(n, f)
      result = ev(n.body, f)
    rescue RunError => e
      clause = rescuable?(e) && n.rescues.find { |c| c.names.empty? || c.names.include?(e.kind) }
      raise unless clause
      @handling.push(e)
      begin
        f.slots[clause.slot] = exception_value(e) if clause.slot
        ev(clause.body, f)
      ensure
        @handling.pop
      end
    else
      n.else_ ? ev(n.else_, f) : result
    end

    def case_match(n, f)
      v = ev(n.subject, f)
      clause = n.clauses.find { |pat, _| pattern_match?(v, pat, f) }
      return ev(clause[1], f) if clause
      return ev(n.else_, f) if n.else_
      what = n.origin.is_a?(Prism::MatchRequiredNode) ? "`=> #{n.origin.pattern.slice}` does not match" : "no `in` branch matches"
      fail_at(n, "NoMatchingPatternError", "#{what} #{Values.describe(v)}")
    end

    def pattern_match?(v, pat, f)
      case pat
      when PType then pat.name == "Record" ? v.is_a?(RecordValue) : Values.type_of(v) == pat.name
      when PAlt then pattern_match?(v, pat.left, f) || pattern_match?(v, pat.right, f)
      when PRecord
        return false unless v.is_a?(RecordValue) && pat.keys.all? { v.field?(_1) }
        pat.keys.zip(pat.slots) { |k, s| f.slots[s] = v[k] }
        true
      when PValue
        lit = ev(pat.value, f)
        Values.type_of(lit) == Values.type_of(v) && lit == v
      when PTuple then v.is_a?(Tuple) && v.elems.size == pat.elems.size && pat.elems.zip(v.elems).all? { |p, e| pattern_match?(e, p, f) }
      when PBind
        f.slots[pat.slot] = v
        true
      end
    end

    # `value => {x:, y: name}` binds fields of a Record to locals.
    def match_record(n, f)
      v = ev(n.value, f)
      pat = n.origin.pattern
      unless v.is_a?(RecordValue)
        hints = v.is_a?(StructValue) ? ["for a Struct, read a field with `#{v.type.name}.#{n.keys.first}(value)`"] : []
        fail_at(n, "TypeError", "pattern `#{pat.slice}` needs a Record, got #{Values.describe(v)}", hints:)
      end
      n.keys.each_with_index do |field, i|
        unless v.field?(field)
          raise RunError.new("KeyError", "Record #{v.shape.display} has no field `#{field}`", pat.elements[i].location.start_line, @stack.dup, file: where_file(pat.elements[i]))
        end
        f.slots[n.slots[i]] = v[field]
      end
      nil
    end

    # Calls a type's own to_s / inspect, if it has one; nil means "use the built-in form".
    def show_hook(kind, v)
      fn = @program.functions.dig(v.type.name, kind.to_s) or return nil
      s = call_user(fn, [v], nil, fn.node)
      return s if s.is_a?(String)
      raise RunError.new("TypeError", "#{fn.full_name} must return a String, got #{Values.describe(s)}", fn.node.location.start_line, @stack.dup, file: where_file(fn.node))
    end

    RANGE_ENDS = [Integer, Float, String, NilClass].freeze

    def range(n, f)
      l = ev(n.left, f)
      r = ev(n.right, f)
      [l, r].each do |v|
        next if RANGE_ENDS.any? { v.is_a?(_1) }
        fail_at(n, "TypeError", "a Range end must be Integer, Float, or String, got #{Values.describe(v)}")
      end
      Range.new(l, r, n.exclusive)
    rescue ::ArgumentError
      fail_at(n, "ArgumentError", "bad Range: #{Values.inspect(l)}, #{Values.inspect(r)}")
    end

    def loop_node(n, f)
      want = !n.until_
      while Values.truthy?(ev(n.cond, f)) == want
        begin
          ev(n.body, f)
        rescue NextSignal
          next
        rescue BreakSignal => e
          return e.value
        end
      end
      nil
    end

    def multi_write(n, f)
      # The targets' receivers, indexes and subjects are evaluated first, left to right (as Ruby does).
      places = n.targets.map do |t|
        case t
        when TIndex then [ev(t.recv, f), ev(t.key, f)]
        when TField then ev(t.subject, f)
        end
      end
      v = ev(n.value, f)
      # As Ruby: missing elements are nil, extra elements are dropped.
      elems = v.is_a?(Tuple) ? v.elems : (v.is_a?(Array) ? v : nil)
      fail_at(n, "TypeError", "multiple assignment needs a Tuple or an Array, got #{Values.describe(v)}") unless elems
      ri = n.targets.index { _1.is_a?(TRest) }
      elems = Interpreter.spread_rest(elems, ri, n.targets.size - ri - 1) if ri
      n.targets.each_with_index do |t, i|
        case t
        when TLocal then f.slots[t.slot] = elems[i]
        when TRest then f.slots[t.slot] = elems[i] if t.slot
        when TIndex then index_op(t.origin, "[]=", [*places[i], elems[i]])
        when TField then call_builtin(t.fn, [places[i], elems[i]], nil, t.origin)
        end
      end
      v
    end

    # As Ruby's `a, *r, z = elems`: the values of the targets, the rest (at index nleft) an Array.
    def self.spread_rest(elems, nleft, npost)
      post = [nleft, elems.size - npost].max
      [*Array.new(nleft) { elems[_1] }, elems[nleft...post] || [], *Array.new(npost) { elems[post + _1] }]
    end

    # origin: the Prism node of the call, for the line in messages and the stack.
    def call_user(fn, args, blk, origin)
      raise RunError.new("SystemStackError", "stack level too deep", origin.location.start_line, @stack.dup, file: where_file(origin)) if @stack.size >= MAX_DEPTH
      ast = @ast.functions.fetch(fn)
      slots = Array.new(ast.nslots)
      args.each_with_index { |v, i| slots[i] = v }
      (args.size...ast.nparams).each { slots[_1] = MISSING }
      frame = Frame.new(fn.full_name, slots, blk)
      @stack.push([fn.full_name, origin.location.start_line, where_file(origin)])
      begin
        ev(ast.body, frame)
      rescue ReturnSignal => e
        raise unless e.frame.equal?(frame)
        e.value
      rescue ::SystemStackError
        raise RunError.new("SystemStackError", "stack level too deep (the interpreter's Ruby stack is exhausted)",
                           origin.location.start_line, @stack.dup, file: where_file(origin))
      ensure
        @stack.pop
      end
    end

    def call_builtin(fn, args, blk, node)
      kw = {}
      if fn.keyword_types.any? && args.last.is_a?(HashPairs)
        kw = args.last.pairs.to_h
        args = args[0...-1]
        kw.each do |k, v|
          want = fn.keyword_types.fetch(k.to_s)
          next if type_ok?(want, v)
          raise RunError.new("TypeError", "keyword `#{k}:` must be #{Array(want).join(" or ")}, got #{Values.describe(v)}",
                             node.location.start_line, @stack.dup, file: where_file(node), expected: want, nil_value: v.nil?, hints: literal_hints(want, v), op: fn.full_name)
        end
      end
      args.each_with_index do |v, i|
        want = fn.param_type(i)
        next if type_ok?(want, v)
        raise RunError.new("TypeError", "argument #{i + 1} must be #{Array(want).join(" or ")}, got #{Values.describe(v)}",
                           node.location.start_line, @stack.dup, file: where_file(node), expected: want, nil_value: v.nil?, hints: literal_hints(want, v), op: fn.full_name)
      end
      return once_value(blk, node) if fn.full_name == "Kernel.once"
      # Array.sum over values of a type with its own + (include Arithmetic): folded with that +, from the initial
      # value when given, else from the first element (Ruby would start from 0, which no user type can be added to).
      if fn.full_name == "Array.sum" && (args[0].any? { _1.is_a?(StructValue) } || args[1].is_a?(StructValue))
        xs = blk ? args[0].map { call_block(blk, [_1], node) } : args[0]
        xs = [args[1], *xs] if args.size > 1
        return xs.empty? ? 0 : xs.drop(1).reduce(xs[0]) { |acc, x| binary_op(node, "+", acc, x) }
      end
      if fn.full_name == "Kernel.dup" && args[0].is_a?(StructValue) && (own = @program.functions.dig(args[0].type.name, "dup"))
        return call_user(own, args, nil, node) # T.dup, when the type defines it
      end
      ruby_blk = blk && (fn.full_name == "Thread.new" ? thread_body(blk, node) : ->(*xs) { call_block(blk, xs, node) })
      v = fn.impl.call(*args, **kw, &ruby_blk)
      if fn.name == "new" && v.is_a?(StructValue)
        init = @program.functions.dig(fn.namespace, "initialize")
        call_user(init, [v], nil, node) if init # after the fields are stored, as Ruby's initialize
      end
      v
    rescue Fail, *RUBY_ERROR_CLASSES => e
      raise ruby_run_error(e, node, fn.full_name)
    end

    # once { ... }: one value per place in the program, shared by threads (copies of this interpreter
    # share @once). A block that reaches its own once again while computing it is an error.
    def once_value(blk, node)
      @once ||= { lock: Monitor.new, values: {}.compare_by_identity, running: {}.compare_by_identity }
      @once[:lock].synchronize do
        values = @once[:values]
        return values[node] if values.key?(node)
        if @once[:running][node]
          raise RunError.new("SystemStackError", "once: the block reached its own once again while computing it",
                             node.location.start_line, @stack.dup, file: where_file(node))
        end
        @once[:running][node] = true
        begin
          values[node] = call_block(blk, [], node)
        ensure
          @once[:running].delete(node)
        end
      end
    end

    # Thread.new's block runs on a copy of this interpreter with its own stack: the program, the
    # frames and so the variables around the block are shared.
    def thread_body(blk, node)
      child = clone
      child.instance_variable_set(:@stack, @stack.dup)
      child.instance_variable_set(:@handling, [])
      child.instance_variable_set(:@running_blocks, [])
      hooks = [Thread.current[:sake_show_hooks], Thread.current[:sake_struct_ops]]
      path = @program.path
      f = blk.frame
      own = block_slots(f.name)
      thread_blk = BlockVal.new(blk.node, Frame.new(f.name, ThreadSlots.new(f.slots, own), f.block))
      lambda do
        Thread.current[:sake_show_hooks], Thread.current[:sake_struct_ops] = hooks
        child.send(:call_block, thread_blk, [], node)
      rescue JumpSignal, ReturnSignal
        raise RunError.new("LocalJumpError", "break or return out of a Thread.new block", line(node), @stack.dup, file: where_file(node))
      rescue RunError => e
        e.path ||= path
        raise
      end
    end

    # The slots of a function's blocks (their parameters and locals).
    def block_slots(name)
      (@block_slots ||= {})[name] ||= begin
        fn = name == "<main>" ? @ast.main : @ast.functions.values.find { _1.name == name }
        slots = []
        walk = lambda do |x|
          case x
          when AST::Block then slots.concat(x.params, x.locals)
          when Array then x.each { walk.(_1) }
          end
          x.each { |v| walk.(v) } if x.is_a?(Struct) && !x.is_a?(AST::Function)
        end
        walk.(fn.body)
        slots.uniq
      end
    end

    # Ruby habits: `result = []` / `{}` used as a growable collection.
    def literal_hints(want, v)
      return [] unless Array(want).include?("Array")
      case v
      when Tuple then ["`[...]` is a Tuple with a fixed length; for a growable Array, write `Array[...]`"]
      when RecordValue then ["`{...}` is a Record; for a growable collection, write `Array[...]` or `Hash[...]`"]
      else []
      end
    end

    def type_ok?(want, v)
      return true if want == "Any"
      Array(want).include?(Values.type_of(v))
    end

    # `a OP b`: a Struct operand runs its type's own operator; built-in types use the table of rows.
    # node: the Prism node (for messages).
    def binary_op(node, op, a, b)
      op = op.to_s
      mod = Operators::MODULE_OF.fetch(op)
      return a.public_send(op, b) if %w[== !=].include?(op) && (a.nil? || b.nil?)
      return user_op(node, mod, op, [a, b]) if a.is_a?(StructValue)
      # A value of another type is never equal to a Struct value (as `struct == other` says).
      return op == "!=" if %w[== !=].include?(op) && b.is_a?(StructValue)
      # `1 + money`: a class on the right that defines coerce(b, a) -> [a', b'] (Ruby's protocol) has the pair
      # converted and the operator run on it (dispatched on a', usually a value of its own type).
      if b.is_a?(StructValue) && (co = own_fn(b.type.name, "coerce"))
        pair = call_user(co, [b, a], nil, node)
        unless pair.is_a?(Tuple) && pair.elems.size == 2
          fail_at(node, "TypeError", "#{b.type.name}.coerce must give a Tuple [left, right], got #{Values.describe(pair)}")
        end
        return binary_op(node, op, pair.elems[0], pair.elems[1])
      end
      # Records compare by their fields (any two shapes; different shapes are not equal).
      return a.public_send(op, b) if %w[== !=].include?(op) && a.is_a?(RecordValue) && b.is_a?(RecordValue)
      # format % {name: v}: the Record's fields name the values (Ruby's `%<name>s` with a Hash).
      return @registry.binary_ops["%"][%w[String Record]].call(a, b) if op == "%" && a.is_a?(String) && b.is_a?(RecordValue)
      rows = @registry.binary_ops[op]
      key = [Values.type_of(a), Values.type_of(b)]
      impl = rows[key]
      return op == "!=" if !impl && %w[== !=].include?(op) # values of different types are not equal (Ruby)
      unless impl
        nil_rows, plain = rows.keys.partition { |r| r.include?("Nil") && r.uniq.size == 2 }
        # Pairs of numbers are listed once, as one entry naming the number types involved.
        nums = Stdlib::NUMERIC
        num_rows, plain = plain.partition { |r| r.all? { nums.include?(_1) } }
        defined = num_rows.empty? ? [] : ["(any two of #{nums.select { |n| num_rows.flatten.include?(n) }.join(", ")})"]
        defined += plain.map { |r| "(#{r.map { Values.display_type(_1) }.join(", ")})" }
        defined << "(any, nil), (nil, any)" unless nil_rows.empty?
        defined = defined.join(", ")
        raise RunError.new("TypeError", "no implementation for (#{Values.describe(a)}, #{Values.describe(b)}); defined for #{defined}",
                           node.location.start_line, @stack.dup, file: where_file(node), nil_value: a.nil? || b.nil?, op: "#{mod}.#{op}")
      end
      impl.call(a, b)
    rescue Fail, *RUBY_ERROR_CLASSES => e
      raise ruby_run_error(e, node, "#{mod}.#{op}")
    end

    # Strings of incompatible encodings (a byte from Integer.chr(227) next to UTF-8 text) meeting.
    def encoding_error(n)
      yield
    rescue ::EncodingError => e
      fail_at(n, "EncodingError", e.message)
    end

    # `-x` / `+x` / `~x`: a Struct value runs its type's own operator; built-in types use their table.
    def unary_op(node, op, a)
      mod = Operators::MODULE_OF.fetch(op)
      return user_op(node, mod, op, [a]) if a.is_a?(StructValue)
      impl = @registry.unary_ops[op][Values.type_of(a)]
      unless impl
        defined = @registry.unary_ops[op].keys.join(", ")
        raise RunError.new("TypeError", "no implementation for #{Values.describe(a)}; defined for #{defined}",
                           node.location.start_line, @stack.dup, file: where_file(node), nil_value: a.nil?, op: "#{mod}.#{op}")
      end
      impl.call(a)
    rescue Fail, *RUBY_ERROR_CLASSES => e
      raise ruby_run_error(e, node, "#{mod}.#{op}")
    end

    # `x[k]` / `x[k] = v`: the index operation of x's type.
    def index_op(node, op, xs)
      recv = xs[0]
      return user_op(node, "Indexable", op, xs) if recv.is_a?(StructValue)
      fn = @registry.lookup(Values.type_of(recv), op)
      unless fn
        raise RunError.new("TypeError", "Indexable.#{op}: #{Values.describe(recv)} cannot be indexed#{op == "[]=" ? " for writing" : ""}",
                           node.location.start_line, @stack.dup, file: where_file(node), nil_value: recv.nil?)
      end
      call_builtin(fn, xs, nil, node)
    end

    def own_fn(type, name) = @program.functions.dig(type, name)

    # An operator on a Struct value: the type must include the module and define the operator.
    # Comparable builds < <= > >= from <=>; == compares fields unless the type defines its own.
    def user_op(node, mod, op, args)
      recv = args[0]
      type = recv.type.name
      if %w[== !=].include?(op)
        eq = struct_equal?(recv, args[1])
        return op == "==" ? eq : !eq
      end
      fail_node = ->(msg, kind = "TypeError") { raise RunError.new(kind, msg, node.location.start_line, @stack.dup, file: where_file(node), op: "#{mod}.#{op}") }
      fail_node.("#{type} does not include #{mod}") unless Operators.includes?(@program.includes, type, mod)
      if (fn = own_fn(type, op))
        return call_user(fn, args, nil, node)
      end
      if mod == "Comparable" && (cmp = own_fn(type, "<=>"))
        r = call_user(cmp, args, nil, node)
        fail_node.("comparison of #{type} with #{Values.describe(args[1])} failed", "ArgumentError") unless r.is_a?(Integer)
        return { "<" => r.negative?, "<=" => r <= 0, ">" => r.positive?, ">=" => r >= 0 }.fetch(op)
      end
      need = mod == "Comparable" && op != "<=>" ? "#{op} or <=>" : op
      fail_node.("#{type} does not define #{need}")
    end

    # A type's own ==; else, with Comparable and <=>, a value of the same type is equal when `a <=> b` is 0
    # (as Ruby's Comparable#==; `x == nil` never calls <=>); else the fields.
    def struct_equal?(a, b)
      if (fn = own_fn(a.type.name, "=="))
        return Values.truthy?(call_user(fn, [a, b], nil, fn.node))
      end
      if Operators.includes?(@program.includes, a.type.name, "Comparable") && (cmp = own_fn(a.type.name, "<=>"))
        return true if a.equal?(b)
        return false unless b.is_a?(StructValue) && b.type.equal?(a.type) # nil and other types are not equal
        return call_user(cmp, [a, b], nil, cmp.node) == 0
      end
      b.is_a?(StructValue) && b.type.equal?(a.type) && a.values == b.values
    end

    # Ruby-level == and <=> of Struct values (Array.include?, sort, ...) use the type's own definitions.
    def struct_ruby_op(kind, a, b)
      return struct_equal?(a, b) if kind == :==
      fn = own_fn(a.type.name, "<=>") or return nil
      call_user(fn, [a, b], nil, fn.node)
    end

    # node: the Prism node of the call or yield that runs the block.
    def call_block(blk, args, node)
      raise RunError.new("LocalJumpError", "no block given (yield)", node.location.start_line, @stack.dup, file: where_file(node)) unless blk
      b = blk.node
      params = b.params
      fixed = params.size - (b.rest ? 1 : 0)
      # A Tuple passed to a block with several parameters is destructured.
      if (params.size > 1 || (b.rest && fixed >= 1)) && args.size == 1
        # As Ruby: a Tuple or an Array is spread over the parameters, nil for missing elements.
        elems = args.first.is_a?(Tuple) ? args.first.elems : (args.first.is_a?(Array) ? args.first.to_a : nil)
        args = b.rest ? elems : Array.new(params.size) { elems[_1] } if elems
      end
      if b.rest
        if !elems && args.size < fixed
          raise RunError.new("ArgumentError", "block takes at least #{fixed} parameter(s) but was given #{args.size}",
                             b.origin.location.start_line, @stack.dup, file: where_file(b.origin))
        end
        args = Interpreter.spread_rest(args, b.rest, fixed - b.rest)
      elsif !params.empty? && params.size != args.size
        raise RunError.new("ArgumentError", "block takes #{params.size} parameter(s) but was given #{args.size}",
                           b.origin.location.start_line, @stack.dup, file: where_file(b.origin))
      end
      slots = blk.frame.slots
      b.locals.each { slots[_1] = nil }
      params.each_with_index { |s, i| slots[s] = args[i] }
      @running_blocks.push(blk)
      begin
        ev(b.body, blk.frame)
      ensure
        @running_blocks.pop
      end
    rescue NextSignal => e
      e.value
    end
  end
end
