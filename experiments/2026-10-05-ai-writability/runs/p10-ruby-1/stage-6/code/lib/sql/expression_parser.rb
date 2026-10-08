# frozen_string_literal: true

require_relative "ast"
require_relative "errors"
require_relative "identifier"

module Sql
  # Parsing of expressions, loosest binding first (1.8). Mixed into Parser.
  module ExpressionParser
    EQUALITY_OPS = { "=" => :eq, "==" => :eq, "!=" => :ne, "<>" => :ne }.freeze
    COMPARISON_OPS = { "<" => :lt, "<=" => :le, ">" => :gt, ">=" => :ge }.freeze
    ADDITIVE_OPS = { "+" => :+, "-" => :- }.freeze
    MULTIPLICATIVE_OPS = { "*" => :*, "/" => :/, "%" => :% }.freeze

    private

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
        if query_start?
          query = parse_query
          expect_op(")")
          return InSubquery.new(expr: left, query: query, negated: negated)
        end
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
        when "EXISTS" then parse_exists
        else fail_syntax
        end
      when :ident
        parse_name_or_call(t.value)
      when :op
        fail_syntax unless t.value == "("
        expr = query_start? ? Subquery.new(query: parse_query) : parse_expr
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

    def parse_exists
      expect_op("(")
      fail_syntax unless query_start?
      query = parse_query
      expect_op(")")
      Exists.new(query: query)
    end

    def parse_cast
      expect_op("(")
      expr = parse_expr
      expect_kw("AS")
      type = Sql.fold(expect_ident)
      fail_syntax unless Sql::COLUMN_TYPES.include?(type)
      expect_op(")")
      Cast.new(expr, type.to_sym)
    end

    # After `name (`: `*)`, or [DISTINCT] args [ORDER BY terms] `)`, then an optional OVER (6.1).
    def parse_call_rest(name)
      if accept_op("*")
        expect_op(")")
        return with_over(Call.new(name: name, args: [], star: true))
      end
      distinct = !accept_kw("DISTINCT").nil?
      fail_syntax if distinct && op?(")")
      args = op?(")") ? [] : parse_expression_list
      order_by = accept_order_by_clause
      expect_op(")")
      with_over(Call.new(name: name, args: args, distinct: distinct, order_by: order_by))
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
