class Request
  attr_reader :ip, :hour, :method, :path, :status, :bytes, :ms

  def initialize(ip, hour, method, path, status, bytes, ms)
    @ip = ip
    @hour = hour
    @method = method
    @path = path
    @status = status
    @bytes = bytes
    @ms = ms
  end
end

def log_text
  <<~LOG
    10.0.0.1 - - [12/Mar/2026:09:01:12 +0000] "GET /index.html HTTP/1.1" 200 5120 12ms
    10.0.0.2 - - [12/Mar/2026:09:03:40 +0000] "GET /api/items?page=2 HTTP/1.1" 200 2048 85ms
    10.0.0.3 - - [12/Mar/2026:09:15:02 +0000] "POST /api/login HTTP/1.1" 401 310 40ms
    10.0.0.1 - - [12/Mar/2026:09:47:55 +0000] "GET /api/items HTTP/1.1" 200 4096 92ms
    garbage line without structure
    10.0.0.4 - - [12/Mar/2026:10:02:18 +0000] "GET /static/app.js HTTP/1.1" 304 0 3ms
    10.0.0.2 - - [12/Mar/2026:10:05:31 +0000] "POST /api/orders HTTP/1.1" 201 512 230ms
    10.0.0.5 - - [12/Mar/2026:10:30:09 +0000] "GET /api/items HTTP/1.1" 500 120 1500ms
    10.0.0.3 - - [12/Mar/2026:10:31:44 +0000] "POST /api/login HTTP/1.1" 200 640 55ms
    10.0.0.6 - - [12/Mar/2026:11:12:00 +0000] "GET /missing HTTP/1.1" 404 210 4ms
    10.0.0.1 - - [12/Mar/2026:11:20:16 +0000] "GET /api/items?page=3 HTTP/1.1" 200 1980 77ms
    10.0.0.2 - - [12/Mar/2026:11:22:47 +0000] "DELETE /api/orders/17 HTTP/1.1" 204 0 61ms
    10.0.0.5 - - [12/Mar/2026:11:59:59 +0000] "GET /api/items HTTP/1.1" 503 95 2010ms
    10.0.0.7 - - [12/Mar/2026:12:00:01 +0000] "GET /index.html HTTP/1.1" 200 5120 9ms
    10.0.0.1 - - [12/Mar/2026:12:44:30 +0000] "GET /api/orders/17 HTTP/1.1" 404 180 21ms
  LOG
end

LINE_PATTERN = /\A(\S+) \S+ \S+ \[[^:]+:(\d\d):\d\d:\d\d [^\]]+\] "(\w+) (\S+) [^"]+" (\d{3}) (\d+) (\d+)ms\z/

def parse(text)
  good = []
  bad = 0
  text.each_line do |line|
    m = line.chomp.match(LINE_PATTERN)
    if !m    
      bad += 1
      next
    end
    path = m[4].sub(/\?.*\z/, "")
    good << Request.new(m[1], m[2].to_i, m[3], path, m[5].to_i, m[6].to_i, m[7].to_i)
  end
  [good, bad]
end

def normalize(path) = path.gsub(/\/\d+/, "/:id")

def status_class(code) = "#{code / 100}xx"

def percentile(sorted, pct)
  return nil if sorted.empty?
  idx = (pct / 100.0 * sorted.size).ceil - 1
  sorted.fetch(idx.clamp(0, sorted.size - 1))
end

def human_bytes(n)
  if n >= 1024 * 1024 then format("%.1fM", n / 1048576.0)
  elsif n >= 1024 then format("%.1fK", n / 1024.0)
  else "#{n}B"
  end
end

reqs, bad = parse(log_text)
puts "Parsed #{reqs.size} requests (#{bad} unparseable)"
puts "Total transferred: #{human_bytes(reqs.sum(&:bytes))}"
puts

puts "By status class:"
classes = reqs.map { |r| status_class(r.status) }.tally
classes.keys.sort.each do |c|
  n = classes[c]
  puts format("  %s %3d %5.1f%%", c, n, n * 100.0 / reqs.size)
end
puts

puts "Requests per hour:"
per_hour = reqs.group_by(&:hour)
peak = per_hour.values.map(&:size).max
(9..12).each do |h|
  list = per_hour[h] || []
  bar = "#" * (list.size * 20 / peak)
  errs = list.count { |r| r.status >= 500 }
  puts format("  %02d:00 %-20s %d%s", h, bar, list.size, errs > 0 ? " (#{errs} server errors)" : "")
end
puts

puts "Endpoints:"
puts format("  %-6s %-18s %5s %6s %6s %6s", "method", "path", "hits", "err%", "p50", "p95")
endpoints = reqs.group_by { |r| [r.method, normalize(r.path)] }
rows = endpoints.map do |(meth, path), list|
  lat = list.map(&:ms).sort
  errs = list.count { |r| r.status >= 400 }
  [meth, path, list.size, errs * 100.0 / list.size, percentile(lat, 50), percentile(lat, 95)]
end
rows.sort_by { |m, p, hits, *| [-hits, p, m] }.each do |m, p, hits, e, p50, p95|
  puts format("  %-6s %-18s %5d %5.1f%% %4dms %4dms", m, p, hits, e, p50, p95)
end
puts

slow = reqs.select { |r| r.ms >= 1000 }
puts "Slow requests (>= 1s): #{slow.size}"
slow.each { |r| puts "  #{r.ip} #{r.method} #{r.path} #{r.status} #{r.ms}ms" }
by_ip = reqs.map(&:ip).tally
busiest = by_ip.max_by { |ip, n| n }
if busiest
  ip, n = busiest
  puts "Busiest client: #{ip} (#{n} requests)"
end
