# frozen_string_literal: true

require_relative 'ast'
require_relative 'errors'
require_relative 'lexer'

module SQL
  # Recursive-descent parser: tokens of one statement -> statement AST (SPEC 1.4, 1.6-1.8).
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
        when 'SELECT' then parse_select
        when 'INSERT' then parse_insert
        when 'CREATE' then parse_create
        when 'DROP' then parse_drop
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
      expect_kw('TABLE')
      if_not_exists = false
      if accept_kw('IF')
        expect_kw('NOT')
        expect_kw('EXISTS')
        if_not_exists = true
      end
      name = expect_ident
      expect_op('(')
      columns = [parse_column_def]
      columns << parse_column_def while accept_op(',')
      expect_op(')')
      CreateTable.new(name, columns, if_not_exists)
    end

    def parse_column_def
      name = expect_ident
      t = peek
      type = t && t.type == :id ? TYPES[t.value.upcase] : nil
      raise SqlError.syntax unless type

      @pos += 1
      ColumnDef.new(name, type)
    end

    def parse_drop
      expect_kw('DROP')
      expect_kw('TABLE')
      if_exists = false
      if accept_kw('IF')
        expect_kw('EXISTS')
        if_exists = true
      end
      DropTable.new(expect_ident, if_exists)
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
      expect_kw('VALUES')
      rows = [parse_value_row]
      rows << parse_value_row while accept_op(',')
      Insert.new(table, columns, rows)
    end

    def parse_value_row
      expect_op('(')
      row = [parse_expr]
      row << parse_expr while accept_op(',')
      expect_op(')')
      row
    end

    # --- SELECT -------------------------------------------------------------------------

    def parse_select
      expect_kw('SELECT')
      items = [parse_result_column]
      items << parse_result_column while accept_op(',')
      from = accept_kw('FROM') ? expect_ident : nil
      where = accept_kw('WHERE') ? parse_expr : nil
      order_by = []
      if accept_kw('ORDER')
        expect_kw('BY')
        order_by << parse_order_term
        order_by << parse_order_term while accept_op(',')
      end
      limit = offset = nil
      if accept_kw('LIMIT')
        limit = parse_expr
        offset = parse_expr if accept_kw('OFFSET')
      end
      Select.new(items, from, where, order_by, limit, offset)
    end

    def parse_result_column
      return Star.new if accept_op('*')

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
    # ||, unary, primary.

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
        else
          return left
        end
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
      else parse_primary
      end
    end

    def parse_primary
      t = peek
      raise SqlError.syntax unless t

      case t.type
      when :int, :real, :str
        @pos += 1
        Literal.new(t.value)
      when :kw
        raise SqlError.syntax unless t.value == 'NULL'

        @pos += 1
        Literal.new(nil)
      when :id
        parse_name
      when :op
        raise SqlError.syntax unless t.value == '('

        @pos += 1
        expr = parse_expr
        expect_op(')')
        expr
      end
    end

    def parse_name
      name = expect_ident
      if accept_op('(')
        args = []
        unless accept_op(')')
          args << parse_expr
          args << parse_expr while accept_op(',')
          expect_op(')')
        end
        Call.new(name, args)
      elsif accept_op('.')
        ColumnRef.new(name, expect_ident)
      else
        ColumnRef.new(nil, name)
      end
    end
  end
end
