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
    "min" => Function.new(2.., true, ->(*xs) { extreme(xs, -1) })
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
