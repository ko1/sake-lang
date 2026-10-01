class Line
  attr_reader :name, :stops, :loop

  def initialize(name, stops, loop)
    @name = name
    @stops = stops
    @loop = loop
  end
end

def network
  [
    Line.new("Red", "Airport Docks Central Museum Park Zoo".split(" "), false),
    Line.new("Blue", "Harbor Docks Market Central Library".split(" "), false),
    Line.new("Green", "Library Museum Stadium Harbor".split(" "), true),
    Line.new("Gold", "Zoo University Stadium".split(" "), false)
  ]
end

# state = [station, line]; riding to the next stop costs 0 transfers, changing lines costs 1.
def moves(lines, by_station, station, line_name)
  out = []
  line = lines.find { |l| l.name == line_name }
  stops = line.stops
  i = stops.index(station)
  [i - 1, i + 1].each do |j|
    if line.loop
      j %= stops.size
    elsif j < 0 || j >= stops.size
      next
    end
    out << [[stops[j], line_name], 0]
  end
  by_station[station].each do |other|
    out << [[station, other], 1] if other != line_name
  end
  out
end

def route(lines, from, to)
  by_station = Hash.new { |h, k| h[k] = [] }
  lines.each do |l|
    l.stops.each { |s| by_station[s] << l.name }
  end
  return nil unless by_station.key?(from) && by_station.key?(to)
  cost = {}
  prev = {}
  deque = []
  by_station[from].each do |ln|
    cost[[from, ln]] = [0, 0]
    deque << [from, ln]
  end
  until deque.empty?
    state = deque.shift
    station, ln = state
    transfers, rides = cost[state]
    if station == to
      path = [state]
      while (back = prev[path.first])
        path.unshift(back)
      end
      return [transfers, rides, path]
    end
    moves(lines, by_station, station, ln).each do |nxt, w|
      t2 = transfers + w
      r2 = rides + 1 - w
      old = cost[nxt]
      if old
        ot, orr = old
        next if ot < t2 || (ot == t2 && orr <= r2)
      end
      cost[nxt] = [t2, r2]
      prev[nxt] = state
      if w == 0
        deque.unshift(nxt)
      else
        deque << nxt
      end
    end
  end
  nil
end

def describe(path)
  legs = []
  path.each do |station, ln|
    last = legs.last
    if last && last[0] == ln
      last[1] << station
    else
      legs << [ln, [station]]
    end
  end
  legs.reject { |ln, stations| stations.size < 2 }
      .map { |ln, stations| "#{ln}: #{stations.first}->#{stations.last}" }
end

lines = network
[["Airport", "Library"], ["Zoo", "Harbor"], ["Market", "University"],
 ["Park", "Park"], ["Airport", "Moon"]].each do |from, to|
  found = route(lines, from, to)
  if !found    
    puts "#{from} -> #{to}: no route"
    next
  end
  transfers, rides, path = found
  puts "#{from} -> #{to}: #{transfers} transfer(s), #{rides} stop(s)"
  describe(path).each { |leg| puts "    #{leg}" }
end
