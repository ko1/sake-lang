Rate = Struct.new(:first, :step, :cap, :grace)

def money(c) = format("%d.%02d", c / 100, c % 100)

def part_fee(rate, minutes)
  return 0 if minutes == 0
  extra = [minutes - 60, 0].max
  rate.first + (extra + 29) / 30 * rate.step
end

def fee(rate, stay)
  return 0 if stay <= rate.grace
  days, rem = stay.divmod(1440)
  days * rate.cap + [rate.cap, part_fee(rate, rem)].min
end

def parse_event(line)
  f = line.split
  return nil unless f.size == 3
  t, kind, plate = f
  m = /\A(\d\d):(\d\d)\z/.match(t)
  return nil unless m
  h = m[1].to_i
  mi = m[2].to_i
  return nil if h > 23 || mi > 59
  return nil unless kind == "IN" || kind == "OUT"
  return nil unless plate.match?(/\A[A-Z0-9]{1,8}\z/) || (kind == "OUT" && plate.match?(/\A#[1-9]\d*\z/))
  [h * 60 + mi, kind, plate]
end

lines = $stdin.readlines(chomp: true)
_, *nums = lines.first.split
rate = Rate.new(*nums.map(&:to_i))

inside = {}
tickets = {}
next_ticket = 0
revenue = Hash.new(0)
exits = Hash.new(0)
day = 0
prev = 0
lines.each_with_index do |line, i|
  next if i == 0 || line.strip.empty?
  n = i + 1
  ev = parse_event(line)
  unless ev
    puts "line #{n}: invalid"
    next
  end
  t, kind, plate = ev
  day += 1 if t < prev
  prev = t
  now = day * 1440 + t
  if kind == "IN"
    if inside.key?(plate)
      puts "line #{n}: #{plate} already inside"
    else
      next_ticket += 1
      inside[plate] = [now, next_ticket]
      tickets[next_ticket] = plate
    end
  else
    if plate.start_with?("#")
      k = plate[1..].to_i
      pl = tickets[k]
      if pl.nil?
        puts "line #{n}: ticket ##{k} not open"
        next
      end
      plate = pl
    end
    entry = inside.delete(plate)
    if entry.nil?
      puts "line #{n}: #{plate} not inside"
    else
      since = entry[0]
      tickets.delete(entry[1])
      stay = now - since
      f = fee(rate, stay)
      revenue[plate] += f
      exits[plate] += 1
      puts format("%s %d:%02d %s", plate, stay / 60, stay % 60, money(f))
    end
  end
end

puts "--- summary"
exits.keys.sort_by { |pl| [-revenue[pl], pl] }.each do |pl|
  puts "#{pl} #{exits[pl]} #{money(revenue[pl])}"
end
puts "total #{exits.values.sum} #{money(revenue.values.sum)}"
puts "inside: #{inside.empty? ? "none" : inside.keys.sort.join(", ")}"
