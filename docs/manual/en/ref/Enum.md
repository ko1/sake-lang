# Enum

Enum is Ruby's Enumerable under a short name, a module that the prelude (`sakelib/prelude.sake`, read before every program) defines in Sake. Its functions, `Enum.map(x) { }` and the others, are mixin functions: they dispatch on the type of the first argument ([Program structure](../02-program.md), "Calling a module's functions"). Array, Hash, Set and Range include Enum and answer with their own operations: `Enum.map(xs)` is `Array.map(xs)` when xs is an Array, and `Enum.each(h) { |k, v| }` is `Hash.each`. Nothing is copied into a built-in type. A value of any other type (an Integer, a Tuple, a String) is a `type` problem before running and a `TypeError` while running. Tuple does not include Enum: its length and position types are fixed, so it is indexed and destructured instead.

A class of your own joins with `include Enum` and `def each(c) = ... yield(v) ...`. Every other function of Enum is written over `each`, so they are copied into the class ([include](../02-program.md)) and `C.map(c) { }`, `C.count(c)` and `Enum.first(c)` all work; the class's own definition of one of them wins.

```ruby
class Deck
  include Enum
  attr_reader cards
  def each(d) = Array.each(@cards) { |c| yield(c) }
end
d = Deck.new(Array["A", "K", "Q", "J"])
p(Deck.map(d) { |c| String.downcase(c) })     # => ["a", "k", "q", "j"]
p(Enum.count(d))                              # => 4
p(Enum.select(Array[3, 1, 2]) { |v| v > 1 })  # => [3, 2]
```

```ruby error
p(Enum.map(5) { |v| v })                      # !> Enum.map dispatches on its first argument, which is Integer; the types that include Enum are Array, Hash, Set, Range
```

The functions whose result may be nil (`find`, `first`, `min_by`, `max_by`) return `nil | T` in a class's copy, and using that unchecked is reported at level 2; dispatched to a built-in type, they follow that type's operation (the nil of a miss of `Array.first` is level 3). The sections below describe Enum's own definitions; on a built-in type the operation of the same name runs ([Array](Array.md), [Hash](Hash.md), [Set](Set.md), [Range](Range.md)).

## each

`Enum.each(x)`

The required function. A class that includes Enum defines `def each(c)` and calls `yield(v)` for each element (two values are fine, as Hash does). `Enum.each(x) { }` dispatches to the `each` of x's type. A class that does not define it is a `type` problem wherever a call can reach it, and `NotImplementedError` while running.

```ruby
Enum.each(Hash[a: 1, b: 2]) { |k, v| puts("#{k}: #{v}") }
# => a: 1
# => b: 2
```

## map

`Enum.map(x) { }`

An Array of the block's value for each element.

```ruby
p(Enum.map(1..3) { |v| v * v })               # => [1, 4, 9]
p(Enum.map(Set[1, 2]) { |v| -v })             # => [-1, -2]
```

## select, filter

`Enum.select(x) { }`

`Enum.filter(x) { }`

An Array of the elements for which the block is true.

```ruby
p(Enum.select(Array[1, 2, 3, 4]) { |v| v % 2 == 0 })   # => [2, 4]
p(Enum.filter(1..6) { |v| v > 4 })                     # => [5, 6]
```

## reject

`Enum.reject(x) { }`

An Array of the elements for which the block is false.

```ruby
p(Enum.reject(Array[1, 2, 3, 4]) { |v| v % 2 == 0 })   # => [1, 3]
```

## filter_map

`Enum.filter_map(x) { }`

Applies the block to each element and keeps the true results (nil and false are dropped).

```ruby
p(Enum.filter_map(Array["1", "x", "3"]) { |s| String.to_i(s) if String.match?(s, /\A\d+\z/) })   # => [1, 3]
```

## flat_map

`Enum.flat_map(x) { }`

The Arrays (or Tuples) the block returns, joined one level deep.

```ruby
p(Enum.flat_map(Array[1, 2]) { |v| Array[v, v * 10] })   # => [1, 10, 2, 20]
```

## find, detect

`Enum.find(x) { }`

`Enum.detect(x) { }`

The first element for which the block is true, or nil when there is none (level 2 in a class's copy, and for `Array.find` and its kin).

```ruby
p(Enum.find(Array[3, 8, 5]) { |v| v > 4 })    # => 8
p(Enum.detect(1..3) { |v| v > 9 })            # => nil
```

## reduce, inject

`Enum.reduce(x, init) { }`

`Enum.inject(x, init) { }`

Starting from `init`, calls the block as `yield(acc, v)` for each element and returns the last accumulated value. Unlike Ruby's, the initial value cannot be left out: the result type would not follow from the element type alone (as for [Array](Array.md)'s `reduce`).

```ruby
p(Enum.reduce(Array[1, 2, 3], 0) { |acc, v| acc + v })     # => 6
p(Enum.inject(1..4, 1) { |acc, v| acc * v })               # => 24
```

## sum

`Enum.sum(x, [init]) [{ }]`

The sum of the elements, or of the block's values, starting from `init` (default 0). On a built-in type the elements must be numbers or values of a type that includes `Arithmetic` ([Array](Array.md)).

```ruby
p(Enum.sum(1..4))                             # => 10
p(Enum.sum(Array[1, 2, 3]) { |v| v * 10 })      # => 60
```

## count

`Enum.count(x) [{ }]`

The number of elements, or of those for which the block is true.

```ruby
p(Enum.count(Set[1, 2, 3]))                   # => 3
p(Enum.count(1..10) { |v| v % 3 == 0 })       # => 3
```

## include?

`Enum.include?(x, v)`

True when some element is `==` to `v`.

```ruby
p(Enum.include?(1..5, 3))                     # => true
p(Enum.include?(Array["a"], "b"))             # => false
```

## any?, all?, none?, one?

`Enum.any?(x) [{ }]`

`Enum.all?(x) [{ }]`

`Enum.none?(x) [{ }]`

`Enum.one?(x) [{ }]`

True when the block is true for at least one element / for all / for none / for exactly one. Without a block, the elements' own truth counts.

```ruby
xs = Array[1, 2, 3]
p(Enum.any?(xs) { |v| v > 2 })                # => true
p(Enum.all?(xs) { |v| v > 2 })                # => false
p(Enum.none?(xs) { |v| v > 5 })               # => true
p(Enum.one?(xs) { |v| v > 2 })                # => true
```

## min_by, max_by

`Enum.min_by(x) { }`

`Enum.max_by(x) { }`

The element with the smallest / largest block value; nil when empty. The block's values must be comparable with each other (the checker sees to it statically).

```ruby
words = Array["pear", "fig", "banana"]
p(Enum.min_by(words) { |w| String.length(w) })   # => "fig"
p(Enum.max_by(words) { |w| String.length(w) })   # => "banana"
```

## sort_by

`Enum.sort_by(x) { }`

An Array of the elements in ascending order of the block's value.

```ruby
p(Enum.sort_by(Array["bb", "a", "ccc"]) { |s| -String.length(s) })   # => ["ccc", "bb", "a"]
```

## to_a

`Enum.to_a(x)`

A new Array of the elements.

```ruby
p(Enum.to_a(1..3))                            # => [1, 2, 3]
p(Enum.to_a(Hash[a: 1]))                      # => [[:a, 1]]
```

## first

`Enum.first(x, [n])`

The first element (nil when empty), or with `n` an Array of the first `n`.

```ruby
p(Enum.first(Array[7, 8, 9]))                 # => 7
p(Enum.first(1..10, 3))                       # => [1, 2, 3]
```

## take, drop

`Enum.take(x, n)`

`Enum.drop(x, n)`

An Array of the first `n` elements / of all but the first `n`.

```ruby
p(Enum.take(1..5, 2))                         # => [1, 2]
p(Enum.drop(1..5, 2))                         # => [3, 4, 5]
```

## group_by

`Enum.group_by(x) { }`

A Hash from each block value to the Array of the elements that gave it.

```ruby
p(Enum.group_by(1..6) { |v| v % 3 })          # => {1 => [1, 4], 2 => [2, 5], 0 => [3, 6]}
```

## partition

`Enum.partition(x) { }`

A Tuple `[yes, no]`: the elements for which the block is true, and the others.

```ruby
yes, no = Enum.partition(1..6) { |v| v > 3 }
p(yes)                                        # => [4, 5, 6]
p(no)                                         # => [1, 2, 3]
```

## each_with_object

`Enum.each_with_object(x, memo) { }`

Calls the block as `yield(v, memo)` for each element and returns `memo`.

```ruby
p(Enum.each_with_object(Array[1, 2], Array[]) { |v, m| Array.unshift(m, v) })   # => [2, 1]
```

## compact

`Enum.compact(x)`

An Array of the elements that are not nil.

```ruby
p(Enum.compact(Array[1, nil, 2]))             # => [1, 2]
```
