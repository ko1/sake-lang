METHODS = %w[GET POST PUT DELETE]
stats = {}
hours = Hash.new(0)
invalid = []
total_valid = 0

$stdin.each_line.with_index(1) do |raw, no|
  line = raw.chomp
  next if line.match?(/\A *\z/)
  f = line.split(/ +/).reject(&:empty?)
  reason =
    if f.size != 6 then "wrong field count"
    elsif !(m = f[0].match(/\A(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})\z/)) ||
          !(1..12).cover?(m[2].to_i) || !(1..31).cover?(m[3].to_i) ||
          m[4].to_i > 23 || m[5].to_i > 59 || m[6].to_i > 59
      "bad timestamp"
    elsif !METHODS.include?(f[1]) then "bad method"
    elsif !f[2].start_with?("/") then "bad path"
    elsif !f[3].match?(/\A\d{3}\z/) || !(100..599).cover?(f[3].to_i) then "bad status"
    elsif !(f[4] == "-" || f[4].match?(/\A\d+\z/)) then "bad bytes"
    elsif !f[5].match?(/\A\d+\z/) then "bad duration"
    end
  if reason
    invalid << "  line #{no}: #{reason}"
    next
  end
  total_valid += 1
  ep = "#{f[1]} #{f[2].split("?", 2)[0]}"
  s = (stats[ep] ||= { count: 0, c4: 0, c5: 0, bytes: 0, sum: 0, max: 0 })
  st = f[3].to_i
  d = f[5].to_i
  s[:count] += 1
  s[:c4] += 1 if st >= 400 && st < 500
  s[:c5] += 1 if st >= 500
  s[:bytes] += f[4].to_i unless f[4] == "-"
  s[:sum] += d
  s[:max] = d if d > s[:max]
  hours[f[0][0, 13]] += 1
end

if total_valid > 0
  rows = stats.sort_by { |ep, s| [-s[:count], ep.b] }
  w = [8, rows.map { |ep, _| ep.size }.max].max
  puts format("%-#{w}s %5s %4s %4s %8s %7s %6s", "endpoint", "count", "4xx", "5xx", "bytes", "avg_ms", "max_ms")
  rows.each do |ep, s|
    tenths = (s[:sum] * 20 + s[:count]) / (2 * s[:count])
    avg = "#{tenths / 10}.#{tenths % 10}"
    puts format("%-#{w}s %5d %4d %4d %8d %7s %6d", ep, s[:count], s[:c4], s[:c5], s[:bytes], avg, s[:max])
  end
  best = hours.min_by { |h, c| [-c, h] }
  puts "busiest hour: #{best[0][0, 10]} #{best[0][11, 2]}:00 (#{best[1]} requests)"
else
  puts "no valid requests"
end
puts "invalid lines: #{invalid.size}"
invalid.each { |l| puts l }
