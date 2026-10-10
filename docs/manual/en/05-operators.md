# Operators and indexing

This chapter covers the binary operators such as `a + b` and the index `x[k]`. Both are shorthands for a module's function, resolved by the type of the left operand (the receiver). A class gets operators and an index by including that module and defining the functions.

## Binary operators

Each operator belongs to a module, and `a OP b` is shorthand for calling that module's function: `a + b` is `Arithmetic.+(a, b)`. A module's function is resolved by the type of its first argument ([module functions and dispatch](02-program.md)), so the call runs `T.+(a, b)` where `T` is the type of `a`: an operator dispatches on its **left operand**. Error messages name the module's function (`Arithmetic.*: ...`).

```ruby
p(1 + 2)                  # => 3
p(Arithmetic.+(1, 2))     # => 3
p(Integer.+(1, 2))        # => 3
p("a" + "b")              # => "ab"
```

| Module | Operators | Built-in types that include it |
|---|---|---|
| `Arithmetic` | `+ - * / % **`, unary `-x` `+x` (`-@` `+@`) | Integer, Float, Rational, Complex, String, Time, Set |
| `Comparable` | `<=> < <= > >=` | Integer, Float, Rational, String, Time, Tuple, Array |
| `Bitwise` | `& \| ^ << >>`, unary `~x` | Integer, Set |
| `Indexable` | `[]`, `[]=` (see "Indexing") | Array, Hash, String, Tuple, MatchData |
| `Kernel` | `== != =~ !~` | every type |

### Explicit forms

`Arithmetic.+(a, b)` dispatches exactly as `a + b` does. `Integer.+(a, b)` calls Integer's `+` directly: `a` must be an Integer, and `b` may be any type that Integer's `+` accepts.

```ruby error
p(Integer.+("a", "b"))    # !> Integer.+: argument 1 must be Integer, but is String
```

### Giving your own type an operator

A class joins an operator by including the module and defining the operator in its body, such as `include Arithmetic` with `def +(a, b)`. With `include Comparable`, defining `<=>` is enough: `<`, `<=`, `>`, and `>=` come from it, and `Array.sort`, `min`, and `max` use that `<=>` too.

```ruby
class Money
  include Arithmetic
  include Comparable
  attr_reader cents
  def +(a, b) = Money.new(@cents + Money.cents(b))
  def <=>(a, b) = @cents <=> Money.cents(b)
  def to_s(m) = format("$%d.%02d", @cents / 100, @cents % 100)
end
a = Money.new(150)
b = Money.new(250)
puts(a + b)                                        # => $4.00
p(a < b)                                           # => true
puts(Array.join(Array.sort(Array[b, a]), " "))     # => $1.50 $2.50
```

When the left operand's type does not include the operator's module, or does not define the operator, it is a `type` problem before running and a `TypeError` while running.

```ruby error
Point = Struct.new(:x, :y)
p(Point.new(1, 2) + Point.new(1, 2))   # !> Arithmetic.+: Point does not include Arithmetic
```

### A built-in on the left: coerce

`2 + money` dispatches on Integer, whose table has no row for Money. A class that defines `coerce(b, a)`, giving a Tuple `[left, right]` as Ruby's protocol does, has the pair converted first and the operator run on it. With the `coerce` below, `2 + money` becomes `Money.new(200) + money`. The checker follows the conversion.

```ruby
class Money
  include Arithmetic
  attr_reader cents
  def +(a, b) = Money.new(@cents + Money.cents(b))
  def coerce(m, other) = [Money.new(other * 100), m]
end
m = Money.new(50)
p(2 + m)                  # => #<struct Money cents=250>
```

### Equality

`==` on a class's values compares the type and the fields, as Ruby's Struct does, unless the type defines its own `==`. `Array.include?`, `index`, and similar operations use the same equality.

```ruby
Point = Struct.new(:x, :y)
p(Point.new(1, 2) == Point.new(1, 2))   # => true
p(Point.new(1, 2) == Point.new(2, 1))   # => false
p(Point.new(1, 2) == "x")               # => false
p(Array.include?(Array[Point.new(1, 2)], Point.new(1, 2)))   # => true
```

A type that includes `Comparable` and defines `<=>` (and not `==`) is equal to a value of the same type when `<=>` gives 0, as Ruby's `Comparable#==`. A value of another type, such as nil, is never equal, and `<=>` is not called then. For the Money above, `a == Money.new(150)` is true and `a == nil` is false.

### The table for the built-in types

For the built-in types, the result type depends on both operand types, through a **closed table**.

| Operator | Rows |
|---|---|
| `+` | (Integer, Integer) → Integer; with a Float → Float; with a Rational (and no Float) → Rational; with a Complex → Complex; (String, String) → String |
| `-` `*` `/` `%` `**` | numeric pairs as for `+` |
| `*` | also (String, Integer) → String |
| `<` `<=` `>` `>=` `<=>` | numeric pairs, (String, String), (Tuple, Tuple), (Array, Array) → true/false (`<=>`: -1, 0, 1, or nil) |
| `==` `!=` | **any two values**: equal values of the same type (numbers compare across Integer, Float, Rational); values of different types are not equal, as in Ruby |
| `+` `-` | also (Array, Array) → Array (concatenation; difference) |
| `*` | also (Array, Integer) → Array (repetition) |
| `<` `<=` `>` `>=` `<=>` | also (Symbol, Symbol) |
| unary `-` `+` | Integer, Float, Rational, Complex → the same type |
| unary `~` | Integer → Integer |
| `&` `\|` `^` `<<` `>>` | (Integer, Integer) → Integer |
| `\|` `&` `-` | (Set, Set) → Set (union, intersection, difference) |
| `=~` | (String, Regexp), (Regexp, String) → Integer or nil; `!~` (String, Regexp) → true/false |
| `%` | (String, Integer / Float / String / Symbol / Tuple / nil / true / false) → String, Ruby's format (`"%d items" % 3`, `"%s-%s" % [a, b]`) |

```ruby
p("ab" * 3)                    # => "ababab"
p(Array[1, 2] + Array[3])      # => [1, 2, 3]
p(Array[1, 2, 3] - Array[2])   # => [1, 3]
p(Set[1, 2] | Set[2, 3])       # => Set[1, 2, 3]
p(5 & 3)                       # => 1
p(1 << 4)                      # => 16
p("abc" =~ /b/)                # => 1
p("abc" !~ /z/)                # => true
p("%s-%s" % ["a", "b"])        # => "a-b"
```

### No matching row

If no row matches the operand types, it is a `type` problem before running and a `TypeError` while running. The runtime message lists the rows that do exist. There is no implicit conversion.

```ruby error
p("a" - "b")   # !> Arithmetic.-: the operands are (String, String), which the left operand's type does not support
```

### Numbers

`/` and `%` on Integers follow Ruby, rounding toward the floor for negative numbers. Dividing an Integer by zero raises `ZeroDivisionError`; Float division by zero follows IEEE.

```ruby
p(7 / 2)        # => 3
p(-7 / 2)       # => -4
p(-7 % 2)       # => 1
p(7.0 / 2)      # => 3.5
p(1 / 2r)       # => (1/2)
p(1.0 / 0)      # => Infinity
```

- **Negative exponent.** `Integer ** negative Integer` raises `ArgumentError`, so that the type of `a ** b` does not depend on the value of `b`. Write `2r ** -1` for a Rational (`(1/2)`).
- **Complex.** A Complex has no ordering, so `<` and the like are not defined for it.

```ruby error
p(1 / 0)        # !> ZeroDivisionError: Arithmetic./: divided by 0
```

```ruby error
p(2 ** -1)      # !> ArgumentError: Arithmetic.**: Integer ** negative Integer (2 ** -1) is an error; for a Rational, write 2r ** -1
```

### Time

`Time ± number` gives a Time, and `Time - Time` gives a Float of seconds. Two Times compare.

```ruby
t = Time.at(0, in: "+00:00")
p(t + 60)                 # => 1970-01-01 00:01:00 +0000
p(Time.at(60) - t)        # => 60.0
p(t < Time.at(1))         # => true
```

### Rules of equality and ordering

Values of different types are never equal: `1 == :a` and `struct == "x"` are false, as in Ruby. A class's own `==` decides for its values. Only numbers compare across Integer, Float, and Rational.

```ruby
p(1 == 1.0)     # => true
p(1 == 1r)      # => true
p(1 == :a)      # => false
p("1" == 1)     # => false
```

Tuples, Arrays, Sets, Hashes, and Records are equal when their contents are. Two Records also need the same fields. Tuples and Arrays are ordered element by element, as Ruby's Arrays are.

```ruby
p([1, 2] == [1, 2])                 # => true
p([1, 2] == Array[1, 2])            # => false
p({x: 1} == {x: 1, y: 2})           # => false
p(Set[1, 2] == Set[2, 1])           # => true
p([1, 2] < [1, 3])                  # => true
p(Array[1, 2] <=> Array[1, 2, 0])   # => -1
```

When two elements cannot be compared, `<` and the like raise `ArgumentError` and `<=>` gives nil. Before running, the checker reports element types that cannot be compared.

```ruby error
p(Array["a", 1] < Array["a", "b"])   # !> Comparable.<: elements compared in order may be (Integer, String), which cannot be compared
```

### Not operators

- **`!x`** is `x ? false : true`. It works on any value and is not an operation of a type.
- **Compound assignment.** `x OP= e` means `x = x OP e`.
- **`&&` and `||`** short-circuit and return one of their operands, as in Ruby.

```ruby
p(!0)                  # => false
p(!nil)                # => true
x = 5
x += 2
p(x)                   # => 7
p(nil || "default")    # => "default"
p(1 && "second")       # => "second"
```

## Indexing

`x[k]` means `Indexable.[](x, k)`, and `x[k] = v` means `Indexable.[]=(x, k, v)`: they run the `[]` and `[]=` of `x`'s type.

```ruby
xs = Array[10, 20, 30]
p(xs[0])                  # => 10
p(xs[-1])                 # => 30
p(xs[1..])                # => [20, 30]
p(xs[0, 2])               # => [10, 20]
p(Indexable.[](xs, 1))    # => 20
xs[1] = 25
p(xs)                     # => [10, 25, 30]
```

The built-in types behave as follows.

| Receiver, index | `x[k]` | `x[k] = v` |
|---|---|---|
| Array, Integer | the element, or nil outside the Array | stores `v` (an Array of T checks `v`) |
| String, Integer | a one-character String, or nil outside the String | not available |
| Tuple, Integer | the element; outside the Tuple, `IndexError` | stores `v` if it has the type of that position |
| Array, Range / String, Range | the slice, or nil | not available |
| Array, Integer, Integer / String, Integer, Integer (`s[start, length]`) | the slice, or nil | not available |
| Hash, any key | the value, or the default (nil unless made by `Hash.new(default)`) | stores `v` |
| MatchData, Integer / String | the group, or nil | not available |

```ruby
s = "hello"
p(s[0])                   # => "h"
p(s[1..2])                # => "el"
p(s[1, 3])                # => "ell"
h = Hash["a" => 1]
p(h["a"])                 # => 1
p(h["z"])                 # => nil
p(Hash.new(0)["z"])       # => 0
m = String.match("2026-10", /(\d+)-(\d+)/)
if m
  p(m[0])                 # => "2026-10"
  p(m[2])                 # => "10"
end
```

### An index outside

Negative indexes count from the end, as in Ruby. A miss gives `nil`, as in Ruby, so the static type of `a[i]` is `T | nil`. A result used unchecked is reported by `index-nil` at level 3; level 2 lets it pass, and the program stops at that operation while running. `Array.fetch(a, i)` raises `IndexError` instead.

```ruby error
xs = Array[10, 20, 30]
p(xs[5] + 1)              # !> TypeError: Arithmetic.+: no implementation for (nil, Integer)
```

```ruby error
xs = Array[10, 20, 30]
p(Array.fetch(xs, 5))     # !> IndexError: Array.fetch: index 5 outside of array bounds: -3...3
```

A Tuple's length is part of its type, so an index outside it is an `IndexError`. With a constant index it is reported before running.

```ruby error
t = [1, "a"]
p(t[2])                   # !> Indexable.[]: the index is outside the Tuple [Integer, String]
```

### Writing

Writing past the end of an untyped Array fills the gap with nil, as in Ruby. An Array of T raises `IndexError` instead, because nil is not a T. Writing a value that is not a T is a `type` problem before running. A Tuple takes only a value of the position's type. A String cannot be written to.

```ruby
xs = Array[1]
xs[3] = 4
p(xs)                     # => [1, nil, nil, 4]
```

```ruby error
ys = Integer[1]
ys[3] = 4                 # !> IndexError: Array.[]=: index 3 is past the end of Integer[] (length 1); the gap would be nil
```

```ruby error
ys = Integer[1]
ys[0] = "a"               # !> Indexable.[]=: an element must be Integer, but is String
```

### Compound assignment

`x[k] OP= v` and `x[k] ||= v` evaluate `x` and `k` once. On a local, `y ||= v` assigns only when `y` is nil or false.

```ruby
h = Hash[]
h[:a] ||= Array[]
Array.push(h[:a], 1)
h[:a] ||= Array[]
p(h)                      # => {a: [1]}
y = nil
y ||= 5
y ||= 6
p(y)                      # => 5
```

### Giving your own type an index

A class joins with `include Indexable` and `def [](x, k)` / `def []=(x, k, v)`. With two indexes, `m[r, c]` calls `def [](m, r, c)` and `m[r, c] = v` calls `def []=(m, r, c, v)`.

```ruby
class Grid
  include Indexable
  attr_reader w, cells
  def [](g, r, c) = @cells[r * @w + c]
  def []=(g, r, c, v)
    @cells[r * @w + c] = v
  end
end
g = Grid.new(2, Array[0, 0, 0, 0])
g[1, 0] = 7
p(g[1, 0])                # => 7
p(Grid.cells(g))          # => [0, 0, 7, 0]
```
