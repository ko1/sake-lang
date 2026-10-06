DAYS = %w[Mon Tue Wed Thu Fri Sat Sun]

def hm(m)
  format("%02d:%02d", m / 60, m % 60)
end

def parse_time(s)
  return nil unless s =~ /\A(\d\d):(\d\d)\z/
  h = $1.to_i
  mi = $2.to_i
  return nil if mi >= 60
  t = h * 60 + mi
  return nil if t % 15 != 0 || t < 480 || t > 1200
  t
end

bookings = {} # id => [room, day, s, e, who]
next_id = 1

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.chomp.split(" ")
  next if f.empty?
  cmd = f[0]
  want = { "BOOK" => 5, "CANCEL" => 2, "FREE" => 4 }[cmd]
  if want.nil?
    puts "line #{n}: error: unknown command"
    next
  end
  if f.size != want
    puts "line #{n}: error: wrong field count"
    next
  end
  err = nil
  case cmd
  when "BOOK"
    room, day, range, who = f[1], f[2], f[3], f[4]
    s = e = nil
    if room !~ /\A[A-Z0-9]{1,8}\z/ then err = "bad room"
    elsif !DAYS.include?(day) then err = "bad day"
    else
      if range =~ /\A([^-]*)-([^-]*)\z/
        s = parse_time($1)
        e = parse_time($2)
      end
      if s.nil? || e.nil? || s >= e then err = "bad time"
      elsif who !~ /\A[a-z]{1,12}\z/ then err = "bad name"
      end
    end
    if err
      puts "line #{n}: error: #{err}"
      next
    end
    conf = bookings.select { |_, b| b[0] == room && b[1] == day && s < b[3] && b[2] < e }
    if !conf.empty?
      id, b = conf.min_by { |i, bb| [bb[2], i] }
      puts "CONFLICT #{room} #{day} with ##{id} (#{b[4]} #{hm(b[2])}-#{hm(b[3])})"
    elsif bookings.values.count { |b| b[4] == who && b[1] == day } >= 3
      puts "LIMIT #{who} #{day}"
    else
      id = next_id
      next_id += 1
      bookings[id] = [room, day, s, e, who]
      puts "OK ##{id} #{room} #{day} #{hm(s)}-#{hm(e)} #{who}"
    end
  when "CANCEL"
    if f[1] !~ /\A\d+\z/
      puts "line #{n}: error: bad id"
      next
    end
    id = f[1].to_i
    if bookings.delete(id)
      puts "CANCELLED ##{id}"
    else
      puts "NO BOOKING ##{id}"
    end
  when "FREE"
    room, day, mins = f[1], f[2], f[3]
    if room !~ /\A[A-Z0-9]{1,8}\z/ then err = "bad room"
    elsif !DAYS.include?(day) then err = "bad day"
    elsif mins !~ /\A\d+\z/ || mins.to_i <= 0 || mins.to_i % 15 != 0 then err = "bad duration"
    end
    if err
      puts "line #{n}: error: #{err}"
      next
    end
    m = mins.to_i
    found = nil
    t = 480
    while t + m <= 1200
      unless bookings.values.any? { |b| b[0] == room && b[1] == day && t < b[3] && b[2] < t + m }
        found = t
        break
      end
      t += 15
    end
    if found
      puts "FREE #{room} #{day} #{hm(found)}-#{hm(found + m)}"
    else
      puts "FULL #{room} #{day}"
    end
  end
end

puts "== schedule =="
list = bookings.map { |id, b| [id, b] }.sort_by { |id, b| [DAYS.index(b[1]), b[0].b, b[2]] }
if list.empty?
  puts "(none)"
else
  list.each do |id, b|
    puts format("%s %-8s %s-%s #%d %s", b[1], b[0], hm(b[2]), hm(b[3]), id, b[4])
  end
end
puts "== usage =="
usage = Hash.new(0)
bookings.each_value { |b| usage[b[0]] += b[3] - b[2] }
if usage.empty?
  puts "(none)"
else
  usage.keys.sort_by(&:b).each do |r|
    puts format("%-8s %dh%02dm", r, usage[r] / 60, usage[r] % 60)
  end
end
