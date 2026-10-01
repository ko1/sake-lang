class J
  attr_accessor :r
  def initialize = @r = 0
  def d = "j"
end
class Q
  def initialize(p) = @p = p
  def add(j) = @p << j
  def all = @p
end
q = Q.new([])
j = J.new
j.r = 1 + 2
q.add(j)
q.all.each { |x| puts x.d }
