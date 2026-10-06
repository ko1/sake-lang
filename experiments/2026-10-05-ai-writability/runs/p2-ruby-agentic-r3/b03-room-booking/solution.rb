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

def fmt(t) = format("%02d:%02d", t / 60, t % 60)

bookings = {} # id => {room, day, s, e, who}
next_id = 1

$stdin.each_line.with_index(1) do |line, no|
  f = line.chomp.split(/ +/).reject(&:empty?)
  next if f.empty?
  err = lambda { |m| puts "line #{no}: error: #{m}" }
  case f[0]
  when "BOOK"
    next err.("wrong field count") if f.size != 5
    _, room, day, tr, who = f
    next err.("bad room") unless room =~ /\A[A-Z0-9]{1,8}\z/
    next err.("bad day") unless DAYS.include?(day)
    ts, te = tr.split("-", -1)
    s = tr.count("-") == 1 ? parse_time(ts) : nil
    e = s && parse_time(te)
    next err.("bad time") unless s && e && s < e
    next err.("bad name") unless who =~ /\A[a-z]{1,12}\z/
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
    next err.("wrong field count") if f.size != 2
    next err.("bad id") unless f[1] =~ /\A\d+\z/
    id = f[1].to_i
    if bookings.delete(id)
      puts "CANCELLED ##{id}"
    else
      puts "NO BOOKING ##{id}"
    end
  when "FREE"
    next err.("wrong field count") if f.size != 4
    _, room, day, ms = f
    next err.("bad room") unless room =~ /\A[A-Z0-9]{1,8}\z/
    next err.("bad day") unless DAYS.include?(day)
    next err.("bad duration") unless ms =~ /\A\d+\z/ && ms.to_i > 0 && ms.to_i % 15 == 0
    n = ms.to_i
    bs = bookings.values.select { |b| b[:room] == room && b[:day] == day }.sort_by { |b| b[:s] }
    cur = 480
    found = nil
    bs.each do |b|
      if b[:s] - cur >= n
        found = cur
        break
      end
      cur = [cur, b[:e]].max
    end
    found ||= (1200 - cur >= n ? cur : nil)
    if found
      puts "FREE #{room} #{day} #{fmt(found)}-#{fmt(found + n)}"
    else
      puts "FULL #{room} #{day}"
    end
  else
    err.("unknown command")
  end
end

puts "== schedule =="
list = bookings.map { |id, b| [DAYS.index(b[:day]), b[:room].b, b[:s], id, b] }.sort_by { |a| a[0..3] }
puts "(none)" if list.empty?
list.each do |_, _, _, id, b|
  puts format("%s %-8s %s-%s #%d %s", b[:day], b[:room], fmt(b[:s]), fmt(b[:e]), id, b[:who])
end
puts "== usage =="
use = Hash.new(0)
bookings.each_value { |b| use[b[:room]] += b[:e] - b[:s] }
puts "(none)" if use.empty?
use.keys.sort_by(&:b).each { |r| puts format("%-8s %dh%02dm", r, use[r] / 60, use[r] % 60) }
