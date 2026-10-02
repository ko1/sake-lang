class Pt
  attr_reader :x, :y
  def initialize(x, y) = (@x = x; @y = y)
end
pts = [Pt.new(1, 2), Pt.new(0, 5)].map { _1 }
pts.sort_by { |pt| [pt.x, pt.y] }
