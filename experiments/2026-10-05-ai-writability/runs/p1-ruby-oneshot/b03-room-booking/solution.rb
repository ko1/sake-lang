DAYS = %w[Mon Tue Wed Thu Fri Sat Sun]

def parse_time(s)
  m = s.match(/\A(\d\d):(\d\d)\z/) or return nil
  h = m[1].to_i
  mi = m[2].to_i
  return nil if mi >= 60 || mi % 15 != 0
  t = h * 60 + mi
  return nil if t < 480 || t > 1200
  t
end

def fmt(t)
  format("%02d:%02d", t / 60, t % 60)
end

bookings = {} # id => {room, day, s, e, who}
next_id = 1

$stdin.each_line.with_index(1) do |raw, no|
  line = raw.chomp
  next if line.match?(/\A *\z/)
  f = line.split(/ +/).reject(&:empty?)
  cmd = f[0]
  unless %w[BOOK CANCEL FREE].include?(cmd)
    puts "line #{no}: error: unknown command"
    next
  end
  want = { "BOOK" => 5, "CANCEL" => 2, "FREE" => 4 }[cmd]
  if f.size != want
    puts "line #{no}: error: wrong field count"
    next
  end

  case cmd
  when "BOOK"
    _, room, day, tm, who = f
    s = e = nil
    if tm.match?(/\A[^-]*-[^-]*\z/)
      a, b = tm.split("-", 2)
      s = parse_time(a)
      e = parse_time(b)
    end
    err =
      if !room.match?(/\A[A-Z0-9]{1,8}\z/) then "bad room"
      elsif !DAYS.include?(day) then "bad day"
      elsif s.nil? || e.nil? || s >= e then "bad time"
      elsif !who.match?(/\A[a-z]{1,12}\z/) then "bad name"
      end
    if err
      puts "line #{no}: error: #{err}"
      next
    end
    conf = bookings.select { |_, b| b[:room] == room && b[:day] == day && s < b[:e] && b[:s] < e }
                   .min_by { |id, b| [b[:s], id] }
    if conf
      id, b = conf
      puts "CONFLICT #{room} #{day} with ##{id} (#{b[:who]} #{fmt(b[:s])}-#{fmt(b[:e])})"
    elsif bookings.count { |_, b| b[:who] == who && b[:day] == day } >= 3
      puts "LIMIT #{who} #{day}"
    else
      id = next_id
      next_id += 1
      bookings[id] = { room: room, day: day, s: s, e: e, who: who }
      puts "OK ##{id} #{room} #{day} #{fmt(s)}-#{fmt(e)} #{who}"
    end
  when "CANCEL"
    unless f[1].match?(/\A\d+\z/)
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
    err =
      if !room.match?(/\A[A-Z0-9]{1,8}\z/) then "bad room"
      elsif !DAYS.include?(day) then "bad day"
      elsif !mins.match?(/\A\d+\z/) || mins.to_i <= 0 || mins.to_i % 15 != 0 then "bad duration"
      end
    if err
      puts "line #{no}: error: #{err}"
      next
    end
    m = mins.to_i
    t = 480
    found = nil
    bookings.values.select { |b| b[:room] == room && b[:day] == day }.sort_by { |b| b[:s] }.each do |b|
      if b[:s] - t >= m
        found = t
        break
      end
      t = b[:e] if b[:e] > t
    end
    found = t if found.nil? && 1200 - t >= m
    if found
      puts "FREE #{room} #{day} #{fmt(found)}-#{fmt(found + m)}"
    else
      puts "FULL #{room} #{day}"
    end
  end
end

puts "== schedule =="
list = bookings.sort_by { |id, b| [DAYS.index(b[:day]), b[:room].b, b[:s], id] }
if list.empty?
  puts "(none)"
else
  list.each do |id, b|
    puts format("%s %-8s %s-%s #%d %s", b[:day], b[:room], fmt(b[:s]), fmt(b[:e]), id, b[:who])
  end
end
puts "== usage =="
usage = Hash.new(0)
bookings.each_value { |b| usage[b[:room]] += b[:e] - b[:s] }
if usage.empty?
  puts "(none)"
else
  usage.keys.sort_by(&:b).each do |r|
    puts format("%-8s %dh%02dm", r, usage[r] / 60, usage[r] % 60)
  end
end
