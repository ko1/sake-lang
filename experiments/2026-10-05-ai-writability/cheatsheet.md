# Sake cheat sheet (for Ruby programmers)

Sake is Ruby syntax where **every operation names its type**: `String.upcase(s)`, never `s.upcase`.
Run: `bin/sake FILE.sake` (`-c` checks only). Exit 0 ok, 1 runtime error, 2 rejected before running.
`--strict=N`: 0 names/arity/syntax only; 1 (default) + wrong types; 2 + a maybe-nil value used
unchecked; 3 + unchecked `x[k]` results and non-exhaustive literal `case`; 4 + `raise` never rescued.

## Part 1. Rules

### Calls
- Built-in and user operations: `Type.op(subject, args...)`. Chain form: `x.T.op(args)` is `T.op(x, args)`.
  A call on a value (`s.strip`, `xs.size`, `3.times`, `1.to_s`, `x.nil?`) is rejected.
- Kernel functions are called bare: `puts print p pp format sprintf gets loop raise rand sleep exit
  warn Integer(s) Float(s) Rational(..) dup(x) block_given? once ARGV`. `p` takes **one** argument.
  `format` is Kernel only (no `String.format`); `"%d-%s" % [a, b]` also works.
- Names are Ruby's: `Integer.to_s`, `String.include?`, `Array.each_with_index`. Not every Ruby
  arity exists: no `Integer.to_s(n, base)`, no `Array.min(xs, n)`, `Array.sort` takes no block
  (use `sort_by`, or `Comparable`), `Array.reduce`/`inject` **require** the initial value.
- `Arithmetic.round(x)` (and `floor ceil truncate abs to_f to_i zero?`) accept Integer|Float|Rational;
  `Float.round(x, 2)` needs a Float.

```ruby
s = "  Hello World  "
puts(String.upcase(String.strip(s)))
puts(s.String.strip.String.downcase)
puts(String.split("b a c", " ").Array.sort.Array.join(","))
p(Array.reduce(Array[1, 2, 3], 0) { |acc, x| acc + x })
p(format("%05.1f|%-3s|%3d", 3.14159, "a", 7))
```

### Literals (the #1 source of errors)
- `[a, b]` is a **Tuple** (fixed length, per-position types). `[]` cannot grow.
- `Array[a, b]` / `Array[]` is a growable Array. `Integer[]`, `String[]`, `Float[]`, `Tuple[]`,
  `Point[]` make an Array whose element type is checked on every write. `Point[1, 2]` is NOT `Point.new`.
- `{k: v}` is a **Record** (read with a pattern `r => {k:}`; no field writes). `{}` and `{"a" => 1}` are errors.
- `Hash["a" => 1]`, `Hash[]`, `Hash.new(0)` make a Hash. `Hash.new { ... }` is rejected.
- `Set[1, 2]`, `1..5`, `1...n`, `1..`, `:sym`, `/re/`, `2r`, `"a#{x}"` as in Ruby.
- No `%w[]`/`%i[]`, no `<<` on String or Array (use `s += t`, `Array.push(xs, x)`).
- No value constants: `LIMIT = 10` is rejected; write `def limit = 10`. Constants hold only
  `Struct.new`. `Math.PI`, `Float.INFINITY`, `ARGV` are operations.

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
- Output: `puts`, `print`, `p`; `IO.puts(IO.stderr, msg)` or `warn(msg)` for stderr.

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
  raise ArgumentError). `Integer.to_s(n)`, `Float.to_s(f)`, `Integer.to_f(n)`, `Float.to_i(f)`,
  `String.to_sym(s)`, `Symbol.to_s(sym)`, `Kernel.to_s(any)`.
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
- Hash blocks receive `[k, v]`: `Hash.each(h) { |k, v| }`. Without a block, `each_with_index`,
  `each_slice`, `each_cons` return an Array (no Enumerator). `loop { break v }` works.
- A function that `yield`s must be called with a block unless it checks `block_given?`.
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
- `def f(a, b = 1, *rest, k: 2, **opts)`, `def f(x) = expr`; `return a, b` returns a Tuple.
  Top-level functions cannot see top-level locals.
- `class C` with `attr_reader x, y` / `attr_accessor n` / `attr_writer w` (names bare, not Symbols;
  `attr_accessor :next` only for reserved words) declares a type with fields in that order.
  `private attr_reader x` hides the reader outside the class. No field defaults (`attr_reader a = 1`
  is rejected); no nested classes/modules, no `A::B`, no constants or code in the body.
- `C.new(x, y)` takes fields positionally (or by keyword: `C.new(1, y: 2)`). Without `initialize`
  every field is required. `def initialize(c)` (exactly one parameter) runs after `new` stored the
  fields; with it, trailing fields may be left out and are nil until initialize sets them.
- Every function in a class is called `C.f(...)`; by convention the first argument is the instance.
  There is **no `self`**. `@x` means field `x` of the function's **first argument**; `@x = v`,
  `@x += v`, `@x ||= v` write it. `@x` outside a class function is rejected; no globals (`$x`).
- From anywhere: reader `C.x(v)` or `v.C.x`; writer (attr_accessor/attr_writer only)
  `C.set_x(v, w)` or `v.C.x = w` (also `v.C.x += 1`). `v.x` is rejected.
- `def C.f(c)` outside the class = `def f(c)` inside. `def self.f` is rejected.
- `Point = Struct.new(:x, :y)` = `class Point` with `attr_accessor x, y` (no block allowed).
- `to_s(c)` / `inspect(c)` in the class are used by `puts`/`"#{}"` and `p`. `==` compares fields.
- `class B < A` copies A's fields and functions into B; it is not inheritance (a B is not an A).

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
  mixin: `include M` in a class borrows its functions (they may call the includer's functions);
  `M.f(x)` dispatches to `x`'s type. A body of only `raise NotImplementedError` marks a required function.
- Operators: `include Comparable` + `def <=>(a, b)` gives `< <= > >= ==` and `Array.sort/min/max`;
  `include Arithmetic` + `def +(a, b)`; `include Indexable` + `def [](c, k)` / `def []=(c, k, v)`.
- `(A|B).f(x)` calls the `f` of x's type among the listed types.

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
module Util
  module_function
  def twice(x) = x * 2
end
p(Shape.describe(Sq.new(3)))
p([Sq.new(2) < Sq.new(3), Array.max(Array[Sq.new(2), Sq.new(5)]), Util.twice(4)])
```

### Pattern matching (instead of `case/when`, `is_a?`)
- `case x` with `in Integer | Float then ...`, `in String`, `in nil`, `in :ok`, `in "s"`,
  `in {name:}`, `in Point`, `else`. `case/when` is rejected. No array/find patterns, pins, guards.
- `x in T` is a boolean test (parenthesize as an argument: `p((x in Integer))`).
- `x => T` asserts (raises NoMatchingPatternError) and narrows x; also clears nil.

```ruby
def kind(x)
  case x
  in Integer | Float then "num"
  in String then "str #{String.size(x)}"
  in nil then "nil"
  in {name:} then "rec #{name}"
  in :ok then "ok"
  else "other"
  end
end
p(Array.map(Array[1, "s", nil, {name: "n"}, :ok, 2.0]) { kind(it) })
v = Array.find(Array[1, 5]) { it > 3 }
v => Integer
p(v + 1)
```

### nil (what `--strict=2` rejects)
- Operations that may return nil: `gets`, `Array.first/last/min/max/pop/shift/find/at`,
  `String.index`, `String.match`, `Hash.delete`, `x[k]` (checked at level 3 only), ... Using such a
  value in another operation without a check is rejected at level 2.
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
  ArgumentError KeyError IndexError ZeroDivisionError RangeError IOError TypeError RuntimeError ...
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

### Also rejected
`self`, `$globals`, `eval`/`send`/`define_method`/`respond_to?`-style reflection, `defined?`,
`&.`, `obj.method`, `Data.define`, `Struct.new(...) do`, `attr_reader :x` (Symbol form), nested
`class`/`module`, `require` of a non-literal, `case/when`, `for`, `%w[]`, writing a Record field,
`<<` on String/Array. Bang variants (`upcase!`, `sort!`, `map!`) do not exist; only the
operations listed in Part 2 exist (in-place ones: `push`, `delete_if`, `keep_if`, `concat`, ...).

## Part 2. Operations

`x` is the subject (an argument of the namespace's type), `[T]` an optional argument, `*T` any
number of them, `{ }` a required block, and `[{ }]` an optional one.

### Arithmetic

- `Arithmetic.abs(Integer|Float|Rational)`
- `Arithmetic.ceil(Integer|Float|Rational, [Integer])`
- `Arithmetic.floor(Integer|Float|Rational, [Integer])`
- `Arithmetic.round(Integer|Float|Rational, [Integer])`
- `Arithmetic.to_f(Integer|Float|Rational)`
- `Arithmetic.to_i(Integer|Float|Rational)`
- `Arithmetic.truncate(Integer|Float|Rational, [Integer])`
- `Arithmetic.zero?(Integer|Float|Rational)`

### Array

- `Array.!=(x, Any)`
- `Array.*(x, Any)`
- `Array.+(x, Any)`
- `Array.-(x, Any)`
- `Array.<(x, Any)`
- `Array.<=(x, Any)`
- `Array.<=>(x, Any)`
- `Array.==(x, Any)`
- `Array.>(x, Any)`
- `Array.>=(x, Any)`
- `Array.[](x, Any, [Integer])`
- `Array.[]=(x, Any, Any)`
- `Array.all?(x) { }`
- `Array.any?(x) { }`
- `Array.append(x, *Any)`
- `Array.at(x, Integer)`
- `Array.bsearch(x) { }`
- `Array.chunk_while(x) { }`
- `Array.clear(x)`
- `Array.collect(x) { }`
- `Array.combination(x, Integer)`
- `Array.compact(x)`
- `Array.concat(x, Array)`
- `Array.count(x, [Any]) [{ }]`
- `Array.delete(x, Any)`
- `Array.delete_at(x, Integer)`
- `Array.delete_if(x) { }`
- `Array.detect(x) { }`
- `Array.difference(x, *Array)`
- `Array.drop(x, Integer)`
- `Array.drop_while(x) { }`
- `Array.dup(x)`
- `Array.each(x) { }`
- `Array.each_cons(x, Integer) [{ }]`
- `Array.each_entry(x) { }`
- `Array.each_index(x) { }`
- `Array.each_slice(x, Integer) [{ }]`
- `Array.each_with_index(x) [{ }]`
- `Array.each_with_object(x, Any) { }`
- `Array.empty?(x)`
- `Array.fetch(x, Integer, [Any])`
- `Array.fill(x, Any)`
- `Array.filter(x) { }`
- `Array.filter_map(x) { }`
- `Array.find(x) { }`
- `Array.find_all(x) { }`
- `Array.find_index(x) { }`
- `Array.first(x, [Integer])`
- `Array.flat_map(x) { }`
- `Array.flatten(x)`
- `Array.group_by(x) { }`
- `Array.include?(x, Any)`
- `Array.index(x, Any)`
- `Array.inject(x, Any) { }`
- `Array.insert(x, Integer, *Any)`
- `Array.intersect?(x, Array)`
- `Array.intersection(x, *Array)`
- `Array.join(x, [String])`
- `Array.keep_if(x) { }`
- `Array.last(x, [Integer])`
- `Array.length(x)`
- `Array.map(x) { }`
- `Array.max(x)`
- `Array.max_by(x) { }`
- `Array.min(x)`
- `Array.min_by(x) { }`
- `Array.minmax(x)`
- `Array.minmax_by(x) { }`
- `Array.new(Integer, [Any]) [{ }]`
- `Array[*Any]`
- `Array.none?(x) { }`
- `Array.one?(x) { }`
- `Array.pack(x, String)`
- `Array.partition(x) { }`
- `Array.permutation(x, [Integer])`
- `Array.pop(x)`
- `Array.product(x, Array)`
- `Array.push(x, *Any)`
- `Array.reduce(x, Any) { }`
- `Array.reject(x) { }`
- `Array.reverse(x)`
- `Array.reverse_each(x) { }`
- `Array.rindex(x, Any)`
- `Array.rotate(x, [Integer])`
- `Array.sample(x)`
- `Array.select(x) { }`
- `Array.shift(x)`
- `Array.shuffle(x)`
- `Array.size(x)`
- `Array.slice_when(x) { }`
- `Array.sort(x)`
- `Array.sort_by(x) { }`
- `Array.sum(x, [Integer|Float|Rational|Complex]) [{ }]`
- `Array.take(x, Integer)`
- `Array.take_while(x) { }`
- `Array.tally(x)`
- `Array.to_h(x)`
- `Array.to_set(x)`
- `Array.transpose(x)`
- `Array.union(x, *Array)`
- `Array.uniq(x)`
- `Array.unshift(x, *Any)`
- `Array.values_at(x, *Integer)`
- `Array.zip(x, *Array)`

### Complex

- `Complex.!=(x, Any)`
- `Complex.*(x, Any)`
- `Complex.**(x, Any)`
- `Complex.+(x, Any)`
- `Complex.-(x, Any)`
- `Complex./(x, Any)`
- `Complex.==(x, Any)`
- `Complex.abs(x)`
- `Complex.arg(x)`
- `Complex.conjugate(x)`
- `Complex.imaginary(x)`
- `Complex[*Any]`
- `Complex.polar(x)`
- `Complex.real(x)`
- `Complex.rectangular(x)`
- `Complex.to_s(x)`

### Dir

- `Dir.children(String)`
- `Dir.each_child(String) { }`
- `Dir.empty?(String)`
- `Dir.entries(String)`
- `Dir.exist?(String)`
- `Dir.glob(String|Array, [base: String])`
- `Dir.home([String])`
- `Dir.mkdir(String, [Integer])`
- `Dir.mktmpdir([String], [String]) [{ }]`
- `Dir.pwd()`
- `Dir.rmdir(String)`
- `Dir.unlink(String)`

### File

- `File.absolute_path(String, [String])`
- `File.absolute_path?(String)`
- `File.atime(String)`
- `File.basename(String, [String])`
- `File.chmod(Integer, *String)`
- `File.delete(String)`
- `File.directory?(String)`
- `File.dirname(String, [Integer])`
- `File.empty?(String)`
- `File.executable?(String)`
- `File.exist?(String)`
- `File.expand_path(String, [String])`
- `File.extname(String)`
- `File.file?(String)`
- `File.ftype(String)`
- `File.identical?(String, String)`
- `File.join(*String|Array)`
- `File.link(String, String)`
- `File.mtime(String)`
- `File.open(String, [String]) [{ }]`
- `File.read(String)`
- `File.readable?(String)`
- `File.readlines(String)`
- `File.readlink(String)`
- `File.realpath(String, [String])`
- `File.rename(String, String)`
- `File.size(String)`
- `File.split(String)`
- `File.symlink(String, String)`
- `File.symlink?(String)`
- `File.unlink(String, *String)`
- `File.utime(Time|Nil, Time|Nil, *String)`
- `File.writable?(String)`
- `File.write(String, String)`
- `File.zero?(String)`

### Float

- `Float.!=(x, Any)`
- `Float.%(x, Any)`
- `Float.*(x, Any)`
- `Float.**(x, Any)`
- `Float.+(x, Any)`
- `Float.-(x, Any)`
- `Float./(x, Any)`
- `Float.<(x, Any)`
- `Float.<=(x, Any)`
- `Float.<=>(x, Any)`
- `Float.==(x, Any)`
- `Float.>(x, Any)`
- `Float.>=(x, Any)`
- `Float.EPSILON()`
- `Float.INFINITY()`
- `Float.MAX()`
- `Float.MIN()`
- `Float.NAN()`
- `Float.abs(x)`
- `Float.between?(x, Float, Float)`
- `Float.ceil(x)`
- `Float.clamp(x, Float, Float)`
- `Float.divmod(x, Float)`
- `Float.fdiv(x, Integer|Float|Rational)`
- `Float.finite?(x)`
- `Float.floor(x)`
- `Float.infinite?(x)`
- `Float.magnitude(x)`
- `Float.modulo(x, Integer|Float|Rational)`
- `Float.nan?(x)`
- `Float.negative?(x)`
- `Float[*Any]`
- `Float.next_float(x)`
- `Float.positive?(x)`
- `Float.prev_float(x)`
- `Float.quo(x, Integer|Float|Rational)`
- `Float.rationalize(x)`
- `Float.round(x, [Integer])`
- `Float.to_f(x)`
- `Float.to_i(x)`
- `Float.to_r(x)`
- `Float.to_s(x)`
- `Float.truncate(x)`
- `Float.zero?(x)`

### Hash

- `Hash.!=(x, Any)`
- `Hash.==(x, Any)`
- `Hash.[](x, Any)`
- `Hash.[]=(x, Any, Any)`
- `Hash.all?(x) { }`
- `Hash.any?(x) { }`
- `Hash.clear(x)`
- `Hash.compact(x)`
- `Hash.count(x) [{ }]`
- `Hash.default(x)`
- `Hash.delete(x, Any)`
- `Hash.delete_if(x) { }`
- `Hash.detect(x) { }`
- `Hash.dig(x, Any)`
- `Hash.drop(x, Integer)`
- `Hash.dup(x)`
- `Hash.each(x) { }`
- `Hash.each_key(x) { }`
- `Hash.each_pair(x) { }`
- `Hash.each_value(x) { }`
- `Hash.each_with_object(x, Any) { }`
- `Hash.empty?(x)`
- `Hash.except(x, *Any)`
- `Hash.fetch(x, Any, [Any])`
- `Hash.fetch_values(x, *Any)`
- `Hash.filter(x) { }`
- `Hash.filter_map(x) { }`
- `Hash.find(x) { }`
- `Hash.first(x)`
- `Hash.flat_map(x) { }`
- `Hash.group_by(x) { }`
- `Hash.has_key?(x, Any)`
- `Hash.has_value?(x, Any)`
- `Hash.include?(x, Any)`
- `Hash.inject(x, Any) { }`
- `Hash.invert(x)`
- `Hash.keep_if(x) { }`
- `Hash.key(x, Any)`
- `Hash.key?(x, Any)`
- `Hash.keys(x)`
- `Hash.length(x)`
- `Hash.map(x) { }`
- `Hash.max_by(x) { }`
- `Hash.member?(x, Any)`
- `Hash.merge(x, Hash)`
- `Hash.min_by(x) { }`
- `Hash.new([Any])`
- `Hash[*Any]`
- `Hash.none?(x) { }`
- `Hash.one?(x) { }`
- `Hash.partition(x) { }`
- `Hash.reduce(x, Any) { }`
- `Hash.reject(x) { }`
- `Hash.select(x) { }`
- `Hash.shift(x)`
- `Hash.size(x)`
- `Hash.slice(x, *Any)`
- `Hash.sort_by(x) { }`
- `Hash.store(x, Any, Any)`
- `Hash.sum(x, [Integer|Float|Rational|Complex]) { }`
- `Hash.take(x, Integer)`
- `Hash.to_a(x)`
- `Hash.transform_keys(x) { }`
- `Hash.transform_values(x) { }`
- `Hash.update(x, Hash)`
- `Hash.value?(x, Any)`
- `Hash.values(x)`
- `Hash.values_at(x, *Any)`

### IO

- `IO.!=(x, Any)`
- `IO.==(x, Any)`
- `IO.close(x)`
- `IO.closed?(x)`
- `IO.each_line(x) { }`
- `IO.eof?(x)`
- `IO.flush(x)`
- `IO.gets(x)`
- `IO.print(x, *Any)`
- `IO.puts(x, *Any)`
- `IO.read(x)`
- `IO.readlines(x)`
- `IO.stderr()`
- `IO.stdin()`
- `IO.stdout()`
- `IO.write(x, String)`

### Integer

- `Integer.!=(x, Any)`
- `Integer.%(x, Any)`
- `Integer.&(x, Any)`
- `Integer.*(x, Any)`
- `Integer.**(x, Any)`
- `Integer.+(x, Any)`
- `Integer.-(x, Any)`
- `Integer./(x, Any)`
- `Integer.<(x, Any)`
- `Integer.<<(x, Any)`
- `Integer.<=(x, Any)`
- `Integer.<=>(x, Any)`
- `Integer.==(x, Any)`
- `Integer.>(x, Any)`
- `Integer.>=(x, Any)`
- `Integer.>>(x, Any)`
- `Integer.^(x, Any)`
- `Integer.abs(x)`
- `Integer.allbits?(x, Integer)`
- `Integer.anybits?(x, Integer)`
- `Integer.between?(x, Integer, Integer)`
- `Integer.bit_length(x)`
- `Integer.ceil(x, [Integer])`
- `Integer.ceildiv(x, Integer)`
- `Integer.chr(x)`
- `Integer.clamp(x, Integer, Integer)`
- `Integer.digits(x)`
- `Integer.div(x, Integer|Float|Rational)`
- `Integer.divmod(x, Integer)`
- `Integer.downto(x, Integer) { }`
- `Integer.even?(x)`
- `Integer.fdiv(x, Integer)`
- `Integer.floor(x, [Integer])`
- `Integer.gcd(x, Integer)`
- `Integer.gcdlcm(x, Integer)`
- `Integer.lcm(x, Integer)`
- `Integer.magnitude(x)`
- `Integer.modulo(x, Integer)`
- `Integer.negative?(x)`
- `Integer[*Any]`
- `Integer.next(x)`
- `Integer.nobits?(x, Integer)`
- `Integer.odd?(x)`
- `Integer.ord(x)`
- `Integer.positive?(x)`
- `Integer.pow(x, Integer, [Integer])`
- `Integer.pred(x)`
- `Integer.remainder(x, Integer)`
- `Integer.round(x, [Integer])`
- `Integer.sqrt(x)`
- `Integer.step(x, Integer, Integer) { }`
- `Integer.succ(x)`
- `Integer.times(x) { }`
- `Integer.to_f(x)`
- `Integer.to_i(x)`
- `Integer.to_r(x)`
- `Integer.to_s(x)`
- `Integer.truncate(x, [Integer])`
- `Integer.upto(x, Integer) { }`
- `Integer.zero?(x)`
- `Integer.|(x, Any)`

### Kernel

- `Kernel.ARGV()`
- `Kernel.Complex(Integer|Float|Rational, [Integer|Float|Rational])`
- `Kernel.Float(String|Integer|Float)`
- `Kernel.Integer(String|Integer|Float)`
- `Kernel.Rational(Integer|Rational|String, [Integer|Rational])`
- `Kernel.block_given?()`
- `Kernel.dup(Any)`
- `Kernel.exit([Integer|Boolean])`
- `Kernel.format(String, *Any)`
- `Kernel.gets()`
- `Kernel.inspect(Any)`
- `Kernel.loop() { }`
- `Kernel.once() { }`
- `Kernel.p(Any)`
- `Kernel.pp(Any)`
- `Kernel.print(*Any)`
- `Kernel.puts(*Any)`
- `Kernel.rand([Integer|Float])`
- `Kernel.sleep([Integer|Float|Rational])`
- `Kernel.sprintf(String, *Any)`
- `Kernel.to_s(Any)`
- `Kernel.warn(*Any)`

### MatchData

- `MatchData.[](x, Any)`
- `MatchData.begin(x, Integer)`
- `MatchData.captures(x)`
- `MatchData.end(x, Integer)`
- `MatchData.named_captures(x)`
- `MatchData.names(x)`
- `MatchData.post_match(x)`
- `MatchData.pre_match(x)`
- `MatchData.to_a(x)`
- `MatchData.to_s(x)`

### Math

- `Math.E()`
- `Math.PI()`
- `Math.atan(Integer|Float|Rational)`
- `Math.atan2(Integer|Float, Integer|Float)`
- `Math.cbrt(Integer|Float|Rational)`
- `Math.cos(Integer|Float|Rational)`
- `Math.exp(Integer|Float|Rational)`
- `Math.hypot(Integer|Float, Integer|Float)`
- `Math.log(Integer|Float|Rational)`
- `Math.log10(Integer|Float|Rational)`
- `Math.log2(Integer|Float|Rational)`
- `Math.sin(Integer|Float|Rational)`
- `Math.sqrt(Integer|Float|Rational)`
- `Math.tan(Integer|Float|Rational)`

### Mutex

- `Mutex.new()`
- `Mutex.synchronize(x) { }`

### Queue

- `Queue.close(x)`
- `Queue.closed?(x)`
- `Queue.empty?(x)`
- `Queue.new()`
- `Queue.pop(x)`
- `Queue.push(x, Any)`
- `Queue.size(x)`

### Range

- `Range.!=(x, Any)`
- `Range.==(x, Any)`
- `Range.all?(x) { }`
- `Range.any?(x) { }`
- `Range.begin(x)`
- `Range.count(x) [{ }]`
- `Range.cover?(x, Any)`
- `Range.detect(x) { }`
- `Range.drop(x, Integer)`
- `Range.each(x) { }`
- `Range.each_cons(x, Integer) { }`
- `Range.each_slice(x, Integer) { }`
- `Range.each_with_index(x) { }`
- `Range.each_with_object(x, Any) { }`
- `Range.end(x)`
- `Range.exclude_end?(x)`
- `Range.filter(x) { }`
- `Range.filter_map(x) { }`
- `Range.find(x) { }`
- `Range.find_index(x) { }`
- `Range.first(x, [Integer])`
- `Range.flat_map(x) { }`
- `Range.group_by(x) { }`
- `Range.include?(x, Any)`
- `Range.inject(x, Any) { }`
- `Range.last(x, [Integer])`
- `Range.map(x) { }`
- `Range.max(x)`
- `Range.max_by(x) { }`
- `Range.member?(x, Any)`
- `Range.min(x)`
- `Range.min_by(x) { }`
- `Range.none?(x) { }`
- `Range.one?(x) { }`
- `Range.overlap?(x, Range)`
- `Range.partition(x) { }`
- `Range.reduce(x, Any) { }`
- `Range.reject(x) { }`
- `Range.reverse_each(x) { }`
- `Range.select(x) { }`
- `Range.size(x)`
- `Range.sort_by(x) { }`
- `Range.step(x, Integer) { }`
- `Range.sum(x, [Integer|Float|Rational|Complex]) [{ }]`
- `Range.take(x, Integer)`
- `Range.take_while(x) { }`
- `Range.tally(x)`
- `Range.to_a(x)`
- `Range.to_set(x)`
- `Range.zip(x, *Array)`

### Rational

- `Rational.!=(x, Any)`
- `Rational.%(x, Any)`
- `Rational.*(x, Any)`
- `Rational.**(x, Any)`
- `Rational.+(x, Any)`
- `Rational.-(x, Any)`
- `Rational./(x, Any)`
- `Rational.<(x, Any)`
- `Rational.<=(x, Any)`
- `Rational.<=>(x, Any)`
- `Rational.==(x, Any)`
- `Rational.>(x, Any)`
- `Rational.>=(x, Any)`
- `Rational.abs(x)`
- `Rational.ceil(x)`
- `Rational.denominator(x)`
- `Rational.floor(x)`
- `Rational.negative?(x)`
- `Rational[*Any]`
- `Rational.numerator(x)`
- `Rational.positive?(x)`
- `Rational.round(x)`
- `Rational.to_f(x)`
- `Rational.to_i(x)`
- `Rational.to_s(x)`
- `Rational.truncate(x)`
- `Rational.zero?(x)`

### Regexp

- `Regexp.!=(x, Any)`
- `Regexp.==(x, Any)`
- `Regexp.=~(x, Any)`
- `Regexp.escape(String)`
- `Regexp.match(x, String, [Integer])`
- `Regexp.match?(x, String, [Integer])`
- `Regexp.new(String)`
- `Regexp.source(x)`

### Set

- `Set.!=(x, Any)`
- `Set.&(x, Any)`
- `Set.-(x, Any)`
- `Set.==(x, Any)`
- `Set.add(x, Any)`
- `Set.add?(x, Any)`
- `Set.all?(x) { }`
- `Set.any?(x) { }`
- `Set.clear(x)`
- `Set.count(x) [{ }]`
- `Set.delete(x, Any)`
- `Set.delete?(x, Any)`
- `Set.delete_if(x) { }`
- `Set.difference(x, Set)`
- `Set.disjoint?(x, Set)`
- `Set.each(x) { }`
- `Set.each_with_object(x, Any) { }`
- `Set.empty?(x)`
- `Set.filter(x) { }`
- `Set.filter_map(x) { }`
- `Set.find(x) { }`
- `Set.first(x)`
- `Set.include?(x, Any)`
- `Set.intersect?(x, Set)`
- `Set.intersection(x, Set)`
- `Set.join(x, [String])`
- `Set.keep_if(x) { }`
- `Set.length(x)`
- `Set.map(x) { }`
- `Set.max(x)`
- `Set.member?(x, Any)`
- `Set.merge(x, Set)`
- `Set.min(x)`
- `Set[*Any]`
- `Set.none?(x) { }`
- `Set.partition(x) { }`
- `Set.proper_subset?(x, Set)`
- `Set.proper_superset?(x, Set)`
- `Set.reduce(x, Any) { }`
- `Set.reject(x) { }`
- `Set.select(x) { }`
- `Set.size(x)`
- `Set.sort(x)`
- `Set.sort_by(x) { }`
- `Set.subset?(x, Set)`
- `Set.subtract(x, Any)`
- `Set.sum(x, [Integer|Float|Rational|Complex])`
- `Set.superset?(x, Set)`
- `Set.to_a(x)`
- `Set.union(x, Set)`
- `Set.|(x, Any)`

### Socket

- `Socket.close(x)`
- `Socket.close_write(x)`
- `Socket.connect(String, Integer)`
- `Socket.gets(x)`
- `Socket.read(x, Integer)`
- `Socket.write(x, String)`

### String

- `String.!=(x, Any)`
- `String.!~(x, Any)`
- `String.%(x, Any)`
- `String.*(x, Integer)`
- `String.+(x, Any)`
- `String.<(x, Any)`
- `String.<=(x, Any)`
- `String.<=>(x, Any)`
- `String.==(x, Any)`
- `String.=~(x, Any)`
- `String.>(x, Any)`
- `String.>=(x, Any)`
- `String.[](x, Any, [Integer])`
- `String.ascii_only?(x)`
- `String.b(x)`
- `String.between?(x, String, String)`
- `String.byteindex(x, String|Regexp, [Integer])`
- `String.bytes(x)`
- `String.bytesize(x)`
- `String.byteslice(x, Integer, [Integer])`
- `String.capitalize(x)`
- `String.casecmp(x, String)`
- `String.casecmp?(x, String)`
- `String.center(x, Integer, [String])`
- `String.chars(x)`
- `String.chomp(x)`
- `String.chop(x)`
- `String.chr(x)`
- `String.clamp(x, String, String)`
- `String.codepoints(x)`
- `String.count(x, String)`
- `String.delete(x, String)`
- `String.delete_prefix(x, String)`
- `String.delete_suffix(x, String)`
- `String.downcase(x)`
- `String.each_byte(x) { }`
- `String.each_char(x) { }`
- `String.each_line(x) { }`
- `String.empty?(x)`
- `String.encoding(x)`
- `String.end_with?(x, String)`
- `String.force_encoding(x, String)`
- `String.getbyte(x, Integer)`
- `String.gsub(x, String|Regexp, [String|Hash]) [{ }]`
- `String.hex(x)`
- `String.include?(x, String)`
- `String.index(x, String|Regexp, [Integer])`
- `String.intern(x)`
- `String.length(x)`
- `String.lines(x)`
- `String.ljust(x, Integer, [String])`
- `String.lstrip(x)`
- `String.match(x, String|Regexp, [Integer])`
- `String.match?(x, String|Regexp, [Integer])`
- `String[*Any]`
- `String.next(x)`
- `String.oct(x)`
- `String.ord(x)`
- `String.partition(x, String|Regexp)`
- `String.reverse(x)`
- `String.rindex(x, String|Regexp, [Integer])`
- `String.rjust(x, Integer, [String])`
- `String.rpartition(x, String|Regexp)`
- `String.rstrip(x)`
- `String.scan(x, String|Regexp)`
- `String.size(x)`
- `String.slice(x, Integer|Range, [Integer])`
- `String.split(x, [String|Regexp], [Integer])`
- `String.squeeze(x)`
- `String.start_with?(x, String)`
- `String.strip(x)`
- `String.sub(x, String|Regexp, [String|Hash]) [{ }]`
- `String.succ(x)`
- `String.swapcase(x)`
- `String.to_c(x)`
- `String.to_f(x)`
- `String.to_i(x)`
- `String.to_r(x)`
- `String.to_s(x)`
- `String.to_sym(x)`
- `String.tr(x, String, String)`
- `String.tr_s(x, String, String)`
- `String.unpack(x, String)`
- `String.unpack1(x, String)`
- `String.upcase(x)`
- `String.upto(x, String) { }`
- `String.valid_encoding?(x)`

### Symbol

- `Symbol.!=(x, Any)`
- `Symbol.<(x, Any)`
- `Symbol.<=(x, Any)`
- `Symbol.<=>(x, Any)`
- `Symbol.==(x, Any)`
- `Symbol.>(x, Any)`
- `Symbol.>=(x, Any)`
- `Symbol.capitalize(x)`
- `Symbol.casecmp?(x, Symbol)`
- `Symbol.downcase(x)`
- `Symbol.empty?(x)`
- `Symbol.end_with?(x, String)`
- `Symbol.length(x)`
- `Symbol[*Any]`
- `Symbol.size(x)`
- `Symbol.start_with?(x, String)`
- `Symbol.succ(x)`
- `Symbol.swapcase(x)`
- `Symbol.to_s(x)`
- `Symbol.to_sym(x)`
- `Symbol.upcase(x)`

### TCPServer

- `TCPServer.accept(x)`
- `TCPServer.close(x)`
- `TCPServer.new(String, Integer)`
- `TCPServer.port(x)`

### Thread

- `Thread.alive?(x)`
- `Thread.join(x)`
- `Thread.new() { }`
- `Thread.value(x)`

### Time

- `Time.!=(x, Any)`
- `Time.+(x, Any)`
- `Time.-(x, Any)`
- `Time.<(x, Any)`
- `Time.<=(x, Any)`
- `Time.<=>(x, Any)`
- `Time.==(x, Any)`
- `Time.>(x, Any)`
- `Time.>=(x, Any)`
- `Time.at(Integer|Float|Rational|Time, [in: String|Integer])`
- `Time.ceil(x, [Integer])`
- `Time.day(x)`
- `Time.floor(x, [Integer])`
- `Time.friday?(x)`
- `Time.getlocal(x, [String|Integer])`
- `Time.getutc(x)`
- `Time.gmt?(x)`
- `Time.gmt_offset(x)`
- `Time.gmtime(x)`
- `Time.gmtoff(x)`
- `Time.hour(x)`
- `Time.iso8601(x, [Integer])`
- `Time.localtime(x, [String|Integer])`
- `Time.mday(x)`
- `Time.min(x)`
- `Time.mon(x)`
- `Time.monday?(x)`
- `Time.month(x)`
- `Time.new(Integer, [Integer], [Integer], [Integer], [Integer], [Integer|Float|Rational], [String|Integer], [in: String|Integer])`
- `Time.now([in: String|Integer])`
- `Time.nsec(x)`
- `Time.round(x, [Integer])`
- `Time.saturday?(x)`
- `Time.sec(x)`
- `Time.strftime(x, String)`
- `Time.sunday?(x)`
- `Time.thursday?(x)`
- `Time.to_f(x)`
- `Time.to_i(x)`
- `Time.to_s(x)`
- `Time.tuesday?(x)`
- `Time.usec(x)`
- `Time.utc(x)`
- `Time.utc?(x)`
- `Time.utc_offset(x)`
- `Time.wday(x)`
- `Time.wednesday?(x)`
- `Time.yday(x)`
- `Time.year(x)`
- `Time.zone(x)`

### Tuple

- `Tuple.!=(x, Any)`
- `Tuple.<(x, Any)`
- `Tuple.<=(x, Any)`
- `Tuple.<=>(x, Any)`
- `Tuple.==(x, Any)`
- `Tuple.>(x, Any)`
- `Tuple.>=(x, Any)`
- `Tuple.[](x, Any)`
- `Tuple.[]=(x, Any, Any)`
- `Tuple.length(x)`
- `Tuple.max(x)`
- `Tuple.min(x)`
- `Tuple.minmax(x)`
- `Tuple[*Any]`
- `Tuple.size(x)`
- `Tuple.to_a(x)`

### Exception types

Each of `RuntimeError`, `ArgumentError`, `KeyError`, `IndexError`, `ZeroDivisionError`, `RangeError`, `IOError`, `EncodingError`, `RegexpError`, `FloatDomainError`, `NoMatchingPatternError`, `TypeError` has `T.new(message)`, `T.get_message(x)`, and `T.set_message(x, v)`. `Exception.message(e)` reads the message of any exception; `Exception.new(:field, ...)` declares an exception type. `Math::DomainError` can only be named in `rescue`.
