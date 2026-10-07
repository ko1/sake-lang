require_relative "ast"
require_relative "errors"
require_relative "values"
require_relative "text"
require_relative "operators"
require_relative "builtins"
require_relative "environment"

module Mini
  # Evaluates a checked program (sections 6 to 9).
  #
  # Helpers that do not know positions raise Faults; they are turned into
  # RuntimeErrors at the node the error is reported at (see #at).
  class Interpreter
    include AST

    MAX_CALL_DEPTH = 150

    def initialize(out)
      @out = out
      @call_depth = 0
      @globals = Environment.new
      Builtins::ALL.each_value { |builtin| @globals.define(builtin.name, builtin) }
    end

    def output(text) = @out << text

    # Runs the program; an uncaught throw or runtime error escapes as a
    # RuntimeError carrying the final message.
    def run(statements)
      execute_list(statements, Environment.new(@globals))
    rescue ThrowSignal => e
      raise RuntimeError.new("throw", "uncaught throw #{Text.repr(e.value)}", e.line, e.col)
    end

    # Calls a function value with evaluated arguments; `call` is the node whose
    # "(" call errors are reported at.
    def call_function(function, args, call)
      unless function.is_a?(UserFunction) || function.is_a?(Builtin)
        raise fault_at(call, "type", "cannot call #{Values.type_name(function)}")
      end
      given = args.length
      if given < function.min_args || (function.max_args && given > function.max_args)
        raise fault_at(call, "arity", Values.arity_message(function, given))
      end
      return at(call) { function.impl.call(self, args, call) } if function.is_a?(Builtin)

      if @call_depth >= MAX_CALL_DEPTH
        raise fault_at(call, "stack", "call depth exceeded #{MAX_CALL_DEPTH}")
      end
      call_user_function(function, args)
    end

    private

    # ---- errors ----

    def fault_at(node, kind, message) = RuntimeError.new(kind, message, node.line, node.col)

    # Runs the block, reporting Faults at `node`.
    def at(node)
      yield
    rescue Fault => e
      raise e.at(node.line, node.col)
    end

    # ---- statements ----

    # A statement list in `env`: its function declarations are created first.
    def execute_list(statements, env)
      statements.each do |stmt|
        env.define(stmt.name.text, UserFunction.new(stmt.function, env)) if stmt.is_a?(FnDecl)
      end
      statements.each { |stmt| execute(stmt, env) }
    end

    def execute_block(statements, env) = execute_list(statements, Environment.new(env))

    def execute(stmt, env)
      case stmt
      when ExprStmt then evaluate(stmt.expr, env)
      when Let then env.define(stmt.name.text, stmt.value ? evaluate(stmt.value, env) : nil)
      when Const then env.define(stmt.name.text, evaluate(stmt.value, env))
      when LetArray then execute_let_array(stmt, env)
      when FnDecl then nil
      when Assign then execute_assign(stmt, env)
      when If then execute_if(stmt, env)
      when Match then execute_match(stmt, env)
      when While then execute_while(stmt, env)
      when For then execute_for(stmt, env)
      when Break then raise BreakSignal
      when Continue then raise ContinueSignal
      when Return then raise ReturnSignal.new(stmt.value ? evaluate(stmt.value, env) : nil)
      when Throw then raise ThrowSignal.new(evaluate(stmt.value, env), stmt.line, stmt.col)
      when Assert then execute_assert(stmt, env)
      when Try then execute_try(stmt, env)
      else raise ArgumentError, "unknown statement #{stmt.class}"
      end
    end

    def execute_let_array(stmt, env)
      value = evaluate(stmt.value, env)
      raise fault_at(stmt, "type", "cannot destructure #{Values.type_name(value)}") unless value.is_a?(Array)
      if value.length != stmt.names.length
        raise fault_at(stmt, "value",
                       "expected #{Values.plural(stmt.names.length, "element")}, got #{value.length}")
      end
      stmt.names.each_with_index { |name, i| env.define(name.text, value[i]) }
    end

    def execute_if(stmt, env)
      stmt.branches.each do |condition, body|
        return execute_block(body, env) if Values.truthy?(evaluate(condition, env))
      end
      execute_block(stmt.else_body, env) if stmt.else_body
    end

    def execute_match(stmt, env)
      subject = evaluate(stmt.subject, env)
      stmt.arms.each do |values, body|
        values.each do |value_node|
          value = evaluate(value_node, env)
          return execute_block(body, env) if at(stmt) { Values.equal_values?(subject, value) }
        end
      end
      execute_block(stmt.else_body, env) if stmt.else_body
    end

    def execute_while(stmt, env)
      while Values.truthy?(evaluate(stmt.condition, env))
        begin
          execute_block(stmt.body, env)
        rescue BreakSignal
          break
        rescue ContinueSignal
          next
        end
      end
    end

    # Iterates over a snapshot; each iteration has a fresh scope holding the
    # loop variables and the body's declarations.
    def execute_for(stmt, env)
      collection = evaluate(stmt.iterable, env)
      items =
        case collection
        when Array then collection.each_with_index.map { |element, i| [element, i, element] }
        when Hash then collection.map { |key, value| [key, key, value] }
        else raise fault_at(stmt, "type", "cannot iterate over #{Values.type_name(collection)}")
        end
      items.each do |single, first, second|
        scope = Environment.new(env)
        if stmt.names.length == 1
          scope.define(stmt.names[0].text, single)
        else
          scope.define(stmt.names[0].text, first)
          scope.define(stmt.names[1].text, second)
        end
        begin
          execute_list(stmt.body, scope)
        rescue BreakSignal
          break
        rescue ContinueSignal
          next
        end
      end
    end

    def execute_assert(stmt, env)
      return if Values.truthy?(evaluate(stmt.condition, env))
      message = "assertion failed"
      message += ": #{Text.str(evaluate(stmt.message, env))}" if stmt.message
      raise fault_at(stmt, "assert", message)
    end

    # The value a `catch` receives: the thrown value or the error map.
    def caught_value(error) = error.is_a?(ThrowSignal) ? error.value : error.to_map

    # A jump or error escaping the body or handler is held while `finally`
    # runs; a jump or error inside `finally` replaces it.
    def execute_try(stmt, env)
      pending = nil
      begin
        begin
          execute_block(stmt.body, env)
        rescue ThrowSignal, RuntimeError => e
          raise unless stmt.catch_body
          scope = Environment.new(env)
          scope.define(stmt.catch_name.text, caught_value(e))
          execute_list(stmt.catch_body, scope)
        end
      rescue Unwind => e
        raise unless stmt.finally_body
        pending = e
      end
      return unless stmt.finally_body
      execute_block(stmt.finally_body, env)
      raise pending if pending
    end

    # ---- assignment ----

    # A target with its parts evaluated: a variable, or a container and key.
    Place = Struct.new(:node, :container, :key)

    def execute_assign(stmt, env)
      places = stmt.targets.map { |target| evaluate_place(target, env) }
      values = stmt.values.map { |value| evaluate(value, env) }
      if stmt.op == "="
        places.zip(values) { |place, value| store(place, value, env) }
      else
        place = places[0]
        current = load(place, env)
        operator = stmt.op.delete_suffix("=")
        store(place, at(stmt) { Operators.binary(operator, current, values[0]) }, env)
      end
    end

    def evaluate_place(target, env)
      case target
      when Name then Place.new(target)
      when Index then Place.new(target, evaluate(target.object, env), evaluate(target.index, env))
      when Field then Place.new(target, evaluate(target.object, env), target.name)
      end
    end

    def load(place, env)
      node = place.node
      return at(node) { env.lookup(node.name, node.hops) } if node.is_a?(Name)
      at(node) { read_index(place.container, place.key) }
    end

    def store(place, value, env)
      node = place.node
      return at(node) { env.assign(node.name, node.hops, value) } if node.is_a?(Name)
      at(node) { write_index(place.container, place.key, value) }
    end

    # ---- indexing (section 7.6) ----

    def read_index(container, key)
      case container
      when Array, String
        container[sequence_index(container, key)]
      when Hash
        Values.check_key(key)
        raise Builtins.key_not_found(key) unless container.key?(key)
        container[key]
      else raise Fault.new("type", "cannot index #{Values.type_name(container)}")
      end
    end

    def write_index(container, key, value)
      case container
      when Array then container[sequence_index(container, key)] = value
      when String then raise Fault.new("type", "strings are immutable")
      when Hash
        Values.check_key(key)
        container[key] = value
      else raise Fault.new("type", "cannot index #{Values.type_name(container)}")
      end
    end

    # The non-negative position `index` denotes in an array or string.
    def sequence_index(sequence, index)
      type = Values.type_name(sequence)
      raise Fault.new("type", "#{type} index must be an int, got #{Values.type_name(index)}") unless index.is_a?(Integer)
      position = index.negative? ? index + sequence.length : index
      return position if position >= 0 && position < sequence.length
      raise Fault.new("index", "index #{index} out of range for #{type} of length #{sequence.length}")
    end

    # ---- expressions ----

    def evaluate(node, env)
      case node
      when Literal then node.value
      when StringLit then evaluate_string(node, env)
      when Name then at(node) { env.lookup(node.name, node.hops) }
      when ArrayLit then node.elements.map { |element| evaluate(element, env) }
      when MapLit then evaluate_map(node, env)
      when Function then UserFunction.new(node, env)
      when Unary then evaluate_unary(node, env)
      when Binary
        left = evaluate(node.left, env)
        right = evaluate(node.right, env)
        at(node) { Operators.binary(node.op, left, right) }
      when Logical then evaluate_logical(node, env)
      when Call then evaluate_call(node, env)
      when Index
        container = evaluate(node.object, env)
        key = evaluate(node.index, env)
        at(node) { read_index(container, key) }
      when Field
        container = evaluate(node.object, env)
        at(node) { read_index(container, node.name) }
      when Slice then evaluate_slice(node, env)
      else raise ArgumentError, "unknown expression #{node.class}"
      end
    end

    def evaluate_string(node, env)
      node.parts.map { |part| part.is_a?(String) ? part : Text.str(evaluate(part, env)) }.join
    end

    # Each key is checked as soon as it is evaluated, at the key expression.
    def evaluate_map(node, env)
      map = {}
      node.entries.each do |key_node, value_node|
        key = evaluate(key_node, env)
        at(start_of(key_node)) { Values.check_key(key) }
        map[key] = evaluate(value_node, env)
      end
      map
    end

    # The node at which an expression begins (the leftmost operand).
    def start_of(node)
      case node
      when Binary, Logical then start_of(node.left)
      when Call then start_of(node.callee)
      when Index, Slice, Field then start_of(node.object)
      else node
      end
    end

    def evaluate_unary(node, env)
      operand = evaluate(node.operand, env)
      return !Values.truthy?(operand) if node.op == "not"
      at(node) { Operators.negate(operand) }
    end

    def evaluate_logical(node, env)
      left = evaluate(node.left, env)
      if node.op == "and"
        Values.truthy?(left) ? evaluate(node.right, env) : left
      else
        Values.truthy?(left) ? left : evaluate(node.right, env)
      end
    end

    def evaluate_call(node, env)
      function = evaluate(node.callee, env)
      args = node.args.map { |arg| evaluate(arg, env) }
      call_function(function, args, node)
    end

    def evaluate_slice(node, env)
      sequence = evaluate(node.object, env)
      from = node.from && evaluate(node.from, env)
      to = node.to && evaluate(node.to, env)
      at(node) do
        unless sequence.is_a?(Array) || sequence.is_a?(String)
          raise Fault.new("type", "cannot slice #{Values.type_name(sequence)}")
        end
        [from, to].each do |bound|
          next if bound.nil? || bound.is_a?(Integer)
          raise Fault.new("type", "slice bound must be an int, got #{Values.type_name(bound)}")
        end
        Builtins.slice(sequence, from, to)
      end
    end

    # Parameters are bound in a new scope; defaults are evaluated there, so
    # they see the earlier parameters.
    def call_user_function(function, args)
      @call_depth += 1
      begin
        scope = Environment.new(function.env)
        function.node.params.each_with_index do |param, i|
          value = i < args.length ? args[i] : evaluate(param.default, scope)
          scope.define(param.name.text, value)
        end
        execute_list(function.node.body, scope)
        nil
      rescue ReturnSignal => e
        e.value
      ensure
        @call_depth -= 1
      end
    end
  end
end
