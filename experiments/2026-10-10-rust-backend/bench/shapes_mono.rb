# shapes.rb with one class only: the control for the cost of a polymorphic call.
module Shape
  def describe = "#{name}: #{area}"
end

class Circle
  include Shape
  def initialize(r) = @r = r
  def area = 3 * @r * @r
  def name = "circle"
end

def run(rounds)
  shapes = []
  i = 0
  while i < 1000
    shapes.push(Circle.new(i))
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
