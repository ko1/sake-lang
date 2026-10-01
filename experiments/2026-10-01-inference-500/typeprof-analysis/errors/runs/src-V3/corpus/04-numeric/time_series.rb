class Reading
  attr_reader :day, :temp

  def initialize(day, temp)
    @day = day
    @temp = temp
  end
end

def readings
  temps = [
    3.2, 4.1, 2.8, 5.5, 6.0, 7.4, 6.9, 8.8, 9.1, 10.4, 9.7, 11.2, 12.5, 11.9,
    13.4, 14.8, 13.9, 15.2, 21.7, 16.1, 17.3, 16.8, 18.2, 17.5, 19.0, 18.4, 17.7, 16.2,
    15.8, 14.1, 14.9, 12.6, 11.8, 10.2, 2.0, 9.3, 8.1, 7.7, 6.2, 5.9
  ]
  temps.each_with_index.map { |t, i| Reading.new(i + 1, t) }
end

def sma(xs, w)
  xs.each_cons(w).map { |win| win.sum / w }
end

def ema(xs, alpha)
  prev = nil
  xs.map do |x|
    prev = prev.nil? ? x : alpha * x + (1.0 - alpha) * prev
  end
end

def rolling_std(xs, w)
  xs.each_cons(w).map do |win|
    m = win.sum / w
    Math.sqrt(win.map { |x| (x - m) ** 2 }.sum / (w - 1))
  end
end

def median_of(xs)
  s = xs.sort
  n = s.size
  n.odd? ? s[n / 2] : (s[n / 2 - 1] + s[n / 2]) / 2.0
end

# Hampel filter: replace points far from the rolling median
def hampel(xs, half, k)
  cleaned = xs.dup
  flagged = []
  xs.each_with_index do |x, i|
    lo = [0, i - half].max
    hi = [xs.size - 1, i + half].min
    win = xs[lo..hi]
    med = median_of(win)
    mad = median_of(win.map { |v| (v - med).abs })
    if (x - med).abs > k * 1.4826 * mad
      cleaned[i] = med
      flagged << [i, x, med]
    end
  end
  [cleaned, flagged]
end

def local_extrema(xs)
  result = []
  (1...(xs.size - 1)).each do |i|
    if xs[i] > xs[i - 1] && xs[i] > xs[i + 1]
      result << [:max, i]
    elsif xs[i] < xs[i - 1] && xs[i] < xs[i + 1]
      result << [:min, i]
    end
  end
  result
end

data = readings
temps = data.map(&:temp)
puts format("%d readings, raw mean %.3f", temps.size, temps.sum / temps.size)

cleaned, flagged = hampel(temps, 3, 3.0)
flagged.each do |i, was, now|
  puts format("day %2d: %.1f looks wrong, replaced by %.2f", data[i].day, was, now)
end

s7 = sma(cleaned, 7)
e3 = ema(cleaned, 0.3)
sd = rolling_std(cleaned, 7)
puts " day   temp  sma7   ema   std7"
cleaned.each_with_index do |t, i|
  next unless i % 4 == 0 || i == cleaned.size - 1
  sm = i >= 6 ? format("%5.2f", s7[i - 6]) : "    -"
  st = i >= 6 ? format("%5.2f", sd[i - 6]) : "    -"
  puts format("%4d %6.2f %s %5.2f %s", i + 1, t, sm, e3[i], st)
end

local_extrema(s7).each do |kind, i|
  label = kind == :max ? "peak" : "trough"
  puts format("smoothed %s on day %d (%.3f)", label, i + 7, s7[i])
end

warm = cleaned.slice_when { |a, b| (a >= 15.0) != (b >= 15.0) }
runs = warm.select { |run| run.first >= 15.0 }
longest = runs.max_by(&:size)
if longest
  puts format("longest warm spell: %d days, mean %.2f", longest.size, longest.sum / longest.size)
end

diffs = cleaned.drop(1).zip(cleaned).map { |b, a| b - a }
up, down = diffs.partition { |d| d > 0.0 }
puts format("rises: %d (avg %.3f), falls: %d (avg %.3f)", up.size, up.sum / up.size, down.size, down.sum / down.size)
biggest = diffs.each_index.max_by { |i| diffs[i].abs }
puts format("biggest day-to-day change: day %d -> %d (%+.2f)", biggest + 1, biggest + 2, diffs[biggest])
