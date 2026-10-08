# frozen_string_literal: true

require_relative "ast"
require_relative "error"
require_relative "functions"
require_relative "operators"
require_relative "value"

module Sql
  # Evaluates a resolved expression against one row (an array of column values). A subquery runs
  # with that row as its outer row; it is run through Query, which query.rb requires (it requires
  # this file), so this file does not.
  module Evaluator
    def self.evaluate(expr, row)
      case expr
      when Ast::Literal then expr.value
      when Ast::ResolvedColumn, Ast::SlotExpr then row.fetch(expr.index)
      when Ast::Unary then unary(expr, row)
      when Ast::Binary then binary(expr, row)
      when Ast::Is then same(expr, row)
      when Ast::FunctionCall then Functions.call(expr.name, expr.args.map { |arg| evaluate(arg, row) })
      when Ast::CaseExpr then case_expr(expr, row)
      when Ast::Between then between(expr, row)
      when Ast::InList then in_list(expr, row)
      when Ast::Like then like(expr, row)
      when Ast::Glob then glob(expr, row)
      when Ast::Cast then Value.cast(evaluate(expr.operand, row), expr.type)
      when Ast::ScalarPlan then scalar_subquery(expr, row)
      when Ast::ExistsPlan then Query.result_rows(expr.plan, row).empty? ? 0 : 1
      when Ast::InPlan then in_subquery(expr, row)
      else raise Error, "internal error: unresolved expression"
      end
    end

    # The comparison affinity of an expression: its column's type or its CAST type, else nil.
    def self.affinity(expr)
      case expr
      when Ast::ResolvedColumn, Ast::Cast then expr.type
      when Ast::ScalarPlan then expr.plan.result_types.first
      end
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

    def self.case_expr(expr, row)
      subject_expr = expr.subject
      subject = subject_expr ? evaluate(subject_expr, row) : nil
      expr.whens.each do |clause|
        candidate = evaluate(clause.condition, row)
        matched =
          if subject_expr
            Operators.comparison("=", subject, affinity(subject_expr), candidate, affinity(clause.condition)) == 1
          else
            Value.truth(candidate) == true
          end
        return evaluate(clause.result, row) if matched
      end
      else_result = expr.else_result
      else_result ? evaluate(else_result, row) : nil
    end

    # value >= low AND value <= high in three-valued logic, value evaluated once.
    def self.between(expr, row)
      value = evaluate(expr.value, row)
      aff = affinity(expr.value)
      low = Operators.comparison(">=", value, aff, evaluate(expr.low, row), affinity(expr.low))
      high = Operators.comparison("<=", value, aff, evaluate(expr.high, row), affinity(expr.high))
      inside = low == 0 || high == 0 ? 0 : (low.nil? || high.nil? ? nil : 1)
      expr.negated ? negate_result(inside) : inside
    end

    # Only the left side's affinity counts: every candidate is converted to it.
    def self.in_list(expr, row)
      candidates = expr.candidates.map { |candidate| evaluate(candidate, row) }
      membership(evaluate(expr.value, row), affinity(expr.value), candidates, nil, expr.negated)
    end

    # The first column of the first row, or NULL without rows.
    def self.scalar_subquery(expr, row)
      first = Query.result_rows(expr.plan, row).first
      first ? first.fetch(0) : nil
    end

    # Like in_list over the subquery's values, which keep their column's affinity.
    def self.in_subquery(expr, row)
      value = evaluate(expr.value, row)
      candidates = Query.result_rows(expr.plan, row).map { |values| values.fetch(0) }
      membership(value, affinity(expr.value), candidates, expr.plan.result_types.fetch(0), expr.negated)
    end

    # x IN (candidates): 1 if one equals x, else NULL if x or a candidate is NULL, else 0; with no
    # candidates at all it is 0 whatever x is.
    def self.membership(value, aff, candidates, candidate_aff, negated)
      found = false
      unknown = value.nil? && !candidates.empty?
      candidates.each do |candidate|
        if candidate.nil?
          unknown = true
        elsif !value.nil?
          left, right = Value.coerce_for_comparison(value, aff, candidate, candidate_aff)
          found ||= Value.compare(left, right) == 0
        end
      end
      result = found ? 1 : (unknown ? nil : 0)
      negated ? negate_result(result) : result
    end

    def self.like(expr, row)
      value = evaluate(expr.value, row)
      pattern = evaluate(expr.pattern, row)
      escape_expr = expr.escape
      escape = escape_expr ? evaluate(escape_expr, row) : nil
      escape_text = escape.nil? ? nil : Value.text_form(escape)
      # Checked before the NULL operands: a bad escape fails even when x or p is NULL.
      raise Error, "ESCAPE expression must be a single character" if escape_text && escape_text.length != 1
      return nil if value.nil? || pattern.nil? || (escape_expr && escape.nil?)

      matched = Operators.like?(Value.text_form(value), Value.text_form(pattern), escape_text)
      matched == expr.negated ? 0 : 1
    end

    def self.glob(expr, row)
      value = evaluate(expr.value, row)
      pattern = evaluate(expr.pattern, row)
      return nil if value.nil? || pattern.nil?

      matched = Operators.glob?(Value.text_form(value), Value.text_form(pattern))
      matched == expr.negated ? 0 : 1
    end

    def self.negate_result(result)
      result.nil? ? nil : 1 - result
    end
  end
end
