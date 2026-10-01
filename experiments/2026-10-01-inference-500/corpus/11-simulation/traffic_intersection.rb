class Vehicle
  attr_reader :id, :approach, :arrived, :turn

  def initialize(id, approach, arrived, turn)
    @id = id
    @approach = approach
    @arrived = arrived
    @turn = turn
  end
end

class Phase
  attr_reader :name, :green, :min_time, :max_time, :yellow

  def initialize(name, green, min_time, max_time, yellow)
    @name = name
    @green = green
    @min_time = min_time
    @max_time = max_time
    @yellow = yellow
  end
end

class Controller
  attr_reader :phases, :switches

  def initialize(phases)
    @phases = phases
    @index = 0
    @elapsed = 0
    @in_yellow = false
    @switches = 0
  end

  def current = @phases.fetch(@index)

  def green_for?(approach)
    !@in_yellow && current.green.include?(approach)
  end

  def tick(queues)
    @elapsed += 1
    ph = current
    if @in_yellow
      if @elapsed >= ph.yellow
        @in_yellow = false
        @index = (@index + 1) % @phases.size
        @elapsed = 0
        @switches += 1
      end
      return
    end
    served = ph.green.sum { |a| queues[a].size }
    waiting = queues.sum { |a, q| ph.green.include?(a) ? 0 : q.size }
    gap_out = served == 0 && waiting > 0
    if @elapsed >= ph.max_time || (@elapsed >= ph.min_time && gap_out)
      @in_yellow = true
      @elapsed = 0
    end
  end
end

OPPOSITE = { north: :south, south: :north, east: :west, west: :east }

def arrivals(t)
  pattern = [
    [:north, 3, 0, :straight], [:south, 4, 1, :left], [:east, 2, 0, :straight],
    [:west, 5, 2, :right], [:north, 7, 3, :left], [:east, 9, 4, :right]
  ]
  pattern.filter_map { |approach, every, offset, turn| [approach, turn] if t % every == offset }
end

def run(min_g, max_g, duration)
  phases = [
    Phase.new("NS", [:north, :south], min_g, max_g, 2),
    Phase.new("EW", [:east, :west], min_g, max_g, 2)
  ]
  ctl = Controller.new(phases)
  queues = { north: [], south: [], east: [], west: [] }
  waits = Hash.new(0)
  passed = Hash.new(0)
  max_queue = Hash.new(0)
  next_id = 1
  duration.times do |t|
    arrivals(t).each do |approach, turn|
      queues[approach] << Vehicle.new(next_id, approach, t, turn)
      next_id += 1
    end
    queues.each do |approach, q|
      next unless ctl.green_for?(approach)
      head = q.first
      next if head.nil?
      if head.turn == :left
        oncoming = queues[OPPOSITE[approach]].first
        next if oncoming && oncoming.turn != :left && oncoming.arrived < head.arrived
      end
      q.shift
      waits[approach] += t - head.arrived
      passed[approach] += 1
    end
    queues.each { |a, q| max_queue[a] = q.size if q.size > max_queue[a] }
    ctl.tick(queues)
  end
  left = queues.sum { |_a, q| q.size }
  { waits: waits, passed: passed, max_queue: max_queue, left: left, switches: ctl.switches }
end

def show(label, r)
  r => { waits:, passed:, max_queue:, left:, switches: }
  total_passed = passed.values.sum
  total_wait = waits.values.sum
  puts "#{label}: passed #{total_passed}, still queued #{left}, phase changes #{switches}"
  [:north, :south, :east, :west].each do |a|
    n = passed[a]
    avg = n == 0 ? 0.0 : waits[a] / n.to_f
    puts format("  %-6s passed %3d  avg wait %5.2f  max queue %2d", a, n, avg, max_queue[a])
  end
  total_wait / total_passed.to_f
end

results = [[3, 8], [5, 15], [8, 30]].map do |min_g, max_g|
  avg = show("min #{min_g} max #{max_g}", run(min_g, max_g, 120))
  [min_g, max_g, avg]
end
mn, mx, avg = results.min_by { |_mn, _mx, a| a }
puts format("best timing: min %d max %d (avg wait %.3f)", mn, mx, avg)
