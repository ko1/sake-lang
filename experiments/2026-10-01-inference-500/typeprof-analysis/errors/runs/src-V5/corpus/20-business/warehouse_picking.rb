class Bin
  attr_reader :location, :sku, :expires
  attr_accessor :qty

  def initialize(location, sku, qty, expires)
    @location = location
    @sku = sku
    @qty = qty
    @expires = expires
  end
end

class Pick
  attr_reader :order_id, :sku, :location, :qty

  def initialize(order_id, sku, location, qty)
    @order_id = order_id
    @sku = sku
    @location = location
    @qty = qty
  end
end

class Location
  include Comparable
  attr_reader :aisle, :bay, :level

  def initialize(aisle, bay, level)
    @aisle = aisle
    @bay = bay
    @level = level
  end

  def self.parse(code)
    m = code.match(/\A([A-Z])-(\d\d)-(\d)\z/)
    raise ArgumentError, "bad location #{code}" unless m
    Location.new(m[1].ord - "A".ord + 1, m[2].to_i, m[3].to_i)
  end

  # serpentine walk: odd aisles go up the bays, even aisles come back down
  def walk_key
    b = aisle.odd? ? bay : 100 - bay
    (aisle * 100 + b) * 10 + level
  end

  def <=>(other) = walk_key <=> other.walk_key
end

def parse_bins(text)
  text.lines.map do |line|
    loc, sku, qty, exp = line.strip.split(/\s+/)
    Bin.new(loc, sku, qty.to_i, exp == "-" ? nil : exp)
  end
end

# first-expiring stock first; bins without an expiry date go last
def allocate(bins, order_id, sku, wanted)
  candidates = bins.select { |b| b.sku == sku && b.qty > 0 }
  ordered = candidates.sort_by { |b| [b.expires || "9999-99-99", b.location] }
  picks = []
  left = wanted
  ordered.each do |b|
    break if left == 0
    take = [left, b.qty].min
    b.qty -= take
    left -= take
    picks << Pick.new(order_id, sku, b.location, take)
  end
  [picks, left]
end

bins = parse_bins(<<~TXT)
  A-01-1 SOAP 40 2027-01-31
  A-04-2 SOAP 25 2026-11-30
  B-02-1 TOWEL 60 -
  B-07-3 SHAMPOO 12 2026-12-15
  C-03-1 SHAMPOO 30 2027-03-01
  A-09-1 BRUSH 8 -
  C-08-2 TOWEL 15 -
  B-07-1 COMB 100 -
  D-01-1 LOTION 6 2026-10-20
TXT

orders = [
  ["SO-1001", [["SOAP", 30], ["TOWEL", 4], ["COMB", 2]]],
  ["SO-1002", [["SHAMPOO", 20], ["BRUSH", 10]]],
  ["SO-1003", [["LOTION", 2], ["SOAP", 10], ["TOWEL", 70]]],
  ["SO-1004", [["RAZOR", 1], ["SHAMPOO", 15]]]
]

all_picks = []
backorders = []
orders.each do |order_id, lines|
  lines.each do |sku, qty|
    picks, short = allocate(bins, order_id, sku, qty)
    all_picks.concat(picks)
    backorders << [order_id, sku, short] if short > 0
  end
end

puts "Pick route (batch of #{orders.size} orders):"
by_location = all_picks.group_by(&:location)
route = by_location.keys.sort_by { |code| Location.parse(code) }
route.each.with_index(1) do |code, step|
  picks = by_location.fetch(code)
  total = picks.sum(&:qty)
  split = picks.map { |p| "#{p.order_id}:#{p.qty}" }.join(" ")
  puts format("%2d. %s %-8s x%-3d (%s)", step, code, picks.first.sku, total, split)
end

puts
puts "Backorders:"
backorders.each { |o, sku, short| puts "  #{o} #{sku} short #{short}" }

puts
first = Location.parse(route.first)
last = Location.parse(route.last)
puts "Route starts at aisle #{first.aisle}, ends at aisle #{last.aisle}; in order: #{first < last}"
farthest = route.map { |c| Location.parse(c) }.max
puts "Last stop by walk order: aisle #{farthest.aisle} bay #{farthest.bay}"
empty = bins.select { |b| b.qty == 0 }
puts "Bins emptied: #{empty.map(&:location).join(", ")}"
expiring = bins.select { |b| b.qty > 0 && b.expires && b.expires < "2026-12-31" }
expiring.each { |b| puts "Expiring this year: #{b.location} #{b.sku} x#{b.qty} (#{b.expires})" }
begin
  Location.parse("Z9")
rescue ArgumentError => e
  puts "Error: #{e.message}"
end
