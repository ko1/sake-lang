# Access-log pipeline: regexp parsing with named groups, status classes, hourly unique visitors, error bursts.

class Entry
  attr_reader :ip, :user, :hour, :minute, :method, :path, :status, :bytes

  def initialize(ip, user, hour, minute, method, path, status, bytes)
    @ip = ip
    @user = user
    @hour = hour
    @minute = minute
    @method = method
    @path = path
    @status = status
    @bytes = bytes
  end
end

def log_text
  <<~LOG
    10.0.0.1 - ann [01/Oct/2026:09:01:12] "GET /index.html" 200 5120
    10.0.0.2 - - [01/Oct/2026:09:02:40] "GET /about.html" 200 2048
    10.0.0.1 - ann [01/Oct/2026:09:15:03] "POST /login" 302 0
    10.0.0.3 - bob [01/Oct/2026:09:47:55] "GET /admin" 403 128
    garbage line that does not parse
    10.0.0.4 - - [01/Oct/2026:10:00:01] "GET /missing" 404 64
    10.0.0.4 - - [01/Oct/2026:10:00:02] "GET /missing2" 404 64
    10.0.0.4 - - [01/Oct/2026:10:00:05] "GET /missing3" 404 64
    10.0.0.2 - cy [01/Oct/2026:10:12:30] "GET /index.html" 200 5120
    10.0.0.5 - dee [01/Oct/2026:10:30:00] "GET /api/data" 500 0
    10.0.0.5 - dee [01/Oct/2026:10:30:09] "GET /api/data" 500 0
    10.0.0.1 - ann [01/Oct/2026:11:05:44] "GET /api/data" 200 9000
    10.0.0.6 - - [01/Oct/2026:11:59:59] "HEAD /index.html" 200 0
    10.0.0.3 - bob [01/Oct/2026:11:20:00] "GET /index.html" 304 0
  LOG
end

LINE_RE = /\A(?<ip>\S+) - (?<user>\S+) \[\d+\/\w+\/\d+:(?<h>\d\d):(?<m>\d\d):\d\d\] "(?<method>[A-Z]+) (?<path>\S+)" (?<status>\d{3}) (?<bytes>\d+)\z/

def parse(line)
  m = line.match(LINE_RE)
  return nil unless m
  user = m["user"] == "-" ? nil : m["user"]
  Entry.new(m["ip"], user, m["h"].to_i, m["m"].to_i, m["method"], m["path"], m["status"].to_i, m["bytes"].to_i)
end

def status_class(code)
  case code / 100
  when 2 then :success
  when 3 then :redirect
  when 4 then :client_error
  when 5 then :server_error
  else :unknown
  end
end

lines = log_text.lines
entries = lines.filter_map { |l| parse(l.chomp) }
puts "parsed #{entries.size} entries, rejected #{lines.size - entries.size}"

classes = entries.map { |e| status_class(e.status) }.tally
[:success, :redirect, :client_error, :server_error].each do |k|
  puts format("  %-13s %d", k, classes.fetch(k, 0))
end

puts "== Per hour =="
by_hour = entries.group_by(&:hour)
by_hour.keys.sort.each do |h|
  es = by_hour[h]
  ips = es.map(&:ip).to_set
  users = es.map(&:user).compact.to_set
  bytes = es.sum(&:bytes)
  puts format("  %02d:00 requests=%d ips=%d users=%s bytes=%d", h, es.size, ips.size, users.empty? ? "-" : users.sort.join(","), bytes)
end

puts "== Top paths =="
paths = entries.map(&:path).tally
paths.sort_by { |p, n| [-n, p] }.take(3).each { |p, n| puts "  #{n} #{p}" }

puts "== Error bursts =="
errors = entries.select { |e| e.status >= 400 }
bursts = errors.chunk_while do |a, b|
  a.ip == b.ip && a.hour * 60 + a.minute + 1 >= b.hour * 60 + b.minute
end
bursts.each do |run|
  next if run.size < 2
  puts "  #{run.first.ip} x#{run.size} status #{run.map(&:status).uniq.join("/")}"
end

anon_ips = entries.select { |e| e.user.nil? }.map(&:ip).to_set
auth_ips = entries.reject { |e| e.user.nil? }.map(&:ip).to_set
puts "ips seen both anonymous and logged in: #{(anon_ips & auth_ips).sort.join(", ")}"
puts "anonymous only: #{(anon_ips - auth_ips).sort.join(", ")}"
puts "methods: #{entries.map(&:method).uniq.join(" ")}"
big = entries.max_by(&:bytes)
puts "largest response: #{big.path} (#{big.bytes} bytes, user #{big.user || "anonymous"})"
