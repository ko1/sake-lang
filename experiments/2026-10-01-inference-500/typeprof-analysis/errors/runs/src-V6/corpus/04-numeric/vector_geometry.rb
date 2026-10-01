class Vec3
  include Comparable
  attr_reader :x, :y, :z

  def initialize(x, y, z)
    @x = x
    @y = y
    @z = z
  end

  def +(b) = Vec3.new(@x + b.x, @y + b.y, @z + b.z)
  def -(b) = Vec3.new(@x - b.x, @y - b.y, @z - b.z)
  def *(k) = Vec3.new(@x * k, @y * k, @z * k)
  def /(k) = Vec3.new(@x / k, @y / k, @z / k)
  def <=>(b) = norm <=> b.norm

  def dot(b) = @x * b.x + @y * b.y + @z * b.z

  def cross(b)
    Vec3.new(@y * b.z - @z * b.y, @z * b.x - @x * b.z, @x * b.y - @y * b.x)
  end

  def norm = Math.sqrt(dot(self))

  def unit
    n = norm
    return nil if n < 1e-12
    self / n
  end

  def angle_deg(b)
    Math.atan2(cross(b).norm, dot(b)) * 180.0 / Math::PI
  end

  def project(onto) = onto * (dot(onto) / onto.dot(onto))

  def to_s = format("(%.4f, %.4f, %.4f)", @x, @y, @z)
end

def gram_schmidt(vs)
  basis = []
  vs.each do |v|
    w = v
    basis.each { |e| w -= w.project(e) }
    u = w.unit
    if u
      basis << u
    else
      puts "  dropped dependent vector #{v}"
    end
  end
  basis
end

class Triangle
  attr_reader :name, :a, :b, :c

  def initialize(name, a, b, c)
    @name = name
    @a = a
    @b = b
    @c = c
  end

  def normal = (@b - @a).cross(@c - @a)
  def area = normal.norm / 2.0
  def centroid = (@a + @b + @c) / 3.0
end

a = Vec3.new(1.0, 2.0, 2.0)
b = Vec3.new(3.0, 0.0, -4.0)
puts "a = #{a}, |a| = #{format("%.4f", a.norm)}"
puts "b = #{b}, |b| = #{format("%.4f", b.norm)}"
puts "a + b = #{a + b}"
puts "a x b = #{a.cross(b)}"
puts format("a . b = %.4f, angle = %.3f deg", a.dot(b), a.angle_deg(b))
puts "proj_b a = #{a.project(b)}"
puts "a < b: #{a < b}, longest: #{[a, b, a + b].max}"

puts "Gram-Schmidt:"
vs = [Vec3.new(1.0, 1.0, 0.0), Vec3.new(1.0, 0.0, 1.0), Vec3.new(2.0, 1.0, 1.0), Vec3.new(0.0, 1.0, 1.0)]
basis = gram_schmidt(vs)
basis.each { |e| puts "  #{e}" }
max_off = 0.0
basis.each_with_index do |e, i|
  basis.each_with_index do |f, j|
    next if i >= j
    max_off = [max_off, e.dot(f).abs].max
  end
end
puts format("  max |e_i . e_j| = %.2e", max_off)

mesh = [
  Triangle.new("base1", Vec3.new(0.0, 0.0, 0.0), Vec3.new(1.0, 0.0, 0.0), Vec3.new(0.0, 1.0, 0.0)),
  Triangle.new("side", Vec3.new(0.0, 0.0, 0.0), Vec3.new(0.0, 0.0, 1.0), Vec3.new(1.0, 0.0, 0.0)),
  Triangle.new("slant", Vec3.new(1.0, 0.0, 0.0), Vec3.new(0.0, 0.0, 1.0), Vec3.new(0.0, 1.0, 0.0)),
  Triangle.new("sliver", Vec3.new(0.0, 0.0, 0.0), Vec3.new(1.0, 1.0, 1.0), Vec3.new(2.0, 2.0, 2.0))
]
total = 0.0
mesh.each do |t|
  ar = t.area
  total += ar
  n = t.normal.unit
  shown = n ? n.to_s : "degenerate"
  puts format("%-7s area=%.6f centroid=%s normal=%s", t.name, ar, t.centroid, shown)
end
puts format("total area = %.6f", total)
biggest = mesh.max_by(&:area)
puts "largest: #{biggest.name}"
sorted = mesh.map(&:normal).sort
puts "normals by length: #{sorted.map { |v| format("%.3f", v.norm) }.join(" < ")}"
