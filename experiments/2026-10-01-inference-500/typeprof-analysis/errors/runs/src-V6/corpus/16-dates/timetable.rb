# A rail timetable: trains with stop times (some stations skipped), journey
# queries "next train from A to B after T", and a per-station departure board.

module Clock
  module_function

  def parse(s)
    return nil if s == "--"
    h, m = s.split(":")
    h.to_i * 60 + m.to_i
  end

  # Times past midnight are stored as 24:xx and shown as 00:xx.
  def show(t) = format("%02d:%02d", (t / 60) % 24, t % 60)

  def span(mins) = mins >= 60 ? "#{mins / 60}h#{format("%02d", mins % 60)}" : "#{mins}m"
end

STATIONS = ["Harbor", "Central", "Museum", "Airport", "Lakeside", "Summit"]

RAW_TABLE = [
  ["101", "local",   "06:10 06:22 06:30 06:45 07:05 07:40"],
  ["201", "express", "06:40 06:50 -- 07:08 -- 07:50"],
  ["103", "local",   "07:15 07:27 07:35 07:50 08:10 08:45"],
  ["203", "express", "08:05 08:15 -- 08:33 -- 09:15"],
  ["105", "local",   "09:30 09:42 09:50 10:05 10:25 --"],
  ["301", "night",   "23:20 23:32 23:40 23:55 24:15 24:50"],
  ["107", "local",   "12:00 12:12 12:20 12:35 12:55 13:30"]
]

class Train
  attr_reader :number, :kind, :stops

  def initialize(number, kind, stops)
    @number = number
    @kind = kind
    @stops = stops
  end

  def stop_at(station) = @stops[STATIONS.index(station)]

  def serves?(from, to)
    dep = stop_at(from)
    arr = stop_at(to)
    !!dep     && !!arr     && dep < arr
  end

  def to_s = "#{@number} (#{@kind})"
end

def load_trains
  RAW_TABLE.map do |number, kind, times|
    Train.new(number, kind, times.split(" ").map { |s| Clock.parse(s) })
  end
end

def next_journey(trains, from, to, after)
  candidates = trains.select { |t| t.serves?(from, to) && t.stop_at(from) >= after }
  candidates.min_by { |t| t.stop_at(to) }
end

trains = load_trains

queries = [
  ["Harbor", "Summit", "06:00"],
  ["Harbor", "Museum", "06:35"],
  ["Central", "Airport", "08:00"],
  ["Museum", "Summit", "09:40"],
  ["Lakeside", "Harbor", "07:00"],
  ["Airport", "Summit", "23:00"],
  ["Harbor", "Summit", "13:00"]
]

puts "Journeys:"
queries.each do |from, to, at|
  after = Clock.parse(at)
  t = after ? next_journey(trains, from, to, after) : nil
  if !t    
    puts format("  %-8s -> %-8s after %s: no train", from, to, at)
  else
    dep = t.stop_at(from)
    arr = t.stop_at(to)
    wait = dep - after
    puts format("  %-8s -> %-8s after %s: %-13s %s-%s  wait %s, ride %s", from, to, at, t.to_s,
                Clock.show(dep), Clock.show(arr), Clock.span(wait), Clock.span(arr - dep))
  end
end

puts
puts "Departures from Central:"
board = trains.filter_map do |t|
  dep = t.stop_at("Central")
  dep ? [dep, t] : nil
end
board.sort_by(&:first).each do |dep, t|
  last = t.stops.map { |s| !!s     }.rindex(true)
  puts format("  %s  %-4s %-8s to %s", Clock.show(dep), t.number, t.kind, STATIONS[last])
end

puts
puts "Average end-to-end time by kind:"
by_kind = trains.select { |t| t.serves?("Harbor", "Summit") }.group_by(&:kind)
by_kind.each do |kind, list|
  total = list.sum { |t| t.stop_at("Summit") - t.stop_at("Harbor") }
  puts format("  %-8s %d trains, %s", kind, list.size, Clock.span(total / list.size))
end

deps = trains.map { |t| t.stop_at("Harbor") }.compact.sort
widest = deps.each_cons(2).map { |a, b| [b - a, a] }.max_by(&:first)
if widest
  gap, from = widest
  puts "Longest gap at Harbor: #{Clock.span(gap)} after #{Clock.show(from)}"
end
