def f1(s)
  m = s.match(/(\d+)/)
  return 0 unless m
  m[1].to_i
end
def f2(s)
  if (m = s.match(/(\d+)/))
    m[1].to_i
  end
end
def f3(a)
  x = a.first
  return 0 if x.nil?
  x + 1
end
def f4(a)
  x = a.first
  x ? x + 1 : 0
end
def f5(a)
  x = a.first
  x&.+(1)
end
class C
  def initialize; @v = nil; end
  def set; @v = 1; end
  def get; @v + 1 if @v; end
  def get2; return 0 unless @v; @v + 1; end
end
p f1("a1"), f2("b2"), f3([1]), f4([1]), f5([1])
c = C.new; c.set; p c.get, c.get2
