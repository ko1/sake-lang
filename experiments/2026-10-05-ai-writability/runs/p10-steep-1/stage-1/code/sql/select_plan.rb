# frozen_string_literal: true

require_relative "ast"
require_relative "error"
require_relative "evaluator"
require_relative "resolver"
require_relative "schema"

module Sql
  # A SELECT with every name checked: result expressions, WHERE, ORDER BY terms (positions and
  # aliases already replaced by the expressions they stand for) and LIMIT/OFFSET.
  class SelectPlan
    attr_reader :results, :where, :order_by, :limit, :offset

    # table is nil for a SELECT without FROM.
    def self.build(select, table)
      columns = table ? table.columns : [] #: Array[Column]
      results = [] #: Array[Ast::Expr]
      aliases = {} #: Hash[String, Ast::Expr]
      plain = Resolver.new(columns, aliases)
      select.items.each do |item|
        item_expr = item.expr
        if item_expr
          resolved = plain.resolve(item_expr)
          results << resolved
          alias_name = item.alias_name
          aliases[Names.fold(alias_name)] = resolved if alias_name
        else
          raise Error, "no tables specified" unless table

          columns.each_with_index { |column, i| results << Ast::ResolvedColumn.new(i, column.type) }
        end
      end
      scope = Resolver.new(columns, aliases)
      where_expr = select.where
      where = where_expr ? scope.resolve(where_expr) : nil
      order_by = select.order_by.each_with_index.map { |term, i| plan_term(term, i, results, aliases, scope) }
      constants = Resolver.new([], {})
      limit = select.limit
      offset = select.offset
      new(results, where, order_by, limit ? constants.resolve(limit) : nil, offset ? constants.resolve(offset) : nil)
    end

    def self.plan_term(term, index, results, aliases, scope)
      expr = term.expr
      position = literal_position(expr)
      if position
        unless position >= 1 && position <= results.length
          raise Error, "#{ordinal(index + 1)} ORDER BY term out of range - should be between 1 and #{results.length}"
        end

        resolved = results.fetch(position - 1)
      elsif expr.is_a?(Ast::ColumnRef) && aliases.key?(Names.fold(expr.name))
        resolved = aliases.fetch(Names.fold(expr.name))
      else
        resolved = scope.resolve(expr)
      end
      Ast::OrderTerm.new(resolved, term.descending, term.nulls_first)
    end

    # k for an integer literal k or -k, else nil.
    def self.literal_position(expr)
      if expr.is_a?(Ast::Literal)
        value = expr.value
        value.is_a?(Integer) ? value : nil
      elsif expr.is_a?(Ast::Unary) && expr.op == "-"
        inner = literal_position(expr.operand)
        inner && expr.operand.is_a?(Ast::Literal) ? -inner : nil
      end
    end

    def self.ordinal(n)
      suffix =
        if (11..13).cover?(n % 100) then "th"
        else
          case n % 10
          when 1 then "st"
          when 2 then "nd"
          when 3 then "rd"
          else "th"
          end
        end
      "#{n}#{suffix}"
    end

    def initialize(results, where, order_by, limit, offset)
      @results = results
      @where = where
      @order_by = order_by
      @limit = limit
      @offset = offset
    end
  end
end
