stats = {}
hours = Hash.new(0)
invalid = []
$stdin.each_line.with_index(1) do |raw, no|
  line = raw.chomp
  f = line.split(/ +/).reject(&:empty?)
  next if f.empty?
  reason =
    if f.size != 6 then "wrong field count"
    else
      ts, m, path, st, by, du = f
      if !(ts =~ /\A(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)\z/ &&
           (1..12).cover?($2.to_i) && (1..31).cover?($3.to_i) && $4.to_i <= 23 && $5.to_i <= 59 && $6.to_i <= 59)
        "bad timestamp"
      elsif !%w[GET POST PUT DELETE].include?(m) then "bad method"
      elsif !path.start_with?("/") then "bad path"
      elsif !(st =~ /\A\d{3}\z/ && (100..599).cover?(st.to_i)) then "bad status"
      elsif !(by == "-" || by =~ /\A\d+\z/) then "bad bytes"
      elsif !(du =~ /\A\d+\z/) then "bad duration"
      end
    end
  if reason
    invalid << "  line #{no}: #{reason}"
    next
  end
  ts, m, path, st, by, du = f
  ep = "#{m} #{path.split("?", 2)[0]}"
  s = (stats[ep] ||= {count: 0, c4: 0, c5: 0, bytes: 0, sum: 0, max: 0})
  s[:count] += 1
  code = st.to_i
  s[:c4] += 1 if code >= 400 && code < 500
  s[:c5] += 1 if code >= 500
  s[:bytes] += by.to_i unless by == "-"
  d = du.to_i
  s[:sum] += d
  s[:max] = d if d > s[:max]
  hours[ts[0, 13]] += 1
end

if stats.empty?
  puts "no valid requests"
else
  w = [stats.keys.map(&:length).max, 8].max
  puts format("%-#{w}s %5s %4s %4s %8s %7s %6s", "endpoint", "count", "4xx", "5xx", "bytes", "avg_ms", "max_ms")
  rows = stats.sort_by { |ep, s| [-s[:count], ep.b] }
  rows.each do |ep, s|
    t = (20 * s[:sum] + s[:count]) / (2 * s[:count])
    avg = "#{t / 10}.#{t % 10}"
    puts format("%-#{w}s %5d %4d %4d %8d %7s %6d", ep, s[:count], s[:c4], s[:c5], s[:bytes], avg, s[:max])
  end
  best = hours.min_by { |h, c| [-c, h] }
  puts "busiest hour: #{best[0][0, 10]} #{best[0][11, 2]}:00 (#{best[1]} requests)"
end
puts "invalid lines: #{invalid.size}"
invalid.each { |l| puts l }
