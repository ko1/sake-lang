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

def fmt(t)
  format("%02d:%02d", t / 60, t % 60)
end

bookings = {} # id => {room:, day:, s:, e:, who:}
next_id = 1

$stdin.each_line.with_index(1) do |raw, no|
  line = raw.chomp
  next if line.strip.empty?
  f = line.split(" ")
  err = lambda { |m| puts "line #{no}: error: #{m}" }
  case f[0]
  when "BOOK"
    next err.call("wrong field count") if f.size != 6
    room, day, tm, who = f[1], f[2], f[3], f[4]
    next err.call("bad room") unless room =~ /\A[A-Z0-9]{1,8}\z/
    next err.call("bad day") unless DAYS.include?(day)
    parts = tm =~ /\A(\d\d:\d\d)-(\d\d:\d\d)\z/ ? [$1, $2] : nil
    s = parts && parse_time(parts[0])
    e = parts && parse_time(parts[1])
    next err.call("bad time") if s.nil? || e.nil? || s >= e
    next err.call("bad name") unless who =~ /\A[a-z]{1,12}\z/
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
    next err.call("wrong field count") if f.size != 2
    next err.call("bad id") unless f[1] =~ /\A\d+\z/
    id = f[1].to_i
    if bookings.delete(id)
      puts "CANCELLED ##{id}"
    else
      puts "NO BOOKING ##{id}"
    end
  when "FREE"
    next err.call("wrong field count") if f.size != 4
    room, day = f[1], f[2]
    next err.call("bad room") unless room =~ /\A[A-Z0-9]{1,8}\z/
    next err.call("bad day") unless DAYS.include?(day)
    next err.call("bad duration") unless f[3] =~ /\A\d+\z/ && f[3].to_i > 0 && f[3].to_i % 15 == 0
    m = f[3].to_i
    here = bookings.values.select { |b| b[:room] == room && b[:day] == day }
    found = nil
    s = 480
    while s + m <= 1200
      if here.none? { |b| s < b[:e] && b[:s] < s + m }
        found = s
        break
      end
      s += 15
    end
    if found
      puts "FREE #{room} #{day} #{fmt(found)}-#{fmt(found + m)}"
    else
      puts "FULL #{room} #{day}"
    end
  else
    err.call("unknown command")
  end
end

puts "== schedule =="
sorted = bookings.sort_by { |id, b| [DAYS.index(b[:day]), b[:room].b, b[:s], id] }
if sorted.empty?
  puts "(none)"
else
  sorted.each do |id, b|
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
