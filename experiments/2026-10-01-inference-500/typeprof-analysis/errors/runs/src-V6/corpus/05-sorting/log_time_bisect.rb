# Answer time-window queries over a sorted event log with lower/upper bound
# binary searches, and locate the rotation point of a ring buffer dump.

class Event
  attr_reader :ts, :level, :msg

  def initialize(ts, level, msg)
    @ts = ts
    @level = level
    @msg = msg
  end
end

def lower_bound(a, key)
  lo = 0
  hi = a.size
  while lo < hi
    mid = (lo + hi) / 2
    if yield(a[mid]) < key
      lo = mid + 1
    else
      hi = mid
    end
  end
  lo
end

def upper_bound(a, key)
  lo = 0
  hi = a.size
  while lo < hi
    mid = (lo + hi) / 2
    if yield(a[mid]) <= key
      lo = mid + 1
    else
      hi = mid
    end
  end
  lo
end

def window(log, from, to)
  i = lower_bound(log, from, &:ts)
  j = upper_bound(log, to, &:ts)
  log[i...j]
end

def parse_ts(s)
  m = s.match(/\A(\d\d):(\d\d):(\d\d)\z/)
  raise ArgumentError, "bad time #{s}" unless m
  m[1].to_i * 3600 + m[2].to_i * 60 + m[3].to_i
end

def fmt_ts(t) = format("%02d:%02d:%02d", t / 3600, t / 60 % 60, t % 60)

# Smallest index of a rotated ascending array (the oldest entry in a ring buffer).
def rotation_point(a)
  lo = 0
  hi = a.size - 1
  while lo < hi
    mid = (lo + hi) / 2
    if a[mid] > a[hi]
      lo = mid + 1
    else
      hi = mid
    end
  end
  lo
end

def search_rotated(a, x)
  k = rotation_point(a)
  n = a.size
  lo = 0
  hi = n - 1
  while lo <= hi
    mid = (lo + hi) / 2
    real = (mid + k) % n
    v = a[real]
    return real if v == x
    if v < x
      lo = mid + 1
    else
      hi = mid - 1
    end
  end
  nil
end

raw = [
  ["08:59:58", :info, "boot"], ["09:00:00", :info, "listen"], ["09:00:00", :warn, "slow disk"],
  ["09:00:07", :info, "req /"], ["09:01:13", :error, "db timeout"], ["09:01:13", :info, "retry"],
  ["09:01:14", :info, "req /api"], ["09:05:00", :warn, "gc pause"], ["09:12:30", :info, "req /"],
  ["09:12:30", :error, "500 /api"], ["09:30:00", :info, "cron"], ["10:00:00", :info, "shutdown"]
]
log = raw.map { |t, lvl, msg| Event.new(parse_ts(t), lvl, msg) }

queries = [["09:00:00", "09:01:13"], ["09:01:15", "09:04:59"], ["09:12:30", "23:59:59"],
           ["00:00:00", "08:59:58"], ["09:00:00", "09:00:00"]]
queries.each do |from, to|
  hits = window(log, parse_ts(from), parse_ts(to))
  errors = hits.count { |e| e.level == :error }
  msgs = hits.map(&:msg)
  puts "#{from}..#{to}: #{hits.size} events, #{errors} errors #{msgs}"
end

first_error = log.find { |e| e.level == :error }
puts "first error at #{fmt_ts(first_error.ts)}" if first_error
same_second = upper_bound(log, 32473, &:ts) - lower_bound(log, 32473, &:ts)
puts "events at #{fmt_ts(32473)}: #{same_second}"

begin
  parse_ts("9:5")
rescue ArgumentError => e
  puts "rejected: #{e.message}"
end

ring = [512, 530, 611, 700, 702, 15, 40, 88, 130, 245, 301]
k = rotation_point(ring)
puts "ring oldest at #{k}: #{ring[k]}, newest #{ring[(k - 1) % ring.size]}"
[88, 700, 512, 301, 5, 999].each do |x|
  idx = search_rotated(ring, x)
  puts(idx ? "#{x} found at #{idx}" : "#{x} missing")
end
