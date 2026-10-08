# frozen_string_literal: true

require_relative "errors"
require_relative "executor"
require_relative "lexer"
require_relative "parser"

module Sql
  # Runs a whole script: splits it into statements, parses and executes each in turn, and collects
  # the output lines (SELECT rows and `Error: ...` lines).
  class Script
    def initialize
      @executor = Executor.new
    end

    # Yields each output line as soon as it is known.
    def run(source)
      Lexer.split_statements(Lexer.tokenize(source)).each do |tokens|
        run_statement(tokens) { |line| yield line }
      end
    end

    private

    def run_statement(tokens)
      @executor.execute(Parser.parse(tokens)).each { |line| yield line }
    rescue SqlError => e
      yield "Error: #{e.message}"
    rescue StandardError => e
      # an engine bug: keep the script going, and keep stdout to what the script is owed
      warn "internal error: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    end
  end
end
