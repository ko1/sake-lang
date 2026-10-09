require "active_support/all"

# The same program as active_support_core_ext.sake, with ActiveSupport itself.
puts "== core_ext"
p "  x ".blank?, "".blank?, " \t\n".blank?, nil.blank?, false.blank?, true.blank?, [].blank?, {}.blank?, 0.blank?, "a".present?, "".presence, "a".presence, [].presence, :"".blank?, :a.blank?, Time.now.blank?, (1..2).blank?
p " foo   bar \n  \t  boo".squish, "foo bar".remove("o"), "foo bar".remove("o", /b/), "Once upon a time in a world far far away".truncate(27), "Once upon a time in a world far far away".truncate(27, separator: " "), "Once upon a time in a world far far away".truncate(27, separator: /\s/), "And they found that many people were sleeping better.".truncate(25, omission: "... (continued)"), "short".truncate(10), "abc".truncate(3), "abcd".truncate(3)
p "Once upon a time in a world far far away".truncate_words(4), "Once<br>upon<br>a<br>time<br>in<br>a<br>world".truncate_words(5, separator: "<br>"), "And they found that many people were sleeping better.".truncate_words(5, omission: "... (continued)"), "a b".truncate_words(5), "a  b  c".truncate_words(2), "a b c".truncate_words(2, separator: /\s+/)
p "  foo\n    bar".indent(2), "foo\n\nbar".indent(2), "foo\n\nbar".indent(2, nil, true), "foo\n\tbar".indent(2), "foo\nbar".indent(2, "\t"), "\tfoo".indent(1), "".indent(2)
p "hello".first, "hello".first(2), "hello".first(0), "hello".first(10), "hello".last, "hello".last(3), "hello".last(10), "hello".at(0), "hello".at(-1), "hello".at(10), "hello".from(2), "hello".from(-2), "hello".from(10), "hello".to(2), "hello".to(-2), "hello".to(10), "hello".to(-10), "hello".starts_with?("he"), "hello".ends_with?("lo")
p "hello world".upcase_first, "Hello".downcase_first, "".upcase_first, "posts".singularize, "post".pluralize, "ActiveModel".underscore, "active_model".camelize, "active_model".camelize(:lower), "active_model".titleize, "employee_salary".humanize, "a_b".dasherize, "Admin::Post".demodulize, "Admin::Post".deconstantize, "Post".foreign_key, "Post".tableize, "posts".classify, "Donald Knuth".parameterize, "Hello World".squish, "x".indent(2)
puts "== array"
p %w(1 2 3 4 5 6 7 8 9 10).in_groups_of(3), %w(1 2 3 4 5 6 7 8 9 10).in_groups_of(3, "&nbsp;"), %w(1 2 3 4 5 6 7).in_groups_of(3, false), [1,2,3].in_groups_of(1), [].in_groups_of(2)
begin; [1].in_groups_of(0); rescue ArgumentError => e; puts e.message; end
p %w(1 2 3 4 5 6 7 8 9 10).in_groups(3), %w(1 2 3 4 5 6 7 8 9 10).in_groups(3, "&nbsp;"), %w(1 2 3 4 5 6 7).in_groups(3, false), [1,2,3].in_groups(5), [].in_groups(2)
p [1, 2, 3, 4, 5].split(3), (1..10).to_a.split { |i| i % 3 == 0 }, [1, 2, 3].split(9), [1, 1].split(1), [].split(1)
p ["one", "two", "three"].to_sentence, ["one", "two"].to_sentence, ["one"].to_sentence, [].to_sentence, ["one", "two", "three"].to_sentence(words_connector: " or ", last_word_connector: " or at least "), ["one", "two"].to_sentence(two_words_connector: " & "), [1, nil, :a].to_sentence
a = [1, 2, 3, 4, 5, 6]
p a.second, a.third, a.fourth, a.fifth, a.forty_two, a.second_to_last, a.third_to_last, [1].second, a.from(2), a.from(10), a.from(-2), a.to(2), a.to(-2), a.to(10), a.including(7, 8), a.including([7, 8]), a.excluding(2, 3), a.without([1, 2]), a.exclude?(3), a.exclude?(9)
p [1, "", nil, 2, " ", [], {}, false, true].compact_blank, [1,2].many?, [1].many?, [].many?, [1,2,3].many? { |x| x > 1 }, [1,2,3].many? { |x| x > 2 }, [1].sole, [1,2,3].sum, [1,2,3].index_by { |x| x * 2 }, [1,2,3].index_with { |x| x.to_s }, [1,2].index_with(0), [[1,2],[3,4]].pluck(0), [{a: 1}, {a: 2}].pluck(:a), [{a: 1, b: 2}].pluck(:a, :b), [{a: 1}, {a: 2}].pick(:a), [].pick(:a), [1,2,3].minimum(:to_s), [[1, 2], [3]].deep_dup, [1, 2, 3].in_order_of(:itself, [3, 1]), [1, 2, 3].in_order_of(:itself, [3, 1], filter: false), [1,2,2].excluding(2), [[1],[2]].excluding([1])
begin; [].sole; rescue => e; puts "#{e.class}: #{e.message}"; end
begin; [1,2].sole; rescue => e; puts "#{e.class}: #{e.message}"; end
puts "== hash"
h1 = { a: 100, b: 200, c: { c1: 100 } }
h2 = { b: 250, c: { c1: 200 } }
p h1.deep_merge(h2), h1.deep_merge(h2) { |key, this_val, other_val| this_val + other_val }, { a: 1 }.deep_merge({ a: { b: 2 } }), { a: { b: 2 } }.deep_merge({ a: 1 }), h1
p({ a: 1 }.reverse_merge(a: 0, b: 2), { a: 1 }.with_defaults(b: 2), { name: "Rob", years: "28" }.stringify_keys, { "name" => "Rob", 1 => 2, :y => 3 }.symbolize_keys, { person: { name: "Rob", years: "28" }, list: [{ a: 1 }] }.deep_stringify_keys, { "person" => { "name" => "Rob", "list" => [{ "a" => 1 }] }, 1 => 2 }.deep_symbolize_keys, { a: 1, b: { c: 2 }, d: [3] }.deep_transform_keys { |k| k.to_s.upcase }, { a: 1, b: { c: 2 }, d: [3] }.deep_transform_values { |v| v * 10 })
p({ a: "", b: nil, c: 1, d: [], e: false, f: " " }.compact_blank, { a: 1 }.blank?, {}.blank?, { a: 1 }.present?)
begin; { a: 1, z: 2 }.assert_valid_keys(:a, :b); rescue ArgumentError => e; puts e.message; end
p({ a: 1 }.assert_valid_keys(:a, :b))
orig = { a: [1, { b: "s" }], "k" => Set[1] }
copy = orig.deep_dup
copy[:a][1][:b] << "x"; copy[:a] << 2
p orig, copy
puts "== integer / numeric"
p 1.ordinalize, 22.ordinalize, 113.ordinalize, -3.ordinal, 9.multiple_of?(3), 10.multiple_of?(3), 0.multiple_of?(0), 5.multiple_of?(0), 2.in_milliseconds, 1.5.in_milliseconds
puts "== duration"
t = Time.new(2024, 1, 31, 12, 30, 15, "+09:00")
d = 2.hours
p d, d.to_i, d.to_s, d.value, d.parts, d.inspect, 1.minute, 90.seconds, 2.days, 1.week, 2.fortnights, 3.months, 1.year, 1.5.hours, (1.hour + 30.minutes), (1.hour + 30.minutes).inspect, (2.days - 1.hour), (1.day * 3), (6.hours / 2), 1.hour + 60, 1.hour == 3600, 1.hour == 60.minutes, 2.hours > 1.hour, [3.hours, 1.hour].min, 1.hour <=> 3600, 1.day.in_hours, 90.minutes.in_hours, 1.year.in_days, 2.weeks.in_days, 1.hour.in_minutes, 1.day.in_seconds, 1.year.in_months, 1.month.in_weeks
p 2.hours.since(t), 2.hours.from_now(t), 2.hours.ago(t), 2.hours.until(t), 1.day.since(t), 1.month.since(t), 1.month.ago(t), 1.year.since(t), 13.months.since(t), 2.weeks.ago(t), 1.day.ago(Time.new(2024, 3, 1, 0, 0, 0, "+09:00")), (1.month + 2.days + 3.hours).since(t), 1.year.ago(Time.new(2024, 2, 29, 12, 0, 0, "+09:00")), 1.5.days.since(t), 90.seconds.since(t), (1.day + 60).since(t), 1.hour.before(t), 1.hour.after(t), 0.5.weeks.since(t)
p ActiveSupport::Duration.build(31556952), ActiveSupport::Duration.build(2716146), ActiveSupport::Duration.build(2716146).parts, ActiveSupport::Duration.build(0), ActiveSupport::Duration.build(-3661), ActiveSupport::Duration.build(3661).inspect, ActiveSupport::Duration.build(3661).iso8601, 1.hour.iso8601, (1.day + 2.hours).iso8601, 1.month.iso8601, 1.5.hours.iso8601, 0.seconds.iso8601, ActiveSupport::Duration.build(90061).iso8601, (-1.hour).iso8601, 1.year.iso8601, 2.weeks.iso8601, (1.week + 1.day).iso8601
p ActiveSupport::Duration.parse("P1Y2M3DT4H5M6S"), ActiveSupport::Duration.parse("P1Y2M3DT4H5M6S").parts, ActiveSupport::Duration.parse("PT1.5H").parts, ActiveSupport::Duration.parse("P2W").parts, ActiveSupport::Duration.parse("-PT1H").parts
begin; ActiveSupport::Duration.parse("1 hour"); rescue => e; puts "#{e.class}: #{e.message}"; end
