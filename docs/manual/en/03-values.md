# Values and types

Sake's values look much like Ruby's, but every value carries one type tag, and every operation checks it. This chapter lists the types and how each is written. Where the spelling is Ruby's but the meaning differs: `[a, b]` is a Tuple, `{x: 1}` is a Record, and `{}` and `{k => v}` are static errors.

| Type | How it is written (a literal, or the operation that makes it) | Notes |
|---|---|---|
| Integer | `42`, `-7` | arbitrary precision |
| Float | `1.5`, `2.0` | |
| String | `"abc"`, `'abc'`, `"a#{x}"` | interpolation uses `to_s` (see "Showing values") |
| true / false | `true`, `false` | internally one type, `Boolean`, which cannot be written in source |
| nil | `nil` | see "nil" below |
| Tuple | `[a, b, ...]` | length and positional types fixed at creation |
| Record | `{x: a, y: b}` | set of (field, type) pairs fixed at creation |
| Array | `Array[a, ...]` | no declared element type |
| Array of T | `T[a, ...]`, e.g. `Float[]`, `Point[p]` | element type T, checked on every write |
| Hash | `Hash["a" => 1, b: 2]`, `Hash.new(0)` | keys compare by value and type (Ruby's `eql?`) |
| Set | `Set[1, 2]` | elements compare by value and type (Ruby's `eql?`) |
| Symbol | `:name` | |
| Range | `1..5`, `1...5`, `1..` | ends are Integer, Float, String, or nil |
| Regexp, MatchData | `/(\d+)-(\d+)/`, `/#{x}/`, `String.match(s, re)` | |
| Rational, Complex | `2r`, `1/3r`, `Rational(1, 3)`, `2i`, `Complex(1, 2)` | Ruby's numeric tower |
| Time | `Time.now`, `Time.at(0)`, `Time.new(2026, 10, 1)` | |
| IO | `IO.stdout`, `File.open(path)` | one type for files and streams |
| Thread, Mutex, Queue, TCPServer, Socket | `Thread.new { }`, `Mutex.new`, ... | concurrency and networking |
| class | `Point.new(x, y)` | record with mutable fields ([Classes](07-classes.md)) |

- **Truthiness.** Only `nil` and `false` are falsy. Every other value, including `0` and `""`, is truthy.
- **Error messages.** `nil`, `true`, and `false` are shown as values (`got nil`). Every other value is shown by its type name (`got Integer`).

```ruby
p(0 ? "yes" : "no")            # => "yes"
p("" ? "yes" : "no")           # => "yes"
p(nil ? "yes" : "no")          # => "no"
p(false ? "yes" : "no")        # => "no"
```

## Showing values

Every value can be shown in two forms. `to_s` is the form for a reader, `inspect` the form that shows a programmer the kind of value as well; they are used as in Ruby.

| Form | Used by | Built-in form |
|---|---|---|
| `to_s` | `puts`, `print`, `"#{x}"`, `Array.join`, `format`'s `%s`, `:"#{x}"`, `/#{x}/` | as Ruby's `to_s`: `nil` shows as empty, Arrays and Tuples as `inspect` |
| `inspect` | `p`, `Kernel.inspect`, `format`'s `%p`, and elements inside an Array, Tuple, Hash, or Record | as Ruby's `inspect`: `#<struct Point x=1, y=2>` |

```ruby
Point = Struct.new(:x, :y)
puts("a")                      # => a
p("a")                         # => "a"
puts("#{nil}|")                # => |
puts("#{[1, "a"]}")            # => [1, "a"]
puts(format("%s %p", "a", "a"))  # => a "a"
p(Point.new(1, 2))             # => #<struct Point x=1, y=2>
```

### Your own form

A class can define its own `to_s` and `inspect` in its body. Each takes one required argument, the value, and must return a String. Parameters with defaults may follow (`to_s(n, base = 10)`).

```ruby
class Point
  attr_accessor x, y
  def to_s(p) = "(#{@x}, #{@y})"
  def inspect(p) = "Point(#{@x}, #{@y})"
end
pt = Point.new(1, 2)
puts(pt)                       # => (1, 2)
puts("at #{pt}")               # => at (1, 2)
p(pt)                          # => Point(1, 2)
p([pt])                        # => [Point(1, 2)]
```

A non-String result is reported before running as a `type` problem. If it is reached while running, it is a `TypeError`.

```ruby error
class Point
  attr_accessor x, y
  def to_s(p) = @x
end
puts(Point.new(1, 2))          # !> Point.to_s must return a String, but returns Integer [type]
```

- **Which one runs.** The set of types is closed, so which `to_s` runs is known whenever the value's type is.

## Tuples, Records, and arrays

The literals `[...]` and `{...}` have no operation with a type, so their **shape** fixes their type at creation: `[a, b]` is a Tuple and `{x: a, y: b}` is a Record. A growable collection is made by an operation with a type (`Array[...]`, `T[...]`, `Hash[...]`).

### What a literal is

- **Contents are mutable.** The contents of a literal may be replaced by values of the same type, and each write is checked. Tuples are written with `t[i] = v`. Records have no write syntax yet.
- **Length is fixed.** The length is part of the type, so an empty `[]` cannot grow.
- **nil.** A position created with `nil` has the type nil, and no other value can be stored there later. To leave room for a value, create it with a placeholder of the intended type, such as `0` or `""`.

```ruby error
xs = []
Array.push(xs, 1)              # !> `[...]` is a Tuple with a fixed length; for a growable Array, write `Array[...]`
```

```ruby error
t = [1, nil]
t[1] = 2                       # !> Indexable.[]=: the value must be Nil, but is Integer [type]
```

### Tuple

The literal `[a, b, ...]` is a Tuple. Its elements are read by multiple assignment, `x, y = t`, or by index, `t[0]`.

```ruby
t = [1, "a"]
x, y = t
p(x)                           # => 1
p(y)                           # => "a"
t[0] = 2
p(t)                           # => [2, "a"]
p(Tuple.size(t))               # => 2
p(Tuple.max([3, 9, 4]))        # => 9
```

- **Multiple assignment.** `x, y = t` takes a Tuple apart. It also takes an Array apart (`key, value = String.split(s, "=")`). As in Ruby, missing elements are nil and extra elements are dropped.
- **An element that may be missing.** A variable that may get one has the type `nil | T`, as `x[k]` does (the `index-nil` item, level 3).
- **Targets.** Elements and fields may be targets too: `a[i], a[j] = a[j], a[i]` swaps, and `@done, @rest = Array.partition(xs) { ... }` assigns to fields. Their receivers and indexes are evaluated first, then the right side.
- **The rest.** `first, *rest = xs` puts the remaining elements in a new Array. `a, *mid, z = xs` does the same, and `x, * = xs` drops them. Only a local variable takes the rest.
- **A splat inside `[...]`.** A Tuple's length must be known, so `[*xs, 1]` is rejected. `Array[*xs, 1]` makes an Array.
- **Indexing.** `t[0]` reads a position and `t[0] = v` replaces it with a value of the same type.
- **Operations.** `Tuple.size` and `Tuple.length` give the number of elements. `Tuple.max([a, b])` is Ruby's `[a, b].max`; the length is known, so the result is never nil.

```ruby
first, *rest = Array[1, 2, 3]
p(first)                       # => 1
p(rest)                        # => [2, 3]
key, value = String.split("a=1", "=")
p(value)                       # => "1"
a = Array[1, 2]
a[0], a[1] = a[1], a[0]
p(a)                           # => [2, 1]
```

### Record

The literal `{x: a, y: b}` is a Record: a small fixed group of values read by field name.

- **Type.** The type of a Record is its set of (field, type) pairs, for example `{x: Integer, y: Integer}`. Two Records with the same set have the same type.
- **Field order.** Order does not matter: `{y: 2, x: 1}` is printed as `{x: 1, y: 2}`, and the two are `==`.
- **Not a class value.** A Record is never a value of a class, even when the fields match: classes are nominal, and Record types are structural.
- **Reading fields.** Take fields apart with a pattern, `r => {x:, y: name}`. This binds the local `x` to field `x` and the local `name` to field `y`. Listing only some of the fields is allowed. `Record.to_h(r)`, `Record.keys(r)`, and `Record.values(r)` exist too.
- **A missing field.** It is reported before running at `type`. If it is reached while running, a missing field raises `KeyError`, and a value that is not a Record raises `TypeError`.
- **Restrictions.** Field names are written as labels (`x:`). An empty `{}` and `{key => value}` are static errors (a Hash is `Hash[...]`).

```ruby
Point = Struct.new(:x, :y)
r = {y: 2, x: 1}
p(r)                           # => {x: 1, y: 2}
p(r == {x: 1, y: 2})           # => true
p(r == Point.new(1, 2))        # => false
r => {x:, y: name}
p(x)                           # => 1
p(name)                        # => 2
p(Record.keys(r))              # => [:x, :y]
```

```ruby error
r = {x: 1}
r => {z:}                      # !> the pattern needs field `z`, but the value is {x: Integer} [type]
```

```ruby error
h = {"a" => 1}                 # !> `{"a" => ...}` is not a Hash in Sake: `{name: value}` makes a Record
```

### Array

`Array[a, ...]` creates an Array with no declared element type. Any value can be added to it. Arrays are mutable and shared by reference.

### Array of T

`T[a, ...]` creates an Array whose element type is T. T is a built-in type (`Integer`, `Float`, `Rational`, `Complex`, `String`, `Symbol`, `Tuple`) or a class.

- **Write checks.** Every write is checked: creation, `Array.push`, `Array.append`, and `Array.concat`. A mismatch raises `TypeError`. There is no implicit conversion, so an Integer cannot go into `Float[]`.
- **Static check.** If a literal argument of `T[...]` has another type, the error is reported before running. This catches `Point[1, 2]`, Ruby's spelling of `Point.new(1, 2)`.
- **Untyped results.** Arrays returned by `map`, `select`, `sort`, and similar operations have no declared element type.

```ruby error
fs = Float[1.5]
Array.push(fs, 2.5)
Array.push(fs, 3)              # !> Array.push: an element must be Float, but is Integer [type]
```

```ruby error
Point = Struct.new(:x, :y)
pt = Point[1, 2]               # !> Point.new(1, 2) creates one Point; Point[...] is an Array of Point
```

```ruby
Point = Struct.new(:x, :y)
pts = Point[Point.new(1, 2), Point.new(3, 4)]
xs = Array.map(pts) { |pt| Point.x(pt) }
Array.push(xs, "s")
p(xs)                          # => [1, 3, "s"]
```

### Ruby habits

- **`[]` where an Array is expected.** A Tuple or Record passed where an Array is expected, such as `result = []` followed by `Array.push(result, x)`, fails with a hint to write `Array[]` (the example above).
- **In-place operations that change the element type.** The checker gives a container one element type for the whole program. So after `Array.map!(xs) { |x| Integer.to_s(x) }` or `Hash.transform_keys!(h) { ... }` it takes the container to hold both the old and the new type, and reports operations that fit only one of them as `type` (partial). Use the in-place forms for a mapping within one type, and `Array.map` / `Hash.transform_keys` (a new container) to change it.

```ruby error
xs = Array[1, 2]
Array.map!(xs) { |x| Integer.to_s(x) }
p(Array.sum(xs))               # !> Array.sum: an element must be Integer|Float|Rational|Complex, but can be String [type]
```

## Hash and Set

A Hash and a Set are growable collections that find a key or an element by its value. The literal `{...}` is a Record, so both are made by an operation with a type.

### Constructors

`Hash[k => v, ...]`, `Hash[]`, and `Hash.new(default)` create a Hash; `Set[x, ...]` creates a Set. The keys of `Hash[name: v]` are Symbols.

```ruby
h = Hash["a" => 1, b: 2]
p(h)                           # => {"a" => 1, b: 2}
counts = Hash.new(0)
Array.each(String.split("the cat the", " ")) { |w| counts[w] += 1 }
p(counts)                      # => {"the" => 2, "cat" => 1}
Hash.each(counts) { |k, v| puts("#{k}: #{v}") }   # => the: 2
                                                  # => cat: 1
```

### Comparing keys and elements

Hash keys and Set elements compare as Ruby's `eql?` does: by value, with the type included. `1` and `1.0` are different keys, while `1 == 1.0` is true.

```ruby
p(Hash[1 => "a"][1.0])         # => nil
p(Set[1, 1.0])                 # => Set[1, 1.0]
p(1 == 1.0)                    # => true
```

- **Allowed.** Integer, Float, String, Symbol, true, false, nil, Time, and Tuples, Records, Arrays, Hashes, Sets, and values of a class made of these.
- **Not allowed (`TypeError`).** Regexp, Range, and values of a class that defines its own equality (`==`, or `Comparable` with `<=>`), because the key comparison could disagree with that equality.
- **Changing a key.** As in Ruby, changing an Array, Hash, Set, or class value after using it as a key makes it unfindable.
- **Keys are copied.** A Tuple or Record key is copied when it is stored, so a later write to the original does not change the key.

```ruby error
h = Hash[/a/ => 1]             # !> Regexp cannot be a Hash key or Set element
```

```ruby
k = [1, 2]
h = Hash[k => "a"]
k[0] = 9
p(Hash.keys(h))                # => [[1, 2]]
```

### Default values

`Hash.new(default)` gives `default` for a missing key, as in Ruby, and the same object is shared, as in Ruby. The block form `Hash.new { ... }` is not available, because blocks are not values.

```ruby
h = Hash.new(Array[])
Array.push(h[:a], 1)
p(h[:b])                       # => [1]
```

```ruby error
h = Hash.new { |hh, k| 0 }     # !> Hash.new does not take a block
```

### Blocks and order

- **Blocks.** A block over a Hash receives `[key, value]` as one Tuple, so `|k, v|` takes it apart (the `Hash.each` example above).
- **Order.** Iteration follows insertion order, as in Ruby.

## nil

`nil` is an ordinary value. A value that may be absent has the type `nil | T`, and there is no Option wrapper. Before such a value goes to an operation that cannot take nil, a check removes nil from its type.

### Run time

An operation that receives `nil` where it needs T raises `TypeError ... got nil`. The interpreter then runs the static analysis, on the error path only, and adds hints naming the fields that may hold `nil` and the lines that store it.

```ruby error
h = Hash["a" => "x"]
puts(String.upcase(h["b"]))    # !> TypeError: String.upcase: argument 1 must be String, got nil
```

### Narrowing

The static analysis narrows a **local variable** in the following places.

| Form | Where `x` is narrowed |
|---|---|
| `if x` / `while x` / `x && …` | non-nil in the branch taken when `x` is truthy |
| `x != nil` / `x == nil` | nil or non-nil in the matching branch |
| `!x` / `unless x` | the same, with the branches swapped (`if !x … else` is non-nil in the else) |
| `return unless x`, `next unless x`, `break unless x`, and other early exits | non-nil after the statement |
| `String.size(x)`, or any built-in operation taking `x` as an argument | after the call, a type that the operation accepts (it checks its arguments while running) |
| `x in T` / `x => T` / `case x in T` | the matching types ([Control flow and patterns](06-control.md)) |

```ruby
def find_even(xs) = Array.find(xs) { |x| x % 2 == 0 }
x = find_even(Array[1, 4])
if x
  p(x + 1)                     # => 5
end
p(x + 1) if x != nil           # => 5
def twice(xs)
  x = find_even(xs)
  return 0 unless x
  x * 2
end
p(twice(Array[1, 4]))          # => 8
p(twice(Array[1, 3]))          # => 0
```

Field reads (`Node.next(n)`) are **not** narrowed, because fields are mutable.

```ruby error
class Node
  attr_accessor value, :next
end
def mk(v) = Node.new(v, nil)
a = mk(1)
Node.set_next(a, mk(2))
if Node.next(a)
  p(Node.value(Node.next(a)))  # !> Node.value: argument 1 may be nil (nil | Node) [nil]
end
```

Copy the field into a local variable first, then test the local.

```ruby
class Node
  attr_accessor value, :next
end
def mk(v) = Node.new(v, nil)
a = mk(1)
Node.set_next(a, mk(2))
nx = Node.next(a)
if nx
  p(Node.value(nx))            # => 2
end
```

### `--strict`

Level 2 reports, before running, every operation that may receive an unchecked `nil`. Level 3 also covers results of `x[k]` ([Overview and running programs](01-overview.md)).

## Ruby's other types

Ruby's other types are made with the same spelling and give the same values as in Ruby. The differences are that operations are called with their type, and that there are no global variables (`$1`, `$stdout`).

### Range

Operations that iterate need a Range that starts with an Integer or a String. `"A".."Z"` walks with `String#succ`, as Ruby's does. `step`, `sum`, and `size` need an Integer. The checker reports a Range of another type (`1.0..2.0`) at `type`.

```ruby
p(Range.to_a("a".."e"))        # => ["a", "b", "c", "d", "e"]
p(Range.sum(1..4))             # => 10
p((1..3) == (1..3))            # => true
p(/a/i == /a/i)                # => true
```

```ruby error
Range.each(1.0..2.0) { |x| p(x) }   # !> Range.each: the Range's first value must be Integer|String, but is Float [type]
```

- **Equality.** Two Ranges are `==` when their ends and `exclude_end?` are; two Regexps when their source and options are.
- **Endless Ranges.** Operations that need a finite Range raise `RangeError` on an endless one.

```ruby error
p(Range.to_a(1..))             # !> RangeError: Range.to_a: cannot do this on an endless Range 1..
```

### Regexp and MatchData

Globals such as `$1` and `$~` do not exist; keep the MatchData in a variable and index it (`m[1]`). `String.match` gives nil when nothing matches, so check it first. `String.sub`, `gsub`, `index`, and `split` also take a Regexp. `/.../n` is a byte regexp, as in Ruby.

```ruby
m = String.match("2026-10", /(\d+)-(\d+)/)
if m
  p(m[1])                      # => "2026"
  p(m[2])                      # => "10"
end
p(String.sub("a-b", /-/, "+")) # => "a+b"
p(String.scan("a1b22", /\d+/)) # => ["1", "22"]
```

```ruby error
m = String.match("a1", /(\d)/)
puts($1)                       # !> Sake has no global variables (`$1`)
```

### Time

A zone is a fixed UTC offset, as Ruby's: `"+09:00"`, `"-0500"`, `"Z"`, `"UTC"`, a military letter, or seconds (`3600`). `Time.new`, `Time.at`, and `Time.now` also take it as the keyword `in:`. `Time.utc(t)` and `Time.localtime(t, zone)` give a converted copy (Ruby's `utc` and `localtime` change the receiver).

```ruby
t = Time.new(2026, 10, 1, 9, 0, 0, in: "+09:00")
p(t)                           # => 2026-10-01 09:00:00 +0900
p(Time.utc(t))                 # => 2026-10-01 00:00:00 UTC
p(t)                           # => 2026-10-01 09:00:00 +0900
p(Time.at(0, in: 3600))        # => 1970-01-01 01:00:00 +0100
```

### IO

`IO.stdin`, `IO.stdout`, and `IO.stderr` give the program's streams as values of type `IO`. Sake has no `$stdout` or `STDOUT`; as with `ARGV`, a value comes from an operation. `File.open(path, mode = "r")` gives an `IO` too; with a block it gives the block's value and closes the file after the block.

- **One type.** There is one type for files and streams, so one function can write to either.
- **Patterns and equality.** `IO` can be matched (`in IO`), and two IO values are `==` when they are the same stream or file.

```ruby
def say(io, s) = IO.puts(io, s)
say(IO.stdout, "to stdout")    # => to stdout
File.open("out.txt", "w") { |f| say(f, "to a file") }
p(File.read("out.txt"))        # => "to a file\n"
p(IO.stdout == IO.stdout)      # => true
```

### Encodings

Strings of incompatible encodings meeting (a byte from `Integer.chr(227)` next to UTF-8 text) raise `EncodingError`, which can be rescued.

```ruby
begin
  s = Integer.chr(227) + "あ"
rescue EncodingError => e
  puts("rescued")              # => rescued
end
```
