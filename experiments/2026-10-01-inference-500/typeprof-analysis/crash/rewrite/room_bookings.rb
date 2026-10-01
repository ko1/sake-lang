# Meeting-room bookings as Ranges of minutes: merge overlaps, find gaps, and answer queries.

class Booking
  attr_reader :room, :who, :span

  def initialize(room, who, span)
    @room = room
    @who = who
    @span = span
  end
end

def hhmm(m) = format("%02d:%02d", m / 60, m % 60)

def parse_time(s)
  h, m = s.split(":")
  h.to_i * 60 + m.to_i
end

def span_to_s(r) = "#{hhmm(r.begin)}-#{hhmm(r.end)}"

def parse_booking(line)
  room, who, from, to = line.split(" ")
  Booking.new(room, who, parse_time(from)...parse_time(to))
end

def merge_spans(spans)
  merged = []
  spans.sort_by(&:begin).each do |r|
    last = merged.last
    if last && r.begin <= last.end
      merged[-1] = last.begin...[r.end, last.end].max
    else
      merged << r
    end
  end
  merged
end

def gaps(merged, day)
  out = []
  cursor = day.begin
  merged.each do |r|
    out << (cursor...r.begin) if r.begin > cursor
    cursor = r.end if r.end > cursor
  end
  out << (cursor...day.end) if cursor < day.end
  out
end

def overlap?(a, b) = a.begin < b.end && b.begin < a.end

lines = [
  "A ann 09:00 10:00", "A bob 09:30 11:00", "A cho 13:00 14:00",
  "B dev 08:30 09:15", "B eve 10:00 12:30", "B fay 12:00 12:45",
  "A gus 10:45 11:30", "C hal 09:00 17:00", "B ivy 15:00 16:00"
]
bookings = lines.map { |l| parse_booking(l) }
day = parse_time("08:00")...parse_time("18:00")

by_room = bookings.group_by(&:room)
by_room.keys.sort.each do |room|
  list = by_room[room]
  merged = merge_spans(list.map(&:span))
  busy = merged.sum(&:size)
  puts "Room #{room}: #{list.size} bookings, busy #{busy} min"
  puts "  busy: #{merged.map { |r| span_to_s(r) }.join(", ")}"
  free = gaps(merged, day)
  puts "  free: #{free.map { |r| span_to_s(r) }.join(", ")}"
  longest = free.max_by(&:size)
  puts "  longest free: #{longest ? span_to_s(longest) : "none"}"
  list.combination(2).each do |a, b|
    puts "  clash: #{a.who} and #{b.who}" if overlap?(a.span, b.span)
  end
end

puts "== Who is in at... =="
["09:10", "12:15", "17:30"].each do |t|
  m = parse_time(t)
  names = bookings.select { |b| b.span.cover?(m) }.map { |b| "#{b.who}@#{b.room}" }
  puts "#{t}: #{names.empty? ? "nobody" : names.join(" ")}"
end

puts "== First room free for 60 min from 10:00 =="
want = 60
from = parse_time("10:00")
found = nil
by_room.keys.sort.each do |room|
  slot = gaps(merge_spans(by_room[room].map(&:span)), day).find do |r|
    r.end - [r.begin, from].max >= want
  end
  if slot
    start = [slot.begin, from].max
    found = [room, start...(start + want)]
    break
  end
end
if found
  room, r = found
  puts "room #{room} at #{span_to_s(r)}"
else
  puts "no room"
end

hours = (8...18).map { |h| [h, bookings.count { |b| overlap?(b.span, (h * 60)...(h * 60 + 60)) }] }
puts "== Load per hour =="
hours.each { |h, n| puts format("%02d %s", h, "#" * n) }
peak = hours.max_by { |e__| h, n = e__; n }
puts "peak hour: #{peak[0]} with #{peak[1]}"
