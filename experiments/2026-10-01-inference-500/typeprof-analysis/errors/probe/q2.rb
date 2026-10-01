class Q
  def initialize(xs) = @xs = xs
  def add(x) = @xs << x
  def all = @xs
end
q1 = Q.new([])
q2 = Q.new([])
q1.add(1)
q2.add("s")
q1.all.each { |x| p(x + 1) }
