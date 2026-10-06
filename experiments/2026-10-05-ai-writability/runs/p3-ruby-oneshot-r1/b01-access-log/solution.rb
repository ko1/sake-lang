stats = {}
hours = Hash.new(0)
invalid = []
$stdin.each_line.with_index(1) do |raw, no|
  line = raw.chomp.delete("\r")
  f = line.split(" ")
  next if f.empty?
  reason =
    if f.size != 6 then "wrong field count"
    elsif !(m = f[0].match(/\A(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)\z/)) ||
          !(1..12).cover?(m[2].to_i) || !(1..31).cover?(m[3].to_i) ||
          m[4].to_i > 23 || m[5].to_i > 59 || m[6].to_i > 59 then "bad timestamp"
    elsif !%w[GET POST PUT DELETE].include?(f[1]) then "bad method"
    elsif !f[2].start_with?("/") then "bad path"
    elsif !(f[3].match?(/\A\d{3}\z/) && (100..599).cover?(f[3].to_i)) then "bad status"
    elsif !(f[4] == "-" || f[4].match?(/\A\d+\z/)) then "bad bytes"
    elsif !f[5].match?(/\A\d+\z/) then "bad duration"
    end
  if reason
    invalid << "  line #{no}: #{reason}"
    next
  end
  path = f[2].split("?", 2)[0]
  key = "#{f[1]} #{path}"
  s = (stats[key] ||= { count: 0, c4: 0, c5: 0, bytes: 0, dur: 0, max: 0 })
  st = f[3].to_i
  s[:count] += 1
  s[:c4] += 1 if st >= 400 && st < 500
  s[:c5] += 1 if st >= 500
  s[:bytes] += f[4].to_i unless f[4] == "-"
  d = f[5].to_i
  s[:dur] += d
  s[:max] = d if d > s[:max]
  hours["#{m[1]}-#{m[2]}-#{m[3]} #{m[4]}:00"] += 1
end
if stats.empty?
  puts "no valid requests"
else
  w = [stats.keys.map(&:size).max, 8].max
  puts format("%-#{w}s %5s %4s %4s %8s %7s %6s", "endpoint", "count", "4xx", "5xx", "bytes", "avg_ms", "max_ms")
  rows = stats.sort_by { |k, s| [-s[:count], k.b] }
  rows.each do |k, s|
    t = (20 * s[:dur] + s[:count]) / (2 * s[:count])
    avg = "#{t / 10}.#{t % 10}"
    puts format("%-#{w}s %5d %4d %4d %8d %7s %6d", k, s[:count], s[:c4], s[:c5], s[:bytes], avg, s[:max])
  end
  best = hours.min_by { |k, v| [-v, k] }
  puts "busiest hour: #{best[0]} (#{best[1]} requests)"
end
puts "invalid lines: #{invalid.size}"
puts invalid
