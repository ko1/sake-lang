DAYS = %w[Mon Tue Wed Thu Fri Sat Sun]
Booking = Struct.new(:id, :room, :day, :s, :e, :who)

def parse_time(t)
  return nil unless t =~ /\A(\d\d):(\d\d)\z/
  h = $1.to_i
  m = $2.to_i
  return nil if m >= 60 || m % 15 != 0
  v = h * 60 + m
  return nil if v < 480 || v > 1200
  v
end

def fmt(v) = format("%02d:%02d", v / 60, v % 60)

books = []
next_id = 1
$stdin.each_line.with_index(1) do |raw, no|
  f = raw.chomp.split(/ +/).reject(&:empty?)
  next if f.empty?
  err = ->(m) { puts "line #{no}: error: #{m}" }
  cmd = f[0]
  unless %w[BOOK CANCEL FREE].include?(cmd)
    err.("unknown command")
    next
  end
  if f.size != { "BOOK" => 5, "CANCEL" => 2, "FREE" => 4 }[cmd]
    err.("wrong field count")
    next
  end
  case cmd
  when "BOOK"
    _, room, day, tr, who = f
    if room !~ /\A[A-Z0-9]{1,8}\z/ then err.("bad room"); next end
    unless DAYS.include?(day) then err.("bad day"); next end
    ts, te = tr.split("-", 2)
    s = ts && parse_time(ts)
    e = te && parse_time(te)
    if s.nil? || e.nil? || tr.count("-") != 1 || s >= e then err.("bad time"); next end
    if who !~ /\A[a-z]{1,12}\z/ then err.("bad name"); next end
    conf = books.select { |b| b.room == room && b.day == day && s < b.e && b.s < e }.min_by(&:s)
    if conf
      puts "CONFLICT #{room} #{day} with ##{conf.id} (#{conf.who} #{fmt(conf.s)}-#{fmt(conf.e)})"
    elsif books.count { |b| b.who == who && b.day == day } >= 3
      puts "LIMIT #{who} #{day}"
    else
      books << Booking.new(next_id, room, day, s, e, who)
      puts "OK ##{next_id} #{room} #{day} #{fmt(s)}-#{fmt(e)} #{who}"
      next_id += 1
    end
  when "CANCEL"
    if f[1] !~ /\A\d+\z/ then err.("bad id"); next end
    id = f[1].to_i
    if (b = books.find { |x| x.id == id })
      books.delete(b)
      puts "CANCELLED ##{id}"
    else
      puts "NO BOOKING ##{id}"
    end
  when "FREE"
    _, room, day, ms = f
    if room !~ /\A[A-Z0-9]{1,8}\z/ then err.("bad room"); next end
    unless DAYS.include?(day) then err.("bad day"); next end
    if ms !~ /\A\d+\z/ || ms.to_i <= 0 || ms.to_i % 15 != 0 then err.("bad duration"); next end
    n = ms.to_i
    bs = books.select { |b| b.room == room && b.day == day }.sort_by(&:s)
    t = 480
    bs.each { |b| t = b.e if b.e > t && b.s < t + n }
    # t only advances past bookings that overlap the candidate window
    loop do
      c = bs.find { |b| b.s < t + n && t < b.e }
      break unless c
      t = c.e
    end
    if t + n <= 1200
      puts "FREE #{room} #{day} #{fmt(t)}-#{fmt(t + n)}"
    else
      puts "FULL #{room} #{day}"
    end
  end
end

puts "== schedule =="
sorted = books.sort_by { |b| [DAYS.index(b.day), b.room.b, b.s] }
if sorted.empty?
  puts "(none)"
else
  sorted.each { |b| puts format("%s %-8s %s-%s #%d %s", b.day, b.room, fmt(b.s), fmt(b.e), b.id, b.who) }
end
puts "== usage =="
if books.empty?
  puts "(none)"
else
  books.group_by(&:room).sort_by { |r, _| r.b }.each do |r, bs|
    m = bs.sum { |b| b.e - b.s }
    puts format("%-8s %dh%02dm", r, m / 60, m % 60)
  end
end
