def ones
  %w[zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen
     fifteen sixteen seventeen eighteen nineteen]
end

def tens = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]

def scales = [[1_000_000_000, "billion"], [1_000_000, "million"], [1000, "thousand"]]

def below_hundred(n)
  return ones[n] if n < 20
  t, u = n.divmod(10)
  u.zero? ? tens[t] : "#{tens[t]}-#{ones[u]}"
end

def below_thousand(n)
  h, rest = n.divmod(100)
  parts = []
  parts << "#{ones[h]} hundred" if h > 0
  if rest > 0
    parts << "and" if h > 0
    parts << below_hundred(rest)
  end
  parts.join(" ")
end

def to_words(n)
  return "zero" if n == 0
  return "minus " + to_words(-n) if n < 0
  parts = []
  rest = n
  scales.each do |size, name|
    if rest >= size
      parts << "#{to_words(rest / size)} #{name}"
      rest %= size
    end
  end
  if rest > 0
    parts << "and" if !parts.empty? && rest < 100
    parts << below_thousand(rest)
  end
  parts.join(" ")
end

def ordinal_word(n)
  irregular = { "one" => "first", "two" => "second", "three" => "third", "five" => "fifth",
                "eight" => "eighth", "nine" => "ninth", "twelve" => "twelfth" }
  words = to_words(n)
  m = words.match(/([a-z]+)\z/)
  return words unless m
  last = m[1]
  stem = words.delete_suffix(last)
  if (replacement = irregular[last])
    stem + replacement
  elsif last.end_with?("y")
    stem + last.delete_suffix("y") + "ieth"
  else
    stem + last + "th"
  end
end

def ordinal_suffix(n)
  return "th" if (n % 100).between?(11, 13)
  case n % 10
  when 1 then "st"
  when 2 then "nd"
  when 3 then "rd"
  else "th"
  end
end

def cheque(amount_cents)
  dollars, cents = amount_cents.divmod(100)
  text = to_words(dollars).capitalize
  unit = dollars == 1 ? "dollar" : "dollars"
  format("%s %s and %02d/100", text, unit, cents)
end

def roman(n)
  table = [[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"], [100, "C"], [90, "XC"],
           [50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]
  out = +""
  rest = n
  table.each do |value, sym|
    while rest >= value
      out << sym
      rest -= value
    end
  end
  out
end

[0, 7, 13, 21, 40, 99, 100, 101, 342, 1000, 1001, 2024, 15_016, 700_000, 1_234_567, -58, 3_000_000_005].each do |n|
  puts format("%14d  %s", n, to_words(n))
end
puts
[1, 2, 3, 4, 11, 12, 13, 21, 22, 30, 101, 112, 1000].each do |n|
  puts format("%5s  %-6s %s", "#{n}#{ordinal_suffix(n)}", roman(n), ordinal_word(n))
end
puts
[100, 1999, 123_456, 100_000_001].each { |c| puts cheque(c) }
total_letters = (1..100).sum { |n| to_words(n).delete(" -").size }
puts "letters used writing 1..100: #{total_letters}"
