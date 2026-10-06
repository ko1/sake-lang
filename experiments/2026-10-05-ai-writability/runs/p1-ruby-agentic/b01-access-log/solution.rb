Stat = Struct.new(:count, :n4, :n5, :bytes, :dsum, :dmax)
stats = {}
hours = Hash.new(0)
invalid = []
$stdin.each_line.with_index(1) do |raw, no|
  line = raw.chomp.delete_suffix("\r")
  f = line.split(/ +/).reject(&:empty?)
  next if f.empty?
  reason =
    if f.size != 6 then "wrong field count"
    elsif f[0] !~ /\A\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])T([01]\d|2[0-3]):[0-5]\d:[0-5]\d\z/ then "bad timestamp"
    elsif !%w[GET POST PUT DELETE].include?(f[1]) then "bad method"
    elsif !f[2].start_with?("/") then "bad path"
    elsif f[3] !~ /\A[1-5]\d\d\z/ then "bad status"
    elsif f[4] != "-" && f[4] !~ /\A\d+\z/ then "bad bytes"
    elsif f[5] !~ /\A\d+\z/ then "bad duration"
    end
  if reason
    invalid << "  line #{no}: #{reason}"
    next
  end
  ep = "#{f[1]} #{f[2].split("?", 2)[0]}"
  s = (stats[ep] ||= Stat.new(0, 0, 0, 0, 0, 0))
  st = f[3].to_i
  d = f[5].to_i
  s.count += 1
  s.n4 += 1 if st / 100 == 4
  s.n5 += 1 if st / 100 == 5
  s.bytes += f[4].to_i if f[4] != "-"
  s.dsum += d
  s.dmax = d if d > s.dmax
  hours[f[0][0, 13]] += 1
end

unless stats.empty?
  w = [stats.keys.map(&:size).max, 8].max
  puts format("%-#{w}s %5s %4s %4s %8s %7s %6s", "endpoint", "count", "4xx", "5xx", "bytes", "avg_ms", "max_ms")
  stats.sort_by { |k, s| [-s.count, k.b] }.each do |k, s|
    t = (s.dsum * 20 + s.count) / (2 * s.count)
    avg = "#{t / 10}.#{t % 10}"
    puts format("%-#{w}s %5d %4d %4d %8d %7s %6d", k, s.count, s.n4, s.n5, s.bytes, avg, s.dmax)
  end
  h, n = hours.min_by { |k, v| [-v, k] }
  puts "busiest hour: #{h[0, 10]} #{h[11, 2]}:00 (#{n} requests)"
else
  puts "no valid requests"
end
puts "invalid lines: #{invalid.size}"
puts invalid
