gem "activesupport", "8.1.3"
require "active_support"
require "active_support/core_ext"

# String (core_ext/string): filters, access, indent, starts_ends_with, exclude, strip
puts "== string"
p("  Hello \n  World  ".squish, "Hello World".remove(/o/, "l"), "Once upon a time in a world far far away".truncate(27, separator: " "))
p("Once upon a time in a world".truncate_words(4), "🔪🔪🔪🔪".truncate_bytes(9), "abc".truncate_bytes(10))
p("hello".at(1), "hello".from(2), "hello".to(2), "hello".first(3), "hello".last(2))
p("foo\nbar".indent(2), "rails".starts_with?("ra"), "rails".exclude?("x"), "    a\n      b\n".strip_heredoc)
p("  \n".blank?, "x".present?, "".presence, nil.blank?, [].blank?, 0.blank?, { a: 1 }.present?)
s = +"  dirty  "
s.squish!
p(s)

# Array (core_ext/array): access, grouping, conversions, wrap, extract_options, extract
puts "== array"
xs = (1..7).to_a
p(xs.second, xs.forty_two, xs.from(5), xs.to(1), xs.including(8), xs.excluding(1, 2))
p(xs.in_groups_of(3), xs.in_groups_of(3, false), xs.in_groups(2), xs.split(4))
(1..4).to_a.in_groups_of(2) { |g| p(g) }
p(["ruby", "rails", "sake"].to_sentence, ["a", "b"].to_sentence(two_words_connector: " or "), [1, 2].map { |i| Struct.new(:id).new(i) }.to_fs(:db), [].to_fs(:db))
p(Array.wrap(nil), Array.wrap([1]), Array.wrap("x"))
args = [1, 2, { verbose: true }]
p(args.extract_options!, args, [1].extract_options!)
nums = (1..10).to_a
odd = nums.extract! { |n| n % 2 == 1 }
p(odd, nums)

# Enumerable (core_ext/enumerable)
puts "== enumerable"
people = [{ name: "ann", age: 30 }, { name: "bob", age: 25 }, { name: "cy", age: 30 }]
p(people.index_by { |x| x[:name] }.keys, ["a", "b"].index_with { |x| x.upcase }, people.many?, people.many? { |x| x[:age] == 25 })
p(people.pluck(:name), people.pluck(:name, :age), people.pick(:name), [1, "", nil, [], "x"].compact_blank)
p(["ccc", "a", "bb"].minimum(:size), ["ccc", "a", "bb"].maximum(:size), [1, 2].exclude?(3), [42].sole)
p(["b", "c", "a"].in_order_of(:itself, ["a", "b"]), [1, 2, 3].without(2))

# Hash (core_ext/hash)
puts "== hash"
h = { a: 1, b: { c: 2, d: { e: 3 } } }
p(h.deep_merge(b: { d: { f: 4 } }), { a: 1 }.reverse_merge(a: 2, b: 3), { x: 1 }.with_defaults(y: 2))
p({ a: 1 }.stringify_keys, { "a" => 1 }.symbolize_keys, h.deep_stringify_keys, h.deep_transform_values { |v| v * 10 })
p({ "x" => [{ "y" => 1 }] }.deep_symbolize_keys, { a: "", b: 1 }.compact_blank, { a: 1 }.assert_valid_keys(:a, :b))
begin
  { a: 1, z: 2 }.assert_valid_keys([:a, :b])
rescue ArgumentError => e
  puts e.message
end

# Object (core_ext/object): deep_dup, inclusion, to_query / to_param
puts "== object"
orig = { "list" => ["a", { "b" => "c" }] }
copy = orig.deep_dup
inner = copy["list"]
inner.push("d")
p(orig, copy)
p(1.in?([1, 2]), 5.in?(1..3), "lo".in?("hello"), "x".presence_in(["x", "y"]), "z".presence_in(["x"]))
begin
  1.in?(2)
rescue ArgumentError => e
  puts e.message
end
p(nil.to_param, true.to_param, 12.to_param, [1, "a b", nil].to_param)
p({ name: "David", nationality: "Danish" }.to_query, { user: { name: "ann", roles: ["admin", "dev"] }, empty: [], q: "a&b" }.to_query)
p({ a: 1 }.to_query("ns"), [].to_query("k"), "x y".to_query("q"), { b: 2, a: 1 }.to_param)

# Integer and Numeric (core_ext/integer, core_ext/numeric)
puts "== numeric"
p(21.ordinalize, 10.multiple_of?(5), 2.kilobytes, 1.megabyte, 1.5.kilobytes, 3.in_milliseconds)
p(1234567.to_fs(:delimited), 5551234.to_fs(:phone), 1234.5.to_fs(:currency), 1234567.to_fs(:human_size), 1234567.to_fs(:human))
