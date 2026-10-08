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
        elsif accept_kw("UPDATE") then parse_update
        elsif accept_kw("DELETE") then parse_delete
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
      constraints = []
      while accept_op(",")
        if kw?("PRIMARY") || kw?("UNIQUE")
          constraints << parse_table_constraint
        else
          fail_syntax unless constraints.empty? # column definitions come before table constraints
          columns << parse_column_def
        end
      end
      expect_op(")")
      CreateTable.new(name, columns, if_not_exists, constraints)
    end

    def parse_column_def
      name = expect_ident
      type = Sql.fold(expect_ident)
      fail_syntax unless COLUMN_TYPES.include?(type)
      flags = { primary_key: false, not_null: false, unique: false }
      default = nil
      loop do
        if accept_kw("PRIMARY")
          expect_kw("KEY")
          flags[:primary_key] = true
        elsif accept_kw("NOT")
          expect_kw("NULL")
          flags[:not_null] = true
        elsif accept_kw("UNIQUE")
          flags[:unique] = true
        elsif accept_kw("DEFAULT")
          default = Default.new(parse_default_value)
        else
          break
        end
      end
      ColumnDef.new(name, type.to_sym, flags[:primary_key], flags[:not_null], flags[:unique], default)
    end

    # [+ | -] numeric-literal | string-literal | NULL
    def parse_default_value
      return nil if accept_kw("NULL")
      return advance.value if peek.type == :str
      negative = accept_op("-")
      accept_op("+") unless negative
      fail_syntax unless %i[int float].include?(peek.type)
      negative ? -advance.value : advance.value
    end

    def parse_table_constraint
      kind = if accept_kw("PRIMARY")
               expect_kw("KEY")
               :primary_key
             else
               expect_kw("UNIQUE")
               :unique
             end
      expect_op("(")
      columns = [expect_ident]
      columns << expect_ident while accept_op(",")
      expect_op(")")
      TableConstraint.new(kind, columns)
    end

    def parse_update
      table = expect_ident
      expect_kw("SET")
      assignments = [parse_assignment]
      assignments << parse_assignment while accept_op(",")
      where = accept_kw("WHERE") ? parse_expr : nil
      Update.new(table, assignments, where)
    end

    def parse_assignment
      column = expect_ident
      expect_op("=")
      [column, parse_expr]
    end

    def parse_delete
      expect_kw("FROM")
      table = expect_ident
      where = accept_kw("WHERE") ? parse_expr : nil
      Delete.new(table, where)
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
      distinct = !accept_kw("DISTINCT").nil?
      accept_kw("ALL") unless distinct
      columns = [parse_result_column]
      columns << parse_result_column while accept_op(",")
      table = accept_kw("FROM") ? expect_ident : nil
      where = accept_kw("WHERE") ? parse_expr : nil
      group_by = accept_group_by_clause
      having = accept_kw("HAVING") ? parse_expr : nil
      order_by = accept_order_by_clause
      limit = offset = nil
      if accept_kw("LIMIT")
        limit = parse_expr
        offset = parse_expr if accept_kw("OFFSET")
      end
      Select.new(distinct, columns, table, where, group_by, having, order_by, limit, offset)
    end

    # GROUP BY expr, ... (nil when absent)
    def accept_group_by_clause
      return nil unless accept_kw("GROUP")
      expect_kw("BY")
      parse_expression_list
    end

    # ORDER BY term, ... ([] when absent)
    def accept_order_by_clause
      return [] unless accept_kw("ORDER")
      expect_kw("BY")
      terms = [parse_order_term]
      terms << parse_order_term while accept_op(",")
      terms
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
        elsif postfix_predicate?
          left = parse_predicate(left)
        else
          return left
        end
      end
    end

    PREDICATES = %w[IN LIKE BETWEEN].freeze

    # At `IN`, `LIKE`, `BETWEEN`, or `NOT` followed by one of them.
    def postfix_predicate?
      t = peek
      return false unless t.type == :kw
      return true if PREDICATES.include?(t.value)
      nxt = @tokens[@pos + 1]
      t.value == "NOT" && nxt&.type == :kw && PREDICATES.include?(nxt.value)
    end

    def parse_predicate(left)
      negated = !accept_kw("NOT").nil?
      if accept_kw("IN")
        expect_op("(")
        list = op?(")") ? [] : parse_expression_list
        expect_op(")")
        In.new(left, list, negated)
      elsif accept_kw("LIKE")
        Like.new(left, parse_comparison, negated)
      else
        expect_kw("BETWEEN")
        low = parse_comparison
        expect_kw("AND")
        Between.new(left, low, parse_comparison, negated)
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
        case t.value
        when "NULL" then Literal.new(nil)
        when "CASE" then parse_case
        when "CAST" then parse_cast
        else fail_syntax
        end
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

    def parse_case
      operand = kw?("WHEN") ? nil : parse_expr
      whens = []
      while accept_kw("WHEN")
        condition = parse_expr
        expect_kw("THEN")
        whens << [condition, parse_expr]
      end
      fail_syntax if whens.empty?
      else_expr = accept_kw("ELSE") ? parse_expr : nil
      expect_kw("END")
      Case.new(operand, whens, else_expr)
    end

    def parse_cast
      expect_op("(")
      expr = parse_expr
      expect_kw("AS")
      type = Sql.fold(expect_ident)
      fail_syntax unless COLUMN_TYPES.include?(type)
      expect_op(")")
      Cast.new(expr, type.to_sym)
    end

    # After `name (`: `*)`, or [DISTINCT] args [ORDER BY terms] `)`.
    def parse_call_rest(name)
      if accept_op("*")
        expect_op(")")
        return Call.new(name: name, args: [], star: true)
      end
      distinct = !accept_kw("DISTINCT").nil?
      fail_syntax if distinct && op?(")")
      args = op?(")") ? [] : parse_expression_list
      order_by = accept_order_by_clause
      expect_op(")")
      Call.new(name: name, args: args, distinct: distinct, order_by: order_by)
    end

    def parse_name_or_call(name)
      if accept_op("(")
        parse_call_rest(name)
      elsif accept_op(".")
        Column.new(name, expect_ident)
      else
        Column.new(nil, name)
      end
    end
  end
end
