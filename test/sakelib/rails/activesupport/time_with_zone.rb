gem "activesupport", "8.1.3"
require "active_support"
require "active_support/time"

# ActiveSupport::TimeZone (values/time_zone), TimeWithZone, Duration and the Time/Date calculations.
puts "== TimeZone"
ny = Time.find_zone!("Eastern Time (US & Canada)")
tokyo = Time.find_zone!("Tokyo")
utc = Time.find_zone!("UTC")
p(ny.name, ny.tzinfo.identifier, tokyo.utc_offset, ny.formatted_offset)
puts(ny.to_s, tokyo.to_s, utc.to_s)
p(ActiveSupport::TimeZone.seconds_to_utc_offset(-18000), ActiveSupport::TimeZone.seconds_to_utc_offset(19800, false), Time.find_zone("Nowhere"), Time.find_zone!("America/Chicago").name)
p((ActiveSupport::TimeZone[9] || utc).name, ActiveSupport::TimeZone.all.size > 100, (ActiveSupport::TimeZone.all.first || utc).name)
p(ny.match?(/New_York/), ny < tokyo)

puts "== TimeWithZone"
t = ny.local(2024, 3, 10, 1, 30, 0)
p(t, t.zone, t.dst?, t.utc_offset)
t2 = t + 1.hour
p(t2, t2.zone, t2.dst?, t2 - t)
p(ny.local(2024, 3, 10, 2, 30, 0), ny.local(2024, 11, 3, 1, 30, 0))
puts(t, t.xmlschema, t.iso8601(3), t.httpdate, t.rfc2822)
puts(t.to_fs(:db), t.to_fs(:long), t.to_fs(:short), t.to_fs(:long_ordinal), t.to_fs(:number))
puts(t.strftime("%a %b %e %H:%M %Z %z %%Z"), t.as_json)
p(t.in_time_zone("Tokyo"), t.utc, t.to_i, t.to_a)
p(t.year, t.month, t.day, t.hour, t.wday, t.yday)
p(t.change(hour: 12), t.change(day: 1), t.advance(days: 1, hours: 2), t.advance(minutes: 90))
p(t.beginning_of_day, t.end_of_day, t.beginning_of_month, t.end_of_month, t.beginning_of_week)
p(t.next_week, t.prev_week, t.tomorrow, t.next_occurring(:friday), t.quarter)
p(t == t.utc, t < t2, t.between?(t, t2), t.utc?, t.in_time_zone("UTC").utc?)
p(tokyo.parse("2024-05-06 07:08:09"), tokyo.parse("2024-05-06 07:08:09 +0000"), ny.iso8601("2024-07-04T12:00:00Z"), tokyo.at(0))
p(t.to_date.readable_inspect, utc.local(2024, 1, 1).to_fs(:rfc822))

puts "== Time.zone"
p(Time.zone)
Time.zone = "Tokyo"
p((Time.zone || utc).name, Time.utc(2024, 1, 1, 0, 0, 0).in_time_zone)
Time.use_zone("Hawaii") { p(Time.utc(2024, 1, 1, 0, 0, 0).in_time_zone) }
p(Time.utc(2024, 1, 1, 0, 0, 0).in_time_zone("Eastern Time (US & Canada)"))
begin
  Time.zone = "Mars"
rescue ArgumentError => e
  puts e.message
end

puts "== Duration"
jan31 = ny.local(2024, 1, 31, 10, 0, 0)
p(1.month.since(jan31), 1.year.ago(jan31), 45.days.since(jan31), 1.5.days.since(jan31))
p(jan31 + 2.weeks, jan31 - 3.hours, 30.minutes.after(jan31), (3.hours + 5.minutes).inspect)
p((1.year + 2.days + 3.hours).iso8601, ActiveSupport::Duration.parse("P1M2DT3H").parts, 1.hour.variable?, 1.day.variable?)
p(ActiveSupport::Duration.build(100000).parts, 1.fortnight.in_days, 2.minutes.as_json)

puts "== Time and Date calculations"
tm = Time.utc(2024, 2, 29, 15, 45, 30)
p(tm.change(year: 2025), tm.change(hour: 9), tm.change(min: 5), tm.advance(years: 1, months: 1), tm.advance(weeks: 1.5))
p(tm.beginning_of_day, tm.end_of_day, tm.middle_of_day, tm.beginning_of_hour, tm.end_of_minute, tm.seconds_since_midnight)
p(tm.beginning_of_week, tm.end_of_week, tm.beginning_of_month, tm.end_of_quarter, tm.beginning_of_year, tm.next_weekday, tm.prev_weekday)
p(Time.days_in_month(2, 2024), Time.days_in_month(2, 2023), Time.days_in_year(2024), tm.on_weekend?, tm.ago(60), tm.since(60), tm.last_month, tm.next_quarter)
puts(tm.to_fs(:db), tm.to_fs(:rfc822), tm.to_fs(:long_ordinal), tm.formatted_offset, tm.formatted_offset(true, "UTC"))
d = Date.new(2024, 2, 29)
[d.advance(months: 1), d.change(day: 1), d.beginning_of_week, d.end_of_month, d.next_week, d.prev_occurring(:monday), d.days_ago(3), d.beginning_of_quarter].each { |x| puts(x.readable_inspect) }
puts(d.to_fs(:long), d.to_fs(:long_ordinal), d.to_fs(:db), d.to_fs(:rfc822), d.to_fs(:number), d.to_fs)
