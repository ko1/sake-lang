def from_call(s)
  a, b = s.split(",")
  a
end
def from_literal
  a, b = ["x", "y"]
  a
end
def from_local(s)
  parts = s.split(",")
  a, b = parts
  a
end
def from_map(xs)
  a, b = xs.map { |x| x * 2 }
  a
end
p from_call("x,y"), from_literal, from_local("x,y"), from_map([1, 2])
