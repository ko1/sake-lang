#!/usr/bin/env ruby

DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

def time_to_minutes(time_str)
  hour, minute = time_str.split(":").map(&:to_i)
  hour * 60 + minute
end

def minutes_to_time(minutes)
  hour = minutes / 60
  min = minutes % 60
  format("%02d:%02d", hour, min)
end

def validate_room(room)
  room =~ /^[A-Z0-9]{1,8}$/
end

def validate_day(day)
  DAYS.include?(day)
end

def validate_time(time_str)
  return false unless time_str =~ /^\d{2}:\d{2}$/
  hour, minute = time_str.split(":").map(&:to_i)
  return false if hour > 23 || minute > 59
  return false if minute % 15 != 0
  minutes = hour * 60 + minute
  return false if minutes < 8 * 60 || minutes > 20 * 60
  true
end

def validate_name(name)
  name =~ /^[a-z]{1,12}$/
end

def validate_id(id_str)
  id_str =~ /^\d+$/
end

def validate_duration(duration_str)
  duration_str =~ /^\d+$/ && duration_str.to_i > 0 && duration_str.to_i % 15 == 0
end

bookings = {}
next_id = 1
all_bookings = {}

STDIN.each_with_index do |line, idx|
  line_num = idx + 1
  line = line.strip

  next if line.empty?

  fields = line.split(/\s+/)
  command = fields[0]

  if command == "BOOK"
    if fields.length != 6
      puts "line #{line_num}: error: wrong field count"
      next
    end

    room = fields[1]
    day = fields[2]
    time_range = fields[3]
    who = fields[4]

    unless validate_room(room)
      puts "line #{line_num}: error: bad room"
      next
    end

    unless validate_day(day)
      puts "line #{line_num}: error: bad day"
      next
    end

    start_str, end_str = time_range.split("-")
    unless start_str && end_str && validate_time(start_str)
      puts "line #{line_num}: error: bad time"
      next
    end

    unless validate_time(end_str)
      puts "line #{line_num}: error: bad time"
      next
    end

    start_min = time_to_minutes(start_str)
    end_min = time_to_minutes(end_str)
    unless start_min < end_min
      puts "line #{line_num}: error: bad time"
      next
    end

    unless validate_name(who)
      puts "line #{line_num}: error: bad name"
      next
    end

    key = "#{room}-#{day}"
    bookings[key] ||= []

    conflicting = bookings[key].find do |b|
      !(b[:end] <= start_min || b[:start] >= end_min)
    end

    if conflicting
      puts "CONFLICT #{room} #{day} with ##{conflicting[:id]} (#{conflicting[:who]} #{conflicting[:start_str]}-#{conflicting[:end_str]})"
      next
    end

    day_bookings = all_bookings.select { |_, b| b[:day] == day && b[:who] == who }
    if day_bookings.length >= 3
      puts "LIMIT #{who} #{day}"
      next
    end

    booking = {
      id: next_id,
      room: room,
      day: day,
      start: start_min,
      end: end_min,
      start_str: start_str,
      end_str: end_str,
      who: who
    }

    all_bookings[next_id] = booking
    bookings[key] << booking

    puts "OK ##{next_id} #{room} #{day} #{start_str}-#{end_str} #{who}"
    next_id += 1

  elsif command == "CANCEL"
    if fields.length != 2
      puts "line #{line_num}: error: wrong field count"
      next
    end

    id_str = fields[1]
    unless validate_id(id_str)
      puts "line #{line_num}: error: bad id"
      next
    end

    id = id_str.to_i
    if all_bookings[id]
      booking = all_bookings[id]
      key = "#{booking[:room]}-#{booking[:day]}"
      bookings[key].delete(booking)
      all_bookings.delete(id)
      puts "CANCELLED ##{id}"
    else
      puts "NO BOOKING ##{id}"
    end

  elsif command == "FREE"
    if fields.length != 4
      puts "line #{line_num}: error: wrong field count"
      next
    end

    room = fields[1]
    day = fields[2]
    duration_str = fields[3]

    unless validate_room(room)
      puts "line #{line_num}: error: bad room"
      next
    end

    unless validate_day(day)
      puts "line #{line_num}: error: bad day"
      next
    end

    unless validate_duration(duration_str)
      puts "line #{line_num}: error: bad duration"
      next
    end

    duration = duration_str.to_i
    key = "#{room}-#{day}"
    room_bookings = bookings[key] || []

    found = false
    (8*60..20*60).step(15) do |minute|
      break if found
      slot_start = minute
      slot_end = minute + duration
      break if slot_end > 20 * 60

      conflict = room_bookings.any? do |b|
        !(b[:end] <= slot_start || b[:start] >= slot_end)
      end

      unless conflict
        puts "FREE #{room} #{day} #{minutes_to_time(slot_start)}-#{minutes_to_time(slot_end)}"
        found = true
      end
    end

    unless found
      puts "FULL #{room} #{day}"
    end
  else
    puts "line #{line_num}: error: unknown command"
  end
end

puts "== schedule =="
schedule = all_bookings.values.sort do |a, b|
  day_cmp = DAYS.index(a[:day]) <=> DAYS.index(b[:day])
  if day_cmp.zero?
    room_cmp = a[:room] <=> b[:room]
    if room_cmp.zero?
      a[:start] <=> b[:start]
    else
      room_cmp
    end
  else
    day_cmp
  end
end

if schedule.empty?
  puts "(none)"
else
  schedule.each do |b|
    puts format("%s %-8s %s-%s #%d %s", b[:day], b[:room], b[:start_str], b[:end_str], b[:id], b[:who])
  end
end

puts "== usage =="
rooms = all_bookings.values.map { |b| b[:room] }.uniq.sort
if rooms.empty?
  puts "(none)"
else
  rooms.each do |room|
    total_minutes = all_bookings.values.select { |b| b[:room] == room }.sum { |b| b[:end] - b[:start] }
    hours = total_minutes / 60
    minutes = total_minutes % 60
    puts format("%-8s %dh%02dm", room, hours, minutes)
  end
end
