def deg(d) = d * Math::PI / 180.0
def fmt(x) = format("%.3f", x.abs < 0.0005 ? 0.0 : x)

class Vec3
  attr_reader :x, :y, :z
  def initialize(x, y, z)
    @x = x
    @y = y
    @z = z
  end
  def +(b) = Vec3.new(@x + b.x, @y + b.y, @z + b.z)
  def -(b) = Vec3.new(@x - b.x, @y - b.y, @z - b.z)
  def *(k) = Vec3.new(@x * k, @y * k, @z * k)
  def dot(b) = @x * b.x + @y * b.y + @z * b.z
  def cross(b)
    Vec3.new(@y * b.z - @z * b.y,
             @z * b.x - @x * b.z,
             @x * b.y - @y * b.x)
  end
  def length = Math.sqrt(dot(self))
  def to_s = "(#{fmt(@x)}, #{fmt(@y)}, #{fmt(@z)})"
end

class Quat
  attr_reader :w, :x, :y, :z

  def initialize(w, x, y, z)
    @w = w
    @x = x
    @y = y
    @z = z
  end

  def self.identity = Quat.new(1.0, 0.0, 0.0, 0.0)

  def self.axis_angle(axis, angle)
    n = axis.length
    s = Math.sin(angle / 2.0) / n
    Quat.new(Math.cos(angle / 2.0), axis.x * s, axis.y * s, axis.z * s)
  end

  def +(b) = Quat.new(@w + b.w, @x + b.x, @y + b.y, @z + b.z)
  def -(b) = Quat.new(@w - b.w, @x - b.x, @y - b.y, @z - b.z)

  def *(b)
    case b
    in Quat
      bw = b.w
      bx = b.x
      by = b.y
      bz = b.z
      Quat.new(@w * bw - @x * bx - @y * by - @z * bz,
               @w * bx + @x * bw + @y * bz - @z * by,
               @w * by - @x * bz + @y * bw + @z * bx,
               @w * bz + @x * by - @y * bx + @z * bw)
    in Integer | Float
      Quat.new(@w * b, @x * b, @y * b, @z * b)
    end
  end

  def conjugate = Quat.new(@w, -@x, -@y, -@z)
  def dot(b) = @w * b.w + @x * b.x + @y * b.y + @z * b.z
  def norm = Math.sqrt(dot(self))
  def normalize = self * (1.0 / norm)
  def vector = Vec3.new(@x, @y, @z)

  def rotate(v)
    p = Quat.new(0.0, v.x, v.y, v.z)
    (self * p * conjugate).vector
  end

  def angle = 2 * Math.atan2(vector.length, @w)

  def slerp(b, t)
    d = dot(b)
    if d < 0
      b = b * -1
      d = -d
    end
    return (self + (b - self) * t).normalize if d > 0.9995
    theta = Math.acos(d)
    sa = Math.sin((1 - t) * theta) / Math.sin(theta)
    sb = Math.sin(t * theta) / Math.sin(theta)
    self * sa + b * sb
  end

  def to_s = "[#{fmt(@w)}; #{fmt(@x)}, #{fmt(@y)}, #{fmt(@z)}]"
end

class Body
  attr_accessor :name, :points, :orientation
  def initialize(name, points, orientation)
    @name = name
    @points = points
    @orientation = orientation
  end
end

def describe(body)
  q = body.orientation
  pts = body.points.map { |p| q.rotate(p) }
  puts "#{body.name}: orientation #{q} (#{fmt(q.angle * 180 / Math::PI)} deg)"
  pts.each { |p| puts "  #{p}" }
  pts
end

x_axis = Vec3.new(1.0, 0.0, 0.0)
y_axis = Vec3.new(0.0, 1.0, 0.0)
z_axis = Vec3.new(0.0, 0.0, 1.0)

qz = Quat.axis_angle(z_axis, deg(90))
qx = Quat.axis_angle(x_axis, deg(90))
puts "qz = #{qz}, |qz| = #{fmt(qz.norm)}"
puts "qx = #{qx}"
puts "rotate x by qz: #{qz.rotate(x_axis)}"
puts "rotate y by qx: #{qx.rotate(y_axis)}"

both = qx * qz
puts "qx * qz = #{both}"
puts "x by (qx * qz): #{both.rotate(x_axis)}"
puts "x by qz then qx: #{qx.rotate(qz.rotate(x_axis))}"
puts "x by (qz * qx): #{(qz * qx).rotate(x_axis)}  (order matters)"
puts "q * conj(q) = #{qz * qz.conjugate}"
puts "scaled: #{qz * 2}, normalized back: #{(qz * 2).normalize}"

square = [Vec3.new(1.0, 1.0, 0.0), Vec3.new(-1.0, 1.0, 0.0), Vec3.new(-1.0, -1.0, 0.0), Vec3.new(1.0, -1.0, 0.0)]
bodies = [
  Body.new("flat", square, Quat.identity),
  Body.new("tilted", square, Quat.axis_angle(Vec3.new(1.0, 1.0, 0.0), deg(60))),
  Body.new("spun", square, Quat.axis_angle(z_axis, deg(45)) * Quat.axis_angle(x_axis, deg(30)))
]

bodies.each do |b|
  pts = describe(b)
  normal = (pts[1] - pts[0]).cross(pts[2] - pts[1])
  normal = normal * (1.0 / normal.length)
  top = pts.max_by(&:z)
  puts "  normal #{normal}, highest corner #{top}"
end

puts "slerp identity -> qz:"
[0.0, 0.25, 0.5, 0.75, 1.0].each do |t|
  q = Quat.identity.slerp(qz, t)
  puts "  t=#{t} #{q.rotate(x_axis)} angle #{fmt(q.angle * 180 / Math::PI)}"
end

steps = (1..12).reduce(Quat.identity) { |acc, i| Quat.axis_angle(z_axis, deg(30)) * acc }
puts "12 x 30 deg about z: #{steps} -> x maps to #{steps.rotate(x_axis)}"
drift = (steps.norm - 1.0).abs
puts "norm drift < 1e-9: #{drift < 0.000000001}"
