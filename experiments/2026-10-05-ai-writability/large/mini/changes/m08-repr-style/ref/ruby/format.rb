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
    when nil then "null"
    when true then "true"
    when false then "false"
    when Integer then value.to_s
    when String then single_quote(value)
    when Array then "[#{value.map { |element| repr(element, depth + 1) }.join(", ")}]"
    when Hash then "{#{value.map { |key, element| "#{repr(key, depth + 1)}: #{repr(element, depth + 1)}" }.join(", ")}}"
    when Closure then value.fn.name.nil? ? "<fn>" : "<fn #{value.fn.name}>"
    when Builtin then "<builtin #{value.name}>"
    else raise ArgumentError, "not a Mini value: #{value.class}"
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

  # A string as `repr` writes it: in single quotes, with \\ ' { newline tab escaped.
  def single_quote(text)
    escaped = text.chars.map do |c|
      case c
      when "\\" then "\\\\"
      when "'" then "\\'"
      when "\n" then "\\n"
      when "\t" then "\\t"
      when "{" then "\\{"
      else c
      end
    end
    "'#{escaped.join}'"
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
