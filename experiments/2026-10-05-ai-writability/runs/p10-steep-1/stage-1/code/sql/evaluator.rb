# frozen_string_literal: true

require_relative "ast"
require_relative "error"
require_relative "functions"
require_relative "operators"
require_relative "value"

module Sql
  # Evaluates a resolved expression against one row (an array of column values).
  module Evaluator
    def self.evaluate(expr, row)
      case expr
      when Ast::Literal then expr.value
      when Ast::ResolvedColumn then row.fetch(expr.index)
      when Ast::Unary then unary(expr, row)
      when Ast::Binary then binary(expr, row)
      when Ast::Is then same(expr, row)
      when Ast::FunctionCall then Functions.call(expr.name, expr.args.map { |arg| evaluate(arg, row) })
      else raise Error, "internal error: unresolved expression"
      end
    end

    # The comparison affinity of an expression: its column's type, or nil.
    def self.affinity(expr)
      expr.is_a?(Ast::ResolvedColumn) ? expr.type : nil
    end

    def self.unary(expr, row)
      value = evaluate(expr.operand, row)
      case expr.op
      when "-" then Operators.negate(value)
      when "+" then value
      else Value.from_truth(negation(Value.truth(value)))
      end
    end

    def self.negation(truth)
      truth.nil? ? nil : !truth
    end

    def self.binary(expr, row)
      case expr.op
      when "AND" then conjunction(expr, row)
      when "OR" then disjunction(expr, row)
      else
        left = evaluate(expr.left, row)
        right = evaluate(expr.right, row)
        case expr.op
        when "+", "-", "*", "/", "%" then Operators.arithmetic(expr.op, left, right)
        when "||" then Operators.concat(left, right)
        else Operators.comparison(expr.op, left, affinity(expr.left), right, affinity(expr.right))
        end
      end
    end

    def self.conjunction(expr, row)
      left = Value.truth(evaluate(expr.left, row))
      return 0 if left == false

      right = Value.truth(evaluate(expr.right, row))
      return 0 if right == false

      left.nil? || right.nil? ? nil : 1
    end

    def self.disjunction(expr, row)
      left = Value.truth(evaluate(expr.left, row))
      return 1 if left == true

      right = Value.truth(evaluate(expr.right, row))
      return 1 if right == true

      left.nil? || right.nil? ? nil : 0
    end

    def self.same(expr, row)
      left = evaluate(expr.left, row)
      right = evaluate(expr.right, row)
      result = Operators.same?(left, affinity(expr.left), right, affinity(expr.right))
      result == expr.negated ? 0 : 1
    end
  end
end
