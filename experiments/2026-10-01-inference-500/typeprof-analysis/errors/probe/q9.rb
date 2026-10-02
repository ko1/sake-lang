class Car
  attr_reader :id, :floor
  def initialize(id, floor) = (@id = id; @floor = floor)
end
cars = [Car.new("A", 0), Car.new("B", 9)]
best = cars.min_by { |c| [c.floor, c.id] }
p best.id
