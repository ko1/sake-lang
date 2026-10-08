module MiniSql
  # Arithmetic, concatenation, comparison and logic on values (SPEC 1.8, 1.9).
  module Operators
    def self.negate(value)
      return nil if value.nil?
      number = Value.to_number(value)
      number.is_a?(Integer) ? -number : -number.to_f
    end

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
      when "/" then y.zero? ? nil : x / y
      else
        divisor = y.truncate
        divisor.zero? ? nil : x.truncate.remainder(divisor).to_f
      end
    end

    def self.concat(left, right)
      return nil if left.nil? || right.nil?
      Value.text_form(left) + Value.text_form(right)
    end

    def self.logic_not(value)
      truth = Value.truth(value)
      truth.nil? ? nil : Value.from_truth(!truth)
    end

    def self.logic_and(left, right)
      a = Value.truth(left)
      b = Value.truth(right)
      return 0 if a == false || b == false
      Value.from_truth(a.nil? || b.nil? ? nil : true)
    end

    def self.logic_or(left, right)
      a = Value.truth(left)
      b = Value.truth(right)
      return 1 if a == true || b == true
      Value.from_truth(a.nil? || b.nil? ? nil : false)
    end

    def self.numeric?(affinity)
      affinity == :integer || affinity == :real
    end

    # Converts the operands of a comparison by affinity (SPEC 1.9).
    def self.apply_affinity(left, left_affinity, right, right_affinity)
      if numeric?(left_affinity) && !numeric?(right_affinity)
        [left, text_as_number(right)]
      elsif numeric?(right_affinity) && !numeric?(left_affinity)
        [text_as_number(left), right]
      elsif left_affinity == :text && right_affinity.nil?
        [left, number_as_text(right)]
      elsif right_affinity == :text && left_affinity.nil?
        [number_as_text(left), right]
      else
        [left, right]
      end
    end

    def self.text_as_number(value)
      value.is_a?(String) ? (Value.parse_number(value) || value) : value
    end

    def self.number_as_text(value)
      value.is_a?(Integer) || value.is_a?(Float) ? Value.text_form(value) : value
    end

    # A comparison operator; op is one of = == != <> < <= > >=, or IS / IS NOT.
    def self.compare(op, left, left_affinity, right, right_affinity)
      a, b = apply_affinity(left, left_affinity, right, right_affinity)
      case op
      when "IS" then return Value.from_truth(same?(a, b))
      when "IS NOT" then return Value.from_truth(!same?(a, b))
      end
      return nil if a.nil? || b.nil?
      order = Value.compare(a, b)
      outcome =
        case op
        when "=", "==" then order == 0
        when "!=", "<>" then order != 0
        when "<" then order < 0
        when "<=" then order <= 0
        when ">" then order > 0
        else order >= 0
        end
      Value.from_truth(outcome)
    end

    def self.same?(left, right)
      return left.nil? && right.nil? if left.nil? || right.nil?
      Value.compare(left, right).zero?
    end

    # `value LIKE pattern` (SPEC 2.3): 1, 0 or NULL.
    def self.like(value, pattern)
      return nil if value.nil? || pattern.nil?
      source = Value.text_form(pattern).each_char.map do |char|
        case char
        when "%" then ".*"
        when "_" then "."
        else Regexp.escape(char)
        end
      end
      matcher = Regexp.new("\\A#{source.join}\\z", Regexp::IGNORECASE | Regexp::MULTILINE)
      Value.from_truth(matcher.match?(Value.text_form(value)))
    end

    # CAST(value AS type) (SPEC 2.3, 7.9); type is :integer, :real, :text or :blob.
    def self.cast(value, type)
      return nil if value.nil?
      case type
      when :integer then Value.to_integer(value)
      when :real then Value.to_number(value).to_f
      when :blob then Value.to_blob(value)
      else Value.text_form(value)
      end
    end
  end
end
