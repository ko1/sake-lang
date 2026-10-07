require_relative "ast"
require_relative "errors"
require_relative "builtins"
require_relative "suggestions"
require_relative "values"

module Mini
  # The static checks of section 5. Walks the program in source order, stops
  # at the first error, and resolves every Name node: `hops` (how many scopes
  # up its declaration is) and `depth` (the depth of that scope, the built-in
  # scope being 0).
  class Checker
    include AST

    # What a name is declared as; min_args/max_args only for functions and
    # built-ins (max_args nil: no maximum).
    Declaration = Struct.new(:kind, :name, :min_args, :max_args) do
      def display_name = name
    end

    # A static scope: the declarations made so far, in order.
    class Scope
      attr_reader :parent, :declarations, :depth

      def initialize(parent)
        @parent = parent
        @declarations = {}
        @depth = parent ? parent.depth + 1 : 0
      end
    end

    ASSIGN_KIND_WORDS = { constant: "constant", function: "function", builtin: "built-in" }.freeze

    def self.check(program) = new.check_program(program)

    def initialize
      @in_function = false
      @in_loop = false
    end

    def check_program(statements)
      builtins = Scope.new(nil)
      Builtins::ALL.each_value do |builtin|
        builtins.declarations[builtin.name] =
          Declaration.new(:builtin, builtin.name, builtin.min_args, builtin.max_args)
      end
      check_list(statements, Scope.new(builtins))
    end

    private

    def error(message, node)
      raise StaticError.new(message, node.line, node.col)
    end

    def declare(scope, token, kind, function = nil)
      name = token.text
      error("'#{name}' is already declared in this scope", token) if scope.declarations.key?(name)
      min = function&.params&.count { |param| param.default.nil? }
      scope.declarations[name] = Declaration.new(kind, name, min, function&.params&.length)
    end

    # A statement list. Its function declarations are entered first so they
    # are visible throughout the list.
    def check_list(statements, scope)
      statements.each do |stmt|
        declare(scope, stmt.name, :function, stmt.function) if stmt.is_a?(FnDecl)
      end
      statements.each_with_index do |stmt, i|
        check_statement(stmt, scope)
        next unless JUMPS.include?(stmt.class) && i < statements.length - 1
        error("code after '#{AST.jump_keyword(stmt)}' is unreachable", stmt)
      end
    end

    def check_block(statements, parent)
      check_list(statements, Scope.new(parent))
    end

    def in_loop
      saved = @in_loop
      @in_loop = true
      yield
    ensure
      @in_loop = saved
    end

    def check_statement(stmt, scope)
      case stmt
      when Let
        check_expr(stmt.value, scope) if stmt.value
        declare(scope, stmt.name, :variable)
      when LetArray
        check_expr(stmt.value, scope)
        stmt.names.each { |name| declare(scope, name, :variable) }
      when Const
        check_expr(stmt.value, scope)
        declare(scope, stmt.name, :constant)
      when FnDecl
        check_function(stmt.function, scope)
      when If
        stmt.branches.each do |condition, body|
          check_expr(condition, scope)
          check_block(body, scope)
        end
        check_block(stmt.else_body, scope) if stmt.else_body
      when Match
        check_expr(stmt.subject, scope)
        stmt.arms.each do |values, body|
          values.each { |value| check_expr(value, scope) }
          check_block(body, scope)
        end
        check_block(stmt.else_body, scope) if stmt.else_body
      when While
        check_expr(stmt.condition, scope)
        in_loop { check_block(stmt.body, scope) }
      when For
        check_expr(stmt.iterable, scope)
        loop_scope = Scope.new(scope)
        stmt.names.each { |name| declare(loop_scope, name, :variable) }
        in_loop { check_list(stmt.body, loop_scope) }
      when Break, Continue
        error("'#{AST.jump_keyword(stmt)}' outside a loop", stmt) unless @in_loop
      when Return
        error("'return' outside a function", stmt) unless @in_function
        check_expr(stmt.value, scope) if stmt.value
      when Throw
        check_expr(stmt.value, scope)
      when Assert
        check_expr(stmt.condition, scope)
        check_expr(stmt.message, scope) if stmt.message
      when Try
        check_block(stmt.body, scope)
        if stmt.catch_body
          catch_scope = Scope.new(scope)
          declare(catch_scope, stmt.catch_name, :variable)
          check_list(stmt.catch_body, catch_scope)
        end
        check_block(stmt.finally_body, scope) if stmt.finally_body
      when Assign
        stmt.targets.each { |target| check_target(target, scope) }
        stmt.values.each { |value| check_expr(value, scope) }
      when ExprStmt
        check_expr(stmt.expr, scope)
      else
        raise ArgumentError, "unknown statement #{stmt.class}"
      end
    end

    def check_target(target, scope)
      return check_expr(target, scope) unless target.is_a?(Name)
      declaration = resolve(target, scope)
      word = ASSIGN_KIND_WORDS[declaration.kind]
      error("cannot assign to #{word} '#{target.name}'", target) if word
    end

    # Parameters and body share one scope; a function body starts outside any
    # loop.
    def check_function(function, scope)
      saved = [@in_function, @in_loop]
      @in_function = true
      @in_loop = false
      function_scope = Scope.new(scope)
      function.params.each do |param|
        check_expr(param.default, function_scope) if param.default
        declare(function_scope, param.name, :variable)
      end
      check_list(function.body, function_scope)
    ensure
      @in_function, @in_loop = saved
    end

    def check_expr(node, scope)
      case node
      when Literal
        nil
      when StringLit
        node.parts.each { |part| check_expr(part, scope) unless part.is_a?(String) }
      when ArrayLit
        node.elements.each { |element| check_expr(element, scope) }
      when MapLit
        node.entries.each do |key, value|
          check_expr(key, scope)
          check_expr(value, scope)
        end
      when Name
        resolve(node, scope)
      when Function
        check_function(node, scope)
      when Unary
        check_expr(node.operand, scope)
      when Binary, Logical
        check_expr(node.left, scope)
        check_expr(node.right, scope)
      when Call
        check_call(node, scope)
      when Index
        check_expr(node.object, scope)
        check_expr(node.index, scope)
      when Slice
        check_expr(node.object, scope)
        check_expr(node.from, scope) if node.from
        check_expr(node.to, scope) if node.to
      when Field
        check_expr(node.object, scope)
      else
        raise ArgumentError, "unknown expression #{node.class}"
      end
    end

    # Calls through a name that refers to a function declaration or a built-in
    # have their argument count checked here.
    def check_call(call, scope)
      declaration = nil
      if call.callee.is_a?(Name)
        declaration = resolve(call.callee, scope)
      else
        check_expr(call.callee, scope)
      end
      call.args.each { |arg| check_expr(arg, scope) }
      return unless declaration && %i[function builtin].include?(declaration.kind)
      given = call.args.length
      return if given >= declaration.min_args && (declaration.max_args.nil? || given <= declaration.max_args)
      error(Values.arity_message(declaration, given), call)
    end

    # Finds the declaration a name refers to and records where it is.
    def resolve(name_node, scope)
      hops = 0
      current = scope
      while current
        declaration = current.declarations[name_node.name]
        if declaration
          name_node.hops = hops
          name_node.depth = current.depth
          return declaration
        end
        hops += 1
        current = current.parent
      end
      undefined(name_node, scope)
    end

    def undefined(name_node, scope)
      visible = []
      current = scope
      while current
        visible << current.declarations.keys
        current = current.parent
      end
      message = "undefined name '#{name_node.name}'"
      suggestion = Suggestions.suggest(name_node.name, visible)
      message += "; did you mean '#{suggestion}'?" if suggestion
      error(message, name_node)
    end
  end
end
