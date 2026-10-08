# frozen_string_literal: true

require_relative 'ast'
require_relative 'compiler'
require_relative 'errors'
require_relative 'scope'
require_relative 'namespace'
require_relative 'query_planner'
require_relative 'schema_changes'
require_relative 'values'

module SQL
  # Runs parsed statements against a Catalog. `execute` returns the lines to print; `namespace` carries
  # the WITH tables of the statement (5.2).
  class Executor
    def initialize(catalog)
      @catalog = catalog
      @schema = SchemaChanges.new(catalog)
    end

    def execute(stmt, namespace = Namespace.new(@catalog))
      case stmt
      when Select, Compound then QueryPlanner.plan(stmt, namespace).run
      when Insert then insert(stmt, namespace)
      when Update then update(stmt)
      when Delete then delete(stmt)
      when WithClause then execute_with(stmt, namespace)
      else execute_other(stmt)
      end
    end

    private

    # The statements that return no rows: schema changes (5.3, 5.6, 5.7) and transactions (5.5).
    def execute_other(stmt)
      case stmt
      when CreateTable then @schema.create_table(stmt)
      when DropTable then @schema.drop_table(stmt)
      when CreateView then @schema.create_view(stmt)
      when DropView then @schema.drop_view(stmt)
      when CreateIndex then @schema.create_index(stmt)
      when DropIndex then @schema.drop_index(stmt)
      when AddColumn then @schema.add_column(stmt)
      when RenameTable then @schema.rename_table(stmt)
      when RenameColumn then @schema.rename_column(stmt)
      when Begin then @catalog.begin_transaction
      when Commit then @catalog.commit
      when Rollback then @catalog.rollback
      end
      []
    end

    def execute_with(stmt, namespace)
      namespace = QueryPlanner.bind_ctes(stmt, namespace)
      stmt.body.is_a?(Insert) ? insert(stmt.body, namespace) : QueryPlanner.plan(stmt.body, namespace).run
    end

    # --- INSERT -------------------------------------------------------------------------

    def insert(stmt, namespace)
      table = writable_table(stmt.table)
      targets = insert_targets(stmt, table)
      rows =
        if stmt.query
          query = QueryPlanner.plan(stmt.query, namespace)
          check_value_count(stmt, table, targets, query.width)
          query.rows
        else
          width = stmt.rows.first.size
          raise SqlError, 'all VALUES must have the same number of terms' if stmt.rows.any? { |r| r.size != width }

          check_value_count(stmt, table, targets, width)
          compiler = Compiler.new(Scope.empty(namespace))
          stmt.rows.map { |exprs| exprs.map { |e| compiler.compile(e).fn.call(nil) } }
        end
      table.insert_rows(targets, rows)
      []
    end

    # The table to change; a view cannot be (5.3).
    def writable_table(name)
      if (view = @catalog.find_view(name))
        raise SqlError, "cannot modify #{view.name} because it is a view"
      end

      @catalog.fetch(name)
    end

    # Column indexes the VALUES positions go to.
    def insert_targets(stmt, table)
      return table.columns.each_index.to_a unless stmt.columns

      stmt.columns.map do |name|
        table.column_index(name) || table.rowid_target(name) or
          raise SqlError, "table #{stmt.table} has no column named #{name}"
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
      table = writable_table(stmt.table)
      compiler = Compiler.new(Scope.for_table(table, Namespace.new(@catalog)))
      assignments = stmt.assignments.map do |name, expr|
        index = table.column_index(name) || table.rowid_target(name) or raise SqlError, "no such column: #{name}"
        [index, compiler.compile(expr).fn]
      end
      table.update_rows(row_filter(compiler, stmt.where),
                        ->(row) { assignments.map { |index, fn| [index, fn.call(row)] } })
      []
    end

    def delete(stmt)
      table = writable_table(stmt.table)
      table.delete_rows(row_filter(Compiler.new(Scope.for_table(table, Namespace.new(@catalog))), stmt.where))
      []
    end

    # A predicate on rows: WHERE is true (1.10); every row without WHERE.
    def row_filter(compiler, where)
      return ->(_row) { true } unless where

      fn = compiler.compile(where).fn
      ->(row) { Values.truth(fn.call(row)) == true }
    end
  end
end
