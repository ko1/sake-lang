module Shape
  def area = raise("#{name}: area not implemented")
  def perimeter = raise("#{name}: perimeter not implemented")
  def name = "shape"
  def scale(k) = raise("#{name}: scale not implemented")

  def describe
    format("%-10s area=%8.3f perimeter=%7.3f", name, area, perimeter)
  end

  def compactness = 4 * Math::PI * area / (perimeter * perimeter)
end

class Circle
  include Shape
  attr_reader :r
  def initialize(r)
    @r = r
  end
  def area = Math::PI * @r * @r
  def perimeter = 2 * Math::PI * @r
  def name = "circle"
  def scale(k) = Circle.new(@r * k)
end

class Rect
  include Shape
  attr_reader :w, :h
  def initialize(w, h)
    @w = w
    @h = h
  end
  def area = @w * @h * 1.0
  def perimeter = 2.0 * (@w + @h)
  def name = @w == @h ? "square" : "rect"
  def scale(k) = Rect.new(@w * k, @h * k)
end

class Triangle
  include Shape
  attr_reader :a, :b, :c
  def initialize(a, b, c)
    @a = a
    @b = b
    @c = c
  end
  def area
    s = perimeter / 2.0
    Math.sqrt(s * (s - @a) * (s - @b) * (s - @c))
  end
  def perimeter = (@a + @b + @c) * 1.0
  def name = "triangle"
  def scale(k) = Triangle.new(@a * k, @b * k, @c * k)
  def valid? = @a + @b > @c && @a + @c > @b && @b + @c > @a
end

class RegularPolygon
  include Shape
  attr_reader :sides, :len
  def initialize(sides, len)
    @sides = sides
    @len = len
  end
  def area = @sides * @len * @len / (4.0 * Math.tan(Math::PI / @sides))
  def perimeter = @sides * @len * 1.0
  def name = "#{@sides}-gon"
  def scale(k) = RegularPolygon.new(@sides, @len * k)
end

def build_shapes
  shapes = []
  shapes << Circle.new(1.5)
  shapes << Rect.new(3, 4)
  shapes << Rect.new(2.5, 2.5)
  t = Triangle.new(3, 4, 5)
  shapes << t if t.valid?
  bad = Triangle.new(1, 2, 10)
  shapes << bad if bad.valid?
  shapes << RegularPolygon.new(6, 2)
  shapes << RegularPolygon.new(5, 1.2)
  shapes << Circle.new(0.5)
  shapes
end

shapes = build_shapes
puts "== all shapes =="
shapes.each { |s| puts s.describe }

total = shapes.sum(&:area)
puts format("total area: %.3f", total)

puts "== by area =="
sorted = shapes.sort_by(&:area)
sorted.each_with_index { |s, i| puts format("%d. %s (%.2f)", i + 1, s.name, s.area) }

largest = shapes.max_by(&:perimeter)
puts "longest perimeter: #{largest.name}" if largest

puts "== compactness =="
shapes.each do |s|
  c = s.compactness
  label = c > 0.9 ? "round" : (c > 0.7 ? "chunky" : "thin")
  puts format("%-10s %.4f %s", s.name, c, label)
end

puts "== doubled =="
doubled = shapes.map { |s| s.scale(2) }
doubled.each_with_index do |d, i|
  ratio = d.area / shapes[i].area
  puts format("%-10s x%.1f", d.name, ratio)
end

groups = shapes.group_by(&:name)
puts "== groups =="
groups.each { |name, members| puts "#{name}: #{members.size}" }

big = shapes.select { |s| s.area > 10 }
puts "big: #{big.map(&:name).join(", ")}"
first_small = shapes.find { |s| s.area < 1 }
if first_small
  puts "first small: #{first_small.describe}"
else
  puts "no small shape"
end
