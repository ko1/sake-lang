class DateError < StandardError
  attr_reader :input

  def initialize(message, input)
    super(message)
    @input = input
  end
end

def month_names = ["January", "February", "March", "April", "May", "June", "July",
                   "August", "September", "October", "November", "December"]
def day_names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

def leap?(y) = (y % 4 == 0 && y % 100 != 0) || y % 400 == 0

def days_in_month(y, m)
  return 29 if m == 2 && leap?(y)
  [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1]
end

class Date
  attr_reader :year, :month, :day

  def initialize(year, month, day)
    @year = year
    @month = month
    @day = day
  end

  def valid? = month.between?(1, 12) && day >= 1 && day <= days_in_month(year, month)

  def weekday
    y = year
    m = month
    if m < 3
      m += 12
      y -= 1
    end
    k = y % 100
    j = y / 100
    h = (day + 13 * (m + 1) / 5 + k + k / 4 + j / 4 + 5 * j) % 7
    (h + 6) % 7
  end

  def day_of_year
    day + (1...month).sum { |m| days_in_month(year, m) }
  end

  def self.ordinal(n)
    return "th" if (11..13).cover?(n % 100)
    case n % 10
    when 1 then "st"
    when 2 then "nd"
    when 3 then "rd"
    else "th"
    end
  end

  def strftime(pattern)
    out = +""
    chars = pattern.chars
    i = 0
    while i < chars.size
      c = chars[i]
      if c != "%" || i + 1 >= chars.size
        out << c
        i += 1
        next
      end
      spec = chars[i + 1]
      out << case spec
             when "Y" then year.to_s
             when "y" then format("%02d", year % 100)
             when "m" then format("%02d", month)
             when "d" then format("%02d", day)
             when "e" then day.to_s.rjust(2)
             when "B" then month_names[month - 1]
             when "b" then month_names[month - 1][0...3]
             when "A" then day_names[weekday]
             when "a" then day_names[weekday][0...3]
             when "j" then format("%03d", day_of_year)
             when "o" then "#{day}#{Date.ordinal(day)}"
             when "%" then "%"
             else "%" + spec
             end
      i += 2
    end
    out
  end
end

def parse_date(s)
  d =
    if (m = s.match(/\A(\d{4})-(\d{1,2})-(\d{1,2})\z/)) && m
      Date.new(m[1].to_i, m[2].to_i, m[3].to_i)
    elsif (m = s.match(/\A(\d{1,2})\/(\d{1,2})\/(\d{4})\z/)) && m
      Date.new(m[3].to_i, m[1].to_i, m[2].to_i)
    elsif (m = s.match(/\A(\d{1,2}) ([A-Za-z]{3})[a-z]* (\d{4})\z/)) && m
      idx = month_names.map { |n| n[0...3].downcase }.index(m[2].downcase)
      raise DateError.new("unknown month '#{m[2]}'", s) if !idx    
      Date.new(m[3].to_i, idx + 1, m[1].to_i)
    else
      raise DateError.new("unrecognized date format", s)
    end
  raise DateError.new("no such day", s) unless d.valid?
  d
end

inputs = ["2026-10-01", "1969-7-20", "02/29/2024", "02/29/2023", "31 Dec 1999", "4 July 1776",
          "13 Smarch 2020", "2000-13-01", "yesterday", "1 jan 2001"]
patterns = ["%Y-%m-%d", "%a %e %b %Y", "%A, %B %o, %Y", "day %j of %Y (%y)", "100%% %q"]

dates = []
inputs.each do |s|
  d = parse_date(s)
  dates << d
  puts "#{s.ljust(16)} -> #{d.strftime(patterns[0])}  #{d.strftime(patterns[1])}"
rescue DateError => e
  puts "#{s.ljust(16)} !! #{e.message} (#{e.input.inspect})"
end
puts
patterns.drop(2).each do |pat|
  puts "pattern #{pat.inspect}:"
  dates.take(3).each { |d| puts "  " + d.strftime(pat) }
end
by_day = dates.group_by { |d| day_names[d.weekday] }
puts
puts "by weekday: " + by_day.keys.sort_by { |n| day_names.index(n) }.map { |n| "#{n}=#{by_day[n].size}" }.join(", ")
