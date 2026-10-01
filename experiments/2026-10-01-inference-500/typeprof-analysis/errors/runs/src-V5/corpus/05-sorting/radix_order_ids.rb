# Non-comparison sorts for a warehouse: counting sort of shipments by zone (stable),
# LSD radix sort of numeric order ids, and a histogram of package weights.

class Shipment
  attr_reader :order_id, :zone, :weight

  def initialize(order_id, zone, weight)
    @order_id = order_id
    @zone = zone
    @weight = weight
  end
end

def counting_sort_by(items, max_key)
  counts = Array.new(max_key + 1, 0)
  items.each { |x| counts[yield(x)] += 1 }
  # prefix sums: starting position for each key
  starts = []
  total = 0
  counts.each do |c|
    starts << total
    total += c
  end
  out = Array.new(items.size)
  items.each do |x|
    k = yield(x)
    out[starts[k]] = x
    starts[k] += 1
  end
  out
end

def radix_sort(nums, base)
  a = nums.dup
  maxv = a.max
  return [a, 0] if !maxv    
  exp = 1
  passes = 0
  while maxv / exp > 0
    a = counting_sort_by(a, base - 1) { |n| n / exp % base }
    exp *= base
    passes += 1
  end
  [a, passes]
end

def histogram(values, width)
  buckets = Hash.new(0)
  values.each { |v| buckets[(v / width).floor] += 1 }
  buckets.keys.sort.each do |b|
    lo = b * width
    label = format("%5.1f-%5.1f", lo, lo + width)
    puts "  #{label} #{"#" * buckets[b]} #{buckets[b]}"
  end
end

shipments = [
  Shipment.new(480213, 3, 2.4), Shipment.new(102938, 1, 12.0), Shipment.new(774001, 3, 0.8),
  Shipment.new(300120, 0, 5.5), Shipment.new(102937, 2, 7.25), Shipment.new(999999, 1, 1.1),
  Shipment.new(450000, 0, 3.3), Shipment.new(450001, 3, 9.9), Shipment.new(120, 2, 4.0),
  Shipment.new(661234, 1, 2.2), Shipment.new(480212, 0, 15.75), Shipment.new(5003, 2, 6.6)
]

by_zone = counting_sort_by(shipments, 3, &:zone)
puts "by zone (stable):"
current = nil
by_zone.each do |s|
  if s.zone != current
    puts "  zone #{s.zone}:"
    current = s.zone
  end
  puts format("    %06d %6.2fkg", s.order_id, s.weight)
end

ids = shipments.map(&:order_id)
[10, 16, 256].each do |base|
  sorted, passes = radix_sort(ids, base)
  puts "radix base #{base}: #{passes} passes, matches sort: #{sorted == ids.sort}"
end
sorted, _ = radix_sort(ids, 10)
puts "ids: #{sorted.map { |i| format("%06d", i) }.join(" ")}"

largest_gap = 0
gap_at = nil
sorted.each_cons(2) do |a, b|
  if b - a > largest_gap
    largest_gap = b - a
    gap_at = a
  end
end
puts "largest id gap: #{largest_gap} after #{gap_at}"

empty_sorted, empty_passes = radix_sort([], 10)
puts "empty input: #{empty_passes} passes"
p empty_sorted

puts "weight histogram:"
histogram(shipments.map(&:weight), 2.5)
heavy = shipments.count { |s| s.weight >= 10.0 }
puts "heavy parcels: #{heavy}, total #{shipments.sum(&:weight).round(2)}kg"
