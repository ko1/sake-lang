require "date"

def show(label, x)
  puts("#{label}: #{x.inspect}")
end

def try_civil(y, m, d)
  Date.new(y, m, d).to_s
rescue Date::Error => e
  "Date::Error: #{e.message}"
end

def try_parse(s)
  Date.parse(s).to_s
rescue Date::Error => e
  "Date::Error: #{e.message}"
end

def try_iso(s)
  Date.iso8601(s).to_s
rescue Date::Error => e
  "Date::Error: #{e.message}"
end

def try_strptime(s, f)
  Date.strptime(s, f).to_s
rescue Date::Error => e
  "Date::Error: #{e.message}"
end

# construction and validation
d = Date.new(2024, 1, 31)
p(d)
puts(d)
show("fields", [d.year, d.month, d.mon, d.day, d.mday])
show("jd", [d.jd, d.mjd, d.ld, d.ajd])
show("wday/yday", [d.wday, d.yday, d.cwday, d.cweek, d.cwyear])
show("negative", [try_civil(2024, -1, -1), try_civil(2024, 2, -1), try_civil(2023, 2, -1), try_civil(2024, 2, -30)])
show("invalid", [try_civil(2024, 2, 30), try_civil(2023, 2, 29), try_civil(2024, 13, 1), try_civil(2024, 0, 1), try_civil(2024, 4, 31)])
show("valid_date?", [Date.valid_date?(2024, 2, 29), Date.valid_date?(2023, 2, 29), Date.valid_date?(2024, 12, 31), Date.valid_civil?(2024, 6, 31)])
show("leap?", [Date.leap?(2024), Date.leap?(1900), Date.leap?(2000), Date.leap?(2023)])
show("leap? date", [Date.new(1500, 1, 1).leap?, Date.new(1900, 1, 1).leap?, d.leap?])
show("gregorian_leap?", [Date.gregorian_leap?(1500), Date.julian_leap?(1500)])
show("Date.jd", [Date.jd(0), Date.jd(2460341), Date.jd(2299160), Date.jd(2299161)])
show("ordinal", [Date.ordinal(2024, 60), Date.ordinal(2024, -1), Date.valid_ordinal?(2023, 366)])
show("commercial", [Date.commercial(2024, 1, 1), Date.commercial(2020, 53, 7), Date.valid_commercial?(2021, 53, 1)])

# calendar reform (Date::ITALY): Julian before 1582-10-15
show("reform", [Date.new(1582, 10, 4) + 1, Date.new(1582, 10, 15) - 1, try_civil(1582, 10, 10)])
show("julian", [Date.new(1582, 10, 4).julian?, Date.new(1582, 10, 15).gregorian?])
show("old diff", Date.new(1000, 3, 1) - Date.new(1000, 2, 28))
show("year 0 and negative", [Date.new(0, 1, 1), Date.new(-1, 12, 31), Date.new(10000, 1, 1)])

# arithmetic
show("+", [d + 1, d + 30, d + -31, d - 365])
show("date - date", [Date.new(2024, 3, 1) - Date.new(2024, 2, 1), d - d, Date.new(2023, 1, 1) - d])
show("to_i of diff", (Date.new(2025, 1, 1) - Date.new(2024, 1, 1)).to_i)
show(">>", [d >> 1, d >> 2, d >> 12, d >> -1, Date.new(2024, 2, 29) >> 12, d >> 13])
show("<<", [d << 1, d << 2, Date.new(2024, 3, 31) << 1, Date.new(2024, 1, 15) << 13])
show("next/prev", [d.next_day, d.prev_day, d.next_month, d.prev_month, d.next_year, d.prev_year])
show("succ", [Date.new(2023, 12, 31).succ, d.next])
show("leap next_year", Date.new(2024, 2, 29).next_year)

# comparison
e = Date.new(2024, 2, 1)
show("cmp", [d < e, d <= e, d > e, d >= e, d == Date.new(2024, 1, 31), d != e, d <=> e, e <=> d, d <=> d])
show("== nil", d == nil)
show("sort", [e, d, Date.new(2023, 5, 5)].sort)
show("max/min", [[d, e].max, [d, e].min])
show("include?", [d, e].include?(Date.new(2024, 2, 1)))

# iteration
xs = []
Date.new(2024, 1, 1).step(Date.new(2024, 1, 10), 3) { |x| xs.push(x.day) }
show("step", xs)
xs = []
Date.new(2024, 1, 10).step(Date.new(2024, 1, 1), -4) { |x| xs.push(x.day) }
show("step down", xs)
xs = []
Date.new(2024, 2, 27).upto(Date.new(2024, 3, 2)) { |x| xs.push(x.to_s) }
show("upto", xs)
xs = []
Date.new(2024, 1, 2).downto(Date.new(2023, 12, 30)) { |x| xs.push(x.wday) }
show("downto", xs)
xs = []
Date.new(2024, 1, 2).upto(Date.new(2024, 1, 1)) { |x| xs.push(x) }
show("upto empty", xs)

# day predicates
show("weekday?", [d.sunday?, d.monday?, d.wednesday?, Date.new(2024, 2, 3).saturday?])

# week numbers around the year boundary
[Date.new(2020, 12, 31), Date.new(2021, 1, 1), Date.new(2021, 1, 4), Date.new(2024, 12, 30), Date.new(2027, 1, 1)].each do |x|
  puts("#{x} cw=#{x.cwyear}-#{x.cweek}-#{x.cwday} #{x.strftime("%U %W %V %G %g %j %u %w")}")
end

# formatting
puts(d.strftime("%Y-%m-%d %y %C %e %j %a %A %b %B %h"))
puts(d.strftime("%F | %D | %x | %T | %X | %R | %r | %c | %v | %+"))
puts(d.strftime("%-m/%-d %_m %^a %^B %10A|%-10A|%010A|%3N|%L|%N|%s|%Q"))
puts(d.strftime("%z %:z %::z %Z %H:%M:%S %I %l %p %P %% %n|%t|"))
puts(Date.new(5, 3, 7).strftime("%Y %C %y %-d %e %10Y"))
puts(Date.new(-1, 1, 1).strftime("%Y|%C|%y|%G"))
puts(d.strftime("no directives"))
puts(d.strftime(""))
puts(d.strftime("%Q%"))
puts(Date.new(2024, 7, 4).strftime("%B %-d, %Y (%A)"))
show("iso8601", [d.iso8601, d.xmlschema, d.rfc3339])
show("httpdate", [d.httpdate, Date.new(2024, 2, 5).rfc2822])
show("to_time", d.to_time.year)
show("to_date", d.to_date == d)
show("names", [Date::MONTHNAMES, Date::ABBR_DAYNAMES])

# parsing
show("parse", ["2024-01-05", "2024/1/5", "20240105", "Jan 5 2024", "5 January 2024",
               "January 5, 2024", "Fri, 5 Jan 2024", "2024-01-05T10:00:00+09:00",
               "5th Mar 2024", "5 Jan 24", "5 Jan 99", "-0044-03-15"].map { |s| try_parse(s) })
show("parse bad", ["", "foo", "2024-02-30", "Foo 5 2024"].map { |s| try_parse(s) })
show("iso8601 parse", ["2024-01-05", "20240105", "2024-005", "2024005", "2024-W01-5",
                       "2024W015", "2024-01-05T00:00:00Z", "2024-1-5", "x", "2024-13-01"].map { |s| try_iso(s) })
show("strptime", [try_strptime("2024-01-05", "%Y-%m-%d"), try_strptime("05/01/2024", "%d/%m/%Y"),
                  try_strptime("24/1/5", "%y/%m/%d"), try_strptime("Jan 5 2024", "%b %d %Y"),
                  try_strptime("2024 60", "%Y %j"), try_strptime("2024", "%Y"),
                  try_strptime("Friday, January 5, 2024", "%A, %B %d, %Y"),
                  try_strptime("2024-01-05", "%F"), try_strptime("01/05/24", "%D"),
                  try_strptime("100%", "100%%")])
show("strptime bad", [try_strptime("x", "%Y"), try_strptime("2024-02-30", "%Y-%m-%d"),
                      try_strptime("2024/01/05", "%Y-%m-%d"), try_strptime("", "%Y")])


# optional arguments (Ruby's defaults)
show("defaults", [Date.new, Date.new(2024), Date.new(2024, 3), Date.ordinal(2024), Date.commercial(2024), Date.commercial(2024, 10)])
show("next/prev n", [d.next_day(3), d.prev_day(31), d.next_month(13), d.prev_month(2), Date.new(2024, 2, 29).next_year(4), d.prev_year(2), d.next_day(0)])
xs = []
Date.new(2024, 2, 27).step(Date.new(2024, 3, 1)) { |x| xs.push(x.day) }
show("step default", xs)
show("strftime default", d.strftime)
show("strptime default", [Date.strptime("2024-03-04").to_s, Date.strptime.to_s, try_strptime("03/04/2024", "%F")])
show("parse comp", [Date.parse("5 Jan 24", false), Date.parse("5 Jan 24", true), Date.parse("Jan 5 99", false), Date.parse])
show("parse limit", [Date.parse("2020-01-03", true, limit: 10), Date.parse("2020-01-01" + " " * 130, limit: nil)])
[["2020-01-01" + " " * 130, 128], ["2020-01-02", 5]].each do |s, n|
  begin
    Date.parse(s, limit: n)
  rescue ArgumentError => e
    show("parse limit error", e.message)
  end
end

# today
t = Time.now
today = Date.today
show("today", today == Date.new(t.year, t.month, t.day) || Date.today != today)

# start (Ruby's fourth argument; only Date::ITALY)
show("start", [Date::ITALY, Date.new(2024, 1, 31, Date::ITALY).start, Date.civil(1582, 10, 15, Date::ITALY),
               Date.parse("2024-02-03", true, Date::ITALY), Date.strptime("2024-02-03", "%F", Date::ITALY),
               Date.ordinal(2024, 60, Date::ITALY), Date.commercial(2024, 1, 1, Date::ITALY)])
# without a block: Ruby's Enumerator, as an Array
show("blockless step", [Date.new(2024, 1, 1).step(Date.new(2024, 1, 10), 4).to_a,
                        Date.new(2024, 2, 28).upto(Date.new(2024, 3, 1)).to_a,
                        Date.new(2024, 3, 1).downto(Date.new(2024, 2, 28)).to_a,
                        Date.new(2024, 3, 1).upto(Date.new(2024, 2, 28)).to_a])
