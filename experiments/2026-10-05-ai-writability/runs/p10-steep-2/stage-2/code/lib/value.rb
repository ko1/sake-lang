module MiniSql
  # Helpers on SQL values: nil (NULL), Integer, Float (REAL) or String (TEXT).
  module Value
    BLANKS = " \t\n\r"
    NUMBER_BODY = '(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?'
    WHOLE_NUMBER = Regexp.new("\\A[#{BLANKS}]*([+-]?#{NUMBER_BODY})[#{BLANKS}]*\\z")
    NUMBER_PREFIX = Regexp.new("\\A[#{BLANKS}]*([+-]?#{NUMBER_BODY})")
    INTEGER_PREFIX = Regexp.new("\\A[#{BLANKS}]*([+-]?\\d+)")
    INT64_MIN = -9_223_372_036_854_775_808
    INT64_MAX = 9_223_372_036_854_775_807

    # "NULL", "INTEGER", "REAL" or "TEXT".
    def self.type_name(value)
      case value
      when nil then "NULL"
      when Integer then "INTEGER"
      when Float then "REAL"
      when String then "TEXT"
      end
    end

    # printf("%.15g") with the spec's fix-ups (1.0, 1.0e+20, no negative zero).
    def self.format_real(real)
      return "0.0" if real == 0.0
      text = format("%.15g", real)
      if text.include?("e")
        mantissa, exponent = text.split("e", 2)
        mantissa = "#{mantissa}.0" unless mantissa.to_s.include?(".")
        "#{mantissa}e#{exponent}"
      elsif text.include?(".")
        text
      else
        "#{text}.0"
      end
    end

    # The text form of a non-NULL value.
    def self.text_form(value)
      case value
      when Integer then value.to_s
      when Float then format_real(value)
      when String then value
      when nil then ""
      end
    end

    # How a result value is printed (NULL included).
    def self.render(value)
      value.nil? ? "NULL" : text_form(value)
    end

    def self.number_from(literal)
      if literal.include?(".") || literal.match?(/[eE]/)
        literal.to_f
      else
        literal.to_i
      end
    end

    # The number a whole text denotes if it is a numeric literal (blanks trimmed), else nil.
    def self.parse_number(text)
      match = WHOLE_NUMBER.match(text)
      return nil unless match
      number_from(match[1].to_s)
    end

    # The number a text starts with (0 if none).
    def self.numeric_prefix(text)
      match = NUMBER_PREFIX.match(text)
      return 0 unless match
      number_from(match[1].to_s)
    end

    # A non-NULL value read as a number.
    def self.to_number(value)
      case value
      when Integer then value
      when Float then value
      when String then numeric_prefix(value)
      else 0
      end
    end

    # A non-NULL value as CAST(.. AS INTEGER) reads it: a REAL truncates, TEXT keeps its leading digits.
    def self.to_integer(value)
      case value
      when Integer then value
      when Float then value.truncate
      else
        match = INTEGER_PREFIX.match(value.to_s)
        match ? match[1].to_s.to_i : 0
      end
    end

    # Truth value of 1.10: true, false, or nil for unknown.
    def self.truth(value)
      return nil if value.nil?
      to_number(value) != 0
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

    # Order of values (1.9): -1, 0 or 1.
    def self.compare(left, right)
      left_rank = rank(left)
      right_rank = rank(right)
      return left_rank <=> right_rank unless left_rank == right_rank
      case left
      when Integer then (left <=> to_number(right)) || 0
      when Float then (left <=> to_number(right)) || 0
      when String then (left <=> right.to_s) || 0
      else 0
      end
    end

    # Whether a REAL is a whole number that fits a 64-bit integer.
    def self.whole_in_int64?(real)
      real.finite? && real == real.floor && real >= INT64_MIN && real <= INT64_MAX
    end
  end
end
