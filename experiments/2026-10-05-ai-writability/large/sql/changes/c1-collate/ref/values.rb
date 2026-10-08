require_relative "errors"

# SQL values (spec 1.3): NULL is nil, INTEGER an Integer, REAL a Float, TEXT a String.
# This module holds the rules every part of the engine shares: printing, reading text as a number,
# the order of values (1.9) and truth (1.10).
module Values
  INT_MIN = -(2**63)
  INT_MAX = 2**63 - 1

  NUMERIC_LITERAL = /\A(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?\z/
  SIGNED_LITERAL = /\A[ \t\n\r]*([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)[ \t\n\r]*\z/
  NUMERIC_PREFIX = /\A[ \t\n\r]*([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)/
  INTEGER_PREFIX = /\A *([+-]?\d+)/

  module_function

  def type_name(value)
    case value
    when nil then "null"
    when Integer then "integer"
    when Float then "real"
    else "text"
    end
  end

  # How a value prints, which is also its text form.
  def to_text(value)
    case value
    when nil then "NULL"
    when Float then format_real(value)
    else value.to_s
    end
  end

  # %.15g, with ".0" added so that the result always reads as a REAL.
  def format_real(x)
    return "0.0" if x.zero?
    s = format("%.15g", x)
    mantissa, exponent = s.split("e")
    mantissa += ".0" unless mantissa.include?(".")
    exponent ? "#{mantissa}e#{exponent}" : mantissa
  end

  # A Float from a numeric literal's text, which Ruby's Float() does not take in every form ("5.", ".5").
  def parse_real(text)
    Float(text.sub(/\A([+-]?)\./, '\10.').sub(/\.(?=[eE]|\z)/, ".0"))
  end

  # The number a signed numeric literal's text stands for: INTEGER without "." and exponent.
  def literal_number(text)
    return parse_real(text) if text.match?(/[.eE]/)
    n = Integer(text, 10)
    n.between?(INT_MIN, INT_MAX) ? n : n.to_f
  end

  # The number a TEXT value is, if it is a whole numeric literal after trimming whitespace (1.5 step 2),
  # else nil.
  def parse_number(text)
    m = SIGNED_LITERAL.match(text)
    m && literal_number(m[1])
  end

  # A TEXT value read as a number by its numeric prefix (1.8); numbers are returned unchanged.
  def to_number(value)
    return value unless value.is_a?(String)
    m = NUMERIC_PREFIX.match(value)
    m ? literal_number(m[1]) : 0
  end

  # CAST(value AS INTEGER) for TEXT: the longest sign-and-digits prefix after leading spaces (2.3).
  def text_to_integer(text)
    m = INTEGER_PREFIX.match(text)
    m ? Integer(m[1], 10).clamp(INT_MIN, INT_MAX) : 0
  end

  # true, false, or nil for unknown (1.10).
  def truth(value)
    return nil if value.nil?
    !to_number(value).zero?
  end

  def from_truth(bool)
    bool.nil? ? nil : (bool ? 1 : 0)
  end

  # -1, 0 or 1 by the order of values: NULL < numbers < TEXT (1.9); two TEXT values compare under
  # `collation` (7.1).
  def compare(a, b, collation = Collation::BINARY)
    ra = rank(a)
    rb = rank(b)
    return ra <=> rb unless ra == rb
    return 0 if a.nil?
    return Collation.key(a, collation) <=> Collation.key(b, collation) if a.is_a?(String)
    a <=> b
  end

  # compare for one ORDER BY term: DESC reverses the order; NULLs come first under ASC and last under
  # DESC unless nulls_first (true or false) says otherwise (1.7).
  def compare_ordered(a, b, descending, nulls_first, collation = Collation::BINARY)
    if a.nil? || b.nil?
      nulls_first = !descending if nulls_first.nil?
      ((a.nil? ? 0 : 1) <=> (b.nil? ? 0 : 1)) * (nulls_first ? 1 : -1)
    else
      compare(a, b, collation) * (descending ? -1 : 1)
    end
  end

  # A hash key under which values equal by 1.9 coincide (1 and 1.0; NULL with NULL; TEXT equal
  # under `collation`).
  def equality_key(value, collation = Collation::BINARY)
    return Collation.key(value, collation) if value.is_a?(String)
    return value unless value.is_a?(Float)
    whole = value.finite? && value == value.truncate && value.truncate.between?(INT_MIN, INT_MAX)
    whole ? value.truncate : value
  end

  def rank(value)
    case value
    when nil then 0
    when String then 2
    else 1
    end
  end
end

# Collating sequences (7.1): a collation is named by its canonical (upper-case) name.
module Collation
  BINARY = "BINARY"
  NAMES = %w[BINARY NOCASE RTRIM].freeze

  # The collation of an expression (7.3): name, and whether it was written with COLLATE.
  Of = Struct.new(:name, :explicit)
  # An operand known only by its collation (a Collation::Of or nil), for `choose`.
  Operand = Struct.new(:collation)

  module_function

  # The canonical name for a collation name as written, or SqlError (7.2).
  def lookup(name)
    canonical = name.upcase
    NAMES.include?(canonical) or raise SqlError, "no such collation sequence: #{name}"
    canonical
  end

  # The text a TEXT value compares as, byte by byte, under the collation.
  def key(text, collation)
    case collation
    when "NOCASE" then text.tr("A-Z", "a-z")
    when "RTRIM" then text.sub(/ +\z/, "")
    else text
    end
  end

  # The collation an operation on a bound expression uses when only that expression counts (7.4).
  def name_of(expr) = expr.collation&.name || BINARY

  # The collation of `a op b` (7.4): explicit left, explicit right, implicit left, implicit right.
  def choose(a, b)
    ca = a.collation
    cb = b.collation
    found = [ca&.explicit && ca, cb&.explicit && cb, ca, cb].find(&:itself)
    found ? found.name : BINARY
  end
end
