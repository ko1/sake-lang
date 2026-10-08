# frozen_string_literal: true

require_relative "binder"
require_relative "errors"
require_relative "evaluator"
require_relative "scope"
require_relative "values"

module Sql
  # INSERT, UPDATE and DELETE (1.6, 2.2, 5.4), mixed into Executor (which has @catalog and #planner).
  module DataStatements
    private

    def execute_insert(stmt)
      source = stmt.query ? select_source(stmt) : values_source(stmt)
      table = @catalog.fetch_writable_table(stmt.table)
      rows = source.call
      targets = insert_targets(stmt, table, rows.width)
      table.atomically do
        rows.each do |values|
          raw = table.default_row
          values.each_with_index { |value, i| raw[targets[i]] = value }
          table.insert(raw)
        end
      end
      []
    end

    # The rows an INSERT stores: how wide they are, and (a lambda, so that names are bound only
    # after the column list is checked) the rows themselves.
    InsertRows = Data.define(:width, :rows) do
      def each(&block) = rows.call.each(&block)
    end

    # VALUES rows: checked first, evaluated one at a time as they are stored.
    def values_source(stmt)
      width = stmt.rows.first.length
      raise SqlError, "all VALUES must have the same number of terms" unless stmt.rows.all? { |r| r.length == width }
      lambda do
        InsertRows.new(width, lambda do
          scope = Scope.new(planner: planner)
          bound = stmt.rows.map { |exprs| exprs.map { |e| Binder.bind(e, scope) } }
          bound.lazy.map { |exprs| exprs.map { |e| Evaluator.evaluate(e, []) } }
        end)
      end
    end

    # INSERT ... SELECT: the select is fully computed before the first row is stored.
    def select_source(stmt)
      lambda do
        query = planner.plan(stmt.query)
        InsertRows.new(query.result_columns.length, -> { query.run })
      end
    end

    def execute_update(stmt)
      table = @catalog.fetch_writable_table(stmt.table)
      scope = Scope.for_table(table, planner)
      assignments = {} # column position => bound expression; the last assignment to a column wins
      stmt.assignments.each do |name, expr|
        index = table.column_index(name) or raise SqlError, "no such column: #{name}"
        assignments[index] = Binder.bind(expr, scope)
      end
      where = stmt.where && Binder.bind(stmt.where, scope)
      table.atomically do
        matching_rows(table, where).each do |row|
          raw = row.dup
          assignments.each { |index, expr| raw[index] = Evaluator.evaluate(expr, row) }
          table.update(row, raw)
        end
      end
      []
    end

    def execute_delete(stmt)
      table = @catalog.fetch_writable_table(stmt.table)
      where = stmt.where && Binder.bind(stmt.where, Scope.for_table(table, planner))
      table.delete(matching_rows(table, where))
      []
    end

    # The rows of the table (a snapshot) for which `where` (bound, or nil) is true.
    def matching_rows(table, where)
      return table.rows.dup unless where
      table.rows.select { |row| Values.truth(Evaluator.evaluate(where, row)) }
    end

    # Column positions the values of each row go to.
    def insert_targets(stmt, table, width)
      if stmt.columns.nil?
        unless width == table.columns.length
          raise SqlError, "table #{stmt.table} has #{table.columns.length} columns but #{width} values were supplied"
        end
        return (0...width).to_a
      end
      targets = stmt.columns.map do |name|
        table.column_index(name) or raise SqlError, "table #{stmt.table} has no column named #{name}"
      end
      raise SqlError, "#{width} values for #{targets.length} columns" unless width == targets.length
      targets
    end
  end
end
