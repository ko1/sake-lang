DAYS = %w[Mon Tue Wed Thu Fri Sat Sun]

def tm(s)
  return nil unless s =~ /\A(\d\d):(\d\d)\z/
  h = $1.to_i
  m = $2.to_i
  return nil if m >= 60
  t = h * 60 + m
  return nil if t % 15 != 0 || t < 480 || t > 1200
  t
end

def hm(t)
  format("%02d:%02d", t / 60, t % 60)
end

bookings = {} # id => {room, day, s, e, who}
next_id = 1

$stdin.each_line.with_index(1) do |raw, no|
  f = raw.chomp.split(/ +/).reject(&:empty?)
  next if f.empty?
  cmd = f[0]
  want = {"BOOK" => 5, "CANCEL" => 2, "FREE" => 4}[cmd]
  if want.nil?
    puts "line #{no}: error: unknown command"
    next
  end
  if f.size != want
    puts "line #{no}: error: wrong field count"
    next
  end
  err = nil
  s = e = nil
  case cmd
  when "BOOK"
    _, room, day, rng, who = f
    if room !~ /\A[A-Z0-9]{1,8}\z/ then err = "bad room"
    elsif !DAYS.include?(day) then err = "bad day"
    else
      if rng =~ /\A([^-]*)-([^-]*)\z/
        s = tm($1)
        e = tm($2)
      end
      if s.nil? || e.nil? || s >= e then err = "bad time"
      elsif who !~ /\A[a-z]{1,12}\z/ then err = "bad name"
      end
    end
  when "CANCEL"
    err = "bad id" if f[1] !~ /\A\d+\z/
  when "FREE"
    _, room, day, mins = f
    if room !~ /\A[A-Z0-9]{1,8}\z/ then err = "bad room"
    elsif !DAYS.include?(day) then err = "bad day"
    elsif mins !~ /\A\d+\z/ || mins.to_i <= 0 || mins.to_i % 15 != 0 then err = "bad duration"
    end
  end
  if err
    puts "line #{no}: error: #{err}"
    next
  end
  case cmd
  when "BOOK"
    _, room, day, _, who = f
    conf = bookings.select { |_, b| b[:room] == room && b[:day] == day && b[:s] < e && s < b[:e] }
    if !conf.empty?
      id, b = conf.min_by { |i, bb| [bb[:s], i] }
      puts "CONFLICT #{room} #{day} with ##{id} (#{b[:who]} #{hm(b[:s])}-#{hm(b[:e])})"
    elsif bookings.count { |_, b| b[:who] == who && b[:day] == day } >= 3
      puts "LIMIT #{who} #{day}"
    else
      bookings[next_id] = {room: room, day: day, s: s, e: e, who: who}
      puts "OK ##{next_id} #{room} #{day} #{hm(s)}-#{hm(e)} #{who}"
      next_id += 1
    end
  when "CANCEL"
    id = f[1].to_i
    if bookings.delete(id)
      puts "CANCELLED ##{id}"
    else
      puts "NO BOOKING ##{id}"
    end
  when "FREE"
    _, room, day, mins = f
    m = mins.to_i
    found = nil
    t = 480
    while t + m <= 1200
      if bookings.none? { |_, b| b[:room] == room && b[:day] == day && b[:s] < t + m && t < b[:e] }
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
list = bookings.sort_by { |i, b| [DAYS.index(b[:day]), b[:room].b, b[:s], i] }
if list.empty?
  puts "(none)"
else
  list.each { |i, b| puts format("%s %-8s %s-%s #%d %s", b[:day], b[:room], hm(b[:s]), hm(b[:e]), i, b[:who]) }
end
puts "== usage =="
use = Hash.new(0)
bookings.each_value { |b| use[b[:room]] += b[:e] - b[:s] }
if use.empty?
  puts "(none)"
else
  use.keys.sort_by(&:b).each { |r| puts format("%-8s %dh%02dm", r, use[r] / 60, use[r] % 60) }
end
