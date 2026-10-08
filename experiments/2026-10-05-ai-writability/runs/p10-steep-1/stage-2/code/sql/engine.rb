# frozen_string_literal: true

require_relative "ast"
require_relative "error"
require_relative "lexer"
require_relative "modify"
require_relative "parser"
require_relative "query"
require_relative "schema"
require_relative "table"

module Sql
  # One in-memory database. execute runs a statement and returns the lines it prints.
  class Engine
    def initialize
      @catalog = Catalog.new
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
      when Ast::CreateTable then create_table(statement)
      when Ast::DropTable then drop_table(statement)
      when Ast::Insert then modify { Modify.insert(statement, @catalog) }
      when Ast::Update then modify { Modify.update(statement, @catalog) }
      when Ast::Delete then modify { Modify.delete(statement, @catalog) }
      when Ast::Select then Query.run(statement, @catalog)
      else raise Error, "internal error: unknown statement"
      end
    end

    private

    NO_LINES = Array.new(0, "").freeze

    # Statements that change data print nothing.
    def modify
      yield
      NO_LINES
    end

    def create_table(statement)
      if @catalog.find(statement.name)
        return NO_LINES if statement.if_not_exists

        raise Error, "table #{statement.name} already exists"
      end
      @catalog.add(Table.from_statement(statement))
      NO_LINES
    end

    def drop_table(statement)
      if @catalog.find(statement.name)
        @catalog.remove(statement.name)
      elsif !statement.if_exists
        raise Error, "no such table: #{statement.name}"
      end
      NO_LINES
    end
  end
end
