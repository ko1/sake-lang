# frozen_string_literal: true

require_relative "compound_plan"
require_relative "evaluator"
require_relative "ordering"
require_relative "recursive_plan"
require_relative "value"

module Sql
  # Running compound selects (spec 5.1) and recursive WITH tables (spec 5.2). The parts run through
  # Query, which requires this file.
  module Compounds
    # The rows of a compound plan: its parts combined left to right, then ORDER BY, LIMIT, OFFSET.
    def self.rows(plan, outer)
      parts = plan.parts
      rows = Query.result_rows(parts.fetch(0), outer)
      plan.ops.each_with_index do |op, i|
        rows = combine(op, rows, Query.result_rows(parts.fetch(i + 1), outer), plan.collations)
      end
      Query.finish(rows, plan.order_by, plan.limit, plan.offset)
    end

    # Rows are equal when their values are equal under the compound's column collations.
    def self.combine(op, left, right, collations)
      case op
      when "UNION ALL" then left + right
      when "UNION" then distinct(left + right, collations)
      when "INTERSECT"
        wanted = keys_of(right, collations)
        distinct(left.select { |row| wanted.key?(key(row, collations)) }, collations)
      else
        unwanted = keys_of(right, collations)
        distinct(left.reject { |row| unwanted.key?(key(row, collations)) }, collations)
      end
    end

    # The rows of a recursive WITH table: a queue starting with the initial rows; each row taken
    # from its front is added to the result and expanded by the recursive select.
    def self.recursive_rows(plan, outer)
      seen = {} #: Hash[Array[value], bool]
      queue = [] #: Array[Array[value]]
      enqueue(queue, seen, Query.result_rows(plan.initial, outer), plan)
      wanted = plan.order_by.empty? ? wanted_rows(plan) : nil
      taken = 0
      while taken < queue.length && (wanted.nil? || taken < wanted)
        plan.feed.rows = [queue.fetch(taken)]
        taken += 1
        enqueue(queue, seen, Query.result_rows(plan.step, outer), plan)
      end
      plan.feed.rows = []
      Query.finish(queue.first(taken), plan.order_by, plan.limit, plan.offset)
    end

    # How many rows LIMIT and OFFSET need, or nil if the whole result is needed.
    def self.wanted_rows(plan)
      limit = Query.bound(plan.limit)
      return nil if limit.nil? || limit < 0

      limit + [Query.bound(plan.offset) || 0, 0].max
    end

    # Appends rows to the queue; with distinct, only those not queued before.
    def self.enqueue(queue, seen, rows, plan)
      rows.each do |row|
        if plan.distinct
          row_key = key(row, plan.collations)
          next if seen.key?(row_key)

          seen[row_key] = true
        end
        queue << row
      end
    end

    # Rows are equal when their values are, NULLs included and TEXT under its column's collation
    # (as in SELECT DISTINCT).
    def self.key(row, collations)
      row.each_with_index.map { |v, i| Value.identity(Value.fold(v, collations.fetch(i))) }
    end

    def self.keys_of(rows, collations)
      keys = {} #: Hash[Array[value], bool]
      rows.each { |row| keys[key(row, collations)] = true }
      keys
    end

    # The first of each set of equal rows.
    def self.distinct(rows, collations)
      seen = {} #: Hash[Array[value], bool]
      rows.select do |row|
        row_key = key(row, collations)
        seen.key?(row_key) ? false : (seen[row_key] = true)
      end
    end
  end
end
