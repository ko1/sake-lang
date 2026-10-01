# Factoring with Pollard's rho (Floyd and Brent cycle finding) and Pollard's p-1,
# compared by iteration counts on semiprimes and larger composites.

class Result
  attr_reader :factor, :iterations, :method

  def initialize(factor, iterations, method)
    @factor = factor
    @iterations = iterations
    @method = method
  end
end

def isqrt_exact?(n)
  r = Integer.sqrt(n)
  r * r == n
end

def prime?(n)
  return false if n < 2
  bases = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37]
  bases.each { |p| return n == p if n % p == 0 }
  d = n - 1
  s = 0
  while d.even?
    d /= 2
    s += 1
  end
  bases.all? do |a|
    x = a.pow(d, n)
    next true if x == 1 || x == n - 1
    (s - 1).times.any? do
      x = x * x % n
      x == n - 1
    end
  end
end

def rho_floyd(n, c)
  x = 2
  y = 2
  d = 1
  steps = 0
  while d == 1
    x = (x * x + c) % n
    y = (y * y + c) % n
    y = (y * y + c) % n
    d = (x - y).abs.gcd(n)
    steps += 1
  end
  d == n ? nil : Result.new(d, steps, "floyd")
end

def rho_brent(n, c)
  y = 2
  r = 1
  d = 1
  steps = 0
  while d == 1
    x = y
    r.times { y = (y * y + c) % n }
    k = 0
    while k < r && d == 1
      y = (y * y + c) % n
      d = (x - y).abs.gcd(n)
      steps += 1
      k += 1
    end
    r *= 2
  end
  d == n ? nil : Result.new(d, steps, "brent")
end

def pollard_p1(n, bound)
  a = 2
  (2..bound).each do |j|
    a = a.pow(j, n)
    g = (a - 1).gcd(n)
    return Result.new(g, j, "p-1") if g > 1 && g < n
    return nil if g == n
  end
  nil
end

def find_factor(n)
  (1...20).each do |c|
    r = rho_brent(n, c)
    return r.factor if r
  end
  raise "no factor found for #{n}"
end

def factorize(n)
  return [] if n == 1
  return [n] if prime?(n)
  return [2] + factorize(n / 2) if n.even?
  if isqrt_exact?(n)
    half = factorize(Integer.sqrt(n))
    return (half + half).sort
  end
  f = find_factor(n)
  (factorize(f) + factorize(n / f)).sort
end

def show(r) = r ? "#{r.factor} in #{r.iterations}" : "failed"

semiprimes = [8051, 10403, 455459, 1022117, 999962000357, 600851475143]
puts format("%-14s %-16s %-16s %-16s", "n", "floyd", "brent", "p-1 (B=200)")
semiprimes.each do |n|
  puts format("%-14d %-16s %-16s %-16s", n, show(rho_floyd(n, 1)), show(rho_brent(n, 1)), show(pollard_p1(n, 200)))
end

puts "full factorizations:"
[600851475143, 2**32 + 1, 2**48 - 1, 1000036000099, 3**20 * 7, 123456789012].each do |n|
  fs = factorize(n)
  prod = fs.reduce(1, :*)
  grouped = fs.tally.map { |p, e| e > 1 ? "#{p}^#{e}" : p.to_s }
  puts "  #{n} = #{grouped.join(" * ")}#{prod == n ? "" : "  MISMATCH"}"
end
