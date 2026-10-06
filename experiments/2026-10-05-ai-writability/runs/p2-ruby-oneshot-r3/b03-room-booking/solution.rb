DAYS = %w[Mon Tue Wed Thu Fri Sat Sun]

def parse_time(s)
  return nil unless s =~ /\A(\d\d):(\d\d)\z/
  h = $1.to_i
  m = $2.to_i
  return nil if m >= 60
  t = h * 60 + m
  return nil unless t % 15 == 0 && t.between?(480, 1200)
  t
end

def fmt(t)
  format("%02d:%02d", t / 60, t % 60)
end

bookings = {}
next_id = 1

$stdin.each_line.with_index(1) do |raw, no|
  f = raw.chomp.delete("\r").split(/ +/).reject(&:empty?)
  next if f.empty?
  err = lambda { |msg| puts "line #{no}: error: #{msg}" }
  cmd = f[0]
  unless %w[BOOK CANCEL FREE].include?(cmd)
    err.call("unknown command")
    next
  end
  need = { "BOOK" => 5, "CANCEL" => 2, "FREE" => 4 }[cmd]
  if f.size != need
    err.call("wrong field count")
    next
  end

  case cmd
  when "BOOK"
    _, room, day, tm, who = f
    if room !~ /\A[A-Z0-9]{1,8}\z/ then err.call("bad room"); next end
    if !DAYS.include?(day) then err.call("bad day"); next end
    ts, te = tm.split("-", -1)
    s = ts && parse_time(ts)
    e = te && parse_time(te)
    if tm.count("-") != 1 || s.nil? || e.nil? || s >= e
      err.call("bad time")
      next
    end
    if who !~ /\A[a-z]{1,12}\z/ then err.call("bad name"); next end
    clash = bookings.values.select { |b| b[:room] == room && b[:day] == day && s < b[:e] && b[:s] < e }
    if !clash.empty?
      b = clash.min_by { |x| x[:s] }
      puts "CONFLICT #{room} #{day} with ##{b[:id]} (#{b[:who]} #{fmt(b[:s])}-#{fmt(b[:e])})"
    elsif bookings.values.count { |b| b[:who] == who && b[:day] == day } >= 3
      puts "LIMIT #{who} #{day}"
    else
      id = next_id
      next_id += 1
      bookings[id] = { id: id, room: room, day: day, s: s, e: e, who: who }
      puts "OK ##{id} #{room} #{day} #{fmt(s)}-#{fmt(e)} #{who}"
    end
  when "CANCEL"
    if f[1] !~ /\A\d+\z/ then err.call("bad id"); next end
    id = f[1].to_i
    if bookings.delete(id)
      puts "CANCELLED ##{id}"
    else
      puts "NO BOOKING ##{id}"
    end
  when "FREE"
    _, room, day, mins = f
    if room !~ /\A[A-Z0-9]{1,8}\z/ then err.call("bad room"); next end
    if !DAYS.include?(day) then err.call("bad day"); next end
    if mins !~ /\A\d+\z/ || mins.to_i <= 0 || mins.to_i % 15 != 0
      err.call("bad duration")
      next
    end
    d = mins.to_i
    here = bookings.values.select { |b| b[:room] == room && b[:day] == day }
    found = nil
    t = 480
    while t + d <= 1200
      if here.none? { |b| t < b[:e] && b[:s] < t + d }
        found = t
        break
      end
      t += 15
    end
    if found
      puts "FREE #{room} #{day} #{fmt(found)}-#{fmt(found + d)}"
    else
      puts "FULL #{room} #{day}"
    end
  end
end

puts "== schedule =="
list = bookings.values.sort_by { |b| [DAYS.index(b[:day]), b[:room].b, b[:s]] }
if list.empty?
  puts "(none)"
else
  list.each do |b|
    puts format("%s %-8s %s-%s #%d %s", b[:day], b[:room], fmt(b[:s]), fmt(b[:e]), b[:id], b[:who])
  end
end
puts "== usage =="
usage = Hash.new(0)
list.each { |b| usage[b[:room]] += b[:e] - b[:s] }
if usage.empty?
  puts "(none)"
else
  usage.keys.sort_by(&:b).each do |r|
    puts format("%-8s %dh%02dm", r, usage[r] / 60, usage[r] % 60)
  end
end
