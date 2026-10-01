class J
  attr_accessor :a, :b
  def initialize = (@a = 0; @b = [])
end
def t1(j)
  j.a += 1
  j
end
def t2(j)
  j.b << "s"
  j
end
def t3(j)
  j.a = 5
  j
end
p t1(J.new), t2(J.new), t3(J.new)
