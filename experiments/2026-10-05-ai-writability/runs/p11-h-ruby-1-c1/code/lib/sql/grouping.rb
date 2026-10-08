# frozen_string_literal: true

require_relative "aggregates"
require_relative "collation"
require_relative "evaluator"
require_relative "values"

module Sql
  # Groups of an aggregate query (3.3). A group is turned into a "group row": the values of one
  # representative row of the table followed by the value of each aggregate, so that bound
  # expressions (ColumnRef for bare columns, AggRef for aggregates) evaluate on it unchanged.
  module Grouping
    module_function

    # Arrays of rows. `exprs` are the bound GROUP BY terms, or nil for the single group of a
    # query without GROUP BY (which exists even with no rows).
    def partition(rows, exprs)
      return [rows] unless exprs
      collations = exprs.map { |e| Collation.of(e) }
      rows.group_by do |row|
        exprs.each_with_index.map { |e, i| Values.group_key(Evaluator.evaluate(e, row), collations[i]) }
      end.values
    end

    # `empty_row` stands for the table's values when the group has no rows (bare columns are NULL).
    # `gap` free slots (for the query's window calls) sit between the table's values and the aggregates.
    def group_row(rows, specs, empty_row, gap = 0)
      representative_row(rows, specs, empty_row) + Array.new(gap) + specs.map { |spec| Aggregates.compute(spec, rows) }
    end

    # A bare column reads the row that gave the minimum / maximum when that is the only aggregate.
    def representative_row(rows, specs, empty_row)
      return empty_row if rows.empty?
      if specs.length == 1 && %w[min max].include?(specs[0].name) && !specs[0].star
        index = Aggregates.extreme_row_index(specs[0], rows)
        return rows[index] if index
      end
      rows.first
    end
  end
end
