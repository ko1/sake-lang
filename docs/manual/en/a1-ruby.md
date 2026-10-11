# Differences from Ruby and what is not supported

Sake's syntax is Ruby's, but several Ruby spellings are static errors and have a Sake spelling in their place. This appendix gathers those replacements in one table and gives the reasons below it. When a program written the Ruby way gets a static error, look it up here first; each error's hint also gives the form on the Sake side of the table.

## From Ruby to Sake

Each row is the Ruby spelling (left), the Sake spelling (middle), and the reason in a few words (right). The sections under the table explain the reasons, with examples.

| Ruby | Sake | Why |
|---|---|---|
| `s.upcase` | `String.upcase(s)`, `s.String.upcase` | the type is written on the operation |
| `p.x`, `p.x = v` | `Point.x(p)`, `p.Point.x = v`; inside the functions, `@x`, `@x = v` | field reads and writes name their type too |
| `x.nil?` | `x == nil` | no calls on values |
| `def self.f` | `def f`; in a module, `module_function` | one name in a namespace is one function |
| `class B < A` (inheritance) | `class B < A` (copies A's definitions; no subtyping) | every call target is static |
| `attr_reader :x` | `attr_reader x` | field names are written bare |
| `def initialize(x) = @x = x` | `C.new(x)` stores the field; `initialize(c)` only checks and converts | the parameter is the new instance |
| `@items = []` (a default) | `@items = Array[]` inside `initialize` | fields have no default values |
| `Data.define` | `Struct.new` | classes are mutable |
| `[1, 2]` (a growable array) | `Array[1, 2]`; `[1, 2]` is a Tuple (fixed length) | a literal's shape fixes its type |
| `{a: 1}` (a Hash) | `Hash[a: 1]`; `{a: 1}` is a Record | same |
| `%w[a b]`, `%i[a b]` | `String["a", "b"]`, `Symbol[:a, :b]` | undecided (Tuple or Array) |
| `PI = 3.14` | `def pi = 3.14`; a table is `once { ... }` | no value constants |
| `Math::PI`, `ARGV`, `$stdout` | `Math.PI` (or `Math::PI`), `ARGV`, `IO.stdout` | read as operations |
| `case x when Integer` | `case x in Integer` | there is no `===` |
| `for x in xs` | `Array.each(xs) { \|x\| }` | iteration is an operation |
| `$1`, `$~` | `m = String.match(s, re)`, then `m[1]` | no global variables |
| `proc`, `lambda`, `->`, `&:sym`, `method(:f)` | none; a block is only passed, with `yield` or `&b` | blocks are second-class |
| `obj.send(:f)`, `define_method`, `method_missing`, `eval` | none | call targets are static |
| `g(**opts)` | none; pass the Hash positionally | an open design question (D11) |
| `rescue A` (catching by hierarchy) | `rescue A, B` (the listed types only) | exception types have no hierarchy |
| `1 + money` | define `coerce(m, other)` in Money | the left operand decides |

### The type is written on the operation

In Sake only operations name a type. A method call on a value such as `s.upcase` is a static error, and the checker's hint gives `String.upcase(s)` and the chain form `s.String.upcase` ([Program structure and name resolution](02-program.md)). Field reads and writes are the same: `p.x` is `Point.x(p)` and `p.x = v` is `p.Point.x = v`. Inside a class's functions, `@x` means field `x` of the first parameter ([Classes](07-classes.md)).

```ruby
Point = Struct.new(:x, :y)
class Point
  def shift(pt, d)
    @x = @x + d          # Point.set_x(pt, Point.x(pt) + d)
    @x
  end
end
pt = Point.new(1, 2)
p(Point.x(pt))           # => 1
pt.Point.x = 5
p(Point.shift(pt, 1))    # => 6
p(pt)                    # => #<struct Point x=6, y=2>
```

`x.nil?` is a method call on a value too, so it gets the same error, with the hint `x == nil`.

### Classes

A type a program defines is a class. Declaring it with `attr_*` lines in `class C` and making it with the shorthand `Struct.new(:x, :y)` give the same thing. These are the points where it differs from a Ruby class ([Classes](07-classes.md)).

- **No `def self.f`.** Sake has no `self`; `def f` inside `class C` is `C.f` as it is. Ruby's class methods and instance methods both become the same `def f` in Sake. In a module, write `module_function`.
- **No inheritance.** `class B < A` is shorthand for writing A's definitions (fields, functions, includes) into B. Afterwards A and B are unrelated types, and passing a B to `A.f(b)` is a type error.
- **Field names are bare.** `attr_reader :x` is an error telling you to write `x` without the `:`.
- **`initialize` takes no value.** After `C.new(x)` has stored the fields, `def initialize(c)` runs with the new instance. Ruby's `def initialize(x) = @x = x` would store the instance in its own field, so it is a static error.
- **Defaults go in `initialize`.** `attr_reader items = Array[]` is an error; the first value is set inside `initialize` with `@items = Array[]`. `C.new` may then leave that field out.
- **No `Data.define`.** Sake's classes are mutable, so use `Struct.new`, the counterpart of Ruby's `Struct`.

```ruby
class A
  attr_reader x
  def double(a) = @x * 2
end
class B < A              # copies A's x and double into B
  attr_reader y
end
b = B.new(1, 2)
p(B.double(b))           # => 2
p(b)                     # => #<struct B x=1, y=2>
```

```ruby error
class Bag
  attr_reader name, items
  def initialize(x) = @items = x    # !> `@items = x` stores the new Bag in its own field: `x` is the instance, not a value
end
```

### Literals and constants

A literal's shape fixes its type ([Values and types](03-values.md)).

- **`[1, 2]` is a Tuple**, of fixed length. A growable array is written `Array[1, 2]`, and the empty one `Array[]`. Passing a Tuple to `Array.push` is a type error whose hint says to write `Array[...]`.
- **`{a: 1}` is a Record**; `Hash[a: 1]` is a Hash. A Record's fields are read with a pattern, `r => {a:}`.
- **`%w[a b]` and `%i[a b]` are not supported.** Whether they are a Tuple or an Array is undecided. `String["a", "b"]` and `Symbol[:a, :b]` give Arrays with an element type.
- **No value constants.** `PI = 3.14` is a static error whose hint gives `def pi = 3.14`. A table computed once and kept is `def table = once { ... }` ([Functions and blocks](04-functions.md)). Only `Struct.new` and `Exception.new` may be assigned to a constant.
- **Built-in constants are operations.** Call them as `Math.PI`, `ARGV`, `IO.stdout`. A few built-in ones such as `Math::PI` are also read in Ruby's form. There are no global variables such as `$stdout`.

```ruby
t = [1, 2]
xs = Array[1, 2]
Array.push(xs, 3)
p(t, xs)                 # => [1, 2]
                         # => [1, 2, 3]
h = Hash[a: 1]
h[:b] = 2
p(h)                     # => {a: 1, b: 2}
def pi = 3.14
p(pi, Math.PI)           # => 3.14
                         # => 3.141592653589793
```

```ruby error
xs = [1, 2]
Array.push(xs, 3)        # !> Array.push: argument 1 must be Array, but is [Integer, Integer] [type]
```

### Control and iteration

- **No `case`/`when`; use `case`/`in`.** Ruby's `when` dispatches `===` on the receiver, and Sake has no `===`. `case x in Integer` branches on the type, and the checker looks at exhaustiveness ([Control flow and patterns](06-control.md)).
- **No `for`; iterate with an operation.** `Array.each(xs) { |x| ... }`, `Range.each(1..3) { |i| ... }`: the operation of the Array or Range hands out the elements ([Functions and blocks](04-functions.md)).
- **No `$1`, `$~`.** Keep the match in a variable: `m = String.match(s, re)`, then `m[1]` when `m` is not nil.

### Blocks and dynamic features

- **Blocks are second-class.** A block is passed to a function and called with `yield`, or passed on with `&b`; it cannot be stored in a variable. There is no `proc`, `lambda`, `->` or `method(:f)`, and `&:sym` cannot be passed ([Functions and blocks](04-functions.md)).
- **Call targets are static.** There is no `send`, `define_method`, `method_missing` or `eval`. `eval` is an error saying it defeats static analysis.
- **Passing keywords on.** `def f(**opts)` can collect them, but `g(**opts)` cannot pass them to the next function (`**` is not supported). Pass the Hash as a positional argument. This is open as design question D11.

### Exceptions

Exception types have no hierarchy, so `rescue A, B => e` catches the listed types only ([Exceptions and errors](08-exceptions.md)). Writing `class MyErr < StandardError` does not make MyErr a subtype of StandardError; the `<` is a copy. The three forms `rescue => e`, `rescue StandardError => e` and `rescue Exception => e` keep Ruby's meaning of "any exception" and catch every rescuable exception.

```ruby
class MyErr < StandardError
end
begin
  raise MyErr, "boom"
rescue KeyError, IndexError => e
  p(1)
rescue MyErr => e
  p(Exception.message(e))    # => "boom"
end
```

### Operators

`a + b` is shorthand for `Arithmetic.+(a, b)`, resolved by the type of the left operand ([Operators and indexing](05-operators.md)). `1 + money` dispatches on Integer, so Money's `+` is never reached. With Ruby's protocol, a `coerce(m, other)` defined in Money that returns the Tuple `[left, right]` has the pair converted first, and then the operator runs.

```ruby
class Money
  include Arithmetic
  attr_reader cents
  def +(a, b) = Money.new(@cents + Money.cents(b))
  def coerce(m, other) = [Money.new(other * 100), m]
end
m = Money.new(50)
p(2 + m)                 # => #<struct Money cents=250>
```

## Not yet supported

Each of these is rejected statically with a "not supported" error. Most wait on a design decision.

- **Writing to Record fields.** `r[:a] = 2` is an error saying a Record cannot be indexed. Reading is by pattern, `r => {a:}`.
- **The type scope `Integer.(a + b)`.**
- **`case`/`when`.** Use `case`/`in`.
- **`%w[]`, `%i[]`.** Tuple or Array is undecided.
- **`for`.** Not planned for now. Iterate with an operation such as `Range.each(1..3) { |i| ... }`.
- **Other pattern forms.** `*rest` in a Tuple pattern, find patterns, pins `^x`, guards `in Integer if c`. The patterns that work are in [Control flow and patterns](06-control.md).
- **First-class blocks.** Storing a block, `proc`, `lambda`.
- **`g(**opts)`.** Passing collected keywords on.
- **`begin ... end while`.** Write the `while` first.

## Design material

- `DESIGN.md` (Japanese): the design notes, with the reasons behind each decision.
- `docs/comparison.md` (Japanese): what is new in Sake and what is not, axis by axis against Elm, Crystal, Rust, Elixir, TypeScript, Clojure and the type-inference literature.
- `TODO.md`: open items and design questions (D1 to D13).
- `experiments/`: each experiment with its method, results, and limits (README).
