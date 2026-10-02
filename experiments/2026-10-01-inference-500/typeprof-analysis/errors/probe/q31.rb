def g = [1, 2].find { |v| v > 1 }
def w1
  while (m = g) && m
    return m + 1
  end
end
class A; def a = 1; end
class B; def b = 2; end
def w2(x)
  while x.is_a?(A)
    return x.a
  end
  0
end
def by(xs)
  xs.map { |x| yield(x) }
end
p by(["a"], &:upcase)
p((2**3).even?)
class Model
  def score = 2 * nparams
end
class Line < Model
  def nparams = 2
end
p Line.new.score
p w1
p w2(A.new)
p w2(B.new)
