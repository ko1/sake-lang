# frozen_string_literal: true

require_relative "aggregates"
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
      rows.group_by { |row| exprs.map { |e| Values.group_key(Evaluator.evaluate(e, row)) } }.values
    end

    def group_row(rows, specs, width)
      representative_row(rows, specs, width) + specs.map { |spec| Aggregates.compute(spec, rows) }
    end

    # A bare column reads the row that gave the minimum / maximum when that is the only aggregate.
    def representative_row(rows, specs, width)
      return Array.new(width) if rows.empty?
      if specs.length == 1 && %w[min max].include?(specs[0].name) && !specs[0].star
        index = Aggregates.extreme_row_index(specs[0], rows)
        return rows[index] if index
      end
      rows.first
    end
  end
end
