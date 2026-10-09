require "set"
require_relative "ref/awesome_print"

def show(title, s)
  puts "--- #{title}"
  puts s
end

# arrays: indices right-aligned to the widest; nested containers one level deeper
show("array", AwesomePrint.ai([1, "two", :three, nil, true, false, 1.5], plain: true))
show("array of 11", AwesomePrint.ai(Array.new(11) { |i| i * i }, plain: true))
show("nested", AwesomePrint.ai([1, [2, [3, []]], {k: "v"}], plain: true))
show("no index", AwesomePrint.ai(["a", "b"], plain: true, index: false))

# hashes: keys aligned on =>; Symbol, String, Integer, Array keys; nested hash
h = {name: "alice", "age" => 30, 7 => "seven", [1, 2] => [3], :"foo bar" => nil, roles: [:admin, :dev]}
show("hash", AwesomePrint.ai(h, plain: true))
show("hash ruby19", AwesomePrint.ai(h, plain: true, ruby19_syntax: true))
show("hash sorted", AwesomePrint.ai(h, plain: true, sort_keys: true))
show("hash in hash", AwesomePrint.ai({a: 1, bb: {ccc: 2, d: {e: [1, 2]}}, f: {}}, plain: true))
show("hash in array", AwesomePrint.ai([{x: 1, long_key: 2}, {}], plain: true))

# indent: 2, 0 (left-aligned after the indent), -4 (left-aligned keys)
show("indent 2", AwesomePrint.ai({a: 1, bbb: [1, 2]}, plain: true, indent: 2))
show("indent 0", AwesomePrint.ai({a: 1, bbb: [1, 2]}, plain: true, indent: 0))
show("indent -4", AwesomePrint.ai({a: 1, bbb: {cc: 2}}, plain: true, indent: -4))

# one line
show("single line", AwesomePrint.ai({a: [1, 2], b: {c: :d}}, plain: true, multiline: false))
show("single line array", AwesomePrint.ai([1, [2, 3]], plain: true, multiline: false))

# empty containers and scalars
show("empties", AwesomePrint.ai([[], {}, Set[], ""], plain: true))
show("scalars", AwesomePrint.ai([42, -1.5, Rational(1, 3), Complex(1, 2), 1..3, /re/i, "s\n", :sym, nil, true, false], plain: true))
show("string", AwesomePrint.ai("plain", plain: true))
show("integer", AwesomePrint.ai(7, plain: true))
show("nil", AwesomePrint.ai(nil, plain: true))

# Sets print as Arrays, Tuples as Arrays, Records as Hashes, Struct values in one piece
S = Struct.new(:x, :y)
show("set", AwesomePrint.ai(Set[1, 2, 3], plain: true))
show("tuple", AwesomePrint.ai([1, "a"], plain: true))
show("record", AwesomePrint.ai({x: 1, y: [2]}, plain: true))
show("struct", AwesomePrint.ai([S.new(1, [2, 3])], plain: true))

# colours: the gem's ANSI codes (shown with p so the escapes are visible)
p AwesomePrint.ai([1, "s", :sym, nil, true, false, 1.5, Rational(1, 2), 1..2])
p AwesomePrint.ai({a: 1, "b" => []})
p AwesomePrint.ai({a: S.new(1, 2)}, ruby19_syntax: true)
p AwesomePrint.ai({a: 1}, multiline: false)

# ap prints and gives the value back
r = AwesomePrint.ap([1, {a: 2}], plain: true)
p r
r2 = AwesomePrint.ap({k: "v"}, plain: true, indent: 2, ruby19_syntax: true)
p r2 == {k: "v"}
