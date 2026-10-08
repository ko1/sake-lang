# SQL values (spec 1.3): NULL is nil, INTEGER an Integer, REAL a Float, TEXT a String.
# This module holds the rules every part of the engine shares: printing, reading text as a number,
# the order of values (1.9) and truth (1.10).
module Values
  INT_MIN = -(2**63)
  INT_MAX = 2**63 - 1

  NUMERIC_LITERAL = /\A(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?\z/
  SIGNED_LITERAL = /\A *([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?) *\z/
  NUMERIC_PREFIX = /\A *([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)/

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

  # The number a TEXT value is, if it is a whole numeric literal after trimming spaces (1.5 step 2),
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

  # true, false, or nil for unknown (1.10).
  def truth(value)
    return nil if value.nil?
    !to_number(value).zero?
  end

  def from_truth(bool)
    bool.nil? ? nil : (bool ? 1 : 0)
  end

  # -1, 0 or 1 by the order of values: NULL < numbers < TEXT (1.9).
  def compare(a, b)
    ra = rank(a)
    rb = rank(b)
    return ra <=> rb unless ra == rb
    return 0 if a.nil?
    a <=> b
  end

  def rank(value)
    case value
    when nil then 0
    when String then 2
    else 1
    end
  end
end
