require "set"

class Circle
  attr_accessor :cx, :cy, :r
  def initialize(cx, cy, r)
    @cx = cx
    @cy = cy
    @r = r
  end
  def bounds = [@cx - @r, @cy - @r, @cx + @r, @cy + @r]
  def moved(dx, dy) = Circle.new(@cx + dx, @cy + dy, @r)
  def to_s = format("circle(%.1f,%.1f r%.1f)", @cx, @cy, @r)
end

class Box
  attr_accessor :x0, :y0, :x1, :y1
  def initialize(x0, y0, x1, y1)
    @x0 = x0
    @y0 = y0
    @x1 = x1
    @y1 = y1
  end
  def bounds = [@x0, @y0, @x1, @y1]
  def moved(dx, dy) = Box.new(@x0 + dx, @y0 + dy, @x1 + dx, @y1 + dy)
  def to_s = format("box(%.1f,%.1f..%.1f,%.1f)", @x0, @y0, @x1, @y1)
end

class Dot
  attr_accessor :px, :py
  def initialize(px, py)
    @px = px
    @py = py
  end
  def bounds = [@px, @py, @px, @py]
  def moved(dx, dy) = Dot.new(@px + dx, @py + dy)
  def to_s = format("dot(%.1f,%.1f)", @px, @py)
end

def clamp(v, lo, hi) = v < lo ? lo : (v > hi ? hi : v)

def circle_circle(a, b)
  dx = a.cx - b.cx
  dy = a.cy - b.cy
  rr = a.r + b.r
  dx * dx + dy * dy <= rr * rr
end

def circle_box(c, b)
  nx = clamp(c.cx, b.x0, b.x1)
  ny = clamp(c.cy, b.y0, b.y1)
  dx = c.cx - nx
  dy = c.cy - ny
  dx * dx + dy * dy <= c.r * c.r
end

def box_box(a, b)
  a.x0 <= b.x1 && b.x0 <= a.x1 &&
    a.y0 <= b.y1 && b.y0 <= a.y1
end

def dot_in(d, s)
  case s
  in Circle then circle_circle(Circle.new(d.px, d.py, 0.0), s)
  in Box then box_box(Box.new(d.px, d.py, d.px, d.py), s)
  in Dot then d.px == s.px && d.py == s.py
  end
end

def collide?(a, b)
  case [a, b]
  in [Circle, Circle] then circle_circle(a, b)
  in [Circle, Box] then circle_box(a, b)
  in [Box, Circle] then circle_box(b, a)
  in [Box, Box] then box_box(a, b)
  in [Dot, _] then dot_in(a, b)
  in [_, Dot] then dot_in(b, a)
  end
end

class Body
  attr_accessor :name, :shape, :vx, :vy
  def initialize(name, shape, vx, vy)
    @name = name
    @shape = shape
    @vx = vx
    @vy = vy
  end
end

bodies = [
  Body.new("ball", Circle.new(0.0, 0.0, 1.0), 1.0, 0.5),
  Body.new("crate", Box.new(6.0, 2.0, 8.0, 4.0), 0.0, 0.0),
  Body.new("puck", Circle.new(10.0, 0.0, 0.5), -1.0, 0.0),
  Body.new("bug", Dot.new(3.0, 6.0), 0.5, -0.75),
  Body.new("wall", Box.new(-2.0, -3.0, 12.0, -2.5), 0.0, 0.0),
  Body.new("seed", Dot.new(7.0, 3.0), 0.0, 0.0)
]

puts "== static checks =="
[
  [Circle.new(0.0, 0.0, 1.0), Circle.new(1.5, 0.0, 0.6)],
  [Circle.new(0.0, 0.0, 1.0), Box.new(1.2, 1.2, 2.0, 2.0)],
  [Box.new(0.0, 0.0, 2.0, 2.0), Circle.new(2.5, 1.0, 0.6)],
  [Box.new(0.0, 0.0, 1.0, 1.0), Box.new(1.0, 1.0, 2.0, 2.0)],
  [Dot.new(0.5, 0.5), Box.new(0.0, 0.0, 1.0, 1.0)],
  [Circle.new(0.0, 0.0, 1.0), Dot.new(0.8, 0.8)],
  [Dot.new(1.0, 1.0), Dot.new(1.0, 1.0)]
].each do |a, b|
  puts "#{a} x #{b}: #{collide?(a, b) ? "hit" : "miss"}"
end

puts "== simulation =="
hits = Hash.new(0)
seen = Set[]
(1..8).each do |tick|
  bodies.each { |bd| bd.shape = bd.shape.moved(bd.vx, bd.vy) }
  events = []
  bodies.each_with_index do |a, i|
    bodies.drop(i + 1).each do |b|
      next unless collide?(a.shape, b.shape)
      pair = [a.name, b.name]
      hits[pair] += 1
      events << "#{a.name}+#{b.name}"
      events << "(first contact)" if seen.add?(pair)
    end
  end
  puts format("t=%d %s", tick, events.empty? ? "-" : events.join(" "))
end

puts "== final positions =="
bodies.each do |bd|
  x0, y0, x1, y1 = bd.shape.bounds
  puts format("%-6s %-28s bbox %.1f..%.1f x %.1f..%.1f", bd.name, bd.shape.to_s, x0, x1, y0, y1)
end

puts "== contact counts =="
hits.each { |pair, n| puts "#{pair[0]}/#{pair[1]}: #{n} tick(s)" }
most = hits.max_by { |e__0| pair, n = e__0; n }
puts "longest contact: #{most[0][0]} & #{most[0][1]}" if most
untouched = bodies.select { |bd| hits.none? { |pair, n| pair[0] == bd.name || pair[1] == bd.name } }
puts "never touched: #{untouched.map(&:name).join(", ")}"
