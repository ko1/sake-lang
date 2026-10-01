class BitNode
  attr_accessor :zero, :one, :route

  def initialize
    @zero = nil
    @one = nil
    @route = nil
  end
end

class Route
  attr_reader :prefix, :len, :iface, :metric

  def initialize(prefix, len, iface, metric)
    @prefix = prefix
    @len = len
    @iface = iface
    @metric = metric
  end

  def to_s = "#{ip_to_s(prefix)}/#{len} via #{iface} (metric #{metric})"
end

class BadAddress < StandardError
  attr_reader :text

  def initialize(message, text)
    super(message)
    @text = text
  end
end

def parse_ip(text)
  parts = text.split(".")
  raise BadAddress.new("bad address #{text}", text) if parts.size != 4
  parts.reduce(0) do |acc, p|
    raise BadAddress.new("bad octet #{p} in #{text}", text) unless p.match?(/\A\d{1,3}\z/) && p.to_i <= 255
    (acc << 8) | p.to_i
  end
end

def ip_to_s(n) = [24, 16, 8, 0].map { |s| (n >> s) & 255 }.join(".")

def bit(addr, i) = (addr >> (31 - i)) & 1

def mask(len) = len == 0 ? 0 : ((1 << len) - 1) << (32 - len)

class RouteTable
  attr_reader :root, :size

  def initialize
    @root = BitNode.new
    @size = 0
  end

  def add(cidr, iface, metric)
    addr, len = cidr.split("/")
    len = len.to_i
    raise BadAddress.new("bad prefix length in #{cidr}", cidr) if len > 32
    prefix = parse_ip(addr) & mask(len)
    node = root
    len.times do |i|
      node = if bit(prefix, i) == 0
               node.zero ||= BitNode.new
             else
               node.one ||= BitNode.new
             end
    end
    old = node.route
    return unless old.nil? || old.metric > metric
    @size += 1 if old.nil?
    node.route = Route.new(prefix, len, iface, metric)
  end

  def lookup(text)
    addr = parse_ip(text)
    node = root
    best = node.route
    depth = 0
    while node && depth < 32
      node = bit(addr, depth) == 0 ? node.zero : node.one
      depth += 1
      best = node.route if node&.route
    end
    best
  end

  def remove(cidr)
    addr, len = cidr.split("/")
    len = len.to_i
    prefix = parse_ip(addr) & mask(len)
    node = root
    len.times do |i|
      node = bit(prefix, i) == 0 ? node.zero : node.one
      return false if node.nil?
    end
    return false if node.route.nil?
    node.route = nil
    @size -= 1
    true
  end

  def each_route(&block) = walk(root, &block)

  def node_count = count(root)

  private

  def walk(node, &block)
    return if node.nil?
    yield node.route if node.route
    walk(node.zero, &block)
    walk(node.one, &block)
  end

  def count(node) = node.nil? ? 0 : 1 + count(node.zero) + count(node.one)
end

table = RouteTable.new
routes = <<~T
  0.0.0.0/0 wan0 100
  10.0.0.0/8 vpn0 10
  10.20.0.0/16 lan1 5
  10.20.30.0/24 lab0 1
  10.20.30.128/25 lab1 1
  192.168.1.0/24 lan0 1
  192.168.1.77/32 printer 1
  172.16.0.0/12 dmz0 20
  10.20.0.0/16 backup 50
  172.16.5.9/33 typo 1
  300.1.1.0/24 typo 1
T
routes.each_line do |line|
  cidr, iface, metric = line.split(" ")
  begin
    table.add(cidr, iface, metric.to_i)
  rescue BadAddress => e
    puts "skip: #{e.message}"
  end
end
puts "#{table.size} routes, #{table.node_count} trie nodes"
table.each_route { |r| puts "  #{r}" }

puts "-- lookups --"
%w[10.20.30.200 10.20.30.5 10.20.99.1 10.1.2.3 192.168.1.77 192.168.1.78 172.31.255.255 8.8.8.8 10.20.30].each do |ip|
  r = table.lookup(ip)
  puts format("  %-15s -> %-8s (%s/%d)", ip, r.iface, ip_to_s(r.prefix), r.len)
rescue BadAddress => e
  puts "  #{ip}: #{e.message}"
end

puts "-- withdraw 10.20.30.0/24 and 0.0.0.0/0 --"
%w[10.20.30.0/24 0.0.0.0/0 10.99.0.0/16].each { |c| puts "  remove #{c}: #{table.remove(c)}" }
%w[10.20.30.5 8.8.8.8].each do |ip|
  r = table.lookup(ip)
  puts "  #{ip} -> #{r.nil? ? "unreachable" : r.iface}"
end
puts "#{table.size} routes left"
