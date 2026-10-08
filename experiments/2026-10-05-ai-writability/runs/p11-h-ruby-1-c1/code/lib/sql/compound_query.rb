# frozen_string_literal: true

require_relative "ast"
require_relative "binder"
require_relative "collation"
require_relative "errors"
require_relative "identifier"
require_relative "limits"
require_relative "ordering"
require_relative "scope"
require_relative "values"

module Sql
  # A compound select (5.1): simple selects joined by UNION [ALL] / INTERSECT / EXCEPT, left to right,
  # then the ORDER BY / LIMIT / OFFSET of the whole. Same interface as Query.
  class CompoundQuery
    OPERATOR_WORDS = { union: "UNION", union_all: "UNION ALL", intersect: "INTERSECT", except: "EXCEPT" }.freeze

    def initialize(planner, compound, parent)
      @ops = compound.rest.map(&:first)
      @parts = [compound.first, *compound.rest.map(&:last)].map { |select| planner.plan(select, parent) }
      check_widths
      @collations = column_collations
      @keys = bind_order_by(compound.order_by)
      limit_scope = Scope.new(planner: planner)
      @limit = compound.limit && Binder.bind(compound.limit, limit_scope)
      @offset = compound.offset && Binder.bind(compound.offset, limit_scope)
      @cache = nil
    end

    # Named by the first select; no affinity.
    def result_columns
      @parts.first.result_columns.each_with_index.map { |c, i| SourceColumn.new(c.name, nil, @collations[i]) }
    end

    # Collation info (see Collation.info) of each result column.
    def result_infos
      @collations.map { |c| [:implicit, c] }
    end

    def volatile?
      @parts.any?(&:volatile?)
    end

    def run(outer_row = [])
      return execute(outer_row) if volatile?
      @cache ||= execute(outer_row)
    end

    private

    def execute(outer_row)
      limit = Limits.count(@limit, 0)
      offset = Limits.count(@offset, 0)
      rows = @parts.first.run(outer_row)
      @ops.each_with_index { |op, i| rows = combine(op, rows, @parts[i + 1].run(outer_row)) }
      rows = Ordering.sort(rows, @keys) { |row, key| row[key.result_index] } unless @keys.empty?
      Limits.slice(rows, limit, offset)
    end

    # The k-th column compares under the collation of the first select whose k-th column has one (7.4).
    def column_collations
      infos = @parts.map(&:result_infos)
      @parts.first.result_columns.each_index.map do |k|
        infos.filter_map { |part_infos| part_infos[k] }.first&.last || :binary
      end
    end

    def check_widths
      width = @parts.first.result_columns.length
      @ops.each_with_index do |op, i|
        next if @parts[i + 1].result_columns.length == width
        raise SqlError, "SELECTs to the left and right of #{OPERATOR_WORDS.fetch(op)} do not have the same number of result columns"
      end
    end

    # An integer (k-th column) or a name of a result column, looked up in each select in turn.
    def bind_order_by(terms)
      width = @parts.first.result_columns.length
      terms.each_with_index.map do |term, i|
        expr, collation = Collation.peel(term.expr)
        index = Ordering.ordinal(expr, i, width, "ORDER BY") || name_index(expr)
        unless index
          raise SqlError, "#{Ordering.ordinal_word(i + 1)} ORDER BY term does not match any column in the result set"
        end
        Ordering.result_key(index, term, collation || @collations[index])
      end
    end

    def name_index(expr)
      return nil unless expr.is_a?(Column) && expr.table.nil?
      key = Sql.fold(expr.name)
      @parts.each do |part|
        index = part.result_columns.index { |c| c.name && Sql.fold(c.name) == key }
        return index if index
      end
      nil
    end

    def combine(op, left, right)
      case op
      when :union_all then left + right
      when :union then distinct(left + right)
      when :intersect
        in_right = row_keys(right)
        distinct(left).select { |row| in_right.key?(Values.row_key(row, @collations)) }
      when :except
        in_right = row_keys(right)
        distinct(left).reject { |row| in_right.key?(Values.row_key(row, @collations)) }
      end
    end

    def distinct(rows)
      rows.uniq { |row| Values.row_key(row, @collations) }
    end

    def row_keys(rows)
      rows.to_h { |row| [Values.row_key(row, @collations), true] }
    end
  end
end
