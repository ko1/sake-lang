# frozen_string_literal: true

module Sake
  # Evaluates the Prism AST directly, using the call targets fixed by Resolver.
  class Interpreter
    Frame = Struct.new(:name, :block, :ns)
    SakeBlock = Struct.new(:node, :params, :env)

    class Env
      attr_reader :parent, :frame, :vars

      def initialize(parent, frame)
        @parent = parent
        @frame = frame
        @vars = {}
      end

      def up(depth)
        e = self
        depth.times { e = e.parent }
        e
      end
    end

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
    class RetrySignal < StandardError; end

    MAX_DEPTH = 10_000

    def initialize(program)
      @program = program
      @registry = program.registry
      @stack = [] # [function name, call line]
      @handling = [] # errors being handled by rescue clauses, innermost last (for a bare `raise`)
    end

    def run
      env = Env.new(nil, Frame.new("<main>", nil, nil))
      @program.toplevel.each { eval_node(_1, env) }
      nil
    end

    private

    def fail_at(node, kind, message, **opts)
      raise RunError.new(kind, message, node.location.start_line, @stack.dup, **opts)
    end

    def eval_node(node, env)
      case node
      when nil then nil
      when Prism::StatementsNode
        v = nil
        node.body.each { v = eval_node(_1, env) }
        v
      when Prism::IntegerNode, Prism::FloatNode, Prism::RationalNode, Prism::ImaginaryNode then node.value
      when Prism::StringNode then node.unescaped.dup
      when Prism::SymbolNode then node.unescaped.to_sym
      when Prism::RegularExpressionNode then regexp(node)
      when Prism::RangeNode then range(node, env)
      when Prism::KeywordHashNode then HashPairs.new(node.elements.map { [eval_node(_1.key, env), eval_node(_1.value, env)] })
      when Prism::TrueNode then true
      when Prism::FalseNode then false
      when Prism::NilNode then nil
      when Prism::LocalVariableReadNode then env.up(node.depth).vars[node.name]
      # Prism gives every block that mentions `it` its own implicit parameter.
      when Prism::ItLocalVariableReadNode then env.vars[:it]
      when Prism::LocalVariableWriteNode
        env.up(node.depth).vars[node.name] = eval_node(node.value, env)
      when Prism::LocalVariableOperatorWriteNode
        scope = env.up(node.depth)
        scope.vars[node.name] = binary_op(node, node.binary_operator, scope.vars[node.name], eval_node(node.value, env))
      when Prism::MultiWriteNode then multi_write(node, env)
      when Prism::LocalVariableOrWriteNode
        scope = env.up(node.depth)
        cur = scope.vars[node.name]
        Values.truthy?(cur) ? cur : (scope.vars[node.name] = eval_node(node.value, env))
      when Prism::IndexOperatorWriteNode, Prism::IndexOrWriteNode then index_update(node, env)
      when Prism::IfNode
        if Values.truthy?(eval_node(node.predicate, env))
          eval_node(node.statements, env)
        else
          eval_node(node.subsequent, env)
        end
      when Prism::UnlessNode
        if Values.truthy?(eval_node(node.predicate, env))
          eval_node(node.else_clause, env)
        else
          eval_node(node.statements, env)
        end
      when Prism::ElseNode then eval_node(node.statements, env)
      when Prism::WhileNode, Prism::UntilNode then loop_node(node, env)
      when Prism::AndNode
        l = eval_node(node.left, env)
        Values.truthy?(l) ? eval_node(node.right, env) : l
      when Prism::OrNode
        l = eval_node(node.left, env)
        Values.truthy?(l) ? l : eval_node(node.right, env)
      when Prism::ParenthesesNode then eval_node(node.body, env)
      when Prism::ArrayNode then Tuple.new(node.elements.map { eval_node(_1, env) })
      when Prism::HashNode then RecordValue.build(node.elements.map { [_1.key.unescaped, eval_node(_1.value, env)] })
      when Prism::MatchRequiredNode then match_record(node, env)
      when Prism::BeginNode then begin_node(node, env)
      when Prism::RescueModifierNode
        begin
          eval_node(node.expression, env)
        rescue RunError => e
          raise unless rescuable?(e)
          eval_node(node.rescue_expression, env)
        end
      when Prism::RetryNode then raise RetrySignal
      when Prism::MatchPredicateNode then pattern_match?(eval_node(node.value, env), node.pattern, env)
      when Prism::CaseMatchNode then case_match(node, env)
      when Prism::ReturnNode then raise ReturnSignal.new(env.frame, jump_value(node, env, tuple: true))
      when Prism::NextNode then raise NextSignal.new(jump_value(node, env))
      when Prism::BreakNode then raise BreakSignal.new(jump_value(node, env))
      when Prism::YieldNode
        call_block(env.frame.block, eval_args(node.arguments, env), node)
      when Prism::CallNode then call(node, env)
      when Prism::InstanceVariableReadNode
        fa = target_of(node, env)
        call_builtin(fa.getter, [subject(env, fa)], nil, node)
      when Prism::InstanceVariableWriteNode
        fa = target_of(node, env)
        recv = subject(env, fa)
        call_builtin(fa.setter, [recv, eval_node(node.value, env)], nil, node)
      when Prism::InstanceVariableOperatorWriteNode
        fa = target_of(node, env)
        recv = subject(env, fa)
        cur = call_builtin(fa.getter, [recv], nil, node)
        call_builtin(fa.setter, [recv, binary_op(node, node.binary_operator, cur, eval_node(node.value, env))], nil, node)
      else raise "BUG: unchecked node #{node.type} at line #{node.location.start_line}"
      end
    end

    def target_of(node, env) = @program.calls.fetch(node).fetch(env.frame.ns)

    # The function's first parameter, even inside blocks that shadow its name.
    def subject(env, fa)
      env = env.parent while env.parent
      env.vars[fa.param]
    end

    # `x[k] OP= v` and `x[k] ||= v`: the receiver and index are evaluated once.
    def index_update(node, env)
      recv = eval_node(node.receiver, env)
      key = eval_node(node.arguments.arguments.first, env)
      cur = call_builtin(@registry.lookup("Index", "[]"), [recv, key], nil, node)
      if node.is_a?(Prism::IndexOrWriteNode)
        return cur if Values.truthy?(cur)
        val = eval_node(node.value, env)
      else
        val = binary_op(node, node.binary_operator, cur, eval_node(node.value, env))
      end
      call_builtin(@registry.lookup("Index", "[]="), [recv, key, val], nil, node)
    end

    NOT_RESCUABLE = Resolver::NOT_RESCUABLE

    def rescuable?(e) = !NOT_RESCUABLE.include?(e.kind)

    def exception_type(name) = @program.struct_types.fetch(name)

    # The exception value of an error, built from its kind and message when an operation raised it.
    def exception_value(e)
      e.value ||= StructValue.new(exception_type(e.kind), [e.message])
    end

    def do_raise(node, env)
      nodes = node.arguments&.arguments || []
      raise @handling.last if nodes.empty?

      args = nodes.size == 2 ? [nil, eval_node(nodes[1], env)] : [eval_node(nodes[0], env)]
      value =
        if args.size == 2
          type = exception_type(nodes[0].slice)
          fail_at(node, "TypeError", "raise: the message must be String, got #{Values.describe(args[1])}") unless args[1].is_a?(String)
          StructValue.new(type, [args[1]])
        elsif args[0].is_a?(String)
          StructValue.new(exception_type("RuntimeError"), [args[0]])
        elsif args[0].is_a?(StructValue) && args[0].type.exception
          args[0]
        else
          fail_at(node, "TypeError", "raise needs a String or an exception, got #{Values.describe(args[0])}")
        end
      err = RunError.new(value.type.name, Values.to_s(value.values[0]), node.location.start_line, @stack.dup)
      err.value = value
      raise err
    end

    # `retry` in a rescue clause runs the begin body again; ensure runs once, when leaving.
    def begin_node(node, env)
      loop do
        return run_begin(node, env)
      rescue RetrySignal
        next
      end
    ensure
      eval_node(node.ensure_clause.statements, env) if node.ensure_clause
    end

    def run_begin(node, env)
      result = eval_node(node.statements, env)
    rescue RunError => e
      clause = rescuable?(e) && find_clause(node.rescue_clause, e)
      raise unless clause
      @handling.push(e)
      begin
        env.up(clause.reference.depth).vars[clause.reference.name] = exception_value(e) if clause.reference
        eval_node(clause.statements, env)
      ensure
        @handling.pop
      end
    else
      node.else_clause ? eval_node(node.else_clause, env) : result
    end

    def find_clause(clause, e)
      while clause
        names = clause.exceptions.map(&:slice)
        return clause if names.empty? || names.include?(e.kind)
        clause = clause.subsequent
      end
      nil
    end

    def case_match(node, env)
      v = eval_node(node.predicate, env)
      branch = node.conditions.find { pattern_match?(v, _1.pattern, env) }
      return eval_node(branch.statements, env) if branch
      return eval_node(node.else_clause, env) if node.else_clause
      fail_at(node, "NoMatchingPatternError", "no `in` branch matches #{Values.describe(v)}")
    end

    def pattern_match?(v, pat, env)
      case pat
      when Prism::ConstantReadNode
        name = pat.name.to_s
        name == "Record" ? v.is_a?(RecordValue) : Values.type_of(v) == name
      when Prism::AlternationPatternNode then pattern_match?(v, pat.left, env) || pattern_match?(v, pat.right, env)
      when Prism::HashPatternNode
        return false unless v.is_a?(RecordValue) && pat.elements.all? { v.field?(_1.key.unescaped) }
        pat.elements.each do |el|
          target = el.value.is_a?(Prism::ImplicitNode) ? el.value.value : el.value
          env.up(target.depth).vars[target.name] = v[el.key.unescaped]
        end
        true
      else
        lit = eval_node(pat, env)
        Values.type_of(lit) == Values.type_of(v) && lit == v
      end
    end

    # `value => {x:, y: name}` binds fields of a Record to locals.
    def match_record(node, env)
      v = eval_node(node.value, env)
      pat = node.pattern
      unless v.is_a?(RecordValue)
        hints = v.is_a?(StructValue) ? ["for a Struct, read a field with `#{v.type.name}.get_#{pat.elements.first.key.unescaped}(value)`"] : []
        fail_at(node, "TypeError", "pattern `#{pat.slice}` needs a Record, got #{Values.describe(v)}", hints:)
      end
      pat.elements.each do |el|
        field = el.key.unescaped
        fail_at(el, "KeyError", "Record #{v.shape.display} has no field `#{field}`") unless v.field?(field)
        target = el.value.is_a?(Prism::ImplicitNode) ? el.value.value : el.value
        env.up(target.depth).vars[target.name] = v[field]
      end
      nil
    end

    def regexp(node)
      opts = 0
      opts |= Regexp::IGNORECASE if node.ignore_case?
      opts |= Regexp::EXTENDED if node.extended?
      opts |= Regexp::MULTILINE if node.multi_line?
      Regexp.new(node.unescaped, opts)
    end

    RANGE_ENDS = [Integer, Float, String, NilClass].freeze

    def range(node, env)
      l = eval_node(node.left, env)
      r = eval_node(node.right, env)
      [l, r].each do |v|
        next if RANGE_ENDS.any? { v.is_a?(_1) }
        fail_at(node, "TypeError", "a Range end must be Integer, Float, or String, got #{Values.describe(v)}")
      end
      Range.new(l, r, node.exclude_end?)
    rescue ::ArgumentError
      fail_at(node, "ArgumentError", "bad Range: #{Values.inspect(l)}, #{Values.inspect(r)}")
    end

    def jump_value(node, env, tuple: false)
      vals = eval_args(node.arguments, env)
      tuple && vals.size > 1 ? Tuple.new(vals) : vals.first
    end

    def eval_args(args_node, env) = (args_node&.arguments || []).map { eval_node(_1, env) }

    def loop_node(node, env)
      want = node.is_a?(Prism::WhileNode)
      while Values.truthy?(eval_node(node.predicate, env)) == want
        begin
          eval_node(node.statements, env)
        rescue NextSignal
          next
        rescue BreakSignal => e
          return e.value
        end
      end
      nil
    end

    def multi_write(node, env)
      v = eval_node(node.value, env)
      fail_at(node, "TypeError", "multiple assignment needs a Tuple, got #{Values.describe(v)}") unless v.is_a?(Tuple)
      if v.elems.size != node.lefts.size
        fail_at(node, "ArgumentError", "multiple assignment of #{node.lefts.size} variables from a Tuple of size #{v.elems.size}")
      end
      node.lefts.zip(v.elems) { |t, x| env.up(t.depth).vars[t.name] = x }
      v
    end

    def call(node, env)
      target = target_of(node, env)
      if target == :binary_op
        return binary_op(node, node.name, eval_node(node.receiver, env), eval_node(node.arguments.arguments.first, env))
      end

      return do_raise(node, env) if target == :raise
      if target.is_a?(IndexCall)
        return call_builtin(target.builtin, [eval_node(node.receiver, env), *eval_args(node.arguments, env)], nil, node)
      end

      args = eval_args(node.arguments, env)
      blk = node.block && SakeBlock.new(node.block, @program.blocks.fetch(node.block), env)
      case target
      when UserFunction then call_user(target, args, blk, node)
      when Builtin then call_builtin(target, args, blk, node)
      end
    end

    def call_user(fn, args, blk, node)
      fail_at(node, "SystemStackError", "stack level too deep") if @stack.size >= MAX_DEPTH
      frame = Frame.new(fn.full_name, blk, fn.namespace)
      env = Env.new(nil, frame)
      fn.params.zip(args) { |name, v| env.vars[name.to_sym] = v }
      @stack.push([fn.full_name, node.location.start_line])
      begin
        eval_node(fn.body, env)
      rescue ReturnSignal => e
        raise unless e.frame.equal?(frame)
        e.value
      rescue ::SystemStackError
        fail_at(node, "SystemStackError", "stack level too deep (the interpreter's Ruby stack is exhausted)")
      ensure
        @stack.pop
      end
    end

    def call_builtin(fn, args, blk, node)
      args.each_with_index do |v, i|
        want = fn.param_type(i)
        next if type_ok?(want, v)
        fail_at(node, "TypeError", "#{fn.full_name}: argument #{i + 1} must be #{Array(want).join(" or ")}, got #{Values.describe(v)}",
                expected: want, nil_value: v.nil?, hints: literal_hints(want, v))
      end
      ruby_blk = blk && ->(*xs) { call_block(blk, xs, node) }
      fn.impl.call(*args, &ruby_blk)
    rescue Fail => e
      fail_at(node, e.kind, "#{fn.full_name}: #{e.message}")
    end

    # Ruby habits: `result = []` / `{}` used as a growable collection.
    def literal_hints(want, v)
      return [] unless Array(want).include?("Array")
      case v
      when Tuple then ["`[...]` is a Tuple with a fixed length; for a growable Array, write `Array[...]`"]
      when RecordValue then ["`{...}` is a Record; for a growable collection, write `Array[...]` (Hash is not available yet)"]
      else []
      end
    end

    def type_ok?(want, v)
      return true if want == "Any"
      Array(want).include?(Values.type_of(v))
    end

    def binary_op(node, op, a, b)
      return a.public_send(op, b) if %w[== !=].include?(op.to_s) && (a.nil? || b.nil?)
      rows = @registry.binary_ops[op.to_s]
      key = [Values.type_of(a), Values.type_of(b)]
      impl = rows[key]
      unless impl
        nil_rows, plain = rows.keys.partition { |r| r.include?("Nil") && r.uniq.size == 2 }
        # Pairs of numbers are listed once, as one entry naming the number types involved.
        nums = Stdlib::NUMERIC
        num_rows, plain = plain.partition { |r| r.all? { nums.include?(_1) } }
        defined = num_rows.empty? ? [] : ["(any two of #{nums.select { |n| num_rows.flatten.include?(n) }.join(", ")})"]
        defined += plain.map { |r| "(#{r.map { Values.display_type(_1) }.join(", ")})" }
        defined << "(any, nil), (nil, any)" unless nil_rows.empty?
        defined = defined.join(", ")
        fail_at(node, "TypeError", "BinaryOp.#{op}: no implementation for (#{Values.describe(a)}, #{Values.describe(b)}); defined for #{defined}",
                nil_value: a.nil? || b.nil?)
      end
      impl.call(a, b)
    rescue Fail => e
      fail_at(node, e.kind, "BinaryOp.#{op}: #{e.message}")
    end

    def call_block(blk, args, node)
      params = blk.params
      # A Tuple passed to a block with several parameters is destructured.
      args = args.first.elems if params.size > 1 && args.size == 1 && args.first.is_a?(Tuple)
      if !params.empty? && params.size != args.size
        fail_at(blk.node, "ArgumentError", "block takes #{params.size} parameter(s) but was given #{args.size}")
      end
      env = Env.new(blk.env, blk.env.frame)
      params.zip(args) { |name, v| env.vars[name.to_sym] = v }
      eval_node(blk.node.body, env)
    rescue NextSignal => e
      e.value
    end
  end
end
