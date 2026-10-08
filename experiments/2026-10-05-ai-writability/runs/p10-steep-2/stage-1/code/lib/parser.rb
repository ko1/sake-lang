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
      columns << parse_column_def while accept_symbol(",")
      expect_symbol(")")
      CreateTable.new(name, columns, if_not_exists)
    end

    def parse_column_def
      name = expect_ident
      type = peek.kind == :ident ? type_named(peek.text.upcase(:ascii)) : nil
      syntax_error unless type
      advance
      ColumnDef.new(name, type)
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

    # SELECT result-column, ... [FROM table] [WHERE expr] [ORDER BY ...] [LIMIT expr [OFFSET expr]]
    def parse_select
      columns = [parse_result_column]
      columns << parse_result_column while accept_symbol(",")
      from = accept_keyword("FROM") ? expect_ident : nil
      where = accept_keyword("WHERE") ? parse_expr : nil
      order_by = [] # @type var order_by: Array[OrderTerm]
      if accept_keyword("ORDER")
        expect_keyword("BY")
        order_by << parse_order_term
        order_by << parse_order_term while accept_symbol(",")
      end
      limit = nil # @type var limit: Expr?
      offset = nil # @type var offset: Expr?
      if accept_keyword("LIMIT")
        limit = parse_expr
        offset = parse_expr if accept_keyword("OFFSET")
      end
      Select.new(columns, from, where, order_by, limit, offset)
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
        else
          return left
        end
      end
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
        syntax_error unless token.text == "NULL"
        advance
        Literal.new(nil)
      when :ident
        advance
        parse_name_or_call(token.text)
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

    def parse_name_or_call(name)
      if accept_symbol("(")
        args = [] # @type var args: Array[Expr]
        unless accept_symbol(")")
          args << parse_expr
          args << parse_expr while accept_symbol(",")
          expect_symbol(")")
        end
        Call.new(name, args)
      elsif accept_symbol(".")
        ColumnRef.new(name, expect_ident)
      else
        ColumnRef.new(nil, name)
      end
    end
  end
end
