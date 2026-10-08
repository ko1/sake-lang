# frozen_string_literal: true

require_relative "ast"
require_relative "catalog"
require_relative "errors"
require_relative "evaluator"
require_relative "query"
require_relative "binder"
require_relative "values"

module Sql
  # Executes parsed statements against one in-memory database. `execute` returns the lines to print
  # (SELECT rows) and raises SqlError for a statement that fails (leaving the database unchanged).
  class Executor
    def initialize
      @catalog = Catalog.new
    end

    def execute(statement)
      case statement
      when Select then execute_select(statement)
      when Insert then execute_insert(statement)
      when CreateTable then execute_create(statement)
      when DropTable then execute_drop(statement)
      when Update then execute_update(statement)
      when Delete then execute_delete(statement)
      else raise "unknown statement #{statement.inspect}"
      end
    end

    private

    def planner
      Query.planner(@catalog)
    end

    def execute_select(select)
      Query.new(@catalog, select).run.map { |row| row.map { |v| Values.display(v) }.join("|") }
    end

    def execute_create(stmt)
      if @catalog.table(stmt.name)
        return [] if stmt.if_not_exists
        raise SqlError, "table #{stmt.name} already exists"
      end
      seen = {}
      stmt.columns.each do |c|
        key = Sql.fold(c.name)
        raise SqlError, "duplicate column name: #{c.name}" if seen[key]
        seen[key] = true
      end
      @catalog.add(build_table(stmt))
      []
    end

    # The Table for a CREATE TABLE: columns with their NOT NULL / DEFAULT, and the UNIQUE and
    # PRIMARY KEY constraints in declaration order (column constraints, then table constraints).
    def build_table(stmt)
      positions = {}
      stmt.columns.each_with_index { |c, i| positions[Sql.fold(c.name)] = i }
      groups = [] # [column positions, primary key?]
      stmt.columns.each_with_index do |c, i|
        groups << [[i], true] if c.primary_key
        groups << [[i], false] if c.unique
      end
      stmt.constraints.each do |tc|
        cols = tc.columns.map { |name| positions[Sql.fold(name)] or raise SqlError, "no such column: #{name}" }
        groups << [cols, tc.kind == :primary_key]
      end
      key_columns = groups.select(&:last).flat_map(&:first)
      columns = stmt.columns.each_with_index.map do |c, i|
        TableColumn.new(c.name, c.type, c.not_null || key_columns.include?(i), c.default&.value)
      end
      Table.new(stmt.name, columns, groups.map { |cols, primary| UniqueConstraint.new(cols, primary) })
    end

    def execute_drop(stmt)
      unless @catalog.table(stmt.name)
        return [] if stmt.if_exists
        raise SqlError, "no such table: #{stmt.name}"
      end
      @catalog.drop(stmt.name)
      []
    end

    def execute_insert(stmt)
      width = stmt.rows.first.length
      raise SqlError, "all VALUES must have the same number of terms" unless stmt.rows.all? { |r| r.length == width }
      table = @catalog.fetch_table(stmt.table)
      targets = insert_targets(stmt, table, width)
      scope = Scope.new(planner: planner)
      bound = stmt.rows.map { |exprs| exprs.map { |e| Binder.bind(e, scope) } }
      table.atomically do
        bound.each do |exprs|
          raw = table.default_row
          exprs.each_with_index { |expr, i| raw[targets[i]] = Evaluator.evaluate(expr, []) }
          table.insert(raw)
        end
      end
      []
    end

    def execute_update(stmt)
      table = @catalog.fetch_table(stmt.table)
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
      table = @catalog.fetch_table(stmt.table)
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
