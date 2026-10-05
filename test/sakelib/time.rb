require "time"

# A parsed Time is shown with its own offset, whether it is UTC, and its zone name.
def show(t) = "#{t.iso8601(3)} utc=#{t.utc?} zone=#{t.zone.inspect}"

def try(label)
  puts "#{label} => #{yield}"
rescue ArgumentError => e
  puts "#{label} => ArgumentError: #{e.message}"
end

now = Time.new(2020, 5, 6, 7, 8, 9).getutc

puts "-- Time.parse"
[
  "2024-01-02 03:04:05 +09:00", "2024-01-02T03:04:05Z", "2024-01-02T03:04:05+00:00",
  "2024-01-02T03:04:05 UTC", "2024-01-02T03:04:05 GMT", "2024-01-02 03:04:05.5",
  "2024-01-02T03:04:05.123+05:30", "Sat, 01 Jan 2000 00:00:00 GMT", "Tue Jan  2 03:04:05 2024",
  "2 January 2024 10am", "20240102", "20240102T030405Z", "2024-01-02 12am", "2024-01-02 12pm",
  "2024-01-02 3pm", "2024-01-02 03:04 PST", "2024-01-02 03:04 -0800", "2024-01-02 03:04 -08",
  "2024-01-02 03:04:05 EST", "Jan 2, 2024 03:04:05", "2024/01/02 10:20", "2024-02-30",
  "2024-01-02 24:00:00", "2024-01-02 23:59:60", "10:20", "Jan 5", "1999-12-31", "5 Mar 99",
  "2024-13-01", "2024-01-02 25:00", "2024-01-02 23:60:00", "garbage", ""
].each do |s|
  try("parse #{s.inspect}") { show(Time.parse(s, now)) }
end
p Time.parse("2024-01-02 03:04:05.5").usec
p Time.parse("12:00").year == Time.now.year

puts "-- Time.strptime"
[
  ["2024-01-02 03:04", "%Y-%m-%d %H:%M"], ["x", "%Y"], ["1700000000", "%s"],
  ["02/Jan/2024:10:00:00 +0530", "%d/%b/%Y:%H:%M:%S %z"], ["2024-01-02 junk", "%Y-%m-%d"],
  ["2024 032", "%Y %j"], ["03:04 PM", "%I:%M %p"], ["12:30 am", "%I:%M %p"],
  ["2024-01-02 UTC", "%Y-%m-%d %Z"], ["2024-01-02 +0000", "%Y-%m-%d %z"],
  ["Tuesday January 2 24", "%A %B %e %y"], ["2024-01-02T03:04:05.123456", "%Y-%m-%dT%H:%M:%S.%N"],
  ["2024-01-02T03:04:05.123", "%FT%T.%L"], ["2024", "%Y"], ["13", "%m"], ["32", "%d"],
  ["2024-02-31", "%F"], ["1700000000 +0900", "%s %z"], ["01/02/24", "%D"], ["100%", "%Y%%"],
  ["2024-01-02", "%Y/%m/%d"]
].each do |s, f|
  try("strptime #{s.inspect} #{f.inspect}") { show(Time.strptime(s, f, now)) }
end
p Time.strptime("2024-01-02T03:04:05.123456", "%Y-%m-%dT%H:%M:%S.%N").usec

puts "-- Time.xmlschema (Ruby's Time.iso8601)"
[
  "2024-01-02T03:04:05Z", "2024-01-02T03:04:05", "2024-01-02T03:04:05.123+01:00",
  "2024-01-02T03:04:05+0530", "2024-01-02T03:04:05+05", " 2024-01-02T03:04:05.5Z ",
  "2024-02-31T00:00:00Z", "2024-01-02", "2024-13-02T00:00:00Z", "2024-01-02T25:00:00Z"
].each do |s|
  try("xmlschema #{s.inspect}") { show(Time.xmlschema(s)) }
end
p Time.xmlschema("2024-01-02T03:04:05.123+01:00").nsec

puts "-- Time.httpdate / rfc2822"
[
  "Sat, 01 Jan 2000 00:00:00 GMT", "Saturday, 01-Jan-00 00:00:00 GMT", "Sat Jan  1 00:00:00 2000",
  "Sat, 01 Jan 2000 00:00:00 +0900"
].each do |s|
  try("httpdate #{s.inspect}") { show(Time.httpdate(s)) }
end
[
  "Sat, 01 Jan 2000 00:00:00 +0900", "01 Jan 2000 00:00 -0000", "Sat, 01 Jan 2000 00:00:00 EST",
  "Sat, 1 Jan 00 00:00:00 +0000", "1 Jan 99 00:00 Z", "31 Feb 2024 00:00 +0000", "bad"
].each do |s|
  try("rfc2822 #{s.inspect}") { show(Time.rfc2822(s)) }
end
p Time.rfc822("Sat, 01 Jan 2000 00:00:00 GMT") == Time.rfc2822("Sat, 01 Jan 2000 00:00:00 GMT")

puts "-- formatting"
u = (Time.new(2024, 1, 2, 3, 4, 5) + Rational(123456, 1000000)).getutc
p u.iso8601
p u.xmlschema
p u.xmlschema(3)
p u.xmlschema(9)
p u.httpdate
p u.rfc2822
p u.rfc822
l = Time.at(0)
p l.rfc2822
p l.httpdate
p l.xmlschema
p Time.at(1.5).getutc.iso8601(2)
p Time.httpdate(u.httpdate).httpdate == u.httpdate
p Time.xmlschema(u.xmlschema(6)).to_i == u.to_i
p Time.rfc2822(u.rfc2822) == Time.at(u.to_i).getutc

puts "-- Time.zone_offset"
["EST", "pdt", "+09:00", "-0530", "+05", "JST", "Z", "UTC", "A", "Y", "+1:00"].each do |z|
  p Time.zone_offset(z)
end

puts "-- fixed offsets"
j = Time.new(2024, 1, 2, 3, 4, 5, "+09:00")
p j
p j.xmlschema
p j.xmlschema(2)
p j.rfc2822
p j.httpdate
p j.strftime("%Y-%m-%d %H:%M %z %:z")
p Time.xmlschema(j.xmlschema) == j
p Time.rfc2822(j.rfc2822) == j
p Time.parse(j.to_s).utc_offset
p Time.parse("2024-06-01 12:00 -0330").getlocal("+02:00")
p Time.at(0, in: "-05:00").xmlschema
p Time.strptime("2024-01-02 03:04 +0530", "%Y-%m-%d %H:%M %z").utc_offset
p Time.strptime("1700000000 +0900", "%s %z").hour
