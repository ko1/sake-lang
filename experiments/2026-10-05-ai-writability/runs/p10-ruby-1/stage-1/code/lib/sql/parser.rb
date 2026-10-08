# frozen_string_literal: true

require_relative "ast"
require_relative "errors"
require_relative "identifier"
require_relative "lexer"

module Sql
  # Recursive-descent parser: the tokens of ONE statement -> a statement node (ast.rb).
  # Only grammar is checked here; names, types and counts are checked later.
  class Parser
    COLUMN_TYPES = %w[integer real text].freeze
    EQUALITY_OPS = { "=" => :eq, "==" => :eq, "!=" => :ne, "<>" => :ne }.freeze
    COMPARISON_OPS = { "<" => :lt, "<=" => :le, ">" => :gt, ">=" => :ge }.freeze
    ADDITIVE_OPS = { "+" => :+, "-" => :- }.freeze
    MULTIPLICATIVE_OPS = { "*" => :*, "/" => :/, "%" => :% }.freeze
    EOF_TOKEN = Token.new(:eof, nil)

    def self.parse(tokens)
      new(tokens).parse_statement
    end

    def initialize(tokens)
      @tokens = tokens
      @pos = 0
    end

    def parse_statement
      statement =
        if accept_kw("SELECT") then parse_select
        elsif accept_kw("INSERT") then parse_insert
        elsif accept_kw("CREATE") then parse_create
        elsif accept_kw("DROP") then parse_drop
        else fail_syntax
        end
      fail_syntax unless peek.type == :eof
      statement
    end

    private

    # ---- token helpers ----

    def peek
      @tokens[@pos] || EOF_TOKEN
    end

    def advance
      token = peek
      @pos += 1
      token
    end

    def fail_syntax
      raise SyntaxError
    end

    def kw?(word)
      t = peek
      t.type == :kw && t.value == word
    end

    def op?(text)
      t = peek
      t.type == :op && t.value == text
    end

    def accept_kw(word)
      kw?(word) ? advance : nil
    end

    def accept_op(text)
      op?(text) ? advance : nil
    end

    def expect_kw(word)
      accept_kw(word) || fail_syntax
    end

    def expect_op(text)
      accept_op(text) || fail_syntax
    end

    def expect_ident
      peek.type == :ident ? advance.value : fail_syntax
    end

    # ---- statements ----

    def parse_create
      expect_kw("TABLE")
      if_not_exists = false
      if accept_kw("IF")
        expect_kw("NOT")
        expect_kw("EXISTS")
        if_not_exists = true
      end
      name = expect_ident
      expect_op("(")
      columns = [parse_column_def]
      columns << parse_column_def while accept_op(",")
      expect_op(")")
      CreateTable.new(name, columns, if_not_exists)
    end

    def parse_column_def
      name = expect_ident
      type = Sql.fold(expect_ident)
      fail_syntax unless COLUMN_TYPES.include?(type)
      ColumnDef.new(name, type.to_sym)
    end

    def parse_drop
      expect_kw("TABLE")
      if_exists = false
      if accept_kw("IF")
        expect_kw("EXISTS")
        if_exists = true
      end
      DropTable.new(expect_ident, if_exists)
    end

    def parse_insert
      expect_kw("INTO")
      table = expect_ident
      columns = nil
      if accept_op("(")
        columns = [expect_ident]
        columns << expect_ident while accept_op(",")
        expect_op(")")
      end
      expect_kw("VALUES")
      rows = [parse_value_row]
      rows << parse_value_row while accept_op(",")
      Insert.new(table, columns, rows)
    end

    def parse_value_row
      expect_op("(")
      row = parse_expression_list
      expect_op(")")
      row
    end

    def parse_expression_list
      list = [parse_expr]
      list << parse_expr while accept_op(",")
      list
    end

    def parse_select
      columns = [parse_result_column]
      columns << parse_result_column while accept_op(",")
      table = accept_kw("FROM") ? expect_ident : nil
      where = accept_kw("WHERE") ? parse_expr : nil
      order_by = []
      if accept_kw("ORDER")
        expect_kw("BY")
        order_by << parse_order_term
        order_by << parse_order_term while accept_op(",")
      end
      limit = offset = nil
      if accept_kw("LIMIT")
        limit = parse_expr
        offset = parse_expr if accept_kw("OFFSET")
      end
      Select.new(columns, table, where, order_by, limit, offset)
    end

    def parse_result_column
      return ResultColumn.new(Star.new, nil) if accept_op("*")
      expr = parse_expr
      name = if accept_kw("AS") then expect_ident
             elsif peek.type == :ident then advance.value
             end
      ResultColumn.new(expr, name)
    end

    def parse_order_term
      expr = parse_expr
      desc = false
      if accept_kw("DESC")
        desc = true
      else
        accept_kw("ASC")
      end
      nulls = nil
      if accept_kw("NULLS")
        nulls = if accept_kw("FIRST") then :first
                else
                  expect_kw("LAST")
                  :last
                end
      end
      OrderTerm.new(expr, desc, nulls)
    end

    # ---- expressions, loosest binding first (1.8) ----

    def parse_expr
      parse_or
    end

    def parse_or
      left = parse_and
      left = Binary.new(:or, left, parse_and) while accept_kw("OR")
      left
    end

    def parse_and
      left = parse_not
      left = Binary.new(:and, left, parse_not) while accept_kw("AND")
      left
    end

    def parse_not
      return Unary.new(:not, parse_not) if accept_kw("NOT")
      parse_equality
    end

    def parse_equality
      left = parse_comparison
      loop do
        t = peek
        if t.type == :op && (op = EQUALITY_OPS[t.value])
          advance
          left = Binary.new(op, left, parse_comparison)
        elsif accept_kw("IS")
          op = accept_kw("NOT") ? :isnot : :is
          left = Binary.new(op, left, parse_comparison)
        else
          return left
        end
      end
    end

    def parse_comparison
      left_assoc(COMPARISON_OPS) { parse_additive }
    end

    def parse_additive
      left_assoc(ADDITIVE_OPS) { parse_multiplicative }
    end

    def parse_multiplicative
      left_assoc(MULTIPLICATIVE_OPS) { parse_concat }
    end

    def parse_concat
      left = parse_unary
      left = Binary.new(:concat, left, parse_unary) while accept_op("||")
      left
    end

    # One left-associative level: operand (op operand)*, operands from the block.
    def left_assoc(ops)
      left = yield
      while peek.type == :op && (op = ops[peek.value])
        advance
        left = Binary.new(op, left, yield)
      end
      left
    end

    def parse_unary
      if accept_op("-")
        operand = parse_unary
        # fold `-<integer literal>` so that -9223372036854775808 is an INTEGER
        return Literal.new(-operand.value) if operand.is_a?(Literal) && operand.value.is_a?(Integer)
        Unary.new(:neg, operand)
      elsif accept_op("+")
        Unary.new(:plus, parse_unary)
      else
        parse_primary
      end
    end

    def parse_primary
      t = advance
      case t.type
      when :int, :float, :str
        Literal.new(t.value)
      when :kw
        t.value == "NULL" ? Literal.new(nil) : fail_syntax
      when :ident
        parse_name_or_call(t.value)
      when :op
        fail_syntax unless t.value == "("
        expr = parse_expr
        expect_op(")")
        expr
      else
        fail_syntax
      end
    end

    def parse_name_or_call(name)
      if accept_op("(")
        args = op?(")") ? [] : parse_expression_list
        expect_op(")")
        Call.new(name, args, nil)
      elsif accept_op(".")
        Column.new(name, expect_ident)
      else
        Column.new(nil, name)
      end
    end
  end
end
