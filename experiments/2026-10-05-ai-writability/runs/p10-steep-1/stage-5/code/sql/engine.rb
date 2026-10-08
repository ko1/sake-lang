# frozen_string_literal: true

require_relative "ast"
require_relative "catalog"
require_relative "ddl"
require_relative "error"
require_relative "lexer"
require_relative "modify"
require_relative "parser"
require_relative "query"

module Sql
  # One in-memory database. execute runs a statement and returns the lines it prints.
  class Engine
    NO_LINES = Array.new(0, "").freeze

    def initialize
      @catalog = Catalog.new
      @saved = nil #: Catalog?
    end

    # Runs a whole script, writing each statement's output (or "Error: ...") to out.
    def run_script(source, out)
      Lexer.new(source).statements.each do |tokens|
        begin
          statement = Parser.new(tokens).parse_statement
          execute(statement).each { |line| out.puts(line) } if statement
        rescue Error => e
          out.puts("Error: #{e.message}")
        end
      end
    end

    def execute(statement)
      case statement
      when Ast::Query then Query.run(statement, @catalog)
      when Ast::Insert then modify { Modify.insert(statement, @catalog) }
      when Ast::Update then modify { Modify.update(statement, @catalog) }
      when Ast::Delete then modify { Modify.delete(statement, @catalog) }
      when Ast::Transaction then modify { transaction(statement.kind) }
      else modify { execute_ddl(statement) }
      end
    end

    private

    # Statements that change data or the schema print nothing.
    def modify
      yield
      NO_LINES
    end

    def execute_ddl(statement)
      case statement
      when Ast::CreateTable then Ddl.create_table(statement, @catalog)
      when Ast::DropTable then Ddl.drop_table(statement, @catalog)
      when Ast::CreateView then Ddl.create_view(statement, @catalog)
      when Ast::DropView then Ddl.drop_view(statement, @catalog)
      when Ast::CreateIndex then Ddl.create_index(statement, @catalog)
      when Ast::DropIndex then Ddl.drop_index(statement, @catalog)
      when Ast::AddColumn then Ddl.add_column(statement, @catalog)
      when Ast::RenameTable then Ddl.rename_table(statement, @catalog)
      when Ast::RenameColumn then Ddl.rename_column(statement, @catalog)
      else raise Error, "internal error: unknown statement"
      end
    end

    # BEGIN keeps a copy of the catalog; ROLLBACK goes back to it. A transaction is the catalog
    # between those two, so every kind of change (data, tables, views, indexes) is undone alike.
    def transaction(kind)
      saved = @saved
      case kind
      when :begin
        raise Error, "cannot start a transaction within a transaction" if saved

        @saved = @catalog.copy
      when :commit
        raise Error, "cannot commit - no transaction is active" unless saved

        @saved = nil
      else
        raise Error, "cannot rollback - no transaction is active" unless saved

        @catalog = saved
        @saved = nil
      end
    end
  end
end
