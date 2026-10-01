class Booking
  attr_reader :start, :finish, :who

  def initialize(start, finish, who)
    @start = start
    @finish = finish
    @who = who
  end

  def overlaps?(s, f) = start < f && s < finish
  def to_s = "#{clock(start)}-#{clock(finish)} #{who}"
end

class INode
  attr_accessor :booking, :max_end, :left, :right

  def initialize(booking, max_end, left, right)
    @booking = booking
    @max_end = max_end
    @left = left
    @right = right
  end
end

class Conflict < StandardError
  attr_reader :existing

  def initialize(message, existing)
    super(message)
    @existing = existing
  end
end

def minutes(hhmm)
  h, m = hhmm.split(":")
  h.to_i * 60 + m.to_i
end

def clock(min) = format("%02d:%02d", min / 60, min % 60)

def insert(node, b)
  return INode.new(b, b.finish, nil, nil) if node.nil?
  if b.start < node.booking.start
    node.left = insert(node.left, b)
  else
    node.right = insert(node.right, b)
  end
  node.max_end = b.finish if b.finish > node.max_end
  node
end

def any_overlap(node, s, f)
  while node
    return node.booking if node.booking.overlaps?(s, f)
    node = node.left && node.left.max_end > s ? node.left : node.right
  end
  nil
end

def all_overlaps(node, s, f, out)
  return out if node.nil? || node.max_end <= s
  all_overlaps(node.left, s, f, out)
  out << node.booking if node.booking.overlaps?(s, f)
  all_overlaps(node.right, s, f, out) if node.booking.start < f
  out
end

def in_order(node, out)
  return out if node.nil?
  in_order(node.left, out)
  out << node.booking
  in_order(node.right, out)
end

class Room
  attr_reader :name
  attr_accessor :root, :count

  def initialize(name)
    @name = name
    @root = nil
    @count = 0
  end

  def book(who, from, to)
    s = minutes(from)
    f = minutes(to)
    raise ArgumentError, "#{who}: end before start" if f <= s
    clash = any_overlap(root, s, f)
    raise Conflict.new("#{who} #{from}-#{to} clashes with #{clash}", clash) if clash
    b = Booking.new(s, f, who)
    self.root = insert(root, b)
    self.count += 1
    b
  end

  def free_slots(day_start, day_end, min_len)
    slots = []
    cursor = minutes(day_start)
    stop = minutes(day_end)
    in_order(root, []).each do |b|
      slots << [cursor, b.start] if b.start - cursor >= min_len
      cursor = [cursor, b.finish].max
    end
    slots << [cursor, stop] if stop - cursor >= min_len
    slots
  end
end

room = Room.new("Orion")
requests = [
  ["standup", "09:00", "09:15"], ["design review", "10:00", "11:30"], ["1:1 ann", "11:30", "12:00"],
  ["lunch talk", "12:30", "13:30"], ["hiring sync", "11:00", "11:45"], ["retro", "15:00", "16:00"],
  ["planning", "14:00", "15:00"], ["oops", "16:30", "16:00"], ["late call", "17:30", "18:30"],
  ["coffee", "09:10", "09:20"], ["deep work", "13:30", "14:00"]
]
requests.each do |who, from, to|
  b = room.book(who, from, to)
  puts "booked   #{b}"
rescue Conflict => e
  puts "rejected #{e.message}"
rescue ArgumentError => e
  puts "invalid  #{e.message}"
end

puts "#{room.name}: #{room.count} bookings"
in_order(room.root, []).each { |b| puts "  #{b}" }

puts "-- who is in the room? --"
%w[09:05 11:30 12:15 14:59 17:45].each do |t|
  m = minutes(t)
  hits = all_overlaps(room.root, m, m + 1, [])
  puts "  #{t}: #{hits.empty? ? "free" : hits.map(&:who).join(", ")}"
end

puts "-- overlapping 11:00-14:10 --"
all_overlaps(room.root, minutes("11:00"), minutes("14:10"), []).each { |b| puts "  #{b}" }

puts "-- free slots of 30+ minutes, 08:00-19:00 --"
room.free_slots("08:00", "19:00", 30).each do |s, f|
  puts "  #{clock(s)}-#{clock(f)} (#{f - s} min)"
end
