# frozen_string_literal: true

require_relative "errors"
require_relative "ast"
require_relative "values"
require_relative "text"
require_relative "operators"
require_relative "environment"
require_relative "builtins"

module Mini
  # Evaluates a checked syntax tree (SPEC sections 6 to 9).
  #
  # Statements return a completion: nil when they finish normally, or BREAK,
  # CONTINUE or a ReturnSignal, which the enclosing loop or call consumes.
  # Runtime errors (EvalError) and `throw` (Thrown) travel as Ruby exceptions.
  class Interpreter
    include AST

    MAX_CALL_DEPTH = 150
    BREAK = :break
    CONTINUE = :continue
    ReturnSignal = Struct.new(:value)

    # An assignment target after its parts have been evaluated: a variable
    # (`name` set) or an element of a container.
    Place = Struct.new(:name, :container, :key, :position)

    def initialize(output)
      @output = output
      @call_depth = 0
      @globals = Environment.new(nil)
      Builtins::TABLE.each { |name, builtin| @globals.define(name, builtin) }
    end

    def run(program)
      execute_body(program.body, Environment.new(@globals))
      nil
    end

    def write_line(text)
      @output.write(text, "\n")
    end

    # Calls a function value; errors about the call itself are reported at
    # `position` (the `(` of the call).
    def call_function(function, args, position)
      case function
      when Builtin
        check_arity(function.name, function.min, function.max, args.size, position)
        function.impl.call(Builtins::Invocation.new(function, args, position, self))
      when UserFunction
        check_arity(function.display_name, function.min_arity, function.max_arity, args.size, position)
        call_user_function(function, args, position)
      else
        raise EvalError.new(:type, "cannot call #{Values.type_name(function)}", position)
      end
    end

    private

    def check_arity(name, min, max, given, position)
      return if given >= min && (max.nil? || given <= max)

      raise EvalError.new(:arity, Mini.arity_message(name, min, max, given), position)
    end

    def call_user_function(function, args, position)
      if @call_depth >= MAX_CALL_DEPTH
        raise EvalError.new(:stack, "call depth exceeded #{MAX_CALL_DEPTH}", position)
      end

      @call_depth += 1
      begin
        env = Environment.new(function.closure)
        function.params.each_with_index do |param, i|
          env.define(param.name.text, i < args.size ? args[i] : evaluate(param.default, env))
        end
        completion = execute_body(function.body, env)
        completion.is_a?(ReturnSignal) ? completion.value : nil
      ensure
        @call_depth -= 1
      end
    end

    # --- statements ---

    # Runs a statement list in `env`. Its function declarations exist from
    # the start of the list (SPEC 6.4).
    def execute_body(body, env)
      body.each do |stmt|
        env.define(stmt.name.text, UserFunction.new(stmt.function, env)) if stmt.is_a?(FnDecl)
      end
      body.each do |stmt|
        completion = execute(stmt, env)
        return completion if completion
      end
      nil
    end

    def execute_block(body, env) = execute_body(body, Environment.new(env))

    def execute(stmt, env)
      case stmt
      when ExprStmt
        evaluate(stmt.expression, env)
        nil
      when Let
        env.define(stmt.name.text, stmt.value ? evaluate(stmt.value, env) : nil)
        nil
      when Const
        env.define(stmt.name.text, evaluate(stmt.value, env))
        nil
      when LetArray then execute_let_array(stmt, env)
      when FnDecl then nil # created when its statement list started
      when Assign then execute_assign(stmt, env)
      when MultiAssign then execute_multi_assign(stmt, env)
      when If then execute_if(stmt, env)
      when Match then execute_match(stmt, env)
      when While then execute_while(stmt, env)
      when For then execute_for(stmt, env)
      when Break then BREAK
      when Continue then CONTINUE
      when Return then ReturnSignal.new(stmt.value ? evaluate(stmt.value, env) : nil)
      when Throw then raise Thrown.new(evaluate(stmt.value, env), stmt.position)
      when Assert then execute_assert(stmt, env)
      when Try then execute_try(stmt, env)
      else raise ArgumentError, "unknown statement #{stmt.class}"
      end
    end

    def execute_let_array(stmt, env)
      value = evaluate(stmt.value, env)
      unless value.is_a?(Array)
        raise EvalError.new(:type, "cannot destructure #{Values.type_name(value)}", stmt.position)
      end
      if value.size != stmt.names.size
        message = "expected #{Mini.plural(stmt.names.size, "element")}, got #{value.size}"
        raise EvalError.new(:value, message, stmt.position)
      end
      stmt.names.zip(value) { |name, element| env.define(name.text, element) }
      nil
    end

    def execute_assign(stmt, env)
      place = evaluate_place(stmt.target, env)
      value = evaluate(stmt.value, env)
      unless stmt.operator == "="
        value = Operators.binary(stmt.operator.delete_suffix("="), read_place(place, env), value, stmt.position)
      end
      write_place(place, value, env)
      nil
    end

    # All targets' parts, then all values, then the stores (SPEC 6.3).
    def execute_multi_assign(stmt, env)
      places = stmt.targets.map { |target| evaluate_place(target, env) }
      values = stmt.values.map { |value| evaluate(value, env) }
      places.zip(values) { |place, value| write_place(place, value, env) }
      nil
    end

    def evaluate_place(target, env)
      case target
      when Name then Place.new(target, nil, nil, target.position)
      when Index then Place.new(nil, evaluate(target.object, env), evaluate(target.index, env), target.position)
      when Field then Place.new(nil, evaluate(target.object, env), target.name, target.position)
      end
    end

    def read_place(place, env)
      if place.name
        env.lookup(place.name.text, place.name.hops, place.position)
      else
        Operators.index(place.container, place.key, place.position)
      end
    end

    def write_place(place, value, env)
      if place.name
        env.assign(place.name.text, place.name.hops, value, place.position)
      else
        Operators.set_index(place.container, place.key, value, place.position)
      end
    end

    def execute_if(stmt, env)
      stmt.branches.each do |branch|
        return execute_block(branch.body, env) if Values.truthy?(evaluate(branch.condition, env))
      end
      stmt.else_body ? execute_block(stmt.else_body, env) : nil
    end

    def execute_match(stmt, env)
      subject = evaluate(stmt.subject, env)
      stmt.arms.each do |arm|
        arm.values.each do |value|
          return execute_block(arm.body, env) if Values.equal?(subject, evaluate(value, env), stmt.position)
        end
      end
      stmt.else_body ? execute_block(stmt.else_body, env) : nil
    end

    def execute_while(stmt, env)
      while Values.truthy?(evaluate(stmt.condition, env))
        completion = execute_block(stmt.body, env)
        break if completion == BREAK
        return completion if completion.is_a?(ReturnSignal)
      end
      nil
    end

    # Iterates over a snapshot: [element] or [index, element] for an array,
    # [key] or [key, value] for a map.
    def execute_for(stmt, env)
      iterable = evaluate(stmt.iterable, env)
      two = stmt.names.size == 2
      rows =
        case iterable
        when Array then two ? iterable.each_with_index.map { |e, i| [i, e] } : iterable.map { |e| [e] }
        when Hash then two ? iterable.to_a : iterable.keys.map { |k| [k] }
        else raise EvalError.new(:type, "cannot iterate over #{Values.type_name(iterable)}", stmt.position)
        end
      rows.each do |row|
        scope = Environment.new(env)
        stmt.names.zip(row) { |name, value| scope.define(name.text, value) }
        completion = execute_body(stmt.body, scope)
        break if completion == BREAK
        return completion if completion.is_a?(ReturnSignal)
      end
      nil
    end

    def execute_assert(stmt, env)
      return nil if Values.truthy?(evaluate(stmt.condition, env))

      message = "assertion failed"
      message += ": #{Text.str(evaluate(stmt.message, env))}" if stmt.message
      raise EvalError.new(:assert, message, stmt.position)
    end

    # SPEC section 9. What happened in the body (or handler) is either a
    # completion or a pending exception; a `finally` that does not complete
    # normally replaces it.
    def execute_try(stmt, env)
      completion = nil
      pending = nil
      begin
        completion = execute_block(stmt.body, env)
      rescue EvalError, Thrown => e
        pending = e
      end
      if pending && stmt.catch_body
        caught = pending
        pending = nil
        begin
          handler_env = Environment.new(env)
          handler_env.define(stmt.catch_name.text, caught.is_a?(Thrown) ? caught.value : caught.to_value)
          completion = execute_body(stmt.catch_body, handler_env)
        rescue EvalError, Thrown => e
          pending = e
        end
      end
      if stmt.finally_body
        final = execute_block(stmt.finally_body, env)
        return final if final
      end
      raise pending if pending

      completion
    end

    # --- expressions ---

    def evaluate(node, env)
      case node
      when Literal then node.value
      when Name then env.lookup(node.text, node.hops, node.position)
      when Binary
        left = evaluate(node.left, env)
        Operators.binary(node.operator, left, evaluate(node.right, env), node.position)
      when Logical
        left = evaluate(node.left, env)
        if node.operator == "and"
          Values.truthy?(left) ? evaluate(node.right, env) : left
        else
          Values.truthy?(left) ? left : evaluate(node.right, env)
        end
      when Not then !Values.truthy?(evaluate(node.operand, env))
      when Negate then Operators.negate(evaluate(node.operand, env), node.position)
      when Call
        callee = evaluate(node.callee, env)
        args = node.arguments.map { |argument| evaluate(argument, env) }
        call_function(callee, args, node.position)
      when Index
        object = evaluate(node.object, env)
        Operators.index(object, evaluate(node.index, env), node.position)
      when Field then Operators.index(evaluate(node.object, env), node.name, node.position)
      when Slice then evaluate_slice(node, env)
      when Interpolation
        node.parts.map { |part| part.is_a?(String) ? part : Text.str(evaluate(part, env)) }.join
      when ArrayLit then node.elements.map { |element| evaluate(element, env) }
      when MapLit then evaluate_map(node, env)
      when FunctionLit then UserFunction.new(node, env)
      else raise ArgumentError, "unknown expression #{node.class}"
      end
    end

    def evaluate_slice(node, env)
      object = evaluate(node.object, env)
      from = node.from ? evaluate(node.from, env) : Operators::OMITTED
      to = node.to ? evaluate(node.to, env) : Operators::OMITTED
      Operators.slice(object, from, to, node.position)
    end

    def evaluate_map(node, env)
      map = {}
      node.entries.each do |entry|
        key = evaluate(entry.key, env)
        value = evaluate(entry.value, env)
        Operators.check_key(key, entry.position)
        map[key] = value
      end
      map
    end
  end
end
