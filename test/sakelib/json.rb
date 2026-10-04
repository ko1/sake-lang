require "json"

# parse: every kind of value
doc = JSON.parse("{\"name\": \"Sake\", \"tags\": [\"a\", \"b\"], \"n\": 3, \"f\": 2.5, \"ok\": true, \"no\": false, \"x\": null}")
p doc
p JSON.parse("[1, -0, -0.0, 1e2, 1E-2, 12345678901234567890, 0.1]")
p JSON.parse("\"a\\u00e9\\n\\t\\\"\\\\\\/\\ud83d\\ude00\"")
p JSON.parse(" \t\n 2 ")
p JSON.parse("null")
p JSON.parse("[]")
p JSON.parse("{}")
p JSON.parse("{\"a\": 1, \"a\": 2}")
p JSON.parse("/* comment */ [1, // line\n 2]")
p JSON.parse("\"日本語\"")

# options
p JSON.parse("{\"a\": {\"b\": [1, {\"c\": 2}]}}", symbolize_names: true)
p JSON.parse("[NaN, Infinity, -Infinity]", allow_nan: true)
p JSON.parse("[1, 2,]", allow_trailing_comma: true)
p JSON.parse("{\"a\": 1,}", allow_trailing_comma: true)
p JSON.parse("[[[1]]]", max_nesting: 3)

# a typical use: read a config and use its values
cfg = JSON.parse("{\"server\": {\"host\": \"localhost\", \"port\": 8080}, \"users\": [\"ko1\", \"matz\"]}")
if cfg in Hash
  server = cfg["server"]
  if server in Hash
    port = server["port"]
    puts "port + 1 = #{port + 1}" if port in Integer
  end
  users = cfg["users"]
  puts users.join(", ") if users in Array
end

# errors
bad = ["", " ", "[1,]", "{\"a\":1,}", "[01]", "[.5]", "[1.]", "[NaN]", "[-Infinity]", "x",
            "[1 ", "[1 2]", "{\"a\" 1}", "{\"a\":1, \"b\" 2}", "{1:2}", "{", "[", "{\"a\":", "{\"a\"",
            "\"abc", "\"a\nb\"", "\"\\x\"", "\"ab\\\n\"", "\"\\u12\"", "\"\\ud800\"", "\"ab\\ud800x\"",
            "\"\\ud800\\u0041\"", "[1]]", "nulx", "tru", "[truex]", "-", "--1", "1.5e", "-a",
            "/x", "/*", "é", "[1,\n  éa]", " [1,2]  \n x", "x" * 40, "{\"a\":1 x}",
            "[\"日本\", tru]", "{\"é\": \"\\é\"}", "[\"あ\\", "[\"日\t本\"]", "[\"日本\" // c\n, 1 /* x */, \"\\u00e9\\ud83d\\ude00\"]",
            "\"日本\\u12\"", "/* 日本 */ [1] x", "[\"日本語のとても長い文字列がここにあります\" x]"]
bad.each do |s|
  begin
    v = JSON.parse(s)
    puts "parsed: #{v.inspect}"
  rescue JSON::ParserError => e
    puts "ParserError: #{e.message}"
  end
end
begin
  JSON.parse("[" * 102 + "]" * 102)
rescue JSON::ParserError => e
  puts "NestingError: #{e.message}"
end
deep_ok = JSON.parse("[" * 101 + "]" * 101)
p deep_ok.size if deep_ok in Array
begin
  JSON.parse("[[[1]]]", max_nesting: 2)
rescue JSON::ParserError => e
  puts "NestingError: #{e.message}"
end

# generate
puts JSON.generate(doc)
puts JSON.generate([1.0, 1e20, 1.5e-7, 123456789.123, 0.1, -0.0, 1e16, 1e15, 1e-5, 0.000123, 2.5e-10, 1.0e100, 12.5, 2 ** 70, -3])
puts JSON.generate(["a/b", "\u0001\u001f\b\f\n\r\t\"\\", "\u007f", "é日本", "\u2028"])
puts JSON.generate({1 => 2, nil => 3, a: 4, "s" => :sym})
puts JSON.generate(1..3)
puts JSON.generate([[], {}, [1, "tuple"]])
puts JSON.generate(nil)
puts JSON.fast_generate([1, {"a" => "b"}])
puts JSON.generate("plain")
begin
  JSON.generate([0.0 / 0.0])
rescue JSON::GeneratorError => e
  puts "GeneratorError: #{e.message}"
end
begin
  JSON.generate({"x" => 1.0 / 0.0})
rescue JSON::GeneratorError => e
  puts "GeneratorError: #{e.message}"
end
puts JSON.generate([0.0 / 0.0, -1.0 / 0.0], allow_nan: true)
begin
  JSON.generate([255.chr])
rescue JSON::GeneratorError => e
  puts "GeneratorError: #{e.message}"
end
puts JSON.generate([227, 129, 130].pack("C*"))
deep = [1]
100.times { deep = [deep] }
begin
  JSON.generate(deep)
rescue JSON::ParserError => e
  puts "NestingError: #{e.message}"
end
puts JSON.generate({"a" => [1, 2]}, space: " ", object_nl: " ")

# pretty_generate
puts JSON.pretty_generate({"a" => [], "b" => {}, "c" => [1, {"d" => nil, "e" => "x"}]})
puts JSON.pretty_generate([])
puts JSON.pretty_generate(1)
puts JSON.pretty_generate({"a" => 1, "b" => [2]}, indent: "\t", space_before: " ")

# dump / load
puts JSON.dump({"n" => 0.0 / 0.0})
p JSON.load("[1, NaN]")
p JSON.load(nil)
p JSON.load("")

# to_json
puts({"k" => [1, 2]}.to_json)
puts ["x", nil].to_json
puts "q\"".to_json
puts 42.to_json
puts 1.5.to_json

# round trip
src = "{\"a\":[1,2.5,\"x\",null,true,{\"b\":[]}],\"c\":\"\\u00e9\\n\"}"
puts JSON.generate(JSON.parse(src))
p JSON.parse(JSON.pretty_generate(JSON.parse(src))) == JSON.parse(src)

# keyword arguments of load_file and fast_generate
path = "json_test_tmp.json"
File.write(path, "{\"k\": [1, 2,]}")
p JSON.load_file(path, symbolize_names: true, allow_trailing_comma: true)
File.delete(path)
puts JSON.fast_generate([1, 2], array_nl: " ")

# keyword arguments: any order, defaults kept, max_nesting: false for no limit
puts JSON.pretty_generate({"a" => [1]}, array_nl: "", indent: "")
puts JSON.generate([[[1]]], max_nesting: false, space: " ")
p JSON.parse("[[[[1]]]]", max_nesting: nil, symbolize_names: false)
begin
  JSON.generate([[1]], max_nesting: 1)
rescue JSON::NestingError => e
  puts "NestingError: #{e.message}"
end
