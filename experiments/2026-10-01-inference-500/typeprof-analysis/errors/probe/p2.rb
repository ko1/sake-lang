class A
  def to_s = "A"
end
class B
  def initialize(a) = @a = a
  def to_s = @a.map { it.to_s }.join
end
class D
  def initialize(a) = @a = a
  def to_s = @a.map { |x| x.to_s }.join
end
class E
end
puts A.new
puts B.new([1])
puts D.new([1])
puts E.new
x = [1, 2].sum { |v| v * 1.5 }
y = [1, 2.0][0]
puts Math.sqrt(y)
z = 1.0 * y
w = y * 2
p z, w
n = [1, nil][0]
v = 3 + n.to_i
p v
