require_relative "errors"
require_relative "lexer"
require_relative "ast"

# A recursive-descent parser for one statement's tokens (grammar of spec 1.4-1.8, 2.1-2.3, 3.1, 4.1, 4.3,
# 5, 6.1). Any token the grammar does not allow raises SqlError "syntax error". Returns nil for an empty
# statement.
class Parser
  # Binary operators by binding strength (higher binds tighter); spec 1.8 lists the levels, and 2.3
  # puts IN, LIKE and BETWEEN (and their NOT forms) on the level of `=`.
  BINARY_PRECEDENCE = {
    "OR" => 1, "AND" => 2,
    "=" => 4, "==" => 4, "!=" => 4, "<>" => 4, "IS" => 4,
    "IN" => 4, "LIKE" => 4, "BETWEEN" => 4, "NOT IN" => 4, "NOT LIKE" => 4, "NOT BETWEEN" => 4,
    "<" => 5, "<=" => 5, ">" => 5, ">=" => 5,
    "+" => 6, "-" => 6, "*" => 7, "/" => 7, "%" => 7, "||" => 8
  }.freeze
  NOT_PRECEDENCE = 3
  UNARY_PRECEDENCE = 9
  # The postfix COLLATE binds tighter than every binary operator (7.2).
  COLLATE_PRECEDENCE = 10
  # BETWEEN's bounds are parsed at the level just tighter than `=` (spec 2.3).
  BETWEEN_BOUND_PRECEDENCE = 5
  KEYWORD_OPERATORS = %w[AND OR IS IN LIKE BETWEEN].freeze
  NEGATABLE = %w[IN LIKE BETWEEN].freeze
  COLUMN_TYPES = %w[INTEGER REAL TEXT].freeze
  COMPOUND_OPERATORS = %w[UNION INTERSECT EXCEPT].freeze
  TRANSACTIONS = { "BEGIN" => :begin, "COMMIT" => :commit, "END" => :commit, "ROLLBACK" => :rollback }.freeze

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
      if keyword?("CREATE") then parse_create
      elsif keyword?("DROP") then parse_drop
      elsif keyword?("ALTER") then parse_alter
      elsif keyword?("INSERT") then parse_insert
      elsif keyword?("UPDATE") then parse_update
      elsif keyword?("DELETE") then parse_delete
      elsif keyword?("SELECT") then parse_select
      elsif keyword?("WITH") then parse_with_statement
      elsif peek.kind == :keyword && TRANSACTIONS.key?(peek.value) then parse_transaction
      else raise SqlError.syntax
      end
    expect_kind(:eof)
    statement
  end

  private

  # --- statements

  def parse_create
    expect_keyword("CREATE")
    if accept_keyword("VIEW") then parse_create_view
    elsif accept_keyword("UNIQUE") then expect_keyword("INDEX"); parse_create_index(true)
    elsif accept_keyword("INDEX") then parse_create_index(false)
    else expect_keyword("TABLE"); parse_create_table
    end
  end

  def parse_if_not_exists
    accept_keyword("IF") ? (expect_keyword("NOT"); expect_keyword("EXISTS"); true) : false
  end

  def parse_if_exists
    accept_keyword("IF") ? (expect_keyword("EXISTS"); true) : false
  end

  # After CREATE TABLE. Column definitions first, then table constraints (spec 2.1).
  def parse_create_table
    if_not_exists = parse_if_not_exists
    name = expect_name
    expect_op("(")
    columns = []
    constraints = []
    loop do
      if keyword?("PRIMARY") || keyword?("UNIQUE")
        constraints << parse_table_constraint
      else
        raise SqlError.syntax unless constraints.empty?
        columns << parse_column_def
      end
      break unless accept_op(",")
    end
    expect_op(")")
    AST::CreateTable.new(name, if_not_exists, columns, constraints)
  end

  def parse_column_def
    name = expect_name
    type = parse_type
    constraints = []
    default = AST::NO_DEFAULT
    collation = nil
    loop do
      if accept_keyword("PRIMARY")
        expect_keyword("KEY")
        constraints << :primary_key
      elsif accept_keyword("NOT")
        expect_keyword("NULL")
        constraints << :not_null
      elsif accept_keyword("UNIQUE")
        constraints << :unique
      elsif accept_keyword("DEFAULT")
        default = parse_default_value
      elsif accept_keyword("COLLATE")
        collation = expect_name
      else
        break
      end
    end
    AST::ColumnDef.new(name, type, constraints, default, collation)
  end

  def parse_type
    token = peek
    raise SqlError.syntax unless token.kind == :ident && COLUMN_TYPES.include?(token.value.upcase)
    advance
    token.value.upcase
  end

  # [+ | -] numeric-literal | string-literal | NULL
  def parse_default_value
    return nil if accept_keyword("NULL")
    return advance.value if peek.kind == :string
    sign = accept_op("-") ? -1 : (accept_op("+"); 1)
    token = advance
    raise SqlError.syntax unless token.kind == :integer || token.kind == :real
    token.value * sign
  end

  def parse_table_constraint
    kind = accept_keyword("UNIQUE") ? :unique : (expect_keyword("PRIMARY"); expect_keyword("KEY"); :primary_key)
    expect_op("(")
    columns = comma_list { expect_name }
    expect_op(")")
    AST::TableConstraint.new(kind, columns)
  end

  # After CREATE VIEW (5.3).
  def parse_create_view
    if_not_exists = parse_if_not_exists
    name = expect_name
    columns = parse_name_list if peek.op?("(")
    expect_keyword("AS")
    AST::CreateView.new(name, if_not_exists, columns, parse_select)
  end

  # After CREATE [UNIQUE] INDEX (5.7): ( column [COLLATE name] [, ...] ) (7.2).
  def parse_create_index(unique)
    if_not_exists = parse_if_not_exists
    name = expect_name
    expect_keyword("ON")
    table = expect_name
    expect_op("(")
    columns = comma_list { [expect_name, accept_keyword("COLLATE") && expect_name] }
    expect_op(")")
    AST::CreateIndex.new(name, unique, if_not_exists, table, columns.map(&:first), columns.map(&:last))
  end

  def parse_drop
    expect_keyword("DROP")
    kind = %w[TABLE VIEW INDEX].find { |word| accept_keyword(word) } or raise SqlError.syntax
    if_exists = parse_if_exists
    name = expect_name
    { "TABLE" => AST::DropTable, "VIEW" => AST::DropView, "INDEX" => AST::DropIndex }.fetch(kind).new(name, if_exists)
  end

  # ALTER TABLE t ADD [COLUMN] column-def | RENAME TO name | RENAME [COLUMN] column TO name (5.6)
  def parse_alter
    expect_keyword("ALTER")
    expect_keyword("TABLE")
    table = expect_name
    if accept_keyword("ADD")
      accept_keyword("COLUMN")
      return AST::AddColumn.new(table, parse_column_def)
    end
    expect_keyword("RENAME")
    return AST::RenameTable.new(table, expect_name) if accept_keyword("TO")
    accept_keyword("COLUMN")
    column = expect_name
    expect_keyword("TO")
    AST::RenameColumn.new(table, column, expect_name)
  end

  # BEGIN | COMMIT | END | ROLLBACK, each with an optional TRANSACTION (5.5).
  def parse_transaction
    action = TRANSACTIONS.fetch(advance.value)
    accept_keyword("TRANSACTION")
    AST::Transaction.new(action)
  end

  # ( name [, name]... )
  def parse_name_list
    expect_op("(")
    names = comma_list { expect_name }
    expect_op(")")
    names
  end

  # WITH ... followed by a select, or by an INSERT (5.4).
  def parse_with_statement
    with = parse_with_clause
    return AST::With.new(with.recursive, with.ctes, parse_query_body) unless keyword?("INSERT")
    insert = parse_insert
    insert.with = with
    insert
  end

  def parse_insert
    expect_keyword("INSERT")
    expect_keyword("INTO")
    table = expect_name
    columns = parse_name_list if peek.op?("(")
    return AST::Insert.new(table, columns, nil, parse_select, nil) unless accept_keyword("VALUES")
    rows = comma_list do
      expect_op("(")
      values = comma_list { parse_expr }
      expect_op(")")
      values
    end
    AST::Insert.new(table, columns, rows, nil, nil)
  end

  def parse_update
    expect_keyword("UPDATE")
    table = expect_name
    expect_keyword("SET")
    assignments = comma_list do
      column = expect_name
      expect_op("=")
      [column, parse_expr]
    end
    where = accept_keyword("WHERE") ? parse_expr : nil
    AST::Update.new(table, assignments, where)
  end

  def parse_delete
    expect_keyword("DELETE")
    expect_keyword("FROM")
    table = expect_name
    where = accept_keyword("WHERE") ? parse_expr : nil
    AST::Delete.new(table, where)
  end

  # select := [WITH ...] simple-select [compound-op simple-select]... [ORDER BY ...] [LIMIT ...] (5.1)
  def parse_select
    return parse_query_body unless keyword?("WITH")
    with = parse_with_clause
    AST::With.new(with.recursive, with.ctes, parse_query_body)
  end

  # WITH [RECURSIVE] cte [, cte]..., as a With without a body (5.2).
  def parse_with_clause
    expect_keyword("WITH")
    recursive = !accept_keyword("RECURSIVE").nil?
    ctes = comma_list do
      name = expect_name
      columns = parse_name_list if peek.op?("(")
      expect_keyword("AS")
      expect_op("(")
      select = parse_select
      expect_op(")")
      AST::Cte.new(name, columns, select)
    end
    AST::With.new(recursive, ctes, nil)
  end

  # A select without WITH: one simple-select (a Select carrying the ORDER BY and LIMIT), or a Compound.
  def parse_query_body
    parts = [[nil, parse_simple_select]]
    while (op = compound_operator)
      parts << [op, parse_simple_select]
    end
    order_by = parse_order_by
    limit = offset = nil
    if accept_keyword("LIMIT")
      limit = parse_expr
      offset = parse_expr if accept_keyword("OFFSET")
    end
    return AST::Compound.new(parts, order_by, limit, offset) if parts.length > 1
    select = parts[0][1]
    select.order_by = order_by
    select.limit = limit
    select.offset = offset
    select
  end

  def compound_operator
    word = COMPOUND_OPERATORS.find { |w| accept_keyword(w) } or return nil
    word == "UNION" && accept_keyword("ALL") ? "UNION ALL" : word
  end

  # SELECT ... without ORDER BY and LIMIT.
  def parse_simple_select
    expect_keyword("SELECT")
    distinct = accept_keyword("DISTINCT") ? true : (accept_keyword("ALL"); false)
    columns = comma_list { parse_result_column }
    from = accept_keyword("FROM") ? parse_from : nil
    where = accept_keyword("WHERE") ? parse_expr : nil
    group_by = []
    if accept_keyword("GROUP")
      expect_keyword("BY")
      group_by = comma_list { parse_expr }
    end
    having = accept_keyword("HAVING") ? parse_expr : nil
    windows = []
    if accept_keyword("WINDOW")
      windows = comma_list do
        name = expect_name
        expect_keyword("AS")
        [name, parse_window_spec]
      end
    end
    AST::Select.new(distinct, columns, from, where, group_by, having, [], nil, nil, windows)
  end

  # ( [base-window-name] [PARTITION BY expr, ...] [ORDER BY ...] [frame] ) (6.1)
  def parse_window_spec
    expect_op("(")
    base = peek.kind == :ident ? advance.value : nil
    partition_by = []
    if accept_keyword("PARTITION")
      expect_keyword("BY")
      partition_by = comma_list { parse_expr }
    end
    order_by = parse_order_by
    frame = parse_frame if keyword?("ROWS") || keyword?("RANGE")
    expect_op(")")
    AST::WindowSpec.new(base, partition_by, order_by, frame)
  end

  # (ROWS | RANGE) frame-start | (ROWS | RANGE) BETWEEN frame-start AND frame-end; a start alone ends
  # at CURRENT ROW.
  def parse_frame
    unit = advance.value == "ROWS" ? :rows : :range
    return AST::FrameSpec.new(unit, parse_frame_bound(:start), AST::FrameBound.new(:current_row, nil)) unless accept_keyword("BETWEEN")
    start = parse_frame_bound(:start)
    expect_keyword("AND")
    AST::FrameSpec.new(unit, start, parse_frame_bound(:end))
  end

  # UNBOUNDED PRECEDING (a start) | UNBOUNDED FOLLOWING (an end) | CURRENT ROW | n PRECEDING | n FOLLOWING
  def parse_frame_bound(side)
    if accept_keyword("UNBOUNDED")
      word = side == :start ? "PRECEDING" : "FOLLOWING"
      expect_keyword(word)
      return AST::FrameBound.new(:"unbounded_#{word.downcase}", nil)
    end
    if accept_keyword("CURRENT")
      expect_keyword("ROW")
      return AST::FrameBound.new(:current_row, nil)
    end
    offset = parse_expr
    return AST::FrameBound.new(:preceding, offset) if accept_keyword("PRECEDING")
    expect_keyword("FOLLOWING")
    AST::FrameBound.new(:following, offset)
  end

  def select_start? = keyword?("SELECT") || keyword?("WITH")

  # from-item [join-op from-item [join-constraint]]... (spec 4.1)
  def parse_from
    first = parse_from_item
    joins = []
    loop do
      kind =
        if accept_op(",") then :comma
        elsif accept_keyword("CROSS") then expect_keyword("JOIN"); :comma
        elsif accept_keyword("INNER") then expect_keyword("JOIN"); :inner
        elsif accept_keyword("JOIN") then :inner
        elsif accept_keyword("LEFT") then accept_keyword("OUTER"); expect_keyword("JOIN"); :left
        else break
        end
      source = parse_from_item
      on, using = kind == :comma ? [nil, nil] : parse_join_constraint
      raise SqlError.syntax if kind == :left && on.nil? && using.nil?
      joins << AST::Join.new(kind == :left ? :left : :inner, source, on, using)
    end
    AST::From.new(first, joins)
  end

  # table [[AS] alias] | ( select ) [[AS] alias]
  def parse_from_item
    if accept_op("(")
      select = parse_select
      expect_op(")")
      AST::SubquerySource.new(select, parse_alias)
    else
      AST::TableSource.new(expect_name, parse_alias)
    end
  end

  # [ON expr | USING ( column [, column]... )] as [on, using].
  def parse_join_constraint
    return [parse_expr, nil] if accept_keyword("ON")
    return [nil, nil] unless accept_keyword("USING")
    expect_op("(")
    columns = comma_list { expect_name }
    expect_op(")")
    [nil, columns]
  end

  # [[AS] alias]
  def parse_alias
    return expect_name if accept_keyword("AS")
    peek.kind == :ident ? advance.value : nil
  end

  # [ORDER BY ordering-term [, ...]], as a list of terms.
  def parse_order_by
    return [] unless accept_keyword("ORDER")
    expect_keyword("BY")
    comma_list { parse_ordering_term }
  end

  def parse_result_column
    return AST::Star.new(nil) if accept_op("*")
    if peek.kind == :ident && peek(1).op?(".") && peek(2).op?("*")
      source = advance.value
      advance
      advance
      return AST::Star.new(source)
    end
    expr = parse_expr
    AST::ResultColumn.new(expr, parse_alias)
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
      if keyword?("COLLATE") && COLLATE_PRECEDENCE >= min_precedence
        advance
        left = AST::Collate.new(left, expect_name)
        next
      end
      op = binary_operator or break
      precedence = BINARY_PRECEDENCE[op]
      break if precedence < min_precedence
      advance
      advance if op.start_with?("NOT ")
      left = parse_operation(op, left, precedence)
    end
    left
  end

  # The rest of `left op ...`, with op's tokens consumed.
  def parse_operation(op, left, precedence)
    negated = op.start_with?("NOT ")
    case op.delete_prefix("NOT ")
    when "IS"
      op = "IS NOT" if accept_keyword("NOT")
      AST::Binary.new(op, left, parse_expr(precedence + 1))
    when "IN"
      expect_op("(")
      if select_start?
        select = parse_select
        expect_op(")")
        return AST::InSelect.new(left, select, negated)
      end
      list = comma_list { parse_expr }
      expect_op(")")
      AST::In.new(left, list, negated)
    when "LIKE"
      AST::Like.new(left, parse_expr(precedence + 1), negated)
    when "BETWEEN"
      low = parse_expr(BETWEEN_BOUND_PRECEDENCE)
      expect_keyword("AND")
      AST::Between.new(left, low, parse_expr(BETWEEN_BOUND_PRECEDENCE), negated)
    else
      AST::Binary.new(op, left, parse_expr(precedence + 1))
    end
  end

  # The operator the next tokens are, if they are a binary one ("NOT IN" for two tokens).
  def binary_operator
    token = peek
    case token.kind
    when :op then BINARY_PRECEDENCE.key?(token.value) ? token.value : nil
    when :keyword
      if KEYWORD_OPERATORS.include?(token.value)
        token.value
      elsif token.value == "NOT" && peek(1).kind == :keyword && NEGATABLE.include?(peek(1).value)
        "NOT #{peek(1).value}"
      end
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
      case token.value
      when "NULL" then AST::Literal.new(nil)
      when "CASE" then parse_case
      when "CAST" then parse_cast
      when "EXISTS" then AST::Exists.new(parse_parenthesized_select)
      else raise SqlError.syntax
      end
    when :ident
      if accept_op("(") then parse_call(token.value)
      elsif accept_op(".") then AST::QualifiedName.new(token.value, expect_name)
      else AST::Name.new(token.value)
      end
    when :op
      raise SqlError.syntax unless token.value == "("
      if select_start?
        select = parse_select
        expect_op(")")
        return AST::Subquery.new(select)
      end
      expr = parse_expr
      expect_op(")")
      AST::Paren.new(expr)
    else
      raise SqlError.syntax
    end
  end

  # After `name (`: `*)`, or [DISTINCT] [expr [, expr]...] [ORDER BY ...] ), then OVER ... (spec 1.8,
  # 3.1, 6.1).
  def parse_call(name)
    if accept_op("*")
      expect_op(")")
      return AST::Call.new(name, [], false, [], true, parse_over)
    end
    distinct = !accept_keyword("DISTINCT").nil?
    args = peek.op?(")") || keyword?("ORDER") ? [] : comma_list { parse_expr }
    order_by = parse_order_by
    expect_op(")")
    AST::Call.new(name, args, distinct, order_by, false, parse_over)
  end

  # [OVER window-name | OVER ( window-spec )] after a call (6.1).
  def parse_over
    return nil unless accept_keyword("OVER")
    peek.op?("(") ? parse_window_spec : expect_name
  end

  def parse_parenthesized_select
    expect_op("(")
    select = parse_select
    expect_op(")")
    select
  end

  # After CASE: [base] WHEN c THEN r [WHEN ...]... [ELSE e] END
  def parse_case
    base = keyword?("WHEN") ? nil : parse_expr
    whens = []
    while accept_keyword("WHEN")
      condition = parse_expr
      expect_keyword("THEN")
      whens << [condition, parse_expr]
    end
    raise SqlError.syntax if whens.empty?
    else_expr = accept_keyword("ELSE") ? parse_expr : nil
    expect_keyword("END")
    AST::Case.new(base, whens, else_expr)
  end

  # After CAST: ( expr AS type )
  def parse_cast
    expect_op("(")
    expr = parse_expr
    expect_keyword("AS")
    type = parse_type
    expect_op(")")
    AST::Cast.new(expr, type)
  end

  # --- token helpers

  def comma_list
    items = [yield]
    items << yield while accept_op(",")
    items
  end

  def peek(offset = 0) = @tokens[[@pos + offset, @tokens.length - 1].min]

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
