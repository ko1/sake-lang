# Linear (Euler) sieve computing smallest prime factor, phi and mu for all n <= N
# in one pass; then square-free density, coprime-pair probability, and totient
# curiosities.

class Tables
  attr_reader :spf, :phi, :mu, :primes

  def initialize(spf, phi, mu, primes)
    @spf = spf
    @phi = phi
    @mu = mu
    @primes = primes
  end
end

def linear_sieve(n)
  spf = Array.new(n + 1, 0)
  phi = Array.new(n + 1, 0)
  mu = Array.new(n + 1, 0)
  phi[1] = 1
  mu[1] = 1
  primes = []
  (2..n).each do |i|
    if spf[i] == 0
      spf[i] = i
      phi[i] = i - 1
      mu[i] = -1
      primes << i
    end
    primes.each do |p|
      break if p > spf[i] || i * p > n
      spf[i * p] = p
      if i % p == 0
        phi[i * p] = phi[i] * p
        mu[i * p] = 0
      else
        phi[i * p] = phi[i] * (p - 1)
        mu[i * p] = -mu[i]
      end
    end
  end
  Tables.new(spf, phi, mu, primes)
end

def factor_with(spf, n)
  out = []
  while n > 1
    out << spf[n]
    n /= spf[n]
  end
  out
end

n = 1500
t = linear_sieve(n)
spf, phi, mu = t.spf, t.phi, t.mu
puts "primes <= #{n}: #{t.primes.size}"

puts "factorizations via smallest-prime-factor table:"
[360, 1155, 1024, 1499, 1001].each do |k|
  puts "  #{k} = #{factor_with(spf, k).join(" * ")}"
end

puts format("%5s %5s %5s %3s", "k", "spf", "phi", "mu")
[1, 2, 12, 30, 97, 100, 210, 1499].each do |k|
  puts format("%5d %5d %5d %3d", k, spf[k], phi[k], mu[k])
end

squarefree = (1..n).count { |k| mu[k] != 0 }
puts format("square-free density: %.4f (6/pi^2 = %.4f)", squarefree / n.to_f, 6 / Math::PI**2)

# number of coprime pairs (a, b) in 1..m is sum_d mu(d) * floor(m/d)^2
m = 600
coprime = (1..m).sum { |d| mu[d] * (m / d) * (m / d) }
puts format("coprime pairs in 1..%d: %d, probability %.4f", m, coprime, coprime / (m * m).to_f)

totient_sum = phi.drop(1).sum
puts "sum of phi(k) for k <= #{n}: #{totient_sum}  (3n^2/pi^2 ~ #{(3 * n * n / Math::PI**2).round})"

equal_pairs = (1..(n - 1)).select { |k| phi[k] == phi[k + 1] }
puts "k with phi(k) = phi(k+1): #{equal_pairs.take(10).join(" ")} ..."

inverse = {}
(1..n).each do |k|
  v = phi[k]
  next if v > 48
  (inverse[v] ||= []) << k
end
puts "inverse totient (values <= 48):"
inverse.keys.sort.each do |v|
  puts "  phi^-1(#{v}) = #{inverse[v].join(" ")}" if inverse[v].size >= 4
end
missing = (1..48).reject { |v| inverse.key?(v) || v.odd? }
puts "even non-totients <= 48: #{missing.join(" ")}"

mertens = 0
zeros = []
(1..n).each do |k|
  mertens += mu[k]
  zeros << k if mertens == 0
end
puts "Mertens zeros <= #{n}: #{zeros.size}, last at #{zeros.last}"
