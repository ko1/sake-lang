# Divisor sums: perfect / abundant / deficient classification, amicable pairs,
# and aliquot sequences with cycle detection.

module Divisors
  module_function

  def proper(n)
    return [] if n < 2
    ds = [1]
    d = 2
    while d * d <= n
      if n % d == 0
        ds << d
        ds << n / d if d * d != n
      end
      d += 1
    end
    ds.sort
  end

  def sum_proper(n) = proper(n).sum
end

def classify(n)
  s = Divisors.sum_proper(n)
  if s == n
    :perfect
  elsif s > n
    :abundant
  else
    :deficient
  end
end

def sieve_sums(limit)
  sums = Array.new(limit + 1, 0)
  (1..(limit / 2)).each do |d|
    (d * 2).step(limit, d) { |m| sums[m] += d }
  end
  sums
end

# returns {kind:, seq:} where kind is :terminates, :cycle or :open
def aliquot(n, max_len)
  seq = [n]
  pos = { n => 0 }
  while seq.size < max_len
    nxt = Divisors.sum_proper(seq.last)
    return { kind: :terminates, seq: seq, cycle: 0 } if nxt == 0
    if (start = pos[nxt])
      return { kind: :cycle, seq: seq, cycle: seq.size - start }
    end
    pos[nxt] = seq.size
    seq << nxt
  end
  { kind: :open, seq: seq, cycle: 0 }
end

puts "proper divisors:"
[28, 220, 284, 945, 97].each do |n|
  ds = Divisors.proper(n)
  puts "  #{n}: #{ds.join(" ")} (sum #{ds.sum}, #{classify(n)})"
end

counts = { perfect: 0, abundant: 0, deficient: 0 }
(1..500).each { |n| counts[classify(n)] += 1 }
counts.each { |k, v| puts "#{k}: #{v}" }

limit = 3000
sums = sieve_sums(limit)
perfect = (2..limit).select { |n| sums[n] == n }
puts "perfect numbers <= #{limit}: #{perfect.join(", ")}"

odd_abundant = (1..limit).find { |n| n.odd? && sums[n] > n }
puts "first odd abundant number: #{odd_abundant}"

amicable = []
(2..limit).each do |a|
  b = sums[a]
  amicable << [a, b] if b > a && b <= limit && sums[b] == a
end
puts "amicable pairs <= #{limit}:"
amicable.each { |a, b| puts "  #{a} <-> #{b}" }

puts "aliquot sequences:"
[12, 95, 220, 562, 25, 6].each do |n|
  aliquot(n, 20) => { kind:, seq:, cycle: }
  shown = seq.take(8).join(" -> ")
  shown = "#{shown} ..." if seq.size > 8
  case kind
  in :terminates then puts "  #{n}: terminates after #{seq.size} terms: #{shown}"
  in :cycle then puts "  #{n}: enters a cycle of length #{cycle}: #{shown}"
  in :open then puts "  #{n}: still open after #{seq.size} terms"
  end
end
