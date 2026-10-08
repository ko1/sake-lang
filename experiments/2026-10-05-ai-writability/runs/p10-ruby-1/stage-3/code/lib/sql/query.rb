# frozen_string_literal: true

require_relative "aggregates"
require_relative "ast"
require_relative "binder"
require_relative "errors"
require_relative "evaluator"
require_relative "grouping"
require_relative "ordering"
require_relative "values"

module Sql
  # Runs a SELECT: binds all names first (so name errors happen before any row is read), then
  # filters, groups (aggregate queries), projects, removes duplicates, sorts and slices.
  # `run` returns the result rows (arrays of values).
  class Query
    BoundColumn = Data.define(:expr, :alias)

    GROUP_BY_SCOPE_AGGREGATES = Aggregates::Forbidden.new("aggregate functions are not allowed in the GROUP BY clause")
    PLAIN_ORDER_BY_AGGREGATES = Aggregates::Forbidden.new("misuse of aggregate: %s()")

    def initialize(catalog, select)
      @catalog = catalog
      @select = select
    end

    def run
      table = @select.table && @catalog.fetch_table(@select.table)
      width = table ? table.columns.length : 0
      collector = Aggregates::Collector.new(width)
      columns = bind_result_columns(table, collector)
      aggregate = !@select.group_by.nil? || @select.columns.any? { |rc| Aggregates.contains_call?(rc.expr) }
      where = bind_where(table, columns)
      group_by = bind_group_by(table, columns)
      having = bind_having(table, columns, collector, aggregate)
      keys = bind_order_by(table, columns, aggregate ? collector : PLAIN_ORDER_BY_AGGREGATES)
      limit = bind_count(@select.limit)
      offset = bind_count(@select.offset)

      rows = table ? table.rows : [[]]
      rows = rows.select { |row| Values.truth(Evaluator.evaluate(where, row)) } if where
      rows = group_rows(rows, group_by, collector.specs, width, having) if aggregate
      entries = rows.map { |row| [columns.map { |c| Evaluator.evaluate(c.expr, row) }, row] }
      entries = distinct(entries) if @select.distinct
      entries = sort(entries, keys) unless keys.empty?
      slice(entries.map(&:first), limit, offset)
    end

    private

    def bind_result_columns(table, collector)
      scope = Scope.new(table: table, aggregates: collector)
      @select.columns.flat_map do |rc|
        if rc.expr.is_a?(Star)
          raise SqlError, "no tables specified" unless table
          table.columns.each_index.map { |i| BoundColumn.new(ColumnRef.new(i, table.columns[i].type), nil) }
        else
          [BoundColumn.new(Binder.bind(rc.expr, scope), rc.alias)]
        end
      end
    end

    def alias_scope(table, columns, aggregates = Scope::NO_AGGREGATES)
      aliases = {}
      columns.each { |c| aliases[Sql.fold(c.alias)] ||= c.expr if c.alias }
      Scope.new(table: table, aliases: aliases, aggregates: aggregates)
    end

    def bind_where(table, columns)
      @select.where && Binder.bind(@select.where, alias_scope(table, columns))
    end

    # Bound GROUP BY terms, or nil without GROUP BY.
    def bind_group_by(table, columns)
      return nil unless @select.group_by
      scope = alias_scope(table, columns, GROUP_BY_SCOPE_AGGREGATES)
      @select.group_by.each_with_index.map do |expr, i|
        index = ordinal(expr, i, columns.length, "GROUP BY")
        if index
          GROUP_BY_SCOPE_AGGREGATES.check_alias(columns[index].expr)
          columns[index].expr
        else
          Binder.bind(expr, scope)
        end
      end
    end

    def bind_having(table, columns, collector, aggregate)
      return nil unless @select.having
      raise SqlError, "HAVING clause on a non-aggregate query" unless aggregate
      Binder.bind(@select.having, alias_scope(table, columns, collector))
    end

    def bind_order_by(table, columns, aggregates)
      scope = alias_scope(table, columns, aggregates)
      @select.order_by.each_with_index.map do |term, i|
        expr = term.expr
        index = ordinal(expr, i, columns.length, "ORDER BY") || alias_index(expr, columns)
        bound = index ? nil : Binder.bind(expr, scope)
        Ordering::SortKey.new(index, bound, term.desc, term.nulls)
      end
    end

    # `k` or `-k` (an integer literal) names the k-th result column (0-based result here).
    def ordinal(expr, position, count, clause)
      return nil unless expr.is_a?(Literal) && expr.value.is_a?(Integer)
      k = expr.value
      return k - 1 if k.between?(1, count)
      raise SqlError, "#{ordinal_word(position + 1)} #{clause} term out of range - should be between 1 and #{count}"
    end

    def ordinal_word(n)
      suffix = if (11..13).cover?(n % 100) then "th"
               else { 1 => "st", 2 => "nd", 3 => "rd" }.fetch(n % 10, "th")
               end
      "#{n}#{suffix}"
    end

    # A term that is just a name equal to a result column's alias means that result column.
    def alias_index(expr, columns)
      return nil unless expr.is_a?(Column) && expr.table.nil?
      key = Sql.fold(expr.name)
      columns.index { |c| c.alias && Sql.fold(c.alias) == key }
    end

    # LIMIT / OFFSET: evaluated once, with no row in scope.
    def bind_count(expr)
      return nil unless expr
      value = Evaluator.evaluate(Binder.bind(expr, Scope.new), [])
      value.nil? ? nil : Values.to_number(value).to_i
    end

    # One group row (see Grouping) per group that HAVING keeps.
    def group_rows(rows, group_by, specs, width, having)
      group_rows = Grouping.partition(rows, group_by).map { |group| Grouping.group_row(group, specs, width) }
      having ? group_rows.select { |row| Values.truth(Evaluator.evaluate(having, row)) } : group_rows
    end

    # Keeps the first of each set of entries with equal result rows (3.4).
    def distinct(entries)
      entries.uniq { |result, _| result.map { |v| Values.group_key(v) } }
    end

    def sort(entries, keys)
      Ordering.sort(entries, keys) do |(result, row), key|
        key.result_index ? result[key.result_index] : Evaluator.evaluate(key.expr, row)
      end
    end

    def slice(rows, limit, offset)
      rows = rows.drop(offset) if offset && offset > 0
      rows = rows.first(limit) if limit && limit >= 0
      rows
    end
  end
end
