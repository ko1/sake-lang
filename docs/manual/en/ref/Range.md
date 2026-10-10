# Range

A Range is a pair of ends with a flag that says whether the end is included: `1..5` includes 5, `1...5` does not. The ends are Integers, Floats, Strings, or nil ([Values and types](../03-values.md)): `1..` is an endless Range, `..5` a beginless one. Write an endless Range in parentheses at the end of a line, `r = (3..)`, because `3..` followed by a line break continues onto the next line, as it does in Ruby. Two ends of different types (`1.."a"`) are an `ArgumentError` at run time. A Range is a value: no operation changes it, and every result is a new value.

The checker keeps the type of the ends with the Range (`Range[Integer]`), and that type decides which operations apply:

- **Walking the values** (`each`, `map`, `to_a`, `select`, `find`, `count`, ...) needs a Range that starts with an Integer or a String. `"a".."e"` walks with Ruby's `String#succ`. A Range of another type, such as `1.0..2.0`, is a `type` problem statically (`the Range's first value must be Integer|String, but is Float`) and a `TypeError` at run time.
- `step`, `sum`, and `size` need an Integer start; a String Range is a `type` problem for them.
- **Finite** is required where the whole Range is used (`to_a`, `map`, `sum`, `last`, `min`, `max`, ...): on an endless Range those raise `RangeError` (`cannot do this on an endless Range 1..`). Operations that can stop early (`each`, `find`, `take`, `first(r, n)`, `each_slice`, `bsearch`) accept an endless Range; `each` on one runs until `break`.
- `cover?`, `overlap?`, `begin`, `end`, and `exclude_end?` compare with the ends only and take any Range, Float and endless ones included. `include?` and `member?` do the same on a Range of numbers, but walk a String Range, as Ruby's do.
- A Range whose beginning is above its end (`5..1`) has no values: walking it does nothing, `to_a` is `[]`, `min` is nil; `first`, `last`, `begin`, and `end` still give the ends.

The operators on Ranges are `==` and `!=` (two Ranges are equal when their ends and `exclude_end?` are). Indexing with a Range (`a[1..3]`, `s[0...2]`) is an operation of Array and String ([Operators and indexing](../05-operators.md)). A Range cannot be a Hash key or a Set element (`TypeError`). Results that may be nil (`first`, `last`, `min`, `max`, `begin`, `end`, `find`, `find_index`, `bsearch`, `min_by`, `max_by`) are typed `T | nil`: `--strict` (level 2) reports using them unchecked. Only the elements of the Tuples of `minmax` and `minmax_by` are the "nil of a miss" (as `a, b = tuple`), which level 3 alone reports.

Many operations are Ruby's Enumerable methods. Unlike Ruby, every block is **required** where the signature shows `{ }` (except `count` and `sum`, whose block is optional), `reduce` and `inject` need the initial value, and the block of `each`, `map`, and the others takes exactly one parameter (`each_with_index`, `each_with_object`, `chunk_while`, `slice_when` take two); a block with the wrong number of parameters is an `ArgumentError` at run time.

## begin, end

`Range.begin(x)`

`Range.end(x)`

The two ends as written, as Ruby's `r.begin` and `r.end`. `end` is the written end even when it is excluded (`Range.end(1...5)` is 5, while `Range.max(1...5)` is 4). The result is `T | nil`: `end` of an endless Range and `begin` of a beginless one are nil, so `--strict` asks for a check before the result is used in arithmetic.

```ruby
p(Range.begin(1..5))         # => 1
p(Range.end(1...5))          # => 5
p(Range.end(1..))            # => nil
p(Range.begin("a".."z"))     # => "a"
```

```ruby error
x = Range.begin(1..5)
p(x + 1)                     # !> the operands may be nil
```

## exclude_end?

`Range.exclude_end?(x)`

True for a Range written with three dots (`1...5`), false for two (`1..5`, `1..`).

```ruby
p(Range.exclude_end?(1..5))      # => false
p(Range.exclude_end?(1...5))     # => true
p(Range.exclude_end?(1..))       # => false
```

## ==, !=

`Range.==(x, Any)`

`Range.!=(x, Any)`

Two Ranges are equal when both ends are `==` and `exclude_end?` agrees (`!=` is the negation). `1..5` and `1...5` differ. A right operand that is not a Range (an Integer, nil) is never equal, with the function form as with the operator: `(1..5) == 5` and `Range.==(1..5, 5)` are both false.

```ruby
p((1..5) == (1..5))          # => true
p((1..5) == (1...5))         # => false
p((1..5) != (1...6))         # => true
p((1..5) == 5)               # => false
p(Range.==(1..5, 1..5))      # => true
p(Range.==(1..5, 5))         # => false
p(Range.!=(1..5, nil))       # => true
```

## include?, cover?, member?

`Range.include?(x, Any)`

`Range.cover?(x, Any)`

`Range.member?(x, Any)`

True when the value is in the Range. `cover?` is Ruby's `cover?`: it compares with the ends only (`begin <= v <= end`, or `< end` for `...`) and never walks the Range, so it works on endless, beginless, and Float Ranges, and a Float is found in an Integer Range. `include?` and `member?` are Ruby's `include?`: on a Range of numbers they are the same as `cover?`, but a **String Range is walked** with `String#succ`, so `"a".."z"` includes `"m"` but not `"mm"` (which `cover?` accepts, since `"a" <= "mm" <= "z"`), and an endless or beginless String Range is a `TypeError` (`cannot determine inclusion in beginless/endless ranges`). A value of another type than the ends (`"a"` in `1..5`, nil) gives false. A Range as the value: `cover?` asks whether it lies entirely inside, as Ruby's; `include?` and `member?` answer false.

```ruby
p(Range.include?(1..5, 5))         # => true
p(Range.include?(1...5, 5))        # => false
p(Range.cover?(1..5, 2.5))         # => true
p(Range.member?(1..5, 0))          # => false
p(Range.include?(1.., 100))        # => true
p(Range.include?("a".."z", "m"))   # => true
p(Range.include?("a".."z", "mm"))  # => false
p(Range.cover?("a".."z", "mm"))    # => true
p(Range.include?(1..5, "a"))       # => false
p(Range.cover?(1..5, 2..3))        # => true
p(Range.include?(1..5, 2..3))      # => false
```

```ruby error
p(Range.include?("a".., "b"))      # !> TypeError: Range.include?: cannot determine inclusion in beginless/endless ranges
```

## overlap?

`Range.overlap?(x, Range)`

True when the two Ranges share at least one value, as Ruby's `overlap?`. An excluded end does not count (`1...5` and `5..8` do not overlap). Any ends are accepted; Ranges of different types do not overlap.

```ruby
p(Range.overlap?(1..5, 3..8))        # => true
p(Range.overlap?(1..5, 6..8))        # => false
p(Range.overlap?(1...5, 5..8))       # => false
p(Range.overlap?(1.., 100..200))     # => true
p(Range.overlap?(1.0..2.0, 1.5..3.0))  # => true
```

## size

`Range.size(x)`

The number of Integers in the Range (an Integer). Only for an Integer Range: a String Range is a `type` problem (`the Range's first value must be Integer, but is String`), as is one that may be a Float (`1..2.5`). An endless Range is a `RangeError`. A Range with the beginning above the end has size 0. Use `count` for a String Range.

```ruby
p(Range.size(1..5))      # => 5
p(Range.size(1...5))     # => 4
p(Range.size(5..1))      # => 0
```

```ruby error
p(Range.size(1..))       # !> RangeError: Range.size: cannot do this on an endless Range 1..
```

## count

`Range.count(x) [{ }]`

Without a block, the number of values (an Integer), walking the Range; with a block, the number of values for which the block gives a truthy result. Works on Integer and String Ranges; needs a finite Range (`RangeError`). Unlike Ruby's `count(v)`, there is no form with a value: use `include?`.

```ruby
p(Range.count("a".."c"))                        # => 3
p(Range.count(1..5) { |i| Integer.odd?(i) })    # => 3
```

## each

`Range.each(x) { }`

Calls the block with each value in turn and returns the Range. An Integer Range walks by 1; a String Range by `String#succ` (`"az".."bc"` gives `"az"`, `"ba"`, `"bb"`, `"bc"`). An endless Range runs until a `break`; `break v` makes `v` the result. The block takes one parameter. A Float Range is a `type` problem.

```ruby
r = Range.each(1..3) { |i| puts(i) }     # => 1
                                         # => 2
                                         # => 3
p(r)                                     # => 1..3
Range.each("a".."c") { |s| print(s) }    # => abc
puts("")
x = Range.each(1..) { |i| break i * 10 if i > 2 }
p(x)                                     # => 30
```

```ruby error
Range.each(1.0..2.0) { |f| p(f) }        # !> the Range's first value must be Integer|String, but is Float
```

## each_with_index

`Range.each_with_index(x) { }`

Calls the block with each value and its position (0, 1, 2, ...) and returns the Range. The block takes two parameters. An endless Range needs a `break`.

```ruby
r = Range.each_with_index("a".."c") { |s, i| p([s, i]) }   # => ["a", 0]
                                                            # => ["b", 1]
                                                            # => ["c", 2]
p(r)                                                        # => "a".."c"
```

## each_entry

`Range.each_entry(x) { }`

The same as `each`: Ruby's `Enumerable#each_entry`, kept for programs written against it. Returns the Range.

```ruby
p(Range.each_entry(1..3) { |i| puts(i) })    # => 1
                                             # => 2
                                             # => 3
                                             # => 1..3
```

## reverse_each

`Range.reverse_each(x) { }`

Calls the block with each value from the end to the beginning and returns the Range. Needs a finite Range (`RangeError`).

```ruby
p(Range.reverse_each(1..3) { |i| puts(i) })  # => 3
                                             # => 2
                                             # => 1
                                             # => 1..3
```

## step

`Range.step(x, Integer) { }`

Calls the block with the beginning, the beginning plus the step, and so on while the value lies in the Range, and returns the Range. Only for an Integer Range (`type` for a String or Float one). An endless Range needs a `break`. A negative step walks a descending Range (`10..1` with -3 gives 10, 7, 4, 1) and gives nothing on an ascending one. A step of 0 is an `ArgumentError` (`step can't be 0`).

```ruby
p(Range.step(1..10, 3) { |i| puts(i) })    # => 1
                                           # => 4
                                           # => 7
                                           # => 10
                                           # => 1..10
Range.step(1...9, 4) { |i| p(i) }          # => 1
                                           # => 5
Range.step(10..1, -3) { |i| p(i) }         # => 10
                                           # => 7
                                           # => 4
                                           # => 1
```

```ruby error
Range.step("a".."z", 2) { |s| p(s) }       # !> the Range's first value must be Integer, but is String
```

```ruby error
Range.step(1..5, 0) { |i| p(i) }           # !> ArgumentError: Range.step: step can't be 0
```

## each_slice

`Range.each_slice(x, Integer) { }`

Calls the block with consecutive Arrays of n values (the last one shorter when the values run out) and returns the Range. An endless Range needs a `break`. A size of 0 or less is an `ArgumentError`.

```ruby
p(Range.each_slice(1..7, 3) { |a| p(a) })    # => [1, 2, 3]
                                             # => [4, 5, 6]
                                             # => [7]
                                             # => 1..7
```

## each_cons

`Range.each_cons(x, Integer) { }`

Calls the block with each window of n consecutive values as an Array and returns the Range. With fewer than n values the block is not called. A size of 0 or less is an `ArgumentError`.

```ruby
p(Range.each_cons(1..4, 2) { |a| p(a) })     # => [1, 2]
                                             # => [2, 3]
                                             # => [3, 4]
                                             # => 1..4
```

## each_with_object

`Range.each_with_object(x, Any) { }`

Calls the block with each value and the given object, and returns that object. Use it to fill a container; as in Ruby, a block that returns a new value does not change the object (`Range.each_with_object(1..3, 0) { |i, acc| acc + i }` returns 0: use `reduce`). An endless Range needs a `break`.

```ruby
a = Range.each_with_object(1..3, Array[]) { |i, acc| Array.push(acc, i * i) }
p(a)                                         # => [1, 4, 9]
```

## cycle

`Range.cycle(x, Integer) { }`

Walks the Range n times over and returns nil. Nothing happens for n of 0 or less. Needs a finite Range (`RangeError`). Unlike Ruby's `cycle` without an argument, the count is required.

```ruby
p(Range.cycle(1..2, 2) { |i| puts(i) })      # => 1
                                             # => 2
                                             # => 1
                                             # => 2
                                             # => nil
```

## to_a, entries

`Range.to_a(x)`

`Range.entries(x)`

A new Array of all the values. Needs an Integer or String Range (`type` otherwise) and a finite one (`RangeError`). The element type of the Array is the type of the ends.

```ruby
p(Range.to_a(1..5))          # => [1, 2, 3, 4, 5]
p(Range.to_a(1...5))         # => [1, 2, 3, 4]
p(Range.entries("a".."e"))   # => ["a", "b", "c", "d", "e"]
p(Range.to_a(5..1))          # => []
```

```ruby error
p(Range.to_a(1..))           # !> RangeError: Range.to_a: cannot do this on an endless Range 1..
```

## first

`Range.first(x, [Integer])`

Without a count: the beginning of the Range, whatever the Range contains (`Range.first(5..1)` is 5, `Range.first(1...1)` is 1, `Range.first(1.0..2.0)` is 1.0). The type is `T | nil` and `--strict` asks for a check before arithmetic; a beginless Range does not give nil but raises `RangeError` (`cannot get the first element of beginless range`). With a count n: a new Array of the first n values (fewer when the Range is shorter), walking the Range, so an Integer or String Range is needed (a Float Range is a `TypeError` at run time, `can't iterate from Float`); an endless Range is fine. A negative count is a `RangeError` (`negative array size (or size too big)`).

```ruby
p(Range.first(1..5))         # => 1
p(Range.first(1..5, 2))      # => [1, 2]
p(Range.first(1..5, 10))     # => [1, 2, 3, 4, 5]
p(Range.first(1.., 3))       # => [1, 2, 3]
p(Range.first("a".."c", 2))  # => ["a", "b"]
```

```ruby error
p(Range.first(..5))          # !> RangeError: Range.first: cannot get the first element of beginless range
```

```ruby error
p(Range.first(1.0..2.0, 2))  # !> TypeError: Range.first: can't iterate from Float
```

## last

`Range.last(x, [Integer])`

Without a count: the written end, as `Range.end` (so `Range.last(1...5)` is 5, as Ruby's). With a count n: a new Array of the last n values, which excludes an excluded end (`Range.last(1...5, 2)` is `[3, 4]`). Needs a finite Range (`RangeError` on an endless one, even without a count). The result without a count is `T | nil`. A negative count is a `RangeError`.

```ruby
p(Range.last(1..5))          # => 5
p(Range.last(1...5))         # => 5
p(Range.last(1..5, 2))       # => [4, 5]
p(Range.last(1...5, 2))      # => [3, 4]
p(Range.last("a".."c"))      # => "c"
```

```ruby error
p(Range.last(1..))           # !> RangeError: Range.last: cannot do this on an endless Range 1..
```

## take

`Range.take(x, Integer)`

A new Array of the first n values (all of them when there are fewer), as `first(r, n)`. An endless Range is fine. A negative n is an `ArgumentError`.

```ruby
p(Range.take(1..10, 3))      # => [1, 2, 3]
p(Range.take(1.., 3))        # => [1, 2, 3]
p(Range.take(1..3, 10))      # => [1, 2, 3]
```

## drop

`Range.drop(x, Integer)`

A new Array of the values after the first n (empty when there are not more). Needs a finite Range (`RangeError`). A negative n is an `ArgumentError`.

```ruby
p(Range.drop(1..5, 2))       # => [3, 4, 5]
p(Range.drop(1..5, 10))      # => []
```

## take_while

`Range.take_while(x) { }`

A new Array of the values from the beginning up to, not including, the first for which the block gives a falsy result. An endless Range is fine as long as the block eventually says no.

```ruby
p(Range.take_while(1..10) { |i| i < 4 })   # => [1, 2, 3]
p(Range.take_while(1..) { |i| i < 4 })     # => [1, 2, 3]
```

## drop_while

`Range.drop_while(x) { }`

A new Array of the values from the first for which the block gives a falsy result to the end. An endless Range is not rejected, but the result would be endless, so the operation never returns on one.

```ruby
p(Range.drop_while(1..6) { |i| i < 4 })    # => [4, 5, 6]
```

## map, collect

`Range.map(x) { }`

`Range.collect(x) { }`

A new Array of the block's results, one per value. Needs a finite Integer or String Range. The element type of the Array is the type of the block's results.

```ruby
n = 4
p(Range.map(1..n) { |i| i * i })                 # => [1, 4, 9, 16]
p(Range.collect("a".."c") { |s| String.upcase(s) })   # => ["A", "B", "C"]
```

```ruby error
p(Range.map(1..) { |i| i })                      # !> RangeError: Range.map: cannot do this on an endless Range 1..
```

## flat_map, collect_concat

`Range.flat_map(x) { }`

`Range.collect_concat(x) { }`

A new Array that joins the Arrays (or Tuples) the block returns, one level deep. The block must return an Array or a Tuple: another value is a `TypeError` at run time (`the block must return an Array or a Tuple, got Integer`). Needs a finite Range.

```ruby
p(Range.flat_map(1..3) { |i| Array[i, i] })      # => [1, 1, 2, 2, 3, 3]
p(Range.flat_map(1..2) { |i| [i, i * 10] })      # => [1, 10, 2, 20]
```

```ruby error
p(Range.flat_map(1..2) { |i| i })                # !> TypeError: Range.flat_map: the block must return an Array or a Tuple, got Integer
```

## select, filter, find_all

`Range.select(x) { }`

`Range.filter(x) { }`

`Range.find_all(x) { }`

A new Array of the values for which the block gives a truthy result. Needs a finite Integer or String Range. The Array's element type is the type of the ends.

```ruby
p(Range.select(1..6) { |i| Integer.even?(i) })   # => [2, 4, 6]
p(Range.filter("a".."e") { |s| s > "c" })        # => ["d", "e"]
```

## reject

`Range.reject(x) { }`

A new Array of the values for which the block gives a falsy result; the complement of `select`. Needs a finite Range.

```ruby
p(Range.reject(1..6) { |i| Integer.even?(i) })   # => [1, 3, 5]
```

## filter_map

`Range.filter_map(x) { }`

A new Array of the block's results, leaving out nil and false, as Ruby's `filter_map`. The checker removes nil from the element type, so the Array can be used without nil checks. Needs a finite Range.

```ruby
p(Range.filter_map(1..6) { |i| Integer.even?(i) ? i * 10 : nil })   # => [20, 40, 60]
```

## partition

`Range.partition(x) { }`

A Tuple of two Arrays: the values for which the block is truthy, then the others. Needs a finite Range.

```ruby
evens, odds = Range.partition(1..6) { |i| Integer.even?(i) }
p(evens)                                         # => [2, 4, 6]
p(odds)                                          # => [1, 3, 5]
```

## group_by

`Range.group_by(x) { }`

A Hash from each block result to the Array of the values that gave it, in order of first appearance. Needs a finite Range. The key type is the type of the block's results; the value type is an Array of the ends' type (reading `h[k]` gives nil for a key that is not there, as any Hash does).

```ruby
h = Range.group_by(1..6) { |i| i % 3 }
p(h)                                             # => {1 => [1, 4], 2 => [2, 5], 0 => [3, 6]}
p(h[1])                                          # => [1, 4]
```

## chunk_while, slice_when

`Range.chunk_while(x) { }`

`Range.slice_when(x) { }`

An Array of Arrays that cuts the values into runs. The block receives two consecutive values; `chunk_while` keeps them in the same run while the block is truthy, `slice_when` starts a new run when it is truthy. Needs a finite Range.

```ruby
p(Range.chunk_while(1..5) { |a, b| b != 3 })         # => [[1, 2], [3, 4, 5]]
p(Range.slice_when(1..6) { |a, b| Integer.even?(b) })  # => [[1], [2, 3], [4, 5], [6]]
```

## slice_before, slice_after

`Range.slice_before(x) { }`

`Range.slice_after(x) { }`

An Array of Arrays that cuts the values before (or after) each value for which the block is truthy. Needs a finite Range.

```ruby
p(Range.slice_before(1..6) { |i| Integer.even?(i) })  # => [[1], [2, 3], [4, 5], [6]]
p(Range.slice_after(1..6) { |i| Integer.even?(i) })   # => [[1, 2], [3, 4], [5, 6]]
```

## find, detect

`Range.find(x) { }`

`Range.detect(x) { }`

The first value for which the block gives a truthy result, or nil when there is none. The result is `T | nil`, so `--strict` wants a check before it is used. An endless Range is fine when some value satisfies the block; otherwise the search never ends.

```ruby
p(Range.find(1..10) { |i| i * i > 10 })      # => 4
p(Range.detect(1..10) { |i| i > 100 })       # => nil
p(Range.find(1..) { |i| i * i > 10 })        # => 4
s = Range.find("a".."e") { |c| c > "b" }
if s
  p(String.upcase(s))                        # => "C"
end
```

## find_index

`Range.find_index(x) { }`

The position (0, 1, 2, ...) of the first value for which the block is truthy, or nil (`Integer | nil`). Unlike Ruby's `find_index(v)`, a block is required and there is no form with a value. An endless Range is fine when a value is found.

```ruby
p(Range.find_index(1..10) { |i| i * i > 10 })  # => 3
p(Range.find_index(1..10) { |i| i > 100 })     # => nil
```

## bsearch

`Range.bsearch(x) { }`

Binary search over an Integer Range, as Ruby's: in find-minimum mode the block gives true for the wanted value and every value above it, and the result is the smallest such value, or nil when the block is never true (`T | nil`). An endless Range is fine. A String Range is a `TypeError` at run time (`can't do binary search for String`).

```ruby
p(Range.bsearch(1..100) { |i| i * i >= 50 })   # => 8
p(Range.bsearch(1..100) { |i| i > 1000 })      # => nil
p(Range.bsearch(1..) { |i| i * i >= 50 })      # => 8
```

```ruby error
p(Range.bsearch("a".."z") { |s| s >= "m" })    # !> TypeError: Range.bsearch: can't do binary search for String
```

## all?, any?, none?, one?

`Range.all?(x) { }`

`Range.any?(x) { }`

`Range.none?(x) { }`

`Range.one?(x) { }`

Whether the block is truthy for every value, for at least one, for none, or for exactly one. Unlike Ruby's, the block is required (there is no `any?` without a block and no pattern argument). Needs a finite Range (`RangeError`). On a Range with no values, `all?` and `none?` are true, `any?` and `one?` false.

```ruby
p(Range.all?(1..5) { |i| i > 0 })    # => true
p(Range.any?(1..5) { |i| i > 4 })    # => true
p(Range.none?(1..5) { |i| i > 5 })   # => true
p(Range.one?(1..5) { |i| i == 3 })   # => true
p(Range.any?(5..1) { |i| true })     # => false
```

## reduce, inject

`Range.reduce(x, Any) { }`

`Range.inject(x, Any) { }`

Folds the values: the block receives the accumulated value and the next value, and its result becomes the accumulated value; the result is the last accumulated value. The initial value is **required** (Ruby's `inject` without one is a `wrong number of arguments` problem), and the result's type is that of the initial value joined with the block's results. There is no symbol form (`reduce(:+)`); use `sum` for that. Needs a finite Range.

```ruby
p(Range.reduce(1..5, 0) { |acc, i| acc + i })                   # => 15
p(Range.inject(1..5, 1) { |acc, i| acc * i })                   # => 120
p(Range.reduce(1..3, "") { |acc, i| acc + Integer.to_s(i) })    # => "123"
p(Range.reduce(5..1, 7) { |acc, i| acc + i })                   # => 7
```

```ruby error
p(Range.inject(1..5) { |acc, i| acc + i })   # !> wrong number of arguments for Range.inject (given 1, expected 2)
```

## sum

`Range.sum(x, [Integer|Float|Rational|Complex]) [{ }]`

The sum of the values, or of the block's results, added to the initial value (default 0). Only for an Integer Range (`type` for a String Range), and a finite one (`RangeError`). The result's type follows the initial value and the block: Integer values with an Integer start give an Integer; a Float start gives a Float. As Ruby's `Range#sum`, an Integer Range with a Rational initial value gives a Float (`Range.sum(1..3, 2r)` is 8.0), and a Complex initial value is a `RangeError` at run time (`can't convert 1+2i into Float`). A block whose results are not numbers is a `type` problem.

```ruby
p(Range.sum(1..100))                 # => 5050
p(Range.sum(1..10, 100))             # => 155
p(Range.sum(1..3) { |i| i * 2 })     # => 12
p(Range.sum(1..3, 0.5))              # => 6.5
p(Range.sum(1..3, 2r))               # => 8.0
p(Range.sum(1..0))                   # => 0
```

```ruby error
p(Range.sum("a".."c"))               # !> the Range's first value must be Integer, but is String
```

```ruby error
p(Range.sum(1..3, Complex(1, 2)))    # !> RangeError: Range.sum: can't convert 1+2i into Float
```

## min, max

`Range.min(x)`

`Range.max(x)`

The smallest and the largest value, or nil when the Range has no values (`5..1`): the type is `T | nil`. `max` respects an excluded end (`Range.max(1...5)` is 4). Needs a finite Range (`RangeError`). Both accept a Float Range with an included end (`Range.max(1.0..2.5)` is 2.5), as Ruby's; `max` of a Float Range with an excluded end is a `TypeError` (`cannot exclude non Integer end value`; `min` of it is fine).

```ruby
p(Range.min(1..5))           # => 1
p(Range.max(1...5))          # => 4
p(Range.max(5..1))           # => nil
p(Range.min("a".."c"))       # => "a"
p(Range.max(1.0..2.5))       # => 2.5
p(Range.min(1.0...2.5))      # => 1.0
```

```ruby error
x = Range.min(1..5)
p(x + 1)                     # !> the operands may be nil
```

```ruby error
p(Range.max(1.0...2.5))      # !> TypeError: Range.max: cannot exclude non Integer end value
```

## minmax

`Range.minmax(x)`

The Tuple `[min, max]`; both are nil on a Range with no values (`5..1`, `2.5..1.0`). Those are the nil of a miss: using an element unchecked is reported only at `--strict=3`. Needs a finite Range (`RangeError`). As `min` and `max`, it accepts a Float Range with an included end (`Range.minmax(1.0..2.5)` is `[1.0, 2.5]`); a Float Range with an excluded end is a `TypeError` (`cannot exclude non Integer end value`).

```ruby
lo, hi = Range.minmax(1..5)
p([lo, hi])                  # => [1, 5]
p(Range.minmax(5..1))        # => [nil, nil]
p(Range.minmax(1.0..2.5))    # => [1.0, 2.5]
p(Range.minmax("a".."c"))    # => ["a", "c"]
```

```ruby error
p(Range.minmax(1.0...2.5))   # !> TypeError: Range.minmax: cannot exclude non Integer end value
```

## min_by, max_by

`Range.min_by(x) { }`

`Range.max_by(x) { }`

The value for which the block gives the smallest (largest) result, or nil on a Range with no values (`T | nil`). Needs a finite Range.

```ruby
p(Range.min_by(1..5) { |i| -i })               # => 5
p(Range.max_by("a".."e") { |s| String.ord(s) })  # => "e"
p(Range.min_by(5..1) { |i| i })                # => nil
```

## minmax_by

`Range.minmax_by(x) { }`

The Tuple of the values with the smallest and the largest block result; `[nil, nil]` on a Range with no values (the nil of a miss, reported only at `--strict=3`). Needs a finite Range.

```ruby
p(Range.minmax_by(1..5) { |i| -i })    # => [5, 1]
```

## sort

`Range.sort(x)`

A new Array of the values in ascending order, which for a Range is `to_a`. Needs a finite Integer or String Range.

```ruby
p(Range.sort(1..3))          # => [1, 2, 3]
p(Range.sort(3..1))          # => []
```

## sort_by

`Range.sort_by(x) { }`

A new Array of the values ordered by the block's results. Needs a finite Range.

```ruby
p(Range.sort_by(1..5) { |i| -i })                    # => [5, 4, 3, 2, 1]
p(Range.sort_by("a".."c") { |s| -String.ord(s) })    # => ["c", "b", "a"]
```

## uniq

`Range.uniq(x)`

A new Array of the values without duplicates; since a Range has none, it is `to_a`. Needs a finite Integer or String Range.

```ruby
p(Range.uniq(1..3))          # => [1, 2, 3]
```

## compact

`Range.compact(x)`

A new Array of the values without nil; since a Range has no nil, it is `to_a`. Needs a finite Integer or String Range.

```ruby
p(Range.compact(1..3))       # => [1, 2, 3]
```

## tally

`Range.tally(x)`

A Hash from each value to how often it appears, which for a Range is always 1. Needs a finite Integer or String Range.

```ruby
p(Range.tally("a".."c"))     # => {"a" => 1, "b" => 1, "c" => 1}
```

## to_set

`Range.to_set(x)`

A new Set of the values. Needs a finite Integer or String Range.

```ruby
p(Range.to_set(1..3))        # => Set[1, 2, 3]
```

## zip

`Range.zip(x, *Array)`

A new Array of Tuples: the i-th Tuple holds the i-th value of the Range and the i-th element of each Array given. A shorter Array contributes nil (the Tuple's type says so). Without Arrays each Tuple holds one value. Needs a finite Integer or String Range.

```ruby
p(Range.zip(1..3, Array["a", "b", "c"]))     # => [[1, "a"], [2, "b"], [3, "c"]]
p(Range.zip(1..3, Array[10, 20]))            # => [[1, 10], [2, 20], [3, nil]]
p(Range.zip(1..2))                           # => [[1], [2]]
```
