def parse_time(time_str)
  if time_str.match?(/^(\d{2}):(\d{2})$/)
    hh, mm = time_str.match(/^(\d{2}):(\d{2})$/).captures.map(&:to_i)
    if hh >= 8 && hh <= 20 && mm >= 0 && mm < 60 && mm % 15 == 0 && (hh < 20 || mm == 0)
      (hh - 8) * 60 + mm  # minutes since 08:00
    else
      nil
    end
  else
    nil
  end
end

def minutes_to_time(mins)
  hh = 8 + mins / 60
  mm = mins % 60
  format("%02d:%02d", hh, mm)
end

def validate_room(room)
  room.match?(/^[A-Z0-9]{1,8}$/)
end

def validate_day(day)
  %w[Mon Tue Wed Thu Fri Sat Sun].include?(day)
end

def validate_name(name)
  name.match?(/^[a-z]{1,12}$/)
end

def validate_duration(dur_str)
  if dur_str.match?(/^\d+$/)
    dur = dur_str.to_i
    dur > 0 && dur % 15 == 0 ? dur : nil
  else
    nil
  end
end

def times_overlap(s1, e1, s2, e2)
  # [s1, e1) and [s2, e2) overlap if s1 < e2 && s2 < e1
  s1 < e2 && s2 < e1
end

lines = STDIN.readlines
bookings = {}  # id -> {room, day, start, end, who}
next_id = 1

lines.each_with_index do |line, idx|
  line_num = idx + 1

  next if line.strip.empty?

  fields = line.split

  if fields.empty?
    next
  end

  cmd = fields[0]

  unless %w[BOOK CANCEL FREE].include?(cmd)
    puts "line #{line_num}: error: unknown command"
    next
  end

  if cmd == "BOOK"
    if fields.length != 5
      puts "line #{line_num}: error: wrong field count"
      next
    end

    room, day, time_range, who = fields[1], fields[2], fields[3], fields[4]

    unless validate_room(room)
      puts "line #{line_num}: error: bad room"
      next
    end

    unless validate_day(day)
      puts "line #{line_num}: error: bad day"
      next
    end

    if !time_range.include?('-')
      puts "line #{line_num}: error: bad time"
      next
    end

    start_str, end_str = time_range.split('-')

    start_mins = parse_time(start_str)
    if start_mins.nil?
      puts "line #{line_num}: error: bad time"
      next
    end

    end_mins = parse_time(end_str)
    if end_mins.nil?
      puts "line #{line_num}: error: bad time"
      next
    end

    if start_mins >= end_mins
      puts "line #{line_num}: error: bad time"
      next
    end

    unless validate_name(who)
      puts "line #{line_num}: error: bad name"
      next
    end

    # Check for conflicts
    conflict_id = nil
    conflict_booking = nil
    bookings.each do |id, booking|
      if booking[:room] == room && booking[:day] == day &&
         times_overlap(booking[:start], booking[:end], start_mins, end_mins)
        if conflict_id.nil? || booking[:start] < conflict_booking[:start]
          conflict_id = id
          conflict_booking = booking
        end
      end
    end

    if conflict_id
      puts "CONFLICT #{room} #{day} with ##{conflict_id} (#{conflict_booking[:who]} #{minutes_to_time(conflict_booking[:start])}-#{minutes_to_time(conflict_booking[:end])})"
      next
    end

    # Check person's booking limit per day
    count = bookings.values.count { |b| b[:who] == who && b[:day] == day }
    if count >= 3
      puts "LIMIT #{who} #{day}"
      next
    end

    # Accept booking
    id = next_id
    bookings[id] = {room: room, day: day, start: start_mins, end: end_mins, who: who}
    puts "OK ##{id} #{room} #{day} #{minutes_to_time(start_mins)}-#{minutes_to_time(end_mins)} #{who}"
    next_id += 1

  elsif cmd == "CANCEL"
    if fields.length != 2
      puts "line #{line_num}: error: wrong field count"
      next
    end

    id_str = fields[1]

    unless id_str.match?(/^\d+$/)
      puts "line #{line_num}: error: bad id"
      next
    end

    id = id_str.to_i

    if bookings[id]
      bookings.delete(id)
      puts "CANCELLED ##{id}"
    else
      puts "NO BOOKING ##{id}"
    end

  elsif cmd == "FREE"
    if fields.length != 4
      puts "line #{line_num}: error: wrong field count"
      next
    end

    room, day, dur_str = fields[1], fields[2], fields[3]

    unless validate_room(room)
      puts "line #{line_num}: error: bad room"
      next
    end

    unless validate_day(day)
      puts "line #{line_num}: error: bad day"
      next
    end

    duration = validate_duration(dur_str)
    if duration.nil?
      puts "line #{line_num}: error: bad duration"
      next
    end

    # Find all bookings for this room and day
    room_bookings = bookings.values.select { |b| b[:room] == room && b[:day] == day }
                           .sort_by { |b| b[:start] }

    # Find earliest slot
    end_time = 12 * 60  # 20:00 = minute 720

    found = false
    for start_slot in (0...end_time).step(15) do
      end_slot = start_slot + duration
      if end_slot > end_time
        break
      end

      # Check if this slot conflicts with any booking
      conflict = false
      room_bookings.each do |b|
        if times_overlap(start_slot, end_slot, b[:start], b[:end])
          conflict = true
          break
        end
      end

      if !conflict
        puts "FREE #{room} #{day} #{minutes_to_time(start_slot)}-#{minutes_to_time(end_slot)}"
        found = true
        break
      end
    end

    unless found
      puts "FULL #{room} #{day}"
    end
  end
end

# Final schedule
puts "== schedule =="
days_order = %w[Mon Tue Wed Thu Fri Sat Sun]
sorted_bookings = bookings.sort_by do |id, booking|
  [days_order.index(booking[:day]), booking[:room], booking[:start]]
end

if sorted_bookings.empty?
  puts "(none)"
else
  sorted_bookings.each do |id, booking|
    start_time = minutes_to_time(booking[:start])
    end_time = minutes_to_time(booking[:end])
    puts format("%s %-8s %s-%s #%d %s", booking[:day], booking[:room], start_time, end_time, id, booking[:who])
  end
end

# Usage stats
puts "== usage =="
rooms_with_bookings = bookings.values.map { |b| b[:room] }.uniq.sort
if rooms_with_bookings.empty?
  puts "(none)"
else
  rooms_with_bookings.each do |room|
    total_mins = bookings.values.select { |b| b[:room] == room }.sum { |b| b[:end] - b[:start] }
    hours = total_mins / 60
    mins = total_mins % 60
    puts format("%-8s %dh%02dm", room, hours, mins)
  end
end
