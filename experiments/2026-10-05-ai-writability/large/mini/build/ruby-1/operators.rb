# frozen_string_literal: true

require_relative "errors"
require_relative "values"
require_relative "text"

module Mini
  # The operators on values (SPEC section 7): arithmetic, comparison,
  # membership, indexing and slicing. Every error is reported at the
  # `position` passed in.
  module Operators
    # Marks a slice bound that was left out (`a[:j]`), as opposed to one that
    # evaluated to nil.
    OMITTED = Object.new.freeze

    module_function

    def binary(operator, left, right, position)
      case operator
      when "+" then add(left, right, position)
      when "-", "*", "/", "%", "**" then arithmetic(operator, left, right, position)
      when "<", "<=", ">", ">=" then compare(operator, left, right, position)
      when "==" then Values.equal?(left, right, position)
      when "!=" then !Values.equal?(left, right, position)
      when "in" then member?(left, right, position)
      else raise ArgumentError, "unknown operator #{operator}"
      end
    end

    def type_error(message, position) = EvalError.new(:type, message, position)

    def operand_error(operator, left, right, position)
      type_error("cannot apply '#{operator}' to #{Values.type_name(left)} and #{Values.type_name(right)}", position)
    end

    def add(left, right, position)
      if (left.is_a?(Integer) && right.is_a?(Integer)) ||
         (left.is_a?(String) && right.is_a?(String)) ||
         (left.is_a?(Array) && right.is_a?(Array))
        return left + right
      end

      raise operand_error("+", left, right, position)
    end

    # Division and remainder round toward negative infinity, as Ruby's do.
    def arithmetic(operator, left, right, position)
      raise operand_error(operator, left, right, position) unless left.is_a?(Integer) && right.is_a?(Integer)

      case operator
      when "-" then left - right
      when "*" then left * right
      when "/", "%"
        raise EvalError.new(:zero, "division by zero", position) if right.zero?

        operator == "/" ? left / right : left % right
      when "**"
        raise EvalError.new(:value, "negative exponent", position) if right.negative?

        left**right
      end
    end

    # Ints numerically, strings by code points (UTF-8 byte order agrees).
    def compare(operator, left, right, position)
      unless (left.is_a?(Integer) && right.is_a?(Integer)) || (left.is_a?(String) && right.is_a?(String))
        raise operand_error(operator, left, right, position)
      end

      left.public_send(operator, right)
    end

    def negate(value, position)
      raise type_error("cannot negate #{Values.type_name(value)}", position) unless value.is_a?(Integer)

      -value
    end

    # `item in container` (SPEC section 7.4).
    def member?(item, container, position)
      case container
      when Array then container.any? { |element| Values.equal?(item, element, position) }
      when Hash then Values.key?(item) && container.key?(item)
      when String
        raise operand_error("in", item, container, position) unless item.is_a?(String)

        container.include?(item)
      else
        raise operand_error("in", item, container, position)
      end
    end

    def check_key(key, position)
      return if Values.key?(key)

      raise type_error("map key must be a string or int, got #{Values.type_name(key)}", position)
    end

    def missing_key(key, position) = EvalError.new(:key, "key #{Text.repr(key)} not found", position)

    # The array or string position for `index`, counting negative indexes
    # from the end.
    def sequence_offset(sequence, index, position)
      type = Values.type_name(sequence)
      raise type_error("#{type} index must be an int, got #{Values.type_name(index)}", position) unless index.is_a?(Integer)

      offset = index.negative? ? index + sequence.size : index
      unless offset >= 0 && offset < sequence.size
        raise EvalError.new(:index, "index #{index} out of range for #{type} of length #{sequence.size}", position)
      end

      offset
    end

    def index(object, key, position)
      case object
      when Array, String
        object[sequence_offset(object, key, position)]
      when Hash
        check_key(key, position)
        object.fetch(key) { raise missing_key(key, position) }
      else
        raise type_error("cannot index #{Values.type_name(object)}", position)
      end
    end

    def set_index(object, key, value, position)
      case object
      when Array
        object[sequence_offset(object, key, position)] = value
      when Hash
        check_key(key, position)
        object[key] = value
      when String
        raise type_error("strings are immutable", position)
      else
        raise type_error("cannot index #{Values.type_name(object)}", position)
      end
    end

    # `object[from:to]`; either bound may be OMITTED.
    def slice(object, from, to, position)
      unless object.is_a?(Array) || object.is_a?(String)
        raise type_error("cannot slice #{Values.type_name(object)}", position)
      end

      [from, to].each do |bound|
        next if bound.equal?(OMITTED) || bound.is_a?(Integer)

        raise type_error("slice bound must be an int, got #{Values.type_name(bound)}", position)
      end
      length = object.size
      first = slice_bound(from, 0, length)
      last = slice_bound(to, length, length)
      return object[0, 0] if last <= first

      object[first...last]
    end

    def slice_bound(bound, default, length)
      return default if bound.equal?(OMITTED)

      bound += length if bound.negative?
      bound.clamp(0, length)
    end
  end
end
