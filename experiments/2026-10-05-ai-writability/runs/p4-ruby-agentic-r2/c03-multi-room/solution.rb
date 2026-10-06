DAYS = %w[Mon Tue Wed Thu Fri Sat Sun].freeze
OPEN = 8 * 60
CLOSE = 20 * 60

Booking = Struct.new(:id, :rooms, :label, :day, :start, :stop, :who)

class InputError < StandardError; end

def hhmm(m) = format("%02d:%02d", m / 60, m % 60)

def parse_time(s)
  m = s.match(/\A(\d\d):(\d\d)\z/) or raise InputError, "bad time"
  t = m[1].to_i * 60 + m[2].to_i
  raise InputError, "bad time" unless m[2].to_i < 60 && t % 15 == 0 && t.between?(OPEN, CLOSE)
  t
end

def check_room(s) = s.match?(/\A[A-Z0-9]{1,8}\z/) ? s : raise(InputError, "bad room")
def check_day(s) = DAYS.include?(s) ? s : raise(InputError, "bad day")

bookings = []
next_id = 1
$stdin.each_line.with_index(1) do |raw, lineno|
  f = raw.split
  next if f.empty?
  begin
    case f[0]
    when "BOOK"
      raise InputError, "wrong field count" unless f.size == 5
      rooms = f[1].split("+", -1)
      raise InputError, "bad room" unless rooms.size.between?(1, 4) && rooms.uniq.size == rooms.size
      rooms.each { |r| check_room(r) }
      day = check_day(f[2])
      a, b = f[3].split("-", 2)
      raise InputError, "bad time" unless b
      start = parse_time(a)
      stop = parse_time(b)
      raise InputError, "bad time" unless start < stop
      who = f[4]
      raise InputError, "bad name" unless who.match?(/\A[a-z]{1,12}\z/)
      clash = nil
      room = nil
      rooms.each do |r|
        clash = bookings.select { |k| k.rooms.include?(r) && k.day == day && k.start < stop && start < k.stop }.min_by(&:start)
        if clash
          room = r
          break
        end
      end
      if clash
        puts "CONFLICT #{room} #{day} with ##{clash.id} (#{clash.who} #{hhmm(clash.start)}-#{hhmm(clash.stop)})"
      elsif bookings.count { |k| k.who == who && k.day == day } >= 3
        puts "LIMIT #{who} #{day}"
      else
        bookings << Booking.new(next_id, rooms, f[1], day, start, stop, who)
        puts "OK ##{next_id} #{f[1]} #{day} #{hhmm(start)}-#{hhmm(stop)} #{who}"
        next_id += 1
      end
    when "CANCEL"
      raise InputError, "wrong field count" unless f.size == 2
      raise InputError, "bad id" unless f[1].match?(/\A\d+\z/)
      id = f[1].to_i
      k = bookings.find { |x| x.id == id }
      if k
        bookings.delete(k)
        puts "CANCELLED ##{id}"
      else
        puts "NO BOOKING ##{id}"
      end
    when "FREE"
      raise InputError, "wrong field count" unless f.size == 4
      room = check_room(f[1])
      day = check_day(f[2])
      raise InputError, "bad duration" unless f[3].match?(/\A\d+\z/) && f[3].to_i > 0 && f[3].to_i % 15 == 0
      len = f[3].to_i
      busy = bookings.select { |k| k.rooms.include?(room) && k.day == day }.sort_by(&:start)
      t = OPEN
      busy.each do |k|
        break if k.start - t >= len
        t = k.stop if k.stop > t
      end
      if t + len <= CLOSE
        puts "FREE #{room} #{day} #{hhmm(t)}-#{hhmm(t + len)}"
      else
        puts "FULL #{room} #{day}"
      end
    else
      raise InputError, "unknown command"
    end
  rescue InputError => e
    puts "line #{lineno}: error: #{e.message}"
  end
end

puts "== schedule =="
puts "(none)" if bookings.empty?
per_room = bookings.flat_map { |k| k.rooms.map { |r| [r, k] } }
per_room.sort_by { |r, k| [DAYS.index(k.day), r, k.start, k.id] }.each do |r, k|
  puts format("%s %-8s %s-%s #%d %s", k.day, r, hhmm(k.start), hhmm(k.stop), k.id, k.who)
end
puts "== usage =="
puts "(none)" if bookings.empty?
per_room.group_by { |r, _| r }.sort.each do |room, pairs|
  total = pairs.sum { |_, k| k.stop - k.start }
  puts format("%-8s %dh%02dm", room, total / 60, total % 60)
end
