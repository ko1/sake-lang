# Mini: reads a program from standard input and runs it (see ../SPEC.md).
#
#   ruby main.rb < program.mini           run it
#   ruby main.rb --tokens < program.mini  print its tokens instead
#   ruby main.rb --ast < program.mini     print its resolved AST instead
#
# Output and error reports both go to standard output; the exit status is 0.

require_relative "errors"
require_relative "tokens"
require_relative "lexer"
require_relative "ast"
require_relative "parser"
require_relative "values"
require_relative "format"
require_relative "builtins"
require_relative "resolver"
require_relative "environment"
require_relative "operators"
require_relative "interpreter"
require_relative "debug"

# mode is "run", "tokens" or "ast".
def run_mini(source, mode)
  tokens = Lexer.new(source).run
  if mode == "tokens"
    Debug.tokens(tokens).each { |line| puts(line) }
    return
  end
  program = Parser.new(tokens).parse_program
  Resolver.new.resolve_program(program)
  if mode == "ast"
    puts(Debug.program(program))
    return
  end
  Interpreter.new.run(program)
rescue MiniCompileError => e
  puts(e.report)
rescue MiniRuntimeError => e
  puts(e.report)
rescue MiniThrow => e
  puts(Errors.uncaught_throw_report(e))
end

def main(args)
  mode =
    case args
    in [] then "run"
    in ["--tokens"] then "tokens"
    in ["--ast"] then "ast"
    else
      puts("usage: ruby main.rb [--tokens | --ast] < program.mini")
      return
    end
  run_mini($stdin.read, mode)
end

main(ARGV)
