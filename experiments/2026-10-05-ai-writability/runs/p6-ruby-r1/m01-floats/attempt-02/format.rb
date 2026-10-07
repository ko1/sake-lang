# How values are written as text (SPEC.md, "Printing values"), and small
# helpers for wording messages.
module Format
  module_function

  # The text `print`, `str`, `join` and interpolation produce: a string as it is,
  # any other value as `repr` writes it.
  def show(value) = value.is_a?(String) ? value : repr(value)

  # The text of a value as it appears inside an array or map: strings are quoted.
  def repr(value, depth = 0)
    return "..." if depth > MAX_NESTING

    case value
    when nil then "nil"
    when true then "true"
    when false then "false"
    when Integer then value.to_s
    when Float then float_repr(value)
    when String then quote(value)
    when Array then "[#{value.map { |element| repr(element, depth + 1) }.join(", ")}]"
    when Hash then "{#{value.map { |key, element| "#{repr(key, depth + 1)}: #{repr(element, depth + 1)}" }.join(", ")}}"
    when Closure then value.fn.name.nil? ? "<fn>" : "<fn #{value.fn.name}>"
    when Builtin then "<builtin #{value.name}>"
    else raise ArgumentError, "not a Mini value: #{value.class}"
    end
  end

  # Shortest round-trip digits; exponent form below 1e-4, from 1e16, or for integers from 1e15.
  def float_repr(value)
    sign = value.to_s.start_with?("-") ? "-" : ""
    abs = value.abs
    return "#{sign}0.0" if abs == 0

    mantissa, ex = abs.to_s.split("e")
    int_part, frac_part = mantissa.split(".")
    digits = int_part + (frac_part || "")
    point = int_part.length + ex.to_i
    lead = digits.length - digits.sub(/\A0+/, "").length
    digits = digits[lead..]
    point -= lead
    digits = digits.sub(/0+\z/, "")
    digits = "0" if digits.empty?
    e = point - 1
    if abs < 0.0001 || abs >= 1e16 || (abs >= 1e15 && abs == abs.floor)
      rest = digits.length > 1 ? digits[1..] : "0"
      exp = format("%02d", e.abs)
      "#{sign}#{digits[0]}.#{rest}e#{e < 0 ? "-" : "+"}#{exp}"
    elsif e >= 0
      padded = digits.ljust(e + 1, "0")
      frac = padded[(e + 1)..]
      "#{sign}#{padded[0..e]}.#{frac.empty? ? "0" : frac}"
    else
      "#{sign}0.#{"0" * (-e - 1)}#{digits}"
    end
  end

  # A string literal that reads back as `text`.
  def quote(text)
    escaped = text.chars.map do |c|
      case c
      when "\\" then "\\\\"
      when "\"" then "\\\""
      when "\n" then "\\n"
      when "\t" then "\\t"
      when "{" then "\\{"
      else c
      end
    end
    "\"#{escaped.join}\""
  end

  # "1 argument", "2 arguments", "0 arguments".
  def count(n, noun) = n == 1 ? "1 #{noun}" : "#{n} #{noun}s"

  # The edit distance between two names: the fewest single-character
  # insertions, deletions, substitutions and swaps of two adjacent characters
  # that turn `a` into `b` (the optimal string alignment distance).
  def edit_distance(a, b)
    x = a.chars
    y = b.chars
    d = Array.new(x.length + 1) { |i| Array.new(y.length + 1) { |j| i == 0 ? j : (j == 0 ? i : 0) } }
    (1..x.length).each do |i|
      (1..y.length).each do |j|
        cost = x[i - 1] == y[j - 1] ? 0 : 1
        best = [d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost].min
        if i > 1 && j > 1 && x[i - 1] == y[j - 2] && x[i - 2] == y[j - 1]
          best = [best, d[i - 2][j - 2] + 1].min
        end
        d[i][j] = best
      end
    end
    d[x.length][y.length]
  end

  # The name a message uses for a function: "f", or "function" when anonymous.
  def function_label(fn) = fn.name.nil? ? "function" : fn.name
end
