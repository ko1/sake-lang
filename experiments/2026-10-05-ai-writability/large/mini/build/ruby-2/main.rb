# Mini interpreter: reads a program from standard input and runs it.
#
#   ruby main.rb [--tokens | --ast] < program.mini
#
# Everything, including error reports, goes to standard output; the exit
# status is always 0.

require_relative "lexer"
require_relative "parser"
require_relative "checker"
require_relative "interpreter"
require_relative "debug_print"

module Mini
  USAGE = "usage: ruby main.rb [--tokens | --ast] < program.mini"

  def self.main(argv, input, out)
    mode = argv.empty? ? :run : { "--tokens" => :tokens, "--ast" => :ast }[argv[0]]
    if mode.nil? || argv.length > 1
      out << USAGE << "\n"
      return
    end

    source = input.read.force_encoding(Encoding::UTF_8)
    tokens = Lexer.tokenize(source)
    return out << DebugPrint.tokens(tokens) if mode == :tokens

    program = Parser.parse_program(tokens)
    Checker.check(program)
    return out << DebugPrint.program(program) if mode == :ast

    Interpreter.new(out).run(program)
  rescue Error, RuntimeError => e
    out << e.report << "\n"
  end
end

if $PROGRAM_NAME == __FILE__
  output = +""
  Mini.main(ARGV, $stdin, output)
  $stdout.write(output)
end
