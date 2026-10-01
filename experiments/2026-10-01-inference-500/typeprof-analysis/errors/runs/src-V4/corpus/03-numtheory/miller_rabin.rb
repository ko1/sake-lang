# Primality testing: trial division vs. Fermat vs. deterministic Miller-Rabin.
# Finds Carmichael numbers (Fermat liars) and strong pseudoprimes to base 2.

def trial_division?(n)
  return false if n < 2
  return true if n < 4
  return false if n.even?
  d = 3
  while d * d <= n
    return false if n % d == 0
    d += 2
  end
  true
end

def fermat_probable?(n, base)
  return n == 2 if n <= 2
  base.pow(n - 1, n) == 1
end

def decompose(n)
  d = n - 1
  s = 0
  while d.even?
    d /= 2
    s += 1
  end
  [s, d]
end

def strong_probable?(n, a)
  return true if a % n == 0
  s, d = decompose(n)
  x = a.pow(d, n)
  return true if x == 1 || x == n - 1
  (s - 1).times do
    x = x * x % n
    return true if x == n - 1
  end
  false
end

def witnesses = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37]

def miller_rabin?(n)
  return false if n < 2
  small = witnesses.find { |p| n % p == 0 }
  return n == small if small
  witnesses.all? { |a| strong_probable?(n, a) }
end

puts "agreement check on 1..2000:"
mismatch = (1..2000).select { |n| trial_division?(n) != miller_rabin?(n) }
puts "  mismatches: #{mismatch.size}"

carmichael = []
3.step(5000, 2) do |n|
  next if trial_division?(n)
  liar = [2, 3, 5, 7, 11, 13].all? { |a| a.gcd(n) != 1 || fermat_probable?(n, a) }
  carmichael << n if liar
end
puts "Carmichael-like composites <= 5000 (Fermat liars to all small coprime bases): #{carmichael.join(" ")}"

spsp2 = (3..5000).select { |n| n.odd? && !trial_division?(n) && strong_probable?(n, 2) }
puts "strong pseudoprimes to base 2 <= 5000: #{spsp2.join(" ")}"
fpsp2 = (3..5000).count { |n| n.odd? && !trial_division?(n) && fermat_probable?(n, 2) }
puts "Fermat pseudoprimes to base 2 <= 5000: #{fpsp2}"

puts "large candidates:"
cands = [2**31 - 1, 2**61 - 1, 2**67 - 1, 1000000007, 1000000007 * 998244353, 561 * 1105, 3825123056546413051, 2**89 - 1]
cands.each do |c|
  verdict = miller_rabin?(c) ? "prime" : "composite"
  s, _d = decompose(c)
  puts format("  %-28s %-9s (n-1 = 2^%d * odd)", c.to_s, verdict, s)
end

puts "next primes after powers of ten:"
(1..12).each do |k|
  m = 10**k + 1
  m += 1 until miller_rabin?(m)
  puts "  10^#{k} + #{m - 10**k}"
end
