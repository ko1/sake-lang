# A meeting-room booking system for one week: requests are checked for
# conflicts and opening hours, rejected requests raise typed errors, and the
# week is summarised per room.

class Conflict < StandardError
  attr_reader :existing

  def initialize(message, existing)
    super(message)
    @existing = existing
  end
end

class OutsideHours < StandardError
  attr_reader :day

  def initialize(message, day)
    super(message)
    @day = day
  end
end

class UnknownRoom < StandardError
  attr_reader :room

  def initialize(message, room)
    super(message)
    @room = room
  end
end

DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri"]
ROOMS = { "Atlas" => 12, "Boreal" => 6, "Cedar" => 4 }

def to_min(hhmm)
  h, m = hhmm.split(":")
  h.to_i * 60 + m.to_i
end

def hhmm(t) = format("%02d:%02d", t / 60, t % 60)

class Booking
  attr_reader :id, :room, :day, :start, :finish, :owner

  def initialize(id, room, day, start, finish, owner)
    @id = id
    @room = room
    @day = day
    @start = start
    @finish = finish
    @owner = owner
  end

  def overlaps?(other)
    @room == other.room && @day == other.day && @start < other.finish && other.start < @finish
  end

  def minutes = @finish - @start

  def to_s = "##{@id} #{@room} #{DAYS[@day]} #{hhmm(@start)}-#{hhmm(@finish)} #{@owner}"
end

class Calendar
  attr_reader :bookings

  def initialize
    @bookings = []
    @next_id = 1
  end

  def book(room, day_name, from, to, owner)
    raise UnknownRoom.new("no such room", room) unless ROOMS.key?(room)
    day = DAYS.index(day_name)
    raise OutsideHours.new("not a working day", day_name) if !day    
    start = to_min(from)
    finish = to_min(to)
    if start < 8 * 60 || finish > 19 * 60 || finish <= start
      raise OutsideHours.new("outside 08:00-19:00: #{from}-#{to}", day_name)
    end
    b = Booking.new(@next_id, room, day, start, finish, owner)
    clash = @bookings.find { |other| b.overlaps?(other) }
    raise Conflict.new("overlaps", clash) if clash
    @bookings << b
    @next_id += 1
    b
  end

  def cancel(id)
    victim = @bookings.find { |b| b.id == id }
    return false if !victim    
    @bookings.delete(victim)
    true
  end
end

requests = [
  ["Atlas", "Mon", "09:00", "10:00", "kim"],
  ["Atlas", "Mon", "09:30", "10:30", "lee"],
  ["Boreal", "Mon", "09:30", "10:30", "lee"],
  ["Cedar", "Tue", "07:30", "08:30", "max"],
  ["Cedar", "Tue", "08:00", "09:00", "max"],
  ["Dome", "Wed", "10:00", "11:00", "nia"],
  ["Atlas", "Sat", "10:00", "11:00", "nia"],
  ["Atlas", "Wed", "13:00", "16:00", "ola"],
  ["Atlas", "Wed", "15:59", "17:00", "kim"],
  ["Atlas", "Wed", "16:00", "17:00", "kim"],
  ["Boreal", "Thu", "11:00", "10:00", "lee"],
  ["Boreal", "Thu", "11:00", "12:30", "lee"],
  ["Cedar", "Fri", "14:00", "18:30", "max"],
  ["Boreal", "Fri", "09:00", "12:00", "ola"]
]

cal = Calendar.new
rejected = Hash.new(0)
requests.each do |room, day, from, to, owner|
  b = cal.book(room, day, from, to, owner)
  puts "ok       #{b}"
rescue Conflict => e
  rejected["conflict"] += 1
  puts "conflict #{room} #{day} #{from}-#{to} #{owner}: #{e.message} #{e.existing}"
rescue OutsideHours => e
  rejected["hours"] += 1
  puts "hours    #{room} #{e.day} #{owner}: #{e.message}"
rescue UnknownRoom => e
  rejected["room"] += 1
  puts "room     #{e.room}: #{e.message}"
end
puts "Rejected: #{rejected.map { |k, n| "#{k}=#{n}" }.join(", ")}"

puts "Cancel #2: #{cal.cancel(2)}, cancel #99: #{cal.cancel(99)}"
retry_b = cal.book("Boreal", "Mon", "10:00", "11:00", "kim")
puts "rebooked #{retry_b}"

puts
puts "Utilisation (11 h days):"
ROOMS.each do |room, seats|
  mine = cal.bookings.select { |b| b.room == room }
  used = mine.sum(&:minutes)
  pct = used * 100 / (5 * 11 * 60)
  busiest = mine.max_by(&:minutes)
  top = busiest ? busiest.to_s : "-"
  puts format("  %-7s %2d seats %4d min %3d%%  longest: %s", room, seats, used, pct, top)
end

per_day = cal.bookings.group_by(&:day)
puts "Bookings per day: " + (0..4).map { |d| "#{DAYS[d]}=#{per_day.fetch(d, []).size}" }.join(" ")
owners = cal.bookings.map(&:owner).tally
puts "By owner: #{owners.keys.sort.map { |o| "#{o}:#{owners[o]}" }.join(" ")}"
