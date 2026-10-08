# Entry point: reads a SQL script from standard input and runs it.
require_relative "lib/sql_error"
require_relative "lib/value"
require_relative "lib/token"
require_relative "lib/lexer"
require_relative "lib/ast"
require_relative "lib/parser"
require_relative "lib/database"
require_relative "lib/functions"
require_relative "lib/operators"
require_relative "lib/evaluator"
require_relative "lib/binder"
require_relative "lib/query"
require_relative "lib/executor"
require_relative "lib/interpreter"

MiniSql::Interpreter.new($stdout).run($stdin.read.to_s)
