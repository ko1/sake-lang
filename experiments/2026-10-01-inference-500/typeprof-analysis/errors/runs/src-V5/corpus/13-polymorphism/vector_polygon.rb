class Vec
  include Comparable
  attr_reader :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end

  def +(b) = Vec.new(@x + b.x, @y + b.y)
  def -(b) = Vec.new(@x - b.x, @y - b.y)
  def *(k) = Vec.new(@x * k, @y * k)
  def /(k) = Vec.new(@x / k, @y / k)
  def <=>(b)
    c = @x <=> b.x
    c == 0 ? @y <=> b.y : c
  end
  def eql?(b) = b.is_a?(Vec) && self == b
  def hash = [@x, @y].hash

  def dot(b) = @x * b.x + @y * b.y
  def cross(b) = @x * b.y - @y * b.x
  def length = Math.sqrt(dot(self))
  def to_s = "(#{@x}, #{@y})"
end

def fmt_vec(v) = format("(%.2f, %.2f)", v.x, v.y)

def shoelace(pts)
  sum = 0
  n = pts.size
  n.times do |i|
    sum += pts[i].cross(pts[(i + 1) % n])
  end
  sum / 2.0
end

def centroid(pts)
  total = pts.reduce(Vec.new(0, 0)) { |acc, p| acc + p }
  total / (pts.size * 1.0)
end

def turn(o, a, b) = (a - o).cross(b - o)

def convex_hull(points)
  pts = points.sort.uniq
  return pts if pts.size < 3
  lower = []
  pts.each do |p|
    lower.pop while lower.size >= 2 && turn(lower[-2], lower[-1], p) <= 0
    lower << p
  end
  upper = []
  pts.reverse_each do |p|
    upper.pop while upper.size >= 2 && turn(upper[-2], upper[-1], p) <= 0
    upper << p
  end
  lower.pop
  upper.pop
  lower.concat(upper)
end

def inside?(poly, q)
  n = poly.size
  inside = false
  j = n - 1
  n.times do |i|
    pi = poly[i]
    pj = poly[j]
    yi = pi.y
    yj = pj.y
    if (yi > q.y) != (yj > q.y)
      xcross = (pj.x - pi.x) * (q.y - yi) / ((yj - yi) * 1.0) + pi.x
      inside = !inside if q.x < xcross
    end
    j = i
  end
  inside
end

cloud = [
  Vec.new(0, 0), Vec.new(4, 0), Vec.new(4, 3), Vec.new(2, 1), Vec.new(1, 2),
  Vec.new(0, 3), Vec.new(2, 5), Vec.new(3, 2), Vec.new(2, 1), Vec.new(5, 1), Vec.new(1, 4)
]

puts "points: #{cloud.size}"
puts "sorted: #{cloud.sort.join(" ")}"
puts "min: #{cloud.min} max: #{cloud.max}"

hull = convex_hull(cloud)
puts "hull: #{hull.join(" -> ")}"
puts format("hull area: %.1f", shoelace(hull))
puts "hull centroid: #{fmt_vec(centroid(hull))}"

perimeter = 0.0
hull.each_with_index do |p, i|
  q = hull[(i + 1) % hull.size]
  perimeter += (q - p).length
end
puts format("hull perimeter: %.3f", perimeter)

interior = cloud.reject { |p| hull.include?(p) }
puts "interior: #{interior.uniq.join(" ")}"

probes = [Vec.new(2, 2), Vec.new(5, 4), Vec.new(1, 1), Vec.new(6, 0), Vec.new(3, 3)]
probes.each do |q|
  where = inside?(hull, q) ? "inside" : "outside"
  puts "#{q} is #{where}"
end

far = cloud.max_by { |p| (p - centroid(cloud)).length }
puts "farthest from centroid: #{far}"

a = Vec.new(3, 4)
b = Vec.new(-1, 2)
puts "a+b=#{a + b} a-b=#{a - b} a*3=#{a * 3} |a|=#{a.length}"
puts "a.b=#{a.dot(b)} axb=#{a.cross(b)}"
puts "a<b? #{a < b} a==Vec(3,4)? #{a == Vec.new(3, 4)}"
cos = a.dot(b) / (a.length * b.length)
puts format("angle: %.2f deg", Math.atan2(a.cross(b), a.dot(b)) * 180 / Math::PI)
puts format("cos: %.4f", cos)
