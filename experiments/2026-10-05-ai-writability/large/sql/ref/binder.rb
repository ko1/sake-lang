require_relative "errors"
require_relative "ast"
require_relative "expressions"
require_relative "functions"

# Resolves the names in a syntax-tree expression and returns the bound expression (Expressions).
# All name and function errors are raised here, before any row is read.
class Binder
  # columns: the table's columns in scope (Table::Column), empty for no row;
  # aliases: name (downcased) => bound expression, consulted when no column matches.
  Scope = Struct.new(:columns, :aliases) do
    def self.empty = new([], {})

    def resolve(name)
      key = name.downcase
      index = columns.index { |column| column.name.downcase == key }
      return Expressions::ColumnRef.new(index, columns[index].type) if index
      aliases.fetch(key) { raise SqlError, "no such column: #{name}" }
    end
  end

  def self.bind(expr, scope)
    new(scope).bind(expr)
  end

  def initialize(scope)
    @scope = scope
  end

  def bind(expr)
    case expr
    when AST::Literal then Expressions::Constant.new(expr.value)
    when AST::Name then @scope.resolve(expr.name)
    when AST::Paren then bind(expr.expr)
    when AST::Unary then bind_unary(expr)
    when AST::Binary then bind_binary(expr)
    when AST::Call
      function = Functions.lookup(expr.name, expr.args.length)
      Expressions::FunctionCall.new(function, expr.args.map { |arg| bind(arg) })
    else raise ArgumentError, "unknown expression #{expr.inspect}"
    end
  end

  private

  def bind_unary(expr)
    operand = bind(expr.operand)
    case expr.op
    when "-" then Expressions::Negate.new(operand)
    when "+" then Expressions::Identity.new(operand)
    when "NOT" then Expressions::Not.new(operand)
    end
  end

  def bind_binary(expr)
    left = bind(expr.left)
    right = bind(expr.right)
    case expr.op
    when "AND" then Expressions::And.new(left, right)
    when "OR" then Expressions::Or.new(left, right)
    when "||" then Expressions::Concat.new(left, right)
    when "+", "-", "*", "/", "%" then Expressions::Arithmetic.new(expr.op, left, right)
    else Expressions::Comparison.new(expr.op, left, right)
    end
  end
end
