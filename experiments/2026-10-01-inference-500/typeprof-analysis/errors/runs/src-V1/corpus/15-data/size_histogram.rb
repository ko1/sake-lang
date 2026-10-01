def file_sizes
  [
    512, 1800, 2400, 3100, 650, 72000, 15000, 15500, 4096, 8191, 8192, 120, 98000, 250000,
    1048576, 3000, 2900, 2048, 640, 33000, 47000, 5100, 5200, 6100, 130, 0, 9, 1_500_000, 16384, 70
  ]
end

def bucket_of(n)
  return 0 if n < 1
  n.bit_length
end

def bucket_label(b)
  return "0" if b == 0
  lo = 2 ** (b - 1)
  hi = 2 ** b - 1
  "#{human(lo)}-#{human(hi)}"
end

def human(n)
  units = %w[B K M G]
  value = n
  idx = 0
  while value >= 1024 && idx < units.size - 1
    value /= 1024
    idx += 1
  end
  "#{value}#{units[idx]}"
end

sizes = file_sizes
counts = Hash.new(0)
sizes.each { |n| counts[bucket_of(n)] += 1 }
lo, hi = counts.keys.minmax
peak = counts.values.max
total = sizes.size

puts "#{total} files, #{human(sizes.sum)} total"
running = 0
lo.upto(hi) do |b|
  c = counts[b]
  running += c
  bar = "*" * (c * 30 / peak)
  puts format("%-11s %3d %-30s %5.1f%%", bucket_label(b), c, bar, running * 100.0 / total)
end
sorted = sizes.sort
median = sorted.fetch(total / 2)
p90 = sorted.fetch(total * 9 / 10)
puts "median #{human(median)}, p90 #{human(p90)}, largest #{human(sorted.last || 0)}"
small = sizes.count { |n| n < 4096 }
puts format("%d files (%.0f%%) fit in one 4K block", small, small * 100.0 / total)
