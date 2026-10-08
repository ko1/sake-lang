# frozen_string_literal: true

require_relative "errors"

module Sql
  # A BLOB value: `data` is a frozen binary (ASCII-8BIT) String. Build it with Values.blob so that
  # two blobs are eql? exactly when their bytes are the same (and never eql? to a TEXT String).
  Blob = Data.define(:data)

  # SQL values are plain Ruby objects: nil (NULL), Integer, Float (REAL), String (TEXT) and Blob.
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

    # A Blob of the bytes of `bytes` (a String, whatever its encoding).
    def blob(bytes)
      Blob.new(bytes.b.freeze)
    end

    # "INTEGER", "REAL", "TEXT", "BLOB" or "NULL"
    def type_name(value)
      case value
      when nil then "NULL"
      when Integer then "INTEGER"
      when Float then "REAL"
      when Blob then "BLOB"
      else "TEXT"
      end
    end

    # Uppercase hexadecimal digits of the bytes of a binary or text String.
    def hex_digits(bytes)
      bytes.unpack1("H*").upcase
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

    # The text form of a non-NULL value (a BLOB's bytes read as characters, 7.1).
    def text_form(value)
      case value
      when String then value
      when Integer then value.to_s
      when Blob then value.data.dup.force_encoding(Encoding::UTF_8)
      else format_real(value)
      end
    end

    # What a result row prints for a value.
    def display(value)
      case value
      when nil then "NULL"
      when Blob then "X'#{hex_digits(value.data)}'"
      else text_form(value)
      end
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

    # Reads any non-NULL value as a number (for arithmetic and truth tests); a BLOB by its text form (7.5).
    def to_number(value)
      case value
      when String then numeric_prefix(value)
      when Blob then numeric_prefix(text_form(value))
      else value
      end
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
      when Blob then 3
      else 1
      end
    end

    # Total order of values (1.9): -1, 0 or 1.
    def compare(a, b)
      ra = rank(a)
      rb = rank(b)
      return ra <=> rb if ra != rb
      return 0 if ra == 0
      case ra
      when 2 then a.b <=> b.b
      when 3 then a.data <=> b.data # binary Strings: byte by byte, a prefix first
      else a <=> b
      end
    end

    # A hash key such that two values are equal by `compare` iff their keys are eql? (DISTINCT, GROUP BY).
    def group_key(value)
      value.is_a?(Float) && value.finite? && value == value.floor && integer_in_range?(value.to_i) ? value.to_i : value
    end

    # The hash key of a whole result row: rows are equal in DISTINCT and compound selects iff keys are eql?.
    def row_key(row)
      row.map { |v| group_key(v) }
    end

    NUMERIC_AFFINITIES = %i[integer real].freeze

    # The affinity of an expression of the given column / CAST type: a BLOB has none (7.3).
    def affinity_of_type(type)
      type == :blob ? nil : type
    end

    # Applies the affinity rules of 1.9 to the two (non-NULL) operands; returns the converted pair.
    # An affinity is :integer, :real, :text or nil (none).
    def apply_affinity(left, left_aff, right, right_aff)
      if NUMERIC_AFFINITIES.include?(left_aff) && (right_aff == :text || right_aff.nil?)
        right = parse_numeric_literal(right) || right if right.is_a?(String)
      elsif NUMERIC_AFFINITIES.include?(right_aff) && (left_aff == :text || left_aff.nil?)
        left = parse_numeric_literal(left) || left if left.is_a?(String)
      elsif left_aff == :text && right_aff.nil?
        right = text_form(right) if right.is_a?(Integer) || right.is_a?(Float)
      elsif right_aff == :text && left_aff.nil?
        left = text_form(left) if left.is_a?(Integer) || left.is_a?(Float)
      end
      [left, right]
    end

    INTEGER_PREFIX = /\A[#{WS}]*([+-]?\d+)/

    # CAST(value AS type) (2.3, 7.6); type is :integer, :real, :text or :blob.
    def cast(value, type)
      return nil if value.nil?
      case type
      when :text then text_form(value)
      when :real then to_number(value).to_f
      when :blob then value.is_a?(Blob) ? value : blob(text_form(value))
      else
        n = case value
            when Integer then value
            when Float then value.truncate
            else (m = INTEGER_PREFIX.match(text_form(value))) ? m[1].to_i : 0
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

    # Converts a value for storing in a column of the given type (:integer, :real, :text, :blob) (1.5, 7.4).
    # Returns [stored_value, nil], or [nil, type_name_of_the_rejected_value] ("INT" for an INTEGER).
    def coerce_for_column(value, column_type)
      return [nil, nil] if value.nil?
      if column_type == :blob
        return [value, nil] if value.is_a?(Blob)
        return [nil, value.is_a?(Integer) ? "INT" : type_name(value)]
      end
      return [nil, "BLOB"] if value.is_a?(Blob)
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
