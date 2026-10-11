# Sake cheat sheet (for Ruby programmers and language models)

Sake is Ruby syntax where **every operation names its type**: `String.upcase(s)`, never `s.upcase`.
Run: `bin/sake FILE.sake` (`-c` checks only). Exit 0 ok, 1 runtime error, 2 rejected before running.
`--strict=N`: 0 names/arity/syntax only; 1 (default) + wrong types and a `rescue` of what is never
raised; 2 + a maybe-nil value used unchecked (except the nil of a miss: `x[k]`, `Array.first/last/
pop/shift/min/max/minmax/at/slice/dig`, `Hash.dig`, `Set.first/min/max`); 3 + those misses and a non-exhaustive literal `case`; 4 + a `raise` never rescued.
Part 1 gives the rules; Part 2 lists every built-in operation (only those exist).

## Part 1. Rules

### Calls
- Built-in and user operations: `Type.op(subject, args...)`. Chain form: `x.T.op(args)` is `T.op(x, args)`.
  A call on a value (`s.strip`, `xs.size`, `3.times`, `1.to_s`, `x.nil?`) is rejected.
- Kernel functions are called bare: `puts print p pp format sprintf gets loop raise rand srand sleep
  exit warn system at_exit Integer(s) Float(s) Rational(..) Complex(..) dup(x) block_given? once ARGV`.
  `format` is Kernel only (no `String.format`); `"%d-%s" % [a, b]` also works.
- Names are Ruby's: `Integer.to_s`, `String.include?`, `Array.each_with_index`. Not every Ruby
  arity exists: no `Array.min(xs, n)`, `Array.sort` takes no block (use `sort_by`, or `Comparable`),
  `Array.reduce`/`inject` **require** the initial value. Check Part 2 before using a name.
- In-place forms exist (`Array.map!`, `sort!`, `uniq!`, `Hash.merge!`, `String.upcase!`, ...). A
  container has one element type for the whole program, so `Array.map!(xs) { Integer.to_s(it) }`
  makes `xs` hold Integer|String; to change the type, use `Array.map` (a new Array).
- `Arithmetic.round(x)` (and `floor ceil truncate abs to_f to_i zero?`) accept Integer|Float|Rational;
  `Float.round(x, 2)` needs a Float.

```ruby
s = "  Hello World  "
puts(String.upcase(String.strip(s)))
puts(s.String.strip.String.downcase)
puts(String.split("b a c", " ").Array.sort.Array.join(","))
p(Array.reduce(Array[1, 2, 3], 0) { |acc, x| acc + x })
p(format("%05.1f|%-3s|%3d", 3.14159, "a", 7), Integer.to_s(255, 16))
```

### Literals (the #1 source of errors)
- `[a, b]` is a **Tuple** (fixed length, per-position types). `[]` cannot grow.
- `Array[a, b]` / `Array[]` is a growable Array. `Integer[]`, `String[]`, `Float[]`, `Tuple[]`,
  `Point[]` make an Array whose element type is checked on every write. `Point[1, 2]` is NOT `Point.new`.
- `{k: v}` is a **Record** (read with a pattern `r => {k:}`; no field writes). `{}` and `{"a" => 1}` are errors.
- `Hash["a" => 1]`, `Hash[]`, `Hash.new(0)` make a Hash. `Hash.new { ... }` is rejected.
- `Set[1, 2]`, `1..5`, `1...n`, `1..`, `:sym`, `/re/i`, `2r`, `"a#{x}"` as in Ruby. `Regexp.new(s, "i")`.
- No `%w[]`/`%i[]`, no `<<` on String or Array (use `s += t`, `Array.push(xs, x)`).
- No value constants: `LIMIT = 10` is rejected; write `def limit = 10`. Constants hold only
  `Struct.new` and `Exception.new`. `Math.PI` (also `Math::PI`), `Float.INFINITY`, `ARGV` are operations.

```ruby
t = [1, "one"]
n, w = t
xs = Array[3, 1]
Array.push(xs, 2)
fs = Float[]
Array.push(fs, 1.5)
r = {name: "ann", age: 3}
r => {name:, age:}
h = Hash["a" => 1]
h["b"] = 2
counts = Hash.new(0)
Array.each(String.split("a b a", " ")) { |k| counts[k] += 1 }
st = Set[1]
Set.add(st, 2)
p([n, w, xs, fs, name, age, h, counts, Set.include?(st, 2)])
```

### Reading input
- `gets` returns String or nil (it keeps the newline). There is no `$stdin`, `STDIN`, `ARGF`, `$<`.
- Whole stdin: `IO.read(IO.stdin)`; lines: `IO.readlines(IO.stdin)` or `IO.each_line(IO.stdin) { |l| }`.
  Files: `File.read(path)`, `File.readlines(path)`, `File.open(path, "w") { |io| IO.puts(io, s) }`.
- Output: `puts`, `print`, `p` (any number of arguments); `IO.puts(IO.stderr, msg)` or `warn(msg)` for stderr.
- Arguments: `ARGV` is an Array of Strings: `Array.fetch(ARGV, 0)`, `Array.first(ARGV)` (nil when absent).
  Environment: `ENV.fetch("HOME")`, `ENV.get("X")` (nil when unset).

```ruby
first = gets
n = first ? String.to_i(String.chomp(first)) : 0
while (line = gets)
  nums = String.split(String.chomp(line), " ").Array.map { |x| String.to_i(x) }
  p([n, Array.sum(nums)])
end
```

### Conversions and formatting
- `String.to_i(s)`, `String.to_f(s)` (lenient, as Ruby); `Integer(s)`, `Float(s)` (strict,
  raise ArgumentError). `Integer.to_s(n, [base])`, `Float.to_s(f)`, `Integer.to_f(n)`, `Float.to_i(f)`,
  `String.to_sym(s)`, `Symbol.to_s(sym)`, `Kernel.to_s(any)`, `Kernel.inspect(any)`.
- `7 / 2` is 3 (floors like Ruby); mixing Integer and Float gives Float; `Integer.fdiv(7, 2)` is 3.5.
  `"a" + 1` is a type error: interpolate (`"n=#{n}"`) or convert.
- `format("%.2f %5d %-8s", ...)`, `String.rjust(s, 3, "0")`, `String.ljust`, `String.center`.
- `Float.round(f)` gives an Integer; `Float.round(f, 2)` a Float.

```ruby
p(Integer("42") + String.to_i("7x"))
p(Float("1.5") + Integer.to_f(1))
p(Integer.to_s(255) + "!")
p(Float.round(3.14159, 2))
p(String.rjust(Integer.to_s(5), 3, "0"))
p(Integer.fdiv(7, 2))
q, r = Integer.divmod(7, 2)
p([q, r, 7 / 2, -7 / 2])
```

### Blocks
- Blocks go only to built-in operations and to your functions that `yield`. They are not values:
  no `proc`, `lambda`, `->`, `method(:f)`, `&:sym`, no stored blocks, no `Hash.new { }`.
  `&b` may only pass the function's own block on: `def f(xs, &b) = Array.map(xs, &b)`.
- `it` / `_1` name a single parameter. `|a, b|` destructures one Tuple/Array argument; `|(k, v), i|`
  and `|h, *rest|` work. `next v`, `break v`, and `return` (leaves the enclosing def) as in Ruby.
- `Enum` (the prelude) is Enumerable under a short name: `Enum.map(x) { }`, `select`, `reduce(x, init) { }`,
  `count`, `include?(x, v)`, `first`, `sort_by`, `group_by`, ... dispatch on x's type to Array, Hash, Set or
  Range (so `Enum.map(xs)` is `Array.map(xs)`); a class joins with `include Enum` and `def each(c) = ... yield(v)`.
- Hash blocks receive `[k, v]`: `Hash.each(h) { |k, v| }`. Without a block, `each_with_index`,
  `each_slice`, `each_cons` return an Array (no Enumerator). `loop { break v }` works.
- A function that `yield`s must be called with a block unless it checks `block_given?`
  (`return x unless block_given?`, or `block_given? && ...`).
- No `for`, no `begin ... end while`; use `while`, `until`, `Integer.times`, `Range.each`.

```ruby
def each_pair(a)
  Array.each(a) { |x| yield(x, x * x) }
end
def maybe(x)
  return yield(x) if block_given?
  x
end
def pass_on(xs, &b) = Array.map(xs, &b)
each_pair(Array[1, 2]) { |x, sq| p([x, sq]) }
p([maybe(1), maybe(1) { it + 1 }, pass_on(Array[1, 2]) { it * 10 }])
p(Array.each_with_index(Array["a", "b"]).Array.map { |c, i| "#{i}#{c}" })
p(Array.sort_by(Array[[2, "b"], [1, "c"]]) { |num, s| [-num, s] })
Hash.each(Hash["x" => 1]) { |k, v| puts("#{k}=#{v}") }
p(Array.each(Array[3, 12, 5]) { |x| break x if x > 10 })
```

### Functions, classes, fields
- `def f(a, b = 1, *rest, k: 2, **opts)`, `def f(x) = expr` (short expressions only); `return a, b` returns a Tuple.
  Top-level functions cannot see top-level locals. `*rest` is an Array, so its elements share one
  type; to keep a type per position, pass a Tuple (`f(["AAPL", 120])`). `f(**opts)` cannot pass
  keywords on (pass the Hash positionally).
- `class C` with `attr_reader x, y` / `attr_accessor n` / `attr_writer w` (names bare, not Symbols;
  `attr_accessor :next` only for reserved words) declares a type with fields in that order.
  `private attr_reader x` hides the reader outside the class. No field defaults (`attr_reader a = 1`
  is rejected); no code in the body. Namespaces nest: `class B` inside `module A` (or `class A::B`) is
  `A::B`, used as `A::B.f(x)`; inside `A`, a bare `B` means `A::B` when it exists.
- `C.new(x, y)` takes fields positionally (or by keyword: `C.new(1, y: 2)`; prefer keywords when
  there are several fields). Without `initialize` every field is required. `def initialize(c)`
  (exactly one parameter: the new instance, **not** the field values) runs after `new` stored the
  fields; with it, trailing fields may be left out and are nil until initialize sets them.
  `def initialize(x) = @x = x` is rejected: it would store the instance in its own field.
- Every function in a class is called `C.f(...)`; by convention the first argument is the instance.
  There is **no `self`**. `@x` means field `x` of the function's **first argument**; `@x = v`,
  `@x += v`, `@x ||= v` write it. `@x` outside a class function is rejected; no globals (`$x`).
- From anywhere: reader `C.x(v)` or `v.C.x`; writer (attr_accessor/attr_writer only)
  `C.set_x(v, w)` or `v.C.x = w` (also `v.C.x += 1`). `v.x` is rejected.
- `def C.f(c)` outside the class = `def f(c)` inside. `def self.f` is rejected: one name is one function.
- `Point = Struct.new(:x, :y)` = `class Point` with `attr_accessor x, y` (no block allowed).
- `to_s(c)` / `inspect(c)` in the class are used by `puts`/`"#{}"` and `p`. `==` compares fields.
- `class B < A` copies A's fields and functions into B; it is not inheritance (a B is not an A).
- For the checker, each `C.new` site is its own type: a `Stack` of Integers made at one place and a
  `Stack` of Strings made at another do not mix, and a generic wrapper (`Box.new(yield(@v))`) is one
  type per caller. Messages write such a type as `Stack@L12` only when the type has several sites.

```ruby
class Stack
  attr_reader items
  attr_accessor limit
  def initialize(s)
    @items = Integer[]
    @limit = 10 if @limit == nil
  end
  def push(s, x)
    Array.push(@items, x)
    s
  end
  def to_s(s) = "Stack(#{Array.join(@items, ",")})"
end
def Stack.top(s) = Array.last(Stack.items(s))
st = Stack.new
Stack.push(st, 1)
st.Stack.push(2)
Stack.set_limit(st, 5)
st.Stack.limit += 1
puts(st)
p([Stack.limit(st), Stack.new(Integer[], 3).Stack.limit, Stack.new(Integer[], limit: 4).Stack.limit])
t = Stack.top(st)
p(t + 1) if t
Point = Struct.new(:x, :y)
pt = Point.new(1, 2)
Point.set_x(pt, 5)
p(pt)
```

### Modules, operators for your types
- `module M` + `module_function`: plain functions `M.f(x)`. A module without `module_function` is a
  mixin: `include M` in a class copies its functions (they may call the includer's functions);
  `M.f(x)` dispatches to `x`'s type. A body of only `raise NotImplementedError` marks a required function.
- Operators: `include Comparable` + `def <=>(a, b)` gives `< <= > >= ==` and `Array.sort/min/max`;
  `include Arithmetic` + `def +(a, b)`; `include Indexable` + `def [](c, k)` / `def []=(c, k, v)`.
  A built-in on the left (`2 + money`) needs `def coerce(m, other) = [Money.new(other), m]` in Money
  (Ruby's protocol: the Tuple `[left, right]` is converted first, then the operator runs).
- `(A|B).f(x)` calls the `f` of x's type among the listed types (built-in types including `IO`, and
  classes; no nil). `*rest` is packed per branch; a function taking keywords cannot be listed.

```ruby
module Shape
  def area(s) = raise(NotImplementedError)
  def describe(s) = "area #{area(s)}"
end
class Sq
  attr_reader side
  include Shape
  include Comparable
  def area(q) = @side * @side
  def <=>(a, b) = @side <=> Sq.side(b)
end
class Money
  attr_reader cents
  include Arithmetic
  def +(a, b) = Money.new(@cents + Money.cents(b))
  def coerce(m, other) = [Money.new(other), m]
  def to_s(m) = "$#{@cents}"
end
module Util
  module_function
  def twice(x) = x * 2
end
class Log
  attr_reader lines
  def print(l, *xs)
    Array.push(@lines, Array.join(Array.map(xs) { Kernel.to_s(it) }, ""))
  end
end
def out(io, a, b) = (IO|Log).print(io, a, b)
p(Shape.describe(Sq.new(3)))
p([Sq.new(2) < Sq.new(3), Array.max(Array[Sq.new(2), Sq.new(5)]), Util.twice(4)])
puts(Money.new(5) + Money.new(3), 3 + Money.new(5))
log = Log.new(String[])
out(IO.stdout, "a", 1)
out(log, "b", 2)
puts("", Log.lines(log))
```

### Pattern matching (instead of `case/when`, `is_a?`)
- `case x` with `in Integer | Float then ...`, `in String`, `in nil`, `in :ok`, `in "s"`,
  `in {name:}`, `in [Integer, String]`, `in [a, b]` (binds), `in Point`, `else`. `case/when` is
  rejected. No `*rest` in Tuple patterns, no find patterns, pins, guards.
- `x in T` is a boolean test (parenthesize as an argument: `p((x in Integer))`).
- `x => T` asserts (raises NoMatchingPatternError) and narrows x; also clears nil.

```ruby
def kind(x)
  case x
  in Integer | Float then "num"
  in String then "str #{String.size(x)}"
  in nil then "nil"
  in {name:} then "rec #{name}"
  in [Integer, b] then "pair #{b}"
  in :ok then "ok"
  else "other"
  end
end
p(Array.map(Array[1, "s", nil, {name: "n"}, [1, "x"], :ok, 2.0]) { kind(it) })
v = Array.find(Array[1, 5]) { it > 3 }
v => Integer
p(v + 1)
```

### nil (what `--strict=2` rejects)
- Operations that may return nil: `gets`, `Array.find/index`, `String.index`, `String.match`,
  `Hash.delete`, `ENV.get`, a field never written, ... Using such a value in another operation
  without a check is rejected at level 2. The nil of a *miss* (`x[k]`, `Array.first/last/pop/
  shift/min/max/minmax/at/slice/dig`, `Hash.dig`, `Set.first/min/max` on an empty collection) is checked only at level 3.
- `Array.sort/min/max/sort_by/min_by/max_by` (and `Set`'s, `Tuple.max/min`) are rejected statically when the
  element (or key) types cannot all be compared with each other (`Array[1, "a"]`, a nil element).
- A **local variable** is narrowed by `if x`, `x ? a : b`, `x != nil`, `return unless x`,
  `next unless x`, `x && ...`, `x => T`, `case x in`. `x.nil?` is rejected: write `x == nil`.
- Defaults: `y = x || 0`, `Hash.fetch(h, k, 0)`, `Array.fetch(a, i, 0)`, `Hash.new(0)`.
- **Field reads are never narrowed** (fields are mutable): copy to a local first.
  `if Node.nxt(n) then Node.v(Node.nxt(n))` is rejected; `m = Node.nxt(n); Node.v(m) if m` is fine.

```ruby
Node = Struct.new(:v, :nxt)
def second(node)
  rest = Node.nxt(node)
  return 0 unless rest
  Node.v(rest)
end
n = Node.new(1, Node.new(2, nil))
p(second(n))
m = Node.nxt(Node.new(1, nil)) || Node.new(0, nil)
p(Node.v(m))
h = Hash["a" => 1]
p([Hash.fetch(h, "zz", 0) + 1, (h["a"] || 0) + 1])
i = String.index("abc", "c")
p(i + 1) if i != nil
```

### Exceptions
- Declare: `class E < StandardError` (or `< Exception`) with optional `attr_reader` fields after
  the implicit first field `message`; or `E = Exception.new(:code)`. No hierarchy: `rescue` lists
  every type it catches (`rescue A, B => e`); bare `rescue => e` catches all.
- `raise "msg"` (RuntimeError), `raise ArgumentError, "msg"` (only for types without extra fields),
  `raise E.new("msg", 7)`. Read: `Exception.message(e)`, `E.code(e)`. No `e.message`.
- `expr rescue fallback`, `def ... rescue ... end`, `ensure`, `retry` work. Built-ins:
  ArgumentError KeyError IndexError ZeroDivisionError RangeError IOError TypeError RuntimeError
  NoMatchingPatternError StopIteration ... (Part 2 lists them). Their messages are Ruby's.
- Level 1 rejects a `rescue` of a type the body never raises.

```ruby
class ParseError < StandardError
  attr_reader line
end
Oops = Exception.new(:code)
def parse(s)
  raise ParseError.new("empty", 1) if String.empty?(s)
  raise ArgumentError, "too long" if String.size(s) > 3
  raise Oops.new("neg", 7) if String.start_with?(s, "-")
  Integer(s)
end
Array.each(Array["", "1234", "-1", "12"]) do |s|
  begin
    p(parse(s))
  rescue ParseError => e
    puts("line #{ParseError.line(e)}: #{Exception.message(e)}")
  rescue ArgumentError => e
    puts(Exception.message(e))
  rescue Oops => e
    puts("code #{Oops.code(e)}")
  end
end
v = Integer("zz") rescue -1
p(v)
```

### Libraries
- `require "json"` loads `sakelib/json.sake` (or `json.sake` next to the file). Names are Ruby's
  with the subject first: `JSON.parse(s)`, `JSON.generate(h)`, `StringScanner.scan(ss, /\w+/)`.
  `require "sql/*"` reads every matching `.sake` file next to the requiring file, in name order.
- Ported: json csv yaml toml base64 digest strscan optparse shellwords set-like structures time date
  fileutils pathname tempfile stringio logger benchmark net_http uri cgi ipaddr webrick monitor
  timeout bigdecimal matrix prime securerandom erb; gems colorize thor rack httparty redis money
  jwt kramdown liquid i18n faker concurrent_ruby rspec minitest. Each has `sakelib/notes/NAME.md`.
- Tests with minitest: `suite = Minitest.suite("x")`, `Minitest.test(suite, "name") { |t|
  Minitest.assert_equal(t, want, got) }`, `Minitest.run(suite)`.

```ruby
require "json"
s = JSON.generate(Hash["a" => Array[1, 2]])
puts(s)
p(JSON.parse(s))
```

### Also rejected
`self`, `$globals`, `eval`/`send`/`define_method`/`respond_to?`-style reflection, `defined?`,
`&.`, `obj.method`, `Data.define`, `Struct.new(...) do`, `attr_reader :x` (Symbol form), `A::B` as a
value (a namespace is not a value), `def A::B.f`, `require` of a non-literal, `case/when`, `for`,
`%w[]`, writing a Record field, `<<` on String/Array, `f(**opts)`, `Integer.(a + b)`. Only the
operations listed in Part 2 exist.
