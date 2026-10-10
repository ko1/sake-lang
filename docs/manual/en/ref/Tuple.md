# Tuple

A Tuple is a sequence of fixed length with a type per position. The literal `[1, "a"]` makes a Tuple (Ruby's `[1, "a"]` is an Array; in Sake the Array is `Array[1, "a"]`, see [Values and types](../03-values.md)). The number of elements and the type at each position are part of the value's type, so the checker sees index ranges and position types statically. A Tuple cannot grow or shrink; use an Array for a sequence of varying length.

Multiple assignment `a, b = t` and the Tuple pattern `in [Integer, String]` take a Tuple apart. A function's `return a, b` returns a Tuple.

The operators on Tuples are `==`, `!=`, `<`, `<=`, `>`, `>=`, `<=>` (two Tuples compare in dictionary order) and the index `t[i]`, `t[i] = v`. The entries `Tuple.<(x, y)` and so on below are the function forms of those operators ([Operators and indexing](../05-operators.md)).

## Tuple[]

`Tuple[*Any]`

Makes an **Array of Tuples** (not a Tuple). It is a typed Array like `Integer[]` and `String[]`: every element must be a Tuple, and every write (`Array.push`, ...) is checked. An element that is not a Tuple is a `type` problem statically and a `TypeError` at run time. The empty Array of Tuples is `Tuple[]`.

```ruby
pairs = Tuple[[1, "a"], [2, "b"]]
Array.push(pairs, [3, "c"])
p(pairs)                   # => [[1, "a"], [2, "b"], [3, "c"]]
p(Array.size(Tuple[]))     # => 0
```

```ruby error
Array.push(Tuple[], 1)     # !> Array.push: an element must be Tuple, but is Integer
```

## []

`Tuple.[](x, Any)`

The function form of `t[i]`. Returns the element at position `i` (an Integer; a negative one counts from the end). The result has the type of that position. Because a Tuple's length is part of its type, an index outside it does not give nil as an Array's does: it is a `type` problem statically (`the index is outside the Tuple`) and an `IndexError` at run time. A Range is not accepted as the index (`TypeError`).

```ruby
t = [1, "a", 2.5]
p(t[0])                    # => 1
p(t[-1])                   # => 2.5
p(Tuple.[](t, 1))          # => "a"
```

```ruby error
t = [1, 2]
p(t[5])                    # !> the index is outside the Tuple
```

## []=

`Tuple.[]=(x, Any, Any)`

The function form of `t[i] = v`. Replaces the element at position `i` with `v` and returns `v`. A value whose type differs from that position's type is a `type` problem statically and a `TypeError` at run time. An index outside the Tuple is an `IndexError`.

```ruby
t = [1, "a"]
t[0] = 10
Tuple.[]=(t, 1, "b")
p(t)                       # => [10, "b"]
```

```ruby error
t = [1, 2]
t[0] = "x"                 # !> the value must be Integer, but is String
```

## length, size

`Tuple.length(x)`

`Tuple.size(x)`

The number of elements (an Integer). A Tuple's length follows from its type, so to the checker it is a constant.

```ruby
p(Tuple.size([1, "a", 2.5]))     # => 3
p(Tuple.length([]))              # => 0
```

## max, min

`Tuple.max(x)`

`Tuple.min(x)`

The largest or smallest element (Ruby's `[a, b].max`). Since each position's type is known, whether the elements are comparable with each other is checked statically: an incomparable pair (an Integer and a String, say) is a `type` problem (`elements compared in order may be (Integer, String), which cannot be compared`), and a position that may be nil a `nil` problem. A comparison failure the checker cannot see (`Float.NAN`, say) is an `ArgumentError` at run time. Integers and Floats compare with each other. The empty Tuple `[]` gives nil. Struct values compare with their type's `<=>` (`include Comparable`). The result's type is the join of the positions' types; for a non-empty Tuple it is never nil.

```ruby
p(Tuple.max([3, 1, 2]))          # => 3
p(Tuple.min([3, 1, 2]))          # => 1
p(Tuple.max([2, 1.5]))           # => 2
p(Tuple.max([3, 1]) + 1)         # => 4
p(Tuple.max([]))                 # => nil
```

```ruby error
p(Tuple.max([1, "a"]))           # !> Tuple.max: elements compared in order may be (Integer, String), which cannot be compared
```

```ruby error
p(Tuple.max([1.0, Float.NAN]))   # !> ArgumentError: Tuple.max: cannot compare elements of types Float
```

## minmax

`Tuple.minmax(x)`

The two-element Tuple `[min, max]`. The comparison rules are those of `min` and `max` (an incomparable pair is a `type` problem statically).

```ruby
lo, hi = Tuple.minmax([3, 1, 2])
p([lo, hi])                      # => [1, 3]
```

## to_a

`Tuple.to_a(x)`

A new Array with the same elements. It is independent of the Tuple, and the Array can grow. Its element type is the union of the Tuple's position types.

```ruby
t = [1, "a"]
a = Tuple.to_a(t)
Array.push(a, :x)
p(a)                             # => [1, "a", :x]
p(t)                             # => [1, "a"]
```

## ==, !=

`Tuple.==(x, Any)`

`Tuple.!=(x, Any)`

True when the two Tuples have the same length and the elements at each position are `==` (`!=` is the negation). A right operand that is not a Tuple (an Array, nil) is never equal. `Array[1, 2]` and `[1, 2]` differ in type and are not equal.

```ruby
p([1, 2] == [1, 2])              # => true
p([1, 2] != [1, 2, 3])           # => true
p([1, 2] == Array[1, 2])         # => false
```

## <, <=, >, >=

`Tuple.<(x, Any)`

`Tuple.<=(x, Any)`

`Tuple.>(x, Any)`

`Tuple.>=(x, Any)`

Compare two Tuples in dictionary order: elements are compared from the front, the first differing position decides, and when all are equal the shorter Tuple is smaller. Each pair of positions must be of comparable types; a pair that is not is a `type` problem statically (`elements compared in order may be (Integer, String)`). The right operand must be a Tuple.

```ruby
p([1, 2] < [1, 3])               # => true
p([2] > [1, 9])                  # => true
p([1] < [1, 0])                  # => true
p(Tuple.<=([1, 2], [1, 2]))      # => true
```

```ruby error
p([1, 2] < [1, "a"])             # !> which cannot be compared
```

## <=>

`Tuple.<=>(x, Any)`

The result of the dictionary-order comparison as -1, 0, or 1. The rules are those of `<`. A Tuple returned as the key of `Array.sort_by` sorts in this order.

```ruby
p([1, 2] <=> [1, 2])             # => 0
p([1, 2] <=> [1, 2, 3])          # => -1
p(Array.sort_by(Array["bb", "a", "c"]) { |s| [String.size(s), s] })   # => ["a", "c", "bb"]
```
