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
    sign = (value < 0 || (value == 0 && 1.0 / value < 0)) ? "-" : ""
    return "#{sign}0.0" if value == 0

    mag = value.abs
    s = mag.to_s
    if s.include?("e")
      mant, exp = s.split("e")
      digits = mant.delete(".")
      x = exp.to_i
    else
      ip, fp = s.split(".")
      all = ip + fp
      lead = all[/\A0*/].length
      digits = all[lead..]
      x = ip.length - 1 - lead
    end
    digits = digits.sub(/0+\z/, "")
    digits = "0" if digits.empty?
    if mag < 0.0001 || mag >= 1e16 || (mag >= 1e15 && mag == mag.floor)
      rest = digits[1..]
      rest = "0" if rest.empty?
      "#{sign}#{digits[0]}.#{rest}e#{x < 0 ? "-" : "+"}#{x.abs.to_s.rjust(2, "0")}"
    elsif x >= 0
      digits = digits.ljust(x + 1, "0")
      frac = digits[(x + 1)..]
      "#{sign}#{digits[0..x]}.#{frac.empty? ? "0" : frac}"
    else
      "#{sign}0.#{"0" * (-x - 1)}#{digits}"
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
