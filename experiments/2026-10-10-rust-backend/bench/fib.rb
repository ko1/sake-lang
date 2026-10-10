# The "fibonacci" micro benchmark, in Ruby: the same program as fib.sake.
def fib(n)
  return n if n < 2
  fib(n - 1) + fib(n - 2)
end

u = ARGV[0].to_i
r = 0
i = 1
while i < u
  r += fib(i)
  i += 1
end
puts(r)
