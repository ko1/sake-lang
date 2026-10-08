# frozen_string_literal: true

require_relative "ast"
require_relative "binder"
require_relative "evaluator"
require_relative "errors"
require_relative "values"

module Sql
  # Runs a SELECT: binds all names first (so name errors happen before any row is read), then
  # filters, projects, sorts and slices. `run` returns the result rows (arrays of values).
  class Query
    # Where an ORDER BY term takes its value: a result column, or an expression on the source row.
    SortKey = Data.define(:result_index, :expr, :desc, :nulls)

    def initialize(catalog, select)
      @catalog = catalog
      @select = select
    end

    def run
      table = @select.table && @catalog.fetch_table(@select.table)
      columns = bind_result_columns(table)
      where = bind_where(table, columns)
      keys = bind_order_by(table, columns)
      limit = bind_count(@select.limit)
      offset = bind_count(@select.offset)

      rows = table ? table.rows : [[]]
      rows = rows.select { |row| Values.truth(Evaluator.evaluate(where, row)) } if where
      entries = rows.map do |row|
        result = columns.map { |c| Evaluator.evaluate(c.expr, row) }
        [result, row]
      end
      entries = sort(entries, keys) unless keys.empty?
      results = entries.map(&:first)
      slice(results, limit, offset)
    end

    private

    BoundColumn = Data.define(:expr, :alias)

    def bind_result_columns(table)
      scope = Scope.new(table: table)
      @select.columns.flat_map do |rc|
        if rc.expr.is_a?(Star)
          raise SqlError, "no tables specified" unless table
          table.columns.each_index.map { |i| BoundColumn.new(ColumnRef.new(i, table.columns[i].type), nil) }
        else
          [BoundColumn.new(Binder.bind(rc.expr, scope), rc.alias)]
        end
      end
    end

    def alias_scope(table, columns)
      aliases = {}
      columns.each { |c| aliases[Sql.fold(c.alias)] ||= c.expr if c.alias }
      Scope.new(table: table, aliases: aliases)
    end

    def bind_where(table, columns)
      @select.where && Binder.bind(@select.where, alias_scope(table, columns))
    end

    def bind_order_by(table, columns)
      scope = alias_scope(table, columns)
      @select.order_by.each_with_index.map do |term, i|
        expr = term.expr
        index = ordinal(expr, i, columns.length) || alias_index(expr, columns)
        bound = index ? nil : Binder.bind(expr, scope)
        SortKey.new(index, bound, term.desc, term.nulls)
      end
    end

    # `k` or `-k` (an integer literal) names the k-th result column (0-based result here).
    def ordinal(expr, position, count)
      return nil unless expr.is_a?(Literal) && expr.value.is_a?(Integer)
      k = expr.value
      return k - 1 if k.between?(1, count)
      raise SqlError, "#{ordinal_word(position + 1)} ORDER BY term out of range - should be between 1 and #{count}"
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

    def sort(entries, keys)
      decorated = entries.each_with_index.map do |(result, row), n|
        values = keys.map { |k| k.result_index ? result[k.result_index] : Evaluator.evaluate(k.expr, row) }
        [result, values, n]
      end
      decorated.sort do |a, b|
        c = compare_keys(a[1], b[1], keys)
        c == 0 ? a[2] <=> b[2] : c
      end.map { |result, _, _| [result] }
    end

    def compare_keys(a, b, keys)
      keys.each_index do |i|
        c = compare_term(a[i], b[i], keys[i])
        return c unless c == 0
      end
      0
    end

    def compare_term(x, y, key)
      if (x.nil? || y.nil?) && key.nulls
        return 0 if x.nil? && y.nil?
        nulls_first = key.nulls == :first
        return x.nil? == nulls_first ? -1 : 1
      end
      c = Values.compare(x, y)
      key.desc ? -c : c
    end

    def slice(rows, limit, offset)
      rows = rows.drop(offset) if offset && offset > 0
      rows = rows.first(limit) if limit && limit >= 0
      rows
    end
  end
end
