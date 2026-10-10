# loops.rb with the loop inside a method: YJIT compiles methods that are called often, not the top level.
def main(u)
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
end
main(ARGV[0].to_i)
