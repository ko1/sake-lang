# frozen_string_literal: true

require_relative "value"

module Sql
  # The SQL operators on already-evaluated values (nil is NULL).
  module Operators
    def self.arithmetic(op, left, right)
      return nil if left.nil? || right.nil?

      x = Value.to_number(left)
      y = Value.to_number(right)
      if x.is_a?(Integer) && y.is_a?(Integer)
        integer_arithmetic(op, x, y)
      else
        real_arithmetic(op, x.to_f, y.to_f)
      end
    end

    def self.integer_arithmetic(op, x, y)
      case op
      when "+" then x + y
      when "-" then x - y
      when "*" then x * y
      when "/"
        return nil if y.zero?

        quotient = x.abs / y.abs
        (x < 0) == (y < 0) ? quotient : -quotient
      else
        y.zero? ? nil : x.remainder(y)
      end
    end

    def self.real_arithmetic(op, x, y)
      case op
      when "+" then x + y
      when "-" then x - y
      when "*" then x * y
      when "/" then y == 0.0 ? nil : x / y
      else
        divisor = y.truncate
        divisor.zero? ? nil : x.truncate.remainder(divisor).to_f
      end
    end

    def self.negate(value)
      return nil if value.nil?

      -Value.to_number(value)
    end

    def self.concat(left, right)
      return nil if left.nil? || right.nil?

      Value.text_form(left) + Value.text_form(right)
    end

    # = != < <= > >= with affinity; NULL if either side is NULL.
    def self.comparison(op, left, left_aff, right, right_aff)
      return nil if left.nil? || right.nil?

      l, r = Value.coerce_for_comparison(left, left_aff, right, right_aff)
      c = Value.compare(l, r)
      outcome =
        case op
        when "=" then c == 0
        when "!=" then c != 0
        when "<" then c < 0
        when "<=" then c <= 0
        when ">" then c > 0
        else c >= 0
        end
      outcome ? 1 : 0
    end

    # IS: equality that is never NULL.
    def self.same?(left, left_aff, right, right_aff)
      return left.nil? && right.nil? if left.nil? || right.nil?

      l, r = Value.coerce_for_comparison(left, left_aff, right, right_aff)
      Value.compare(l, r) == 0
    end

    # Whether text matches a LIKE pattern: % any run, _ any one character, ASCII case ignored.
    def self.like?(text, pattern)
      source = pattern.tr("A-Z", "a-z").each_char.map do |c|
        case c
        when "%" then ".*"
        when "_" then "."
        else Regexp.escape(c)
        end
      end.join
      Regexp.new("\\A#{source}\\z", Regexp::MULTILINE).match?(text.tr("A-Z", "a-z"))
    end
  end
end
