# frozen_string_literal: true

require_relative "ast"
require_relative "compounds"
require_relative "evaluator"
require_relative "grouping"
require_relative "joins"
require_relative "namespace"
require_relative "ordering"
require_relative "plan"
require_relative "planner"
require_relative "schema"
require_relative "select_plan"
require_relative "table"
require_relative "value"
require_relative "windows"

module Sql
  # Runs a query: filters, groups, projects and sorts the rows, and returns the lines to print.
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
      plan = Planner.build(statement, Namespace.new(catalog), nil)
      result_rows(plan, []).map { |values| values.map { |v| v.nil? ? "NULL" : Value.printed(v) }.join("|") }
    end

    # The result rows of a plan. outer is the row of the enclosing query it is run for (empty at
    # the top level), which the plan's expressions read after their own sources' columns.
    def self.result_rows(plan, outer)
      outer = outer.first(plan.outer_width)
      case plan
      when SelectPlan then select_rows(plan, outer)
      when CompoundPlan then Compounds.rows(plan, outer)
      when RecursivePlan then Compounds.recursive_rows(plan, outer)
      else raise Error, "internal error: unknown plan"
      end
    end

    def self.select_rows(plan, outer)
      entries = entries(plan, source_rows(plan, outer))
      entries = distinct(entries) if plan.distinct
      entries = Ordering.sort(entries, entries.map(&:keys), plan.order_by) unless plan.order_by.empty?
      window(entries, plan.limit, plan.offset).map(&:values)
    end

    # Rows of a compound select after its ORDER BY, LIMIT and OFFSET.
    def self.finish(rows, order_by, limit, offset)
      unless order_by.empty?
        keys = rows.map { |row| order_by.map { |term| Evaluator.evaluate(term.expr, row) } }
        rows = Ordering.sort(rows, keys, order_by)
      end
      window(rows, limit, offset)
    end

    # The items after skipping OFFSET and keeping LIMIT (a negative LIMIT keeps all).
    def self.window(items, limit_expr, offset_expr)
      limit = bound(limit_expr)
      offset = bound(offset_expr)
      items = items.drop([offset || 0, 0].max)
      limit && limit >= 0 ? items.first(limit) : items
    end

    # The rows the result is computed from: the joined rows (each followed by the outer row) that
    # pass WHERE, or the group rows of a plan, with the values of its window calls.
    def self.source_rows(plan, outer)
      rows = Joins.run(plan.from, plan.from.items.map { |item| item_rows(item) }, outer)
      rows = rows.map { |row| row + outer } unless outer.empty?
      where = plan.where
      rows = rows.select { |row| Value.truth(Evaluator.evaluate(where, row)) == true } if where
      rows = Grouping.collapse(plan, rows, outer) if plan.grouped?
      plan.windows.empty? ? rows : with_windows(plan, rows)
    end

    # The rows (of a plan with window calls) extended with the value of each window call.
    def self.with_windows(plan, rows)
      rows = rows.map { |row| row + Array.new(plan.slots.length, nil) } unless plan.grouped?
      Windows.apply(plan.windows, rows)
      rows
    end

    # The rows of a FROM item: a table's, the row being expanded of a recursive WITH table, or what
    # its plan (subquery, view, WITH table) returns (run once, on its own).
    def self.item_rows(item)
      table = item.table
      return table.rows if table

      feed = item.feed
      return feed.rows if feed

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
