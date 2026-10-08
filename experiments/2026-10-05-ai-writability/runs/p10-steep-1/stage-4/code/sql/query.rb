# frozen_string_literal: true

require_relative "ast"
require_relative "evaluator"
require_relative "grouping"
require_relative "joins"
require_relative "ordering"
require_relative "schema"
require_relative "select_plan"
require_relative "table"
require_relative "value"

module Sql
  # Runs a SELECT: filters, groups, projects and sorts the rows, and returns the lines to print.
  module Query
    # A result row with the values its ORDER BY terms evaluate to.
    class Entry
      attr_reader :values, :keys

      def initialize(values, keys)
        @values = values
        @keys = keys
      end
    end

    def self.run(statement, catalog)
      plan = SelectPlan.build(statement, catalog, nil)
      result_rows(plan, []).map { |values| values.map { |v| v.nil? ? "NULL" : Value.text_form(v) }.join("|") }
    end

    # The result rows of a plan. outer is the row of the enclosing query it is run for (empty at
    # the top level), which the plan's expressions read after their own sources' columns.
    def self.result_rows(plan, outer)
      outer = outer.first(plan.outer_width)
      limit = bound(plan.limit)
      offset = bound(plan.offset)
      entries = entries(plan, source_rows(plan, outer))
      entries = distinct(entries) if plan.distinct
      entries = Ordering.sort(entries, entries.map(&:keys), plan.order_by) unless plan.order_by.empty?
      entries = entries.drop([offset || 0, 0].max)
      entries = entries.first(limit) if limit && limit >= 0
      entries.map(&:values)
    end

    # The rows the result is computed from: the joined rows (each followed by the outer row) that
    # pass WHERE, or the group rows of a plan.
    def self.source_rows(plan, outer)
      rows = Joins.run(plan.from, plan.from.items.map { |item| item_rows(item) }, outer)
      rows = rows.map { |row| row + outer } unless outer.empty?
      where = plan.where
      rows = rows.select { |row| Value.truth(Evaluator.evaluate(where, row)) == true } if where
      plan.grouped? ? Grouping.collapse(plan, rows, outer) : rows
    end

    # The rows of a FROM item: a table's, or what its subquery returns (run once, on its own).
    def self.item_rows(item)
      table = item.table
      return table.rows if table

      plan = item.plan
      plan ? result_rows(plan, []) : []
    end

    def self.entries(plan, rows)
      rows.map do |row|
        Entry.new(plan.results.map { |expr| Evaluator.evaluate(expr, row) },
                  plan.order_by.map { |term| Evaluator.evaluate(term.expr, row) })
      end
    end

    # The first of each set of entries whose result values are equal (NULLs equal).
    def self.distinct(entries)
      seen = {} #: Hash[Array[value], bool]
      entries.select do |entry|
        key = entry.values.map { |v| Value.identity(v) }
        seen.key?(key) ? false : (seen[key] = true)
      end
    end

    # The integer a LIMIT or OFFSET expression evaluates to, or nil without one.
    def self.bound(expr)
      return nil unless expr

      value = Evaluator.evaluate(expr, [])
      return nil if value.nil?

      Value.to_number(value).to_i
    end
  end
end
