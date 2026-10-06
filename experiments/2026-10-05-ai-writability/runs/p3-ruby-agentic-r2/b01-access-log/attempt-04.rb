stats = {}
hours = Hash.new(0)
bad = []
$stdin.each_line.with_index(1) do |raw, no|
  line = raw.chomp
  next if line.strip.empty?
  f = line.split(/ +/).reject(&:empty?)
  reason =
    if f.size != 6 then "wrong field count"
    elsif !(f[0] =~ /\A(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)\z/ && (1..12).cover?($2.to_i) && (1..31).cover?($3.to_i) && $4.to_i <= 23 && $5.to_i <= 59 && $6.to_i <= 59) then "bad timestamp"
    elsif !%w[GET POST PUT DELETE].include?(f[1]) then "bad method"
    elsif !f[2].start_with?("/") then "bad path"
    elsif !(f[3] =~ /\A\d{3}\z/ && (100..599).cover?(f[3].to_i)) then "bad status"
    elsif !(f[4] =~ /\A\d+\z/ || f[4] == "-") then "bad bytes"
    elsif !(f[5] =~ /\A\d+\z/) then "bad duration"
    end
  if reason
    bad << "  line #{no}: #{reason}"
    next
  end
  key = "#{f[1]} #{f[2].split("?", 2)[0]}"
  s = (stats[key] ||= {c: 0, x4: 0, x5: 0, b: 0, d: 0, m: 0})
  st = f[3].to_i
  s[:c] += 1
  s[:x4] += 1 if st >= 400 && st < 500
  s[:x5] += 1 if st >= 500
  s[:b] += f[4].to_i if f[4] != "-"
  d = f[5].to_i
  s[:d] += d
  s[:m] = d if d > s[:m]
  hours[f[0][0, 13]] += 1
end
unless stats.empty?
  w = [8, stats.keys.map(&:size).max].max
  puts format("%-#{w}s %5s %4s %4s %8s %7s %6s", "endpoint", "count", "4xx", "5xx", "bytes", "avg_ms", "max_ms")
  stats.sort_by { |k, s| [-s[:c], k.b] }.each do |k, s|
    t = (s[:d] * 20 + s[:c]) / (2 * s[:c])
    avg = "#{t / 10}.#{t % 10}"
    puts format("%-#{w}s %5d %4d %4d %8d %7s %6d", k, s[:c], s[:x4], s[:x5], s[:b], avg, s[:m])
  end
  h, n = hours.min_by { |k, v| [-v, k] }
  puts "busiest hour: #{h[0, 10]} #{h[11, 2]}:00 (#{n} requests)"
else
  puts "no valid requests"
end
puts "invalid lines: #{bad.size}"
puts bad
