# A cron-expression evaluator: parses "min hour dom month dow" fields with
# lists, ranges and steps, then finds the next firing times after a moment.

require "set"

class CronError < StandardError
  attr_reader :field

  def initialize(message, field)
    super(message)
    @field = field
  end
end

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

ALIASES = { "mon" => 1, "tue" => 2, "wed" => 3, "thu" => 4, "fri" => 5, "sat" => 6, "sun" => 0,
            "jan" => 1, "feb" => 2, "mar" => 3, "apr" => 4, "may" => 5, "jun" => 6,
            "jul" => 7, "aug" => 8, "sep" => 9, "oct" => 10, "nov" => 11, "dec" => 12 }

def value(token, name)
  v = ALIASES[token.downcase]
  return v if v
  raise CronError.new("not a number: #{token}", name) unless token.match?(/\A\d+\z/)
  token.to_i
end

def parse_field(text, name, lo, hi)
  out = Set[]
  text.split(",").each do |part|
    range_text, step_text = part.split("/", 2)
    step = step_text.nil? ? 1 : value(step_text, name)
    raise CronError.new("step must be positive", name) if step < 1
    if range_text == "*"
      a = lo
      b = hi
    elsif range_text.include?("-")
      x, y = range_text.split("-", 2)
      a = value(x, name)
      b = value(y, name)
    else
      a = value(range_text, name)
      b = step_text.nil? ? a : hi
    end
    raise CronError.new("#{a}-#{b} outside #{lo}-#{hi}", name) if a < lo || b > hi || a > b
    (a..b).step(step) { |v| out << (name == "dow" ? v % 7 : v) }
  end
  out
end

class Cron
  attr_reader :text

  def self.parse(text)
    fields = text.split(" ")
    raise CronError.new("expected 5 fields, got #{fields.size}", "all") if fields.size != 5
    new(text, fields)
  end

  def initialize(text, fields)
    @text = text
    @minutes = parse_field(fields[0], "minute", 0, 59).sort
    @hours = parse_field(fields[1], "hour", 0, 23).sort
    @doms = parse_field(fields[2], "dom", 1, 31)
    @months = parse_field(fields[3], "month", 1, 12)
    @dows = parse_field(fields[4], "dow", 0, 7)
    @dom_any = fields[2] == "*"
    @dow_any = fields[4] == "*"
  end

  def day_matches?(z)
    _y, m, d = civil_from_days(z)
    return false unless @months.include?(m)
    dom_ok = @doms.include?(d)
    dow_ok = @dows.include?(wday(z))
    return dow_ok if @dom_any
    return dom_ok if @dow_any
    dom_ok || dow_ok
  end

  # Next firing strictly after t (minutes since epoch), searching up to a few years.
  def next_after(t)
    t += 1
    day = t / 1440
    limit = day + 366 * 5
    while day < limit
      if day_matches?(day)
        from = day == t / 1440 ? t % 1440 : 0
        @hours.each do |h|
          @minutes.each do |mi|
            return day * 1440 + h * 60 + mi if h * 60 + mi >= from
          end
        end
      end
      day += 1
    end
    nil
  end
end

def show(t)
  y, m, d = civil_from_days(t / 1440)
  format("%04d-%02d-%02d %s %02d:%02d", y, m, d, %w[Sun Mon Tue Wed Thu Fri Sat][wday(t / 1440)], (t % 1440) / 60, t % 60)
end

now = days_from_civil(2026, 10, 1) * 1440 + 9 * 60 + 41
puts "Now: #{show(now)}"
exprs = [
  "*/15 9-17 * * mon-fri",
  "0 0 1 * *",
  "30 2 * * 0",
  "0 12 13 * 5",
  "0 9 29 2 *",
  "5,35 */6 * jan,oct *",
  "0 18 L * *",
  "0 8 * * 1-5/2",
  "61 * * * *",
  "* * *"
]
exprs.each do |text|
  cron = Cron.parse(text)
  times = []
  t = now
  4.times do
    t = cron.next_after(t) if t
    times << t if t
  end
  puts format("%-22s %s", text, times.map { |x| show(x) }.join(" | "))
rescue CronError => e
  puts format("%-22s error in %s: %s", text, e.field, e.message)
end

job = Cron.parse("*/15 9-17 * * mon-fri")
t = days_from_civil(2026, 10, 1) * 1440 - 1
stop = days_from_civil(2026, 10, 15) * 1440
count = 0
per_day = Hash.new(0)
while (t = job.next_after(t)) && t < stop
  count += 1
  per_day[t / 1440] += 1
end
puts "Firings in the first two weeks of October 2026 of '#{job.text}': #{count} on #{per_day.size} days, #{per_day.values.max} per day"
