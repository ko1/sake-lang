# `a, b = ary` with ary : Array[T] binds the whole array to `a` and nothing to `b`.
def minutes(s)
  h, m = s.split(":").map(&:to_i)
  h * 60 + m
end
p minutes("09:30")
