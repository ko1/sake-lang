module MiniSql
  # Evaluates a bound expression on one row (an array of values; empty when there is no table).
  module Evaluator
    def self.evaluate(expr, row)
      case expr
      when Literal then expr.value
      when BoundColumn then row.fetch(expr.index, nil)
      when AggregateRef then row.fetch(expr.index, nil)
      when WindowRef then row.fetch(expr.index, nil)
      when OuterRef then evaluate(expr.inner, expr.frame.row)
      when BoundSubquery then expr.evaluate(row)
      when Unary then unary(expr, row)
      when Binary then binary(expr, row)
      when Not then Operators.logic_not(evaluate(expr.operand, row))
      when Compare then compare(expr, row)
      when Case then evaluate_case(expr, row)
      when Like then like(expr, row)
      when Cast then Operators.cast(evaluate(expr.operand, row), expr.type)
      when Collated then evaluate(expr.operand, row)
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

    # Only the searched form reaches here (the Binder rewrites the simple one).
    def self.evaluate_case(expr, row)
      expr.whens.each do |clause|
        return evaluate(clause.result, row) if Value.truth(evaluate(clause.condition, row)) == true
      end
      else_expr = expr.else_expr
      else_expr ? evaluate(else_expr, row) : nil
    end

    def self.like(expr, row)
      result = Operators.like(evaluate(expr.operand, row), evaluate(expr.pattern, row))
      expr.negated ? Operators.logic_not(result) : result
    end

    def self.compare(expr, row)
      Operators.compare(expr.op, evaluate(expr.left, row), expr.left_affinity,
                        evaluate(expr.right, row), expr.right_affinity, expr.text_collation)
    end
  end
end
