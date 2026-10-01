def g = [1, 2].find { |v| v > 1 }
def n1(x = g) = x.nil? || x.even?
def n2(x = g) = x == nil ? 0 : x + 1
def a2
  while (m = g)
    return m + 1
  end
end
p n1, n2, a2
