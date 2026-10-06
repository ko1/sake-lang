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

def hm(t) = format("%02d:%02d", t / 60, t % 60)

books = {}
next_id = 1

$stdin.each_line.with_index(1) do |line, n|
  f = line.chomp.split(" ")
  next if f.empty?
  err = lambda { |m| puts "line #{n}: error: #{m}" }
  cmd = f[0]
  unless %w[BOOK CANCEL FREE].include?(cmd)
    err.call("unknown command"); next
  end
  if f.size != { "BOOK" => 5 + 1, "CANCEL" => 2, "FREE" => 4 }[cmd]
    err.call("wrong field count"); next
  end
  case cmd
  when "BOOK"
    _, room, day, tr, who = f
    unless room =~ /\A[A-Z0-9]{1,8}\z/ then err.call("bad room"); next end
    unless DAYS.include?(day) then err.call("bad day"); next end
    parts = tr.split("-", -1)
    s = parts.size == 2 ? parse_time(parts[0]) : nil
    e = parts.size == 2 ? parse_time(parts[1]) : nil
    unless s && e && s < e then err.call("bad time"); next end
    unless who =~ /\A[a-z]{1,12}\z/ then err.call("bad name"); next end
    conf = books.values.select { |b| b[:room] == room && b[:day] == day && s < b[:e] && b[:s] < e }.min_by { |b| b[:s] }
    if conf
      puts "CONFLICT #{room} #{day} with ##{conf[:id]} (#{conf[:who]} #{hm(conf[:s])}-#{hm(conf[:e])})"
    elsif books.values.count { |b| b[:who] == who && b[:day] == day } >= 3
      puts "LIMIT #{who} #{day}"
    else
      id = next_id
      next_id += 1
      books[id] = { id: id, room: room, day: day, s: s, e: e, who: who }
      puts "OK ##{id} #{room} #{day} #{hm(s)}-#{hm(e)} #{who}"
    end
  when "CANCEL"
    unless f[1] =~ /\A\d+\z/ then err.call("bad id"); next end
    id = f[1].to_i
    if books.delete(id)
      puts "CANCELLED ##{id}"
    else
      puts "NO BOOKING ##{id}"
    end
  when "FREE"
    _, room, day, dur = f
    unless room =~ /\A[A-Z0-9]{1,8}\z/ then err.call("bad room"); next end
    unless DAYS.include?(day) then err.call("bad day"); next end
    unless dur =~ /\A\d+\z/ && dur.to_i > 0 && dur.to_i % 15 == 0 then err.call("bad duration"); next end
    d = dur.to_i
    bs = books.values.select { |b| b[:room] == room && b[:day] == day }
    found = (480..1200 - d).step(15).find { |st| bs.none? { |b| st < b[:e] && b[:s] < st + d } }
    if found
      puts "FREE #{room} #{day} #{hm(found)}-#{hm(found + d)}"
    else
      puts "FULL #{room} #{day}"
    end
  end
end

puts "== schedule =="
bl = books.values.sort_by { |b| [DAYS.index(b[:day]), b[:room].b, b[:s]] }
puts "(none)" if bl.empty?
bl.each { |b| puts format("%s %-8s %s-%s #%d %s", b[:day], b[:room], hm(b[:s]), hm(b[:e]), b[:id], b[:who]) }
puts "== usage =="
use = Hash.new(0)
bl.each { |b| use[b[:room]] += b[:e] - b[:s] }
puts "(none)" if use.empty?
use.keys.sort_by(&:b).each { |r| puts format("%-8s %dh%02dm", r, use[r] / 60, use[r] % 60) }
