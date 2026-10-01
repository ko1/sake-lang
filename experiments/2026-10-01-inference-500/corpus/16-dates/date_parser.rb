# A tolerant date parser: ISO, US slashes, European dots, "1 Oct 2026",
# "October 1, 2026", compact digits and relative words, normalised to ISO.

class ParseError < StandardError
  attr_reader :input, :reason

  def initialize(message, input, reason)
    super(message)
    @input = input
    @reason = reason
  end
end

MONTH_NAMES = ["january", "february", "march", "april", "may", "june", "july",
               "august", "september", "october", "november", "december"]

def leap?(y) = (y % 4 == 0 && y % 100 != 0) || y % 400 == 0

def dim(y, m) = m == 2 && leap?(y) ? 29 : [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1]

def month_number(word)
  w = word.downcase
  return nil if w.size < 3
  i = MONTH_NAMES.find_index { |name| name.start_with?(w) }
  i ? i + 1 : nil
end

def check(input, y, m, d)
  raise ParseError.new("bad month", input, "month #{m}") if m < 1 || m > 12
  raise ParseError.new("bad day", input, "day #{d} of #{y}-#{m}") if d < 1 || d > dim(y, m)
  [y, m, d]
end

def to_days(y, m, d)
  n = (y - 1) * 365 + (y - 1) / 4 - (y - 1) / 100 + (y - 1) / 400
  (1...m).each { |mm| n += dim(y, mm) }
  n + d
end

def from_days(n)
  y = (n * 400) / 146097 + 1
  y -= 1 while to_days(y, 1, 1) > n
  y += 1 while to_days(y + 1, 1, 1) <= n
  rest = n - to_days(y, 1, 1) + 1
  m = 1
  while rest > dim(y, m)
    rest -= dim(y, m)
    m += 1
  end
  [y, m, rest]
end

def expand_year(y) = y < 100 ? (y < 70 ? 2000 + y : 1900 + y) : y

def parse(input, today)
  s = input.strip
  raise ParseError.new("empty", input, "nothing to parse") if s.empty?
  if (m = s.match(/\A(\d{4})-(\d{1,2})-(\d{1,2})\z/))
    return check(input, m[1].to_i, m[2].to_i, m[3].to_i)
  end
  if (m = s.match(/\A(\d{1,2})\/(\d{1,2})\/(\d{2,4})\z/))
    return check(input, expand_year(m[3].to_i), m[1].to_i, m[2].to_i)
  end
  if (m = s.match(/\A(\d{1,2})\.(\d{1,2})\.(\d{4})\z/))
    return check(input, m[3].to_i, m[2].to_i, m[1].to_i)
  end
  if (m = s.match(/\A(\d{4})(\d{2})(\d{2})\z/))
    return check(input, m[1].to_i, m[2].to_i, m[3].to_i)
  end
  if (m = s.match(/\A(\d{1,2})\s+([A-Za-z]+)\.?\s+(\d{4})\z/))
    mon = month_number(m[2])
    raise ParseError.new("bad month", input, "unknown month #{m[2]}") if mon.nil?
    return check(input, m[3].to_i, mon, m[1].to_i)
  end
  if (m = s.match(/\A([A-Za-z]+)\.?\s+(\d{1,2}),?\s+(\d{4})\z/))
    mon = month_number(m[1])
    raise ParseError.new("bad month", input, "unknown month #{m[1]}") if mon.nil?
    return check(input, m[3].to_i, mon, m[2].to_i)
  end
  base = to_days(*today)
  case s.downcase
  when "today" then return today
  when "tomorrow" then return from_days(base + 1)
  when "yesterday" then return from_days(base - 1)
  end
  if (m = s.match(/\Ain (\d+) (day|week)s?\z/))
    n = m[1].to_i
    n *= 7 if m[2] == "week"
    return from_days(base + n)
  end
  if (m = s.match(/\A(\d+) (day|week)s? ago\z/))
    n = m[1].to_i
    n *= 7 if m[2] == "week"
    return from_days(base - n)
  end
  raise ParseError.new("unrecognised", input, "no format matches")
end

inputs = [
  "2026-10-01", "2026-2-3", "10/31/2026", "12/25/99", "1/1/05", "24.12.2026", "20270115",
  "1 Oct 2026", "15 Sept. 2026", "March 3, 2027", "Jan 31 2028", "today", "Tomorrow",
  "in 3 weeks", "10 days ago", "2026-02-29", "2028-02-29", "13/01/2026", "31.04.2026",
  "5 Smarch 2026", "  ", "next tuesday", "2026-10-01T10:00"
]

today = [2026, 10, 1]
ok = []
failures = Hash.new(0)
inputs.each do |text|
  y, m, d = parse(text, today)
  iso = format("%04d-%02d-%02d", y, m, d)
  ok << iso
  puts format("%-18s => %s", "\"#{text}\"", iso)
rescue ParseError => e
  failures[e.message] += 1
  puts format("%-18s !! %s (%s)", "\"#{e.input}\"", e.message, e.reason)
end

puts
puts "Parsed #{ok.size} of #{inputs.size}"
failures.sort_by { |reason, _n| reason }.each { |reason, n| puts "  #{reason}: #{n}" }
sorted = ok.uniq.sort
puts "Distinct dates: #{sorted.size}, range #{sorted.first} .. #{sorted.last}"
sorted.group_by { |iso| iso[0..3].to_i }.each { |year, list| puts "  #{year}: #{list.size}" }
