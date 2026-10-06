stats = {}
hours = Hash.new(0)
invalid = []
$stdin.each_line.with_index(1) do |raw, no|
  line = raw.chomp
  next if line.strip.empty? && line.delete(" ").empty?
  f = line.split(" ")
  reason =
    if f.size != 6 then "wrong field count"
    else
      ts, m, path, st, by, du = f
      if ts !~ /\A\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])T([01]\d|2[0-3]):[0-5]\d:[0-5]\d\z/ then "bad timestamp"
      elsif !%w[GET POST PUT DELETE].include?(m) then "bad method"
      elsif !path.start_with?("/") then "bad path"
      elsif st !~ /\A\d{3}\z/ || !(100..599).cover?(st.to_i) then "bad status"
      elsif by != "-" && by !~ /\A\d+\z/ then "bad bytes"
      elsif du !~ /\A\d+\z/ then "bad duration"
      end
    end
  if reason
    invalid << "  line #{no}: #{reason}"
    next
  end
  ts, m, path, st, by, du = f
  key = "#{m} #{path.split("?", 2)[0]}"
  s = (stats[key] ||= {count: 0, c4: 0, c5: 0, bytes: 0, sum: 0, max: 0})
  s[:count] += 1
  s[:c4] += 1 if st.to_i / 100 == 4
  s[:c5] += 1 if st.to_i / 100 == 5
  s[:bytes] += by.to_i if by != "-"
  s[:sum] += du.to_i
  s[:max] = [s[:max], du.to_i].max
  hours[ts[0, 13]] += 1
end
unless stats.empty?
  w = [stats.keys.map(&:size).max, 8].max
  puts format("%-#{w}s %5s %4s %4s %8s %7s %6s", "endpoint", "count", "4xx", "5xx", "bytes", "avg_ms", "max_ms")
  stats.sort_by { |k, s| [-s[:count], k.b] }.each do |k, s|
    t = (s[:sum] * 20 + s[:count]) / (2 * s[:count])
    avg = "#{t / 10}.#{t % 10}"
    puts format("%-#{w}s %5d %4d %4d %8d %7s %6d", k, s[:count], s[:c4], s[:c5], s[:bytes], avg, s[:max])
  end
  h, n = hours.min_by { |k, v| [-v, k] }
  puts "busiest hour: #{h[0, 10]} #{h[11, 2]}:00 (#{n} requests)"
else
  puts "no valid requests"
end
puts "invalid lines: #{invalid.size}"
puts invalid
