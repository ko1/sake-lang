# frozen_string_literal: true

require_relative "errors"

module Sql
  # SQL values are plain Ruby objects: nil (NULL), Integer, Float (REAL) and String (TEXT).
  # This module holds everything that depends only on values: printing, number reading,
  # the order of values, affinity conversion and the conversion done when storing into a column.
  module Values
    INT_MIN = -(2**63)
    INT_MAX = 2**63 - 1
    WS = " \t\n\r"
    NUMBER = /[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?/
    NUMERIC_LITERAL = /\A[#{WS}]*(#{NUMBER})[#{WS}]*\z/
    NUMERIC_PREFIX = /\A[#{WS}]*(#{NUMBER})/

    module_function

    def integer_in_range?(n)
      n.between?(INT_MIN, INT_MAX)
    end

    # "INTEGER", "REAL", "TEXT" or "NULL"
    def type_name(value)
      case value
      when nil then "NULL"
      when Integer then "INTEGER"
      when Float then "REAL"
      else "TEXT"
      end
    end

    def format_real(x)
      return "0.0" if x == 0
      s = format("%.15g", x)
      if s.include?("e")
        mantissa, exponent = s.split("e", 2)
        mantissa += ".0" unless mantissa.include?(".")
        "#{mantissa}e#{exponent}"
      else
        s.include?(".") ? s : "#{s}.0"
      end
    end

    # The text form of a non-NULL value.
    def text_form(value)
      case value
      when String then value
      when Integer then value.to_s
      else format_real(value)
      end
    end

    # What a result row prints for a value.
    def display(value)
      value.nil? ? "NULL" : text_form(value)
    end

    # Number denoted by the matched literal text: INTEGER without `.`/exponent, else REAL.
    def number_from_literal(literal)
      if literal.match?(/[.eE]/)
        literal.to_f
      else
        n = literal.to_i
        integer_in_range?(n) ? n : n.to_f
      end
    end

    # The whole text (after trimming) as a number, or nil when it is not a numeric literal.
    def parse_numeric_literal(text)
      m = NUMERIC_LITERAL.match(text)
      m && number_from_literal(m[1])
    end

    # Longest numeric prefix of a text, 0 when there is none (1.8).
    def numeric_prefix(text)
      m = NUMERIC_PREFIX.match(text)
      m ? number_from_literal(m[1]) : 0
    end

    # Reads any non-NULL value as a number (for arithmetic and truth tests).
    def to_number(value)
      value.is_a?(String) ? numeric_prefix(value) : value
    end

    # true / false / nil (unknown), 1.10
    def truth(value)
      return nil if value.nil?
      to_number(value) != 0
    end

    def from_bool(bool)
      bool.nil? ? nil : (bool ? 1 : 0)
    end

    def rank(value)
      case value
      when nil then 0
      when String then 2
      else 1
      end
    end

    # What a text is compared byte by byte as under a collation (:binary, :nocase, :rtrim; 7.1).
    def text_key(text, collation)
      case collation
      when :nocase then text.b.downcase(:ascii)
      when :rtrim then text.b.sub(/ +\z/, "")
      else text
      end
    end

    # Total order of values (1.9): -1, 0 or 1. Two TEXT values compare under `collation` (7).
    def compare(a, b, collation = :binary)
      ra = rank(a)
      rb = rank(b)
      return ra <=> rb if ra != rb
      return 0 if ra == 0
      return a <=> b unless ra == 2
      collation == :binary ? a.b <=> b.b : text_key(a, collation) <=> text_key(b, collation)
    end

    # A hash key such that two values are equal by `compare` (under `collation`) iff their keys are eql?
    # (DISTINCT, GROUP BY).
    def group_key(value, collation = :binary)
      return text_key(value, collation) if value.is_a?(String)
      value.is_a?(Float) && value.finite? && value == value.floor && integer_in_range?(value.to_i) ? value.to_i : value
    end

    # The hash key of a whole result row: rows are equal in DISTINCT and compound selects iff keys are eql?.
    # `collations`: one per column (nil: all :binary).
    def row_key(row, collations = nil)
      row.each_with_index.map { |v, i| group_key(v, collations ? collations[i] : :binary) }
    end

    NUMERIC_AFFINITIES = %i[integer real].freeze

    # Applies the affinity rules of 1.9 to the two (non-NULL) operands; returns the converted pair.
    # An affinity is :integer, :real, :text or nil (none).
    def apply_affinity(left, left_aff, right, right_aff)
      if NUMERIC_AFFINITIES.include?(left_aff) && (right_aff == :text || right_aff.nil?)
        right = parse_numeric_literal(right) || right if right.is_a?(String)
      elsif NUMERIC_AFFINITIES.include?(right_aff) && (left_aff == :text || left_aff.nil?)
        left = parse_numeric_literal(left) || left if left.is_a?(String)
      elsif left_aff == :text && right_aff.nil?
        right = text_form(right) unless right.is_a?(String)
      elsif right_aff == :text && left_aff.nil?
        left = text_form(left) unless left.is_a?(String)
      end
      [left, right]
    end

    INTEGER_PREFIX = /\A[#{WS}]*([+-]?\d+)/

    # CAST(value AS type) (2.3); type is :integer, :real or :text.
    def cast(value, type)
      return nil if value.nil?
      case type
      when :text then text_form(value)
      when :real then to_number(value).to_f
      else
        n = case value
            when Integer then value
            when Float then value.truncate
            else (m = INTEGER_PREFIX.match(value)) ? m[1].to_i : 0
            end
        n.clamp(INT_MIN, INT_MAX)
      end
    end

    LIKE_REGEXPS = {}

    # `text LIKE pattern` (2.3): % any run, _ one character, the rest case-insensitive.
    def like?(text, pattern)
      regexp = (LIKE_REGEXPS[pattern] ||= begin
        body = pattern.each_char.map do |ch|
          case ch
          when "%" then ".*"
          when "_" then "."
          else Regexp.escape(ch)
          end
        end.join
        Regexp.new("\\A#{body}\\z", Regexp::IGNORECASE | Regexp::MULTILINE)
      end)
      regexp.match?(text)
    end

    # Converts a value for storing in a column of the given type (:integer, :real, :text) (1.5).
    # Returns [stored_value, nil], or [nil, type_name_of_the_rejected_value].
    def coerce_for_column(value, column_type)
      return [nil, nil] if value.nil?
      if value.is_a?(String) && column_type != :text
        parsed = parse_numeric_literal(value)
        value = parsed unless parsed.nil?
      end
      case column_type
      when :integer
        case value
        when Integer then [value, nil]
        when Float
          if value == value.floor && value >= INT_MIN.to_f && value < 2.0**63
            [value.to_i, nil]
          else
            [nil, "REAL"]
          end
        else [nil, "TEXT"]
        end
      when :real
        case value
        when Integer then [value.to_f, nil]
        when Float then [value, nil]
        else [nil, "TEXT"]
        end
      else
        [text_form(value), nil]
      end
    end
  end
end
