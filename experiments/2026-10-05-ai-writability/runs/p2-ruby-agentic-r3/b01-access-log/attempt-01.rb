rows = Hash.new { |h, k| h[k] = [0, 0, 0, 0, 0, 0] } # count n4 n5 bytes sum max
hours = Hash.new(0)
bad = []
$stdin.each_line.with_index(1) do |line, no|
  line = line.chomp.chomp("\r")
  next if line.strip(" ").empty? && line.delete(" ").empty?
  f = line.gsub(/\A +| +\z/, "").split(/ +/)
  r = if f.size != 6 then "wrong field count"
  else
    ts, m, path, st, by, du = f
    if ts !~ /\A\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])T([01]\d|2[0-3]):[0-5]\d:[0-5]\d\z/ then "bad timestamp"
    elsif !%w[GET POST PUT DELETE].include?(m) then "bad method"
    elsif !path.start_with?("/") then "bad path"
    elsif st !~ /\A[1-5]\d\d\z/ then "bad status"
    elsif by !~ /\A(\d+|-)\z/ then "bad bytes"
    elsif du !~ /\A\d+\z/ then "bad duration"
    end
  end
  if r
    bad << [no, r]
    next
  end
  ts, m, path, st, by, du = f
  e = "#{m} #{path.sub(/\?.*/m, '')}"
  x = rows[e]
  x[0] += 1
  x[1] += 1 if st[0] == "4"
  x[2] += 1 if st[0] == "5"
  x[3] += by.to_i unless by == "-"
  d = du.to_i
  x[4] += d
  x[5] = d if d > x[5]
  hours[ts[0, 13]] += 1
end
if rows.empty?
  puts "no valid requests"
else
  w = [8, rows.keys.map(&:size).max].max
  puts format("%-#{w}s %5s %4s %4s %8s %7s %6s", "endpoint", "count", "4xx", "5xx", "bytes", "avg_ms", "max_ms")
  rows.sort_by { |e, x| [-x[0], e.b] }.each do |e, x|
    t = (x[4] * 20 + x[0]) / (2 * x[0])
    avg = "#{t / 10}.#{t % 10}"
    puts format("%-#{w}s %5d %4d %4d %8d %7s %6d", e, x[0], x[1], x[2], x[3], avg, x[5])
  end
  h, n = hours.min_by { |k, v| [-v, k] }
  puts "busiest hour: #{h[0, 10]} #{h[11, 2]}:00 (#{n} requests)"
end
puts "invalid lines: #{bad.size}"
bad.each { |no, r| puts "  line #{no}: #{r}" }
