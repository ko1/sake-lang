# frozen_string_literal: true

require_relative "ast"
require_relative "evaluator"
require_relative "schema"
require_relative "select_plan"
require_relative "table"
require_relative "value"

module Sql
  # Runs a SELECT: filters, projects and sorts the rows, and returns the lines to print.
  module Query
    # A result row with the values its ORDER BY terms evaluate to and its input position.
    class Entry
      attr_reader :values, :keys, :index

      def initialize(values, keys, index)
        @values = values
        @keys = keys
        @index = index
      end
    end

    def self.run(statement, catalog)
      table = statement.table ? catalog.fetch(statement.table) : nil
      plan = SelectPlan.build(statement, table)
      limit = bound(plan.limit)
      offset = bound(plan.offset)
      rows = table ? table.rows : [[]] #: Array[Array[value]]
      where = plan.where
      rows = rows.select { |row| Value.truth(Evaluator.evaluate(where, row)) == true } if where
      entries = rows.each_with_index.map do |row, i|
        Entry.new(plan.results.map { |expr| Evaluator.evaluate(expr, row) },
                  plan.order_by.map { |term| Evaluator.evaluate(term.expr, row) }, i)
      end
      entries = entries.sort { |a, b| compare_entries(a, b, plan.order_by) } unless plan.order_by.empty?
      entries = entries.drop([offset || 0, 0].max)
      entries = entries.first(limit) if limit && limit >= 0
      entries.map { |entry| entry.values.map { |v| v.nil? ? "NULL" : Value.text_form(v) }.join("|") }
    end

    # The integer a LIMIT or OFFSET expression evaluates to, or nil without one.
    def self.bound(expr)
      return nil unless expr

      value = Evaluator.evaluate(expr, [])
      return nil if value.nil?

      Value.to_number(value).to_i
    end

    def self.compare_entries(left, right, terms)
      terms.each_with_index do |term, i|
        c = compare_keys(left.keys.fetch(i), right.keys.fetch(i), term)
        return c unless c == 0
      end
      left.index < right.index ? -1 : 1
    end

    def self.compare_keys(a, b, term)
      return 0 if a.nil? && b.nil?

      if a.nil? || b.nil?
        nulls_first = term.nulls_first.nil? ? !term.descending : term.nulls_first
        return a.nil? == nulls_first ? -1 : 1
      end
      c = Value.compare(a, b)
      term.descending ? -c : c
    end
  end
end
