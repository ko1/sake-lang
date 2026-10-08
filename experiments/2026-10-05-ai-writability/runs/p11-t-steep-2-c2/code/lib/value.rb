module MiniSql
  # A BLOB value: a string of bytes. Equal (and the same Hash key) when the bytes are equal.
  class Blob
    attr_reader :bytes

    def initialize(bytes)
      @bytes = bytes.b.freeze
    end

    def ==(other)
      other.is_a?(Blob) && @bytes == other.bytes
    end

    def eql?(other)
      self == other
    end

    def hash
      @bytes.hash
    end

    # The bytes read as characters (SPEC 7.1).
    def text
      @bytes.dup.force_encoding(Encoding::UTF_8)
    end

    # Two uppercase hexadecimal digits per byte.
    def hex
      @bytes.unpack1("H*").to_s.upcase
    end
  end

  # Helpers on SQL values: nil (NULL), Integer, Float (REAL), String (TEXT) or Blob.
  module Value
    BLANKS = " \t\n\r"
    NUMBER_BODY = '(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?'
    WHOLE_NUMBER = Regexp.new("\\A[#{BLANKS}]*([+-]?#{NUMBER_BODY})[#{BLANKS}]*\\z")
    NUMBER_PREFIX = Regexp.new("\\A[#{BLANKS}]*([+-]?#{NUMBER_BODY})")
    INTEGER_PREFIX = Regexp.new("\\A[#{BLANKS}]*([+-]?\\d+)")
    INT64_MIN = -9_223_372_036_854_775_808
    INT64_MAX = 9_223_372_036_854_775_807

    # "NULL", "INTEGER", "REAL", "TEXT" or "BLOB".
    def self.type_name(value)
      case value
      when nil then "NULL"
      when Integer then "INTEGER"
      when Float then "REAL"
      when String then "TEXT"
      when Blob then "BLOB"
      end
    end

    # The type name of storage errors (SPEC 7.6): "INT" for an INTEGER.
    def self.storage_name(value)
      value.is_a?(Integer) ? "INT" : type_name(value)
    end

    # The Blob that a run of hex digits denotes, or nil unless it has an even number of digits.
    def self.blob_from_hex(digits)
      return nil unless digits.match?(/\A(?:\h\h)*\z/)
      Blob.new([digits].pack("H*"))
    end

    # CAST(x AS BLOB) for a non-NULL value: the bytes of its text form (a Blob stays as it is).
    def self.to_blob(value)
      value.is_a?(Blob) ? value : Blob.new(text_form(value).b)
    end

    # hex(x): a Blob's bytes, or the bytes of another value's text form, as uppercase hex; "" for NULL.
    def self.hex(value)
      value.nil? ? "" : to_blob(value).hex
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
      when Blob then value.text
      when nil then ""
      end
    end

    # How a result value is printed (NULL included).
    def self.render(value)
      case value
      when nil then "NULL"
      when Blob then "X'#{value.hex}'"
      else text_form(value)
      end
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
      when Blob then numeric_prefix(value.text)
      else 0
      end
    end

    # A non-NULL value as CAST(.. AS INTEGER) reads it: a REAL truncates, TEXT keeps its leading digits.
    def self.to_integer(value)
      case value
      when Integer then value
      when Float then value.truncate
      else
        match = INTEGER_PREFIX.match(text_form(value))
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
      when Blob then 3
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
      when Blob then right.is_a?(Blob) ? (left.bytes <=> right.bytes) || 0 : 0
      else 0
      end
    end

    # The value as a Hash key under equality of 1.9: a whole REAL is the same key as its INTEGER.
    def self.group_key(value)
      value.is_a?(Float) && whole_in_int64?(value) ? value.to_i : value
    end

    # Whether a REAL is a whole number that fits a 64-bit integer.
    def self.whole_in_int64?(real)
      real.finite? && real == real.floor && real >= INT64_MIN && real <= INT64_MAX
    end
  end
end
