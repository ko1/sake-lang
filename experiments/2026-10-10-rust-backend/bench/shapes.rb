# The "shapes" micro benchmark in Ruby: the same program as shapes.sake, with a polymorphic method call.
module Shape
  def describe = "#{name}: #{area}"
end

class Circle
  include Shape
  def initialize(r) = @r = r
  def area = 3 * @r * @r
  def name = "circle"
end

class Rect
  include Shape
  def initialize(w, h)
    @w = w
    @h = h
  end
  def area = @w * @h
  def name = "rect"
end

class Tri
  include Shape
  def initialize(b, h)
    @b = b
    @h = h
  end
  def area = @b * @h / 2
  def name = "tri"
end

def run(rounds)
  shapes = []
  i = 0
  while i < 1000
    case i % 3
    in 0 then shapes.push(Circle.new(i))
    in 1 then shapes.push(Rect.new(i, 2))
    else shapes.push(Tri.new(i, 4))
    end
    i += 1
  end
  total = 0
  k = 0
  while k < rounds
    shapes.each { |s| total += s.area }
    k += 1
  end
  puts(total)
  puts(shapes[1].describe)
end
run(ARGV[0].to_i)
