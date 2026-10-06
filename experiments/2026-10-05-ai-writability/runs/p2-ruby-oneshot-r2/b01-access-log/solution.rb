stats = {}
hours = Hash.new(0)
invalid = []
valid = 0

$stdin.each_line.with_index(1) do |raw, no|
  line = raw.chomp
  next if line.strip.empty?
  f = line.split(" ")
  reason =
    if f.size != 6 then "wrong field count"
    elsif !(f[0] =~ /\A(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)\z/ &&
            (1..12).cover?($2.to_i) && (1..31).cover?($3.to_i) &&
            $4.to_i <= 23 && $5.to_i <= 59 && $6.to_i <= 59) then "bad timestamp"
    elsif !%w[GET POST PUT DELETE].include?(f[1]) then "bad method"
    elsif !f[2].start_with?("/") then "bad path"
    elsif !(f[3] =~ /\A\d{3}\z/ && (100..599).cover?(f[3].to_i)) then "bad status"
    elsif !(f[4] == "-" || f[4] =~ /\A\d+\z/) then "bad bytes"
    elsif !(f[5] =~ /\A\d+\z/) then "bad duration"
    end
  if reason
    invalid << "  line #{no}: #{reason}"
    next
  end
  valid += 1
  ep = "#{f[1]} #{f[2].split("?", 2)[0]}"
  s = (stats[ep] ||= { count: 0, c4: 0, c5: 0, bytes: 0, sum: 0, max: 0 })
  st = f[3].to_i
  s[:count] += 1
  s[:c4] += 1 if st >= 400 && st < 500
  s[:c5] += 1 if st >= 500
  s[:bytes] += f[4].to_i unless f[4] == "-"
  d = f[5].to_i
  s[:sum] += d
  s[:max] = d if d > s[:max]
  hours[f[0][0, 13].sub("T", " ")] += 1
end

if valid > 0
  rows = stats.sort_by { |ep, s| [-s[:count], ep.b] }
  w = [rows.map { |ep, _| ep.size }.max, 8].max
  puts format("%-#{w}s %5s %4s %4s %8s %7s %6s", "endpoint", "count", "4xx", "5xx", "bytes", "avg_ms", "max_ms")
  rows.each do |ep, s|
    t = (s[:sum] * 20 + s[:count]) / (2 * s[:count])
    avg = "#{t / 10}.#{t % 10}"
    puts format("%-#{w}s %5d %4d %4d %8d %7s %6d", ep, s[:count], s[:c4], s[:c5], s[:bytes], avg, s[:max])
  end
  best = hours.min_by { |h, n| [-n, h] }
  puts "busiest hour: #{best[0]}:00 (#{best[1]} requests)"
else
  puts "no valid requests"
end
puts "invalid lines: #{invalid.size}"
invalid.each { |l| puts l }
