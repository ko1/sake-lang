require_relative "ast"
require_relative "errors"

module Mini
  # Recursive-descent parser for the grammar of section 3.
  class Parser
    include AST

    ASSIGN_OPS = %w[= += -= *= /= %=].freeze
    COMPARISON_OPS = %w[== != < <= > >=].freeze

    # Parses a whole program: a list of statements.
    def self.parse_program(tokens)
      parser = new(tokens)
      body = parser.parse_statements
      parser.expect_end_of_input
      body
    end

    def initialize(tokens)
      @tokens = tokens
      @pos = 0
    end

    def expect_end_of_input
      fail_expected("end of input") unless current.type == :eof
    end

    # Statements up to the end of input or a block-ending keyword.
    def parse_statements
      statements = []
      loop do
        advance while current.separator?
        break if current.type == :eof || current.block_end?
        statements << parse_statement
        next if current.separator? || current.type == :eof || current.block_end?
        fail_expected("end of statement")
      end
      statements
    end

    # The expression of an interpolation, whose tokens end with its '}'.
    def parse_interpolation
      expr = parse_expression
      expect_op("}")
      expr
    end

    private

    # ---- token helpers ----

    # Past the end (only possible in an interpolation) the last token repeats.
    def current = @tokens[@pos] || @tokens.last
    def peek_next = @tokens[@pos + 1] || @tokens.last

    def advance
      token = current
      @pos += 1
      token
    end

    def at_op?(symbol) = current.op?(symbol)
    def at_keyword?(word) = current.keyword?(word)

    def error(message, token = current)
      raise SyntaxError.new(message, token.line, token.col)
    end

    def fail_expected(what) = error("expected #{what}, got #{current.describe}")

    def expect_op(symbol)
      fail_expected("'#{symbol}'") unless at_op?(symbol)
      advance
    end

    def expect_keyword(word)
      fail_expected("'#{word}'") unless at_keyword?(word)
      advance
    end

    def expect_name
      fail_expected("name") unless current.type == :name
      advance
    end

    def pos_of(token) = { line: token.line, col: token.col }

    # ---- statements ----

    def parse_statement
      token = current
      if token.type == :keyword
        case token.text
        when "let" then return parse_let
        when "const" then return parse_const
        when "fn" then return parse_fn_decl if peek_next.type == :name
        when "if" then return parse_if
        when "match" then return parse_match
        when "while" then return parse_while
        when "for" then return parse_for
        when "break" then advance; return Break.new(**pos_of(token))
        when "continue" then advance; return Continue.new(**pos_of(token))
        when "return" then return parse_return
        when "throw" then advance; return Throw.new(value: parse_expression, **pos_of(token))
        when "assert" then return parse_assert
        when "try" then return parse_try
        end
      end
      parse_expression_statement
    end

    def parse_let
      let = advance
      if at_op?("[")
        bracket = advance
        names = [expect_name]
        names << expect_name while at_op?(",") && advance
        expect_op("]")
        expect_op("=")
        return LetArray.new(names: names, value: parse_expression, **pos_of(bracket))
      end
      name = expect_name
      value = nil
      value = parse_expression if at_op?("=") && advance
      Let.new(name: name, value: value, **pos_of(let))
    end

    def parse_const
      const = advance
      name = expect_name
      expect_op("=")
      Const.new(name: name, value: parse_expression, **pos_of(const))
    end

    def parse_fn_decl
      fn = advance
      name = expect_name
      function = parse_function_rest(name.text, fn)
      FnDecl.new(name: name, function: function, **pos_of(fn))
    end

    # Parameters, body and `end` of a function; the `fn` (and name) are read.
    def parse_function_rest(name, fn_token)
      expect_op("(")
      params = []
      seen_default = false
      until at_op?(")")
        param_name = expect_name
        default = nil
        if at_op?("=")
          advance
          default = parse_expression
          seen_default = true
        elsif seen_default
          error("parameter '#{param_name.text}' needs a default value", param_name)
        end
        params << Param.new(name: param_name, default: default, **pos_of(param_name))
        break unless at_op?(",")
        advance
      end
      expect_op(")")
      body = parse_statements
      expect_keyword("end")
      Function.new(name: name, params: params, body: body, **pos_of(fn_token))
    end

    def parse_if
      if_token = advance
      branches = []
      loop do
        condition = parse_expression
        expect_keyword("then")
        branches << [condition, parse_statements]
        break unless at_keyword?("elif")
        advance
      end
      else_body = nil
      else_body = parse_statements if at_keyword?("else") && advance
      expect_keyword("end")
      If.new(branches: branches, else_body: else_body, **pos_of(if_token))
    end

    def parse_match
      match = advance
      subject = parse_expression
      advance while current.separator?
      fail_expected("'when'") unless at_keyword?("when")
      arms = []
      while at_keyword?("when")
        advance
        values = [parse_expression]
        values << parse_expression while at_op?(",") && advance
        expect_keyword("then")
        arms << [values, parse_statements]
      end
      else_body = nil
      else_body = parse_statements if at_keyword?("else") && advance
      expect_keyword("end")
      Match.new(subject: subject, arms: arms, else_body: else_body, **pos_of(match))
    end

    def parse_while
      while_token = advance
      condition = parse_expression
      expect_keyword("do")
      body = parse_statements
      expect_keyword("end")
      While.new(condition: condition, body: body, **pos_of(while_token))
    end

    def parse_for
      for_token = advance
      names = [expect_name]
      names << expect_name if at_op?(",") && advance
      expect_keyword("in")
      iterable = parse_expression
      expect_keyword("do")
      body = parse_statements
      expect_keyword("end")
      For.new(names: names, iterable: iterable, body: body, **pos_of(for_token))
    end

    def parse_return
      return_token = advance
      value = nil
      unless current.separator? || current.type == :eof || current.block_end?
        value = parse_expression
      end
      Return.new(value: value, **pos_of(return_token))
    end

    def parse_assert
      assert = advance
      condition = parse_expression
      message = nil
      message = parse_expression if at_op?(",") && advance
      Assert.new(condition: condition, message: message, **pos_of(assert))
    end

    def parse_try
      try = advance
      body = parse_statements
      catch_name = catch_body = finally_body = nil
      if at_keyword?("catch")
        advance
        catch_name = expect_name
        catch_body = parse_statements
      end
      finally_body = parse_statements if at_keyword?("finally") && advance
      fail_expected("'catch' or 'finally'") if catch_body.nil? && finally_body.nil?
      expect_keyword("end")
      Try.new(body: body, catch_name: catch_name, catch_body: catch_body,
              finally_body: finally_body, **pos_of(try))
    end

    # An expression, or an assignment whose targets are parsed as expressions.
    def parse_expression_statement
      first = parse_expression
      targets = [first]
      if at_op?(",")
        targets << parse_expression while at_op?(",") && advance
        fail_expected("'='") unless at_op?("=")
      end
      unless current.type == :op && ASSIGN_OPS.include?(current.text)
        return ExprStmt.new(expr: first, line: first.line, col: first.col)
      end

      op = advance
      targets.each { |target| error("invalid assignment target", op) unless assignable?(target) }
      values = [parse_expression]
      values << parse_expression while op.text == "=" && at_op?(",") && advance
      if targets.length != values.length
        error("#{count(targets.length, "target")} but #{count(values.length, "value")}", op)
      end
      Assign.new(op: op.text, targets: targets, values: values, **pos_of(op))
    end

    def assignable?(node) = node.is_a?(Name) || node.is_a?(Index) || node.is_a?(Field)

    def count(n, noun) = n == 1 ? "1 #{noun}" : "#{n} #{noun}s"

    # ---- expressions, loosest binding first ----

    def parse_expression = parse_or

    def parse_or
      left = parse_and
      while at_keyword?("or")
        op = advance
        left = Logical.new(op: "or", left: left, right: parse_and, **pos_of(op))
      end
      left
    end

    def parse_and
      left = parse_not
      while at_keyword?("and")
        op = advance
        left = Logical.new(op: "and", left: left, right: parse_not, **pos_of(op))
      end
      left
    end

    def parse_not
      return parse_comparison unless at_keyword?("not")
      op = advance
      Unary.new(op: "not", operand: parse_not, **pos_of(op))
    end

    def comparison_op?(token)
      (token.type == :op && COMPARISON_OPS.include?(token.text)) || token.keyword?("in")
    end

    def parse_comparison
      left = parse_additive
      return left unless comparison_op?(current)
      op = advance
      node = Binary.new(op: op.text, left: left, right: parse_additive, **pos_of(op))
      error("comparison operators cannot be chained") if comparison_op?(current)
      node
    end

    def parse_additive
      left = parse_multiplicative
      while at_op?("+") || at_op?("-")
        op = advance
        left = Binary.new(op: op.text, left: left, right: parse_multiplicative, **pos_of(op))
      end
      left
    end

    def parse_multiplicative
      left = parse_negation
      while at_op?("*") || at_op?("/") || at_op?("%")
        op = advance
        left = Binary.new(op: op.text, left: left, right: parse_negation, **pos_of(op))
      end
      left
    end

    def parse_negation
      return parse_power unless at_op?("-")
      op = advance
      Unary.new(op: "-", operand: parse_negation, **pos_of(op))
    end

    # `**` is right-associative and its exponent may be a negation.
    def parse_power
      base = parse_postfix
      return base unless at_op?("**")
      op = advance
      Binary.new(op: "**", left: base, right: parse_negation, **pos_of(op))
    end

    def parse_postfix
      node = parse_primary
      loop do
        if at_op?("(")
          paren = advance
          args = parse_list(")") { parse_expression }
          node = Call.new(callee: node, args: args, **pos_of(paren))
        elsif at_op?("[")
          node = parse_index_or_slice(node)
        elsif at_op?(".")
          dot = advance
          name = expect_name
          node = Field.new(object: node, name: name.text, **pos_of(dot))
        else
          return node
        end
      end
    end

    def parse_index_or_slice(object)
      bracket = advance
      from = at_op?(":") ? nil : parse_expression
      if at_op?(":")
        advance
        to = at_op?("]") ? nil : parse_expression
        expect_op("]")
        return Slice.new(object: object, from: from, to: to, **pos_of(bracket))
      end
      expect_op("]")
      Index.new(object: object, index: from, **pos_of(bracket))
    end

    # Comma-separated items up to `closer`, trailing comma allowed; the opener
    # has been read. Reads the closer.
    def parse_list(closer)
      items = []
      until at_op?(closer)
        items << yield
        break unless at_op?(",")
        advance
      end
      expect_op(closer)
      items
    end

    def parse_primary
      token = current
      case token.type
      when :int
        advance
        return Literal.new(value: token.value, **pos_of(token))
      when :string
        advance
        return parse_string(token)
      when :name
        advance
        return Name.new(name: token.text, **pos_of(token))
      when :keyword
        case token.text
        when "true", "false", "nil"
          advance
          value = { "true" => true, "false" => false, "nil" => nil }[token.text]
          return Literal.new(value: value, **pos_of(token))
        when "fn"
          advance
          return parse_function_rest(nil, token)
        end
      when :op
        case token.text
        when "("
          advance
          inner = parse_expression
          expect_op(")")
          return inner
        when "["
          advance
          return ArrayLit.new(elements: parse_list("]") { parse_expression }, **pos_of(token))
        when "{"
          advance
          entries = parse_list("}") do
            key = parse_expression
            expect_op(":")
            [key, parse_expression]
          end
          return MapLit.new(entries: entries, **pos_of(token))
        end
      end
      fail_expected("expression")
    end

    # Each interpolation is parsed from its own tokens, which end with '}'.
    def parse_string(token)
      parts = token.parts.map do |part|
        part.is_a?(String) ? part : Parser.new(part).parse_interpolation
      end
      StringLit.new(parts: parts, **pos_of(token))
    end
  end
end
