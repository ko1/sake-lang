TOP_FLOOR = 9

class Elevator
  attr_reader :floor, :direction, :door, :dwell, :stops, :moved, :served

  def initialize
    @floor = 0
    @direction = :idle
    @door = :closed
    @dwell = 0
    @stops = Set[]
    @moved = 0
    @served = []
  end

  def request(floor)
    raise ArgumentError, "no floor #{floor}" unless floor.between?(0, TOP_FLOOR)
    @stops << floor
  end

  def above? = @stops.any? { it > @floor }
  def below? = @stops.any? { it < @floor }

  def choose_direction
    case @direction
    in :up then above? ? :up : (below? ? :down : :idle)
    in :down then below? ? :down : (above? ? :up : :idle)
    in :idle
      if @stops.empty?
        :idle
      else
        nearest = @stops.min_by { |f| [(f - @floor).abs, f] }
        nearest > @floor ? :up : :down
      end
    end
  end

  def tick(t)
    if @door == :open
      @dwell -= 1
      if @dwell == 0
        @door = :closed
        return "doors close at #{@floor}"
      end
      return "doors open at #{@floor}"
    end
    if @stops.include?(@floor)
      @stops.delete(@floor)
      @served << [t, @floor]
      @door = :open
      @dwell = 2
      return "arrive #{@floor}, doors open"
    end
    @direction = choose_direction
    case @direction
    in :idle then "idle at #{@floor}"
    in :up
      @floor += 1
      @moved += 1
      "up to #{@floor}"
    in :down
      @floor -= 1
      @moved += 1
      "down to #{@floor}"
    end
  end
end

class Call
  attr_reader :tick, :floor, :passenger

  def initialize(tick, floor, passenger)
    @tick = tick
    @floor = floor
    @passenger = passenger
  end
end

calls = [
  Call.new(0, 5, "ann"), Call.new(1, 2, "bob"), Call.new(3, 8, "cy"),
  Call.new(6, 1, "dee"), Call.new(9, 12, "eve"), Call.new(10, 7, "fay"),
  Call.new(14, 0, "gus"), Call.new(22, 3, "hal")
]
e = Elevator.new
pending = calls.dup
waits = {}
t = 0
while t < 40
  while !pending.empty? && pending.first.tick == t
    c = pending.shift
    begin
      e.request(c.floor)
      waits[c.passenger] = [t, c.floor]
    rescue ArgumentError => err
      puts format("t=%02d  rejected %s: %s", t, c.passenger, err.message)
    end
  end
  msg = e.tick(t)
  stops = e.stops.to_a.sort
  puts format("t=%02d  %-22s dir=%-5s stops=%s", t, msg, e.direction, stops)
  break if pending.empty? && e.stops.empty? && e.door == :closed
  t += 1
end

puts "moved #{e.moved} floors, finished at t=#{t}"
waits.each do |who, (at, floor)|
  served = e.served.find { |st, f| f == floor && st >= at }
  if served
    puts format("  %-4s floor %d waited %d", who, floor, served[0] - at)
  else
    puts format("  %-4s floor %d never served", who, floor)
  end
end
