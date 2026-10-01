# Decimal expansions of fractions by long division: terminating vs. repeating,
# the repetend in parentheses, period lengths, and full-reptend (cyclic) primes.

def expand(num, den)
  int_part, rem = num.divmod(den)
  digits = +""
  seen = {}
  pos = 0
  while rem != 0 && !seen.key?(rem)
    seen[rem] = pos
    rem *= 10
    d, rem = rem.divmod(den)
    digits << d.to_s
    pos += 1
  end
  if rem == 0
    { int: int_part, prefix: digits, cycle: "" }
  else
    start = seen[rem]
    { int: int_part, prefix: digits[0...start], cycle: digits[start..] }
  end
end

def format_expansion(e)
  int, prefix, cycle = e[:int], e[:prefix], e[:cycle]
  return int.to_s if prefix.empty? && cycle.empty?
  return "#{int}.#{prefix}" if cycle.empty?
  "#{int}.#{prefix}(#{cycle})"
end

def multiplicative_order(base, n)
  return nil if base.gcd(n) != 1
  k = 1
  x = base % n
  while x != 1
    x = x * base % n
    k += 1
  end
  k
end

def strip_2_5(n)
  n /= 2 while n % 2 == 0
  n /= 5 while n % 5 == 0
  n
end

def period(den)
  core = strip_2_5(den)
  core == 1 ? 0 : multiplicative_order(10, core)
end

puts "expansions:"
[[1, 3], [1, 7], [22, 7], [1, 12], [3, 8], [5, 6], [1, 81], [7, 1], [1, 97]].each do |n, d|
  shown = format_expansion(expand(n, d))
  shown = shown[0...40] + "..." if shown.length > 40
  puts format("  %3d/%-3d = %s", n, d, shown)
end

puts "period of 1/d, checked against long division:"
mismatches = (2..300).count { |d| expand(1, d)[:cycle].length != period(d) }
puts "  mismatches for d in 2..300: #{mismatches}"

lens = (2..40).map { |d| period(d) }
puts "  periods for d = 2..40: #{lens.join(" ")}"

longest = (2..1000).max_by { |d| period(d) }
puts "  longest period below 1000: 1/#{longest} with #{period(longest)} digits"

primes = (3..500).select { |p| p != 5 && (2..Integer.sqrt(p)).none? { |q| p % q == 0 } }
full = primes.select { |p| period(p) == p - 1 }
puts "full reptend primes < 500: #{full.join(" ")}"
puts "share among primes != 2, 5: #{full.size}/#{primes.size}"

cycle = expand(1, 7)[:cycle]
puts "cyclic number #{cycle}:"
(1..6).each do |k|
  prod = cycle.to_i * k
  puts "  #{cycle} x #{k} = #{prod.to_s.rjust(6, "0")}"
end

puts "midy's theorem (halves of the repetend sum to 9...9):"
[7, 13, 17, 19].each do |p|
  cycle = expand(1, p)[:cycle]
  half = cycle.length / 2
  a = cycle[0...half].to_i
  b = cycle[half..].to_i
  puts "  1/#{p}: #{cycle[0...half]} + #{cycle[half..]} = #{a + b}"
end
