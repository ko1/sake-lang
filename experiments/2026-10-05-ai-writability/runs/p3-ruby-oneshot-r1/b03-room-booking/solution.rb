DAYS = %w[Mon Tue Wed Thu Fri Sat Sun]

def tm(s)
  m = s.match(/\A(\d\d):(\d\d)\z/)
  return nil unless m
  h = m[1].to_i
  mi = m[2].to_i
  return nil if mi >= 60 || mi % 15 != 0
  t = h * 60 + mi
  return nil if t < 480 || t > 1200
  t
end

def hm(t)
  format("%02d:%02d", t / 60, t % 60)
end

books = {}
next_id = 1
$stdin.each_line.with_index(1) do |raw, no|
  f = raw.chomp.split(" ")
  next if f.empty?
  err = nil
  case f[0]
  when "BOOK"
    if f.size != 5 then err = "wrong field count"
    elsif !f[1].match?(/\A[A-Z0-9]{1,8}\z/) then err = "bad room"
    elsif !DAYS.include?(f[2]) then err = "bad day"
    else
      m = f[3].match(/\A([^-]*)-([^-]*)\z/)
      s = m && tm(m[1])
      e = m && tm(m[2])
      if s.nil? || e.nil? || s >= e then err = "bad time"
      elsif !f[4].match?(/\A[a-z]{1,12}\z/) then err = "bad name"
      else
        room, day, who = f[1], f[2], f[4]
        conf = books.values.select { |b| b[:room] == room && b[:day] == day && b[:s] < e && s < b[:e] }.min_by { |b| b[:s] }
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
      end
    end
  when "CANCEL"
    if f.size != 2 then err = "wrong field count"
    elsif !f[1].match?(/\A\d+\z/) then err = "bad id"
    else
      id = f[1].to_i
      if books.delete(id) then puts "CANCELLED ##{id}"
      else puts "NO BOOKING ##{id}"
      end
    end
  when "FREE"
    if f.size != 4 then err = "wrong field count"
    elsif !f[1].match?(/\A[A-Z0-9]{1,8}\z/) then err = "bad room"
    elsif !DAYS.include?(f[2]) then err = "bad day"
    elsif !(f[3].match?(/\A\d+\z/) && f[3].to_i > 0 && f[3].to_i % 15 == 0) then err = "bad duration"
    else
      room, day, mins = f[1], f[2], f[3].to_i
      bs = books.values.select { |b| b[:room] == room && b[:day] == day }
      found = nil
      st = 480
      while st + mins <= 1200
        if bs.none? { |b| b[:s] < st + mins && st < b[:e] }
          found = st
          break
        end
        st += 15
      end
      if found then puts "FREE #{room} #{day} #{hm(found)}-#{hm(found + mins)}"
      else puts "FULL #{room} #{day}"
      end
    end
  else
    err = "unknown command"
  end
  puts "line #{no}: error: #{err}" if err
end
puts "== schedule =="
list = books.values.sort_by { |b| [DAYS.index(b[:day]), b[:room].b, b[:s]] }
if list.empty?
  puts "(none)"
else
  list.each { |b| puts format("%s %-8s %s-%s #%d %s", b[:day], b[:room], hm(b[:s]), hm(b[:e]), b[:id], b[:who]) }
end
puts "== usage =="
use = Hash.new(0)
list.each { |b| use[b[:room]] += b[:e] - b[:s] }
if use.empty?
  puts "(none)"
else
  use.keys.sort_by(&:b).each { |r| puts format("%-8s %dh%02dm", r, use[r] / 60, use[r] % 60) }
end
