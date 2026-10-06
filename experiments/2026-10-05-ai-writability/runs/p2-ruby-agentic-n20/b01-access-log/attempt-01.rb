stats = {}
hours = Hash.new(0)
invalid = []
$stdin.each_line.with_index(1) do |line, no|
  f = line.chomp.split(/ +/).reject(&:empty?)
  next if f.empty?
  reason =
    if f.size != 6 then "wrong field count"
    elsif !(f[0] =~ /\A(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)\z/ &&
            (1..12).cover?($2.to_i) && (1..31).cover?($3.to_i) && $4.to_i <= 23 && $5.to_i <= 59 && $6.to_i <= 59) then "bad timestamp"
    elsif !%w[GET POST PUT DELETE].include?(f[1]) then "bad method"
    elsif f[2][0] != "/" then "bad path"
    elsif !(f[3] =~ /\A\d{3}\z/ && (100..599).cover?(f[3].to_i)) then "bad status"
    elsif !(f[4] == "-" || f[4] =~ /\A\d+\z/) then "bad bytes"
    elsif f[5] !~ /\A\d+\z/ then "bad duration"
    end
  if reason
    invalid << "  line #{no}: #{reason}"
    next
  end
  path = f[2].split("?", 2)[0]
  e = (stats["#{f[1]} #{path}"] ||= [0, 0, 0, 0, 0, 0])
  st = f[3].to_i
  d = f[5].to_i
  e[0] += 1
  e[1] += 1 if st >= 400 && st < 500
  e[2] += 1 if st >= 500
  e[3] += f[4].to_i if f[4] != "-"
  e[4] += d
  e[5] = d if d > e[5]
  hours[f[0][0, 13]] += 1
end
if stats.empty?
  puts "no valid requests"
else
  w = [stats.keys.map(&:size).max, 8].max
  puts format("%-#{w}s %5s %4s %4s %8s %7s %6s", "endpoint", "count", "4xx", "5xx", "bytes", "avg_ms", "max_ms")
  stats.sort_by { |k, v| [-v[0], k.b] }.each do |k, v|
    t = (v[4] * 20 + v[0]) / (2 * v[0])
    avg = "#{t / 10}.#{t % 10}"
    puts format("%-#{w}s %5d %4d %4d %8d %7s %6d", k, v[0], v[1], v[2], v[3], avg, v[5])
  end
  best = hours.min_by { |k, v| [-v, k] }
  puts "busiest hour: #{best[0][0, 10]} #{best[0][11, 2]}:00 (#{best[1]} requests)"
end
puts "invalid lines: #{invalid.size}"
puts invalid
