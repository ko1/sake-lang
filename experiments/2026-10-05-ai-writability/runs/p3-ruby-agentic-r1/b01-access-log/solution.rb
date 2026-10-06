stats = {}
hours = Hash.new(0)
bad = []
$stdin.each_line.with_index(1) do |line, no|
  line = line.chomp
  next if line.strip.empty?
  f = line.split(" ")
  if f.size != 6
    bad << [no, "wrong field count"]; next
  end
  ts, m, path, st, by, du = f
  m1 = ts.match(/\A(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)\z/)
  ok = m1 && (1..12).cover?(m1[2].to_i) && (1..31).cover?(m1[3].to_i) && m1[4].to_i <= 23 && m1[5].to_i <= 59 && m1[6].to_i <= 59
  reason = if !ok then "bad timestamp"
  elsif !%w[GET POST PUT DELETE].include?(m) then "bad method"
  elsif !path.start_with?("/") then "bad path"
  elsif !(st =~ /\A\d{3}\z/ && (100..599).cover?(st.to_i)) then "bad status"
  elsif !(by == "-" || by =~ /\A\d+\z/) then "bad bytes"
  elsif !(du =~ /\A\d+\z/) then "bad duration"
  end
  if reason
    bad << [no, reason]; next
  end
  ep = "#{m} #{path.sub(/\?.*/m, '')}"
  s = (stats[ep] ||= {count: 0, n4: 0, n5: 0, bytes: 0, sum: 0, max: 0})
  s[:count] += 1
  s[:n4] += 1 if st.start_with?("4")
  s[:n5] += 1 if st.start_with?("5")
  s[:bytes] += by.to_i unless by == "-"
  d = du.to_i
  s[:sum] += d
  s[:max] = d if d > s[:max]
  hours[ts[0, 13]] += 1
end
if stats.empty?
  puts "no valid requests"
else
  w = [stats.keys.map(&:size).max, 8].max
  puts format("%-#{w}s %5s %4s %4s %8s %7s %6s", "endpoint", "count", "4xx", "5xx", "bytes", "avg_ms", "max_ms")
  stats.sort_by { |k, v| [-v[:count], k.b] }.each do |k, v|
    t = (v[:sum] * 20 + v[:count]) / (2 * v[:count])
    avg = "#{t / 10}.#{t % 10}"
    puts format("%-#{w}s %5d %4d %4d %8d %7s %6d", k, v[:count], v[:n4], v[:n5], v[:bytes], avg, v[:max])
  end
  h, n = hours.min_by { |k, v| [-v, k] }
  puts "busiest hour: #{h[0, 10]} #{h[11, 2]}:00 (#{n} requests)"
end
puts "invalid lines: #{bad.size}"
bad.each { |no, r| puts "  line #{no}: #{r}" }
