# Time-zone conversion with fixed offsets and rule-based daylight saving
# (EU and US rules), using integer minutes since 1970-01-01 UTC.

def days_from_civil(y, m, d)
  y -= 1 if m <= 2
  era = y / 400
  yoe = y - era * 400
  doy = (153 * ((m + 9) % 12) + 2) / 5 + d - 1
  era * 146097 + yoe * 365 + yoe / 4 - yoe / 100 + doy - 719468
end

def civil_from_days(z)
  z += 719468
  era = z / 146097
  doe = z - era * 146097
  yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
  doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
  mp = (5 * doy + 2) / 153
  m = mp < 10 ? mp + 3 : mp - 9
  [yoe + era * 400 + (m <= 2 ? 1 : 0), m, doy - (153 * mp + 2) / 5 + 1]
end

def wday(z) = (z + 4) % 7

def last_sunday(y, m)
  last = days_from_civil(y, m + 1, 1) - 1
  last - wday(last)
end

def nth_sunday(y, m, n)
  first = days_from_civil(y, m, 1)
  first + (7 - wday(first)) % 7 + (n - 1) * 7
end

def utc_minutes(y, mo, d, h, mi) = (days_from_civil(y, mo, d) * 24 + h) * 60 + mi

class Zone
  attr_reader :name, :offset, :dst

  def initialize(name, offset, dst)
    @name = name
    @offset = offset
    @dst = dst
  end

  # DST window [start, finish) in UTC minutes for a year, or nil.
  def dst_window(y)
    case @dst
    in :eu
      [last_sunday(y, 3) * 1440 + 60, last_sunday(y, 10) * 1440 + 60]
    in :us
      [nth_sunday(y, 3, 2) * 1440 + 120 - @offset, nth_sunday(y, 11, 1) * 1440 + 120 - (@offset + 60)]
    in :none
      nil
    end
  end

  def offset_at(t)
    y, _m, _d = civil_from_days(t / 1440)
    window = dst_window(y)
    return @offset if window.nil?
    from, to = window
    t >= from && t < to ? @offset + 60 : @offset
  end

  def local(t) = t + offset_at(t)

  def label(t)
    off = offset_at(t)
    sign = off < 0 ? "-" : "+"
    a = off.abs
    format("UTC%s%02d:%02d", sign, a / 60, a % 60)
  end
end

def show(t)
  y, m, d = civil_from_days(t / 1440)
  mins = t % 1440
  format("%04d-%02d-%02d %02d:%02d", y, m, d, mins / 60, mins % 60)
end

ZONES = [
  Zone.new("London", 0, :eu),
  Zone.new("Berlin", 60, :eu),
  Zone.new("New York", -300, :us),
  Zone.new("Los Angeles", -480, :us),
  Zone.new("Kolkata", 330, :none),
  Zone.new("Tokyo", 540, :none),
  Zone.new("Kathmandu", 345, :none)
]

puts "DST windows 2026:"
ZONES.each do |zn|
  w = zn.dst_window(2026)
  next unless w
  from, to = w
  puts format("  %-12s %s UTC .. %s UTC", zn.name, show(from), show(to))
end

calls = [utc_minutes(2026, 3, 9, 15, 0), utc_minutes(2026, 3, 30, 15, 0), utc_minutes(2026, 10, 1, 23, 30),
         utc_minutes(2026, 10, 26, 15, 0), utc_minutes(2026, 11, 2, 15, 0)]
calls.each do |t|
  puts
  puts "Call at #{show(t)} UTC"
  utc_day = t / 1440
  ZONES.each do |zn|
    lt = zn.local(t)
    shift = lt / 1440 - utc_day
    tag = shift == 0 ? "" : format(" (%+d day)", shift)
    h = (lt % 1440) / 60
    mood = h >= 9 && h < 18 ? "work" : (h >= 7 && h < 22 ? "ok" : "night")
    puts format("  %-12s %s  %s  %-5s%s", zn.name, show(lt), zn.label(t), mood, tag)
  end
end

puts
day = days_from_civil(2026, 10, 1)
scores = (0..23).map do |h|
  t = (day * 24 + h) * 60
  inside = ZONES.count do |zn|
    lh = (zn.local(t) % 1440) / 60
    lh >= 9 && lh < 18
  end
  [h, inside]
end
best = scores.max_by { |h, n| n * 100 - h }
if best
  h, n = best
  puts format("Best UTC hour on 2026-10-01: %02d:00 with %d of %d zones in office hours", h, n, ZONES.size)
end
puts "Hours with nobody at work: #{scores.select { |_h, n| n == 0 }.map(&:first).join(" ")}"
