days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
bookings = {}
next_id = 1
line_num = 0

$stdin.each_line do |line|
  line_num += 1
  line = line.chomp
  next if line.strip.empty?

  fields = line.split(/\s+/)
  next if fields.empty?

  command = fields[0]

  unless ['BOOK', 'CANCEL', 'FREE'].include?(command)
    puts "line #{line_num}: error: unknown command"
    next
  end

  if (command == 'BOOK' && fields.length != 5) || (command == 'CANCEL' && fields.length != 2) || (command == 'FREE' && fields.length != 4)
    puts "line #{line_num}: error: wrong field count"
    next
  end

  if command == 'BOOK'
    room, day, time_range, who = fields[1], fields[2], fields[3], fields[4]

    unless room =~ /^[A-Z0-9]{1,8}$/
      puts "line #{line_num}: error: bad room"
      next
    end

    unless days.include?(day)
      puts "line #{line_num}: error: bad day"
      next
    end

    unless time_range =~ /^\d{2}:\d{2}-\d{2}:\d{2}$/
      puts "line #{line_num}: error: bad time"
      next
    end

    start_str, end_str = time_range.split('-')
    start_h, start_m = start_str.split(':').map(&:to_i)
    end_h, end_m = end_str.split(':').map(&:to_i)

    start_min = start_h * 60 + start_m
    end_min = end_h * 60 + end_m

    if start_min < 480 || start_min > 1200 || start_m % 15 != 0
      puts "line #{line_num}: error: bad time"
      next
    end

    if end_min < 480 || end_min > 1200 || end_m % 15 != 0
      puts "line #{line_num}: error: bad time"
      next
    end

    if start_min >= end_min
      puts "line #{line_num}: error: bad time"
      next
    end

    unless who =~ /^[a-z]{1,12}$/
      puts "line #{line_num}: error: bad name"
      next
    end

    # Check conflicts
    conflict = nil
    bookings.each do |id, booking|
      if booking[:room] == room && booking[:day] == day
        if !(booking[:end] <= start_min || booking[:start] >= end_min)
          if conflict.nil? || booking[:start] < conflict[:start]
            conflict = booking.merge(id: id)
          end
        end
      end
    end

    if conflict
      start_fmt = format('%02d:%02d', conflict[:start] / 60, conflict[:start] % 60)
      end_fmt = format('%02d:%02d', conflict[:end] / 60, conflict[:end] % 60)
      puts "CONFLICT #{room} #{day} with ##{conflict[:id]} (#{conflict[:who]} #{start_fmt}-#{end_fmt})"
      next
    end

    # Check person limit
    count_today = bookings.count { |_, b| b[:day] == day && b[:who] == who }
    if count_today >= 3
      puts "LIMIT #{who} #{day}"
      next
    end

    # Book it
    bookings[next_id] = {
      room: room,
      day: day,
      start: start_min,
      end: end_min,
      who: who
    }

    start_fmt = format('%02d:%02d', start_min / 60, start_min % 60)
    end_fmt = format('%02d:%02d', end_min / 60, end_min % 60)
    puts "OK ##{next_id} #{room} #{day} #{start_fmt}-#{end_fmt} #{who}"
    next_id += 1

  elsif command == 'CANCEL'
    id = fields[1]

    unless id =~ /^\d+$/
      puts "line #{line_num}: error: bad id"
      next
    end

    id_int = id.to_i

    if bookings[id_int]
      bookings.delete(id_int)
      puts "CANCELLED ##{id_int}"
    else
      puts "NO BOOKING ##{id_int}"
    end

  elsif command == 'FREE'
    room, day, minutes = fields[1], fields[2], fields[3]

    unless room =~ /^[A-Z0-9]{1,8}$/
      puts "line #{line_num}: error: bad room"
      next
    end

    unless days.include?(day)
      puts "line #{line_num}: error: bad day"
      next
    end

    unless minutes =~ /^\d+$/ && minutes.to_i > 0 && minutes.to_i % 15 == 0
      puts "line #{line_num}: error: bad duration"
      next
    end

    duration = minutes.to_i

    room_bookings = bookings.select { |_, b| b[:room] == room && b[:day] == day }.values
    room_bookings = room_bookings.sort_by { |b| b[:start] }

    current = 480
    free_slot = nil

    room_bookings.each do |booking|
      if current + duration <= booking[:start]
        free_slot = [current, current + duration]
        break
      end
      current = booking[:end]
    end

    if !free_slot && current + duration <= 1200
      free_slot = [current, current + duration]
    end

    if free_slot
      start_min, end_min = free_slot
      start_fmt = format('%02d:%02d', start_min / 60, start_min % 60)
      end_fmt = format('%02d:%02d', end_min / 60, end_min % 60)
      puts "FREE #{room} #{day} #{start_fmt}-#{end_fmt}"
    else
      puts "FULL #{room} #{day}"
    end
  end
end

puts "== schedule =="
if bookings.empty?
  puts "(none)"
else
  sorted = bookings.sort_by do |id, booking|
    day_idx = days.index(booking[:day])
    [day_idx, booking[:room], booking[:start], id]
  end

  sorted.each do |id, booking|
    start_fmt = format('%02d:%02d', booking[:start] / 60, booking[:start] % 60)
    end_fmt = format('%02d:%02d', booking[:end] / 60, booking[:end] % 60)
    puts format("%s %-8s %s-%s #%d %s", booking[:day], booking[:room], start_fmt, end_fmt, id, booking[:who])
  end
end

puts "== usage =="
rooms = bookings.group_by { |_, b| b[:room] }

if rooms.empty?
  puts "(none)"
else
  rooms.keys.sort.each do |room|
    total_min = rooms[room].sum { |_, b| b[:end] - b[:start] }
    hours = total_min / 60
    mins = total_min % 60
    puts format("%-8s %dh%02dm", room, hours, mins)
  end
end
