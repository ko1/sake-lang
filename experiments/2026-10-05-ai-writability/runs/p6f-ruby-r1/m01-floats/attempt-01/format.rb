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

  # Shortest round-trip digits; plain or exponent form per SPEC change m01.
  def float_repr(x)
    neg = x.to_s.start_with?("-")
    sign = neg ? "-" : ""
    return "#{sign}0.0" if x == 0

    m = /\A(\d+)\.(\d+)(?:e([+-]\d+))?\z/.match(x.abs.to_s)
    all = m[1] + m[2]
    point = m[1].length + m[3].to_i
    lead = all[/\A0*/].length
    all = all[lead..]
    point -= lead
    all = all.sub(/0+\z/, "")
    e = point - 1
    abs = x.abs
    if abs < 0.0001 || abs >= 1e16 || (abs >= 1e15 && abs == abs.floor)
      frac = all.length > 1 ? all[1..] : "0"
      "#{sign}#{all[0]}.#{frac}e#{e < 0 ? "-" : "+"}#{e.abs.to_s.rjust(2, "0")}"
    elsif e >= 0
      ip = all[0..e].ljust(e + 1, "0")
      fp = all.length > e + 1 ? all[(e + 1)..] : "0"
      "#{sign}#{ip}.#{fp}"
    else
      "#{sign}0.#{"0" * (-e - 1)}#{all}"
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
