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
        elsif accept_keyword("INSERT") then parse_insert(nil)
        elsif peek.keyword?("SELECT") then parse_select_body
        elsif peek.keyword?("WITH") then parse_with_statement
        elsif accept_keyword("UPDATE") then parse_update
        elsif accept_keyword("DELETE") then parse_delete
        elsif accept_keyword("ALTER") then parse_alter
        elsif accept_keyword("BEGIN") then parse_transaction(:begin)
        elsif accept_keyword("COMMIT") || accept_keyword("END") then parse_transaction(:commit)
        elsif accept_keyword("ROLLBACK") then parse_transaction(:rollback)
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

    # `IF NOT EXISTS`, if present.
    def accept_if_not_exists
      return false unless accept_keyword("IF")
      expect_keyword("NOT")
      expect_keyword("EXISTS")
      true
    end

    # `IF EXISTS`, if present.
    def accept_if_exists
      return false unless accept_keyword("IF")
      expect_keyword("EXISTS")
      true
    end

    # `( name, name, ... )`
    def parse_name_list
      expect_symbol("(")
      names = [expect_ident]
      names << expect_ident while accept_symbol(",")
      expect_symbol(")")
      names
    end

    # CREATE TABLE ... | CREATE VIEW ... | CREATE [UNIQUE] INDEX ...; CREATE has been consumed.
    def parse_create
      unique = accept_keyword("UNIQUE")
      return parse_create_index(unique) if accept_keyword("INDEX")
      syntax_error if unique
      return parse_create_view if accept_keyword("VIEW")
      expect_keyword("TABLE")
      parse_create_table
    end

    # [IF NOT EXISTS] name ( column-def, ... ); TABLE has been consumed.
    def parse_create_table
      if_not_exists = accept_if_not_exists
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

    # [IF NOT EXISTS] name [( column, ... )] AS select; VIEW has been consumed.
    def parse_create_view
      if_not_exists = accept_if_not_exists
      name = expect_ident
      columns = peek.symbol?("(") ? parse_name_list : nil
      expect_keyword("AS")
      CreateView.new(name, columns, parse_query, if_not_exists)
    end

    # [IF NOT EXISTS] name ON table ( column, ... ); INDEX has been consumed.
    def parse_create_index(unique)
      if_not_exists = accept_if_not_exists
      name = expect_ident
      expect_keyword("ON")
      table = expect_ident
      CreateIndex.new(name, table, parse_name_list, unique, if_not_exists)
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

    # [+ | -] numeric-literal | string-literal | blob-literal | NULL
    def parse_default_value
      token = peek
      case token.kind
      when :string
        advance
        token.text
      when :blob
        advance
        Blob.from_hex(token.text)
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
      TableConstraint.new(kind, parse_name_list)
    end

    def type_named(word)
      case word
      when "INTEGER" then :integer
      when "REAL" then :real
      when "TEXT" then :text
      when "BLOB" then :blob
      end
    end

    # DROP TABLE | VIEW | INDEX [IF EXISTS] name; DROP has been consumed.
    def parse_drop
      if accept_keyword("VIEW")
        if_exists = accept_if_exists
        DropView.new(expect_ident, if_exists)
      elsif accept_keyword("INDEX")
        if_exists = accept_if_exists
        DropIndex.new(expect_ident, if_exists)
      else
        expect_keyword("TABLE")
        if_exists = accept_if_exists
        DropTable.new(expect_ident, if_exists)
      end
    end

    # ALTER TABLE table ADD [COLUMN] def | RENAME TO name | RENAME [COLUMN] column TO name; ALTER has been consumed.
    def parse_alter
      expect_keyword("TABLE")
      table = expect_ident
      if accept_keyword("ADD")
        accept_keyword("COLUMN")
        AddColumn.new(table, parse_column_def)
      else
        expect_keyword("RENAME")
        return RenameTable.new(table, expect_ident) if accept_keyword("TO")
        accept_keyword("COLUMN")
        column = expect_ident
        expect_keyword("TO")
        RenameColumn.new(table, column, expect_ident)
      end
    end

    # BEGIN | COMMIT | END | ROLLBACK [TRANSACTION]; the first word has been consumed.
    def parse_transaction(kind)
      accept_keyword("TRANSACTION")
      TransactionStatement.new(kind)
    end

    # INSERT INTO table [(column, ...)] VALUES (expr, ...), ... | select; INSERT has been consumed.
    def parse_insert(with)
      expect_keyword("INTO")
      table = expect_ident
      columns = peek.symbol?("(") ? parse_name_list : nil
      if accept_keyword("VALUES")
        rows = [parse_value_row]
        rows << parse_value_row while accept_symbol(",")
        Insert.new(table, columns, ValuesList.new(rows), with)
      else
        Insert.new(table, columns, parse_query, with)
      end
    end

    # WITH ... followed by a select or an INSERT.
    def parse_with_statement
      with = parse_with_clause
      return parse_insert(with) if accept_keyword("INSERT")
      WithSelect.new(with, parse_select_body)
    end

    # WITH [RECURSIVE] name [(column, ...)] AS ( select ), ...
    def parse_with_clause
      expect_keyword("WITH")
      recursive = accept_keyword("RECURSIVE")
      tables = [parse_common_table]
      tables << parse_common_table while accept_symbol(",")
      WithClause.new(recursive, tables)
    end

    def parse_common_table
      name = expect_ident
      columns = peek.symbol?("(") ? parse_name_list : nil
      expect_keyword("AS")
      CommonTable.new(name, columns, parse_parenthesized_select)
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

    # A select with its optional WITH: `[WITH ...] simple-select [compound-op simple-select]... [ORDER BY ...] [LIMIT ...]`.
    def parse_query
      return WithSelect.new(parse_with_clause, parse_select_body) if peek.keyword?("WITH")
      parse_select_body
    end

    # simple-select [compound-op simple-select]... [ORDER BY ...] [LIMIT expr [OFFSET expr]]
    def parse_select_body
      first = parse_select_core
      arms = [] # @type var arms: Array[CompoundArm]
      while (op = accept_compound_operator)
        arms << CompoundArm.new(op, parse_select_core)
      end
      order_by = parse_order_by
      limit = nil # @type var limit: Expr?
      offset = nil # @type var offset: Expr?
      if accept_keyword("LIMIT")
        limit = parse_expr
        offset = parse_expr if accept_keyword("OFFSET")
      end
      return first.with_tail(order_by, limit, offset) if arms.empty?
      CompoundSelect.new(first, arms, order_by, limit, offset)
    end

    # Consumes UNION [ALL], INTERSECT or EXCEPT and returns it ("UNION ALL" for the first with ALL); nil
    # (consuming nothing) when the next token is none of them.
    def accept_compound_operator
      if accept_keyword("UNION")
        accept_keyword("ALL") ? "UNION ALL" : "UNION"
      elsif accept_keyword("INTERSECT")
        "INTERSECT"
      elsif accept_keyword("EXCEPT")
        "EXCEPT"
      end
    end

    # SELECT [DISTINCT | ALL] result-column, ... [FROM ...] [WHERE expr] [GROUP BY expr, ... [HAVING expr]]
    def parse_select_core
      expect_keyword("SELECT")
      distinct = accept_keyword("DISTINCT")
      accept_keyword("ALL") unless distinct
      columns = [parse_result_column]
      columns << parse_result_column while accept_symbol(",")
      from = accept_keyword("FROM") ? parse_from : nil
      where = accept_keyword("WHERE") ? parse_expr : nil
      group_by = [] # @type var group_by: Array[Expr]
      if accept_keyword("GROUP")
        expect_keyword("BY")
        group_by << parse_expr
        group_by << parse_expr while accept_symbol(",")
      end
      having = accept_keyword("HAVING") ? parse_expr : nil
      no_windows = [] # @type var no_windows: Array[NamedWindow]
      windows = accept_keyword("WINDOW") ? parse_named_windows : no_windows
      no_order = [] # @type var no_order: Array[OrderTerm]
      Select.new(distinct, columns, from, where, group_by, having, windows, no_order, nil, nil)
    end

    # name AS ( window-spec ) [, ...]; WINDOW has been consumed.
    def parse_named_windows
      windows = [] # @type var windows: Array[NamedWindow]
      loop do
        name = expect_ident
        expect_keyword("AS")
        windows << NamedWindow.new(name, parse_window_spec)
        break unless accept_symbol(",")
      end
      windows
    end

    # `( [base] [PARTITION BY expr, ...] [ORDER BY term, ...] [frame] )`
    def parse_window_spec
      expect_symbol("(")
      base = peek.kind == :ident ? advance.text : nil
      partition_by = [] # @type var partition_by: Array[Expr]
      if accept_keyword("PARTITION")
        expect_keyword("BY")
        partition_by << parse_expr
        partition_by << parse_expr while accept_symbol(",")
      end
      order_by = parse_order_by
      frame = peek.keyword?("ROWS") || peek.keyword?("RANGE") ? parse_frame : nil
      expect_symbol(")")
      WindowSpec.new(base, partition_by, order_by, frame)
    end

    # (ROWS | RANGE) bound | (ROWS | RANGE) BETWEEN bound AND bound; a lone bound ends at CURRENT ROW.
    def parse_frame
      mode = advance.text == "ROWS" ? :rows : :range
      return FrameSpec.new(mode, parse_frame_bound, FrameBound.new(:current, nil)) unless accept_keyword("BETWEEN")
      start = parse_frame_bound
      expect_keyword("AND")
      FrameSpec.new(mode, start, parse_frame_bound)
    end

    def parse_frame_bound
      if accept_keyword("UNBOUNDED")
        return FrameBound.new(:unbounded_preceding, nil) if accept_keyword("PRECEDING")
        expect_keyword("FOLLOWING")
        return FrameBound.new(:unbounded_following, nil)
      end
      if accept_keyword("CURRENT")
        expect_keyword("ROW")
        return FrameBound.new(:current, nil)
      end
      negative = accept_symbol("-")
      syntax_error unless peek.kind == :number
      offset = Value.number_from(advance.text)
      offset = -offset if negative
      return FrameBound.new(:preceding, offset) if accept_keyword("PRECEDING")
      expect_keyword("FOLLOWING")
      FrameBound.new(:following, offset)
    end

    # `OVER window-name` or `OVER ( window-spec )`; OVER has been consumed.
    def parse_over
      return parse_window_spec if peek.symbol?("(")
      WindowSpec.new(expect_ident, [], [], nil)
    end

    # from-item [join-op from-item [join-constraint]]...
    def parse_from
      first = parse_from_item
      joins = [] # @type var joins: Array[JoinClause]
      while (kind = accept_join_operator)
        item = parse_from_item
        on = nil # @type var on: Expr?
        using = nil # @type var using: Array[String]?
        if accept_keyword("ON")
          on = parse_expr
        elsif accept_keyword("USING")
          using = parse_name_list
        end
        joins << JoinClause.new(kind, item, on, using)
      end
      FromClause.new(first, joins)
    end

    # Consumes `,`, `[INNER] JOIN`, `CROSS JOIN` or `LEFT [OUTER] JOIN` and returns :inner or :left; nil (consuming
    # nothing) when the next tokens are none of these.
    def accept_join_operator
      return :inner if accept_symbol(",")
      if accept_keyword("LEFT")
        accept_keyword("OUTER")
        expect_keyword("JOIN")
        :left
      elsif accept_keyword("CROSS") || accept_keyword("INNER")
        expect_keyword("JOIN")
        :inner
      elsif accept_keyword("JOIN")
        :inner
      end
    end

    # table [[AS] alias] | ( select ) [[AS] alias]
    def parse_from_item
      if peek.symbol?("(")
        select = parse_parenthesized_select
        SubqueryRef.new(select, parse_alias)
      else
        TableRef.new(expect_ident, parse_alias)
      end
    end

    # [AS] alias, or nil.
    def parse_alias
      return expect_ident if accept_keyword("AS")
      peek.kind == :ident ? advance.text : nil
    end

    # `( select )`
    def parse_parenthesized_select
      expect_symbol("(")
      select = parse_query
      expect_symbol(")")
      select
    end

    # Whether the token after the current `(` starts a select.
    def subquery_ahead?
      peek_at(1).keyword?("SELECT") || peek_at(1).keyword?("WITH")
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
      return ResultColumn.new(nil, nil, nil) if accept_symbol("*")
      if peek.kind == :ident && peek_at(1).symbol?(".") && peek_at(2).symbol?("*")
        qualifier = advance.text
        2.times { advance }
        return ResultColumn.new(nil, nil, qualifier)
      end
      ResultColumn.new(parse_expr, parse_alias, nil)
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
      when "IN"
        if peek.symbol?("(") && subquery_ahead?
          InSelect.new(negated, left, parse_parenthesized_select)
        else
          InList.new(negated, left, parse_in_items)
        end
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
      when :blob
        advance
        Literal.new(Blob.from_hex(token.text))
      when :keyword
        advance
        case token.text
        when "NULL" then Literal.new(nil)
        when "CASE" then parse_case
        when "CAST" then parse_cast
        when "EXISTS" then ExistsSelect.new(parse_parenthesized_select)
        else syntax_error
        end
      when :ident
        advance
        parse_name_or_call(token.text, @pos - 1)
      when :symbol
        syntax_error unless token.text == "("
        return ScalarSelect.new(parse_parenthesized_select) if subquery_ahead?
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
      signature = signature_since(start)
      Call.new(name, args, star, distinct, order_by, signature, accept_keyword("OVER") ? parse_over : nil)
    end

    # The tokens from `start` on as one string (names case-insensitive), to compare calls by what was written.
    def signature_since(start)
      tokens = @tokens[start...@pos] || []
      tokens.map { |token| signature_of(token) }.join(" ")
    end

    def signature_of(token)
      case token.kind
      when :string then "'#{token.text}'"
      when :blob then "x'#{token.text.downcase(:ascii)}'"
      else token.text.downcase(:ascii)
      end
    end
  end
end
