# frozen_string_literal: true

require_relative "ast"
require_relative "evaluator"
require_relative "grouping"
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
      table = statement.table ? catalog.fetch(statement.table) : nil
      plan = SelectPlan.build(statement, table)
      limit = bound(plan.limit)
      offset = bound(plan.offset)
      entries = entries(plan, source_rows(plan, table))
      entries = distinct(entries) if plan.distinct
      entries = Ordering.sort(entries, entries.map(&:keys), plan.order_by) unless plan.order_by.empty?
      entries = entries.drop([offset || 0, 0].max)
      entries = entries.first(limit) if limit && limit >= 0
      entries.map { |entry| entry.values.map { |v| v.nil? ? "NULL" : Value.text_form(v) }.join("|") }
    end

    # The rows the result is computed from: those passing WHERE, or the group rows of a plan.
    def self.source_rows(plan, table)
      rows = table ? table.rows : [[]] #: Array[Array[value]]
      where = plan.where
      rows = rows.select { |row| Value.truth(Evaluator.evaluate(where, row)) == true } if where
      plan.grouped? ? Grouping.collapse(plan, rows) : rows
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
