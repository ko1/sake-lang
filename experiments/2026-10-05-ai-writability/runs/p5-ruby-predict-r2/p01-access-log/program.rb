METHODS = %w[GET POST PUT DELETE].freeze

Stat = Struct.new(:count, :c4, :c5, :bytes, :ms_total, :ms_max)

def check(fields)
  return "wrong field count" unless fields.size == 6
  ts, meth, path, status, bytes, ms = fields
  m = ts.match(/\A(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})\z/)
  return "bad timestamp" unless m && (1..12).cover?(m[2].to_i) && (1..31).cover?(m[3].to_i) &&
                                m[4].to_i <= 23 && m[5].to_i <= 59 && m[6].to_i <= 59
  return "bad method" unless METHODS.include?(meth)
  return "bad path" unless path.start_with?("/")
  return "bad status" unless status.match?(/\A\d{3}\z/) && (100..599).cover?(status.to_i)
  return "bad bytes" unless bytes == "-" || bytes.match?(/\A\d+\z/)
  return "bad duration" unless ms.match?(/\A\d+\z/)
  nil
end

stats = {}
hours = Hash.new(0)
invalid = []
$stdin.each_line.with_index(1) do |raw, lineno|
  line = raw.chomp
  next if line.strip.empty?
  fields = line.split(" ")
  if (reason = check(fields))
    invalid << [lineno, reason]
    next
  end
  ts, meth, path, status, bytes, ms = fields
  key = "#{meth} #{path.split("?", 2)[0]}"
  st = (stats[key] ||= Stat.new(0, 0, 0, 0, 0, 0))
  st.count += 1
  code = status.to_i
  st.c4 += 1 if code >= 400 && code <= 499
  st.c5 += 1 if code >= 500
  st.bytes += bytes.to_i unless bytes == "-"
  st.ms_total += ms.to_i
  st.ms_max = ms.to_i if ms.to_i > st.ms_max
  hours[ts[0, 13]] += 1
end

if stats.empty?
  puts "no valid requests"
else
  w = [8, *stats.keys.map(&:size)].max
  puts format("%-#{w}s %5s %4s %4s %8s %7s %6s", "endpoint", "count", "4xx", "5xx", "bytes", "avg_ms", "max_ms")
  stats.sort_by { |k, s| [-s.count, k] }.each do |k, s|
    tenths = (s.ms_total * 20 + s.count) / (s.count * 2)
    avg = "#{tenths / 10}.#{tenths % 10}"
    puts format("%-#{w}s %5d %4d %4d %8d %7s %6d", k, s.count, s.c4, s.c5, s.bytes, avg, s.ms_max)
  end
  hour, n = hours.min_by { |h, c| [-c, h] }
  puts "busiest hour: #{hour[0, 10]} #{hour[11, 2]}:00 (#{n} requests)"
end
puts "invalid lines: #{invalid.size}"
invalid.each { |lineno, reason| puts "  line #{lineno}: #{reason}" }
