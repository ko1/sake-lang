class Vehicle
  attr_reader :id, :max_speed
  attr_accessor :pos, :speed, :laps, :stops

  def initialize(id, pos, max_speed)
    @id = id
    @pos = pos
    @speed = 0
    @max_speed = max_speed
    @laps = 0
    @stops = 0
  end
end

class Road
  attr_reader :length, :cars

  def initialize(length, n, seed, p_slow)
    @length = length
    @rng = seed
    @p_slow = p_slow
    spacing = length / n
    @cars = Array.new(n) { |i| Vehicle.new(i, i * spacing, i % 4 == 3 ? 3 : 5) }
  end

  def chance
    @rng = (@rng * 69069 + 1) % 4294967296
    @rng / 4294967296.0
  end

  def step
    sorted = @cars.sort_by(&:pos)
    n = sorted.size
    gaps = (0...n).map do |i|
      (sorted[(i + 1) % n].pos - sorted[i].pos - 1 + @length) % @length
    end
    sorted.each_with_index do |car, i|
      v = car.speed
      v += 1 if v < car.max_speed
      v = gaps[i] if v > gaps[i]
      v -= 1 if v > 0 && chance < @p_slow
      car.stops += 1 if v == 0 && car.speed > 0
      car.speed = v
    end
    flow = 0
    sorted.each do |car|
      np = car.pos + car.speed
      if np >= @length
        car.laps += 1
        flow += 1
        np -= @length
      end
      car.pos = np
    end
    flow
  end

  def picture
    cells = Array.new(@length, ".")
    @cars.each { |c| cells[c.pos] = c.speed.to_s }
    cells.join
  end

  def mean_speed = @cars.sum(&:speed) / @cars.size.to_f
end

def run(n, p_slow, steps, show)
  road = Road.new(60, n, 12345, p_slow)
  passed = 0
  speeds = []
  steps.times do |t|
    passed += road.step
    speeds << road.mean_speed
    puts format("%3d %s", t, road.picture) if show && t >= steps - 12
  end
  jams = road.cars.sum(&:stops)
  tail = speeds.drop(steps / 2)
  { passed: passed, avg_speed: tail.sum / tail.size, jams: jams, cars: road.cars }
end

puts "space-time diagram, 15 cars, p=0.25 (last 12 steps)"
detail = run(15, 0.25, 60, true)
cars = detail[:cars]
slowest = cars.min_by { |c| [c.laps, c.pos] }
fastest = cars.max_by { |c| [c.laps, c.pos] }
puts "leader: car #{fastest.id} (#{fastest.laps} laps), last: car #{slowest.id} (#{slowest.laps} laps)"

puts "--- fundamental diagram"
puts "cars density  p=0.00              p=0.25              p=0.50"
[5, 15, 25, 40].each do |n|
  cols = [0.0, 0.25, 0.5].map do |p|
    r = run(n, p, 40, false)
    format("flow %3d v %4.2f j%3d", r[:passed], r[:avg_speed], r[:jams])
  end
  puts format("%4d %6.2f  %s", n, n / 60.0, cols.join(" | "))
end
