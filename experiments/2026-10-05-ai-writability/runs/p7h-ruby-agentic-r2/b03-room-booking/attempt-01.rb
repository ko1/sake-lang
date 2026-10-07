#!/usr/bin/env ruby

def parse_time(time_str)
  return nil unless time_str =~ /^(\d{2}):(\d{2})$/
  hh, mm = $1.to_i, $2.to_i
  return nil if hh < 8 || hh > 20 || mm >= 60 || mm % 15 != 0
  hh * 60 + mm
end

def format_time(minutes)
  hh = minutes / 60
  mm = minutes % 60
  format("%02d:%02d", hh, mm)
end

def valid_room?(room)
  room =~ /^[A-Z0-9]{1,8}$/
end

def valid_day?(day)
  %w[Mon Tue Wed Thu Fri Sat Sun].include?(day)
end

def valid_name?(name)
  name =~ /^[a-z]{1,12}$/
end

DAY_ORDER = { "Mon" => 0, "Tue" => 1, "Wed" => 2, "Thu" => 3, "Fri" => 4, "Sat" => 5, "Sun" => 6 }

bookings = {}  # id => {room, day, start, end, who}
next_id = 1
bookings_by_room_day = {}  # [room, day] => [{id, start, end, who}, ...]

ARGF.each_with_index do |line, idx|
  line_no = idx + 1
  line = line.chomp

  next if line.strip.empty?

  fields = line.split(/\s+/)
  command = fields[0]

  unless %w[BOOK CANCEL FREE].include?(command)
    puts "line #{line_no}: error: unknown command"
    next
  end

  if command == "BOOK"
    if fields.length != 6
      puts "line #{line_no}: error: wrong field count"
      next
    end

    room, day, time_str, who = fields[1], fields[2], fields[3], fields[5]

    unless valid_room?(room)
      puts "line #{line_no}: error: bad room"
      next
    end

    unless valid_day?(day)
      puts "line #{line_no}: error: bad day"
      next
    end

    # Parse time
    unless time_str =~ /^(\d{2}:\d{2})-(\d{2}:\d{2})$/
      puts "line #{line_no}: error: bad time"
      next
    end

    start_str, end_str = $1, $2
    start = parse_time(start_str)
    unless start
      puts "line #{line_no}: error: bad time"
      next
    end

    finish = parse_time(end_str)
    unless finish
      puts "line #{line_no}: error: bad time"
      next
    end

    unless start < finish
      puts "line #{line_no}: error: bad time"
      next
    end

    unless valid_name?(who)
      puts "line #{line_no}: error: bad name"
      next
    end

    # Check conflict
    key = [room, day]
    if bookings_by_room_day[key]
      conflict = bookings_by_room_day[key].find { |b| !(finish <= b[:start] || start >= b[:end]) }
      if conflict
        earliest = bookings_by_room_day[key].min_by { |b| b[:start] }
        puts "CONFLICT #{room} #{day} with ##{earliest[:id]} (#{earliest[:who]} #{format_time(earliest[:start])}-#{format_time(earliest[:end])})"
        next
      end
    end

    # Check limit (WHO has 3 bookings on this day)
    count = bookings.select { |id, b| b[:who] == who && b[:day] == day }.length
    if count >= 3
      puts "LIMIT #{who} #{day}"
      next
    end

    # Add booking
    id = next_id
    booking = { room: room, day: day, start: start, end: finish, who: who, id: id }
    bookings[id] = booking
    bookings_by_room_day[key] ||= []
    bookings_by_room_day[key] << { id: id, start: start, end: finish, who: who }

    puts "OK ##{id} #{room} #{day} #{format_time(start)}-#{format_time(finish)} #{who}"
    next_id += 1

  elsif command == "CANCEL"
    if fields.length != 2
      puts "line #{line_no}: error: wrong field count"
      next
    end

    id_str = fields[1]
    unless id_str =~ /^\d+$/
      puts "line #{line_no}: error: bad id"
      next
    end

    id = id_str.to_i
    unless bookings[id]
      puts "NO BOOKING ##{id}"
      next
    end

    b = bookings[id]
    key = [b[:room], b[:day]]
    bookings_by_room_day[key].delete_if { |x| x[:id] == id }
    bookings.delete(id)

    puts "CANCELLED ##{id}"

  elsif command == "FREE"
    if fields.length != 4
      puts "line #{line_no}: error: wrong field count"
      next
    end

    room, day, minutes_str = fields[1], fields[2], fields[3]

    unless valid_room?(room)
      puts "line #{line_no}: error: bad room"
      next
    end

    unless valid_day?(day)
      puts "line #{line_no}: error: bad day"
      next
    end

    unless minutes_str =~ /^\d+$/ && minutes_str.to_i > 0 && minutes_str.to_i % 15 == 0
      puts "line #{line_no}: error: bad duration"
      next
    end

    duration = minutes_str.to_i

    # Find earliest free slot
    key = [room, day]
    occupied = bookings_by_room_day[key] || []
    occupied = occupied.sort_by { |b| b[:start] }

    # Check from 08:00
    current = 8 * 60
    end_time = 20 * 60

    found = false
    occupied.each do |b|
      if current + duration <= b[:start]
        # Found slot before this booking
        if current + duration <= end_time
          puts "FREE #{room} #{day} #{format_time(current)}-#{format_time(current + duration)}"
          found = true
          break
        end
      end
      current = b[:end]
    end

    unless found
      # Check after last booking or if no bookings
      if current + duration <= end_time
        puts "FREE #{room} #{day} #{format_time(current)}-#{format_time(current + duration)}"
      else
        puts "FULL #{room} #{day}"
      end
    end
  end
end

puts "== schedule =="

# Sort bookings by day, room, start time
sorted = bookings.values.sort_by { |b| [DAY_ORDER[b[:day]], b[:room], b[:start]] }

if sorted.empty?
  puts "(none)"
else
  sorted.each do |b|
    puts format("%s %-8s %s-%s #%d %s", b[:day], b[:room],
                format_time(b[:start]), format_time(b[:end]), b[:id], b[:who])
  end
end

puts "== usage =="

# Calculate usage per room
rooms_with_bookings = sorted.map { |b| b[:room] }.uniq.sort
if rooms_with_bookings.empty?
  puts "(none)"
else
  rooms_with_bookings.each do |room|
    total_minutes = sorted.select { |b| b[:room] == room }.sum { |b| b[:end] - b[:start] }
    hours = total_minutes / 60
    minutes = total_minutes % 60
    puts format("%-8s %dh%02dm", room, hours, minutes)
  end
end
