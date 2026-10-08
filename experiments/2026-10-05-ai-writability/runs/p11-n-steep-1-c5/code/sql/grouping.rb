# frozen_string_literal: true

require_relative "aggregates"
require_relative "ast"
require_relative "evaluator"
require_relative "ordering"
require_relative "value"

module Sql
  # GROUP BY and HAVING (spec 3.3): turns the rows that passed WHERE into one row per group.
  # A group's row is a representative row of the table followed by the values of the plan's
  # aggregate calls (and room for its window calls), which is what the plan's expressions are
  # resolved against.
  module Grouping
    # outer is the enclosing query's row that the rows end with (empty at the top level).
    def self.collapse(plan, rows, outer)
      groups = plan.group_by.empty? ? [rows] : partition(plan.group_by, rows)
      collapsed = groups.map { |group| group_row(plan, group, outer) }
      having = plan.having
      return collapsed unless having

      collapsed.select { |row| Value.truth(Evaluator.evaluate(having, row)) == true }
    end

    # The rows split by their GROUP BY values (NULLs equal), groups in the order of those values.
    def self.partition(terms, rows)
      buckets = {} #: Hash[Array[value], Array[Array[value]]]
      rows.each do |row|
        key = terms.map { |term| Value.identity(Evaluator.evaluate(term, row)) }
        bucket = buckets[key]
        if bucket
          bucket << row
        else
          buckets[key] = [row]
        end
      end
      buckets.keys.sort { |a, b| Ordering.compare_lists(a, b) }.map { |key| buckets.fetch(key) }
    end

    def self.group_row(plan, group, outer)
      representative(plan, group, outer) + plan.slots.map { |slot| slot.is_a?(Ast::Aggregate) ? Aggregates.compute(slot, group) : nil }
    end

    # The row bare columns read: NULLs (then the outer row) for an empty group; the min/max row
    # when the query's only aggregate is a min or max; else the first.
    def self.representative(plan, group, outer)
      return Array.new(plan.local_width, nil) + outer if group.empty?

      only = plan.aggregates.length == 1 ? plan.aggregates.fetch(0) : nil
      only && Aggregates.picks_row?(only) ? Aggregates.extreme_row(only, group) : group.fetch(0)
    end
  end
end
