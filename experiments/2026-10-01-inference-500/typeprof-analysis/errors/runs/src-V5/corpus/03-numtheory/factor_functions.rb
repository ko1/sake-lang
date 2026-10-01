# Prime factorization into a Hash of prime => exponent, and the multiplicative
# functions built from it: tau, sigma, Euler's phi, Moebius, radical.

def factorize(n)
  f = {}
  d = 2
  while d * d <= n
    while n % d == 0
      f[d] = f.fetch(d, 0) + 1
      n /= d
    end
    d += d == 2 ? 1 : 2
  end
  f[n] = f.fetch(n, 0) + 1 if n > 1
  f
end

def show_factors(f)
  return "1" if f.empty?
  f.map { |p, e| e == 1 ? p.to_s : "#{p}^#{e}" }.join(" * ")
end

def tau(f) = f.reduce(1) { |acc, (_, e)| acc * (e + 1) }

def sigma(f)
  prod = 1
  f.each { |p, e| prod *= (p**(e + 1) - 1) / (p - 1) }
  prod
end

def phi(n, f) = f.reduce(n) { |acc, (p, _)| acc / p * (p - 1) }

def moebius(f)
  return 0 if f.any? { |_, e| e > 1 }
  f.size.even? ? 1 : -1
end

def radical(f) = f.keys.reduce(1, :*)

def from_factors(f) = f.reduce(1) { |acc, (p, e)| acc * p**e }

samples = [1, 2, 12, 60, 97, 360, 1001, 1024, 30030, 65536 + 1, 999999, 123456789]
puts format("%10s  %-22s %5s %10s %10s %3s %8s", "n", "factors", "tau", "sigma", "phi", "mu", "rad")
samples.each do |n|
  f = factorize(n)
  raise "roundtrip failed for #{n}" if from_factors(f) != n
  puts format("%10d  %-22s %5d %10d %10d %3d %8d", n, show_factors(f), tau(f), sigma(f), phi(n, f), moebius(f), radical(f))
end

# most divisors below a bound (highly composite records)
records = []
best = 0
(1..2000).each do |n|
  t = tau(factorize(n))
  if t > best
    best = t
    records << [n, t]
  end
end
puts "highly composite numbers <= 2000:"
puts "  " + records.map { |n, t| "#{n}(#{t})" }.join(" ")

# sum of phi(d) over divisors d of n equals n
[36, 100, 210].each do |n|
  divs = (1..n).select { |d| n % d == 0 }
  total = divs.sum { |d| phi(d, factorize(d)) }
  puts "sum of phi(d) for d | #{n} = #{total}"
end

# Mertens function M(n) = sum of mu(k)
m = 0
marks = {}
(1..200).each do |k|
  m += moebius(factorize(k))
  marks[k] = m if k % 40 == 0
end
puts "Mertens: " + marks.map { |k, v| "M(#{k})=#{v}" }.join(", ")

# smooth numbers: largest prime factor <= 7
smooth = (1..120).select { |n| f = factorize(n); f.empty? || f.keys.max <= 7 }
puts "7-smooth numbers <= 120 (#{smooth.size}): #{smooth.join(" ")}"

# most frequent largest prime factor among 2..500
lpf = Hash.new(0)
(2..500).each { |n| lpf[factorize(n).keys.max] += 1 }
top = lpf.to_a.sort_by { |p, c| [-c, p] }.take(5)
puts "most common largest prime factors: " + top.map { |p, c| "#{p}:#{c}" }.join(" ")
