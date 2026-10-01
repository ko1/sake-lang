# Per-sensor order statistics with quickselect (Lomuto partition, deterministic
# median-of-medians pivot), checked against sorting.

def partition(a, lo, hi, pivot_index)
  pivot = a[pivot_index]
  a[pivot_index] = a[hi]
  a[hi] = pivot
  store = lo
  (lo...hi).each do |i|
    if a[i] < pivot
      a[i], a[store] = a[store], a[i]
      store += 1
    end
  end
  a[hi] = a[store]
  a[store] = pivot
  store
end

def median_of_five(a, lo, hi)
  group = a[lo..hi].sort
  group[(group.size - 1) / 2]
end

# Deterministic pivot: the median of the medians of groups of five.
def pivot_value(a, lo, hi)
  return median_of_five(a, lo, hi) if hi - lo < 5
  medians = lo.step(hi, 5).map { |i| median_of_five(a, i, (i + 4).clamp(lo, hi)) }
  quickselect(medians, (medians.size - 1) / 2)
end

def quickselect(input, k)
  raise IndexError, "rank #{k} out of 0...#{input.size}" if k < 0 || k >= input.size
  a = input.dup
  lo = 0
  hi = a.size - 1
  loop do
    return a[lo] if lo == hi
    pv = pivot_value(a, lo, hi)
    pos = partition(a, lo, hi, (lo..hi).find { |i| a[i] == pv })
    if k == pos
      return a[pos]
    elsif k < pos
      hi = pos - 1
    else
      lo = pos + 1
    end
  end
end

def median(a)
  n = a.size
  if n.odd?
    quickselect(a, n / 2)
  else
    (quickselect(a, n / 2 - 1) + quickselect(a, n / 2)) / 2.0
  end
end

def percentile(a, pct)
  rank = (pct / 100.0 * a.size).ceil - 1
  quickselect(a, rank.clamp(0, a.size - 1))
end

readings = [
  ["north", 21.4], ["north", 22.0], ["south", 18.9], ["north", 21.7], ["east", 25.2],
  ["south", 19.4], ["east", 24.8], ["north", 35.0], ["south", 18.1], ["east", 25.0],
  ["north", 21.9], ["south", 19.0], ["east", 26.1], ["north", 22.3], ["south", -4.0],
  ["east", 24.9], ["north", 21.5], ["south", 18.7], ["east", 25.5], ["north", 21.8],
  ["west", 15.5]
]

by_sensor = {}
readings.each do |name, value|
  (by_sensor[name] ||= []) << value
end

by_sensor.keys.sort.each do |name|
  vals = by_sensor[name]
  med = median(vals)
  lo = quickselect(vals, 0)
  hi = quickselect(vals, vals.size - 1)
  p90 = percentile(vals, 90)
  check = vals.sort
  ok = lo == check.first && hi == check.last
  puts format("%-6s n=%2d min=%5.1f median=%5.2f p90=%5.1f max=%5.1f %s",
              name, vals.size, lo, med, p90, hi, ok ? "ok" : "MISMATCH")
end

puts "outliers (more than 5.0 from the sensor median):"
by_sensor.each do |name, vals|
  med = median(vals)
  vals.each do |v|
    d = v - med
    puts "  #{name}: #{v} (#{d > 0 ? "+" : ""}#{d.round(2)})" if d.abs > 5.0
  end
end

big = []
x = 12345
301.times do
  x = (x * 7919 + 17) % 100003
  big << x % 1000
end
sorted = big.sort
all_ok = [0, 1, 50, 150, 299, 300].all? { |k| quickselect(big, k) == sorted[k] }
puts "big: median=#{median(big)} p99=#{percentile(big, 99)} ranks agree=#{all_ok}"

begin
  quickselect([3.0, 1.0], 2)
rescue IndexError => e
  puts "error: #{e.message}"
end
