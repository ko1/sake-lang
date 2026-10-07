# frozen_string_literal: true

require_relative "errors"
require_relative "ast"
require_relative "suggestions"
require_relative "builtins"

module Mini
  # The static checks (SPEC section 5): resolves every name to its
  # declaration and reports the first error, walking the program in source
  # order. Fills in Name#decl, Name#hops and Name#depth for the interpreter.
  class Checker
    include AST

    # kind is :variable, :constant, :function or :builtin. arity is
    # [min, max] (max nil when unbounded) for functions and built-ins.
    Decl = Struct.new(:name, :kind, :arity)

    class Scope
      attr_reader :parent, :depth, :decls

      def initialize(parent)
        @parent = parent
        @depth = parent ? parent.depth + 1 : 0
        @decls = {}
      end
    end

    ASSIGN_KIND_WORDS = { constant: "constant", function: "function", builtin: "built-in" }.freeze

    def initialize
      @scope = Scope.new(nil)
      Builtins::TABLE.each_value do |builtin|
        @scope.decls[builtin.name] = Decl.new(builtin.name, :builtin, [builtin.min, builtin.max])
      end
      @in_function = false
      @in_loop = false
    end

    def check(program)
      in_scope { check_body(program.body) }
    end

    private

    def error(message, position) = raise(StaticError.new(message, position))

    def in_scope
      @scope = Scope.new(@scope)
      yield
    ensure
      @scope = @scope.parent
    end

    def declare(name, kind, arity = nil)
      error("'#{name.text}' is already declared in this scope", name.position) if @scope.decls.key?(name.text)
      @scope.decls[name.text] = Decl.new(name.text, kind, arity)
    end

    def resolve(node)
      scope = @scope
      while scope
        if (decl = scope.decls[node.text])
          node.decl = decl
          node.hops = @scope.depth - scope.depth
          node.depth = scope.depth
          return decl
        end
        scope = scope.parent
      end
      message = "undefined name '#{node.text}'"
      suggestion = Suggestions.suggest(node.text, visible_names)
      message += "; did you mean '#{suggestion}'?" if suggestion
      error(message, node.position)
    end

    def visible_names
      names = []
      scope = @scope
      while scope
        names << scope.decls.keys
        scope = scope.parent
      end
      names
    end

    # A statement list in the current scope. Its function declarations are
    # visible throughout it, so they are declared first.
    def check_body(body)
      body.each { |stmt| declare(stmt.name, :function, function_arity(stmt.function)) if stmt.is_a?(FnDecl) }
      body.each_with_index do |stmt, i|
        check_statement(stmt)
        keyword = JUMP_KEYWORDS[stmt.class]
        error("code after '#{keyword}' is unreachable", stmt.position) if keyword && i < body.size - 1
      end
    end

    def check_block(body) = in_scope { check_body(body) }

    def function_arity(function) = [function.params.count { |p| p.default.nil? }, function.params.size]

    def check_statement(stmt)
      case stmt
      when Let
        check_expression(stmt.value) if stmt.value
        declare(stmt.name, :variable)
      when LetArray
        check_expression(stmt.value)
        stmt.names.each { |name| declare(name, :variable) }
      when Const
        check_expression(stmt.value)
        declare(stmt.name, :constant)
      when FnDecl
        check_function(stmt.function)
      when If
        stmt.branches.each do |branch|
          check_expression(branch.condition)
          check_block(branch.body)
        end
        check_block(stmt.else_body) if stmt.else_body
      when Match
        check_expression(stmt.subject)
        stmt.arms.each do |arm|
          arm.values.each { |value| check_expression(value) }
          check_block(arm.body)
        end
        check_block(stmt.else_body) if stmt.else_body
      when While
        check_expression(stmt.condition)
        in_loop { check_block(stmt.body) }
      when For
        check_expression(stmt.iterable)
        in_loop do
          in_scope do
            stmt.names.each { |name| declare(name, :variable) }
            check_body(stmt.body)
          end
        end
      when Break, Continue
        keyword = JUMP_KEYWORDS[stmt.class]
        error("'#{keyword}' outside a loop", stmt.position) unless @in_loop
      when Return
        error("'return' outside a function", stmt.position) unless @in_function
        check_expression(stmt.value) if stmt.value
      when Throw
        check_expression(stmt.value)
      when Assert
        check_expression(stmt.condition)
        check_expression(stmt.message) if stmt.message
      when Try
        check_block(stmt.body)
        if stmt.catch_body
          in_scope do
            declare(stmt.catch_name, :variable)
            check_body(stmt.catch_body)
          end
        end
        check_block(stmt.finally_body) if stmt.finally_body
      when Assign
        check_target(stmt.target)
        check_expression(stmt.value)
      when MultiAssign
        stmt.targets.each { |target| check_target(target) }
        stmt.values.each { |value| check_expression(value) }
      when ExprStmt
        check_expression(stmt.expression)
      else
        raise ArgumentError, "unknown statement #{stmt.class}"
      end
    end

    def in_loop
      saved = @in_loop
      @in_loop = true
      yield
    ensure
      @in_loop = saved
    end

    # Parameters and body share one scope; a function body starts outside
    # any loop.
    def check_function(function)
      saved = [@in_function, @in_loop]
      @in_function = true
      @in_loop = false
      in_scope do
        function.params.each do |param|
          check_expression(param.default) if param.default
          declare(param.name, :variable)
        end
        check_body(function.body)
      end
    ensure
      @in_function, @in_loop = saved
    end

    def check_target(target)
      case target
      when Name
        decl = resolve(target)
        word = ASSIGN_KIND_WORDS[decl.kind]
        error("cannot assign to #{word} '#{target.text}'", target.position) if word
      when Index
        check_expression(target.object)
        check_expression(target.index)
      when Field
        check_expression(target.object)
      end
    end

    def check_expression(node)
      case node
      when Literal
        nil
      when Interpolation
        node.parts.each { |part| check_expression(part) unless part.is_a?(String) }
      when Name
        resolve(node)
      when ArrayLit
        node.elements.each { |element| check_expression(element) }
      when MapLit
        node.entries.each do |entry|
          check_expression(entry.key)
          check_expression(entry.value)
        end
      when FunctionLit
        check_function(node)
      when Negate, Not
        check_expression(node.operand)
      when Binary, Logical
        check_expression(node.left)
        check_expression(node.right)
      when Call
        check_call(node)
      when Index
        check_expression(node.object)
        check_expression(node.index)
      when Slice
        check_expression(node.object)
        check_expression(node.from) if node.from
        check_expression(node.to) if node.to
      when Field
        check_expression(node.object)
      else
        raise ArgumentError, "unknown expression #{node.class}"
      end
    end

    # Argument counts are checked only when the callee is written as a name
    # of a function declaration or a built-in.
    def check_call(node)
      check_expression(node.callee)
      node.arguments.each { |argument| check_expression(argument) }
      callee = node.callee
      return unless callee.is_a?(Name) && %i[function builtin].include?(callee.decl.kind)

      min, max = callee.decl.arity
      given = node.arguments.size
      return if given >= min && (max.nil? || given <= max)

      error(Mini.arity_message(callee.text, min, max, given), node.position)
    end
  end
end
