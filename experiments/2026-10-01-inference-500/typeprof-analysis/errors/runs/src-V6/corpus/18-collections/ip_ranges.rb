# GeoIP-style lookup: CIDR blocks become Integer Ranges; lookups use bsearch; overlaps and coverage.

class Block
  attr_reader :cidr, :range, :label

  def initialize(cidr, range, label)
    @cidr = cidr
    @range = range
    @label = label
  end
end

class InvalidAddress < StandardError
  attr_reader :text

  def initialize(message, text)
    super(message)
    @text = text
  end
end

def parse_ip(s)
  parts = s.split(".")
  raise InvalidAddress.new("expected 4 octets", s) unless parts.size == 4
  parts.reduce(0) do |acc, part|
    raise InvalidAddress.new("bad octet #{part}", s) unless part.match?(/\A\d{1,3}\z/)
    n = part.to_i
    raise InvalidAddress.new("octet out of range #{n}", s) unless (0..255).cover?(n)
    (acc << 8) | n
  end
end

def ip_to_s(n) = [24, 16, 8, 0].map { |sh| (n >> sh) & 255 }.join(".")

def parse_cidr(text, label)
  addr, bits = text.split("/")
  bits = bits.to_i
  base = parse_ip(addr)
  size = 1 << (32 - bits)
  start = base & (0xFFFFFFFF ^ (size - 1))
  Block.new(text, start..(start + size - 1), label)
end

def table
  rows = [
    ["10.0.0.0/8", "private"], ["192.168.0.0/16", "private"], ["203.0.113.0/24", "docs-net"],
    ["198.51.100.0/25", "docs-a"], ["198.51.100.128/25", "docs-b"], ["8.8.8.0/24", "dns"],
    ["100.64.0.0/10", "cgnat"], ["192.168.10.0/24", "lab"]
  ]
  rows.map { |c, l| parse_cidr(c, l) }.sort_by { |b| b.range.begin }
end

def lookup(blocks, ip)
  idx = (0...blocks.size).to_a.bsearch { |i| blocks[i].range.end >= ip }
  matches = blocks.select { |b| b.range.cover?(ip) }
  return nil if matches.empty?
  [matches.min_by { |b| b.range.size }, idx]
end

blocks = table
puts "blocks:"
blocks.each do |b|
  r = b.range
  puts format("  %-18s %-15s - %-15s %8d  %s", b.cidr, ip_to_s(r.begin), ip_to_s(r.end), r.size, b.label)
end

puts "lookups:"
["10.1.2.3", "192.168.10.77", "192.168.3.4", "198.51.100.200", "8.8.4.4", "100.127.255.255", "300.1.1.1", "1.2.3"].each do |text|
  ip = parse_ip(text)
  found = lookup(blocks, ip)
  if found
    b, _idx = found
    puts format("  %-16s %-8s (%s)", text, b.label, b.cidr)
  else
    puts format("  %-16s unknown", text)
  end
rescue InvalidAddress => e
  puts format("  %-16s invalid: %s", e.text, e.message)
end

puts "nested or overlapping:"
blocks.combination(2).each do |x, y|
  a = x.range
  b = y.range
  next unless a.overlap?(b)
  kind = a.cover?(b.begin) && a.cover?(b.end) ? "contains" : "overlaps"
  puts "  #{x.cidr} #{kind} #{y.cidr}"
end

adjacent = blocks.combination(2).select { |x, y| x.range.end + 1 == y.range.begin }
adjacent.each { |x, y| puts "adjacent: #{x.cidr} + #{y.cidr}" }

by_label = blocks.group_by(&:label).transform_values { |bs| bs.sum { |b| b.range.size } }
total = by_label.values.sum
puts "address share:"
by_label.sort_by { |l, n| -n }.each do |l, n|
  puts format("  %-9s %5.2f%%", l, n * 100.0 / total)
end
first_octets = blocks.map { |b| b.range.begin >> 24 }.to_set
puts "first octets used: #{first_octets.sort.join(" ")}"
