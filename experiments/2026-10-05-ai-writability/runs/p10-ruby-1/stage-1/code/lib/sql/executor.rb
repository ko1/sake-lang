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
      else raise "unknown statement #{statement.inspect}"
      end
    end

    private

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
      @catalog.add(Table.new(stmt.name, stmt.columns.map { |c| TableColumn.new(c.name, c.type) }))
      []
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
      scope = Scope.new
      new_rows = stmt.rows.map do |exprs|
        row = Array.new(table.columns.length)
        exprs.each_with_index do |expr, i|
          value = Evaluator.evaluate(Binder.bind(expr, scope), [])
          row[targets[i]] = table.coerce(targets[i], value)
        end
        row
      end
      table.append_rows(new_rows)
      []
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
