stats = {}
hours = Hash.new(0)
invalid = []
$stdin.each_line.with_index(1) do |raw, n|
  f = raw.chomp.split(" ")
  next if f.empty?
  reason =
    if f.size != 6 then "wrong field count"
    else
      ts, m, path, st, by, du = f
      if ts !~ /\A(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)\z/ ||
         !($2.to_i.between?(1, 12) && $3.to_i.between?(1, 31) && $4.to_i <= 23 && $5.to_i <= 59 && $6.to_i <= 59)
        "bad timestamp"
      elsif !%w[GET POST PUT DELETE].include?(m) then "bad method"
      elsif !path.start_with?("/") then "bad path"
      elsif st !~ /\A\d{3}\z/ || !st.to_i.between?(100, 599) then "bad status"
      elsif by != "-" && by !~ /\A\d+\z/ then "bad bytes"
      elsif du !~ /\A\d+\z/ then "bad duration"
      end
    end
  if reason
    invalid << "  line #{n}: #{reason}"
    next
  end
  ts, m, path, st, by, du = f
  key = "#{m} #{path.sub(/\?.*/m, '')}"
  s = (stats[key] ||= { count: 0, c4: 0, c5: 0, bytes: 0, sum: 0, max: 0 })
  s[:count] += 1
  c = st.to_i
  s[:c4] += 1 if c.between?(400, 499)
  s[:c5] += 1 if c.between?(500, 599)
  s[:bytes] += by.to_i if by != "-"
  d = du.to_i
  s[:sum] += d
  s[:max] = d if d > s[:max]
  hours[ts[0, 13]] += 1
end

if stats.empty?
  puts "no valid requests"
else
  w = [stats.keys.map(&:size).max, 8].max
  puts format("%-*s %5s %4s %4s %8s %7s %6s", w, "endpoint", "count", "4xx", "5xx", "bytes", "avg_ms", "max_ms")
  stats.sort_by { |k, v| [-v[:count], k.b] }.each do |k, v|
    q = (v[:sum] * 20 + v[:count]) / (2 * v[:count])
    avg = "#{q / 10}.#{q % 10}"
    puts format("%-*s %5d %4d %4d %8d %7s %6d", w, k, v[:count], v[:c4], v[:c5], v[:bytes], avg, v[:max])
  end
  best = hours.min_by { |k, c| [-c, k] }
  puts "busiest hour: #{best[0][0, 10]} #{best[0][11, 2]}:00 (#{best[1]} requests)"
end
puts "invalid lines: #{invalid.size}"
invalid.each { |l| puts l }
