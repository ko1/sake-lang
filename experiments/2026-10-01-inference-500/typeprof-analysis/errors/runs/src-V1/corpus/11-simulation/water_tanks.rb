class Tank
  attr_reader :name, :area, :height, :elevation, :level, :overflowed
  attr_accessor :drawn

  def initialize(name, area, height, elevation, level)
    @name = name
    @area = area
    @height = height
    @elevation = elevation
    @level = level
    @overflowed = 0.0
    @drawn = 0.0
  end

  def volume = @area * @level
  def head = @elevation + @level

  def add(v)
    @level += v / @area
    if @level > @height
      spill = (@level - @height) * @area
      @level = @height
      @overflowed += spill
    end
    @level = 0.0 if @level < 0.0
  end

  def take(v)
    got = [v, volume].min
    @level -= got / @area
    @level = 0.0 if @level < 0.0
    got
  end
end

class Pipe
  attr_reader :from, :to, :conductance
  attr_accessor :open

  def initialize(from, to, conductance, open)
    @from = from
    @to = to
    @conductance = conductance
    @open = open
  end
end

class Pump
  attr_reader :from, :to, :rate, :on_below, :off_above
  attr_accessor :running

  def initialize(from, to, rate, on_below, off_above)
    @from = from
    @to = to
    @rate = rate
    @on_below = on_below
    @off_above = off_above
    @running = false
  end
end

STORMS = [{ from: 2, to: 5, mm: 12.0 }, { from: 9, to: 10, mm: 30.0 }, { from: 16, to: 19, mm: 6.0 }].freeze

def rain(hour)
  s = STORMS.find { |st| hour >= st[:from] && hour < st[:to] }
  s ? s[:mm] : 0.0
end

def demand(hour) = (hour >= 6 && hour < 9) || (hour >= 18 && hour < 22) ? 1.2 : 0.3

def step(tanks, pipes, pumps, hour, dt)
  tanks["roof"].add(rain(hour) * 0.04 * dt)
  pipes.each do |p|
    next unless p.open
    a = tanks[p.from]
    b = tanks[p.to]
    head = a.head - b.head
    next if head <= 0.0
    flow = p.conductance * Math.sqrt(head) * dt
    b.add(a.take(flow))
  end
  pumps.each do |pm|
    src = tanks[pm.from]
    dst = tanks[pm.to]
    if pm.running && dst.level >= pm.off_above
      pm.running = false
    elsif !pm.running && dst.level <= pm.on_below
      pm.running = true
    end
    dst.add(src.take(pm.rate * dt)) if pm.running
  end
  house = tanks["header"]
  got = house.take(demand(hour) * dt)
  house.drawn += got
  demand(hour) * dt - got
end

tanks = {}
[["roof", 4.0, 0.5, 3.0, 0.1], ["cistern", 6.0, 2.0, 0.0, 0.8], ["well", 3.0, 3.0, -0.5, 2.5], ["header", 1.5, 1.2, 4.0, 0.6]].each do |name, area, h, elev, level|
  tanks[name] = Tank.new(name, area, h, elev, level)
end
pipes = [Pipe.new("roof", "cistern", 1.2, true), Pipe.new("well", "cistern", 0.3, false)]
pumps = [Pump.new("cistern", "header", 1.5, 0.4, 1.1)]
events = { 8 => ["open", 1], 14 => ["close", 1], 20 => ["open", 1] }

shortfall = 0.0
short_hours = []
dt = 0.25
24.times do |hour|
  if (ev = events[hour])
    action, idx = ev
    pipes.fetch(idx).open = action == "open"
    puts "#{hour.to_s.rjust(2, "0")}:00 #{action} pipe well->cistern"
  end
  missing = 0.0
  4.times { missing += step(tanks, pipes, pumps, hour, dt) }
  shortfall += missing
  short_hours << hour if missing > 0.001
  levels = tanks.values.map { |t| format("%s %.2f", t.name, t.level) }
  pump = pumps.fetch(0).running ? "P" : "-"
  puts format("%02d:59 %s %s rain %4.1f", hour, pump, levels.join(" | "), rain(hour))
end

puts "--- totals"
tanks.each_value do |t|
  puts format("%-8s final %5.2f m (%.2f m3), overflow %.2f m3", t.name, t.level, t.volume, t.overflowed)
end
puts format("delivered %.2f m3, shortfall %.2f m3", tanks["header"].drawn, shortfall)
puts(short_hours.empty? ? "no shortages" : "short in hours #{short_hours.join(",")}")
