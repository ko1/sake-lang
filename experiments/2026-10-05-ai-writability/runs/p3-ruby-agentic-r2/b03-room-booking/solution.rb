DAYS = %w[Mon Tue Wed Thu Fri Sat Sun]

def tm(s)
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

$stdin.each_line.with_index(1) do |raw, no|
  line = raw.chomp
  next if line.strip.empty?
  f = line.split(/ +/).reject(&:empty?)
  cmd = f[0]
  unless %w[BOOK CANCEL FREE].include?(cmd)
    puts "line #{no}: error: unknown command"
    next
  end
  if f.size != { "BOOK" => 5, "CANCEL" => 2, "FREE" => 4 }[cmd]
    puts "line #{no}: error: wrong field count"
    next
  end
  err = nil
  s = e = nil
  case cmd
  when "BOOK", "FREE"
    err = "bad room" unless f[1] =~ /\A[A-Z0-9]{1,8}\z/
    err ||= "bad day" unless DAYS.include?(f[2])
    if cmd == "BOOK"
      unless err
        a, b = f[3].split("-", 2)
        s = tm(a.to_s) if f[3].count("-") == 1
        e = tm(b.to_s) if f[3].count("-") == 1
        err = "bad time" unless s && e && s < e
      end
      err ||= "bad name" unless f[4] =~ /\A[a-z]{1,12}\z/
    else
      err ||= "bad duration" unless f[3] =~ /\A\d+\z/ && f[3].to_i > 0 && f[3].to_i % 15 == 0
    end
  when "CANCEL"
    err = "bad id" unless f[1] =~ /\A\d+\z/
  end
  if err
    puts "line #{no}: error: #{err}"
    next
  end
  case cmd
  when "BOOK"
    room, day, who = f[1], f[2], f[4]
    same = bookings.values.select { |b| b[:room] == room && b[:day] == day }
    c = same.select { |b| b[:s] < e && s < b[:e] }.min_by { |b| b[:s] }
    if c
      id = bookings.key(c)
      puts "CONFLICT #{room} #{day} with ##{id} (#{c[:who]} #{fmt(c[:s])}-#{fmt(c[:e])})"
    elsif bookings.values.count { |b| b[:who] == who && b[:day] == day } >= 3
      puts "LIMIT #{who} #{day}"
    else
      bookings[next_id] = { room:, day:, s:, e:, who: }
      puts "OK ##{next_id} #{room} #{day} #{fmt(s)}-#{fmt(e)} #{who}"
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
    room, day, n = f[1], f[2], f[3].to_i
    same = bookings.values.select { |b| b[:room] == room && b[:day] == day }
    found = nil
    t = 480
    while t + n <= 1200
      if same.none? { |b| b[:s] < t + n && t < b[:e] }
        found = t
        break
      end
      t += 15
    end
    puts found ? "FREE #{room} #{day} #{fmt(found)}-#{fmt(found + n)}" : "FULL #{room} #{day}"
  end
end

puts "== schedule =="
list = bookings.sort_by { |id, b| [DAYS.index(b[:day]), b[:room].b, b[:s]] }
puts "(none)" if list.empty?
list.each { |id, b| puts format("%s %-8s %s-%s #%d %s", b[:day], b[:room], fmt(b[:s]), fmt(b[:e]), id, b[:who]) }
puts "== usage =="
tot = Hash.new(0)
bookings.each_value { |b| tot[b[:room]] += b[:e] - b[:s] }
puts "(none)" if tot.empty?
tot.keys.sort_by(&:b).each { |r| puts format("%-8s %dh%02dm", r, tot[r] / 60, tot[r] % 60) }
