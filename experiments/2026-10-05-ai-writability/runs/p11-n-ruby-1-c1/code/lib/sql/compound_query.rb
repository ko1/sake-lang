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
      @infos = column_collation_infos
      @collations = @infos.map { |info| info ? info.first : :binary }
      @keys = bind_order_by(compound.order_by)
      limit_scope = Scope.new(planner: planner)
      @limit = compound.limit && Binder.bind(compound.limit, limit_scope)
      @offset = compound.offset && Binder.bind(compound.offset, limit_scope)
      @cache = nil
    end

    # Named by the first select; no affinity; each column has the collation the compound compares it under.
    def result_columns
      @parts.first.result_columns.each_with_index.map { |c, k| SourceColumn.new(c.name, nil, @collations[k]) }
    end

    # Per column: nil, or [name, explicit?] of the first select's column that has a collation (7.4).
    def result_collation_infos
      @infos
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

    def check_widths
      width = @parts.first.result_columns.length
      @ops.each_with_index do |op, i|
        next if @parts[i + 1].result_columns.length == width
        raise SqlError, "SELECTs to the left and right of #{OPERATOR_WORDS.fetch(op)} do not have the same number of result columns"
      end
    end

    # The k-th column's collation info is that of the first select whose k-th result column has one.
    def column_collation_infos
      per_part = @parts.map(&:result_collation_infos)
      per_part.first.each_index.map { |k| per_part.filter_map { |infos| infos[k] }.first }
    end

    # An integer (k-th column) or a name of a result column, looked up in each select in turn; either
    # may be followed by COLLATE, else the term sorts under the column's collation.
    def bind_order_by(terms)
      width = @parts.first.result_columns.length
      terms.each_with_index.map do |term, i|
        expr, collate = Ordering.split_collate(term.expr)
        index = Ordering.ordinal(expr, i, width, "ORDER BY") || name_index(expr)
        unless index
          raise SqlError, "#{Ordering.ordinal_word(i + 1)} ORDER BY term does not match any column in the result set"
        end
        collation = collate ? Collation.lookup(collate) : @collations[index]
        Ordering::SortKey.new(index, nil, term.desc, term.nulls, collation)
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
