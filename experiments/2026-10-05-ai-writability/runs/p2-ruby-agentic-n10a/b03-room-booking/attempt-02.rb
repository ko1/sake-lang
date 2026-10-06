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

def hm(t)
  format("%02d:%02d", t / 60, t % 60)
end

bookings = {}
next_id = 1

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.chomp.split(" ")
  next if f.empty?
  err = lambda { |m| puts "line #{n}: error: #{m}" }
  cmd = f[0]
  unless %w[BOOK CANCEL FREE].include?(cmd)
    err.call("unknown command")
    next
  end
  need = {"BOOK" => 5, "CANCEL" => 2, "FREE" => 4}[cmd]
  if f.size != need
    err.call("wrong field count")
    next
  end
  case cmd
  when "BOOK"
    _, room, day, tr, who = f
    if room !~ /\A[A-Z0-9]{1,8}\z/ then err.call("bad room"); next end
    if !DAYS.include?(day) then err.call("bad day"); next end
    s, e = tr.split("-", -1)
    s = s && parse_time(s)
    e = e && parse_time(e) if s
    if tr.count("-") != 1 || s.nil? || e.nil? || s >= e then err.call("bad time"); next end
    if who !~ /\A[a-z]{1,12}\z/ then err.call("bad name"); next end
    c = bookings.values.select { |b| b[:room] == room && b[:day] == day && s < b[:e] && b[:s] < e }
                .min_by { |b| [b[:s], b[:id]] }
    if c
      puts "CONFLICT #{room} #{day} with ##{c[:id]} (#{c[:who]} #{hm(c[:s])}-#{hm(c[:e])})"
    elsif bookings.values.count { |b| b[:who] == who && b[:day] == day } >= 3
      puts "LIMIT #{who} #{day}"
    else
      id = next_id
      next_id += 1
      bookings[id] = {id: id, room: room, day: day, s: s, e: e, who: who}
      puts "OK ##{id} #{room} #{day} #{hm(s)}-#{hm(e)} #{who}"
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
    if mins !~ /\A\d+\z/ || mins.to_i <= 0 || mins.to_i % 15 != 0 then err.call("bad duration"); next end
    d = mins.to_i
    bs = bookings.values.select { |b| b[:room] == room && b[:day] == day }
    found = nil
    (480..1200 - d).step(15) do |st|
      if bs.none? { |b| st < b[:e] && b[:s] < st + d }
        found = st
        break
      end
    end
    if found
      puts "FREE #{room} #{day} #{hm(found)}-#{hm(found + d)}"
    else
      puts "FULL #{room} #{day}"
    end
  end
end

puts "== schedule =="
list = bookings.values.sort_by { |b| [DAYS.index(b[:day]), b[:room].b, b[:s], b[:id]] }
puts "(none)" if list.empty?
list.each do |b|
  puts format("%s %-8s %s-%s #%d %s", b[:day], b[:room], hm(b[:s]), hm(b[:e]), b[:id], b[:who])
end
puts "== usage =="
use = Hash.new(0)
list.each { |b| use[b[:room]] += b[:e] - b[:s] }
puts "(none)" if use.empty?
use.keys.sort_by(&:b).each do |r|
  puts format("%-8s %dh%02dm", r, use[r] / 60, use[r] % 60)
end
