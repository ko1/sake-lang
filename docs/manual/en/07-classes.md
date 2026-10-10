# Classes

A type a program defines is a class. Declared with `attr_*` lines in a `class` or made with `Struct.new(:x, :y)`, it is the same thing: its values hold fields (and print as Ruby's Struct values, `#<struct Point x=3, y=4>`), and its operations are called with the type, `Point.norm2(pt)`. Classes do not inherit and values take no method calls, so what a Sake class shares with Ruby's is declaring a type and gathering its operations.

The `# => value` comments in this chapter are the real output of `bin/sake --strict=2`.

## Declaring a type: class and attr_*

`class C ... end` declares the type `C`. The `attr_*` lines of its body give the fields, and its `def`s give the operations. `C.new` makes a value; a field is read with the reader `C.x(c)` and written with the writer `C.set_x(c, v)`.

```ruby
class Account
  attr_reader owner
  attr_accessor balance
  def initialize(a)
    @balance = 0 if @balance == nil
  end
end
acct = Account.new("ko1")
p(acct)                              # => #<struct Account owner="ko1", balance=0>
p(Account.owner(acct))               # => "ko1"
Account.set_balance(acct, 100)
p(Account.balance(acct))             # => 100
rich = Account.new("you", 500)
p(Account.balance(rich))             # => 500
```

Every `class` is a type. Its fields are declared in the body of its first `class`; a later `class Account` adds functions only. The field names are written bare.

| Line | Meaning |
|---|---|
| `attr_accessor x, ...` | fields with a reader `C.x(c)` and a writer `C.set_x(c, v)` |
| `attr_reader x, ...` | the reader only; inside the type's functions, `@x = v` still writes them |
| `attr_writer x, ...` | the writer only; inside the type's functions, `@x` still reads them |
| `private attr_... x` | the reader and writer are for the class's own functions only; `new` still takes it |

A `private` field can be read and written by the class's functions on any of its values (`@x`, or `T.x(other)`). `T.x(c)` from outside is a static error.

```ruby
class Counter
  attr_reader label
  private attr_accessor n
  def bump(c) = @n += 1
  def same?(c, other) = n(c) == n(other)
end
c = Counter.new("hits", 0)
Counter.bump(c)
p(Counter.bump(c))                   # => 2
p(Counter.same?(c, Counter.new("x", 2)))   # => true
```

```ruby error
class Counter
  attr_reader label
  private attr_accessor n
end
c = Counter.new("hits", 0)
p(Counter.n(c))                      # !> field `n` of Counter is private (private attr_*)
```

### Field order and new

Fields are in the order written, across lines. That is the order of `C.new`'s arguments. `C.new` takes the fields positionally, whatever their access, and also by name: `Logger.new("app", level: :warn)` gives the first field by position and `level` by keyword.

- Prefer the names for a type with several fields: a positional `new` is not checked against the field order.
- An unknown name, and one field given twice, are static errors.
- Without `initialize`, every field must be given.
- With `initialize`, trailing fields may be left out, or skipped for a later keyword. A field left out is nil when initialize starts, and initialize sets it.

```ruby
class Logger
  attr_reader name, level
  def initialize(l)
    @level = :info if @level == nil
  end
end
a = Logger.new("app")
p(Logger.level(a))                   # => :info
b = Logger.new("app", level: :warn)
p(Logger.level(b))                   # => :warn
c = Logger.new(level: :debug, name: "db")
p(c)                                 # => #<struct Logger name="db", level=:debug>
```

```ruby error
class Logger
  attr_reader name, level
  def initialize(l)
    @level = :info if @level == nil
  end
end
Logger.new("app", lvl: :warn)        # !> Logger has no field `lvl`
```

### initialize

`def initialize(c)` in a class runs **after** `C.new` has stored the fields, with the new instance. As in Ruby, it is the place for first values (`@items = Array[]`), checks (`@port => Integer`), and conversions (`@celsius = Float(@celsius)`). `@level = :info if @level == nil` keeps a value that `new` gave.

- It takes exactly that one parameter, the new instance. Two or more is a static error.
- Calling `C.initialize` directly is a static error; `C.new` calls it.
- The checker analyzes initialize for each `C.new` call. There, `@x` reads the value that call gave, so a wrong argument is reported for that call. The fields hold what initialize leaves in them.

```ruby
class Temp
  attr_reader celsius, label
  def initialize(t)
    @celsius = Float(@celsius)
    @label = "C" if @label == nil
  end
end
t = Temp.new(21)
p(Temp.celsius(t))                   # => 21.0
p(Temp.label(t))                     # => "C"
p(Temp.new(1, "K"))                  # => #<struct Temp celsius=1.0, label="K">
```

```ruby error
class Box
  attr_reader value
  def initialize(b)
    @value => Integer                # !> `=> Integer`: the value is String, which does not match [type]
  end
end
p(Box.new(1))
p(Box.new("s"))
```

> [!WARNING]
> Ruby's `def initialize(x) = @x = x` is a static error in Sake: `x` is the new instance, not a value, so this would store the instance in its own field. `C.new(...)` has already stored the fields; initialize only checks or converts them.

```ruby error
class Box
  attr_reader value
  def initialize(x) = @value = x     # !> `@value = x` stores the new Box in its own field: `x` is the instance, not a value
end
```

### No default values

`attr_reader items = Array[]` is a static error. A field's first value is set in `initialize`: it is the one place that runs for each new instance, and it can read the other fields (`@len = String.bytesize(@src)`). The checker follows the fields through initialize, so a field that initialize always sets is not nil afterwards.

```ruby error
class Bag
  attr_reader items = Array[]        # !> a field has no default value; set it in initialize, which runs after Bag.new
end
```

```ruby
class Bag
  attr_reader items
  def initialize(b)
    @items = Array[] if @items == nil
  end
  def add(b, x) = Array.push(@items, x)
end
b = Bag.new
Bag.add(b, 1)
p(Bag.items(b))                      # => [1]
```

### A field named like a reserved word

A field named like a reserved word is declared as a Symbol: `attr_accessor :next`. Written bare it would not parse. Its reader is `Node.next(n)`, and `@next` inside the functions works as usual.

```ruby
class Node
  attr_accessor value, :next
  def last_value(n)
    nx = @next
    nx ? last_value(nx) : @value
  end
end
list = Node.new(1, Node.new(2, nil))
p(Node.next(Node.next(list)))        # => nil
p(Node.last_value(list))             # => 2
```

### One type per construction

For the checker, each `C.new` is its own type. Instances made at different places keep their own field types, so a `Heap` of Integers and a `Heap` of Strings do not mix. When one `C.new` sits in a function called with different argument types (`expect(42)` and `expect("x")`), the types are separate per call too. A generic wrapper (`Ok.new(yield(@value))` in `Result.map`) is one type per caller.

- Messages name such a type with its site (`Heap@L7`) only when the type has several.
- Values built from values (`Value.new(a + b)` inside a function taking Values) stay one type per place.

```ruby
class Heap
  attr_reader items
  def push(h, x) = Array.push(@items, x)
  def top(h) = Array.first(@items)
end
ints = Heap.new(Array[])
Heap.push(ints, 3)
words = Heap.new(Array[])
Heap.push(words, "job")
p(Heap.top(ints) + 1)                # => 4
p(String.upcase(Heap.top(words)))    # => "JOB"
```

### class B < A

`class B < A` is shorthand for writing A's definitions in B. It is not inheritance.

- A's fields come first, then B's.
- A's functions are B's too. Inside them, unqualified names and `@x` mean B's.
- A's `include`s are B's.
- B's own definition of a function wins over A's.
- Nothing relates A and B afterwards. A B is not an A: `A.f(b)` is a type error, and `b in A` is false.
- `<` takes a class of the program (or a `Struct.new` type). A module is included with `include`.

```ruby
class Shape
  attr_reader name
  def describe(s) = "a shape called " + @name
end
class Circle < Shape
  attr_reader r
  def area(c) = 3.0 * @r * @r
end
class Square < Shape
  attr_reader side
  def describe(s) = "a square called " + @name
end
c = Circle.new("c1", 2.0)
p(c)                                 # => #<struct Circle name="c1", r=2.0>
p(Circle.describe(c))                # => "a shape called c1"
p(Circle.area(c))                    # => 12.0
p(Square.describe(Square.new("s1", 3.0)))   # => "a square called s1"
```

```ruby error
class Shape
  attr_reader name
  def describe(s) = @name            # !> Shape.name: argument 1 must be Shape, but is Circle [type]
end
class Circle < Shape
  attr_reader r
end
p(Shape.describe(Circle.new("c", 2.0)))
```

### Exception types

`class E < Exception` (or `< StandardError`) declares an exception type: `message` is its first field, then the fields of its `attr_*` lines. The fields after `message` may always be left out: `E.new("msg")` gives the message only. The form `raise E, "msg"` is for an exception type with no fields besides `message` ([Exceptions and errors](08-exceptions.md)).

```ruby
class ParseError < StandardError
  attr_reader line
end
begin
  raise ParseError.new("bad token", 7)
rescue ParseError => e
  p(ParseError.message(e))           # => "bad token"
  p(ParseError.line(e))              # => 7
end
begin
  raise ParseError.new("no line")
rescue ParseError => e
  p(ParseError.line(e))              # => nil
end
```

### Shorthands: Struct.new and Exception.new

`Struct.new(:x, :y)` is shorthand for `class C` with `attr_accessor x, y`. Ruby's form `class C < Struct.new(:x, :y)` also works: it declares those fields first, then the body's `attr_*` lines and functions. `Exception.new(:line)` is shorthand for `class C < Exception` with `attr_accessor line`.

```ruby
class Point < Struct.new(:x, :y)
  attr_reader label
  def to_s(pt) = @label + "(" + Integer.to_s(@x) + ", " + Integer.to_s(@y) + ")"
end
p(Point.to_s(Point.new(1, 2, "P")))  # => "P(1, 2)"
Oops = Exception.new(:line)
begin
  raise Oops.new("oops", 3)
rescue Oops => e
  p(Oops.line(e))                    # => 3
end
```

### Static errors in a declaration

Each of the following is a static error, and the checker's hint shows the fix.

- `attr_reader :x`: a field that is not a reserved word, written as a Symbol (write it bare).
- A field declared in a `class C` after the first one.
- A default value, `attr_reader x = v`.
- A write from outside the class to a read-only (`attr_reader`) field.
- The old form `class C < {reader: [...]}`; the hint gives the `attr_*` lines.

## The operations of Struct.new

```ruby
Point = Struct.new(:x, :y)
```

This defines the namespace `Point` with the following operations.

| Operation | Meaning |
|---|---|
| `Point.new(x, y)` | create; positional arguments, one per field |
| `Point.x(p)`, `p.Point.x` | read field `x` (the reader has the field's name) |
| `Point.set_x(p, v)`, `p.Point.x = v` | write field `x` in place; returns `v` |
| `p.Point.x += v`, `\|\|=`, `&&=` | `p.Point.x = p.Point.x + v` with `p` evaluated once |
| `Point[p1, ...]` | an Array of Point |
| `p == nil`, `p != nil` | comparison with nil |

```ruby
Point = Struct.new(:x, :y)
pt = Point.new(3, 4)
p(pt)                                # => #<struct Point x=3, y=4>
p(Point.x(pt))                       # => 3
p(Point.set_x(pt, 10))               # => 10
pt.Point.y += 1
p(pt)                                # => #<struct Point x=10, y=5>
pts = Point[Point.new(1, 2), Point.new(3, 4)]
p(pts)                               # => [#<struct Point x=1, y=2>, #<struct Point x=3, y=4>]
p(pt == nil)                         # => false
```

### Mutability

Values are mutable and shared by reference. A change made through one variable is visible through every other variable that holds the same value.

```ruby
Point = Struct.new(:x, :y)
pt = Point.new(3, 4)
q = pt
Point.set_y(q, 0)
p(pt)                                # => #<struct Point x=3, y=0>
```

### Adding operations

Add your own operations in `class Point ... end` or with `def Point.f`. Inside them, the readers and writers can be called unqualified (`x(p)`, `set_x(p, v)`). A function named like a field (`def x(p) = ...`) replaces its reader, as a method after `attr_reader` does in Ruby; `@x` still reads the field.

```ruby
Point = Struct.new(:x, :y)
def Point.shift(pt, dx)
  @x += dx
  pt
end
class Point
  def norm2(pt) = @x * @x + @y * @y
  def x(pt) = 100
end
pt = Point.new(3, 4)
p(Point.shift(pt, 1))                # => #<struct Point x=4, y=4>
p(Point.norm2(pt))                   # => 32
p(Point.x(pt))                       # => 100
```

### Field shorthand @x

Inside a function of a class (in `class Point` or `def Point.f`), `@x` means field `x` of the function's **first parameter**. The first parameter is the subject by convention.

| Written | Means |
|---|---|
| `@x` | `Point.x(p)` |
| `@x = v` | `Point.set_x(p, v)` |
| `@x OP= v` | `Point.set_x(p, Point.x(p) OP v)` |
| `@x \|\|= v` | `Point.x(p) \|\| Point.set_x(p, v)` |

- `p` is the first parameter's current value, even inside a block whose parameter has the same name.
- The usual runtime check applies: the first argument must be a Point.
- `@x` is a static error in each of these cases: outside a function of a class, in a function with no parameters, and when the field does not exist.

```ruby error
Point = Struct.new(:x, :y)
def far(pt) = @x > 100               # !> `@x` means a field of the first argument, so it is only available in a function of a class
```

### Printing

`p` prints a Struct value as `#<struct Point x=1, y=2>`. `puts` prints it the same way.

### Restrictions of Struct.new

`Struct.new` must be assigned to a top-level constant. It takes symbols only, and no block; functions are defined in `class Point`.

There is no `Data.define`: it is rejected with a hint to use `Struct.new`. Ruby's `Data` is immutable, but Sake's named types are mutable, which is what Ruby's `Struct` provides.

```ruby error
Point = Data.define(:x, :y)          # !> Sake's named types are mutable, so they are made with Struct.new, not Data.define
```

### Copying: Kernel.dup

`Kernel.dup(x)` is a shallow copy: new containers and Struct values, the same elements. A type that defines `dup` gets its own.

```ruby
Point = Struct.new(:x, :y)
a = Point.new(1, Array[2])
b = Kernel.dup(a)
Point.set_x(b, 9)
Array.push(Point.y(b), 3)
p(a)                                 # => #<struct Point x=1, y=[2, 3]>
p(b)                                 # => #<struct Point x=9, y=[2, 3]>
```
