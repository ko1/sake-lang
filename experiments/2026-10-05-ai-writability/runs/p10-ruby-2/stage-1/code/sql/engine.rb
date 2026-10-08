# frozen_string_literal: true

require_relative 'errors'
require_relative 'executor'
require_relative 'lexer'
require_relative 'parser'
require_relative 'storage'

module SQL
  # One in-memory database fed with a script: split into statements, then for each statement
  # tokenize, parse and execute. A SqlError is printed as `Error: <message>` and the script goes on.
  class Engine
    def initialize(out)
      @out = out
      @executor = Executor.new(Catalog.new)
    end

    def run_script(script)
      Lexer.split_statements(script).each { |text| run_statement(text) }
      @out.flush
    end

    private

    def run_statement(text)
      stmt = Parser.parse(Lexer.tokenize(text))
      return unless stmt

      @executor.execute(stmt).each { |line| @out.puts(line) }
    rescue SqlError => e
      @out.puts("Error: #{e.message}")
    end
  end
end
