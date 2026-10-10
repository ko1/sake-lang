# Array

An Array is a sequence whose length varies. `Array[1, 2, 3]` makes an Array. Ruby's `[1, 2, 3]` is an Array, but Sake's literal `[1, 2, 3]` is a Tuple of fixed length, and passing one to `Array.push` and the like is rejected statically ([Values and types](../03-values.md)). A typed Array such as `Integer[1, 2]`, `String[]` or `Point[p]` is an Array with a declared element type: every write (`Array.push`, `append`, `unshift`, `prepend`, `insert`, `concat`, `map!`, `fill`, `a[i] = v`, ...) is checked, and a value of another type is a `type` problem statically and a `TypeError` at run time. Every operation in this chapter works on typed Arrays too. The new Arrays returned by `map`, `select`, `sort`, `first(a, n)`, `+` and so on carry no element type declaration; only `dup` keeps it.

The checker gives one Array (one construction site) a single element type for the whole program. After an in-place rewrite such as `Array.map!` puts another type in, the Array is taken to hold both types from then on, and operations that fit only one of them become `type` (partial) problems ([Values and types](../03-values.md)).

Two kinds of operation use nil for "no element". The nil of a miss (`x[k]`, `first`, `last`, `pop`, `shift`, `min`, `max`, `at`, `sample`, `delete_at`: an empty Array or an index outside it), used unchecked, is an `index-nil` problem at `--strict=3` only; `--strict` (level 2) lets it pass. Every other nil (`find`, `index`, `find_index`, `rindex`, `bsearch`, `delete`, `min_by`, `dig`, `slice`, `uniq!`, ...) is a level 2 `nil` problem ([Overview](../01-overview.md)).

The operators on Arrays are `+`, `-`, `*`, `==`, `!=`, `<`, `<=`, `>`, `>=`, `<=>` (two Arrays compare in dictionary order) and the index `a[i]`, `a[i, n]`, `a[range]`, `a[i] = v`. The entries `Array.+(x, y)` and so on are the function forms of those operators ([Operators and indexing](../05-operators.md)). Operations that compare elements (`sort`, `min`, `max`, `<`, ...) need elements of comparable types: Integers and Floats compare with each other, Tuples element by element, Struct values with their type's `<=>` (`include Comparable`).

Operations with a block are written as in Ruby (`Array.map(xs) { |x| x * 2 }`). There is no Enumerator (no blockless `each`). The operations whose block is optional (`each_with_index`, `each_slice`, `each_cons`) return an Array when called without one.

## Array[]

`Array[*Any]`

Makes a new Array of the given elements. The elements may be of any types, mixed, and any value can be added later (the checker adds the type of each added value to the element type). The empty Array is `Array[]`. The literal `[1, 2]` is a Tuple, so a sequence that grows is always written `Array[...]`. A typed Array is made with the type's name, `Integer[1, 2]` (see that type's chapter).

```ruby
xs = Array[1, "a"]
Array.push(xs, :sym)
p(xs)                          # => [1, "a", :sym]
e = Array[]
Array.push(e, 1)
p(e)                           # => [1]
p([1, 2] == Array[1, 2])       # => false
```

```ruby error
xs = [1, 2]
Array.push(xs, 3)              # !> `[...]` is a Tuple with a fixed length; for a growable Array, write `Array[...]`
```

## new

`Array.new(Integer, [Any]) [{ }]`

Makes a new Array of length `n`. `Array.new(n)` holds n nils, `Array.new(n, v)` the same value `v` n times (one shared value: the two elements of `Array.new(2, Array[])` are the same Array), and `Array.new(n) { |i| ... }` the block's value for each index i. The element type is nil, the type of `v`, or the block's result type. A negative `n` is an `ArgumentError`.

```ruby
p(Array.new(3))                        # => [nil, nil, nil]
p(Array.new(2, "a"))                   # => ["a", "a"]
p(Array.new(3) { |i| i * i })          # => [0, 1, 4]
rows = Array.new(2, Array[])
Array.push(Array.fetch(rows, 0), 1)
p(rows)                                # => [[1], [1]]
rows2 = Array.new(2) { |i| Array[] }
Array.push(Array.fetch(rows2, 0), 1)
p(rows2)                               # => [[1], []]
```

```ruby error
Array.new(-1)                          # !> ArgumentError: Array.new: negative size -1
```

## dup

`Array.dup(x)`

A new Array with the same elements (a shallow copy: the elements are shared). The copy of a typed Array is a typed Array with the same element type; unlike every other new Array in this chapter, this one keeps the declaration.

```ruby
xs = Integer[1, 2]
ys = Array.dup(xs)
Array.push(ys, 3)
p(xs)                          # => [1, 2]
p(ys)                          # => [1, 2, 3]
```

```ruby error
ys = Array.dup(Integer[1])
Array.push(ys, "s")            # !> Array.push: an element must be Integer, but is String
```

## to_a

`Array.to_a(x)`

The subject itself (the same Array), not a copy. It exists for symmetry with `Tuple.to_a`, `Set.to_a`, `Hash.to_a` and the other operations that give an Array of another type.

```ruby
xs = Array[1, 2]
p(Array.to_a(xs))                          # => [1, 2]
p(Kernel.equal?(Array.to_a(xs), xs))       # => true
```

## length, size

`Array.length(x)`

`Array.size(x)`

The number of elements (an Integer).

```ruby
p(Array.size(Array[3, 1, 2]))      # => 3
p(Array.length(Array[]))           # => 0
```

## empty?

`Array.empty?(x)`

True when there are no elements.

```ruby
p(Array.empty?(Array[]))           # => true
p(Array.empty?(Array[1]))          # => false
```

## []

`Array.[](x, Any, [Integer])`

The function form of `a[i]`, `a[i, n]` and `a[range]`. `a[i]` is the element at position `i` (an Integer; a negative one counts from the end), or nil outside the Array. That nil is the nil of a miss: using it unchecked is an `index-nil` problem at `--strict=3` (level 2 does not report it). `a[i, n]` gives n elements from position i and `a[range]` the elements of the range, as a new Array, or nil when the start is past the end. Use `Array.fetch` for an exception instead. An index that is neither an Integer nor a Range is a `TypeError`.

```ruby
xs = Array[3, 1, 2]
p(xs[1])                       # => 1
p(xs[-1])                      # => 2
p(xs[9])                       # => nil
p(xs[1, 2])                    # => [1, 2]
p(xs[0..1])                    # => [3, 1]
p(xs[5, 1])                    # => nil
p(Array.[](xs, 0))             # => 3
p(Array.[](xs, 0, 2))          # => [3, 1]
```

## []=

`Array.[]=(x, Any, Any)`

The function form of `a[i] = v`. Replaces the element at position `i` with `v` and returns `v`. Writing past the end fills the gap with nil, as in Ruby. In a typed Array the type of `v` is checked (`type` statically, `TypeError` at run time), and since nil cannot be an element, writing past the end is an `IndexError`. A negative index before the start is an `IndexError`.

```ruby
xs = Array[1]
xs[3] = 2
p(xs)                          # => [1, nil, nil, 2]
xs[-1] = 5
p(xs)                          # => [1, nil, nil, 5]
p(Array.[]=(xs, 0, 0))         # => 0
```

```ruby error
is = Integer[1]
is[3] = 2                      # !> IndexError: Array.[]=: index 3 is past the end of Integer[] (length 1); the gap would be nil
```

## at

`Array.at(x, Integer)`

The element at position `i` (the same as `a[i]`; a negative one counts from the end). Outside the Array it is nil, the nil of a miss, reported at level 3 only.

```ruby
xs = Array[3, 1, 2]
p(Array.at(xs, 0))             # => 3
p(Array.at(xs, -1))            # => 2
p(Array.at(xs, 9))             # => nil
```

## fetch

`Array.fetch(x, Integer, [Any])`

The element at position `i`. Outside the Array it returns `default` when given and raises `IndexError` otherwise. The result is never nil (unless the default is), so it is the way to avoid the nil check of an index under `--strict`. The result type is the element type (joined with the default's type when given).

```ruby
xs = Array[3, 1, 2]
p(Array.fetch(xs, 1))          # => 1
p(Array.fetch(xs, -1))         # => 2
p(Array.fetch(xs, 9, 0))       # => 0
```

```ruby error
Array.fetch(Array[3, 1, 2], 9)     # !> IndexError: Array.fetch: index 9 outside of array bounds: -3...3
```

## first, last

`Array.first(x, [Integer])`

`Array.last(x, [Integer])`

`first(a)` is the first element and `last(a)` the last; on an empty Array nil (the nil of a miss, reported at level 3 only). `first(a, n)` and `last(a, n)` give the first or last n elements as a new Array (fewer when there are not enough; never nil). A negative n is an `ArgumentError`.

```ruby
xs = Array[3, 1, 2]
p(Array.first(xs))             # => 3
p(Array.last(xs))              # => 2
p(Array.first(xs, 2))          # => [3, 1]
p(Array.last(xs, 5))           # => [3, 1, 2]
p(Array.first(Array[]))        # => nil
p(Array.last(Array[], 2))      # => []
```

```ruby error
Array.first(Array[1], -1)      # !> ArgumentError: Array.first: negative size -1
```

## slice

`Array.slice(x, Integer|Range, [Integer])`

The same results as `a[i]`, `a[i, n]` and `a[range]`: `slice(a, i)` is an element or nil, `slice(a, i, n)` and `slice(a, range)` a new Array or nil (when the start is past the end). Unlike `a[i]`'s, this nil is reported as a level 2 `nil` problem.

```ruby
xs = Array[3, 1, 2]
p(Array.slice(xs, 1))          # => 1
p(Array.slice(xs, 1, 5))       # => [1, 2]
p(Array.slice(xs, 1..))        # => [1, 2]
p(Array.slice(xs, 9))          # => nil
```

```ruby error
y = Array.slice(Array[3, 1, 2], 0)
p(y + 1)                       # !> the operands may be nil
```

## dig

`Array.dig(x, Integer)`

The element at position `i` or nil (the same as `a[i]`). Ruby's `dig` takes any number of indexes and digs into nested values; in Sake it takes exactly one. The nil is a level 2 `nil` problem.

```ruby
xs = Array[Array[1, 2], Array[3]]
p(Array.dig(xs, 0))            # => [1, 2]
p(Array.dig(xs, 5))            # => nil
```

## values_at

`Array.values_at(x, *Integer)`

A new Array of the elements at the given positions. A position outside the Array gives nil (the element type is joined with nil).

```ruby
xs = Array[3, 1, 2]
p(Array.values_at(xs, 0, 2, 7))    # => [3, 2, nil]
```

## fetch_values

`Array.fetch_values(x, *Integer)`

A new Array of the elements at the given positions. A position outside the Array is an `IndexError` (never nil).

```ruby
p(Array.fetch_values(Array[3, 1, 2], 0, 2))    # => [3, 2]
```

```ruby error
Array.fetch_values(Array[3, 1, 2], 0, 9)       # !> IndexError: Array.fetch_values: index 9 outside of array bounds: -3...3
```

## push, append

`Array.push(x, *Any)`

`Array.append(x, *Any)`

Add the values (any number) at the end and return the subject. In place. A typed Array checks each value's type (`type` statically, `TypeError` at run time). The checker adds the added values' types to the Array's element type. There is no Ruby `<<`.

```ruby
xs = Array[1]
p(Array.push(xs, 2, 3))        # => [1, 2, 3]
p(Array.append(xs, 4))         # => [1, 2, 3, 4]
```

```ruby error
Array.push(Integer[1, 2], "x")     # !> Array.push: an element must be Integer, but is String
```

## unshift, prepend

`Array.unshift(x, *Any)`

`Array.prepend(x, *Any)`

Add the values (any number, in the order given) at the front and return the subject. In place. A typed Array checks the types.

```ruby
xs = Array[3]
p(Array.unshift(xs, 1, 2))     # => [1, 2, 3]
p(Array.prepend(xs, 0))        # => [0, 1, 2, 3]
```

## insert

`Array.insert(x, Integer, *Any)`

Inserts the values (any number) before position `i` and returns the subject. A negative `i` counts from the end (`-1` appends). When `i` is beyond the length the gap is filled with nil, as in Ruby (currently also in a typed Array: it is not an `IndexError`). A typed Array checks the inserted values' types.

```ruby
xs = Array[1, 2, 3]
p(Array.insert(xs, 1, 9, 9))   # => [1, 9, 9, 2, 3]
p(Array.insert(xs, -2, 7))     # => [1, 9, 9, 2, 7, 3]
p(Array.insert(Array[1], 3, 2))    # => [1, nil, nil, 2]
```

## concat

`Array.concat(x, Array)`

Appends all elements of the other Array and returns the subject. In place (`+` makes a new Array). A typed Array checks the elements' types.

```ruby
xs = Array[1]
p(Array.concat(xs, Array[2, 3]))   # => [1, 2, 3]
```

```ruby error
Array.concat(Integer[1], Array["a"])   # !> Array.concat: an element must be Integer, but is String
```

## fill

`Array.fill(x, Any)`

Replaces every element with `v` and returns the subject (the length does not change). Ruby's range and block forms do not exist. A typed Array checks the type of `v` at run time (`TypeError`; not reported statically).

```ruby
xs = Array[1, 2, 3]
p(Array.fill(xs, 0))           # => [0, 0, 0]
```

```ruby error
Array.fill(Integer[1], "a")    # !> TypeError: Array.fill: Integer[] element must be Integer, got String
```

## replace

`Array.replace(x, Array)`

Replaces the subject's contents with the other Array's elements and returns the subject (unlike `a = other`, every place that shares the Array sees it). A typed Array checks the elements' types statically (there is no run-time check).

```ruby
xs = Array[1, 2, 3]
ys = xs
p(Array.replace(xs, Array[9]))     # => [9]
p(ys)                              # => [9]
```

```ruby error
Array.replace(Integer[1], Array["a"])  # !> Array.replace: an element must be Integer, but is String
```

## pop

`Array.pop(x)`

Removes and returns the last element. On an empty Array nil (the nil of a miss, reported at level 3 only). There is no Ruby `pop(n)`.

```ruby
xs = Array[1, 2]
p(Array.pop(xs))               # => 2
p(xs)                          # => [1]
p(Array.pop(Array[]))          # => nil
```

## shift

`Array.shift(x, [Integer])`

`shift(a)` removes and returns the first element, nil on an empty Array (the nil of a miss, reported at level 3 only). `shift(a, n)` removes the first n elements and returns them as a new Array (fewer when there are not enough; never nil). A negative n is an `ArgumentError`.

```ruby
xs = Array[1, 2, 3, 4]
p(Array.shift(xs))             # => 1
p(Array.shift(xs, 2))          # => [2, 3]
p(xs)                          # => [4]
p(Array.shift(Array[]))        # => nil
p(Array.shift(Array[], 2))     # => []
```

## delete

`Array.delete(x, Any)`

Removes every element `==` to `v` and returns `v`. When there was none, nil (a level 2 `nil` problem).

```ruby
xs = Array[1, 2, 1, 3]
p(Array.delete(xs, 1))         # => 1
p(xs)                          # => [2, 3]
p(Array.delete(xs, 42))        # => nil
```

## delete_at

`Array.delete_at(x, Integer)`

Removes and returns the element at position `i`. Outside the Array nil (the nil of a miss, reported at level 3 only).

```ruby
xs = Array[1, 2, 3]
p(Array.delete_at(xs, 1))      # => 2
p(xs)                          # => [1, 3]
p(Array.delete_at(xs, 99))     # => nil
```

## slice!

`Array.slice!(x, Integer|Range, [Integer])`

Returns what `slice` returns and removes it from the subject: `slice!(a, i)` an element or nil, `slice!(a, i, n)` and `slice!(a, range)` a new Array or nil. The nil is a level 2 `nil` problem.

```ruby
xs = Array[1, 2, 3, 4]
p(Array.slice!(xs, 1, 2))      # => [2, 3]
p(xs)                          # => [1, 4]
p(Array.slice!(xs, 0))         # => 1
p(Array.slice!(xs, 5))         # => nil
p(Array.slice!(xs, 0..0))      # => [4]
p(xs)                          # => []
```

## clear

`Array.clear(x)`

Removes every element and returns the subject (now empty).

```ruby
xs = Array[1, 2]
p(Array.clear(xs))             # => []
p(xs)                          # => []
```

## each, each_entry

`Array.each(x) { }`

`Array.each_entry(x) { }`

Passes each element in order to the block and returns the subject. The block is required (there is no form returning Ruby's Enumerator). `break v` ends it at once with `v` as the result. `each_entry` is the same as `each`.

```ruby
xs = Array[1, 2, 3]
r = Array.each(xs) { |x| puts(x) }
# => 1
# => 2
# => 3
p(r)                                   # => [1, 2, 3]
p(Array.each(xs) { |x| break x if x == 2 })    # => 2
```

## each_with_index

`Array.each_with_index(x) [{ }]`

Passes each element and its index (from 0) to the block and returns the subject. Without a block it returns, instead of Ruby's Enumerator, a new Array of `[element, index]` Tuples.

```ruby
xs = Array["a", "b"]
Array.each_with_index(xs) { |s, i| puts("#{i}:#{s}") }
# => 0:a
# => 1:b
p(Array.each_with_index(xs))           # => [["a", 0], ["b", 1]]
```

## each_index

`Array.each_index(x) { }`

Passes the indexes 0 to length-1 in order to the block and returns the subject.

```ruby
xs = Array["a", "b"]
Array.each_index(xs) { |i| puts(i) }
# => 0
# => 1
```

## reverse_each

`Array.reverse_each(x) { }`

Passes each element to the block from the last to the first and returns the subject.

```ruby
Array.reverse_each(Array[1, 2, 3]) { |x| puts(x) }
# => 3
# => 2
# => 1
```

## each_slice, each_cons

`Array.each_slice(x, Integer) [{ }]`

`Array.each_cons(x, Integer) [{ }]`

`each_slice(a, n)` passes the elements cut into Arrays of n, and `each_cons(a, n)` each window of n consecutive elements, to the block, and returns the subject. Without a block they return, instead of Ruby's Enumerator, a new Array of those Arrays (`each_cons` gives `[]` when n exceeds the length). n must be at least 1 (a negative n is an `ArgumentError`; 0 is currently an error too, but Ruby's exception leaks through).

```ruby
xs = Array[1, 2, 3]
p(Array.each_slice(xs, 2))             # => [[1, 2], [3]]
p(Array.each_cons(xs, 2))              # => [[1, 2], [2, 3]]
Array.each_slice(xs, 2) { |s| p(s) }
# => [1, 2]
# => [3]
p(Array.each_cons(xs, 2) { |s| s })    # => [1, 2, 3]
p(Array.each_cons(xs, 5))              # => []
```

## each_with_object

`Array.each_with_object(x, Any) { }`

Passes each element and `memo` (in that order) to the block and finally returns `memo`, whose type is the result type. Unlike `reduce`, the block's value is not used: the result accumulates by changing `memo` in place.

```ruby
xs = Array[1, 2, 3]
p(Array.each_with_object(xs, Array[]) { |x, acc| Array.push(acc, x * 2) })   # => [2, 4, 6]
```

## cycle

`Array.cycle(x, Integer) { }`

Passes all elements to the block n times over and returns nil. Ruby's endless form (no argument) does not exist: n is required. For n of 0 or less nothing happens.

```ruby
p(Array.cycle(Array[1, 2], 2) { |x| puts(x) })
# => 1
# => 2
# => 1
# => 2
# => nil
```

## map, collect

`Array.map(x) { }`

`Array.collect(x) { }`

A new Array of the block's results for each element. Its element type is the block's result type, with no declaration (anything can be added, even when made from a typed Array).

```ruby
xs = Array[1, 2, 3]
p(Array.map(xs) { |x| x * 2 })             # => [2, 4, 6]
p(Array.collect(xs) { |x| Integer.to_s(x) })   # => ["1", "2", "3"]
p(xs)                                      # => [1, 2, 3]
```

## map!, collect!

`Array.map!(x) { }`

`Array.collect!(x) { }`

Replace each element with the block's value and return the subject. In place. Because the checker gives one Array one element type, putting in a type other than the original makes the Array hold both types from then on, and operations that fit only one of them become `type` problems. Use them for a mapping within one type, and `map` (a new Array) to change the type. A typed Array checks the results' type (`type` statically, `TypeError` at run time).

```ruby
xs = Array[1, 2, 3]
p(Array.map!(xs) { |x| x * 2 })        # => [2, 4, 6]
p(Array.collect!(xs) { |x| x + 1 })    # => [3, 5, 7]
p(xs)                                  # => [3, 5, 7]
```

```ruby error
xs = Array[1, 2, 3]
Array.map!(xs) { |x| Integer.to_s(x) }
p(Array.sum(xs))               # !> Array.sum: an element must be Integer|Float|Rational|Complex, but can be String
```

## flat_map

`Array.flat_map(x) { }`

A new Array that joins the Arrays the block returns for each element. The block must return an Array (not a Tuple either); any other value is a `TypeError` at run time. Unlike Ruby's, it does not keep a non-Array value as it is.

```ruby
p(Array.flat_map(Array[1, 2]) { |x| Array[x, x * 10] })   # => [1, 10, 2, 20]
```

```ruby error
Array.flat_map(Array[1]) { |x| [x, x] }    # !> TypeError: Array.flat_map: the block must return an Array, got Tuple
```

## filter_map

`Array.filter_map(x) { }`

A new Array of the block's results for each element, without the nils and falses (`map` and `compact` in one; nil is removed from the element type).

```ruby
xs = Array[1, 2, 3, 4]
p(Array.filter_map(xs) { |x| x * 10 if x > 2 })    # => [30, 40]
p(Array.filter_map(xs) { |x| x > 2 })              # => [true, true]
```

## select, filter, find_all

`Array.select(x) { }`

`Array.filter(x) { }`

`Array.find_all(x) { }`

A new Array of the elements for which the block returns a truthy value (anything but nil and false).

```ruby
xs = Array[1, 2, 3, 4]
p(Array.select(xs) { |x| x > 2 })      # => [3, 4]
p(Array.filter(xs) { |x| x > 2 })      # => [3, 4]
p(Array.find_all(xs) { |x| x > 2 })    # => [3, 4]
```

## select!, filter!, keep_if

`Array.select!(x) { }`

`Array.filter!(x) { }`

`Array.keep_if(x) { }`

Keep only the elements for which the block is truthy (in place). `keep_if` always returns the subject. `select!` and `filter!` return nil when nothing was removed (as Ruby's), and using that result unchecked is a level 2 `nil` problem.

```ruby
xs = Array[1, 2, 3]
p(Array.select!(xs) { |x| x > 1 })     # => [2, 3]
p(Array.select!(xs) { |x| x > 1 })     # => nil
p(Array.keep_if(xs) { |x| x > 1 })     # => [2, 3]
p(Array.keep_if(xs) { |x| x > 2 })     # => [3]
p(xs)                                  # => [3]
```

## reject

`Array.reject(x) { }`

A new Array without the elements for which the block is truthy.

```ruby
p(Array.reject(Array[1, 2, 3, 4]) { |x| x > 2 })   # => [1, 2]
```

## reject!, delete_if

`Array.reject!(x) { }`

`Array.delete_if(x) { }`

Remove the elements for which the block is truthy (in place). `delete_if` always returns the subject. `reject!` returns nil when nothing was removed (as Ruby's), and using that result unchecked is a level 2 `nil` problem.

```ruby
xs = Array[1, 2, 3]
p(Array.reject!(xs) { |x| x > 2 })     # => [1, 2]
p(Array.reject!(xs) { |x| x > 2 })     # => nil
p(Array.delete_if(xs) { |x| x > 5 })   # => [1, 2]
p(Array.delete_if(xs) { |x| x > 1 })   # => [1]
```

## partition

`Array.partition(x) { }`

The two-element Tuple `[selected, rest]`: an Array of the elements for which the block is truthy, and an Array of the others. Take it apart with multiple assignment.

```ruby
evens, odds = Array.partition(Array[1, 2, 3, 4]) { |x| Integer.even?(x) }
p(evens)                       # => [2, 4]
p(odds)                        # => [1, 3]
```

## group_by

`Array.group_by(x) { }`

A Hash from each block value to the Array of the elements that gave it (in order of first appearance). The keys must be values a Hash key can be (a Regexp and the like are a `TypeError`; [Values and types](../03-values.md)).

```ruby
p(Array.group_by(Array[1, 2, 3, 4]) { |x| x % 2 })    # => {1 => [1, 3], 0 => [2, 4]}
```

## chunk_while, slice_when

`Array.chunk_while(x) { }`

`Array.slice_when(x) { }`

Cut the sequence by passing each pair of neighbours `(a, b)` to the block, and return a new Array of the pieces (Arrays). `chunk_while` keeps neighbours together while the block is truthy; `slice_when` cuts where it is.

```ruby
xs = Array[1, 2, 4, 5, 7]
p(Array.chunk_while(xs) { |a, b| b == a + 1 })    # => [[1, 2], [4, 5], [7]]
p(Array.slice_when(xs) { |a, b| b != a + 1 })     # => [[1, 2], [4, 5], [7]]
```

## take, drop

`Array.take(x, Integer)`

`Array.drop(x, Integer)`

`take(a, n)` is a new Array of the first n elements, `drop(a, n)` of the rest after the first n (fewer when there are not enough). A negative n is an `ArgumentError`.

```ruby
xs = Array[1, 2, 3, 4]
p(Array.take(xs, 2))           # => [1, 2]
p(Array.drop(xs, 2))           # => [3, 4]
p(Array.take(xs, 9))           # => [1, 2, 3, 4]
```

## take_while, drop_while

`Array.take_while(x) { }`

`Array.drop_while(x) { }`

A new Array of the leading elements for which the block is truthy (`take_while`), or of the rest after dropping them (`drop_while`).

```ruby
xs = Array[1, 2, 3, 4]
p(Array.take_while(xs) { |x| x < 3 })  # => [1, 2]
p(Array.drop_while(xs) { |x| x < 3 })  # => [3, 4]
```

## include?

`Array.include?(x, Any)`

True when some element is `==` to `v`. Struct values compare with their type's equality ([Operators and indexing](../05-operators.md)).

```ruby
p(Array.include?(Array[1, 2], 2))          # => true
p(Array.include?(Array[1, 2], nil))        # => false
p(Array.include?(Array[[1, 2]], [1, 2]))   # => true
```

## index, rindex

`Array.index(x, Any)`

`Array.rindex(x, Any)`

The position (an Integer) of the first (`index`) or last (`rindex`) element `==` to `v`, or nil when there is none: a level 2 `nil` problem. Ruby's block form does not exist; to search by a condition use `find_index`.

```ruby
xs = Array[3, 1, 4, 1]
p(Array.index(xs, 1))          # => 1
p(Array.rindex(xs, 1))         # => 3
p(Array.index(xs, 9))          # => nil
```

```ruby error
i = Array.index(Array[1, 2], 2)
p(i + 1)                       # !> the operands may be nil
```

## find_index

`Array.find_index(x) { }`

The position (an Integer) of the first element for which the block is truthy, or nil when there is none (a level 2 `nil` problem).

```ruby
p(Array.find_index(Array[3, 1, 4]) { |x| x > 3 })   # => 2
p(Array.find_index(Array[3, 1, 4]) { |x| x > 9 })   # => nil
```

## find, detect

`Array.find(x) { }`

`Array.detect(x) { }`

The first element for which the block is truthy, or nil when there is none: a level 2 `nil` problem (an empty Array gives nil too; there is no telling "no elements" from "not found").

```ruby
xs = Array[3, 1, 4]
p(Array.find(xs) { |x| x > 3 })        # => 4
p(Array.detect(xs) { |x| x > 30 })     # => nil
```

```ruby error
y = Array.find(Array[3, 1, 4]) { |x| x > 1 }
p(y + 1)                       # !> the operands may be nil
```

## rfind

`Array.rfind(x) { }`

The last element for which the block is truthy, or nil when there is none (a level 2 `nil` problem). It maps to Ruby 4.0's `Array#rfind` and is unavailable on an older Ruby.

```ruby
p(Array.rfind(Array[3, 1, 4, 1, 5]) { |x| x < 4 })    # => 1
```

## bsearch, bsearch_index

`Array.bsearch(x) { }`

`Array.bsearch_index(x) { }`

Binary search in a sorted Array, giving the element (`bsearch`) or its position (`bsearch_index`). Ruby's two modes apply: when the block returns true/false, the first element for which it is true (find-minimum); when it returns an Integer (the result of `<=>`), an element for which it is 0 (find-any). Nil when nothing is found (a level 2 `nil` problem). On an unsorted Array the result is undefined.

```ruby
xs = Array[1, 3, 5, 7]
p(Array.bsearch(xs) { |x| x >= 4 })        # => 5
p(Array.bsearch_index(xs) { |x| x >= 4 })  # => 2
p(Array.bsearch(xs) { |x| 3 <=> x })       # => 3
p(Array.bsearch(xs) { |x| x >= 40 })       # => nil
```

## assoc, rassoc

`Array.assoc(x, Any)`

`Array.rassoc(x, Any)`

In an Array of pairs (Tuples or Arrays), the first element whose first item equals `k` (`assoc`) or whose second item equals `v` (`rassoc`). Nil when there is none (a level 2 `nil` problem). Ruby's `assoc` looks at Array elements only; Sake's pairs are usually Tuples, so Tuples are looked at too.

```ruby
pairs = Array[[1, "a"], [2, "b"]]
p(Array.assoc(pairs, 2))       # => [2, "b"]
p(Array.rassoc(pairs, "a"))    # => [1, "a"]
p(Array.assoc(pairs, 9))       # => nil
```

## count

`Array.count(x, [Any]) [{ }]`

`count(a)` is the number of elements, `count(a, v)` the number of elements `==` to `v`, and `count(a) { |x| ... }` the number of elements for which the block is truthy (an Integer).

```ruby
xs = Array[3, 1, 4, 1]
p(Array.count(xs))                     # => 4
p(Array.count(xs, 1))                  # => 2
p(Array.count(xs) { |x| x > 1 })       # => 2
```

## any?, all?, none?, one?

`Array.any?(x) { }`

`Array.all?(x) { }`

`Array.none?(x) { }`

`Array.one?(x) { }`

True when the block is truthy for at least one element (`any?`), for every element (`all?`), for no element (`none?`), or for exactly one (`one?`). The block is required (Ruby's blockless form and pattern argument do not exist). On an empty Array `all?` and `none?` are true, `any?` and `one?` false.

```ruby
xs = Array[3, 1, 4]
p(Array.any?(xs) { |x| x > 3 })        # => true
p(Array.all?(xs) { |x| x > 0 })        # => true
p(Array.none?(xs) { |x| x > 4 })       # => true
p(Array.one?(xs) { |x| x > 3 })        # => true
p(Array.all?(Array[]) { |x| x > 0 })   # => true
```

```ruby error
Array.any?(Array[1])           # !> Array.any? requires a block
```

## sum

`Array.sum(x, [Any]) [{ }]`

The sum of the elements; with a block, of the block's values. Addition starts from `init` (default 0), and on an empty Array the result is `init` itself. The elements and `init` must be numbers (Integer, Float, Rational, Complex) or values of a Struct type that includes `Arithmetic` and defines `+`; anything else is a `type` problem statically and a `TypeError` at run time (to concatenate Strings use `join`). Write `sum(a, 0.0)` for a Float sum: it is a Float even when the Array is empty.

```ruby
p(Array.sum(Array[1, 2, 3]))                       # => 6
p(Array.sum(Array[]))                              # => 0
p(Array.sum(Array[], 0.0))                         # => 0.0
p(Array.sum(Array[1, 2.5]))                        # => 3.5
p(Array.sum(Array[1, 2], 10))                      # => 13
p(Array.sum(Array["a", "bb"]) { |s| String.size(s) })  # => 3
```

```ruby error
Array.sum(Array["a", "b"])     # !> Array.sum: an element must be Integer|Float|Rational|Complex, but is String
```

## reduce, inject

`Array.reduce(x, Any) { }`

`Array.inject(x, Any) { }`

Starting from `init`, passes the accumulated value and each element (in that order) to the block, takes its value as the next accumulated value, and returns the last. Unlike Ruby's, `init` is required (leaving it out is a static argument-count error). On an empty Array the result is `init`. Ruby's Symbol form (`inject(:+)`) does not exist. The result type is the union of `init`'s type and the block's result type.

```ruby
p(Array.reduce(Array[1, 2, 3], 0) { |acc, x| acc + x })     # => 6
p(Array.inject(Array[1, 2, 3], 1) { |acc, x| acc * x })     # => 6
p(Array.reduce(Array[], 0) { |acc, x| acc + x })            # => 0
p(Array.reduce(Array["a", "b"], "") { |acc, x| acc + x })   # => "ab"
```

```ruby error
Array.reduce(Array[1, 2]) { |acc, x| acc + x }    # !> wrong number of arguments for Array.reduce (given 1, expected 2)
```

## min, max

`Array.min(x)`

`Array.max(x)`

The smallest or largest element. On an empty Array nil (the nil of a miss, reported at level 3 only). The elements must be comparable with each other; a pair that is not (an Integer and a String, say) is an `ArgumentError` at run time. Integers and Floats compare with each other. Struct values compare with their type's `<=>` (`include Comparable`). Ruby's `min(n)` and block forms do not exist.

```ruby
xs = Array[3, 1, 4, 1, 5]
p(Array.min(xs))               # => 1
p(Array.max(xs))               # => 5
p(Array.max(Array[2, 1.5]))    # => 2
p(Array.min(Array[]))          # => nil
```

```ruby error
Array.min(Array[1, "a"])       # !> ArgumentError: Array.min: cannot compare elements of types Integer, String
```

## minmax

`Array.minmax(x)`

The two-element Tuple `[min, max]`. On an empty Array `[nil, nil]`, and each position's type is the element type joined with nil (unlike `min` and `max`, this one is reported as a level 2 `nil` problem). The comparison rules are those of `min` and `max`; an incomparable pair is an `ArgumentError`.

```ruby
p(Array.minmax(Array[3, 1, 4]))    # => [1, 4]
p(Array.minmax(Array[]))           # => [nil, nil]
```

## min_by, max_by

`Array.min_by(x) { }`

`Array.max_by(x) { }`

The element for which the block's value is smallest or largest. On an empty Array nil (a level 2 `nil` problem). The block's values must be comparable with each other; an incomparable pair is an `ArgumentError`.

```ruby
ws = Array["bb", "a", "ccc"]
p(Array.min_by(ws) { |s| String.size(s) })     # => "a"
p(Array.max_by(ws) { |s| String.size(s) })     # => "ccc"
p(Array.min_by(Array[]) { |s| s })             # => nil
```

```ruby error
Array.min_by(Array[1, "a"]) { |x| x }  # !> ArgumentError: Array.min_by: cannot compare block results of types Integer, String
```

## minmax_by

`Array.minmax_by(x) { }`

The two-element Tuple of the element with the smallest block value and the one with the largest. On an empty Array `[nil, nil]` (each position a level 2 `nil`).

```ruby
lo, hi = Array.minmax_by(Array["bb", "a", "ccc"]) { |s| String.size(s) }
p([lo, hi])                    # => ["a", "ccc"]
```

## tally

`Array.tally(x)`

A Hash from each element to the number of times it occurs (an Integer), in order of first appearance. The elements must be values a Hash key can be (`TypeError`).

```ruby
p(Array.tally(Array["a", "b", "a"]))   # => {"a" => 2, "b" => 1}
```

## sort, sort!

`Array.sort(x)`

`Array.sort!(x)`

A new Array of the elements in ascending order (`sort`), or the subject sorted in place and returned (`sort!`). Ruby's comparison block is not accepted (a static error); for another order use `sort_by`. The elements must be comparable with each other; an incomparable pair is an `ArgumentError` at run time. Integers and Floats compare with each other, Tuples element by element, Struct values with their type's `<=>`.

```ruby
xs = Array[3, 1, 2]
p(Array.sort(xs))              # => [1, 2, 3]
p(xs)                          # => [3, 1, 2]
p(Array.sort!(xs))             # => [1, 2, 3]
p(xs)                          # => [1, 2, 3]
p(Array.sort(Array[[2, "a"], [1, "b"]]))   # => [[1, "b"], [2, "a"]]
```

```ruby error
Array.sort(Array[1, 2]) { |a, b| b <=> a }     # !> Array.sort does not take a block
```

```ruby error
Array.sort(Array[1, "a"])      # !> ArgumentError: Array.sort: cannot compare elements of types Integer, String
```

## sort_by, sort_by!

`Array.sort_by(x) { }`

`Array.sort_by!(x) { }`

A new Array of the elements in ascending order of the block's values (the keys), or the subject sorted in place and returned (`sort_by!`). The keys must be comparable with each other; an incomparable pair is an `ArgumentError`. A descending order is a negated key; several keys are a Tuple `[k1, k2]` (Tuples compare in dictionary order).

```ruby
ws = Array["bb", "a", "ccc"]
p(Array.sort_by(ws) { |s| -String.size(s) })           # => ["ccc", "bb", "a"]
p(Array.sort_by(Array["bb", "a", "c"]) { |s| [String.size(s), s] })   # => ["a", "c", "bb"]
xs = Array[3, 1, 2]
p(Array.sort_by!(xs) { |x| -x })                       # => [3, 2, 1]
p(xs)                                                  # => [3, 2, 1]
```

## reverse, reverse!

`Array.reverse(x)`

`Array.reverse!(x)`

A new Array of the elements in reverse order (`reverse`), or the subject reversed in place and returned (`reverse!`).

```ruby
xs = Array[1, 2, 3]
p(Array.reverse(xs))           # => [3, 2, 1]
p(xs)                          # => [1, 2, 3]
p(Array.reverse!(xs))          # => [3, 2, 1]
p(xs)                          # => [3, 2, 1]
```

## rotate, rotate!

`Array.rotate(x, [Integer])`

`Array.rotate!(x, [Integer])`

A new Array with the first n elements (default 1) moved to the end (`rotate`), or the subject rotated in place and returned (`rotate!`). A negative n rotates the other way.

```ruby
xs = Array[1, 2, 3]
p(Array.rotate(xs))            # => [2, 3, 1]
p(Array.rotate(xs, 2))         # => [3, 1, 2]
p(Array.rotate(xs, -1))        # => [3, 1, 2]
p(Array.rotate!(xs))           # => [2, 3, 1]
p(xs)                          # => [2, 3, 1]
```

## shuffle, shuffle!

`Array.shuffle(x)`

`Array.shuffle!(x)`

A new Array of the elements in random order (`shuffle`), or the subject shuffled in place and returned (`shuffle!`).

```ruby
xs = Array[1, 2, 3]
p(Array.size(Array.shuffle(xs)))       # => 3
p(Array.sort(Array.shuffle!(xs)))      # => [1, 2, 3]
```

## sample

`Array.sample(x)`

One element chosen at random. On an empty Array nil (the nil of a miss, reported at level 3 only). There is no Ruby `sample(n)`.

```ruby
p(Array.sample(Array[7]))      # => 7
p(Array.sample(Array[]))       # => nil
```

## uniq, uniq!

`Array.uniq(x)`

`Array.uniq!(x)`

A new Array without the duplicate elements (`==` to an earlier one; the first is kept), or the subject with them removed in place and returned (`uniq!`). `uniq!` returns nil when nothing was removed (as Ruby's), and using that result unchecked is a level 2 `nil` problem. Ruby's block form does not exist.

```ruby
p(Array.uniq(Array[1, 2, 1, 3, 2]))    # => [1, 2, 3]
xs = Array[1, 1]
p(Array.uniq!(xs))                     # => [1]
p(Array.uniq!(xs))                     # => nil
```

```ruby error
p(Array.size(Array.uniq!(Array[1, 1])))    # !> Array.size: argument 1 may be nil
```

## compact, compact!

`Array.compact(x)`

`Array.compact!(x)`

A new Array without the nil elements (`compact`; nil is removed from the element type), or the subject with them removed in place and returned (`compact!`). `compact!` returns nil when there was no nil, and using that result unchecked is a level 2 `nil` problem.

```ruby
p(Array.compact(Array[1, nil, 2]))     # => [1, 2]
xs = Array[1, nil]
p(Array.compact!(xs))                  # => [1]
p(Array.compact!(xs))                  # => nil
```

## flatten, flatten!

`Array.flatten(x)`

`Array.flatten!(x)`

A new Array with every nested Array expanded into its elements (`flatten`), or the subject flattened in place and returned (`flatten!`). Only Arrays are expanded; Tuple elements stay as they are. `flatten!` returns nil when there was nothing nested, and using that result unchecked is a level 2 `nil` problem. Ruby's depth argument does not exist.

```ruby
p(Array.flatten(Array[1, Array[2, Array[3]], 4]))     # => [1, 2, 3, 4]
p(Array.flatten(Array[[1, 2], 3]))                    # => [[1, 2], 3]
xs = Array[1, Array[2]]
p(Array.flatten!(xs))                                 # => [1, 2]
p(Array.flatten!(xs))                                 # => nil
```

## zip

`Array.zip(x, *Array)`

A new Array of Tuples pairing each element of the subject with the elements at the same position in the other Arrays. Its length is the subject's: a shorter other Array is padded with nil (that position's type is the element type joined with nil), and a longer one's extra elements are dropped. Unlike Ruby's, the groups are Tuples, not Arrays.

```ruby
p(Array.zip(Array[1, 2, 3], Array["a", "b"]))              # => [[1, "a"], [2, "b"], [3, nil]]
p(Array.zip(Array[1, 2], Array["a", "b"], Array[:x, :y]))  # => [[1, "a", :x], [2, "b", :y]]
```

## product

`Array.product(x, Array)`

A new Array of all combinations `[a, b]` (Tuples) of an element of the subject and an element of the other Array. Unlike Ruby's, it takes exactly one other Array, and the groups are Tuples.

```ruby
p(Array.product(Array[1, 2], Array["a", "b"]))    # => [[1, "a"], [1, "b"], [2, "a"], [2, "b"]]
p(Array.product(Array[1], Array[]))               # => []
```

## transpose

`Array.transpose(x)`

Takes an Array of Arrays as a matrix and returns a new Array with rows and columns exchanged. The elements must all be Arrays of the same length: a different length is an `IndexError`, and a Tuple element an `ArgumentError` (a sequence of Tuples such as `zip`'s result cannot be transposed as it is).

```ruby
p(Array.transpose(Array[Array[1, 2], Array[3, 4]]))   # => [[1, 3], [2, 4]]
```

```ruby error
Array.transpose(Array[Array[1, 2], Array[3]])  # !> IndexError: Array.transpose: element size differs (1 should be 2)
```

## combination, repeated_combination

`Array.combination(x, Integer)`

`Array.repeated_combination(x, Integer)`

A new Array of the combinations of n elements, as Arrays: each element at most once (`combination`), or with repetition (`repeated_combination`). An Array, not Ruby's Enumerator. When n exceeds the length, `combination` gives `[]`.

```ruby
p(Array.combination(Array[1, 2, 3], 2))           # => [[1, 2], [1, 3], [2, 3]]
p(Array.repeated_combination(Array[1, 2], 2))     # => [[1, 1], [1, 2], [2, 2]]
p(Array.combination(Array[1, 2], 5))              # => []
```

## permutation, repeated_permutation

`Array.permutation(x, [Integer])`

`Array.repeated_permutation(x, Integer)`

A new Array of the permutations of n elements, as Arrays. `permutation(a)` without n uses all elements. `repeated_permutation` may pick the same element again (n is required).

```ruby
p(Array.permutation(Array[1, 2, 3], 2))   # => [[1, 2], [1, 3], [2, 1], [2, 3], [3, 1], [3, 2]]
p(Array.permutation(Array[1, 2]))         # => [[1, 2], [2, 1]]
p(Array.repeated_permutation(Array[1, 2], 2))     # => [[1, 1], [1, 2], [2, 1], [2, 2]]
```

## union, intersection, difference

`Array.union(x, *Array)`

`Array.intersection(x, *Array)`

`Array.difference(x, *Array)`

New Arrays treating the Arrays as sets (in the subject's order, comparing with `==`). `union` is the elements of the subject and all the other Arrays without duplicates (the element type is the union of all); `intersection` the elements that are in every other Array, without duplicates; `difference` the elements that are in none of the other Arrays (duplicates kept). Any number of other Arrays may be given, even none.

```ruby
a = Array[1, 2, 3]
b = Array[2, 3, 4]
p(Array.union(a, b))                   # => [1, 2, 3, 4]
p(Array.union(Array[1, 1]))            # => [1]
p(Array.intersection(a, b))            # => [2, 3]
p(Array.intersection(a, b, Array[3]))  # => [3]
p(Array.difference(a, b))              # => [1]
p(Array.difference(Array[1, 2, 2, 3], Array[2], Array[3]))    # => [1]
```

## intersect?

`Array.intersect?(x, Array)`

True when the two Arrays have at least one element in common.

```ruby
p(Array.intersect?(Array[1, 2], Array[2, 3]))  # => true
p(Array.intersect?(Array[1, 2], Array[9]))     # => false
```

## join

`Array.join(x, [String])`

A String of the elements converted with `to_s`, separated by `sep` (default `""`). `to_s` follows the rules of `puts`: nil is empty, Arrays and Tuples take their `inspect` form, and a Struct value uses its type's `to_s` ([Values and types](../03-values.md)).

```ruby
p(Array.join(Array[1, 2, 3], ", "))            # => "1, 2, 3"
p(Array.join(Array[1, "a", nil, :s, [1, 2]]))  # => "1as[1, 2]"
p(Array.join(Array[]))                         # => ""
```

## to_h

`Array.to_h(x)`

A Hash from a sequence of `[key, value]` Tuples. Every element must be a two-element Tuple (not an Array); any other value is a `TypeError`. When a key occurs more than once the later one stays. The keys must be values a Hash key can be. Ruby's block form does not exist.

```ruby
p(Array.to_h(Array[[:a, 1], [:b, 2]]))     # => {a: 1, b: 2}
p(Array.to_h(Array[[1, "a"], [1, "b"]]))   # => {1 => "b"}
p(Array.to_h(Array[]))                     # => {}
```

```ruby error
Array.to_h(Array[1, 2])        # !> TypeError: Array.to_h: Array.to_h needs [key, value] Tuples, got Integer
```

## to_set

`Array.to_set(x)`

A new Set of the elements (duplicates become one). The elements must be values a Set element can be (`TypeError`).

```ruby
p(Array.to_set(Array[1, 2, 1]))    # => Set[1, 2]
```

## pack

`Array.pack(x, String)`

Ruby's `Array#pack`: the elements as a byte String according to the format `fmt`. An invalid format is an `ArgumentError`. An element that does not fit the format (a String for `"C*"`, say) currently leaks Ruby's `TypeError`. The reverse is `String.unpack`.

```ruby
p(Array.pack(Array[65, 66], "C*"))     # => "AB"
p(Array.pack(Array[1, 2], "n*"))       # => "\x00\x01\x00\x02"
```

## +, -, *

`Array.+(x, Any)`

`Array.-(x, Any)`

`Array.*(x, Any)`

`a + b` is a new Array of both Arrays' elements (the element type is the union; `concat` does it in place). `a - b` is a new Array without every element that is `==` to one in `b` (the same as `difference`). `a * n` is a new Array of `a` repeated n times; a negative n is an `ArgumentError`. The right operand must be an Array for `+` and `-` and an Integer for `*`; a Tuple or a String (Ruby's `a * ","` is `join`) is a `type` problem statically.

```ruby
a = Array[1, 2, 3]
b = Array[2, 3, 4]
p(a + b)                       # => [1, 2, 3, 2, 3, 4]
p(a - b)                       # => [1]
p(Array[1, 2, 2] - Array[2])   # => [1]
p(a * 2)                       # => [1, 2, 3, 1, 2, 3]
p(Array.+(a, Array[9]))        # => [1, 2, 3, 9]
p(Array.*(a, 0))               # => []
```

```ruby error
p(Array[1] + [2])              # !> which the left operand's type does not support
```

## ==, !=

`Array.==(x, Any)`

`Array.!=(x, Any)`

True when the two Arrays have the same length and the elements at each position are `==` (`!=` is the negation). A right operand that is not an Array (a Tuple, nil) is never equal. `[1, 2]` is a Tuple and so is not equal to `Array[1, 2]`.

```ruby
a = Array[1, 2, 3]
p(a == Array[1, 2, 3])         # => true
p(a != Array[1, 2])            # => true
p(a == [1, 2, 3])              # => false
p(a == nil)                    # => false
p(Array.==(a, a))              # => true
```

## <, <=, >, >=

`Array.<(x, Any)`

`Array.<=(x, Any)`

`Array.>(x, Any)`

`Array.>=(x, Any)`

Compare two Arrays in dictionary order: elements are compared from the front, the first differing position decides, and when all are equal the shorter Array is smaller. The elements must be of comparable types; a pair that is not is a `type` problem statically (`which cannot be compared`) and an `ArgumentError` at run time. The right operand must be an Array (a Tuple is a `type` problem).

```ruby
p(Array[1, 2] < Array[1, 3])           # => true
p(Array[1, 2] < Array[1, 2, 0])        # => true
p(Array[2] > Array[1, 9])              # => true
p(Array[1, 2] <= Array[1, 2])          # => true
p(Array.>=(Array[1], Array[1]))        # => true
```

```ruby error
p(Array[1, "a"] < Array[1, 2])         # !> which cannot be compared
```

## <=>

`Array.<=>(x, Any)`

The result of the dictionary-order comparison as -1, 0, or 1. The rules are those of `<`. An incomparable pair is a `type` problem statically; run without the check (`--strict=0`) it gives nil (where `<` and the others raise `ArgumentError`).

```ruby
a = Array[1, 2, 3]
p(a <=> Array[1, 2, 4])        # => -1
p(a <=> a)                     # => 0
p(Array.<=>(a, Array[1]))      # => 1
```
