# frozen_string_literal: true

require_relative "evaluator"
require_relative "from_plan"
require_relative "value"

module Sql
  # Combines the rows of the sources of a FROM (spec 4.1): nested loops, joining to the left.
  module Joins
    # The joined rows. row_sets holds the rows of each source in FROM order. outer is the row of
    # the enclosing query, which a condition may read (it follows the joined columns).
    def self.run(from, row_sets, outer)
      return [[]] unless from.first

      rows = row_sets.fetch(0)
      from.joins.each_with_index do |join, i|
        rows = join_rows(join, rows, row_sets.fetch(i + 1), outer)
      end
      rows
    end

    # Every left row with each right row the condition accepts; a LEFT join keeps a left row with
    # no match once, followed by NULLs.
    def self.join_rows(join, left_rows, right_rows, outer)
      condition = join.condition
      padding = Array.new(join.item.source.width, nil) #: Array[value]
      joined = [] #: Array[Array[value]]
      left_rows.each do |left|
        matched = false
        right_rows.each do |right|
          row = left + right
          next unless accepts?(condition, outer.empty? ? row : row + outer)

          matched = true
          joined << row
        end
        joined << (left + padding) if join.kind == :left && !matched
      end
      joined
    end

    def self.accepts?(condition, row)
      condition.nil? || Value.truth(Evaluator.evaluate(condition, row)) == true
    end
  end
end
