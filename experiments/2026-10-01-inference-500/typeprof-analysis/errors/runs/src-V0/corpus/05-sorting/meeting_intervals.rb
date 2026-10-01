# Calendar analysis: sort meetings by start, merge overlapping busy blocks,
# list free slots, and count rooms needed with a sorted sweep.

def clock(t) = format("%02d:%02d", t / 60, t % 60)

class Meeting
  attr_reader :title, :start, :finish, :room

  def initialize(title, start, finish, room)
    @title = title
    @start = start
    @finish = finish
    @room = room
  end

  def minutes = finish - start
  def to_s = "#{title} #{clock(start)}-#{clock(finish)}"
end

class InvalidMeeting < StandardError
  attr_reader :title

  def initialize(message, title)
    super(message)
    @title = title
  end
end

def parse_clock(s)
  h, m = s.split(":").map(&:to_i)
  h * 60 + m
end

def make(title, from, to, room)
  start = parse_clock(from)
  finish = parse_clock(to)
  raise InvalidMeeting.new("ends before it starts", title) if finish <= start
  Meeting.new(title, start, finish, room)
end

def merge_busy(meetings)
  blocks = []
  meetings.sort_by(&:start).each do |m|
    last = blocks.last
    if last && m.start <= last[1]
      last[1] = m.finish if m.finish > last[1]
    else
      blocks << [m.start, m.finish]
    end
  end
  blocks
end

def free_slots(blocks, day_start, day_end, min_len)
  slots = []
  cursor = day_start
  blocks.each do |s, f|
    slots << [cursor, s] if s - cursor >= min_len
    cursor = f if f > cursor
  end
  slots << [cursor, day_end] if day_end - cursor >= min_len
  slots
end

def rooms_needed(meetings)
  starts = meetings.map(&:start).sort
  ends = meetings.map(&:finish).sort
  i = 0
  j = 0
  current = 0
  peak = 0
  peak_at = nil
  while i < starts.size
    if starts[i] < ends[j]
      current += 1
      if current > peak
        peak = current
        peak_at = starts[i]
      end
      i += 1
    else
      current -= 1
      j += 1
    end
  end
  [peak, peak_at]
end

input = [
  ["standup", "09:00", "09:15", "A"], ["design review", "10:00", "11:30", "B"],
  ["1:1 kana", "10:30", "11:00", "A"], ["lunch talk", "12:00", "13:00", "C"],
  ["hiring sync", "11:15", "12:15", "A"], ["retro", "15:00", "16:00", "B"],
  ["broken", "14:00", "13:30", "C"], ["vendor call", "15:30", "16:15", "B"],
  ["planning", "16:15", "17:00", "B"]
]

meetings = []
input.each do |title, from, to, room|
  meetings << make(title, from, to, room)
rescue InvalidMeeting => e
  puts "skipped #{e.title}: #{e.message}"
end

puts "agenda:"
meetings.sort_by(&:start).each { |m| puts "  #{m} [#{m.room}]" }

blocks = merge_busy(meetings)
puts "busy: " + blocks.map { |s, f| "#{clock(s)}-#{clock(f)}" }.join(", ")
busy_total = blocks.sum { |s, f| f - s }
puts "busy minutes: #{busy_total}, booked minutes: #{meetings.sum(&:minutes)}"
free = free_slots(blocks, parse_clock("09:00"), parse_clock("17:30"), 30)
puts "free (>= 30 min): " + free.map { |s, f| "#{clock(s)}-#{clock(f)}" }.join(", ")

peak, at = rooms_needed(meetings)
puts "rooms needed: #{peak} (first reached at #{clock(at)})"

by_room = meetings.group_by(&:room)
by_room.keys.sort.each do |room|
  ms = by_room[room].sort_by(&:start)
  clashes = ms.each_cons(2).select { |a, b| b.start < a.finish }.map { |a, b| "#{a.title}/#{b.title}" }
  status = clashes.empty? ? "ok" : "double-booked: #{clashes.join(", ")}"
  puts "room #{room}: #{ms.size} meetings, #{status}"
end
longest = meetings.max_by(&:minutes)
puts "longest: #{longest}"
