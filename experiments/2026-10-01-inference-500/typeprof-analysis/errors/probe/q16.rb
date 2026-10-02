class S
  def d = @d
  def initialize(d) = @d = d
end
def d(a, b) = a - b
def f = d(3, 1)
p f
p S.new(1).d
