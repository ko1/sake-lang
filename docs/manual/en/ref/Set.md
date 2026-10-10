# Set

A Set is a collection of elements without duplicates. `Set[1, 2]` makes a Set (there is no `Set.new`, Ruby's `Set.new([1, 2])`; see [Values and types](../03-values.md)). Elements are told apart by the rules of Hash keys: Integer, Float, String, Symbol, true, false, nil, Time, and Tuples, Records, Arrays, Hashes, Sets and values of a class made of these can be elements; a Regexp, a Range, or a value of a class that defines its own equality (`==` or `Comparable`) is a `TypeError` at run time. Whether two values are the same element is decided as Ruby's Hash does, by `hash` and `eql?`, so `1` and `1.0` are two elements. Elements keep the order they were added in, and iteration follows it. A String used as an element is copied in, so changing the original String afterwards does not change the Set.

The checker follows the element type of a Set per construction site and widens it on writes such as `Set.add`. The block of an operation that takes one receives values of that element type.

The operators on Sets are `|` (union), `&` (intersection), `-` (difference), `==` and `!=`. `^`, `+`, `<`, `<=` and the like do not apply; subset tests are `Set.subset?` and its relatives. The entries `Set.|(x, y)` and so on below are the function forms of the operators ([Operators and indexing](../05-operators.md)). Most operations that pick elements out (`select`, `map`, `sort`, `to_a`, ...) return an **Array**, not a Set; this differs from Ruby's `Set#select`, which returns a Set.

## Set[]

`Set[*Any]`

Makes a Set of the listed elements. Unlike the other types' `T[...]`, which make "an Array of T", `Set[...]` makes **a Set itself**. Duplicate elements collapse into one. A value that cannot be an element (a Regexp, a Range, a Struct value with its own equality) is a `TypeError` at run time. `Set[]` is the empty Set; elements added later with `Set.add` widen its element type.

```ruby
s = Set[1, 2, 2, 3]
p(s)                          # => Set[1, 2, 3]
p(Set[])                      # => Set[]
p(Set.size(Set[1, 1.0]))      # => 2
```

```ruby error
p(Set[/a/])                   # !> TypeError: Set[]: Regexp cannot be a Hash key or Set element
```

## length, size

`Set.length(x)`

`Set.size(x)`

The number of elements (an Integer).

```ruby
p(Set.size(Set[1, 2, 3]))     # => 3
p(Set.length(Set[]))          # => 0
```

## empty?

`Set.empty?(x)`

True when the Set has no elements.

```ruby
p(Set.empty?(Set[]))          # => true
p(Set.empty?(Set[1]))         # => false
```

## include?, member?

`Set.include?(x, Any)`

`Set.member?(x, Any)`

True when the value is an element. Elements compare as Hash keys do (`hash` and `eql?`), so a Set holding `1` does not hold `1.0`. Asking for a value of a type other than the Set's element type is not a static problem; the answer is false.

```ruby
s = Set[1, 2]
p(Set.include?(s, 1))         # => true
p(Set.include?(s, 1.0))       # => false
p(Set.member?(s, "a"))        # => false
p(Set.include?(Set[[1, 2]], [1, 2]))   # => true
```

## add

`Set.add(x, Any)`

Adds the value as an element and returns the Set itself (in place). A value already present changes nothing. A value that cannot be an element is a `TypeError` at run time. The type of the added value joins the Set's element type.

```ruby
s = Set[1]
p(Set.add(s, 2))              # => Set[1, 2]
p(Set.add(s, 2))              # => Set[1, 2]
p(s)                          # => Set[1, 2]
```

```ruby error
Set.add(Set[1], 1..2)         # !> TypeError: Set.add: Range cannot be a Hash key or Set element
```

## add?

`Set.add?(x, Any)`

As `add`, but returns **nil** when the value was already present (the Set itself when it was newly added). The result is a Set or nil, so `--strict` (level 2) reports using it unchecked. Use it to ask "is this the first time I see this value?".

```ruby
s = Set[1]
p(Set.add?(s, 2))             # => Set[1, 2]
p(Set.add?(s, 2))             # => nil
```

```ruby error
s = Set[1]
x = Set.add?(s, 2)
p(Set.size(x))                # !> argument 1 may be nil
```

## delete

`Set.delete(x, Any)`

Removes the value from the elements and returns the Set itself (in place). A value that is not present changes nothing. As Ruby's.

```ruby
s = Set[1, 2, 3]
p(Set.delete(s, 2))           # => Set[1, 3]
p(Set.delete(s, 99))          # => Set[1, 3]
```

## delete?

`Set.delete?(x, Any)`

As `delete`, but returns **nil** when the value was not present (the Set itself when it was removed). `--strict` (level 2) reports using the result unchecked.

```ruby
s = Set[1, 2]
p(Set.delete?(s, 2))          # => Set[1]
p(Set.delete?(s, 2))          # => nil
```

## merge

`Set.merge(x, Set)`

Adds every element of the other Set and returns the Set itself (in place). The argument must be a Set (an Array is a `type` problem statically; Ruby's `merge` takes any enumerable). For a new Set use `|` or `union`.

```ruby
s = Set[1, 2]
p(Set.merge(s, Set[2, 3]))    # => Set[1, 2, 3]
p(s)                          # => Set[1, 2, 3]
```

```ruby error
Set.merge(Set[1], Array[2])   # !> argument 2 must be Set, but is Array
```

## subtract

`Set.subtract(x, Any)`

Removes every element contained in the argument and returns the Set itself (in place). The argument is a Set, an Array, a Tuple, or a Range; the checker does not check it (the signature says `Any`), and anything else is a `TypeError` at run time (`argument 2 must be Set, Array, Tuple, or Range, got Integer`). For a new Set use `-` or `difference`.

```ruby
s = Set[1, 2, 3, 4, 5]
p(Set.subtract(s, Set[1]))    # => Set[2, 3, 4, 5]
p(Set.subtract(s, Array[2]))  # => Set[3, 4, 5]
p(Set.subtract(s, [3]))       # => Set[4, 5]
p(Set.subtract(s, 4..4))      # => Set[5]
p(s)                          # => Set[5]
```

```ruby error
Set.subtract(Set[1, 2], 1)    # !> TypeError: Set.subtract: argument 2 must be Set, Array, Tuple, or Range, got Integer
```

## replace

`Set.replace(x, Set)`

Replaces all elements with those of the other Set and returns the Set itself (in place). The other Set's element type joins this Set's.

```ruby
s = Set[1, 2]
p(Set.replace(s, Set[7, 8]))  # => Set[7, 8]
p(s)                          # => Set[7, 8]
```

## clear

`Set.clear(x)`

Removes all elements and returns the now empty Set itself.

```ruby
s = Set[1, 2]
p(Set.clear(s))               # => Set[]
p(Set.empty?(s))              # => true
```

## |, union

`Set.|(x, Any)`

`Set.union(x, Set)`

The union: a **new** Set with the elements of both. `Set.|` is the function form of `a | b`. The right operand must be a Set; an Array or other value is a `type` problem statically. The result's element type is the union of both element types.

```ruby
a = Set[1, 2]
b = Set[2, 3]
p(a | b)                      # => Set[1, 2, 3]
p(Set.union(a, b))            # => Set[1, 2, 3]
p(a)                          # => Set[1, 2]
```

```ruby error
p(Set[1] | Array[2])          # !> Bitwise.|: the operands are (Set@L1[Integer], Array@L1[Integer])
```

## &, intersection

`Set.&(x, Any)`

`Set.intersection(x, Set)`

The intersection: a **new** Set with only the elements present in both. `Set.&` is the function form of `a & b`. The right operand must be a Set.

```ruby
a = Set[1, 2, 3]
b = Set[2, 3, 4]
p(a & b)                      # => Set[2, 3]
p(Set.intersection(a, b))     # => Set[2, 3]
```

## -, difference

`Set.-(x, Any)`

`Set.difference(x, Set)`

The difference: a **new** Set with the elements of the left operand that are not in the right one. `Set.-` is the function form of `a - b`. The right operand must be a Set.

```ruby
a = Set[1, 2, 3]
b = Set[2]
p(a - b)                      # => Set[1, 3]
p(Set.difference(a, b))       # => Set[1, 3]
p(a)                          # => Set[1, 2, 3]
```

## ==, !=

`Set.==(x, Any)`

`Set.!=(x, Any)`

True when the two Sets have the same elements, in any order (`!=` is the negation). A right operand that is not a Set (an Array, nil) is never equal.

```ruby
p(Set[1, 2] == Set[2, 1])     # => true
p(Set[1, 2] == Set[1])        # => false
p(Set[1] != Set[1])           # => false
p(Set[1, 2] == Array[1, 2])   # => false
```

## subset?, superset?

`Set.subset?(x, Set)`

`Set.superset?(x, Set)`

`subset?` is true when every element of x is in the argument Set; `superset?` is the reverse. Equal Sets answer true to both. The argument must be a Set (an Array is a `type` problem statically). Ruby's `<=` and `>=` operators do not apply to Sets; use these functions.

```ruby
a = Set[1, 2]
b = Set[1, 2, 3]
p(Set.subset?(a, b))          # => true
p(Set.subset?(a, a))          # => true
p(Set.superset?(b, a))        # => true
p(Set.superset?(a, b))        # => false
```

```ruby error
p(Set[1] <= Set[1, 2])        # !> Comparable.<=: the operands are (Set@L1[Integer], Set@L1[Integer])
```

## proper_subset?, proper_superset?

`Set.proper_subset?(x, Set)`

`Set.proper_superset?(x, Set)`

Proper subset tests: as `subset?` and `superset?`, but equal Sets answer false (Ruby's `<` and `>`).

```ruby
a = Set[1, 2]
b = Set[1, 2, 3]
p(Set.proper_subset?(a, b))   # => true
p(Set.proper_subset?(a, a))   # => false
p(Set.proper_superset?(b, a)) # => true
```

## disjoint?, intersect?

`Set.disjoint?(x, Set)`

`Set.intersect?(x, Set)`

`intersect?` is true when the two Sets share at least one element; `disjoint?` is its negation.

```ruby
p(Set.intersect?(Set[1, 2], Set[2, 3]))   # => true
p(Set.disjoint?(Set[1, 2], Set[2, 3]))    # => false
p(Set.disjoint?(Set[1], Set[9]))          # => true
```

## each, each_entry

`Set.each(x) { }`

`Set.each_entry(x) { }`

Passes the elements to the block one at a time, in the order they were added, and returns the Set itself. The block is required (there is no block-less form giving an Enumerator as in Ruby).

```ruby
s = Set[3, 1, 2]
Set.each(s) { |x| puts(x) }
# => 3
# => 1
# => 2
p(Set.each_entry(s) { |x| x })   # => Set[3, 1, 2]
```

## each_with_index

`Set.each_with_index(x) { }`

Passes each element and its position (from 0) to the block and returns the Set itself.

```ruby
Set.each_with_index(Set["a", "b"]) { |x, i| puts("#{i}: #{x}") }
# => 0: a
# => 1: b
```

## each_with_object

`Set.each_with_object(x, Any) { }`

Passes each element and the second argument to the block, and returns that second argument. The usual form passes an Array or Hash to accumulate into.

```ruby
a = Set.each_with_object(Set[1, 2], Array[]) { |x, acc| Array.push(acc, x * 2) }
p(a)                          # => [2, 4]
```

## reverse_each

`Set.reverse_each(x) { }`

Passes the elements to the block in the reverse of the order they were added, and returns the Set itself.

```ruby
Set.reverse_each(Set[1, 2, 3]) { |x| puts(x) }
# => 3
# => 2
# => 1
```

## each_slice, each_cons

`Set.each_slice(x, Integer) { }`

`Set.each_cons(x, Integer) { }`

`each_slice` cuts the elements into Arrays of n (the last may be shorter) and passes each to the block; `each_cons` passes each run of n consecutive elements as an Array, moving one element at a time. Both return the Set itself. An n of 0 or less is an `ArgumentError`.

```ruby
s = Set[1, 2, 3, 4]
Set.each_slice(s, 3) { |a| p(a) }
# => [1, 2, 3]
# => [4]
Set.each_cons(s, 3) { |a| p(a) }
# => [1, 2, 3]
# => [2, 3, 4]
```

```ruby error
Set.each_slice(Set[1], 0) { |a| p(a) }   # !> ArgumentError: Set.each_slice: invalid slice size
```

## cycle

`Set.cycle(x, Integer) { }`

Passes the sequence of elements to the block n times over and returns **nil**. The count is required (there is no endless `cycle` as in Ruby). An n of 0 or less does nothing.

```ruby
Set.cycle(Set[1, 2], 2) { |x| print(x) }
puts("")
# => 1212
p(Set.cycle(Set[1], 0) { |x| p(x) })   # => nil
```

## map, collect

`Set.map(x) { }`

`Set.collect(x) { }`

The **Array** of the block's results for each element (not a Set: in element order, duplicates kept). Its element type is the type of the block's result.

```ruby
p(Set.map(Set[1, 2, 3]) { |x| x * 10 })        # => [10, 20, 30]
p(Set.collect(Set[1, 2, 3]) { |x| x % 2 })     # => [1, 0, 1]
```

## map!, collect!

`Set.map!(x) { }`

`Set.collect!(x) { }`

Replaces each element with the block's result and returns the Set itself (in place). Results that coincide leave fewer elements. The block's result type joins the element type. A result that cannot be an element is a `TypeError` at run time.

```ruby
s = Set[1, 2, 3]
p(Set.map!(s) { |x| x % 2 })  # => Set[1, 0]
p(s)                          # => Set[1, 0]
```

## flat_map, collect_concat

`Set.flat_map(x) { }`

`Set.collect_concat(x) { }`

The block returns an **Array or a Tuple** for each element, and the result is the one Array of all of them joined. A block result that is neither is a `TypeError` at run time (`the block must return an Array or a Tuple, got Integer`; the value is not kept as is, as Ruby would).

```ruby
p(Set.flat_map(Set[1, 2]) { |x| Array[x, x * 10] })   # => [1, 10, 2, 20]
p(Set.flat_map(Set[1, 2]) { |x| [x, x * 10] })        # => [1, 10, 2, 20]
```

```ruby error
Set.flat_map(Set[1]) { |x| x }    # !> TypeError: Set.flat_map: the block must return an Array or a Tuple, got Integer
```

## select, filter, find_all

`Set.select(x) { }`

`Set.filter(x) { }`

`Set.find_all(x) { }`

The **Array** of the elements for which the block is truthy (Ruby's `Set#select` returns a Set; in Sake it is an Array). For a Set, narrow in place with `select!`, or turn the Array back with `Array.to_set`.

```ruby
s = Set[1, 2, 3, 4]
p(Set.select(s) { |x| Integer.even?(x) })      # => [2, 4]
p(Set.filter(s) { |x| x > 3 })                 # => [4]
p(Set.find_all(s) { |x| x < 0 })               # => []
```

## reject

`Set.reject(x) { }`

The **Array** of the elements for which the block is falsy (the reverse of `select`).

```ruby
p(Set.reject(Set[1, 2, 3, 4]) { |x| Integer.even?(x) })   # => [1, 3]
```

## select!, filter!, reject!

`Set.select!(x) { }`

`Set.filter!(x) { }`

`Set.reject!(x) { }`

`select!` and `filter!` remove the elements for which the block is falsy, `reject!` those for which it is truthy, in place. They return the Set itself when something was removed and **nil when nothing changed** (as Ruby's). `--strict` (level 2) reports using the result unchecked. The forms that always return the Set are `keep_if` and `delete_if`.

```ruby
s = Set[1, 2, 3, 4]
p(Set.select!(s) { |x| x > 1 })    # => Set[2, 3, 4]
p(Set.select!(s) { |x| x > 1 })    # => nil
p(Set.reject!(s) { |x| x > 3 })    # => Set[2, 3]
p(Set.filter!(s) { |x| x < 9 })    # => nil
p(s)                               # => Set[2, 3]
```

## keep_if, delete_if

`Set.keep_if(x) { }`

`Set.delete_if(x) { }`

`keep_if` keeps only the elements for which the block is truthy; `delete_if` removes those (in place). Both always return the Set itself.

```ruby
s = Set[1, 2, 3, 4]
p(Set.keep_if(s) { |x| x > 1 })        # => Set[2, 3, 4]
p(Set.delete_if(s) { |x| x > 3 })      # => Set[2, 3]
p(Set.delete_if(s) { |x| x > 9 })      # => Set[2, 3]
```

## filter_map

`Set.filter_map(x) { }`

Applies the block to each element and collects the results that are neither nil nor false, as an Array. The result's element type has nil removed.

```ruby
p(Set.filter_map(Set[1, 2, 3, 4]) { |x| Integer.even?(x) ? x * 10 : nil })   # => [20, 40]
```

## partition

`Set.partition(x) { }`

The Tuple `[yes, no]` of the Array of elements for which the block is truthy and the Array of the others.

```ruby
ev, od = Set.partition(Set[1, 2, 3, 4]) { |x| Integer.even?(x) }
p(ev)                         # => [2, 4]
p(od)                         # => [1, 3]
```

## group_by

`Set.group_by(x) { }`

A Hash from each block result to the Array of the elements that gave it. A block result that cannot be a key is a `TypeError` at run time.

```ruby
p(Set.group_by(Set[1, 2, 3, 4]) { |x| x % 2 })    # => {1 => [1, 3], 0 => [2, 4]}
```

## classify

`Set.classify(x) { }`

The same grouping as `group_by`, but the Hash's values are **Sets** rather than Arrays (Ruby's `Set#classify`).

```ruby
p(Set.classify(Set[1, 2, 3, 4]) { |x| x % 2 })    # => {1 => Set[1, 3], 0 => Set[2, 4]}
```

## tally

`Set.tally(x)`

A Hash from each element to its count. A Set has no duplicates, so every value is 1 (the operation comes from Array and exists for uniformity).

```ruby
p(Set.tally(Set["a", "b"]))   # => {"a" => 1, "b" => 1}
```

## chunk_while, slice_when

`Set.chunk_while(x) { }`

`Set.slice_when(x) { }`

Pass each pair of adjacent elements to the block; `chunk_while` keeps a run together while the block is truthy, `slice_when` cuts where it is truthy. The result is an Array of Arrays.

```ruby
s = Set[1, 2, 4, 5, 7]
p(Set.chunk_while(s) { |a, b| b == a + 1 })   # => [[1, 2], [4, 5], [7]]
p(Set.slice_when(s) { |a, b| b > a + 1 })     # => [[1, 2], [4, 5], [7]]
```

## slice_before, slice_after

`Set.slice_before(x) { }`

`Set.slice_after(x) { }`

An Array of Arrays cut just before (`slice_before`) or just after (`slice_after`) each element for which the block is truthy.

```ruby
s = Set[1, 2, 3, 4]
p(Set.slice_before(s) { |x| x == 3 })   # => [[1, 2], [3, 4]]
p(Set.slice_after(s) { |x| x == 2 })    # => [[1, 2], [3, 4]]
```

## find, detect

`Set.find(x) { }`

`Set.detect(x) { }`

The first element for which the block is truthy. When no element is, the result is **nil**, and `--strict` (level 2) reports using it unchecked.

```ruby
s = Set[1, 2, 3]
p(Set.find(s) { |x| x > 1 })      # => 2
p(Set.detect(s) { |x| x > 9 })    # => nil
```

```ruby error
x = Set.find(Set[1]) { |v| v > 0 }
p(x + 1)                          # !> the operands may be nil
```

## find_index

`Set.find_index(x) { }`

The position (an Integer, from 0 in the order added) of the first element for which the block is truthy, or **nil** when there is none (reported at `--strict` level 2).

```ruby
s = Set["a", "b", "c"]
p(Set.find_index(s) { |x| x == "c" })   # => 2
p(Set.find_index(s) { |x| x == "z" })   # => nil
```

## any?, all?, none?, one?

`Set.any?(x) { }`

`Set.all?(x) { }`

`Set.none?(x) { }`

`Set.one?(x) { }`

True when the block is truthy for at least one element, for all of them, for none, or for exactly one. The block is required (Ruby's block-less forms do not exist; emptiness is `empty?`).

```ruby
s = Set[1, 2, 3]
p(Set.any?(s) { |x| x > 2 })      # => true
p(Set.all?(s) { |x| x > 2 })      # => false
p(Set.none?(s) { |x| x > 9 })     # => true
p(Set.one?(s) { |x| x == 1 })     # => true
```

```ruby error
p(Set.any?(Set[1]))               # !> Set.any? requires a block
```

## count

`Set.count(x) [{ }]`

Without a block, the number of elements; with one, the number of elements for which the block is truthy (an Integer).

```ruby
s = Set[1, 2, 3]
p(Set.count(s))                   # => 3
p(Set.count(s) { |x| x > 1 })     # => 2
```

## sum

`Set.sum(x, [Integer|Float|Rational|Complex])`

The sum of the elements: the initial value (0 by default) plus each element in turn. Elements and the initial value must be numbers: a String or other initial value is a `type` problem statically, and an element that is not a number is a `TypeError` at run time (`String can't be coerced into Integer`; Ruby's `sum("")` for joining Strings does not exist; use `join`). The empty Set gives the initial value.

```ruby
p(Set.sum(Set[1, 2, 3]))          # => 6
p(Set.sum(Set[1, 2], 0.5))        # => 3.5
p(Set.sum(Set[]))                 # => 0
```

```ruby error
p(Set.sum(Set["a", "b"], ""))     # !> argument 2 must be Integer|Float|Rational|Complex, but is String
```

## reduce, inject

`Set.reduce(x, Any) { }`

`Set.inject(x, Any) { }`

Folds the elements: starting from the initial value, the block receives the accumulated value and an element. The initial value is **required** (Ruby's form that starts from the first element does not exist). The result type follows from the initial value and the block's result.

```ruby
p(Set.reduce(Set[1, 2, 3], 0) { |acc, x| acc + x })     # => 6
p(Set.inject(Set[1, 2, 3], 1) { |acc, x| acc * x })     # => 6
```

```ruby error
p(Set.reduce(Set[1]) { |a, b| a + b })   # !> wrong number of arguments for Set.reduce (given 1, expected 2)
```

## min, max

`Set.min(x)`

`Set.max(x)`

The smallest or largest element. The elements must be comparable with each other: the checker rejects a Set whose element type mixes types that cannot be compared (`Set[1, "a"]`) statically as a `type` problem, and an element that may be nil as a `nil` problem. When the checker cannot see it (`Set[1.0, Float.NAN]`), it is an `ArgumentError` at run time (`cannot compare the elements`). The empty Set gives **nil**, the nil of a miss, as with `Array.min`: using it unchecked is reported only at `--strict=3`.

```ruby
s = Set[3, 1, 2]
p(Set.min(s))                     # => 1
p(Set.max(s))                     # => 3
p(Set.max(Set[]))                 # => nil
```

```ruby error
p(Set.min(Set[1, "a"]))           # !> Set.min: elements compared in order may be (Integer, String), which cannot be compared
```

```ruby error
p(Set.min(Set[1.0, Float.NAN]))   # !> ArgumentError: Set.min: cannot compare the elements
```

## minmax

`Set.minmax(x)`

The Tuple `[min, max]`. The empty Set gives `[nil, nil]`; those are the nil of a miss, reported only at `--strict=3` when an element is used unchecked. The comparison rules are those of `min` and `max`, static check included.

```ruby
lo, hi = Set.minmax(Set[3, 1, 2])
p([lo, hi])                       # => [1, 3]
p(Set.minmax(Set[]))              # => [nil, nil]
```

## min_by, max_by

`Set.min_by(x) { }`

`Set.max_by(x) { }`

The element for which the block's result is smallest or largest. The block's results must be comparable with each other: a block whose result type mixes types that cannot be compared is rejected statically (`type`), as with `min`. The empty Set gives **nil**, the nil of a miss (reported only at `--strict=3`).

```ruby
s = Set["bb", "a", "ccc"]
p(Set.min_by(s) { |x| String.size(x) })   # => "a"
p(Set.max_by(s) { |x| String.size(x) })   # => "ccc"
p(Set.max_by(Set[]) { |x| x })            # => nil
```

```ruby error
p(Set.min_by(Set[1, 2]) { |x| x == 1 ? 1 : "a" })   # !> Set.min_by: elements compared in order may be (Integer, String), which cannot be compared
```

## minmax_by

`Set.minmax_by(x) { }`

The Tuple of the elements with the smallest and the largest block result. The empty Set gives `[nil, nil]` (the nil of a miss, level 3). The block's results are checked as for `min_by`.

```ruby
p(Set.minmax_by(Set[1, 2, 3]) { |x| -x })   # => [3, 1]
```

## sort

`Set.sort(x)`

The Array of the elements in ascending order. The elements must be comparable with each other: a Set whose element type mixes types that cannot be compared is rejected statically (`type`), one whose elements may be nil as a `nil` problem; when the checker cannot see it (`Set[1.0, Float.NAN]`), `ArgumentError` at run time (`cannot compare the elements`).

```ruby
p(Set.sort(Set[3, 1, 2]))         # => [1, 2, 3]
```

```ruby error
p(Set.sort(Set[1, "a"]))          # !> Set.sort: elements compared in order may be (Integer, String), which cannot be compared
```

## sort_by

`Set.sort_by(x) { }`

The Array of the elements in ascending order of the block's results. A Tuple result sorts in dictionary order. The block's results must be comparable with each other; a result type that mixes types that cannot be compared is rejected statically (`type`).

```ruby
p(Set.sort_by(Set["bb", "a", "ccc"]) { |x| String.size(x) })   # => ["a", "bb", "ccc"]
p(Set.sort_by(Set[1, 2, 3]) { |x| -x })                        # => [3, 2, 1]
```

```ruby error
p(Set.sort_by(Set[1, 2]) { |x| x == 1 ? 1 : "a" })   # !> Set.sort_by: elements compared in order may be (Integer, String), which cannot be compared
```

## first

`Set.first(x)`

The element added first. The empty Set gives **nil**, the nil of a miss as with `Array.first`: using it unchecked is reported only at `--strict=3`. There is no form with a count (use `take`).

```ruby
p(Set.first(Set[3, 1]))           # => 3
p(Set.first(Set[]))               # => nil
```

## take, drop

`Set.take(x, Integer)`

`Set.drop(x, Integer)`

The Array of the first n elements, or of the elements after the first n. A negative n is an `ArgumentError`.

```ruby
s = Set[1, 2, 3, 4]
p(Set.take(s, 2))                 # => [1, 2]
p(Set.drop(s, 2))                 # => [3, 4]
p(Set.take(s, 9))                 # => [1, 2, 3, 4]
```

```ruby error
p(Set.take(Set[1], -1))           # !> ArgumentError: Set.take: attempt to take negative size
```

## take_while, drop_while

`Set.take_while(x) { }`

`Set.drop_while(x) { }`

The Array of the leading elements while the block is truthy, or of the rest.

```ruby
s = Set[1, 2, 3, 1]
p(Set.take_while(s) { |x| x < 3 })    # => [1, 2]
p(Set.drop_while(s) { |x| x < 3 })    # => [3]
```

## to_a, entries

`Set.to_a(x)`

`Set.entries(x)`

A new Array of the elements in the order they were added. Changing the Array does not change the Set.

```ruby
s = Set[3, 1]
a = Set.to_a(s)
Array.push(a, 9)
p(a)                              # => [3, 1, 9]
p(s)                              # => Set[3, 1]
p(Set.entries(s))                 # => [3, 1]
```

## to_set

`Set.to_set(x)`

Returns the Set itself (not a copy). It exists for uniformity with `Array.to_set`.

```ruby
s = Set[1]
Set.add(Set.to_set(s), 2)
p(s)                              # => Set[1, 2]
```

## uniq

`Set.uniq(x)`

The Array of the elements. A Set has no duplicates, so it is the same as `to_a`.

```ruby
p(Set.uniq(Set[1, 2]))            # => [1, 2]
```

## compact

`Set.compact(x)`

The Array of the elements without nil.

```ruby
p(Set.compact(Set[1, nil, 2]))    # => [1, 2]
```

## flatten

`Set.flatten(x)`

A **new Set** with the element Sets opened up recursively (Ruby's `Set#flatten`). Array elements are not opened.

```ruby
p(Set.flatten(Set[1, Set[2, Set[3]]]))   # => Set[1, 2, 3]
p(Set.flatten(Set[1, 2]))                # => Set[1, 2]
```

## zip

`Set.zip(x, *Array)`

The Array of Tuples pairing each element with the elements at the same position of each Array. A shorter Array contributes nil. The arguments must be Arrays (a Set is a `type` problem statically).

```ruby
p(Set.zip(Set[1, 2, 3], Array["a", "b"]))   # => [[1, "a"], [2, "b"], [3, nil]]
p(Set.zip(Set[1, 2]))                       # => [[1], [2]]
```

## join

`Set.join(x, [String])`

The String of the elements' `to_s` joined, with the separator ("" by default) between them. Array elements are joined through recursively.

```ruby
s = Set[1, 2, 3]
p(Set.join(s))                    # => "123"
p(Set.join(s, ", "))              # => "1, 2, 3"
```
