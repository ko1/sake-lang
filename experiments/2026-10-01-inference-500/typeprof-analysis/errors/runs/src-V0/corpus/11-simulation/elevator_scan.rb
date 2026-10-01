require "set"

class Rider
  attr_reader :name, :from, :to, :called_at
  attr_accessor :boarded_at, :arrived_at

  def initialize(name, from, to, called_at)
    @name = name
    @from = from
    @to = to
    @called_at = called_at
    @boarded_at = nil
    @arrived_at = nil
  end
end

TOP_FLOOR = 9

def direction_to(from, to)
  if to > from
    :up
  elsif to < from
    :down
  else
    :idle
  end
end

class Car
  attr_reader :id, :floor, :dir, :riders, :stops, :moves

  def initialize(id, floor)
    @id = id
    @floor = floor
    @dir = :idle
    @riders = []
    @stops = Set.new
    @moves = 0
  end

  def to_s = "car #{@id} @#{@floor} #{@dir} load=#{@riders.size}"

  def cost(floor, dir)
    distance = (@floor - floor).abs
    return distance if @dir == :idle
    heading = direction_to(@floor, floor)
    return distance if heading == @dir && (dir == @dir || heading == :idle)
    distance + 2 * TOP_FLOOR
  end

  def next_dir
    return :idle if @stops.empty?
    ahead = @stops.select { |s| @dir == :up ? s > @floor : s < @floor }
    return @dir if @dir != :idle && !ahead.empty?
    target = @stops.min_by { |s| (s - @floor).abs }
    direction_to(@floor, target)
  end

  def step(tick, waiting, done)
    @dir = next_dir
    case @dir
    when :up
      @floor += 1
      @moves += 1
    when :down
      @floor -= 1
      @moves += 1
    end
    return unless @stops.include?(@floor)
    @stops.delete(@floor)
    leaving, @riders = @riders.partition { |r| r.to == @floor }
    leaving.each do |r|
      r.arrived_at = tick
      done << r
      puts "t=#{tick} #{r.name} leaves car #{@id} at #{@floor}"
    end
    boarding = waiting.select { |r| r.from == @floor && r.boarded_at.nil? }
    boarding.each do |r|
      r.boarded_at = tick
      @riders << r
      @stops << r.to
      puts "t=#{tick} #{r.name} boards car #{@id} at #{@floor} -> #{r.to}"
    end
    waiting.reject! { |r| r.boarded_at }
    @dir = next_dir if @stops.empty?
  end
end

def dispatch(cars, rider)
  dir = direction_to(rider.from, rider.to)
  best = cars.min_by { |c| [c.cost(rider.from, dir), c.id] }
  best.stops << rider.from
  best
end

calls = [
  [0, "ann", 0, 7], [0, "ben", 5, 1], [2, "cat", 3, 9], [3, "dan", 8, 0],
  [4, "eve", 1, 4], [6, "fay", 9, 2], [7, "gus", 4, 6], [9, "hal", 0, 3],
  [11, "ivy", 6, 0], [12, "jon", 2, 8], [15, "kim", 7, 5], [16, "lou", 0, 9]
]
riders = calls.map { |t, name, from, to| Rider.new(name, from, to, t) }
cars = [Car.new("A", 0), Car.new("B", 9)]
waiting = []
done = []
pending = riders.dup

tick = 0
while tick < 60
  arriving, pending = pending.partition { |r| r.called_at == tick }
  arriving.each do |r|
    car = dispatch(cars, r)
    waiting << r
    puts "t=#{tick} #{r.name} calls at #{r.from}, assigned #{car.id}"
  end
  cars.each { |c| c.step(tick, waiting, done) }
  break if pending.empty? && waiting.empty? && cars.all? { |c| c.riders.empty? }
  tick += 1
end

puts "--- finished at t=#{tick}"
cars.each { |c| puts c }
total_wait = 0
total_ride = 0
done.sort_by(&:name).each do |r|
  wait = r.boarded_at - r.called_at
  ride = r.arrived_at - r.boarded_at
  total_wait += wait
  total_ride += ride
  puts format("%-4s %d->%d wait %2d ride %2d", r.name, r.from, r.to, wait, ride)
end
n = done.size
puts format("avg wait %.2f, avg ride %.2f, moves %s", total_wait / n.to_f, total_ride / n.to_f,
  cars.map { |c| "#{c.id}=#{c.moves}" }.join(" "))
unserved = riders.select { |r| r.arrived_at.nil? }
puts "unserved: #{unserved.size}"
