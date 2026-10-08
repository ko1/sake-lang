# frozen_string_literal: true

require_relative "ast"
require_relative "catalog"
require_relative "data_statements"
require_relative "errors"
require_relative "planner"
require_relative "schema_statements"
require_relative "values"

module Sql
  # Executes parsed statements against one in-memory database. `execute` returns the lines to print
  # (SELECT rows) and raises SqlError for a statement that fails (leaving the database unchanged).
  # The statements are split over DataStatements (INSERT, UPDATE, DELETE) and SchemaStatements
  # (CREATE, DROP, ALTER); SELECT and transactions are here.
  class Executor
    include DataStatements
    include SchemaStatements

    def initialize
      @catalog = Catalog.new
      @snapshot = nil # the catalog as BEGIN found it, while a transaction is open
    end

    def execute(statement)
      case statement
      when Select, Compound, WithQuery then execute_select(statement)
      when Insert then execute_insert(statement)
      when CreateTable then execute_create_table(statement)
      when DropTable then execute_drop_table(statement)
      when CreateView then execute_create_view(statement)
      when DropView then execute_drop_view(statement)
      when CreateIndex then execute_create_index(statement)
      when DropIndex then execute_drop_index(statement)
      when AlterAddColumn then execute_add_column(statement)
      when AlterRenameTable then execute_rename_table(statement)
      when AlterRenameColumn then execute_rename_column(statement)
      when Update then execute_update(statement)
      when Delete then execute_delete(statement)
      when Begin, Commit, Rollback then execute_transaction(statement)
      else raise "unknown statement #{statement.inspect}"
      end
    end

    private

    def planner
      Planner.new(@catalog)
    end

    def execute_select(select)
      planner.plan(select).run.map { |row| row.map { |v| Values.display(v) }.join("|") }
    end

    # BEGIN keeps a copy of the whole database; ROLLBACK goes back to it (5.5).
    def execute_transaction(statement)
      case statement
      when Begin
        raise SqlError, "cannot start a transaction within a transaction" if @snapshot
        @snapshot = @catalog.snapshot
      when Commit
        raise SqlError, "cannot commit - no transaction is active" unless @snapshot
        @snapshot = nil
      when Rollback
        raise SqlError, "cannot rollback - no transaction is active" unless @snapshot
        @catalog.restore(@snapshot)
        @snapshot = nil
      end
      []
    end
  end
end
