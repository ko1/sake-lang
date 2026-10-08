require_relative "errors"
require_relative "lexer"
require_relative "ast"

# A recursive-descent parser for one statement's tokens (grammar of spec 1.4-1.8). Any token the
# grammar does not allow raises SqlError "syntax error". Returns nil for an empty statement.
class Parser
  # Binary operators by binding strength (higher binds tighter); spec 1.8 lists the levels.
  BINARY_PRECEDENCE = {
    "OR" => 1, "AND" => 2,
    "=" => 4, "==" => 4, "!=" => 4, "<>" => 4, "IS" => 4,
    "<" => 5, "<=" => 5, ">" => 5, ">=" => 5,
    "+" => 6, "-" => 6, "*" => 7, "/" => 7, "%" => 7, "||" => 8
  }.freeze
  NOT_PRECEDENCE = 3
  UNARY_PRECEDENCE = 9
  COLUMN_TYPES = %w[INTEGER REAL TEXT].freeze

  def self.parse(source)
    new(Lexer.tokenize(source)).parse_statement
  end

  def initialize(tokens)
    @tokens = tokens
    @pos = 0
  end

  def parse_statement
    return nil if peek.kind == :eof
    statement =
      if keyword?("CREATE") then parse_create_table
      elsif keyword?("DROP") then parse_drop_table
      elsif keyword?("INSERT") then parse_insert
      elsif keyword?("SELECT") then parse_select
      else raise SqlError.syntax
      end
    expect_kind(:eof)
    statement
  end

  private

  # --- statements

  def parse_create_table
    expect_keyword("CREATE")
    expect_keyword("TABLE")
    if_not_exists = accept_keyword("IF") ? (expect_keyword("NOT"); expect_keyword("EXISTS"); true) : false
    name = expect_name
    expect_op("(")
    columns = comma_list { parse_column_def }
    expect_op(")")
    AST::CreateTable.new(name, if_not_exists, columns)
  end

  def parse_column_def
    name = expect_name
    type = peek
    raise SqlError.syntax unless type.kind == :ident && COLUMN_TYPES.include?(type.value.upcase)
    advance
    AST::ColumnDef.new(name, type.value.upcase)
  end

  def parse_drop_table
    expect_keyword("DROP")
    expect_keyword("TABLE")
    if_exists = accept_keyword("IF") ? (expect_keyword("EXISTS"); true) : false
    AST::DropTable.new(expect_name, if_exists)
  end

  def parse_insert
    expect_keyword("INSERT")
    expect_keyword("INTO")
    table = expect_name
    columns = nil
    if accept_op("(")
      columns = comma_list { expect_name }
      expect_op(")")
    end
    expect_keyword("VALUES")
    rows = comma_list do
      expect_op("(")
      values = comma_list { parse_expr }
      expect_op(")")
      values
    end
    AST::Insert.new(table, columns, rows)
  end

  def parse_select
    expect_keyword("SELECT")
    columns = comma_list { parse_result_column }
    from = accept_keyword("FROM") ? expect_name : nil
    where = accept_keyword("WHERE") ? parse_expr : nil
    order_by = []
    if accept_keyword("ORDER")
      expect_keyword("BY")
      order_by = comma_list { parse_ordering_term }
    end
    limit = offset = nil
    if accept_keyword("LIMIT")
      limit = parse_expr
      offset = parse_expr if accept_keyword("OFFSET")
    end
    AST::Select.new(columns, from, where, order_by, limit, offset)
  end

  def parse_result_column
    return AST::Star.new if accept_op("*")
    expr = parse_expr
    name = if accept_keyword("AS") then expect_name
           elsif peek.kind == :ident then advance.value
           end
    AST::ResultColumn.new(expr, name)
  end

  def parse_ordering_term
    expr = parse_expr
    descending = accept_keyword("DESC") ? true : (accept_keyword("ASC"); false)
    nulls_first = nil
    if accept_keyword("NULLS")
      if accept_keyword("FIRST") then nulls_first = true
      else expect_keyword("LAST"); nulls_first = false
      end
    end
    AST::OrderingTerm.new(expr, descending, nulls_first)
  end

  # --- expressions (precedence climbing)

  def parse_expr(min_precedence = 1)
    left = parse_prefix
    loop do
      op = binary_operator or break
      precedence = BINARY_PRECEDENCE[op]
      break if precedence < min_precedence
      advance
      op = "IS NOT" if op == "IS" && accept_keyword("NOT")
      left = AST::Binary.new(op, left, parse_expr(precedence + 1))
    end
    left
  end

  # The operator the next token is, if it is a binary one.
  def binary_operator
    token = peek
    case token.kind
    when :op then BINARY_PRECEDENCE.key?(token.value) ? token.value : nil
    when :keyword then %w[AND OR IS].include?(token.value) ? token.value : nil
    end
  end

  # NOT takes as its operand everything that binds tighter than NOT, even where it appears as the
  # operand of a tighter operator (`1 = NOT 0 = 0` is `1 = NOT (0 = 0)`, as in SQLite).
  def parse_prefix
    return AST::Unary.new("NOT", parse_expr(NOT_PRECEDENCE)) if accept_keyword("NOT")
    if peek.op?("-") || peek.op?("+")
      return AST::Unary.new(advance.value, parse_expr(UNARY_PRECEDENCE))
    end
    parse_primary
  end

  def parse_primary
    token = advance
    case token.kind
    when :integer, :real, :string
      AST::Literal.new(token.value)
    when :keyword
      raise SqlError.syntax unless token.value == "NULL"
      AST::Literal.new(nil)
    when :ident
      return AST::Name.new(token.value) unless accept_op("(")
      args = peek.op?(")") ? [] : comma_list { parse_expr }
      expect_op(")")
      AST::Call.new(token.value, args)
    when :op
      raise SqlError.syntax unless token.value == "("
      expr = parse_expr
      expect_op(")")
      AST::Paren.new(expr)
    else
      raise SqlError.syntax
    end
  end

  # --- token helpers

  def comma_list
    items = [yield]
    items << yield while accept_op(",")
    items
  end

  def peek = @tokens[@pos]

  def advance
    token = @tokens[@pos]
    @pos += 1 unless token.kind == :eof
    token
  end

  def keyword?(word) = peek.keyword?(word)

  def accept_keyword(word)
    keyword?(word) ? advance : nil
  end

  def accept_op(op)
    peek.op?(op) ? advance : nil
  end

  def expect_keyword(word)
    accept_keyword(word) or raise SqlError.syntax
  end

  def expect_op(op)
    accept_op(op) or raise SqlError.syntax
  end

  def expect_kind(kind)
    raise SqlError.syntax unless peek.kind == kind
    advance
  end

  def expect_name
    expect_kind(:ident).value
  end
end
