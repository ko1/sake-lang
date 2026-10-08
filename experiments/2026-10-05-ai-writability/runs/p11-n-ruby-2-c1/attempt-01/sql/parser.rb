# frozen_string_literal: true

require_relative 'ast'
require_relative 'errors'
require_relative 'lexer'

module SQL
  # Recursive-descent parser: tokens of one statement -> statement AST (SPEC 1.4-1.8, 2.1-2.3).
  class Parser
    TYPES = { 'INTEGER' => :integer, 'REAL' => :real, 'TEXT' => :text }.freeze

    BINARY_LEVELS = [
      { '=' => :eq, '==' => :eq, '!=' => :ne, '<>' => :ne },
      { '<' => :lt, '<=' => :le, '>' => :gt, '>=' => :ge },
      { '+' => :add, '-' => :sub },
      { '*' => :mul, '/' => :div, '%' => :mod },
      { '||' => :concat }
    ].freeze

    # Returns nil for an empty statement.
    def self.parse(tokens) = new(tokens).parse_statement

    def initialize(tokens)
      @tokens = tokens
      @pos = 0
    end

    def parse_statement
      return nil if @tokens.empty?

      stmt =
        case keyword
        when 'SELECT' then parse_query
        when 'WITH' then parse_with(allow_insert: true)
        when 'INSERT' then parse_insert
        when 'CREATE' then parse_create
        when 'DROP' then parse_drop
        when 'ALTER' then parse_alter
        when 'UPDATE' then parse_update
        when 'DELETE' then parse_delete
        when 'BEGIN', 'COMMIT', 'END', 'ROLLBACK' then parse_transaction
        else raise SqlError.syntax
        end
      raise SqlError.syntax unless eof?

      stmt
    end

    private

    # --- token helpers ------------------------------------------------------------------

    def eof? = @pos >= @tokens.size
    def peek(offset = 0) = @tokens[@pos + offset]

    def keyword
      t = peek
      t && t.type == :kw ? t.value : nil
    end

    def accept_kw(name)
      return false unless keyword == name

      @pos += 1
      true
    end

    def expect_kw(name) = accept_kw(name) || raise(SqlError.syntax)

    def op?(value, offset = 0)
      t = peek(offset)
      !t.nil? && t.type == :op && t.value == value
    end

    def accept_op(value)
      return false unless op?(value)

      @pos += 1
      true
    end

    def expect_op(value) = accept_op(value) || raise(SqlError.syntax)

    def expect_ident
      t = peek
      raise SqlError.syntax unless t && t.type == :id

      @pos += 1
      t.value
    end

    # --- CREATE / DROP ------------------------------------------------------------------

    def parse_create
      expect_kw('CREATE')
      unique = accept_kw('UNIQUE')
      return parse_create_index(unique) if keyword == 'INDEX'
      raise SqlError.syntax if unique

      case keyword
      when 'TABLE' then parse_create_table
      when 'VIEW' then parse_create_view
      else raise SqlError.syntax
      end
    end

    def accept_if_not_exists
      return false unless accept_kw('IF')

      expect_kw('NOT')
      expect_kw('EXISTS')
      true
    end

    def accept_if_exists
      return false unless accept_kw('IF')

      expect_kw('EXISTS')
      true
    end

    def parse_create_table
      expect_kw('TABLE')
      if_not_exists = accept_if_not_exists
      name = expect_ident
      expect_op('(')
      columns = []
      constraints = []
      loop do
        if %w[PRIMARY UNIQUE].include?(keyword)
          raise SqlError.syntax if columns.empty?

          constraints << parse_table_constraint
        else
          raise SqlError.syntax unless constraints.empty? # column definitions come first

          columns << parse_column_def
        end
        break unless accept_op(',')
      end
      expect_op(')')
      CreateTable.new(name, columns, constraints, if_not_exists)
    end

    def parse_create_view
      expect_kw('VIEW')
      if_not_exists = accept_if_not_exists
      name = expect_ident
      columns = accept_op('(') ? parse_name_list_rest : nil
      expect_kw('AS')
      CreateView.new(name, columns, parse_query, if_not_exists)
    end

    def parse_create_index(unique)
      expect_kw('INDEX')
      if_not_exists = accept_if_not_exists
      name = expect_ident
      expect_kw('ON')
      table = expect_ident
      expect_op('(')
      columns, collations = parse_index_columns
      CreateIndex.new(name, table, columns, collations, unique, if_not_exists)
    end

    # After `(`: `column [COLLATE name]` separated by commas, and the closing `)`. [names, collation names].
    def parse_index_columns
      names = []
      collations = []
      loop do
        names << expect_ident
        collations << (accept_kw('COLLATE') ? expect_ident : nil)
        break unless accept_op(',')
      end
      expect_op(')')
      [names, collations]
    end

    # After `(`: names separated by commas, and the closing `)`.
    def parse_name_list_rest
      names = [expect_ident]
      names << expect_ident while accept_op(',')
      expect_op(')')
      names
    end

    def parse_column_def
      name = expect_ident
      t = peek
      type = t && t.type == :id ? TYPES[t.value.upcase] : nil
      raise SqlError.syntax unless type

      @pos += 1
      flags = { not_null: false, primary_key: false, unique: false, default: nil, collation: nil }
      loop do
        if accept_kw('PRIMARY') then expect_kw('KEY'); flags[:primary_key] = true
        elsif accept_kw('NOT') then expect_kw('NULL'); flags[:not_null] = true
        elsif accept_kw('UNIQUE') then flags[:unique] = true
        elsif accept_kw('DEFAULT') then flags[:default] = parse_default_value
        elsif accept_kw('COLLATE') then flags[:collation] = expect_ident
        else break
        end
      end
      ColumnDef.new(name:, type:, **flags)
    end

    # [+ | -] numeric-literal | string-literal | NULL, as a Ruby value.
    def parse_default_value
      sign = accept_op('-') ? -1 : (accept_op('+') ? 1 : nil)
      t = peek
      raise SqlError.syntax unless t

      if %i[int real].include?(t.type)
        @pos += 1
        sign == -1 ? -t.value : t.value
      elsif sign.nil? && t.type == :str
        @pos += 1
        t.value
      elsif sign.nil? && t.type == :kw && t.value == 'NULL'
        @pos += 1
        nil
      else
        raise SqlError.syntax
      end
    end

    def parse_table_constraint
      kind = accept_kw('PRIMARY') ? (expect_kw('KEY') && :primary_key) : (expect_kw('UNIQUE') && :unique)
      expect_op('(')
      columns = [expect_ident]
      columns << expect_ident while accept_op(',')
      expect_op(')')
      TableConstraint.new(kind, columns)
    end

    def parse_drop
      expect_kw('DROP')
      kind = keyword
      raise SqlError.syntax unless %w[TABLE VIEW INDEX].include?(kind)

      @pos += 1
      if_exists = accept_if_exists
      name = expect_ident
      case kind
      when 'TABLE' then DropTable.new(name, if_exists)
      when 'VIEW' then DropView.new(name, if_exists)
      else DropIndex.new(name, if_exists)
      end
    end

    # --- ALTER TABLE / transactions -----------------------------------------------------

    def parse_alter
      expect_kw('ALTER')
      expect_kw('TABLE')
      table = expect_ident
      if accept_kw('ADD')
        accept_kw('COLUMN')
        AddColumn.new(table, parse_column_def)
      else
        expect_kw('RENAME')
        return RenameTable.new(table, expect_ident) if accept_kw('TO')

        accept_kw('COLUMN')
        column = expect_ident
        expect_kw('TO')
        RenameColumn.new(table, column, expect_ident)
      end
    end

    def parse_transaction
      kind = keyword
      @pos += 1
      accept_kw('TRANSACTION')
      { 'BEGIN' => Begin, 'COMMIT' => Commit, 'END' => Commit, 'ROLLBACK' => Rollback }.fetch(kind).new
    end

    # --- INSERT -------------------------------------------------------------------------

    def parse_insert
      expect_kw('INSERT')
      expect_kw('INTO')
      table = expect_ident
      columns = nil
      if accept_op('(')
        columns = [expect_ident]
        columns << expect_ident while accept_op(',')
        expect_op(')')
      end
      return Insert.new(table, columns, nil, parse_query) if %w[SELECT WITH].include?(keyword)

      expect_kw('VALUES')
      rows = [parse_value_row]
      rows << parse_value_row while accept_op(',')
      Insert.new(table, columns, rows, nil)
    end

    def parse_value_row
      expect_op('(')
      row = [parse_expr]
      row << parse_expr while accept_op(',')
      expect_op(')')
      row
    end

    # --- UPDATE / DELETE ----------------------------------------------------------------

    def parse_update
      expect_kw('UPDATE')
      table = expect_ident
      expect_kw('SET')
      assignments = [parse_assignment]
      assignments << parse_assignment while accept_op(',')
      Update.new(table, assignments, accept_kw('WHERE') ? parse_expr : nil)
    end

    def parse_assignment
      column = expect_ident
      expect_op('=')
      [column, parse_expr]
    end

    def parse_delete
      expect_kw('DELETE')
      expect_kw('FROM')
      table = expect_ident
      Delete.new(table, accept_kw('WHERE') ? parse_expr : nil)
    end

    # --- SELECT -------------------------------------------------------------------------

    # A query: [WITH ...] simple-select [compound-op simple-select]... [ORDER BY ...] [LIMIT ...] (5.1, 5.2).
    def parse_query = keyword == 'WITH' ? parse_with(allow_insert: false) : parse_compound

    def parse_compound
      query = parse_select
      while (op = parse_compound_operator)
        query = Compound.new(op, query, parse_select, [], nil, nil)
      end
      order_by = parse_order_by
      limit = offset = nil
      if accept_kw('LIMIT')
        limit = parse_expr
        offset = parse_expr if accept_kw('OFFSET')
      end
      query.with(order_by:, limit:, offset:)
    end

    def parse_compound_operator
      if accept_kw('UNION') then accept_kw('ALL') ? :union_all : :union
      elsif accept_kw('INTERSECT') then :intersect
      elsif accept_kw('EXCEPT') then :except
      end
    end

    def parse_with(allow_insert:)
      expect_kw('WITH')
      recursive = accept_kw('RECURSIVE')
      ctes = [parse_cte]
      ctes << parse_cte while accept_op(',')
      body = allow_insert && keyword == 'INSERT' ? parse_insert : parse_compound
      WithClause.new(recursive, ctes, body)
    end

    def parse_cte
      name = expect_ident
      columns = accept_op('(') ? parse_name_list_rest : nil
      expect_kw('AS')
      expect_op('(')
      query = parse_query
      expect_op(')')
      Cte.new(name, columns, query)
    end

    # A simple select: no ORDER BY / LIMIT (they belong to the whole query).
    def parse_select
      expect_kw('SELECT')
      distinct = accept_kw('DISTINCT')
      accept_kw('ALL') unless distinct
      items = [parse_result_column]
      items << parse_result_column while accept_op(',')
      from = accept_kw('FROM') ? parse_from : nil
      where = accept_kw('WHERE') ? parse_expr : nil
      group_by = []
      if accept_kw('GROUP')
        expect_kw('BY')
        group_by << parse_expr
        group_by << parse_expr while accept_op(',')
      end
      having = accept_kw('HAVING') ? parse_expr : nil
      windows = accept_kw('WINDOW') ? parse_window_definitions : []
      Select.new(distinct:, items:, from:, where:, group_by:, having:, windows:, order_by: [], limit: nil, offset: nil)
    end

    # --- windows (6.1) ------------------------------------------------------------------

    # After WINDOW: `name AS (spec) [, ...]`, as [[name, WindowSpec]].
    def parse_window_definitions
      defs = []
      loop do
        name = expect_ident
        expect_kw('AS')
        expect_op('(')
        defs << [name, parse_window_spec]
        break unless accept_op(',')
      end
      defs
    end

    # After OVER: a window name, or `(spec)`.
    def parse_window_reference
      return expect_ident unless accept_op('(')

      parse_window_spec
    end

    # After `(`: [base] [PARTITION BY ...] [ORDER BY ...] [frame], and the closing `)`.
    def parse_window_spec
      base = peek&.type == :id ? expect_ident : nil
      partition_by = []
      if accept_kw('PARTITION')
        expect_kw('BY')
        partition_by << parse_expr
        partition_by << parse_expr while accept_op(',')
      end
      order_by = parse_order_by
      frame = parse_window_frame
      expect_op(')')
      WindowSpec.new(base, partition_by, order_by, frame)
    end

    def parse_window_frame
      unit = accept_kw('ROWS') ? :rows : (accept_kw('RANGE') ? :range : nil)
      return nil unless unit

      if accept_kw('BETWEEN')
        start = parse_frame_bound
        expect_kw('AND')
        WindowFrame.new(unit, start, parse_frame_bound)
      else
        WindowFrame.new(unit, parse_frame_bound, FrameBound.new(:current, nil))
      end
    end

    def parse_frame_bound
      if accept_kw('UNBOUNDED')
        FrameBound.new(accept_kw('PRECEDING') ? :unbounded_preceding : (expect_kw('FOLLOWING') && :unbounded_following), nil)
      elsif accept_kw('CURRENT')
        expect_kw('ROW')
        FrameBound.new(:current, nil)
      else
        offset = parse_frame_offset
        FrameBound.new(accept_kw('PRECEDING') ? :preceding : (expect_kw('FOLLOWING') && :following), offset)
      end
    end

    # An integer literal, with an optional `-`; a REAL is kept for the frame checks to refuse.
    def parse_frame_offset
      negative = accept_op('-')
      t = peek
      raise SqlError.syntax unless t && %i[int real].include?(t.type)

      @pos += 1
      negative ? -t.value : t.value
    end

    # from-item [join-op from-item [constraint]]..., as a left-leaning tree of Joins (4.1).
    def parse_from
      tree = parse_from_item
      while (kind = parse_join_operator)
        right = parse_from_item
        on, using = parse_join_constraint(kind)
        tree = Join.new(tree, right, kind, on, using)
      end
      tree
    end

    def parse_from_item
      if accept_op('(')
        select = parse_query
        expect_op(')')
        SubquerySource.new(select, parse_optional_alias)
      else
        name = expect_ident
        TableSource.new(name, parse_optional_alias)
      end
    end

    def parse_optional_alias
      return expect_ident if accept_kw('AS')

      peek&.type == :id ? expect_ident : nil
    end

    # :cross, :inner or :left; nil when no join operator follows.
    def parse_join_operator
      if accept_op(',') then :cross
      elsif accept_kw('CROSS') then expect_kw('JOIN') && :cross
      elsif accept_kw('INNER') then expect_kw('JOIN') && :inner
      elsif accept_kw('LEFT')
        accept_kw('OUTER')
        expect_kw('JOIN') && :left
      elsif accept_kw('JOIN') then :inner
      end
    end

    # [on, using]: ON expr, or USING (names); a LEFT JOIN must have one, `,` and CROSS JOIN take none.
    def parse_join_constraint(kind)
      return [nil, nil] if kind == :cross

      if accept_kw('ON')
        [parse_expr, nil]
      elsif accept_kw('USING')
        expect_op('(')
        names = [expect_ident]
        names << expect_ident while accept_op(',')
        expect_op(')')
        [nil, names]
      elsif kind == :left
        raise SqlError.syntax
      else
        [nil, nil]
      end
    end

    # [ORDER BY term, ...] as an array (empty when absent).
    def parse_order_by
      return [] unless accept_kw('ORDER')

      expect_kw('BY')
      terms = [parse_order_term]
      terms << parse_order_term while accept_op(',')
      terms
    end

    def parse_result_column
      return Star.new if accept_op('*')

      if peek&.type == :id && op?('.', 1) && op?('*', 2)
        table = expect_ident
        @pos += 2
        return Star.new(table:)
      end

      expr = parse_expr
      if accept_kw('AS')
        ResultColumn.new(expr, expect_ident)
      elsif peek&.type == :id
        ResultColumn.new(expr, expect_ident)
      else
        ResultColumn.new(expr, nil)
      end
    end

    def parse_order_term
      expr = parse_expr
      desc = false
      if accept_kw('ASC')
        desc = false
      elsif accept_kw('DESC')
        desc = true
      end
      nulls = nil
      if accept_kw('NULLS')
        nulls = accept_kw('FIRST') ? :first : (expect_kw('LAST') && :last)
      end
      OrderTerm.new(expr, desc, nulls)
    end

    # --- expressions --------------------------------------------------------------------
    # Loosest to tightest: OR, AND, NOT, equality/IS, relational, additive, multiplicative,
    # ||, unary, postfix COLLATE, primary.

    def parse_expr = parse_or

    def parse_or
      left = parse_and
      left = Binary.new(:or, left, parse_and) while accept_kw('OR')
      left
    end

    def parse_and
      left = parse_not
      left = Binary.new(:and, left, parse_not) while accept_kw('AND')
      left
    end

    def parse_not
      accept_kw('NOT') ? Unary.new(:not, parse_not) : parse_equality
    end

    def parse_equality
      left = parse_binary(1)
      loop do
        if (op = binary_op(0))
          @pos += 1
          left = Binary.new(op, left, parse_binary(1))
        elsif accept_kw('IS')
          op = accept_kw('NOT') ? :is_not : :is
          left = Binary.new(op, left, parse_binary(1))
        elsif (node = parse_predicate(left))
          left = node
        else
          return left
        end
      end
    end

    # `[NOT] IN (...)`, `[NOT] LIKE p`, `[NOT] BETWEEN a AND b` after `left`, or nil if none follows.
    def parse_predicate(left)
      negated = keyword == 'NOT' && %w[IN LIKE BETWEEN].include?(peek(1)&.value) && peek(1).type == :kw
      @pos += 1 if negated
      if accept_kw('IN')
        expect_op('(')
        if query_start?
          select = parse_query
          expect_op(')')
          return InSelect.new(left, select, negated)
        end
        items = [parse_expr]
        items << parse_expr while accept_op(',')
        expect_op(')')
        InList.new(left, items, negated)
      elsif accept_kw('LIKE')
        Like.new(left, parse_binary(1), negated)
      elsif accept_kw('BETWEEN')
        low = parse_binary(1) # the AND below belongs to BETWEEN
        expect_kw('AND')
        Between.new(left, low, parse_binary(1), negated)
      end
    end

    # Left-associative binary operators of BINARY_LEVELS[level], tighter levels below.
    def parse_binary(level)
      return parse_unary if level >= BINARY_LEVELS.size

      left = parse_binary(level + 1)
      while (op = binary_op(level))
        @pos += 1
        left = Binary.new(op, left, parse_binary(level + 1))
      end
      left
    end

    def binary_op(level)
      t = peek
      t && t.type == :op ? BINARY_LEVELS[level][t.value] : nil
    end

    def parse_unary
      if accept_op('-') then Unary.new(:neg, parse_unary)
      elsif accept_op('+') then Unary.new(:pos, parse_unary)
      else parse_postfix
      end
    end

    # A primary followed by any `COLLATE name`; it binds tighter than every binary operator (7.2).
    def parse_postfix
      expr = parse_primary
      expr = Collate.new(expr, expect_ident) while accept_kw('COLLATE')
      expr
    end

    def parse_primary
      t = peek
      raise SqlError.syntax unless t

      case t.type
      when :int, :real, :str
        @pos += 1
        Literal.new(t.value)
      when :kw
        parse_keyword_primary(t.value)
      when :id
        parse_name
      when :op
        raise SqlError.syntax unless t.value == '('

        @pos += 1
        return parse_subquery_rest if query_start?

        expr = parse_expr
        expect_op(')')
        expr
      end
    end

    def parse_keyword_primary(word)
      case word
      when 'NULL'
        @pos += 1
        Literal.new(nil)
      when 'EXISTS'
        @pos += 1
        expect_op('(')
        Exists.new(parse_subquery_rest.select)
      when 'CASE' then parse_case
      when 'CAST' then parse_cast
      else raise SqlError.syntax
      end
    end

    def query_start? = %w[SELECT WITH].include?(keyword)

    # After `(`: a query and the closing `)`.
    def parse_subquery_rest
      select = parse_query
      expect_op(')')
      Subquery.new(select)
    end

    def parse_case
      expect_kw('CASE')
      operand = keyword == 'WHEN' ? nil : parse_expr
      whens = []
      while accept_kw('WHEN')
        condition = parse_expr
        expect_kw('THEN')
        whens << [condition, parse_expr]
      end
      raise SqlError.syntax if whens.empty?

      else_expr = accept_kw('ELSE') ? parse_expr : nil
      expect_kw('END')
      CaseExpr.new(operand, whens, else_expr)
    end

    def parse_cast
      expect_kw('CAST')
      expect_op('(')
      expr = parse_expr
      expect_kw('AS')
      t = peek
      type = t && t.type == :id ? TYPES[t.value.upcase] : nil
      raise SqlError.syntax unless type

      @pos += 1
      expect_op(')')
      Cast.new(expr, type)
    end

    # After `name (`: `*`, or [DISTINCT] args [ORDER BY terms], then `)`.
    def parse_call_rest(name)
      if accept_op('*')
        raise SqlError.syntax unless name.casecmp?('count')

        expect_op(')')
        return Call.new(name:, args: [Star.new])
      end
      return Call.new(name:, args: []) if accept_op(')')

      distinct = accept_kw('DISTINCT')
      args = [parse_expr]
      args << parse_expr while accept_op(',')
      order_by = parse_order_by
      expect_op(')')
      Call.new(name:, args:, distinct:, order_by:)
    end

    def parse_name
      name = expect_ident
      if accept_op('(')
        call = parse_call_rest(name)
        accept_kw('OVER') ? WindowCall.new(call, parse_window_reference) : call
      elsif accept_op('.')
        ColumnRef.new(name, expect_ident)
      else
        ColumnRef.new(nil, name)
      end
    end
  end
end
