# frozen_string_literal: true

# Mini interpreter: reads a program from standard input and runs it.
#
#   ruby main.rb [--tokens | --ast] < program.mini
#
# Everything, including error reports, goes to standard output; the exit
# status is always 0 (SPEC section 1).

require_relative "errors"
require_relative "lexer"
require_relative "parser"
require_relative "checker"
require_relative "interpreter"
require_relative "debug_output"

module Mini
  USAGE = "usage: ruby main.rb [--tokens | --ast] < program.mini"

  def self.main(argv, input, output)
    mode = { [] => :run, ["--tokens"] => :tokens, ["--ast"] => :ast }[argv]
    return output.puts(USAGE) if mode.nil?

    source = input.read.force_encoding(Encoding::UTF_8)
    tokens = Lexer.new(source).tokenize
    return DebugOutput.write_tokens(tokens, output) if mode == :tokens

    program = Parser.new(tokens).parse_program
    Checker.new.check(program)
    return DebugOutput.write_ast(program, output) if mode == :ast

    Interpreter.new(output).run(program)
  rescue Mini::Error => e
    output.puts(e.report)
  end
end

Mini.main(ARGV, $stdin, $stdout)
