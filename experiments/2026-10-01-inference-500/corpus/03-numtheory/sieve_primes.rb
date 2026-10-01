# Sieve of Eratosthenes with a small report: prime counts per block,
# twin primes, largest gaps, and primes of a few special forms.

def sieve(limit)
  is_prime = Array.new(limit + 1, true)
  is_prime[0] = false
  is_prime[1] = false
  i = 2
  while i * i <= limit
    if is_prime[i]
      (i * i).step(limit, i) { |j| is_prime[j] = false }
    end
    i += 1
  end
  primes = []
  is_prime.each_with_index { |flag, n| primes << n if flag }
  primes
end

def counts_per_block(primes, block, limit)
  counts = Hash.new(0)
  primes.each { |p| counts[p / block] += 1 }
  rows = []
  b = 0
  while b * block <= limit
    lo = b * block
    hi = lo + block - 1
    rows << [lo, hi, counts[b]]
    b += 1
  end
  rows
end

def twin_primes(primes)
  primes.each_cons(2).select { |a, b| b - a == 2 }
end

def largest_gaps(primes, k)
  gaps = primes.each_cons(2).map { |a, b| { from: a, to: b, size: b - a } }
  gaps.sort_by { |g| [-g[:size], g[:from]] }.take(k)
end

def mersenne_exponents(primes, max_exp)
  primes.take_while { |p| p <= max_exp }.select do |p|
    m = 2**p - 1
    is_p = m > 1
    d = 2
    while d * d <= m
      if m % d == 0
        is_p = false
        break
      end
      d += 1
    end
    is_p
  end
end

limit = 2000
primes = sieve(limit)
puts "primes up to #{limit}: #{primes.size}"
puts "first 15: #{primes.take(15).join(" ")}"
puts "last 5: #{primes.last(5).join(" ")}"

puts "per block of 500:"
counts_per_block(primes, 500, limit - 1).each do |lo, hi, c|
  puts format("  %4d-%4d %4d %s", lo, hi, c, "*" * (c / 5))
end

twins = twin_primes(primes)
puts "twin pairs: #{twins.size}"
if (last_twin = twins.last)
  a, b = last_twin
  puts "largest twin pair: (#{a}, #{b})"
end

puts "largest gaps:"
largest_gaps(primes, 4).each do |g|
  puts "  #{g[:from]} -> #{g[:to]}: #{g[:size]}"
end

puts "Mersenne prime exponents <= 30: #{mersenne_exponents(primes, 30).join(", ")}"

sophie = primes.select { |p| p < 500 && primes.include?(2 * p + 1) }
puts "Sophie Germain primes < 500: #{sophie.size} (max #{sophie.max})"
