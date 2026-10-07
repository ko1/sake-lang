# The static pass (SPEC.md, "Static checks"): runs over the whole program before
# it starts and stops at the first error. It also records, in each Name node,
# how many scopes out its variable lives, which the interpreter relies on.
#
# The scopes it opens must match the environments the interpreter creates, one
# for one: the built-ins, the program, each block (if/elif/else branch, match
# arm, while body, try body, finally body), each function call (parameters and
# body together), each for iteration (loop variable and body together) and
# each catch (variable and handler).

# What the resolver knows about a declared name.
# kind: "variable" (let, parameter, loop or catch variable), "constant", "function"
# (fn declaration) or "built-in". fn is the FnExpr of a "function", else nil.
Decl = Struct.new(:kind, :fn)

class Resolver
  attr_reader :scopes
  attr_accessor :loop_depth, :function_depth

  def initialize
    builtins = {}
    Builtins.names.each { |name| builtins[name] = Decl.new("built-in", nil) }
    @scopes = [builtins]
    @loop_depth = 0
    @function_depth = 0
  end

  def resolve_program(program)
    with_scope { resolve_statements(program.body) }
  end

  private

  # ---- scopes ----

  def with_scope
    @scopes.push({})
    yield
    @scopes.pop
    nil
  end

  def declare(name, decl, pos)
    scope = @scopes.last
    Errors.static("'#{name}' is already declared in this scope", pos) if scope.key?(name)

    scope[name] = decl
  end

  def declare_variable(name, pos) = declare(name, Decl.new("variable", nil), pos)

  # How many scopes out `name` is declared, or nil if it is not declared at all.
  def depth_of(name)
    i = @scopes.length - 1
    while i >= 0
      return @scopes.length - 1 - i if @scopes[i].key?(name)

      i -= 1
    end
    nil
  end

  def decl_at(depth, name) = @scopes[@scopes.length - 1 - depth][name]

  def in_loop
    @loop_depth += 1
    yield
    @loop_depth -= 1
  end

  # ---- statements ----

  # Function declarations are visible in their whole statement list, so they are
  # declared before any statement of the list is looked at. A statement after
  # break, continue, return or throw in the same list could never run.
  def resolve_statements(stmts)
    stmts.each do |stmt|
      declare(stmt.fn.name, Decl.new("function", stmt.fn), stmt.pos) if stmt.is_a?(FnDecl)
    end
    stmts.each_index do |i|
      stmt = stmts[i]
      resolve_statement(stmt)
      jump = jump_keyword(stmt)
      Errors.static("code after '#{jump}' is unreachable", stmt.pos) if !jump.nil? && i < stmts.length - 1
    end
  end

  def jump_keyword(stmt)
    case stmt
    when Break then "break"
    when Continue then "continue"
    when Return then "return"
    when Throw then "throw"
    end
  end

  def resolve_block(stmts)
    with_scope { resolve_statements(stmts) }
  end

  def resolve_statement(stmt)
    case stmt
    when Let
      resolve_expression(stmt.value) unless stmt.value.nil?
      declare_variable(stmt.name, stmt.pos)
    when LetList
      resolve_expression(stmt.value)
      stmt.names.each { |name| declare_variable(name.name, name.pos) }
    when Const
      resolve_expression(stmt.value)
      declare(stmt.name, Decl.new("constant", nil), stmt.pos)
    when FnDecl
      resolve_function(stmt.fn)
    when Assign
      resolve_target(stmt.target)
      resolve_expression(stmt.value)
    when MultiAssign
      stmt.targets.each { |target| resolve_target(target) }
      stmt.values.each { |value| resolve_expression(value) }
    when ExprStmt
      resolve_expression(stmt.expr)
    when If
      stmt.branches.each do |branch|
        resolve_expression(branch.cond)
        resolve_block(branch.body)
      end
      resolve_block(stmt.else_body) unless stmt.else_body.nil?
    when Match
      resolve_match(stmt)
    when While
      resolve_expression(stmt.cond)
      in_loop { resolve_block(stmt.body) }
    when For
      resolve_expression(stmt.iterable)
      with_scope do
        stmt.vars.each { |var| declare_variable(var.name, var.pos) }
        in_loop { resolve_statements(stmt.body) }
      end
    when Break
      Errors.static("'break' outside a loop", stmt.pos) if @loop_depth == 0
    when Continue
      Errors.static("'continue' outside a loop", stmt.pos) if @loop_depth == 0
    when Return
      Errors.static("'return' outside a function", stmt.pos) if @function_depth == 0
      resolve_expression(stmt.value) unless stmt.value.nil?
    when Throw
      resolve_expression(stmt.value)
    when Assert
      resolve_expression(stmt.cond)
      resolve_expression(stmt.message) unless stmt.message.nil?
    when Try
      resolve_block(stmt.body)
      unless stmt.var.nil?
        with_scope do
          declare_variable(stmt.var.name, stmt.var.pos)
          resolve_statements(stmt.handler)
        end
      end
      resolve_block(stmt.finally_body) unless stmt.finally_body.nil?
    else
      raise ArgumentError, "unknown statement #{stmt.class}"
    end
  end

  def resolve_match(stmt)
    resolve_expression(stmt.subject)
    stmt.arms.each do |arm|
      arm.values.each { |value| resolve_expression(value) }
      resolve_block(arm.body)
    end
    resolve_block(stmt.else_body) unless stmt.else_body.nil?
  end

  # Only variables can be assigned; constants, functions and built-ins cannot.
  def resolve_target(target)
    case target
    when Name
      resolve_name(target)
      kind = decl_at(target.depth, target.name).kind
      Errors.static("cannot assign to #{kind} '#{target.name}'", target.pos) unless kind == "variable"
    when Index
      resolve_expression(target.target)
      resolve_expression(target.index)
    end
  end

  # A function body sees no enclosing loop: `break` inside it needs its own loop.
  # A parameter's default sees the parameters before it.
  def resolve_function(fn)
    saved_loop_depth = @loop_depth
    @loop_depth = 0
    @function_depth += 1
    with_scope do
      fn.params.each do |param|
        resolve_expression(param.default) unless param.default.nil?
        declare_variable(param.name, param.pos)
      end
      resolve_statements(fn.body)
    end
    @function_depth -= 1
    @loop_depth = saved_loop_depth
  end

  # ---- expressions ----

  def resolve_name(node)
    depth = depth_of(node.name)
    Errors.static(undefined_message(node.name), node.pos) if depth.nil?

    node.depth = depth
  end

  # "undefined name 'pirnt'; did you mean 'print'?". A visible name is suggested
  # when its edit distance is at most (length of the undefined name - 1) / 2,
  # and at most 2. The closest wins; among equally close names, the one in the
  # innermost scope, then the first in alphabetical order.
  def undefined_message(name)
    best = nil
    best_distance = [(name.length - 1) / 2, 2].min + 1
    i = @scopes.length - 1
    while i >= 0
      @scopes[i].keys.sort.each do |candidate|
        distance = Format.edit_distance(name, candidate)
        if distance < best_distance
          best = candidate
          best_distance = distance
        end
      end
      i -= 1
    end
    message = "undefined name '#{name}'"
    best.nil? ? message : "#{message}; did you mean '#{best}'?"
  end

  def resolve_expression(node)
    case node
    when IntLit, StrLit, BoolLit, NilLit
      nil
    when InterpStr
      node.parts.each { |part| resolve_expression(part) unless part.is_a?(String) }
    when Name
      resolve_name(node)
    when ArrayLit
      node.elements.each { |element| resolve_expression(element) }
    when MapLit
      node.keys.each_index do |i|
        resolve_expression(node.keys[i])
        resolve_expression(node.values[i])
      end
    when FnExpr
      resolve_function(node)
    when Unary
      resolve_expression(node.operand)
    when Binary, Logical
      resolve_expression(node.left)
      resolve_expression(node.right)
    when Call
      resolve_call(node)
    when Index
      resolve_expression(node.target)
      resolve_expression(node.index)
    when Slice
      resolve_expression(node.target)
      resolve_expression(node.start) unless node.start.nil?
      resolve_expression(node.stop) unless node.stop.nil?
    else
      raise ArgumentError, "unknown expression #{node.class}"
    end
  end

  # A call whose callee names a fn declaration or a built-in directly has its
  # argument count checked here; such names can never be reassigned.
  def resolve_call(node)
    resolve_expression(node.callee)
    node.args.each { |arg| resolve_expression(arg) }
    callee = node.callee
    return unless callee.is_a?(Name)

    decl = decl_at(callee.depth, callee.name)
    case decl.kind
    when "function"
      min, max = Arity.of_function(decl.fn)
    when "built-in"
      min, max = Builtins.arity(callee.name)
    else
      return
    end
    return if Arity.accepts?(min, max, node.args.length)

    Errors.static(Arity.message(callee.name, min, max, node.args.length), node.pos)
  end
end
