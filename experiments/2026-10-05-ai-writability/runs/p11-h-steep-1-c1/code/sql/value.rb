# frozen_string_literal: true

require_relative "collation"

module Sql
  # Operations on SQL values, which are nil (NULL), Integer, Float and String (TEXT).
  module Value
    INT_MIN = -9_223_372_036_854_775_808
    INT_MAX = 9_223_372_036_854_775_807
    NUMBER = "(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?"
    NUMERIC_LITERAL = /\A[+-]?#{NUMBER}\z/
    NUMERIC_PREFIX = /\A[ \t\n\r]*([+-]?#{NUMBER})/
    BLANKS = /\A[ \t\n\r]+|[ \t\n\r]+\z/

    # The value of a numeric literal's text; an integer beyond 64 bits becomes a REAL.
    def self.parse_number(text)
      if text.match?(/[.eE]/)
        Float(text)
      else
        n = Integer(text, 10)
        n < INT_MIN || n > INT_MAX ? n.to_f : n
      end
    end

    # The number a TEXT is, after trimming blanks, when all of it is a numeric literal.
    def self.parse_numeric_text(text)
      trimmed = text.gsub(BLANKS, "")
      trimmed.match?(NUMERIC_LITERAL) ? parse_number(trimmed) : nil
    end

    # The Integer a REAL equals when it is a whole number within 64 bits, else nil.
    def self.integer_exact(x)
      x == x.floor && x >= INT_MIN && x < INT_MAX.to_f ? x.to_i : nil
    end

    # A value in a form that is equal (eql?) exactly when the two are equal in the order of
    # values: a REAL that is a whole number becomes that INTEGER, a TEXT becomes its fold under the
    # collation. For hash keys (and, being ordered like the values, for sorting groups).
    def self.identity(value, collation = :binary)
      case value
      when Float then value.finite? ? (integer_exact(value) || value) : value
      when String then Collation.fold(value, collation)
      else value
      end
    end

    def self.numeric_prefix(text)
      m = NUMERIC_PREFIX.match(text)
      return 0 unless m

      parse_number(m[1].to_s)
    end

    def self.to_number(value)
      case value
      when String then numeric_prefix(value)
      else value
      end
    end

    # Printing of a REAL: %.15g, then ".0" added where the result would read as an integer.
    def self.format_real(x)
      return "0.0" if x == 0.0

      s = format("%.15g", x)
      if s.include?("e")
        mantissa, exponent = s.split("e", 2)
        mantissa = "#{mantissa}.0" unless mantissa.to_s.include?(".")
        "#{mantissa}e#{exponent}"
      else
        s.include?(".") ? s : "#{s}.0"
      end
    end

    # The text form of a non-NULL value.
    def self.text_form(value)
      case value
      when String then value
      when Integer then value.to_s
      else format_real(value)
      end
    end

    def self.type_name(value)
      case value
      when nil then "null"
      when Integer then "integer"
      when Float then "real"
      else "text"
      end
    end

    # nil (unknown), true or false.
    def self.truth(value)
      case value
      when nil then nil
      when String then to_number(value) != 0
      else value != 0
      end
    end

    def self.from_truth(truth)
      truth.nil? ? nil : (truth ? 1 : 0)
    end

    def self.rank(value)
      case value
      when nil then 0
      when String then 2
      else 1
      end
    end

    # The order of values: NULL < numbers < TEXT (byte order of the texts as the collation folds
    # them). Returns -1, 0 or 1.
    def self.compare(left, right, collation = :binary)
      lr = rank(left)
      rr = rank(right)
      return lr < rr ? -1 : 1 if lr != rr

      case left
      when nil then 0
      when String then right.is_a?(String) ? (Collation.fold(left, collation) <=> Collation.fold(right, collation)) || 0 : 0
      else right.is_a?(String) || right.nil? ? 0 : (left <=> right) || 0
      end
    end

    INTEGER_PREFIX = /\A[ \t\n\r]*([+-]?[0-9]+)/

    # CAST(value AS type) (spec 2.3).
    def self.cast(value, type)
      return nil if value.nil?

      case type
      when :integer then cast_integer(value)
      when :real then to_number(value).to_f
      else text_form(value)
      end
    end

    # Integers saturate at the 64-bit limits.
    def self.cast_integer(value)
      n =
        case value
        when Integer then value
        when Float then value.nan? ? 0 : (value.infinite? ? (value > 0 ? INT_MAX : INT_MIN) : value.truncate)
        else INTEGER_PREFIX.match(value)&.[](1).to_i
        end
      n.clamp(INT_MIN, INT_MAX)
    end

    def self.numeric_affinity?(affinity)
      affinity == :integer || affinity == :real
    end

    # Applies the comparison affinity rules (spec 1.9) to the two operands.
    def self.coerce_for_comparison(left, left_aff, right, right_aff)
      if numeric_affinity?(left_aff) && !numeric_affinity?(right_aff)
        [left, number_if_text(right)]
      elsif numeric_affinity?(right_aff) && !numeric_affinity?(left_aff)
        [number_if_text(left), right]
      elsif left_aff == :text && right_aff.nil?
        [left, text_if_number(right)]
      elsif right_aff == :text && left_aff.nil?
        [text_if_number(left), right]
      else
        [left, right]
      end
    end

    def self.number_if_text(value)
      return value unless value.is_a?(String)

      parse_numeric_text(value) || value
    end

    def self.text_if_number(value)
      value.is_a?(Integer) || value.is_a?(Float) ? text_form(value) : value
    end
  end
end
