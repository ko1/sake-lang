require "prime"

# each with a bound
Prime.each(30) { |p| print(p, " ") }
puts
xs = []
Prime.each(2) { |p| xs.push(p) }
p(xs)
Prime.each(1) { |p| xs.push(p) }
p(xs)
p(Prime.each(10) { |q| q * 10 })
Prime.each(12).each_with_index { |q, i| print(i, ":", q, " ") }
puts

# first / take / take_while / find
p(Prime.first(10))
p(Prime.first(0))
p(Prime.first(1000).last)
p(Prime.take(3))
p(Prime.take_while { |q| q < 40 })
p(Prime.find { |q| q > 1000 })
p(Prime.each(50).to_a)

# prime?
p((-5..40).select { |n| Prime.prime?(n) })
p(Prime.prime?(1))
p(Prime.prime?(2147483647))
p(Prime.prime?(2147483649))
p(Prime.prime?(1_000_000_007))
p(Prime.prime?(561))
p(97.prime?)
p((1_000_000_007 * 998_244_353).prime?)
p((2 ** 61 - 1).prime?)
p(Prime.include?(13))

# prime_division and back
[1, 2, 12, 360, 97, 1024, 1001, -12, -1, 600851475143, 2 ** 31 - 1, 3 ** 20 * 7].each do |n|
  pd = Prime.prime_division(n)
  puts("#{n}: #{pd.inspect} -> #{Prime.int_from_prime_division(pd)}")
end
p(84.prime_division)
p(Integer.from_prime_division(84.prime_division))
p(Prime.int_from_prime_division([]))
begin
  Prime.prime_division(0)
rescue ZeroDivisionError => e
  puts("ZeroDivisionError: #{e.message}")
end

# Integer.each_prime
s = 0
Integer.each_prime(100) { |q| s += q }
p(s)

# a small use: Euler's totient from the factorization
def phi(n) = Prime.prime_division(n).inject(n) { |acc, (q, _)| acc / q * (q - 1) }
p((1..20).map { |n| phi(n) })
