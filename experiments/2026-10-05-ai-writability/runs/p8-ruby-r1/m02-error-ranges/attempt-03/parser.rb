# Builds the AST from tokens by recursive descent (SPEC.md, "Syntax").
#
# Expression precedence, loosest first:
#   or < and < not < comparison (== != < <= > >= in, not chainable)
#      < + - < * / % < unary - < ** (right-associative)
#      < call f(...), index a[...] and field m.name
class Parser
  attr_reader :tokens
  attr_accessor :index

  def initialize(tokens)
    @tokens = tokens
    @index = 0
  end

  def parse_program
    body = parse_statements
    expect_end_of_input
    Program.new(body)
  end

  # The expression of one "{...}" in a string; its tokens end with a "}" :eof token.
  def parse_interpolation
    expr = parse_expression
    syntax_error("expected '}', got #{Tokens.describe(current)}") unless current.type == :eof
    expr
  end

  private

  # ---- token helpers ----

  def current = @tokens[@index]

  def lookahead = @tokens[[@index + 1, @tokens.length - 1].min]

  def advance
    tok = current
    @index += 1 unless tok.type == :eof
    tok
  end

  def check_op(text) = Tokens.op?(current, text)

  def check_kw(word) = Tokens.kw?(current, word)

  # The range from `first` (a token) to the last token consumed.
  def span(first)
    last = @tokens[@index - 1]
    Pos.new(first.pos.line, first.pos.col, last.pos.end_line, last.pos.end_col)
  end

  def syntax_error(message, pos = current.pos)
    Errors.syntax(message, pos)
  end

  def expect_op(text)
    syntax_error("expected '#{text}', got #{Tokens.describe(current)}") unless check_op(text)
    advance
  end

  def expect_kw(word)
    syntax_error("expected '#{word}', got #{Tokens.describe(current)}") unless check_kw(word)
    advance
  end

  def expect_name
    syntax_error("expected name, got #{Tokens.describe(current)}") unless current.type == :ident
    advance
  end

  def expect_end_of_input
    return if current.type == :eof

    syntax_error("expected end of input, got #{Tokens.describe(current)}")
  end

  # ---- statements ----

  def separator? = current.type == :newline || check_op(";")

  def at_block_end?
    current.type == :eof || (current.type == :kw && BLOCK_END_KEYWORDS.include?(current.text))
  end

  def skip_separators
    advance while separator?
  end

  # Statements up to (not including) `end`, `elif`, `else`, `catch` or the end of input.
  def parse_statements
    stmts = []
    skip_separators
    until at_block_end?
      stmts.push(parse_statement)
      if separator?
        skip_separators
      elsif !at_block_end?
        syntax_error("expected end of statement, got #{Tokens.describe(current)}")
      end
    end
    stmts
  end

  def parse_statement
    tok = current
    if tok.type == :kw
      case tok.text
      when "let" then return parse_let
      when "const" then return parse_const
      when "match" then return parse_match
      when "fn" then return parse_fn_decl if lookahead.type == :ident
      when "if" then return parse_if
      when "while" then return parse_while
      when "for" then return parse_for
      when "try" then return parse_try
      when "return" then return parse_return
      when "throw" then return parse_throw
      when "assert" then return parse_assert
      when "break"
        advance
        return Break.new(tok.pos)
      when "continue"
        advance
        return Continue.new(tok.pos)
      end
    end
    parse_expression_statement
  end

  def parse_let
    advance
    return parse_let_list if check_op("[")

    name = expect_name
    value = nil
    if check_op("=")
      advance
      value = parse_expression
    end
    Let.new(name.text, value, name.pos)
  end

  # After `let`: "[" names "]" "=" value.
  def parse_let_list
    open = advance
    names = []
    while true
      tok = expect_name
      names.push(Param.new(tok.text, nil, tok.pos))
      break unless check_op(",")

      advance
    end
    expect_op("]")
    list_pos = span(open)
    expect_op("=")
    LetList.new(names, parse_expression, list_pos)
  end

  def parse_const
    advance
    name = expect_name
    expect_op("=")
    Const.new(name.text, parse_expression, name.pos)
  end

  def parse_fn_decl
    fn_tok = advance
    name = advance
    FnDecl.new(parse_function_rest(name.text, fn_tok), name.pos)
  end

  # After `fn` (and the name, if any): "(" params ")" body "end".
  def parse_function_rest(name, first)
    expect_op("(")
    params = []
    unless check_op(")")
      while true
        params.push(parse_param(params))
        break unless check_op(",")

        advance
        break if check_op(")")
      end
    end
    expect_op(")")
    body = parse_statements
    expect_kw("end")
    FnExpr.new(name, params, body, span(first))
  end

  # `name` or `name = default`; once one parameter has a default, all later ones need one.
  def parse_param(earlier)
    tok = expect_name
    default = nil
    if check_op("=")
      advance
      default = parse_expression
    elsif !earlier.empty? && !earlier.last.default.nil?
      syntax_error("parameter '#{tok.text}' needs a default value", tok.pos)
    end
    Param.new(tok.text, default, tok.pos)
  end

  def parse_if
    if_tok = advance
    branches = [parse_if_branch]
    while check_kw("elif")
      advance
      branches.push(parse_if_branch)
    end
    else_body = nil
    if check_kw("else")
      advance
      else_body = parse_statements
    end
    expect_kw("end")
    If.new(branches, else_body, if_tok.pos)
  end

  # cond "then" body, after `if` or `elif`.
  def parse_if_branch
    cond = parse_expression
    expect_kw("then")
    IfBranch.new(cond, parse_statements)
  end

  def parse_while
    tok = advance
    cond = parse_expression
    expect_kw("do")
    body = parse_statements
    expect_kw("end")
    While.new(cond, body, tok.pos)
  end

  # for x in xs do ... end, or for k, v in m do ... end
  def parse_for
    tok = advance
    var = expect_name
    vars = [Param.new(var.text, nil, var.pos)]
    if check_op(",")
      advance
      second = expect_name
      vars.push(Param.new(second.text, nil, second.pos))
    end
    expect_kw("in")
    iterable = parse_expression
    expect_kw("do")
    body = parse_statements
    expect_kw("end")
    For.new(vars, iterable, body, tok.pos)
  end

  # match subject (newlines) when v, ... then body ... [else body] end
  def parse_match
    tok = advance
    subject = parse_expression
    skip_separators
    arms = []
    while check_kw("when")
      advance
      values = [parse_expression]
      while check_op(",")
        advance
        values.push(parse_expression)
      end
      expect_kw("then")
      arms.push(MatchArm.new(values, parse_statements))
    end
    syntax_error("expected 'when', got #{Tokens.describe(current)}") if arms.empty?
    else_body = nil
    if check_kw("else")
      advance
      else_body = parse_statements
    end
    expect_kw("end")
    Match.new(subject, arms, else_body, tok.pos)
  end

  # try body [catch name handler] [finally body] end, with at least one of the two.
  def parse_try
    tok = advance
    body = parse_statements
    unless check_kw("catch") || check_kw("finally")
      syntax_error("expected 'catch' or 'finally', got #{Tokens.describe(current)}")
    end
    var = nil
    handler = nil
    if check_kw("catch")
      advance
      name = expect_name
      var = Param.new(name.text, nil, name.pos)
      handler = parse_statements
    end
    finally_body = nil
    if check_kw("finally")
      advance
      finally_body = parse_statements
    end
    expect_kw("end")
    Try.new(body, var, handler, finally_body, tok.pos)
  end

  def parse_return
    tok = advance
    value = (separator? || at_block_end?) ? nil : parse_expression
    Return.new(value, span(tok))
  end

  def parse_throw
    tok = advance
    value = parse_expression
    Throw.new(value, span(tok))
  end

  def parse_assert
    tok = advance
    cond = parse_expression
    message = nil
    if check_op(",")
      advance
      message = parse_expression
    end
    Assert.new(cond, message, span(tok))
  end

  def parse_expression_statement
    first = current
    expr = parse_expression
    return parse_multi_assign(expr, first) if check_op(",")
    return ExprStmt.new(expr) unless current.type == :op && ASSIGNMENT_OPERATORS.include?(current.text)

    op = advance
    check_target(expr)
    value = parse_expression
    Assign.new(expr, op.text, value, span(first))
  end

  def check_target(expr)
    syntax_error("invalid assignment target", expr.pos) unless expr.is_a?(Name) || expr.is_a?(Index)
  end

  # After the first target of `a, b = x, y`.
  def parse_multi_assign(first_target, first)
    targets = [first_target]
    while check_op(",")
      advance
      targets.push(parse_expression)
    end
    expect_op("=")
    targets.each { |target| check_target(target) }
    values = [parse_expression]
    while check_op(",")
      advance
      values.push(parse_expression)
    end
    if values.length != targets.length
      syntax_error("#{Format.count(targets.length, "target")} but #{Format.count(values.length, "value")}", span(first))
    end
    MultiAssign.new(targets, values, span(first))
  end

  # ---- expressions ----

  def parse_expression = parse_or

  def parse_or
    first = current
    left = parse_and
    while check_kw("or")
      advance
      right = parse_and
      left = Logical.new("or", left, right, span(first))
    end
    left
  end

  def parse_and
    first = current
    left = parse_not
    while check_kw("and")
      advance
      right = parse_not
      left = Logical.new("and", left, right, span(first))
    end
    left
  end

  def parse_not
    return parse_comparison unless check_kw("not")

    op = advance
    operand = parse_not
    Unary.new("not", operand, span(op))
  end

  def comparison_op?
    (current.type == :op || current.type == :kw) && COMPARISON_OPERATORS.include?(current.text)
  end

  def parse_comparison
    first = current
    left = parse_additive
    return left unless comparison_op?

    op = advance
    right = parse_additive
    expr = Binary.new(op.text, left, right, span(first))
    syntax_error("comparison operators cannot be chained") if comparison_op?
    expr
  end

  def parse_additive
    first = current
    left = parse_multiplicative
    while current.type == :op && ADDITIVE_OPERATORS.include?(current.text)
      op = advance
      right = parse_multiplicative
      left = Binary.new(op.text, left, right, span(first))
    end
    left
  end

  def parse_multiplicative
    first = current
    left = parse_unary
    while current.type == :op && MULTIPLICATIVE_OPERATORS.include?(current.text)
      op = advance
      right = parse_unary
      left = Binary.new(op.text, left, right, span(first))
    end
    left
  end

  def parse_unary
    return parse_power unless check_op("-")

    op = advance
    operand = parse_unary
    Unary.new("-", operand, span(op))
  end

  # The exponent may itself be negated or a power: 2 ** -1, 2 ** 3 ** 2 = 2 ** 9.
  def parse_power
    first = current
    base = parse_postfix
    return base unless check_op("**")

    advance
    exponent = parse_unary
    Binary.new("**", base, exponent, span(first))
  end

  def parse_postfix
    first = current
    expr = parse_primary
    while true
      if check_op("(")
        advance
        args = parse_list(")")
        expr = Call.new(expr, args, span(first))
      elsif check_op("[")
        advance
        expr = parse_index_rest(expr, first)
      elsif check_op(".")
        advance
        field = expect_name
        expr = Index.new(expr, StrLit.new(field.text, field.pos), span(first))
      else
        return expr
      end
    end
  end

  # After the "[" of `target[`: an index `i]` or a slice `start:stop]`, where
  # either bound may be left out. `first` is the token the target starts with.
  def parse_index_rest(target, first)
    start = check_op(":") ? nil : parse_expression
    if check_op("]") && !start.nil?
      advance
      return Index.new(target, start, span(first))
    end
    expect_op(":")
    stop = check_op("]") ? nil : parse_expression
    expect_op("]")
    Slice.new(target, start, stop, span(first))
  end

  # Comma-separated expressions up to and including `closer`, after the opener.
  # A trailing comma is allowed (here, in maps, and in parameter lists).
  def parse_list(closer)
    items = []
    unless check_op(closer)
      while true
        items.push(parse_expression)
        break unless check_op(",")

        advance
        break if check_op(closer)
      end
    end
    expect_op(closer)
    items
  end

  def parse_primary
    tok = current
    case tok.type
    when :int
      advance
      return IntLit.new(tok.value, tok.pos)
    when :str
      advance
      return StrLit.new(tok.value, tok.pos)
    when :interp
      advance
      return parse_interpolated_string(tok)
    when :ident
      advance
      return Name.new(tok.text, tok.pos, nil)
    when :kw
      case tok.text
      when "true", "false"
        advance
        return BoolLit.new(tok.text == "true", tok.pos)
      when "nil"
        advance
        return NilLit.new(tok.pos)
      when "fn"
        advance
        return parse_function_rest(nil, tok)
      end
    when :op
      case tok.text
      when "("
        advance
        expr = parse_expression
        expect_op(")")
        return expr
      when "["
        advance
        elements = parse_list("]")
        return ArrayLit.new(elements, span(tok))
      when "{"
        advance
        return parse_map_rest(tok)
      end
    end
    syntax_error("expected expression, got #{Tokens.describe(tok)}")
  end

  def parse_interpolated_string(tok)
    parts = tok.value.map do |part|
      part.is_a?(String) ? part : Parser.new(part).parse_interpolation
    end
    InterpStr.new(parts, tok.pos)
  end

  # After "{": entries `key: value` separated by commas, then "}".
  def parse_map_rest(first)
    keys = []
    values = []
    unless check_op("}")
      while true
        keys.push(parse_expression)
        expect_op(":")
        values.push(parse_expression)
        break unless check_op(",")

        advance
        break if check_op("}")
      end
    end
    expect_op("}")
    MapLit.new(keys, values, span(first))
  end
end
