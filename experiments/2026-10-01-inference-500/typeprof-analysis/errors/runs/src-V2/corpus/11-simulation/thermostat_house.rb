class Room
  attr_reader :name, :mass, :loss, :heater_kw
  attr_accessor :temp, :heating, :on_minutes

  def initialize(name, temp, mass, loss, heater_kw)
    @name = name
    @temp = temp
    @mass = mass
    @loss = loss
    @heater_kw = heater_kw
    @heating = false
    @on_minutes = 0
  end

  def to_s = format("%-8s %5.2fC %s", @name, @temp, @heating ? "ON " : "off")
end

OUTDOOR = [-2.0, -2.5, -3.0, -3.5, -3.0, -2.0, 0.0, 2.0, 4.0, 6.0, 7.5, 8.5,
           9.0, 9.0, 8.0, 6.5, 5.0, 3.5, 2.0, 1.0, 0.0, -0.5, -1.0, -1.5].freeze

SCHEDULE = [
  { rooms: ["living", "kitchen"], hours: 7...9, target: 21.0 },
  { rooms: ["living", "kitchen"], hours: 17...23, target: 21.5 },
  { rooms: ["bedroom"], hours: 21...24, target: 19.0 },
  { rooms: ["bedroom"], hours: 0...7, target: 18.0 },
  { rooms: ["office"], hours: 9...17, target: 20.5 }
].freeze

def outdoor(hour) = OUTDOOR.fetch(hour % 24)

def setpoint(room_name, hour)
  hit = SCHEDULE.find { |entry| entry[:rooms].include?(room_name) && entry[:hours].cover?(hour) }
  hit ? hit[:target] : 16.0
end

def step(rooms, walls, hour, minutes)
  out = outdoor(hour)
  flows = Hash.new(0.0)
  walls.each do |a, b, k|
    q = k * (rooms[a].temp - rooms[b].temp)
    flows[a] -= q
    flows[b] += q
  end
  rooms.each do |name, r|
    target = setpoint(name, hour)
    t = r.temp
    if r.heating && t >= target + 0.5
      r.heating = false
    elsif !r.heating && t <= target - 0.5
      r.heating = true
    end
    gain = r.heating ? r.heater_kw : 0.0
    r.on_minutes += minutes if r.heating
    loss = r.loss * (t - out)
    dt = (gain - loss + flows[name]) * minutes / 60.0 / r.mass
    r.temp = t + dt
  end
end

rooms = {}
[
  ["living", 19.0, 1.6, 0.09, 4.0], ["kitchen", 18.5, 1.0, 0.07, 3.0],
  ["bedroom", 17.0, 1.2, 0.06, 2.5], ["office", 16.5, 0.8, 0.08, 2.5]
].each do |name, temp, mass, loss, kw|
  rooms[name] = Room.new(name, temp, mass, loss, kw)
end
walls = [["living", "kitchen", 0.12], ["living", "bedroom", 0.05], ["kitchen", "office", 0.04], ["bedroom", "office", 0.06]]

minutes = 10
comfort_misses = Hash.new(0)
lows = {}
24.times do |hour|
  (60 / minutes).times { step(rooms, walls, hour, minutes) }
  rooms.each do |name, r|
    t = r.temp
    comfort_misses[name] += 1 if t < setpoint(name, hour) - 1.0
    lows[name] = t if lows[name].nil? || t < lows[name]
  end
  if hour % 3 == 2
    puts format("%02d:00 out %5.1fC | %s", hour + 1, outdoor(hour), rooms.values.map(&:to_s).join(" | "))
  end
end

puts "--- daily summary"
total_kwh = 0.0
rooms.each do |name, r|
  kwh = r.heater_kw * r.on_minutes / 60.0
  total_kwh += kwh
  puts format("%-8s heater on %4d min, %5.2f kWh, low %5.2fC, hours below target %d",
    name, r.on_minutes, kwh, lows[name], comfort_misses[name])
end
puts format("total %.2f kWh, cost %.2f", total_kwh, total_kwh * 0.31)
coldest = lows.min_by { |_n, t| t }
if coldest
  n, t = coldest
  puts format("coldest moment: %s at %.2fC", n, t)
end
