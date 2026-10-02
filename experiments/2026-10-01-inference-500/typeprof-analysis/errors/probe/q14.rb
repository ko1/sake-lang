class Pt
  attr_reader :x, :y
  def initialize(x, y) = (@x = x; @y = y)
end
pts = [Pt.new(1, 2), Pt.new(0, 5)]
pts.sort_by { |pt| pt.x }
pts.sort_by { |pt| [pt.x] }
