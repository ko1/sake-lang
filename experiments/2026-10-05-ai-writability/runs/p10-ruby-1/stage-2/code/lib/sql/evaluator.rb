# frozen_string_literal: true

require_relative "ast"
require_relative "functions"
require_relative "values"

module Sql
  # Evaluates a bound expression (see Binder) against one row (an Array of values; [] for none).
  module Evaluator
    COMPARISONS = {
      eq: ->(c) { c == 0 }, ne: ->(c) { c != 0 }, lt: ->(c) { c < 0 },
      le: ->(c) { c <= 0 }, gt: ->(c) { c > 0 }, ge: ->(c) { c >= 0 }
    }.freeze

    module_function

    def evaluate(node, row)
      case node
      when Literal then node.value
      when ColumnRef then row[node.index]
      when Unary then unary(node.op, evaluate(node.operand, row))
      when Binary then binary(node, row)
      when Call then Functions.call(node.fn, node.args.map { |a| evaluate(a, row) })
      when Case then case_expr(node, row)
      when Between then between(node, row)
      when In then in_list(node, row)
      when Like then like(node, row)
      when Cast then Values.cast(evaluate(node.expr, row), node.type)
      else raise "cannot evaluate #{node.inspect}"
      end
    end

    # Affinity of an expression: a column's type or a CAST's type, else none (1.9).
    def affinity(node)
      case node
      when ColumnRef, Cast then node.type
      end
    end

    # Three-valued `left op right` (true / false / nil) with affinity; op is a COMPARISONS key.
    def compare_nodes(op, left_node, left, right_node, right)
      return nil if left.nil? || right.nil?
      l, r = Values.apply_affinity(left, affinity(left_node), right, affinity(right_node))
      COMPARISONS.fetch(op).call(Values.compare(l, r))
    end

    def case_expr(node, row)
      if node.operand
        subject = evaluate(node.operand, row)
        node.whens.each do |cond, result|
          return evaluate(result, row) if compare_nodes(:eq, node.operand, subject, cond, evaluate(cond, row))
        end
      else
        node.whens.each do |cond, result|
          return evaluate(result, row) if Values.truth(evaluate(cond, row))
        end
      end
      node.else_expr && evaluate(node.else_expr, row)
    end

    def between(node, row)
      x = evaluate(node.expr, row)
      lo = compare_nodes(:ge, node.expr, x, node.low, evaluate(node.low, row))
      hi = compare_nodes(:le, node.expr, x, node.high, evaluate(node.high, row))
      result = if lo == false || hi == false then false
               elsif lo.nil? || hi.nil? then nil
               else true
               end
      negate_if(node.negated, result)
    end

    # Only x's affinity counts: each element is converted to it before comparing (2.3).
    def in_list(node, row)
      x = evaluate(node.expr, row)
      return negate_if(node.negated, false) if node.list.empty?
      return nil if x.nil?
      aff = affinity(node.expr)
      saw_null = false
      found = node.list.any? do |element|
        v = evaluate(element, row)
        if v.nil?
          saw_null = true
          next false
        end
        _, v = Values.apply_affinity(x, aff, v, nil)
        Values.compare(x, v) == 0
      end
      negate_if(node.negated, found ? true : (saw_null ? nil : false))
    end

    def like(node, row)
      text = evaluate(node.expr, row)
      pattern = evaluate(node.pattern, row)
      return nil if text.nil? || pattern.nil?
      negate_if(node.negated, Values.like?(Values.text_form(text), Values.text_form(pattern)))
    end

    # Wraps a true / false / nil result as 1 / 0 / NULL, negated when asked.
    def negate_if(negated, truth)
      Values.from_bool(truth.nil? || !negated ? truth : !truth)
    end

    def unary(op, value)
      case op
      when :plus then value
      when :neg then value.nil? ? nil : -Values.to_number(value)
      when :not
        t = Values.truth(value)
        Values.from_bool(t.nil? ? nil : !t)
      end
    end

    def binary(node, row)
      op = node.op
      return logic(node, row) if op == :and || op == :or
      left = evaluate(node.left, row)
      right = evaluate(node.right, row)
      case op
      when :+, :-, :*, :/, :% then arithmetic(op, left, right)
      when :concat
        left.nil? || right.nil? ? nil : Values.text_form(left) + Values.text_form(right)
      when :is, :isnot
        equal = is_equal?(node, left, right)
        Values.from_bool(op == :is ? equal : !equal)
      else
        return nil if left.nil? || right.nil?
        Values.from_bool(COMPARISONS.fetch(op).call(compare_with_affinity(node, left, right)))
      end
    end

    def compare_with_affinity(node, left, right)
      l, r = Values.apply_affinity(left, affinity(node.left), right, affinity(node.right))
      Values.compare(l, r)
    end

    def is_equal?(node, left, right)
      return left.nil? && right.nil? if left.nil? || right.nil?
      compare_with_affinity(node, left, right) == 0
    end

    # Three-valued AND / OR (1.8); the right side is only evaluated when it can matter.
    def logic(node, row)
      left = Values.truth(evaluate(node.left, row))
      if node.op == :and
        return 0 if left == false
        right = Values.truth(evaluate(node.right, row))
        return 0 if right == false
        Values.from_bool(left.nil? || right.nil? ? nil : true)
      else
        return 1 if left == true
        right = Values.truth(evaluate(node.right, row))
        return 1 if right == true
        Values.from_bool(left.nil? || right.nil? ? nil : false)
      end
    end

    def arithmetic(op, left, right)
      return nil if left.nil? || right.nil?
      a = Values.to_number(left)
      b = Values.to_number(right)
      if a.is_a?(Integer) && b.is_a?(Integer)
        integer_arithmetic(op, a, b)
      else
        real_arithmetic(op, a.to_f, b.to_f)
      end
    end

    def integer_arithmetic(op, a, b)
      case op
      when :+ then a + b
      when :- then a - b
      when :* then a * b
      when :/ then b == 0 ? nil : truncating_divide(a, b)
      when :% then b == 0 ? nil : a.remainder(b)
      end
    end

    def truncating_divide(a, b)
      q = a.abs / b.abs
      (a < 0) == (b < 0) ? q : -q
    end

    def real_arithmetic(op, a, b)
      case op
      when :+ then a + b
      when :- then a - b
      when :* then a * b
      when :/ then b == 0 ? nil : a / b
      when :%
        ia = a.truncate
        ib = b.truncate
        ib == 0 ? nil : ia.remainder(ib).to_f
      end
    end
  end
end
