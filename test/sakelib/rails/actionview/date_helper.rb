gem "actionview", "8.1.3"
require "action_view"
require "active_support/core_ext"
# A record (ActiveModel's interface: ModelNaming::Model)
class Event
  attr_reader :id, :starts_at
  def initialize(id, starts_at) = (@id, @starts_at = id, starts_at)
  def to_key = @id ? [@id] : nil
end





view = ActionView::Base.empty
V = view
from = Time.utc(2026, 10, 20, 12, 0, 0)

# distance_of_time_in_words
[0, 3, 7, 15, 30, 50, 61, 89, 300, 2700, 5400, 7200, 86400, 172800, 2592000, 5184000, 31536000, 47304000, 63072000, 94608000, 315360000].each do |secs|
  puts "#{secs}: #{V.distance_of_time_in_words(from, from + secs)} | #{V.distance_of_time_in_words(from, from + secs, include_seconds: true)}"
end
puts V.distance_of_time_in_words(from + 3600, from)
puts V.distance_of_time_in_words(Date.new(2026, 1, 1), Date.new(2026, 3, 1))
puts V.distance_of_time_in_words(0, 3600)
puts V.time_ago_in_words(Time.utc(1990, 1, 1))
puts V.relative_time_in_words(Time.utc(1990, 1, 1))
puts V.relative_time_in_words(Time.utc(2990, 1, 1))
begin
  V.distance_of_time_in_words(:x, from)
rescue ArgumentError => e
  puts e.message
end
# time_tag
puts V.time_tag(Date.new(2026, 10, 20))
puts V.time_tag(from)
puts V.time_tag(from, "Right now", class: "t")
puts V.time_tag(Date.new(2026, 10, 20), format: :short)
puts V.time_tag(Date.new(2026, 10, 20)) { "in a block" }
# the selects
d = Date.new(2026, 10, 20)
t = Time.utc(2026, 10, 20, 14, 35, 9)
puts V.select_year(d, { start_year: 2024, end_year: 2028 })
puts V.select_year(d, { start_year: 2028, end_year: 2026, prefix: "event", field_name: "y" })
puts V.select_month(d, { use_month_numbers: true })
puts V.select_month(d, { add_month_numbers: true, include_blank: true })
puts V.select_month(d, { use_short_month: true, prompt: "Choose" })
puts V.select_month(d, { month_format_string: "%{name} (%{number})", use_two_digit_numbers: false })
puts V.select_day(d, { use_two_digit_numbers: true, prompt: true })
puts V.select_day(7, { use_hidden: true })
puts V.select_hour(t, { ampm: true, start_hour: 9, end_hour: 17 })
puts V.select_minute(t, { minute_step: 15 }, { class: "m" })
puts V.select_second(t)
puts V.select_date(d, { order: [:month, :day, :year], prefix: "payday", date_separator: "/" })
puts V.select_date(d, { discard_day: true, with_css_classes: true })
puts V.select_date({ year: 2026, month: 2, day: 9 }, { prompt: { day: "Choose day", month: "Choose month", year: "Choose year" } })
puts V.select_time(t, { include_seconds: true })
puts V.select_time(t, { ignore_date: true, time_separator: ":" })
puts V.select_datetime(t, { start_year: 2025, end_year: 2027, prefix: "start" })
puts V.select_datetime(t, { discard_year: true, disabled: true, namespace: "ns" })
begin
  V.select_year(d, { start_year: 1, end_year: 5000 })
rescue ArgumentError => e
  puts e.message
end
# date_select / time_select / datetime_select for a record
event = Event.new(1, Time.utc(2026, 12, 24, 18, 30, 0))
puts V.date_select("event", :starts_at, { object: event, start_year: 2026, end_year: 2027 })
puts V.time_select("event", :starts_at, { object: event, minute_step: 30 })
puts V.datetime_select("event", :starts_at, { object: event, start_year: 2026, end_year: 2026, discard_minute: true }, { class: "dt" })
puts V.date_select("event", :starts_at, { object: event, order: [:day, :month], start_year: 2026, end_year: 2027, index: 3 })
puts V.date_select("event", :starts_at, { selected: Date.new(2027, 1, 2), start_year: 2026, end_year: 2027, discard_type: true })
