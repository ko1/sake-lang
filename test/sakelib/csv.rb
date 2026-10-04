require "csv"

def show(label, v)
  puts "#{label}: #{v.inspect}"
end

def try_parse(s)
  show("parse #{s.inspect}", CSV.parse(s))
rescue CSV::MalformedCSVError => e
  puts "MalformedCSVError: #{e.message} (#{e.line_number})"
end

puts "== parse"
show("basic", CSV.parse("a,b,c\n1,2,3\n"))
show("empty fields", CSV.parse("a,,b\n\"\",x\n\nc"))
show("empty", CSV.parse(""))
show("newline only", CSV.parse("\n"))
show("trailing blank", CSV.parse("a\n\n"))
show("quotes", CSV.parse("\"a,b\",\"say \"\"hi\"\"\",\"multi\nline\"\nnext,row"))
show("crlf", CSV.parse("a,b\r\nc,d\r\n"))
show("cr", CSV.parse("a,b\rc,d"))
show("unicode", CSV.parse("名前,値\n日本,\"東京, 大阪\"\n"))
show("spaces kept", CSV.parse(" a , b "))
try_parse("\"a")
try_parse("a\"b,c")
try_parse("\"a\"b")
try_parse("a,b\r\nc\nd")
try_parse("x\n\"a\nb")
try_parse("a\nb\"c")

puts "== options"
show("col_sep ;", CSV.parse("a;b\nc;d", col_sep: ";"))
show("col_sep tab", CSV.parse("a\tb c\td", col_sep: "\t"))
show("col_sep space", CSV.parse("a b  c", col_sep: " "))
show("col_sep ||", CSV.parse("a||b|c", col_sep: "||"))
show("quote_char", CSV.parse("'a,b',c", quote_char: "'"))
show("row_sep", CSV.parse("a,b|c,d|", row_sep: "|"))
show("skip_blanks", CSV.parse("a\n\nb\n", skip_blanks: true))
show("skip_lines", CSV.parse("a,b\n#x\nc", skip_lines: /\A#/))
show("numeric", CSV.parse("1,2.5,\"3\", 4 ,0x1A,1_000,1e3,abc,,-7", converters: :numeric))
show("integer", CSV.parse("1,2.5,x", converters: :integer))
show("float", CSV.parse("1,2.5,x", converters: :float))
show("list", CSV.parse("1,2.5,x", converters: [:float, :integer]))
show("nil/empty value", CSV.parse("x,,\"\"", nil_value: "N", empty_value: "E"))
rows = CSV.parse("10,20\n30,x", converters: :numeric)
total = 0
rows.each do |r|
  r.each { |v| total += v if v in Integer }
end
show("sum", total)

puts "== parse_line"
show("line", CSV.parse_line("a,\"b,c\",,d"))
show("line empty", CSV.parse_line(""))
show("line two rows", CSV.parse_line("a,b\nc,d"))
show("line opts", CSV.parse_line("1;x", col_sep: ";", converters: :numeric))
show("parse_csv", "x,y".parse_csv)

puts "== headers"
t = CSV.parse("name,age,city\nAlice,30,Tokyo\nBob,25\n\nCarol,41,Osaka,extra\n", headers: true)
show("table", t)
show("headers", t.headers)
show("size", t.size)
t.each do |row|
  show("row", row)
  show("  to_h", row.to_h)
  show("  fields", row.fields)
end
r = t[0]
show("r[name]", r["name"])
show("r[1]", r[1])
show("r[zz]", r["zz"])
show("fetch", r.fetch("city"))
begin
  r.fetch("zz")
rescue KeyError => e
  puts "KeyError: #{e.message}"
end
show("header?", r.header?("age"))
show("field?", r.field?("Tokyo"))
show("index", r.index("city"))
show("values_at", r.values_at("city", "name"))
r["age"] = "31"
r["zip"] = "100"
show("set", r)
show("row size", r.size)
show("row to_s", r.to_s)
show("delete", r.delete("zip"))
r.each { |h, v| puts "  #{h}=#{v}" }
show("column", t["age"])
show("to_a", t.to_a)
show("to_csv", t.to_csv)
show("names", t.map { |row| row["name"] })
show("select", t.select { |row| row["city"] != nil }.map { |row| row["name"] })
show("find", t.find { |row| row["name"] == "Bob" })
show("only header", CSV.parse("a,b", headers: true).headers)
show("only header to_a", CSV.parse("a,b", headers: true).to_a)
show("empty headers", CSV.parse("", headers: true).headers)
show("given headers", CSV.parse("1,2\n3,4", headers: ["x", "y"]).to_a)
show("string headers", CSV.parse("1,2", headers: "p,q").to_a)
nums = CSV.parse("A b,C-d,n\n1,x,2.5\n", headers: true, converters: :numeric, header_converters: :symbol)
show("symbol headers", nums[0])
show("num col", nums[:n])
show("downcase", CSV.parse("Ab,CD\n1,2", headers: true, header_converters: :downcase).headers)
t << ["Dave", "50", "Nagoya"]
show("pushed", t.to_a)
show("delete col", t.delete("city"))
show("after delete", t.headers)
t["age"] = "0"
show("set col", t["age"])

puts "== generate"
show("line", CSV.generate_line(["a", nil, "", "x,y", "q\"", 1, 2.5, "l\nb", :sym]))
show("tuple line", CSV.generate_line(["a", 1]))
show("to_csv", ["a", nil].to_csv)
show("line opts", CSV.generate_line(["a", "b;c"], col_sep: ";", row_sep: "\r\n"))
show("force_quotes", CSV.generate_line([nil, "x"], force_quotes: true))
show("quote_empty", CSV.generate_line(["", "a b", " x"], quote_empty: false))
show("unicode", CSV.generate_line(["日本", "東京, 大阪"]))
s = CSV.generate do |csv|
  csv << [1, "a,b"]
  csv << ["x"]
  csv << []
end
show("generate", s)
s2 = CSV.generate(headers: ["h1", "h2"], write_headers: true) do |csv|
  csv << {"h2" => 2, "h1" => 1}
  csv << CSV::Row.new(["a", "b"], [3, 4])
end
show("generate headers", s2)
show("generate_lines", CSV.generate_lines([["a", "b"], ["c", nil]]))
show("roundtrip", CSV.parse(CSV.generate_line(["a\"b", "c,d", "e\nf", ""])))

puts "== files"
path = "/tmp/sakelib_csv_test.csv"
CSV.open(path, "w") do |csv|
  csv << ["id", "name", "score"]
  csv << [1, "Alice", 90.5]
  csv << [2, "Bob, Jr.", 72]
end
CSV.open(path, "a") { |csv| csv << [3, "Carol", 88] }
show("file", File.read(path))
show("read", CSV.read(path))
show("readlines", CSV.readlines(path))
CSV.foreach(path) { |row| show("foreach", row) }
CSV.foreach(path, headers: true, converters: :numeric) { |row| show("foreach h", row) }
show("read opts", CSV.read(path, converters: :integer))
tab = CSV.table(path)
show("table", tab)
show("table scores", tab[:score])
show("table sum", tab[:score].map { |v| (v in Integer | Float) ? v : 0 }.sum)
begin
  CSV.read("/nonexistent/x.csv")
rescue SystemCallError => e
  puts "IOError"
end

puts "== phase 2: options as the last argument"
show("parse_line rest unparsed", CSV.parse_line("a,b\n\"c"))
show("generate_lines opts", CSV.generate_lines([["a", "b"], ["c", nil]], col_sep: "\t"))
show("readlines opts", CSV.readlines(path, converters: :numeric))
show("multi-line quoted", CSV.parse("\"a\nb\",c\nd,\"e\n\nf\"\ng"))
try_parse("\"a\nb\",c\nd,\"e\n\nf\"x\ng")
try_parse("x\n\"a\nb\"\nc,\"d")
show("|| with quotes", CSV.parse("\"a||b\"||c||\"\"", col_sep: "||"))
show("quote_char |", CSV.parse("|a,b|,|c||d|", quote_char: "|"))
show("skip_lines crlf", CSV.parse("#a\r\nb\r\n#c\r\n\"d\r\ne\"\r\nf", skip_lines: /\A#/))

puts "== keyword arguments"
show("kw order", CSV.parse("1|'a|b'", quote_char: "'", converters: :integer, col_sep: "|"))
show("kw generate_line", CSV.generate_line(["a|b", nil], quote_char: "'", col_sep: "|", force_quotes: true))
show("kw generate", CSV.generate(col_sep: "\t", row_sep: "\r\n") { |csv| csv << ["a", "b c"] })
CSV.open(path, "w", col_sep: ";", headers: ["k", "v"], write_headers: true) { |csv| csv << ["x", "1;2"] }
show("kw open", File.read(path))
CSV.foreach(path, col_sep: ";", headers: true) { |row| show("kw foreach", row) }
show("kw readlines", CSV.readlines(path, col_sep: ";", skip_lines: /\Ak/))
show("kw generate str", CSV.generate("h\n", col_sep: ";") { |csv| csv << ["a", "b"] })

puts "== IO and optional blocks"
iopath = "csv_test_io.tmp"
show("open value", CSV.open(iopath, "w") { |csv| csv.add_row(["a", 1]); csv << ["b", nil]; :done })
w = CSV.open(iopath, "a", force_quotes: true)
w.puts(["c", "x;y"])
show("open no block", w)
p(w.close)
show("open file", File.read(iopath))
show("foreach value", CSV.foreach(iopath, "r") { |row| show("foreach mode", row) })
show("parse block value", CSV.parse("h,i\n1,2\n") { |row| show("parse row", row) })
CSV.parse("h,i\n1,2\n", headers: true) { |row| show("parse h row", row) }
puts "ArgumentError: reading"   # the Sake port reads only through read/foreach
File.delete(iopath)
