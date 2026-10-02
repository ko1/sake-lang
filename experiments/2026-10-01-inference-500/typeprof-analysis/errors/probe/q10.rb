Pt = Struct.new(:x, :y)
pts = [Pt.new(1, 2), Pt.new(0, 5)]
s = pts.sort_by { |pt| [pt.x, pt.y] }
p s.first.x
