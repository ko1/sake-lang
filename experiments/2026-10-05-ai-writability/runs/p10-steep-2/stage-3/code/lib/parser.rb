module MiniSql
  # Recursive-descent parser for one statement's tokens (ending with an :eof token).
  class Parser
    COMPARISON_OPS = %w[< <= > >=].freeze
    EQUALITY_OPS = %w[= == != <>].freeze

    def self.parse(tokens)
      new(tokens).parse_statement
    end

    def initialize(tokens)
      @tokens = tokens
      @pos = 0
    end

    def parse_statement
      statement =
        if accept_keyword("CREATE") then parse_create
        elsif accept_keyword("DROP") then parse_drop
        elsif accept_keyword("INSERT") then parse_insert
        elsif accept_keyword("SELECT") then parse_select
        elsif accept_keyword("UPDATE") then parse_update
        elsif accept_keyword("DELETE") then parse_delete
        else syntax_error
        end
      syntax_error unless peek.kind == :eof
      statement
    end

    private

    def syntax_error
      raise SqlError, "syntax error"
    end

    def peek
      @tokens[@pos] || Token.new(:eof, "")
    end

    # The token `offset` places after the current one.
    def peek_at(offset)
      @tokens[@pos + offset] || Token.new(:eof, "")
    end

    def advance
      token = peek
      @pos += 1 unless token.kind == :eof
      token
    end

    def accept_keyword(word)
      return false unless peek.keyword?(word)
      advance
      true
    end

    def accept_symbol(text)
      return false unless peek.symbol?(text)
      advance
      true
    end

    def expect_keyword(word)
      syntax_error unless accept_keyword(word)
    end

    def expect_symbol(text)
      syntax_error unless accept_symbol(text)
    end

    def expect_ident
      token = peek
      syntax_error unless token.kind == :ident
      advance.text
    end

    # CREATE TABLE [IF NOT EXISTS] name ( column-def, ... )
    def parse_create
      expect_keyword("TABLE")
      if_not_exists = false
      if accept_keyword("IF")
        expect_keyword("NOT")
        expect_keyword("EXISTS")
        if_not_exists = true
      end
      name = expect_ident
      expect_symbol("(")
      columns = [parse_column_def]
      constraints = [] # @type var constraints: Array[TableConstraint]
      while accept_symbol(",")
        if peek.keyword?("PRIMARY") || peek.keyword?("UNIQUE")
          constraints << parse_table_constraint
        else
          syntax_error unless constraints.empty?
          columns << parse_column_def
        end
      end
      expect_symbol(")")
      CreateTable.new(name, columns, constraints, if_not_exists)
    end

    # name type [PRIMARY KEY | NOT NULL | UNIQUE | DEFAULT value]...
    def parse_column_def
      name = expect_ident
      type = peek.kind == :ident ? type_named(peek.text.upcase(:ascii)) : nil
      syntax_error unless type
      advance
      primary_key = false
      not_null = false
      unique = false
      default = nil # @type var default: sql_value
      loop do
        if accept_keyword("PRIMARY")
          expect_keyword("KEY")
          primary_key = true
        elsif accept_keyword("NOT")
          expect_keyword("NULL")
          not_null = true
        elsif accept_keyword("UNIQUE")
          unique = true
        elsif accept_keyword("DEFAULT")
          default = parse_default_value
        else
          break
        end
      end
      ColumnDef.new(name, type, primary_key, not_null, unique, default)
    end

    # [+ | -] numeric-literal | string-literal | NULL
    def parse_default_value
      token = peek
      case token.kind
      when :string
        advance
        token.text
      when :keyword
        expect_keyword("NULL")
        nil
      else
        negative = accept_symbol("-")
        accept_symbol("+") unless negative
        number = peek
        syntax_error unless number.kind == :number
        advance
        value = Value.number_from(number.text)
        negative ? Operators.negate(value) : value
      end
    end

    # PRIMARY KEY (column, ...) | UNIQUE (column, ...)
    def parse_table_constraint
      kind = :unique
      if accept_keyword("PRIMARY")
        expect_keyword("KEY")
        kind = :primary
      else
        expect_keyword("UNIQUE")
      end
      expect_symbol("(")
      names = [expect_ident]
      names << expect_ident while accept_symbol(",")
      expect_symbol(")")
      TableConstraint.new(kind, names)
    end

    def type_named(word)
      case word
      when "INTEGER" then :integer
      when "REAL" then :real
      when "TEXT" then :text
      end
    end

    # DROP TABLE [IF EXISTS] name
    def parse_drop
      expect_keyword("TABLE")
      if_exists = false
      if accept_keyword("IF")
        expect_keyword("EXISTS")
        if_exists = true
      end
      DropTable.new(expect_ident, if_exists)
    end

    # INSERT INTO table [(column, ...)] VALUES (expr, ...), ...
    def parse_insert
      expect_keyword("INTO")
      table = expect_ident
      columns = nil # @type var columns: Array[String]?
      if accept_symbol("(")
        names = [expect_ident]
        names << expect_ident while accept_symbol(",")
        expect_symbol(")")
        columns = names
      end
      expect_keyword("VALUES")
      rows = [parse_value_row]
      rows << parse_value_row while accept_symbol(",")
      Insert.new(table, columns, rows)
    end

    def parse_value_row
      expect_symbol("(")
      values = [parse_expr]
      values << parse_expr while accept_symbol(",")
      expect_symbol(")")
      values
    end

    # UPDATE table SET column = expr, ... [WHERE expr]
    def parse_update
      table = expect_ident
      expect_keyword("SET")
      assignments = [parse_assignment]
      assignments << parse_assignment while accept_symbol(",")
      where = accept_keyword("WHERE") ? parse_expr : nil
      Update.new(table, assignments, where)
    end

    def parse_assignment
      column = expect_ident
      expect_symbol("=")
      Assignment.new(column, parse_expr)
    end

    # DELETE FROM table [WHERE expr]
    def parse_delete
      expect_keyword("FROM")
      table = expect_ident
      where = accept_keyword("WHERE") ? parse_expr : nil
      Delete.new(table, where)
    end

    # SELECT [DISTINCT | ALL] result-column, ... [FROM table] [WHERE expr] [GROUP BY expr, ...]
    # [HAVING expr] [ORDER BY ...] [LIMIT expr [OFFSET expr]]
    def parse_select
      distinct = accept_keyword("DISTINCT")
      accept_keyword("ALL") unless distinct
      columns = [parse_result_column]
      columns << parse_result_column while accept_symbol(",")
      from = accept_keyword("FROM") ? expect_ident : nil
      where = accept_keyword("WHERE") ? parse_expr : nil
      group_by = [] # @type var group_by: Array[Expr]
      if accept_keyword("GROUP")
        expect_keyword("BY")
        group_by << parse_expr
        group_by << parse_expr while accept_symbol(",")
      end
      having = accept_keyword("HAVING") ? parse_expr : nil
      order_by = parse_order_by
      limit = nil # @type var limit: Expr?
      offset = nil # @type var offset: Expr?
      if accept_keyword("LIMIT")
        limit = parse_expr
        offset = parse_expr if accept_keyword("OFFSET")
      end
      Select.new(distinct, columns, from, where, group_by, having, order_by, limit, offset)
    end

    # [ORDER BY ordering-term, ...]: empty when absent.
    def parse_order_by
      order_by = [] # @type var order_by: Array[OrderTerm]
      if accept_keyword("ORDER")
        expect_keyword("BY")
        order_by << parse_order_term
        order_by << parse_order_term while accept_symbol(",")
      end
      order_by
    end

    def parse_result_column
      return ResultColumn.new(nil, nil) if accept_symbol("*")
      expr = parse_expr
      alias_name = nil # @type var alias_name: String?
      if accept_keyword("AS")
        alias_name = expect_ident
      elsif peek.kind == :ident
        alias_name = advance.text
      end
      ResultColumn.new(expr, alias_name)
    end

    def parse_order_term
      expr = parse_expr
      descending = false
      if accept_keyword("DESC")
        descending = true
      else
        accept_keyword("ASC")
      end
      nulls = nil # @type var nulls: Symbol?
      if accept_keyword("NULLS")
        if accept_keyword("FIRST")
          nulls = :first
        else
          expect_keyword("LAST")
          nulls = :last
        end
      end
      OrderTerm.new(expr, descending, nulls)
    end

    # Expressions, loosest binding first (see SPEC 1.8).
    def parse_expr
      parse_or
    end

    def parse_or
      left = parse_and
      left = Binary.new("OR", left, parse_and) while accept_keyword("OR")
      left
    end

    def parse_and
      left = parse_not
      left = Binary.new("AND", left, parse_not) while accept_keyword("AND")
      left
    end

    def parse_not
      return Not.new(parse_not) if accept_keyword("NOT")
      parse_equality
    end

    def parse_equality
      left = parse_comparison
      loop do
        token = peek
        if token.kind == :symbol && EQUALITY_OPS.include?(token.text)
          advance
          left = Binary.new(token.text, left, parse_comparison)
        elsif accept_keyword("IS")
          negated = accept_keyword("NOT")
          left = Is.new(negated, left, parse_comparison)
        elsif (word = membership_keyword)
          left = parse_membership(word, left)
        else
          return left
        end
      end
    end

    # Consumes `[NOT] IN | LIKE | BETWEEN` after an operand and returns "NOT IN" etc., or nil
    # (consuming nothing) when the next tokens are not one of these.
    def membership_keyword
      offset = peek.keyword?("NOT") ? 1 : 0
      word = peek_at(offset)
      return nil unless word.keyword?("IN") || word.keyword?("LIKE") || word.keyword?("BETWEEN")
      advance if offset == 1
      advance
      offset == 1 ? "NOT #{word.text}" : word.text
    end

    def parse_membership(word, left)
      negated = word.start_with?("NOT ")
      case word.delete_prefix("NOT ")
      when "IN" then InList.new(negated, left, parse_in_items)
      when "LIKE" then Like.new(negated, left, parse_comparison)
      else
        low = parse_comparison
        expect_keyword("AND")
        Between.new(negated, left, low, parse_comparison)
      end
    end

    def parse_in_items
      expect_symbol("(")
      items = [] # @type var items: Array[Expr]
      unless accept_symbol(")")
        items << parse_expr
        items << parse_expr while accept_symbol(",")
        expect_symbol(")")
      end
      items
    end

    def parse_comparison
      left = parse_additive
      while peek.kind == :symbol && COMPARISON_OPS.include?(peek.text)
        op = advance.text
        left = Binary.new(op, left, parse_additive)
      end
      left
    end

    def parse_additive
      left = parse_multiplicative
      while peek.symbol?("+") || peek.symbol?("-")
        op = advance.text
        left = Binary.new(op, left, parse_multiplicative)
      end
      left
    end

    def parse_multiplicative
      left = parse_concat
      while peek.symbol?("*") || peek.symbol?("/") || peek.symbol?("%")
        op = advance.text
        left = Binary.new(op, left, parse_concat)
      end
      left
    end

    def parse_concat
      left = parse_unary
      left = Binary.new("||", left, parse_unary) while accept_symbol("||")
      left
    end

    def parse_unary
      return Unary.new("-", parse_unary) if accept_symbol("-")
      return Unary.new("+", parse_unary) if accept_symbol("+")
      parse_primary
    end

    def parse_primary
      token = peek
      case token.kind
      when :number
        advance
        Literal.new(Value.number_from(token.text))
      when :string
        advance
        Literal.new(token.text)
      when :keyword
        advance
        case token.text
        when "NULL" then Literal.new(nil)
        when "CASE" then parse_case
        when "CAST" then parse_cast
        else syntax_error
        end
      when :ident
        advance
        parse_name_or_call(token.text, @pos - 1)
      when :symbol
        syntax_error unless token.text == "("
        advance
        inner = parse_expr
        expect_symbol(")")
        inner
      else
        syntax_error
      end
    end

    # CASE [operand] WHEN cond THEN result ... [ELSE expr] END; CASE has been consumed.
    def parse_case
      operand = peek.keyword?("WHEN") ? nil : parse_expr
      whens = [] # @type var whens: Array[WhenClause]
      while accept_keyword("WHEN")
        condition = parse_expr
        expect_keyword("THEN")
        whens << WhenClause.new(condition, parse_expr)
      end
      syntax_error if whens.empty?
      else_expr = accept_keyword("ELSE") ? parse_expr : nil
      expect_keyword("END")
      Case.new(operand, whens, else_expr)
    end

    # CAST ( expr AS type ); CAST has been consumed.
    def parse_cast
      expect_symbol("(")
      operand = parse_expr
      expect_keyword("AS")
      type = peek.kind == :ident ? type_named(peek.text.upcase(:ascii)) : nil
      syntax_error unless type
      advance
      expect_symbol(")")
      Cast.new(operand, type)
    end

    # A name after its token (at index `start`) has been consumed: a column or a call.
    def parse_name_or_call(name, start)
      if accept_symbol("(")
        parse_call(name, start)
      elsif accept_symbol(".")
        ColumnRef.new(name, expect_ident)
      else
        ColumnRef.new(nil, name)
      end
    end

    # The rest of `name ( * )` or `name ( [DISTINCT] args [ORDER BY terms] )`; the `(` has been consumed.
    def parse_call(name, start)
      args = [] # @type var args: Array[Expr]
      order_by = [] # @type var order_by: Array[OrderTerm]
      star = accept_symbol("*")
      distinct = false
      if star
        expect_symbol(")")
      elsif !accept_symbol(")")
        distinct = accept_keyword("DISTINCT")
        args << parse_expr
        args << parse_expr while accept_symbol(",")
        order_by = parse_order_by
        expect_symbol(")")
      end
      Call.new(name, args, star, distinct, order_by, signature_since(start))
    end

    # The tokens from `start` on as one string (names case-insensitive), to compare calls by what was written.
    def signature_since(start)
      tokens = @tokens[start...@pos] || []
      tokens.map { |token| token.kind == :string ? "'#{token.text}'" : token.text.downcase(:ascii) }.join(" ")
    end
  end
end
