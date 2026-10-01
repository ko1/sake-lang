def g = [1, 2].find { |v| v > 1 }
def n1(x = g) = !x      || x.even?
def n3(x = g) = !x      ? 0 : x + 1
def n4(x = g)
  until !x
    return x + 1
  end
end
def n15(x = g)
  if !!x
    x + 1
  end
end
def n16(x = g)
  x = 3 if !x
  x + 1
end
def n17(x = g, y = g)
  return 0 if !x || !y
  x + y
end
class C
  def initialize = @v = nil
  def set = @v = 1
  def a = (@v ? @v + 1 : 0)
  def b
    if @v
      @v + 1
    end
  end
  def c
    return 0 unless @v
    @v + 1
  end
  def d
    v = @v
    return 0 unless v
    v + 1
  end
end
c = C.new; c.set
p [n1, n3, n4, n15, n16, n17, c.a, c.b, c.c, c.d]
