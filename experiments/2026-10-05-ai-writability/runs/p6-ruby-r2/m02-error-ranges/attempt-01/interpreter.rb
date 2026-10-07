# Runs a resolved program (SPEC.md, "Evaluation").
#
# Statements return nil when control goes on to the next statement, or a Flow
# when a break, continue or return is on its way out. Errors and throws travel
# as Ruby exceptions (MiniRuntimeError and MiniThrow) up to the nearest `try`.

# kind is :break, :continue or :return; value is the returned value.
Flow = Struct.new(:kind, :value)

# A call deeper than this many user functions is a "stack" runtime error.
MAX_CALL_DEPTH = 150

class Interpreter
  attr_reader :globals
  attr_accessor :call_depth, :closure_count

  def initialize
    builtins = Env.new(nil)
    Builtins.names.each { |name| builtins.define(name, Builtin.new(name)) }
    @globals = Env.new(builtins)
    @call_depth = 0
    @closure_count = 0
  end

  def run(program)
    execute_statements(program.body, @globals)
    nil
  end

  # Calls a function value (a Closure or a Builtin) with evaluated arguments;
  # `pos` is where a problem with the call itself is reported.
  def call_function(callee, args, pos)
    case callee
    when Closure then call_closure(callee, args, pos)
    when Builtin
      case callee.name
      when "map", "filter" then call_higher_order(callee.name, args, pos)
      else Builtins.call(callee.name, args, pos)
      end
    else Errors.runtime("type", "cannot call #{Values.type_name(callee)}", pos)
    end
  end

  private

  # ---- statements ----

  # Function declarations are bound first, so they can be called from anywhere
  # in their statement list (and from each other).
  def execute_statements(stmts, env)
    stmts.each { |stmt| env.define(stmt.fn.name, make_closure(stmt.fn, env)) if stmt.is_a?(FnDecl) }
    stmts.each do |stmt|
      flow = execute(stmt, env)
      return flow unless flow.nil?
    end
    nil
  end

  def execute_block(stmts, env) = execute_statements(stmts, Env.new(env))

  def execute(stmt, env)
    case stmt
    when ExprStmt
      evaluate(stmt.expr, env)
      nil
    when Let
      env.define(stmt.name, stmt.value.nil? ? nil : evaluate(stmt.value, env))
    when LetList
      execute_let_list(stmt, env)
    when Const
      env.define(stmt.name, evaluate(stmt.value, env))
    when FnDecl
      nil
    when Assign
      execute_assign(stmt, env)
    when MultiAssign
      execute_multi_assign(stmt, env)
    when If
      execute_if(stmt, env)
    when Match
      execute_match(stmt, env)
    when While
      execute_while(stmt, env)
    when For
      execute_for(stmt, env)
    when Break
      Flow.new(:break, nil)
    when Continue
      Flow.new(:continue, nil)
    when Return
      Flow.new(:return, stmt.value.nil? ? nil : evaluate(stmt.value, env))
    when Throw
      raise MiniThrow.new(evaluate(stmt.value, env), stmt.pos)
    when Assert
      execute_assert(stmt, env)
    when Try
      execute_try(stmt, env)
    else
      raise ArgumentError, "unknown statement #{stmt.class}"
    end
  end

  def execute_let_list(stmt, env)
    value = evaluate(stmt.value, env)
    Errors.runtime("type", "cannot destructure #{Values.type_name(value)}", stmt.pos) unless value.is_a?(Array)
    if value.length != stmt.names.length
      Errors.runtime("value", "expected #{Format.count(stmt.names.length, "element")}, got #{value.length}", stmt.pos)
    end
    stmt.names.each_index { |i| env.define(stmt.names[i].name, value[i]) }
    nil
  end

  # The target's parts are evaluated first, then the right side; a compound
  # assignment then reads the current value and applies its operator.
  def execute_assign(stmt, env)
    target = stmt.target
    case target
    when Name
      value = evaluate(stmt.value, env)
      if stmt.op != "="
        current = env.lookup(target.depth, target.name, target.pos)
        value = Operators.binary(stmt.op[0], current, value, stmt.pos)
      end
      env.assign(target.depth, target.name, value, target.pos)
    when Index
      container = evaluate(target.target, env)
      key = evaluate(target.index, env)
      value = evaluate(stmt.value, env)
      if stmt.op != "="
        current = Operators.index_get(container, key, target.pos)
        value = Operators.binary(stmt.op[0], current, value, stmt.pos)
      end
      Operators.index_set(container, key, value, target.pos)
    end
    nil
  end

  # All targets' parts, then all values, left to right; then the stores, left to
  # right. So `a, b = b, a` swaps.
  def execute_multi_assign(stmt, env)
    places = stmt.targets.map do |target|
      target.is_a?(Index) ? [evaluate(target.target, env), evaluate(target.index, env)] : nil
    end
    values = stmt.values.map { |value| evaluate(value, env) }
    stmt.targets.each_index do |i|
      target = stmt.targets[i]
      if target.is_a?(Index)
        Operators.index_set(places[i][0], places[i][1], values[i], target.pos)
      else
        env.assign(target.depth, target.name, values[i], target.pos)
      end
    end
    nil
  end

  def execute_assert(stmt, env)
    return nil if Values.truthy?(evaluate(stmt.cond, env))

    message = "assertion failed"
    message = "#{message}: #{Format.show(evaluate(stmt.message, env))}" unless stmt.message.nil?
    Errors.runtime("assert", message, stmt.pos)
  end

  def execute_if(stmt, env)
    stmt.branches.each do |branch|
      return execute_block(branch.body, env) if Values.truthy?(evaluate(branch.cond, env))
    end
    return nil if stmt.else_body.nil?

    execute_block(stmt.else_body, env)
  end

  # The first arm with a value == the subject runs; the values are evaluated in
  # order, and only until one matches.
  def execute_match(stmt, env)
    subject = evaluate(stmt.subject, env)
    stmt.arms.each do |arm|
      arm.values.each do |value|
        return execute_block(arm.body, env) if Values.equal(subject, evaluate(value, env), value.pos)
      end
    end
    return nil if stmt.else_body.nil?

    execute_block(stmt.else_body, env)
  end

  def execute_while(stmt, env)
    while Values.truthy?(evaluate(stmt.cond, env))
      flow = execute_block(stmt.body, env)
      next if flow.nil? || flow.kind == :continue
      return nil if flow.kind == :break

      return flow
    end
    nil
  end

  # Iterates over a copy, taken when the loop starts: with one variable, an
  # array's elements or a map's keys; with two, an array's index and element
  # or a map's key and value. Each iteration has its own scope and variables.
  def execute_for(stmt, env)
    iterable = evaluate(stmt.iterable, env)
    unless iterable.is_a?(Array) || iterable.is_a?(Hash)
      Errors.runtime("type", "cannot iterate over #{Values.type_name(iterable)}", stmt.iterable.pos)
    end
    loop_values(iterable, stmt.vars.length).each do |values|
      scope = Env.new(env)
      stmt.vars.each_index { |i| scope.define(stmt.vars[i].name, values[i]) }
      flow = execute_statements(stmt.body, scope)
      next if flow.nil? || flow.kind == :continue
      return nil if flow.kind == :break

      return flow
    end
    nil
  end

  # The finally body runs however the body and handler end: normally, by break,
  # continue or return, or by an error or throw. If it ends normally, the earlier
  # outcome goes on; if it breaks, continues, returns or raises, that replaces it.
  # One Array of loop-variable values per iteration.
  def loop_values(iterable, count)
    if iterable.is_a?(Hash)
      count == 1 ? iterable.keys.map { |key| [key] } : iterable.to_a
    else
      count == 1 ? iterable.map { |element| [element] } : (0...iterable.length).map { |i| [i, iterable[i]] }
    end
  end

  def execute_try(stmt, env)
    return execute_try_catch(stmt, env) if stmt.finally_body.nil?

    begin
      flow = execute_try_catch(stmt, env)
    rescue MiniThrow, MiniRuntimeError => e
      final = execute_block(stmt.finally_body, env)
      return final unless final.nil?

      raise e
    end
    final = execute_block(stmt.finally_body, env)
    final.nil? ? flow : final
  end

  # The body, and the handler if the body raised and there is a `catch`.
  def execute_try_catch(stmt, env)
    return execute_block(stmt.body, env) if stmt.var.nil?

    caught = nil
    begin
      return execute_block(stmt.body, env)
    rescue MiniThrow => e
      caught = e.value
    rescue MiniRuntimeError => e
      caught = Values.error_map(e)
    end
    scope = Env.new(env)
    scope.define(stmt.var.name, caught)
    execute_statements(stmt.handler, scope)
  end

  # ---- expressions ----

  def evaluate(node, env)
    case node
    when IntLit, StrLit, BoolLit
      node.value
    when NilLit
      nil
    when InterpStr
      node.parts.map { |part| part.is_a?(String) ? part : Format.show(evaluate(part, env)) }.join
    when Name
      env.lookup(node.depth, node.name, node.pos)
    when ArrayLit
      node.elements.map { |element| evaluate(element, env) }
    when MapLit
      evaluate_map(node, env)
    when FnExpr
      make_closure(node, env)
    when Unary
      evaluate_unary(node, env)
    when Binary
      left = evaluate(node.left, env)
      Operators.binary(node.op, left, evaluate(node.right, env), node.pos)
    when Logical
      evaluate_logical(node, env)
    when Call
      callee = evaluate(node.callee, env)
      args = node.args.map { |arg| evaluate(arg, env) }
      call_function(callee, args, node.pos)
    when Index
      target = evaluate(node.target, env)
      Operators.index_get(target, evaluate(node.index, env), node.pos)
    when Slice
      target = evaluate(node.target, env)
      start = node.start.nil? ? nil : evaluate(node.start, env)
      stop = node.stop.nil? ? nil : evaluate(node.stop, env)
      Operators.slice_expression(target, start, stop, node.pos)
    else
      raise ArgumentError, "unknown expression #{node.class}"
    end
  end

  # Entries are added in order; a repeated key keeps its first place and its last value.
  def evaluate_map(node, env)
    map = {}
    node.keys.each_index do |i|
      key = evaluate(node.keys[i], env)
      Values.check_key(key, node.keys[i].pos)
      map[key] = evaluate(node.values[i], env)
    end
    map
  end

  def evaluate_unary(node, env)
    value = evaluate(node.operand, env)
    node.op == "not" ? !Values.truthy?(value) : Operators.negate(value, node.pos)
  end

  # `and` and `or` give back the operand that decided the result, not a bool.
  def evaluate_logical(node, env)
    left = evaluate(node.left, env)
    if node.op == "and"
      Values.truthy?(left) ? evaluate(node.right, env) : left
    else
      Values.truthy?(left) ? left : evaluate(node.right, env)
    end
  end

  def make_closure(fn, env)
    @closure_count += 1
    Closure.new(fn, env, @closure_count)
  end

  # ---- calls ----

  # Arguments fill the parameters in order; a missing one takes its default,
  # evaluated in the new scope, where the parameters before it are already set.
  def call_closure(closure, args, pos)
    fn = closure.fn
    min, max = Arity.of_function(fn)
    unless Arity.accepts?(min, max, args.length)
      Errors.runtime("arity", Arity.message(Format.function_label(fn), min, max, args.length), pos)
    end
    Errors.runtime("stack", "call depth exceeded #{MAX_CALL_DEPTH}", pos) if @call_depth >= MAX_CALL_DEPTH

    @call_depth += 1
    begin
      scope = Env.new(closure.env)
      fn.params.each_index do |i|
        param = fn.params[i]
        scope.define(param.name, i < args.length ? args[i] : evaluate(param.default, scope))
      end
      flow = execute_statements(fn.body, scope)
    ensure
      @call_depth -= 1
    end
    flow.nil? ? nil : flow.value
  end

  # map(array, f) and filter(array, f), over a copy of the array.
  def call_higher_order(name, args, pos)
    Builtins.check_arity(name, args, pos)
    array = Builtins.array_arg(name, args, 1, pos)
    f = Builtins.function_arg(name, args, 2, pos)
    if name == "map"
      array.dup.map { |element| call_function(f, [element], pos) }
    else
      array.dup.select { |element| Values.truthy?(call_function(f, [element], pos)) }
    end
  end
end
