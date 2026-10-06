DAYS = %w[Mon Tue Wed Thu Fri Sat Sun]

def parse_time(s)
  return nil unless s =~ /\A(\d\d):(\d\d)\z/
  h = $1.to_i
  m = $2.to_i
  return nil if m >= 60 || m % 15 != 0
  t = h * 60 + m
  return nil if t < 480 || t > 1200
  t
end

def hm(t) = format("%02d:%02d", t / 60, t % 60)

bookings = {} # id => [room, day, s, e, who]
next_id = 1

$stdin.each_line.with_index(1) do |line, no|
  f = line.chomp.split(/ +/).reject(&:empty?)
  next if f.empty?
  cmd = f[0]
  unless %w[BOOK CANCEL FREE].include?(cmd)
    puts "line #{no}: error: unknown command"
    next
  end
  if f.size != { "BOOK" => 6, "CANCEL" => 2, "FREE" => 4 }[cmd]
    puts "line #{no}: error: wrong field count"
    next
  end
  err = nil
  case cmd
  when "BOOK"
    _, room, day, tr, who = f
    s = e = nil
    if room !~ /\A[A-Z0-9]{1,8}\z/ then err = "bad room"
    elsif !DAYS.include?(day) then err = "bad day"
    else
      a, b = tr.split("-", 2)
      s = parse_time(a)
      e = b && parse_time(b)
      err = "bad time" if s.nil? || e.nil? || s >= e || tr.count("-") != 1
      err ||= "bad name" if who !~ /\A[a-z]{1,12}\z/
    end
    if err
      puts "line #{no}: error: #{err}"
      next
    end
    conf = bookings.select { |_, b| b[0] == room && b[1] == day && b[2] < e && s < b[3] }
                   .min_by { |id, b| [b[2], id] }
    if conf
      id, b = conf
      puts "CONFLICT #{room} #{day} with ##{id} (#{b[4]} #{hm(b[2])}-#{hm(b[3])})"
    elsif bookings.count { |_, b| b[4] == who && b[1] == day } >= 3
      puts "LIMIT #{who} #{day}"
    else
      id = next_id
      next_id += 1
      bookings[id] = [room, day, s, e, who]
      puts "OK ##{id} #{room} #{day} #{hm(s)}-#{hm(e)} #{who}"
    end
  when "CANCEL"
    if f[1] !~ /\A\d+\z/
      puts "line #{no}: error: bad id"
      next
    end
    id = f[1].to_i
    if bookings.delete(id)
      puts "CANCELLED ##{id}"
    else
      puts "NO BOOKING ##{id}"
    end
  when "FREE"
    _, room, day, mins = f
    err = if room !~ /\A[A-Z0-9]{1,8}\z/ then "bad room"
          elsif !DAYS.include?(day) then "bad day"
          elsif mins !~ /\A\d+\z/ || mins.to_i <= 0 || mins.to_i % 15 != 0 then "bad duration"
          end
    if err
      puts "line #{no}: error: #{err}"
      next
    end
    m = mins.to_i
    found = nil
    s = 480
    while s + m <= 1200
      if bookings.none? { |_, b| b[0] == room && b[1] == day && b[2] < s + m && s < b[3] }
        found = s
        break
      end
      s += 15
    end
    puts found ? "FREE #{room} #{day} #{hm(found)}-#{hm(found + m)}" : "FULL #{room} #{day}"
  end
end

puts "== schedule =="
list = bookings.map { |id, b| [id, *b] }.sort_by { |id, room, day, s, _e, _w| [DAYS.index(day), room.b, s, id] }
puts "(none)" if list.empty?
list.each do |id, room, day, s, e, who|
  puts format("%s %-8s %s-%s #%d %s", day, room, hm(s), hm(e), id, who)
end
puts "== usage =="
usage = Hash.new(0)
bookings.each_value { |b| usage[b[0]] += b[3] - b[2] }
puts "(none)" if usage.empty?
usage.keys.sort_by(&:b).each { |r| puts format("%-8s %dh%02dm", r, usage[r] / 60, usage[r] % 60) }
