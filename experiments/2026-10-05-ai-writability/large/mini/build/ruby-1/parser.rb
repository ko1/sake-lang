# frozen_string_literal: true

require_relative "errors"
require_relative "token"
require_relative "ast"

module Mini
  # Recursive-descent parser from tokens to the syntax tree (SPEC section 3).
  class Parser
    include AST

    BLOCK_END_KEYWORDS = %w[end elif else catch finally when].freeze
    ASSIGN_OPERATORS = %w[= += -= *= /= %=].freeze
    COMPARISON_OPERATORS = %w[== != < <= > >=].freeze

    STATEMENT_KEYWORDS = {
      "let" => :parse_let, "const" => :parse_const, "if" => :parse_if,
      "match" => :parse_match, "while" => :parse_while, "for" => :parse_for,
      "break" => :parse_break, "continue" => :parse_continue,
      "return" => :parse_return, "throw" => :parse_throw,
      "assert" => :parse_assert, "try" => :parse_try
    }.freeze

    def initialize(tokens)
      @tokens = tokens
      @index = 0
    end

    def parse_program
      body = parse_block
      fail_expected("end of input") unless peek.type == :eof
      Program.new(body)
    end

    # The expression of an interpolation; its token list ends with :interp_end.
    def parse_interpolation
      expression = parse_expression
      fail_expected("'}'") unless peek.type == :interp_end
      expression
    end

    private

    # --- token access ---

    def peek(offset = 0) = @tokens[@index + offset] || @tokens.last

    def advance
      token = peek
      @index += 1
      token
    end

    def error(message, token = peek) = raise(ParseError.new(message, token.position))

    def fail_expected(what) = error("expected #{what}, got #{peek.describe}")

    def expect_op(text)
      fail_expected("'#{text}'") unless peek.op?(text)
      advance
    end

    def expect_keyword(text)
      fail_expected("'#{text}'") unless peek.keyword?(text)
      advance
    end

    def expect_name
      fail_expected("name") unless peek.type == :name
      token = advance
      DeclName.new(token.text, token.position)
    end

    def separator?(token) = token.type == :newline || token.op?(";")

    def block_end?(token) = token.type == :eof || token.keyword?(*BLOCK_END_KEYWORDS)

    # --- statements ---

    # Statements up to the next block-ending keyword or the end of input.
    def parse_block
      body = []
      loop do
        advance while separator?(peek)
        break if block_end?(peek)

        body << parse_statement
        fail_expected("end of statement") unless separator?(peek) || block_end?(peek)
      end
      body
    end

    def parse_statement
      token = peek
      if token.type == :keyword
        return parse_fn_declaration if token.text == "fn" && peek(1).type == :name

        method = STATEMENT_KEYWORDS[token.text]
        return send(method) if method
      end
      parse_expression_statement
    end

    def parse_let
      advance
      if peek.op?("[")
        bracket = advance
        names = [expect_name]
        while peek.op?(",")
          advance
          names << expect_name
        end
        expect_op("]")
        expect_op("=")
        return LetArray.new(bracket.position, names, parse_expression)
      end
      name = expect_name
      value = nil
      if peek.op?("=")
        advance
        value = parse_expression
      end
      Let.new(name, value)
    end

    def parse_const
      advance
      name = expect_name
      expect_op("=")
      Const.new(name, parse_expression)
    end

    def parse_fn_declaration
      advance
      name = expect_name
      FnDecl.new(name, parse_function_rest(name.text))
    end

    # From the `(` of the parameters to the `end`.
    def parse_function_rest(name)
      expect_op("(")
      params = parse_params
      expect_op(")")
      body = parse_block
      expect_keyword("end")
      FunctionLit.new(name, params, body)
    end

    def parse_params
      params = []
      seen_default = false
      until peek.op?(")")
        name = expect_name
        default = nil
        if peek.op?("=")
          advance
          default = parse_expression
          seen_default = true
        elsif seen_default
          raise ParseError.new("parameter '#{name.text}' needs a default value", name.position)
        end
        params << Param.new(name, default)
        break unless peek.op?(",")

        advance
      end
      params
    end

    def parse_if
      advance
      branches = [parse_branch]
      while peek.keyword?("elif")
        advance
        branches << parse_branch
      end
      else_body = parse_else
      expect_keyword("end")
      If.new(branches, else_body)
    end

    def parse_branch
      condition = parse_expression
      expect_keyword("then")
      Branch.new(condition, parse_block)
    end

    def parse_else
      return nil unless peek.keyword?("else")

      advance
      parse_block
    end

    def parse_match
      keyword = advance
      subject = parse_expression
      advance while separator?(peek)
      fail_expected("'when'") unless peek.keyword?("when")
      arms = []
      while peek.keyword?("when")
        advance
        values = [parse_expression]
        while peek.op?(",")
          advance
          values << parse_expression
        end
        expect_keyword("then")
        arms << Arm.new(values, parse_block)
      end
      else_body = parse_else
      expect_keyword("end")
      Match.new(keyword.position, subject, arms, else_body)
    end

    def parse_while
      advance
      condition = parse_expression
      expect_keyword("do")
      body = parse_block
      expect_keyword("end")
      While.new(condition, body)
    end

    def parse_for
      keyword = advance
      names = [expect_name]
      if peek.op?(",")
        advance
        names << expect_name
      end
      expect_keyword("in")
      iterable = parse_expression
      expect_keyword("do")
      body = parse_block
      expect_keyword("end")
      For.new(keyword.position, names, iterable, body)
    end

    def parse_break = Break.new(advance.position)

    def parse_continue = Continue.new(advance.position)

    def parse_return
      keyword = advance
      value = separator?(peek) || block_end?(peek) ? nil : parse_expression
      Return.new(keyword.position, value)
    end

    def parse_throw
      keyword = advance
      Throw.new(keyword.position, parse_expression)
    end

    def parse_assert
      keyword = advance
      condition = parse_expression
      message = nil
      if peek.op?(",")
        advance
        message = parse_expression
      end
      Assert.new(keyword.position, condition, message)
    end

    def parse_try
      advance
      body = parse_block
      catch_name = catch_body = finally_body = nil
      if peek.keyword?("catch")
        advance
        catch_name = expect_name
        catch_body = parse_block
      end
      if peek.keyword?("finally")
        advance
        finally_body = parse_block
      end
      fail_expected("'catch' or 'finally'") if catch_body.nil? && finally_body.nil?
      expect_keyword("end")
      Try.new(body, catch_name, catch_body, finally_body)
    end

    # An expression, an assignment or a multiple assignment.
    def parse_expression_statement
      first = parse_expression
      operator = peek
      if operator.type == :op && ASSIGN_OPERATORS.include?(operator.text)
        advance
        error("invalid assignment target", operator) unless assignable?(first)
        return Assign.new(first, operator.text, operator.position, parse_expression)
      end
      return ExprStmt.new(first) unless operator.op?(",")

      targets = [first]
      while peek.op?(",")
        advance
        targets << parse_expression
      end
      equals = expect_op("=")
      error("invalid assignment target", equals) unless targets.all? { |t| assignable?(t) }
      values = [parse_expression]
      while peek.op?(",")
        advance
        values << parse_expression
      end
      if targets.size != values.size
        error("#{Mini.plural(targets.size, "target")} but #{Mini.plural(values.size, "value")}", equals)
      end
      MultiAssign.new(targets, equals.position, values)
    end

    def assignable?(node) = node.is_a?(Name) || node.is_a?(Index) || node.is_a?(Field)

    # --- expressions, loosest binding first (SPEC section 3.2) ---

    def parse_expression = parse_or

    def parse_or
      left = parse_and
      while peek.keyword?("or")
        advance
        left = Logical.new("or", left, parse_and)
      end
      left
    end

    def parse_and
      left = parse_not
      while peek.keyword?("and")
        advance
        left = Logical.new("and", left, parse_not)
      end
      left
    end

    def parse_not
      return parse_comparison unless peek.keyword?("not")

      advance
      Not.new(parse_not)
    end

    def comparison?(token) = token.op?(*COMPARISON_OPERATORS) || token.keyword?("in")

    def parse_comparison
      left = parse_additive
      return left unless comparison?(peek)

      operator = advance
      node = Binary.new(operator.text, operator.position, left, parse_additive)
      error("comparison operators cannot be chained") if comparison?(peek)
      node
    end

    def parse_additive
      left = parse_multiplicative
      while peek.op?("+", "-")
        operator = advance
        left = Binary.new(operator.text, operator.position, left, parse_multiplicative)
      end
      left
    end

    def parse_multiplicative
      left = parse_unary
      while peek.op?("*", "/", "%")
        operator = advance
        left = Binary.new(operator.text, operator.position, left, parse_unary)
      end
      left
    end

    def parse_unary
      return parse_power unless peek.op?("-")

      operator = advance
      Negate.new(operator.position, parse_unary)
    end

    # `**` is right-associative and its exponent may be a negation.
    def parse_power
      base = parse_postfix
      return base unless peek.op?("**")

      operator = advance
      Binary.new("**", operator.position, base, parse_unary)
    end

    def parse_postfix
      node = parse_primary
      loop do
        token = peek
        if token.op?("(")
          advance
          node = Call.new(node, token.position, parse_comma_list(")") { parse_expression })
        elsif token.op?("[")
          advance
          node = parse_index_rest(node, token)
        elsif token.op?(".")
          advance
          node = Field.new(node, token.position, expect_name.text)
        else
          return node
        end
      end
    end

    # After the `[`: `i]`, `i:j]`, `i:]`, `:j]` or `:]`.
    def parse_index_rest(object, bracket)
      from = peek.op?(":") ? nil : parse_expression
      unless peek.op?(":")
        expect_op("]")
        return Index.new(object, bracket.position, from)
      end
      advance
      to = peek.op?("]") ? nil : parse_expression
      expect_op("]")
      Slice.new(object, bracket.position, from, to)
    end

    # Items up to `closer`, separated by commas, with an optional trailing comma.
    def parse_comma_list(closer)
      items = []
      until peek.op?(closer)
        items << yield
        break unless peek.op?(",")

        advance
      end
      expect_op(closer)
      items
    end

    def parse_primary
      token = peek
      case token.type
      when :int
        advance
        return Literal.new(token.value)
      when :string
        advance
        return string_literal(token)
      when :name
        advance
        return Name.new(token.text, token.position)
      when :keyword
        case token.text
        when "true", "false", "nil"
          advance
          return Literal.new({ "true" => true, "false" => false, "nil" => nil }[token.text])
        when "fn"
          advance
          return parse_function_rest(nil)
        end
      when :op
        case token.text
        when "("
          advance
          expression = parse_expression
          expect_op(")")
          return expression
        when "["
          advance
          return ArrayLit.new(parse_comma_list("]") { parse_expression })
        when "{"
          advance
          return MapLit.new(parse_comma_list("}") { parse_map_entry })
        end
      end
      fail_expected("expression")
    end

    def parse_map_entry
      position = peek.position
      key = parse_expression
      expect_op(":")
      MapEntry.new(key, parse_expression, position)
    end

    def string_literal(token)
      parts = token.value
      return Literal.new(parts.first) if parts.size == 1 && parts.first.is_a?(String)

      Interpolation.new(parts.map { |part| part.is_a?(String) ? part : Parser.new(part).parse_interpolation })
    end
  end
end
