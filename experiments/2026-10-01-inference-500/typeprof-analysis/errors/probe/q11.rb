class Pt
  attr_reader :x, :y
  def initialize(x, y) = (@x = x; @y = y)
end
pts = [Pt.new(1, 2), Pt.new(0, 5)]
s = pts.sort_by { |pt| [pt.x, pt.y] }
p s.first.x
m = pts.max_by { |pt| [pt.x, pt.y] }
