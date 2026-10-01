class Room
  attr_reader :name, :capacity, :features

  def initialize(name, capacity, features)
    @name = name
    @capacity = capacity
    @features = features
  end
end

class Booking
  attr_reader :id, :room, :who, :day, :slot, :people

  def initialize(id, room, who, day, slot, people)
    @id = id
    @room = room
    @who = who
    @day = day
    @slot = slot
    @people = people
  end
end

class ConflictError < StandardError
  attr_reader :with_id

  def initialize(message, with_id)
    super(message)
    @with_id = with_id
  end
end

class RequestError < StandardError
end

def parse_time(s)
  m = s.match(/\A(\d{1,2}):(\d\d)\z/)
  raise RequestError, "bad time '#{s}'" unless m
  h = m[1].to_i
  min = m[2].to_i
  raise RequestError, "bad time '#{s}'" if h > 23 || min > 59
  h * 60 + min
end

def show_time(minutes) = format("%02d:%02d", minutes / 60, minutes % 60)

def show_slot(r) = "#{show_time(r.begin)}-#{show_time(r.end)}"

class Schedule
  attr_reader :rooms, :bookings

  def initialize(rooms)
    @rooms = rooms
    @bookings = []
    @last_id = 0
  end

  def conflict(room, day, slot)
    @bookings.find { |b| b.room == room && b.day == day && b.slot.overlap?(slot) }
  end

  def book(room_name, who, day, from, to, people)
    room = @rooms.find { |r| r.name == room_name }
    raise RequestError, "no room #{room_name}" unless room
    slot = parse_time(from)...parse_time(to)
    raise RequestError, "empty slot #{from}-#{to}" if slot.size == 0
    if people > room.capacity
      raise RequestError, "#{room_name} holds #{room.capacity}, not #{people}"
    end
    other = conflict(room_name, day, slot)
    if other
      raise ConflictError.new("#{room_name} is taken by #{other.who} #{show_slot(other.slot)}", other.id)
    end
    @last_id += 1
    b = Booking.new(@last_id, room_name, who, day, slot, people)
    @bookings << b
    b
  end

  def cancel(id)
    b = @bookings.find { |x| x.id == id }
    raise RequestError, "no booking ##{id}" unless b
    @bookings.delete(b)
  end

  # smallest free room that fits and has the needed features
  def suggest(day, from, to, people, needs)
    slot = parse_time(from)...parse_time(to)
    fits = @rooms.select do |r|
      r.capacity >= people && needs.subset?(r.features) && !conflict(r.name, day, slot)    
    end
    fits.min_by(&:capacity)
  end

  def day_plan(day)
    @bookings.select { |b| b.day == day }.sort_by { |b| [b.slot.begin, b.id] }
  end
end

rooms = [
  Room.new("Aspen", 4, Set[:screen]),
  Room.new("Birch", 8, Set[:screen, :whiteboard]),
  Room.new("Cedar", 16, Set[:screen, :whiteboard, :video]),
  Room.new("Dogwood", 2, Set[])
]
sched = Schedule.new(rooms)

requests = [
  ["Birch", "kim", "mon", "09:00", "10:30", 6],
  ["Birch", "lee", "mon", "10:00", "11:00", 5],
  ["Birch", "lee", "mon", "10:30", "11:30", 5],
  ["Aspen", "max", "mon", "09:15", "09:45", 6],
  ["Cedar", "ola", "mon", "13:00", "15:00", 12],
  ["Cedar", "pat", "mon", "14:59", "16:00", 10],
  ["Elm", "pat", "mon", "14:00", "15:00", 3],
  ["Aspen", "quin", "mon", "9:00", "9:60", 2],
  ["Dogwood", "rui", "mon", "12:00", "12:00", 2],
  ["Dogwood", "rui", "mon", "12:00", "12:45", 2],
  ["Cedar", "sam", "tue", "09:00", "17:00", 15],
  ["Aspen", "tia", "tue", "11:00", "12:00", 3]
]

requests.each do |room, who, day, from, to, people|
  begin
    b = sched.book(room, who, day, from, to, people)
    puts "##{b.id} #{who}: #{room} #{day} #{show_slot(b.slot)}"
  rescue ConflictError => e
    puts "conflict for #{who}: #{e.message} (##{e.with_id})"
    alt = sched.suggest(day, from, to, people, Set[])
    puts "  try #{alt ? alt.name : "another time"}"
  rescue RequestError => e
    puts "rejected #{who}: #{e.message}"
  end
end

sched.cancel(1)
puts "cancelled #1"
begin
  sched.cancel(1)
rescue RequestError => e
  puts "rejected: #{e.message}"
end

pick = sched.suggest("mon", "10:00", "11:00", 3, Set[:whiteboard])
puts "whiteboard for 3 on mon 10-11: #{pick ? pick.name : "none"}"
pick = sched.suggest("tue", "10:00", "11:00", 10, Set[:video])
puts "video for 10 on tue 10-11: #{pick ? pick.name : "none"}"

%w[mon tue].each do |day|
  puts
  puts "#{day}:"
  sched.day_plan(day).each do |b|
    puts format("  %s %-8s %-5s %2d people", show_slot(b.slot), b.room, b.who, b.people)
  end
end

puts
open_minutes = 9 * 60
puts "Utilization (9 hours a day, 2 days):"
rooms.each do |r|
  mine = sched.bookings.select { |b| b.room == r.name }
  used = mine.sum { |b| b.slot.size }
  seat_use = mine.sum { |b| b.people * 1.0 / r.capacity }
  puts format("  %-8s %4d min %5.1f%%  seats %.2f", r.name, used, used * 100.0 / (open_minutes * 2), seat_use)
end
