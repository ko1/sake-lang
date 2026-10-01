def pair = [1, "a"]
def from_tuple
  a, b = pair
  b
end
def from_partition(s)
  whole, _dot, frac = s.partition(".")
  frac
end
p from_tuple, from_partition("1.5")
