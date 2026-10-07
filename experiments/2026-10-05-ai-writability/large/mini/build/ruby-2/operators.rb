require_relative "values"

module Mini
  # The operators of section 7 on values. Errors are raised as Faults; the
  # evaluator reports them at the operator.
  module Operators
    module_function

    def binary(op, left, right)
      case op
      when "+" then add(left, right)
      when "-"
        both_ints(op, left, right)
        left - right
      when "*"
        both_ints(op, left, right)
        left * right
      when "/", "%" then divide(op, left, right)
      when "**" then power(left, right)
      when "==" then Values.equal_values?(left, right)
      when "!=" then !Values.equal_values?(left, right)
      when "<", "<=", ">", ">=" then compare(op, left, right)
      when "in" then member?(left, right)
      else raise ArgumentError, "unknown operator #{op}"
      end
    end

    def negate(value)
      raise Fault.new("type", "cannot negate #{Values.type_name(value)}") unless value.is_a?(Integer)
      -value
    end

    def add(left, right)
      if (left.is_a?(Integer) && right.is_a?(Integer)) ||
         (left.is_a?(String) && right.is_a?(String)) ||
         (left.is_a?(Array) && right.is_a?(Array))
        return left + right
      end
      cannot_apply("+", left, right)
    end

    def both_ints(op, left, right)
      cannot_apply(op, left, right) unless left.is_a?(Integer) && right.is_a?(Integer)
    end

    # Ruby's Integer#/ and #% already round toward negative infinity.
    def divide(op, left, right)
      both_ints(op, left, right)
      raise Fault.new("zero", "division by zero") if right.zero?
      op == "/" ? left / right : left % right
    end

    def power(left, right)
      both_ints("**", left, right)
      raise Fault.new("value", "negative exponent") if right.negative?
      left**right
    end

    def compare(op, left, right)
      comparable = (left.is_a?(Integer) && right.is_a?(Integer)) ||
                   (left.is_a?(String) && right.is_a?(String))
      cannot_apply(op, left, right) unless comparable
      left.public_send(op, right)
    end

    # `x in c` (section 7.4).
    def member?(item, collection)
      case collection
      when Array then collection.any? { |element| Values.equal_values?(item, element) }
      when Hash then Values.valid_key?(item) && collection.key?(item)
      when String
        cannot_apply("in", item, collection) unless item.is_a?(String)
        collection.include?(item)
      else cannot_apply("in", item, collection)
      end
    end

    def cannot_apply(op, left, right)
      raise Fault.new("type",
                      "cannot apply '#{op}' to #{Values.type_name(left)} and #{Values.type_name(right)}")
    end
  end
end
