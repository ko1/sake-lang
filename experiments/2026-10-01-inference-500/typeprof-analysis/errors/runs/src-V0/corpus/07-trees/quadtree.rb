class Rect
  attr_reader :x, :y, :w, :h

  def initialize(x, y, w, h)
    @x = x
    @y = y
    @w = w
    @h = h
  end

  def contains?(p) = x <= p.x && p.x < x + w && y <= p.y && p.y < y + h
  def intersects?(o) = x < o.x + o.w && o.x < x + w && y < o.y + o.h && o.y < y + h
  def to_s = "(#{x},#{y} #{w}x#{h})"
end

class Pt
  attr_reader :x, :y, :label

  def initialize(x, y, label)
    @x = x
    @y = y
    @label = label
  end
end

class OutOfBounds < StandardError
  attr_reader :point

  def initialize(message, point)
    super(message)
    @point = point
  end
end

CAPACITY = 3
MAX_DEPTH = 5

class Quad
  attr_reader :bounds, :points, :kids, :depth

  def initialize(bounds, depth)
    @bounds = bounds
    @points = []
    @kids = []
    @depth = depth
  end

  def insert(p)
    raise OutOfBounds.new("#{p.label} at (#{p.x},#{p.y}) is outside #{bounds}", p) unless bounds.contains?(p)
    if kids.empty?
      if points.size < CAPACITY || depth == MAX_DEPTH
        points << p
        return self
      end
      subdivide
    end
    kids.find { |k| k.bounds.contains?(p) }.insert(p)
  end

  def query(area, out, stats)
    stats[:visited] += 1
    return out unless bounds.intersects?(area)
    points.each { |p| out << p if area.contains?(p) }
    kids.each { |k| k.query(area, out, stats) }
    out
  end

  def count = points.size + kids.sum(&:count)
  def nodes = 1 + kids.sum(&:nodes)
  def height = kids.empty? ? 1 : 1 + kids.map(&:height).max

  def dump(indent)
    if kids.empty?
      labels = points.map(&:label)
      puts "#{indent}#{bounds} #{labels.empty? ? "-" : labels.join(" ")}"
    else
      puts "#{indent}#{bounds}"
      kids.each { |k| k.dump(indent + "  ") }
    end
  end

  private

  def subdivide
    hw = bounds.w / 2
    hh = bounds.h / 2
    x = bounds.x
    y = bounds.y
    kids.push(Quad.new(Rect.new(x, y, hw, hh), depth + 1), Quad.new(Rect.new(x + hw, y, hw, hh), depth + 1),
              Quad.new(Rect.new(x, y + hh, hw, hh), depth + 1), Quad.new(Rect.new(x + hw, y + hh, hw, hh), depth + 1))
    old = points.dup
    points.clear
    old.each { |p| insert(p) }
  end
end

world = Quad.new(Rect.new(0, 0, 64, 64), 0)
readings = <<~TXT
  a 3 4
  b 60 2
  c 10 12
  d 12 10
  e 33 40
  f 35 41
  g 34 44
  h 36 46
  i 50 50
  j 8 9
  k 11 11
  l 70 5
  m 9 13
  n 62 62
TXT
readings.each_line do |line|
  label, x, y = line.split(" ")
  begin
    world.insert(Pt.new(x.to_i, y.to_i, label))
  rescue OutOfBounds => e
    puts "skip: #{e.message}"
  end
end
puts "points #{world.count}, nodes #{world.nodes}, height #{world.height}"
world.dump("")

areas = [Rect.new(0, 0, 16, 16), Rect.new(30, 38, 8, 8), Rect.new(40, 0, 24, 24), Rect.new(0, 0, 64, 64)]
areas.each do |area|
  stats = { visited: 0 }
  hits = world.query(area, [], stats)
  puts "query #{area}: #{hits.size} hit(s) [#{hits.map(&:label).sort.join(",")}] visiting #{stats[:visited]} of #{world.nodes} nodes"
end

dense = Quad.new(Rect.new(0, 0, 64, 64), 0)
6.times { |i| dense.insert(Pt.new(1, 1, "p#{i}")) }
puts "same spot x6: nodes #{dense.nodes}, height #{dense.height} (depth capped at #{MAX_DEPTH})"
