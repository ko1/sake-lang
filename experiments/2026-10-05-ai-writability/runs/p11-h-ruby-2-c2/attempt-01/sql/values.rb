# frozen_string_literal: true

require_relative 'errors'

module SQL
  # A BLOB value (SPEC 7): a string of bytes. It is its own class so it is never mistaken for TEXT
  # (a Ruby String); equal bytes make equal values, also as Hash keys (GROUP BY, DISTINCT, UNIQUE).
  class Blob
    include Comparable

    attr_reader :bytes

    def initialize(bytes)
      @bytes = bytes.b.freeze
    end

    def size = @bytes.bytesize

    # Unsigned bytewise order; a prefix comes first (7.2).
    def <=>(other) = other.is_a?(Blob) ? @bytes <=> other.bytes : nil

    def ==(other) = other.is_a?(Blob) && @bytes == other.bytes

    alias eql? ==

    def hash = [Blob, @bytes].hash

    # The bytes read as characters (7.1 "text form").
    def to_text = @bytes.dup.force_encoding(Encoding::UTF_8)

    # Two uppercase hexadecimal digits per byte.
    def to_hex = @bytes.unpack1('H*').upcase
  end

  # Runtime values are plain Ruby objects: nil (NULL), Integer, Float (REAL), String (TEXT), Blob (BLOB).
  # This module holds everything that is about values alone: printing, number parsing,
  # truth values, ordering and comparison with affinity (SPEC 1.3, 1.5, 1.8-1.10).
  module Values
    INT_MIN = -(2**63)
    INT_MAX = (2**63) - 1

    NUMBER = /(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?/
    SPACE = '[ \t\n\r]'
    PREFIX_RE = /\A[ \t\n\r\f\v]*([+-]?#{NUMBER})/o
    LITERAL_RE = /\A#{SPACE}*([+-]?#{NUMBER})#{SPACE}*\z/o

    module_function

    def int64?(n) = n.between?(INT_MIN, INT_MAX)

    def type_name(v)
      case v
      when nil then 'null'
      when Integer then 'integer'
      when Float then 'real'
      when Blob then 'blob'
      else 'text'
      end
    end

    # --- printing ---------------------------------------------------------------------

    def format_real(x)
      return '0.0' if x.zero?

      s = format('%.15g', x)
      if s.include?('e')
        mant, exp = s.split('e')
        mant += '.0' unless mant.include?('.')
        "#{mant}e#{exp}"
      else
        s.include?('.') ? s : "#{s}.0"
      end
    end

    # The text form: how a number becomes text anywhere (1.3).
    def text_form(v)
      case v
      when Integer then v.to_s
      when Float then format_real(v)
      when Blob then v.to_text
      else v
      end
    end

    # How a value is printed (1.3, 7.1): a BLOB as X'..', unlike its text form.
    def display(v)
      case v
      when nil then 'NULL'
      when Blob then "X'#{v.to_hex}'"
      else text_form(v)
      end
    end

    # --- reading numbers from text ----------------------------------------------------

    # `s` is a signed numeric literal; INTEGER unless it has a fraction or exponent.
    def number_from_literal(s)
      if s.match?(/[.eE]/)
        Float(s.gsub(/(?<!\d)\./, '0.').gsub(/\.(?!\d)/, '.0'))
      else
        n = Integer(s, 10)
        int64?(n) ? n : n.to_f
      end
    end

    # The whole text (trimmed) is a numeric literal: its number, else nil (1.5 step 2).
    def parse_numeric_literal(s)
      m = LITERAL_RE.match(s)
      m && number_from_literal(m[1])
    end

    # Longest numeric prefix, or INTEGER 0 (1.8).
    def numeric_prefix(s)
      m = PREFIX_RE.match(s)
      m ? number_from_literal(m[1]) : 0
    end

    # A value as a number for arithmetic; nil stays nil. A BLOB is read through its text form (7.5).
    def to_number(v)
      v.is_a?(String) || v.is_a?(Blob) ? numeric_prefix(text_form(v)) : v
    end

    # CAST (2.3): NULL stays NULL.
    def cast(v, type)
      return nil if v.nil?

      case type
      when :integer then cast_to_integer(v)
      when :real then to_number(v).to_f
      when :blob then v.is_a?(Blob) ? v : Blob.new(text_form(v))
      else text_form(v)
      end
    end

    def cast_to_integer(v)
      v = text_form(v) if v.is_a?(Blob)
      n = v.is_a?(String) ? (v[/\A[ \t\n\r\f\v]*([+-]?\d+)/, 1] || 0).to_i : v.to_i
      n.clamp(INT_MIN, INT_MAX)
    end

    # --- truth ------------------------------------------------------------------------

    # true / false / nil (unknown) (1.10)
    def truth(v)
      v = to_number(v)
      v.nil? ? nil : v != 0
    end

    def from_bool(b) = b.nil? ? nil : (b ? 1 : 0)

    # Three-valued logic on true / false / nil (1.8).
    def and3(a, b) = a == false || b == false ? false : (a.nil? || b.nil? ? nil : true)
    def or3(a, b) = a == true || b == true ? true : (a.nil? || b.nil? ? nil : false)
    def not3(a) = a.nil? ? nil : !a

    # --- ordering and comparison ------------------------------------------------------

    def rank(v)
      case v
      when nil then 0
      when Numeric then 1
      when String then 2
      else 3
      end
    end

    # Total order of values (1.9, 7.2): NULL < numbers < TEXT < BLOB.
    def order_compare(a, b)
      ra = rank(a)
      rb = rank(b)
      return ra <=> rb if ra != rb

      ra.zero? ? 0 : a <=> b
    end

    # A Hash key under which equal values (1.9) coincide; NULL is equal to NULL (GROUP BY, DISTINCT).
    def group_key(v)
      v.is_a?(Float) && v.finite? && v == v.floor ? v.to_i : v
    end

    # A value converted to a numeric (:integer/:real) or :text affinity as `IN` does (2.3).
    def convert_to_affinity(v, affinity)
      case affinity
      when :integer, :real then v.is_a?(String) ? parse_numeric_literal(v) || v : v
      when :text then v.is_a?(Numeric) ? text_form(v) : v
      else v
      end
    end

    # Convert operands by affinity (1.9). Affinity is :integer, :real, :text or nil.
    def apply_affinity(a, aaff, b, baff)
      a_num = %i[integer real].include?(aaff)
      b_num = %i[integer real].include?(baff)
      if a_num && !b_num
        b = parse_numeric_literal(b) || b if b.is_a?(String)
      elsif b_num && !a_num
        a = parse_numeric_literal(a) || a if a.is_a?(String)
      elsif aaff == :text && baff.nil?
        b = text_form(b) if b.is_a?(Numeric)
      elsif baff == :text && aaff.nil?
        a = text_form(a) if a.is_a?(Numeric)
      end
      [a, b]
    end

    # -1/0/1 after affinity conversion, nil if either side is NULL.
    def compare(a, aaff, b, baff)
      return nil if a.nil? || b.nil?

      a, b = apply_affinity(a, aaff, b, baff)
      order_compare(a, b)
    end

    # Equality as `IS` sees it: never unknown.
    def same?(a, aaff, b, baff)
      return a.nil? && b.nil? if a.nil? || b.nil?

      compare(a, aaff, b, baff).zero?
    end
  end
end
