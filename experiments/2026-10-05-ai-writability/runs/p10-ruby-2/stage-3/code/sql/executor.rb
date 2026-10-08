# frozen_string_literal: true

require_relative 'ast'
require_relative 'compiler'
require_relative 'errors'
require_relative 'select_query'
require_relative 'storage'
require_relative 'values'

module SQL
  # Runs parsed statements against a Catalog. `execute` returns the lines to print.
  class Executor
    def initialize(catalog)
      @catalog = catalog
    end

    def execute(stmt)
      case stmt
      when CreateTable then create_table(stmt)
      when DropTable then drop_table(stmt)
      when Insert then insert(stmt)
      when Select then select(stmt)
      when Update then update(stmt)
      when Delete then delete(stmt)
      end
    end

    private

    # --- DDL ----------------------------------------------------------------------------

    def create_table(stmt)
      if @catalog.find(stmt.name)
        return [] if stmt.if_not_exists

        raise SqlError, "table #{stmt.name} already exists"
      end
      seen = {}
      stmt.columns.each do |c|
        raise SqlError, "duplicate column name: #{c.name}" if seen[c.name.downcase]

        seen[c.name.downcase] = true
      end
      @catalog.add(Table.define(stmt))
      []
    end

    def drop_table(stmt)
      if @catalog.find(stmt.name)
        @catalog.drop(stmt.name)
      elsif !stmt.if_exists
        raise SqlError, "no such table: #{stmt.name}"
      end
      []
    end

    # --- INSERT -------------------------------------------------------------------------

    def insert(stmt)
      table = @catalog.fetch(stmt.table)
      targets = insert_targets(stmt, table)
      width = stmt.rows.first.size
      raise SqlError, 'all VALUES must have the same number of terms' if stmt.rows.any? { |r| r.size != width }

      check_value_count(stmt, table, targets, width)
      compiler = Compiler.new(Scope::EMPTY)
      rows = stmt.rows.map { |exprs| exprs.map { |e| compiler.compile(e).fn.call(nil) } }
      table.insert_rows(targets, rows)
      []
    end

    # Column indexes the VALUES positions go to.
    def insert_targets(stmt, table)
      return table.columns.each_index.to_a unless stmt.columns

      stmt.columns.map do |name|
        table.column_index(name) or raise SqlError, "table #{stmt.table} has no column named #{name}"
      end
    end

    def check_value_count(stmt, table, targets, width)
      return if width == targets.size

      if stmt.columns
        raise SqlError, "#{width} values for #{targets.size} columns"
      else
        raise SqlError, "table #{stmt.table} has #{table.columns.size} columns but #{width} values were supplied"
      end
    end

    # --- UPDATE / DELETE ----------------------------------------------------------------

    def update(stmt)
      table = @catalog.fetch(stmt.table)
      compiler = Compiler.new(Scope.new(table))
      assignments = stmt.assignments.map do |name, expr|
        index = table.column_index(name) or raise SqlError, "no such column: #{name}"
        [index, compiler.compile(expr).fn]
      end
      table.update_rows(row_filter(compiler, stmt.where),
                        ->(row) { assignments.map { |index, fn| [index, fn.call(row)] } })
      []
    end

    def delete(stmt)
      table = @catalog.fetch(stmt.table)
      table.delete_rows(row_filter(Compiler.new(Scope.new(table)), stmt.where))
      []
    end

    # A predicate on rows: WHERE is true (1.10); every row without WHERE.
    def row_filter(compiler, where)
      return ->(_row) { true } unless where

      fn = compiler.compile(where).fn
      ->(row) { Values.truth(fn.call(row)) == true }
    end

    # --- SELECT -------------------------------------------------------------------------

    def select(stmt) = SelectQuery.new(stmt, @catalog).run
  end
end
