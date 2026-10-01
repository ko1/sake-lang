require "set"

class Request
  attr_reader :ip, :method, :path, :params, :status, :bytes

  def initialize(ip, method, path, params, status, bytes)
    @ip = ip
    @method = method
    @path = path
    @params = params
    @status = status
    @bytes = bytes
  end
end

class BadLine < StandardError
  attr_reader :line

  def initialize(message, line)
    super(message)
    @line = line
  end
end

def log_lines
  [
    "10.0.0.1 GET /search?q=red%20shoes&page=1 200 5120",
    "10.0.0.2 GET /product/42 200 2048",
    "10.0.0.1 GET /search?q=red%20shoes&page=2 200 4800",
    "10.0.0.3 POST /cart/add?item=42&qty=2 302 0",
    "10.0.0.2 GET /search?q=blue+hat 200 3900",
    "10.0.0.4 GET /product/7 404 512",
    "10.0.0.3 GET /checkout 200 8000",
    "corrupted entry",
    "10.0.0.5 GET /search?q=red%20shoes&sort=price 200 5300",
    "10.0.0.4 GET /product/999 404 512",
    "10.0.0.1 GET /product/42?ref=search 200 2048",
    "10.0.0.6 GET /search?q=caf%C3%A9 200 1500",
    "10.0.0.5 POST /cart/add?item=7&qty=1 500 128",
    "10.0.0.6 GET /search?page=3 200 4000"
  ]
end

def decode(s)
  bytes = s.tr("+", " ").bytes
  out = []
  i = 0
  while i < bytes.size
    b = bytes[i]
    if b == 37 && i + 2 < bytes.size
      out << (bytes[i + 1].chr + bytes[i + 2].chr).hex.chr
      i += 3
    else
      out << b.chr
      i += 1
    end
  end
  out.join
end

def parse_line(line)
  m = line.match(/\A(\S+) (GET|POST) (\S+) (\d{3}) (\d+)\z/)
  raise BadLine.new("cannot parse", line) unless m
  path, _, query = m[3].partition("?")
  params = {}
  unless query.empty?
    query.split("&").each do |pair|
      k, _, v = pair.partition("=")
      params[decode(k)] = decode(v)
    end
  end
  Request.new(m[1], m[2], path, params, m[4].to_i, m[5].to_i)
end

def route(path) = path.gsub(/\/\d+/, "/:id")

requests = []
bad = []
log_lines.each do |line|
  begin
    requests << parse_line(line)
  rescue BadLine => e
    bad << e.line
  end
end
puts "requests: #{requests.size}, unparseable: #{bad.size} #{bad}"

status = Hash.new(0)
requests.each { |r| status[r.status] += 1 }
puts "status: " + status.keys.sort.map { |s| "#{s}x#{status[s]}" }.join(" ")

routes = {}
requests.each do |r|
  key = "#{r.method} #{route(r.path)}"
  stats = routes[key] ||= { hits: [], bytes: [], ips: Set[], params: Set[] }
  stats[:hits] << r.status
  stats[:bytes] << r.bytes
  stats[:ips] << r.ip
  r.params.each_key { |k| stats[:params] << k }
end
puts "routes:"
routes.keys.sort.each do |key|
  routes[key] => { hits:, bytes:, ips:, params: }
  errors = hits.count { |s| s >= 400 }
  puts format("  %-22s hits=%d errors=%d bytes=%6d visitors=%d params=%s",
              key, hits.size, errors, bytes.sum, ips.size, params.sort.join(","))
end

terms = Hash.new(0)
requests.each do |r|
  q = r.params["q"]
  terms[q] += 1 if q
end
puts "search terms:"
ranked = terms.to_a.sort_by { |t, n| [-n, t] }
ranked.each { |t, n| puts "  #{n} #{t}" }

missing = requests.select { |r| r.status == 404 }.map(&:path).uniq
puts "not found: #{missing.join(", ")}"

per_ip = requests.group_by(&:ip)
per_ip.keys.sort.each do |ip|
  rs = per_ip[ip]
  failed = rs.count { |r| r.status >= 400 }
  pages = rs.select { |r| r.params.key?("page") }.map { |r| r.params["page"] }
  extra = pages.empty? ? "" : " pages=#{pages.join(",")}"
  puts format("  %-9s %d req, %d failed%s", ip, rs.size, failed, extra)
end
