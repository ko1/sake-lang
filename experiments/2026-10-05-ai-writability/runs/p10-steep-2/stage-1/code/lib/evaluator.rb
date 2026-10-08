module MiniSql
  # Evaluates a bound expression on one row (an array of values; empty when there is no table).
  module Evaluator
    def self.evaluate(expr, row)
      case expr
      when Literal then expr.value
      when BoundColumn then row.fetch(expr.index, nil)
      when Unary then unary(expr, row)
      when Binary then binary(expr, row)
      when Not then Operators.logic_not(evaluate(expr.operand, row))
      when Compare then compare(expr, row)
      when BoundCall then Functions.call(expr.name, expr.args.map { |arg| evaluate(arg, row) })
      else raise ArgumentError, "unbound expression"
      end
    end

    def self.unary(expr, row)
      value = evaluate(expr.operand, row)
      expr.op == "-" ? Operators.negate(value) : value
    end

    def self.binary(expr, row)
      left = evaluate(expr.left, row)
      right = evaluate(expr.right, row)
      case expr.op
      when "AND" then Operators.logic_and(left, right)
      when "OR" then Operators.logic_or(left, right)
      when "||" then Operators.concat(left, right)
      else Operators.arithmetic(expr.op, left, right)
      end
    end

    def self.compare(expr, row)
      Operators.compare(expr.op, evaluate(expr.left, row), expr.left_affinity,
                        evaluate(expr.right, row), expr.right_affinity)
    end
  end
end
