# frozen_string_literal: true

require_relative "aggregate_slots"
require_relative "ast"
require_relative "error"
require_relative "evaluator"
require_relative "resolver"
require_relative "schema"

module Sql
  # A SELECT with every name checked: result expressions, WHERE, GROUP BY terms, HAVING, ORDER BY
  # terms (positions and aliases already replaced by the expressions they stand for) and
  # LIMIT/OFFSET. In a grouped plan (an aggregate query) the expressions after WHERE are resolved
  # against group rows: the table's width columns, then the value of each of aggregates.
  class SelectPlan
    attr_reader :distinct, :results, :where, :group_by, :having, :order_by, :limit, :offset,
                :aggregates, :width

    # table is nil for a SELECT without FROM.
    def self.build(select, table)
      columns = table ? table.columns : [] #: Array[Column]
      slots = AggregateSlots.new(columns.length)
      aliases = {} #: Hash[String, Ast::Expr]
      results = resolve_results(select.items, table, columns, aliases, slots)
      grouped = !select.group_by.empty? || !slots.empty?
      raise Error, "HAVING clause on a non-aggregate query" if select.having && !grouped

      where_expr = select.where
      where = where_expr ? Resolver.new(columns, aliases, :where).resolve(where_expr) : nil
      grouping = Resolver.new(columns, aliases, :group_by)
      group_by = select.group_by.each_with_index.map { |term, i| plan_group_term(term, i, results, grouping) }
      having_expr = select.having
      having = having_expr ? Resolver.new(columns, aliases, :allow, slots).resolve(having_expr) : nil
      scope = Resolver.new(columns, aliases, grouped ? :allow : :order, slots)
      order_by = select.order_by.each_with_index.map { |term, i| plan_term(term, i, results, aliases, scope) }
      constants = Resolver.new([], {})
      limit = select.limit
      offset = select.offset
      new(select.distinct, results, where, group_by, having, order_by,
          limit ? constants.resolve(limit) : nil, offset ? constants.resolve(offset) : nil,
          grouped ? slots.calls : nil, slots.width)
    end

    # The result column expressions; fills aliases with those that have an AS name.
    def self.resolve_results(items, table, columns, aliases, slots)
      results = [] #: Array[Ast::Expr]
      scope = Resolver.new(columns, aliases, :allow, slots)
      items.each do |item|
        item_expr = item.expr
        if item_expr
          resolved = scope.resolve(item_expr)
          results << resolved
          alias_name = item.alias_name
          aliases[Names.fold(alias_name)] = resolved if alias_name
        else
          raise Error, "no tables specified" unless table

          columns.each_with_index { |column, i| results << Ast::ResolvedColumn.new(i, column.type) }
        end
      end
      results
    end

    def self.plan_group_term(expr, index, results, scope)
      position = literal_position(expr)
      return scope.resolve(expr) unless position

      unless position >= 1 && position <= results.length
        raise Error, "#{ordinal(index + 1)} GROUP BY term out of range - should be between 1 and #{results.length}"
      end

      resolved = results.fetch(position - 1)
      raise Error, "aggregate functions are not allowed in the GROUP BY clause" if resolved.first_aggregate

      resolved
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

    # aggregates is nil unless the query is an aggregate query (it may then be empty).
    def initialize(distinct, results, where, group_by, having, order_by, limit, offset, aggregates, width)
      @distinct = distinct
      @results = results
      @where = where
      @group_by = group_by
      @having = having
      @order_by = order_by
      @limit = limit
      @offset = offset
      @aggregates = aggregates || [] #: Array[Ast::Aggregate]
      @grouped = !aggregates.nil?
      @width = width
    end

    # Whether this is an aggregate query (has GROUP BY or aggregate calls in its result columns).
    def grouped?
      @grouped
    end
  end
end
