# An implicit-self call at the top level resolves to a same-named method of an unrelated class.
class Edge
  attr_reader :distance
  def initialize(d) = @distance = d
end
def distance(a, b) = (a - b).abs
p distance(3, 1)
p Edge.new(2).distance
