# The "loops" micro benchmark, in Ruby: the same program as loops.sake.
u = ARGV[0].to_i
r = rand(10000)
a = Array.new(10000, 0)
i = 0
while i < 10000
  j = 0
  while j < 100000
    a[i] = a[i] + j % u
    j += 1
  end
  a[i] = a[i] + r
  i += 1
end
puts(a[r])
