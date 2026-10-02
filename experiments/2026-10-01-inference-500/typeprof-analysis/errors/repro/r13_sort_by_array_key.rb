# sort_by/min_by/max_by with an Array key: the key's element types leak into the receiver's element type.
class Pt
  attr_reader :x, :y
  def initialize(x, y) = (@x = x; @y = y)
end
pts = [Pt.new(1, 2), Pt.new(0, 5)]
p pts.sort_by { |pt| [pt.x, pt.y] }.first.x
