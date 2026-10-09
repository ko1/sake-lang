require "pp"

def show(v, width)
  puts("--- width #{width}")
  PP.pp(v, $stdout, width)
end

# nested Hash and Array at several widths (Ruby 3.4's `k: v` / `"k" => v` style)
v = {a: 1, "k" => [1, 2, 3], nested: {x: [1, 2], y: "str"}, s: :sym, n: nil, f: 1.5, t: true}
show(v, 79)
show(v, 40)
show(v, 20)
show(v, 1)
show([1, [2, [3, [4, 5]]]], 10)
show([{name: "alice", roles: [:admin, :dev]}, {name: "bob", roles: []}], 30)
show(Array.new(30) { |i| i }, 40)

# scalars and the containers that fall back to inspect
show(42, 10)
show(-1.5, 10)
show(nil, 10)
show(true, 10)
show(:sym, 10)
show(1..5, 10)
show(Rational(1, 3), 10)
show(Complex(1, 2), 10)
show("plain", 3)
show("日本語", 2)

# empty containers; Tuples print as Arrays; a Record as a Hash of Symbol keys (one line)
show([], 1)
show({}, 1)
show(Set[], 1)
show("", 1)
show([1, "two", :three], 79)
show({x: 1, y: "s"}, 79)
show([[1, 2], [3, 4]], 8)

# Sets break like Arrays
show(Set[1, 2, 3], 79)
show(Set[1, 2, 3], 8)
show(Set["aaaa", "bbbb", Set[1, 2]], 15)

# Strings: several lines are written one per line, joined by +
show("line1\nline2\nline3", 79)
show("line1\nline2\nline3", 10)
show(["a\nb", "c"], 79)
show(["a\nb", "c"], 5)
show("ends with newline\n", 5)
show("long string " * 5, 20)

# odd Symbol keys are quoted when they must be, operator keys as Ruby writes them
show({:"foo bar" => 1, :"a=" => 2, :+ => 3, :a? => 4, :a! => 5, :"@x" => 6, :"$g" => 7, :A => 8}, 30)
show({nil => 1, 1.5 => 2, [1, 2] => 3, "s" => 4, true => 5}, 25)

# Struct values are one piece (Kernel.inspect); long Hash values break after the key
S = Struct.new(:x, :y)
show(S.new(1, [1, 2, 3]), 79)
show({key: ["a" * 10, "b" * 10], other: S.new(1, 2)}, 30)

# output to a String (appended, returned), to IO.stdout (returned)
buf = +"pre:"
r = PP.pp({a: [1, 2]}, buf, 8)
p(r)
p(r == buf)
p(PP.pp(1, $stdout, 79) == $stdout)
# default width is 79
PP.pp(Array.new(20) { |i| "item#{i}" }, $stdout)
PP.pp(Array.new(20) { |i| "item#{i}" })

# singleline_pp: everything on one line, no newline; pretty_inspect: the String with its newline
p(PP.singleline_pp({a: [1, 2], b: {c: 3}}, +""))
PP.singleline_pp([1, 2])
puts("")
p({a: 1}.pretty_inspect)
p(PP.pp(Array.new(12) { |i| i }, +"", 20))
p(PP.pp([1, 2], +"", 5))   # Ruby: pretty_inspect; pp_to_s is this port's name

# PP.format would give a PrettyPrint, which has no `pp`: build a PP (Sake: PrettyPrint.format)
def pp_format(width)
  q = PP.new(+"", width)
  yield q
  q.flush
  q.output
end

# a type's own pretty printing: Ruby's `def pretty_print(q)`, called directly
class Point
  attr_reader :x, :y
  def initialize(x, y)
    @x = x
    @y = y
  end

  def pretty_print(q)
    q.group(1, "#<Point", ">") do
      q.breakable
      q.text("x=")
      q.pp(@x)
      q.comma_breakable
      q.text("y=")
      q.pp(@y)
    end
  end
end
pt = Point.new([1, 2, 3], {k: "v"})
puts(pp_format(79) { |q| pt.pretty_print(q) })
puts(pp_format(12) { |q| pt.pretty_print(q) })

# seplist with another separator; comma_breakable; pp_hash on its own
puts(pp_format(10) { |q| q.seplist([1, 2, 3], lambda { q.text(";"); q.breakable }) { |e| q.pp(e * 100) } })
puts(pp_format(15) { |q| q.pp_hash({1 => [1, 2], 2 => []}) })

# an error inside the block is raised through format; what was written before it stays
out = +""
begin
  PrettyPrint.format(out, 79) do |q|
    q.text("before")
    raise ArgumentError, "stop"
  end
rescue ArgumentError => e
  puts("ArgumentError: #{e.message}")
end
p(out)
