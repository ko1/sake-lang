require_relative "values"

# The scalar functions (spec 1.11, 2.4), looked up case-insensitively.
module Functions
  # arity: the allowed argument counts; null_in_null_out: a NULL argument gives NULL without calling.
  Function = Struct.new(:arity, :null_in_null_out, :body) do
    def call(args)
      return nil if null_in_null_out && args.any?(&:nil?)
      body.(*args)
    end
  end

  module_function

  def text(value) = Values.to_text(value)

  def ascii_case(value, from, to)
    text(value).tr(from, to)
  end

  def abs(value)
    case value
    when Integer, Float then value.abs
    else Values.to_number(value).to_f.abs
    end
  end

  # The steps of spec 2.4; len nil means "to the end".
  def substr(value, start, len = nil)
    s = text(value)
    p = Values.to_number(start).to_i
    q = len.nil? ? Float::INFINITY : Values.to_number(len).to_i
    if p.negative?
      p += s.length
      if p.negative?
        q += p
        p = 0
        q = 0 if q.negative?
      end
    elsif p.positive?
      p -= 1
    elsif q.positive?
      q -= 1
    end
    if q.negative?
      q = -q
      p -= q
      if p.negative?
        q += p
        p = 0
      end
    end
    q <= 0 ? "" : (s[p, q == Float::INFINITY ? s.length : q] || "")
  end

  # Removes characters of `chars` (default: space) from the chosen ends.
  def trim(value, chars, leading:, trailing:)
    s = text(value)
    set = chars.nil? ? " " : text(chars)
    return s if set.empty?
    from = 0
    to = s.length
    from += 1 while leading && from < to && set.include?(s[from])
    to -= 1 while trailing && to > from && set.include?(s[to - 1])
    s[from...to]
  end

  def trim_function(leading, trailing)
    Function.new(1..2, true, ->(x, chars = nil) { trim(x, chars, leading:, trailing:) })
  end

  def replace(value, from, to)
    s = text(value)
    pattern = text(from)
    pattern.empty? ? s : s.gsub(pattern) { text(to) }
  end

  # The decimal %.17g form rounded half away from zero to n places, as a REAL.
  def round(value, places = 0)
    x = Values.to_number(value).to_f
    n = [Values.to_number(places).to_i, 0].max
    Rational(format("%.17g", x)).round(n, half: :up).to_f
  end

  # An argument of a math function as a number by 7.1 (whole numeric literal text only), else nil.
  def math_number(value)
    value.is_a?(String) ? Values.parse_number(value) : value
  end

  # A math function of numbers (change 7): NULL if an argument is not a number by 7.1, or for a NaN.
  def math_function(arity, &body)
    Function.new(arity..arity, false, lambda do |*args|
      numbers = args.map { |a| math_number(a) }
      result = numbers.any?(&:nil?) ? nil : body.(*numbers)
      result.is_a?(Float) && result.nan? ? nil : result
    end)
  end

  # ceil, floor and trunc: an INTEGER unchanged, a REAL rounded by `method` and kept REAL.
  def rounding_function(method) = math_function(1) { |x| x.is_a?(Integer) ? x : x.public_send(method).to_f }

  # C's pow: NULL when the result is not a real number (a negative base with a fractional exponent).
  def pow(x, y)
    r = x.to_f**y.to_f
    r.is_a?(Float) ? r : nil
  end

  # C's fmod: the remainder of x / y with x's sign; Float#remainder loses it when |y| is much larger.
  def fmod(x, y)
    r = x.abs % y.abs
    x.negative? ? -r : r
  end

  # The largest (sign 1) or smallest (sign -1) by the order of values; the first of equal ones.
  def extreme(values, sign)
    values.reduce { |best, v| Values.compare(v, best) * sign > 0 ? v : best }
  end

  TABLE = {
    "length" => Function.new(1..1, true, ->(x) { text(x).length }),
    "upper" => Function.new(1..1, true, ->(x) { ascii_case(x, "a-z", "A-Z") }),
    "lower" => Function.new(1..1, true, ->(x) { ascii_case(x, "A-Z", "a-z") }),
    "abs" => Function.new(1..1, true, ->(x) { abs(x) }),
    "typeof" => Function.new(1..1, false, ->(x) { Values.type_name(x) }),
    "coalesce" => Function.new(2.., false, ->(*xs) { xs.find { |x| !x.nil? } }),
    "ifnull" => Function.new(2..2, false, ->(x, y) { x.nil? ? y : x }),
    "nullif" => Function.new(2..2, false, ->(x, y) { !x.nil? && !y.nil? && Values.compare(x, y).zero? ? nil : x }),
    "substr" => Function.new(2..3, true, ->(*args) { substr(*args) }),
    "trim" => trim_function(true, true),
    "ltrim" => trim_function(true, false),
    "rtrim" => trim_function(false, true),
    "replace" => Function.new(3..3, true, ->(x, from, to) { replace(x, from, to) }),
    "instr" => Function.new(2..2, true, ->(x, y) { (text(x).index(text(y)) || -1) + 1 }),
    "round" => Function.new(1..2, true, ->(*args) { round(*args) }),
    "max" => Function.new(2.., true, ->(*xs) { extreme(xs, 1) }),
    "min" => Function.new(2.., true, ->(*xs) { extreme(xs, -1) }),
    "ceil" => rounding_function(:ceil),
    "ceiling" => rounding_function(:ceil),
    "floor" => rounding_function(:floor),
    "trunc" => rounding_function(:truncate),
    "mod" => math_function(2) { |x, y| y.zero? ? nil : fmod(x.to_f, y.to_f) },
    "pow" => math_function(2) { |x, y| pow(x, y) },
    "power" => math_function(2) { |x, y| pow(x, y) },
    "sqrt" => math_function(1) { |x| x.negative? ? nil : Math.sqrt(x) },
    "pi" => math_function(0) { Math::PI }
  }.freeze

  # The function for a call written as `name(n arguments)`; raises SqlError for an unknown name or count.
  def lookup(name, argument_count)
    function = TABLE[name.downcase] or raise SqlError, "no such function: #{name}"
    unless function.arity.include?(argument_count)
      raise SqlError, "wrong number of arguments to function #{name}()"
    end
    function
  end
end
