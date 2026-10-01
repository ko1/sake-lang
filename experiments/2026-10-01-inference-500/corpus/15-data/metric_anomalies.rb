class Point
  attr_reader :day, :value

  def initialize(day, value)
    @day = day
    @value = value
  end
end

def readings
  [
    ["2026-02-01", 120], ["2026-02-02", 132], ["2026-02-03", 128], ["2026-02-04", 125],
    ["2026-02-05", 140], ["2026-02-06", 95], ["2026-02-07", 90], ["2026-02-09", 131],
    ["2026-02-10", 129], ["2026-02-11", 310], ["2026-02-12", 136], ["2026-02-13", 141],
    ["2026-02-14", 99], ["2026-02-15", 97], ["2026-02-16", 138], ["2026-02-17", 145],
    ["2026-02-19", 12], ["2026-02-20", 150], ["2026-02-21", 104], ["2026-02-22", 101]
  ]
end

def parse_day(s)
  y, m, d = s.split("-").map(&:to_i)
  Time.new(y, m, d)
end

DAY_SECONDS = 86400

def series
  readings.map { |s, v| Point.new(parse_day(s), v) }
end

def label(t) = t.strftime("%a %m-%d")

def find_gaps(points)
  gaps = []
  points.each_cons(2) do |a, b|
    days = ((b.day - a.day) / DAY_SECONDS).round
    (days - 1).times { |k| gaps << a.day + (k + 1) * DAY_SECONDS } if days > 1
  end
  gaps
end

def moving_average(values, window)
  out = []
  values.each_with_index do |v, i|
    next if i + 1 < window
    slice = values[(i + 1 - window)..i]
    out << (slice ? slice.sum / Float(window) : nil)
  end
  out
end

def mean(xs) = xs.sum / Float(xs.size)

def stddev(xs)
  m = mean(xs)
  Math.sqrt(xs.sum { |x| (x - m) ** 2 } / (xs.size - 1))
end

def median(xs)
  s = xs.sort
  n = s.size
  n.odd? ? s.fetch(n / 2).to_f : (s.fetch(n / 2 - 1) + s.fetch(n / 2)) / 2.0
end

def mad(xs)
  m = median(xs)
  median(xs.map { |x| (x - m).abs })
end

points = series
values = points.map(&:value)
first = points.first
last = points.last
if first && last
  puts "Series #{label(first.day)} .. #{label(last.day)}: #{points.size} readings"
end
gaps = find_gaps(points)
puts "Missing days: #{gaps.empty? ? "none" : gaps.map { |g| label(g) }.join(", ")}"
puts format("mean %.1f  stddev %.1f  median %.1f  MAD %.1f", mean(values), stddev(values), median(values), mad(values))
puts

puts "Robust outliers (|x - median| > 3.5 * 1.4826 * MAD):"
med = median(values)
spread = mad(values) * 1.4826
points.each do |pt|
  score = (pt.value - med) / spread
  next if score.abs <= 3.5
  puts format("  %s %5d  score %+6.2f  %s", label(pt.day), pt.value, score, score > 0 ? "spike" : "drop")
end
puts

puts "3-day moving average:"
ma = moving_average(values, 3)
ma.each_with_index do |avg, i|
  pt = points.fetch(i + 2)
  v = pt.value
  marker = (v - avg).abs > avg * 0.4 ? " <-- deviates" : ""
  puts format("  %s %5d %8.1f%s", label(pt.day), v, avg, marker)
end
puts

puts "Weekday vs weekend:"
weekend, weekday = points.partition { |pt| pt.day.saturday? || pt.day.sunday? }
we = weekend.map(&:value)
wd = weekday.map(&:value)
puts format("  weekday n=%2d median %.1f", wd.size, median(wd))
puts format("  weekend n=%2d median %.1f", we.size, median(we))

puts
puts "Weekly totals (ISO week):"
weeks = points.group_by { |pt| pt.day.strftime("%G-W%V") }
weeks.each do |wk, pts|
  vals = pts.map(&:value)
  puts format("  %s days=%d total=%5d max=%4d", wk, vals.size, vals.sum, vals.max)
end
