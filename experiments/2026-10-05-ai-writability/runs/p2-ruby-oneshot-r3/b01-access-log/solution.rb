stats = {}
hours = Hash.new(0)
invalid = []
valid = 0

$stdin.each_line.with_index(1) do |raw, no|
  line = raw.chomp.delete("\r")
  f = line.split(/ +/).reject(&:empty?)
  next if f.empty?
  reason =
    if f.size != 6 then "wrong field count"
    else
      ts, m, path, st, by, du = f
      if ts !~ /\A(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)\z/ ||
         !($2.to_i.between?(1, 12) && $3.to_i.between?(1, 31) &&
           $4.to_i <= 23 && $5.to_i <= 59 && $6.to_i <= 59)
        "bad timestamp"
      elsif !%w[GET POST PUT DELETE].include?(m) then "bad method"
      elsif !path.start_with?("/") then "bad path"
      elsif st !~ /\A\d{3}\z/ || !st.to_i.between?(100, 599) then "bad status"
      elsif by !~ /\A(\d+|-)\z/ then "bad bytes"
      elsif du !~ /\A\d+\z/ then "bad duration"
      end
    end
  if reason
    invalid << "  line #{no}: #{reason}"
    next
  end
  ts, m, path, st, by, du = f
  key = "#{m} #{path.split("?", 2)[0]}"
  s = (stats[key] ||= { count: 0, n4: 0, n5: 0, bytes: 0, sum: 0, max: 0 })
  s[:count] += 1
  code = st.to_i
  s[:n4] += 1 if code.between?(400, 499)
  s[:n5] += 1 if code.between?(500, 599)
  s[:bytes] += by.to_i unless by == "-"
  d = du.to_i
  s[:sum] += d
  s[:max] = d if d > s[:max]
  hours[ts[0, 13]] += 1
  valid += 1
end

if valid == 0
  puts "no valid requests"
else
  w = [8, stats.keys.map(&:length).max].max
  puts format("%-#{w}s %5s %4s %4s %8s %7s %6s", "endpoint", "count", "4xx", "5xx", "bytes", "avg_ms", "max_ms")
  stats.sort_by { |k, s| [-s[:count], k.b] }.each do |k, s|
    t = (s[:sum] * 20 + s[:count]) / (2 * s[:count])
    avg = "#{t / 10}.#{t % 10}"
    puts format("%-#{w}s %5d %4d %4d %8d %7s %6d", k, s[:count], s[:n4], s[:n5], s[:bytes], avg, s[:max])
  end
  h, n = hours.min_by { |k, c| [-c, k] }
  puts "busiest hour: #{h[0, 10]} #{h[11, 2]}:00 (#{n} requests)"
end
puts "invalid lines: #{invalid.size}"
puts invalid
