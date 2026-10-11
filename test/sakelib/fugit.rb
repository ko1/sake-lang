require "fugit"

# Times are fixed UTC values (never the clock); results print as text
def show(t) = t.strftime("%F %T %z %a")

# cron: parse, fields, to_cron_s
c = Fugit::Cron.parse("*/15 9-17 * * mon-fri")
p(c.original)
p(c.to_cron_s)
p(c.seconds)
p(c.minutes)
p(c.hours)
p(c.monthdays)
p(c.months)
p(c.weekdays)
p(c.to_a)
p(c.to_h)

# next_time / previous_time / match? from a fixed time
t = Time.new(2024, 1, 31, 10, 7, 0, "UTC")
puts(show(c.next_time(t)))
puts(show(c.previous_time(t)))
p(c.match?(t))
p(c.match?(Time.new(2024, 1, 31, 10, 15, 0, "UTC")))
p(c.match?(Time.new(2024, 2, 3, 10, 15, 0, "UTC")))
# from a Friday evening, the next is Monday morning
puts(show(c.next_time(Time.new(2024, 2, 2, 17, 50, 0, "UTC"))))
puts(show(c.previous_time(Time.new(2024, 2, 5, 9, 0, 0, "UTC"))))

# a run of next times
n = Time.new(2024, 2, 28, 23, 0, 0, "UTC")
Fugit::Cron.parse("30 0 * * *").next(n).take(3).each { |x| puts(show(x)) }
Fugit::Cron.parse("0 12 * * *").prev(n).take(2).each { |x| puts(show(x)) }
w = Fugit::Cron.parse("0 */6 * * *").within(Time.new(2024, 3, 1, 0, 0, 0, "UTC"), Time.new(2024, 3, 2, 0, 0, 0, "UTC"))
p(w.map { |x| x.hour })

# the many forms of a cron string
[
  "0 0 L * *",
  "0 0 -2 * *",
  "0 0 * * 1#2,5#-1",
  "0 0 * * tue%2+1",
  "0 0 * * mon%2",
  "@daily",
  "@hourly",
  "@weekly",
  "*/10 * * * * *",
  "5 0 * 8 *",
  "0 22 * * 1-5",
  "0 0,12 1 */2 *",
  "0 4 8-14 * *",
  "0 0 1,15 * 3",
  "0 0 1,15 * 3&",
  "0 0 * * sun,7",
  "0 0 * * fri-mon",
  "0 0 * jan-mar,dec *",
  "0 23-2 * * *",
  "0 0 30 * *",
  "0 9 * * * +09:00",
  "0 9 * * * UTC",
  ",0,,30, * * * *",
].each do |s|
  cc = Fugit::Cron.parse(s)
  puts("#{s.inspect} -> #{cc.to_cron_s.inspect} #{show(cc.next_time(t))} #{show(cc.previous_time(t))}")
end

# hash (n-th weekday) and modulo (every other week) in action
second_monday = Fugit::Cron.parse("0 8 * * mon#2")
puts(show(second_monday.next_time(t)))
last_friday = Fugit::Cron.parse("0 8 * * fri#L")
puts(show(last_friday.next_time(t)))
every_other = Fugit::Cron.parse("0 8 * * tue%2")
puts(show(every_other.next_time(t)))
puts(show(every_other.next_time(every_other.next_time(t))))
# monthday and weekday: either matches; with & both must
p(Fugit::Cron.parse("0 0 13 * 5").next(t).take(3).map { |x| show(x) })
p(Fugit::Cron.parse("0 0 13 * 5&").next(t).take(2).map { |x| show(x) })

# a cron with a zone: computed there, shown in the zone of the argument
tokyo = Fugit::Cron.parse("0 9 * * * +09:00")
p(tokyo.zone)
puts(show(tokyo.next_time(t)))
p(tokyo.match?(Time.new(2024, 2, 1, 0, 0, 0, "UTC")))

# rough_frequency (seconds between occurrences, roughly)
["* * * * *", "*/15 * * * *", "0 * * * *", "0 0 * * *", "0 0 * * 1", "0 0 1 * *", "*/10 * * * * *"].each do |s|
  p([s, Fugit::Cron.parse(s).rough_frequency])
end

# equality
p(Fugit::Cron.parse("0 0 * * *") == Fugit::Cron.parse("@daily"))
p(Fugit::Cron.parse("0 0 * * *") == Fugit::Cron.parse("@hourly"))

# what is not a cron: nil from parse, ArgumentError from do_parse
["", "* * *", "60 * * * *", "* 25 * * *", "0 0 30 2 *", "@reboot", "0 0 * * * Europe/Nowhere", "*/0 * * * *", "1 2 3 4 5 6 7 8"].each do |s|
  p([s, Fugit::Cron.parse(s)])
end
begin
  Fugit::Cron.do_parse("nada")
rescue ArgumentError => e
  puts(e.message)
end
begin
  Fugit::Cron.do_parse("a long string that is not a cron, not at all")
rescue ArgumentError => e
  puts(e.message)
end
# an impossible date is found while searching
begin
  p(Fugit::Cron.parse("0 0 31 4,6 *"))
  p(Fugit::Cron.parse("0 0 31 * 0&").next_time(t).year)
rescue RuntimeError => e
  puts(e.message[0, 40])
end

# duration: parse, h, the printers
d = Fugit::Duration.parse("1h30m")
p(d.h)
p(d.to_plain_s)
p(d.to_iso_s)
p(d.to_long_s)
p(d.to_rufus_s)
p(d.to_sec)
p(d.original)
[
  "1y2M3d4h5m6s",
  "1 year, 2 months and 3 days",
  "2 weeks",
  "1.5h",
  "-1h +30m",
  "-1h30m",
  "90",
  "1h 90s",
  "3 hours and 15 minutes",
  "P1Y2M3DT4H5M6.5S",
  "PT36H",
  "p1w",
  "1d 2h, 3m",
].each do |s|
  dd = Fugit::Duration.parse(s)
  puts("#{s.inspect} -> #{dd.h} #{dd.to_plain_s} #{dd.to_iso_s} #{dd.deflate.to_plain_s}")
end
p(Fugit::Duration.parse(3700).h)
p(Fugit::Duration.parse(3700).deflate.h)
p(Fugit::Duration.parse(90.5).deflate.to_plain_s)
p(Fugit::Duration.parse("1.5h").deflate.h)
p(Fugit::Duration.parse("100d").deflate(month: true).to_plain_s)
p(Fugit::Duration.parse("400d").deflate(year: true, month: true).to_plain_s)
p(Fugit::Duration.parse("36h").inflate.h)
p(Fugit::Duration.parse("1y36h").inflate.h)
p(Fugit::Duration.parse("1y2M").to_long_s(oxford: false))

# class-level shorthands: parse, deflate, print
p(Fugit::Duration.to_plain_s("3600s"))
p(Fugit::Duration.to_iso_s("90m"))
p(Fugit::Duration.to_long_s("1y2M3d"))

# arithmetic on durations and times
p((Fugit::Duration.parse("1d2h") + Fugit::Duration.parse("3h")).h)
p((Fugit::Duration.parse("1d2h") + 60).h)
p((Fugit::Duration.parse("1d2h") + "1d").h)
p((Fugit::Duration.parse("1d2h") - Fugit::Duration.parse("3h")).h)
p(Fugit::Duration.parse("1h").opposite.h)
p((-Fugit::Duration.parse("1h")).h)
p(Fugit::Duration.parse("1h30m").drop_seconds.h)
p(Fugit::Duration.parse("30s").drop_seconds.h)
p(Fugit::Duration.parse("1h") == Fugit::Duration.parse("60m"))
p(Fugit::Duration.parse("1h") == Fugit::Duration.parse("1h"))
puts(show(Fugit::Duration.parse("1d1h") + t))
puts(show(Fugit::Duration.parse("1M") + Time.new(2024, 1, 15, 0, 0, 0, "UTC")))
puts(show(Fugit::Duration.parse("1y") + t))
puts(show(Fugit::Duration.parse("1h").next_time(t)))
puts(show(Fugit::Duration.parse("2h") - t))

# not a duration
["", "abc", "1x", "h1"].each do |s|
  dd = Fugit::Duration.parse(s)
  p([s, dd ? dd.h : nil])
end
begin
  Fugit::Duration.do_parse("nope")
rescue ArgumentError => e
  puts(e.message)
end
p(Fugit::Duration.parse("P1Y2M", iso: true).h)
p(Fugit::Duration.parse("1h", iso: true))
p(Fugit::Duration.parse("P1D", plain: true))

# Fugit.parse: a cron, else a duration, else nil
p(Fugit.parse("0 0 * * *").is_a?(Fugit::Cron))
p(Fugit.parse("1h").is_a?(Fugit::Duration))
p(Fugit.parse("tomorrow!"))
p(Fugit.parse_cron("@noon").to_cron_s)
p(Fugit.parse_duration("2d").to_plain_s)
p(Fugit.parse_in("1h").to_sec)
puts(Fugit.time_to_plain_s(t))
