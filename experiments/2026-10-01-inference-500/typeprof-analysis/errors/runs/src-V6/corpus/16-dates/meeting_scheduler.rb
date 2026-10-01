# Finds common free time for a group of people from their busy intervals,
# then books a list of meeting requests greedily.

class Slot
  attr_accessor :start, :finish

  def initialize(start, finish)
    @start = start
    @finish = finish
  end

  def self.parse(text)
    a, b = text.split("-")
    new(minutes(a), minutes(b))
  end

  def self.minutes(hhmm)
    h, m = hhmm.split(":")
    h.to_i * 60 + m.to_i
  end

  def self.clock(t) = format("%02d:%02d", t / 60, t % 60)

  def length = @finish - @start

  def overlaps?(other) = @start < other.finish && other.start < @finish

  def to_s = "#{Slot.clock(@start)}-#{Slot.clock(@finish)}"
end

def merge_busy(slots)
  merged = []
  slots.sort_by(&:start).each do |s|
    last = merged.last
    if last && s.start <= last.finish
      last.finish = s.finish if s.finish > last.finish
    else
      merged << Slot.new(s.start, s.finish)
    end
  end
  merged
end

def free_slots(busy, day)
  free = []
  cursor = day.start
  merge_busy(busy).each do |b|
    if b.start > cursor
      free << Slot.new(cursor, b.start.clamp(cursor, day.finish))
    end
    cursor = b.finish if b.finish > cursor
  end
  free << Slot.new(cursor, day.finish) if cursor < day.finish
  free.select { |s| s.length > 0 }
end

def first_fit(free, duration)
  found = free.find { |s| s.length >= duration }
  return nil if !found    
  Slot.new(found.start, found.start + duration)
end

calendars = {
  "ana" => ["09:00-10:30", "12:00-13:00", "15:00-16:00"],
  "ben" => ["09:30-11:00", "13:30-14:00", "16:30-17:30"],
  "cho" => ["08:00-09:15", "11:00-11:30", "12:30-13:15", "14:45-15:15"],
  "dev" => ["10:00-10:45", "16:00-18:00"]
}
day = Slot.parse("09:00-17:30")

busy = calendars.transform_values { |list| list.map { |t| Slot.parse(t) } }

busy.each do |name, slots|
  free = free_slots(slots, day)
  minutes = free.sum(&:length)
  puts format("%-4s free %3d min: %s", name, minutes, free.map(&:to_s).join(" "))
end

requests = [
  [["ana", "ben"], 30, "design review"],
  [["ana", "ben", "cho", "dev"], 45, "all hands"],
  [["cho", "dev"], 60, "pairing"],
  [["ana", "dev"], 90, "planning"],
  [["ben", "cho"], 120, "workshop"],
  [["ana", "cho"], 15, "check-in"]
]

puts
puts "Bookings:"
booked = 0
requests.each do |people, duration, title|
  all_busy = people.flat_map { |n| busy.fetch(n) }
  slot = first_fit(free_slots(all_busy, day), duration)
  if !slot    
    puts format("  %-14s %3d min  no common slot for %s", title, duration, people.join(", "))
  else
    puts format("  %-14s %3d min  %s  %s", title, duration, slot.to_s, people.join(", "))
    people.each { |n| busy.fetch(n) << slot }
    booked += 1
  end
end
puts "Booked #{booked} of #{requests.size}"

load = busy.map do |name, slots|
  inside = merge_busy(slots).map do |s|
    Slot.new([s.start, day.start].max, [s.finish, day.finish].min)
  end
  [name, inside.sum(&:length)]
end
load.sort_by { |_name, mins| -mins }.each do |name, mins|
  puts format("  %-4s busy %3d min (%d%%)", name, mins, mins * 100 / day.length)
end

conflicts = []
busy.keys.combination(2).each do |a, b|
  n = busy.fetch(a).count { |s| busy.fetch(b).any? { |t| s.overlaps?(t) } }
  conflicts << "#{a}/#{b}:#{n}" if n > 0
end
puts "Overlapping busy blocks: #{conflicts.join(" ")}"
