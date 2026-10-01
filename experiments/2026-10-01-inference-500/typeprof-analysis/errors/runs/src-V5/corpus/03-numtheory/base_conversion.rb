# Positional numeral systems: converting to and from bases 2..36, parsing with
# validation, balanced ternary, and numbers that are palindromes in two bases.

class InvalidDigit < StandardError
  attr_reader :char, :base

  def initialize(message, char, base)
    super(message)
    @char = char
    @base = base
  end
end

def alphabet = "0123456789abcdefghijklmnopqrstuvwxyz"

def to_base(n, base)
  raise ArgumentError, "base #{base} out of range" unless base.between?(2, 36)
  return "0" if n.zero?
  sign = n.negative? ? "-" : ""
  n = n.abs
  out = +""
  while n > 0
    n, r = n.divmod(base)
    out.prepend(alphabet[r])
  end
  sign + out
end

def parse_base(s, base)
  s = s.strip.downcase
  neg = s.start_with?("-")
  s = s.delete_prefix("-")
  raise ArgumentError, "empty number" if s.empty?
  value = 0
  s.each_char do |c|
    next if c == "_"
    d = alphabet.index(c)
    raise InvalidDigit.new("bad digit '#{c}' for base #{base}", c, base) if !d     || d >= base
    value = value * base + d
  end
  neg ? -value : value
end

def balanced_ternary(n)
  return "0" if n.zero?
  out = +""
  while n != 0
    r = n % 3
    if r == 2
      out.prepend("T")
      n = (n + 1) / 3
    else
      out.prepend(r.to_s)
      n = (n - r) / 3
    end
  end
  out
end

def from_balanced_ternary(s)
  s.chars.reduce(0) { |acc, c| acc * 3 + (c == "T" ? -1 : c.to_i) }
end

puts "to_base:"
[[255, 2], [255, 16], [-42, 7], [1295, 36], [0, 5], [100, 1]].each do |n, b|
  puts "  #{n} in base #{b} = #{to_base(n, b)}"
rescue ArgumentError => e
  puts "  #{n} in base #{b}: #{e.message}"
end

puts "parse:"
inputs = [["ff", 16], ["1010_1010", 2], ["-zz", 36], ["129", 8], ["", 10], [" 7Fa ", 16], ["12g", 16]]
inputs.each do |s, b|
  v = parse_base(s, b)
  puts format("  %-12s base %2d = %d", "\"#{s}\"", b, v)
rescue InvalidDigit, ArgumentError => e
  puts format("  %-12s base %2d: %s", "\"#{s}\"", b, e.message)
end

puts "round trips:"
ok = (2..36).count do |b|
  [0, 1, 35, 1000, 65535, 123456789].all? { |n| parse_base(to_base(n, b), b) == n }
end
puts "  bases with exact round trip: #{ok} of 35"

puts "balanced ternary:"
[0, 1, 2, 5, 8, -7, 100, -100].each do |n|
  bt = balanced_ternary(n)
  puts format("  %5d -> %-8s -> %d", n, bt, from_balanced_ternary(bt))
end

puts "palindromic in base 10 and base 2:"
both = (1..2000).select do |n|
  d = n.to_s
  b = to_base(n, 2)
  d == d.reverse && b == b.reverse
end
both.each { |n| puts "  #{n} = #{to_base(n, 2)}" }

puts "digit sums of 2^20 by base:"
n = 2**20
[2, 3, 7, 10, 16, 36].each do |b|
  s = to_base(n, b).chars.sum { |c| alphabet.index(c) || 0 }
  puts "  base #{b}: #{to_base(n, b)} (digit sum #{s})"
end
