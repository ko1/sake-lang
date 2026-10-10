# Hash

A Hash maps keys to values and keeps insertion order. There is no literal like Ruby's `{"a" => 1}`: a Hash is made by `Hash["a" => 1, b: 2]`, `Hash[]`, or `Hash.new(default)` ([Values and types](../03-values.md)). **`{k: v}` is a Record, not a Hash** (and `{}` is an empty Record, rejected statically; see [Record](Record.md)). Keys written as labels, `Hash[name: v]`, are Symbols.

A key may be an Integer, Float, String, Symbol, true, false, nil, Time, or a Tuple, Record, Array, Hash, Set, or a value of a class made only of these. A Regexp, a Range, or a value of a class that defines its own equality (`==` or `Comparable`) cannot be a key: `TypeError` at run time. Tuple and Record keys are copied when stored, so writing to the original later does not change the key (an Array key, as in Ruby, becomes unfindable when changed). `"a"` and `:a` are different keys, and so are `1` and `1.0`.

`h[k]` gives nil on a miss (the default, for a Hash made by `Hash.new(default)`). Using that nil unchecked is reported only at `--strict=3`, as `index-nil` (level 2 does not report it). To make a miss an exception, use `Hash.fetch`. The nil of `Hash.dig`, `Hash.min_by` and `Hash.max_by` is a miss too (level 3). The nil of `Hash.delete`, `Hash.key`, `Hash.first`, `Hash.shift`, `Hash.find` and the like is reported at level 2.

An operation that takes a block passes each entry as one Tuple `[key, value]`: `|k, v|` takes it apart, `|kv|` receives the Tuple. `each_with_object` takes `|(k, v), memo|` and `reduce` takes `|acc, (k, v)|`. Iteration follows insertion order. The pairs returned by `to_a`, `sort_by`, `take`, `first` and others are `[k, v]` Tuples too.

The checker gives each Hash, per the place it is made, one key type and one value type. Storing another type with `Hash.store` or `[]=` makes the value type a union (after putting `"x"` into `Hash["a" => 1]` the values are `Integer | String`, and `+ 1` on a fetched value is a `type` problem). In-place operations that change the element type, `transform_keys!` and `transform_values!`, do the same (see below).

The operators on a Hash are `==`, `!=` and the index `h[k]`, `h[k] = v`. `Hash.==(x, y)` and so on are the function forms of those operators ([Operators and indexing](../05-operators.md)).

## Hash[]

`Hash[*Any]`

`Hash[k => v, ...]` makes a new Hash. The arguments are `key => value` pairs only (in the label form `Hash[name: v]` the key is a Symbol); anything else (`Hash[1]`, `Hash[{x: 1}]`) is a static error. `Hash[]` is the empty Hash. When a key is written twice, the later value stays. A value that cannot be a key is a `TypeError` at run time. Unlike the other `T[...]` forms, this returns a Hash itself, not an Array of Hashes.

```ruby
h = Hash["a" => 1, b: 2]
p(h)                               # => {"a" => 1, b: 2}
p(Hash[])                          # => {}
p(Hash[1 => 2, 1 => 3])            # => {1 => 3}
p(Hash[[1, 2] => "t", nil => "n"])  # => {[1, 2] => "t", nil => "n"}
```

```ruby error
p(Hash[1])                         # !> Hash[...] takes `key => value` pairs, like `Hash["a" => 1]`
```

## new

`Hash.new([Any])`

Makes an empty Hash. `Hash.new(default)` makes one whose `h[k]` gives `default` for a missing key, as Ruby's does. That one object is shared: changing the Array of `Hash.new(Array[])` through `h["x"]` is visible under every key, and nothing is stored in the Hash. Ruby's block form `Hash.new { |h, k| ... }` does not exist (a static error). `Hash.fetch` ignores the default.

```ruby
counts = Hash.new(0)
counts["x"] += 1
counts["x"] += 1
p(counts)                          # => {"x" => 2}
p(counts["none"])                  # => 0
p(Hash.new["none"])                # => nil
d = Hash.new(Array[])
Array.push(d["a"], 1)
p(d["b"])                          # => [1]
p(d)                               # => {}
```

```ruby error
h = Hash.new { |hh, k| 0 }         # !> Hash.new does not take a block
```

## default, set_default

`Hash.default(x)`

`Hash.set_default(x, Any)`

`default` is the value `h[k]` gives for a missing key (the default of `Hash.new(default)`; nil when there is none). `set_default(h, v)` changes it to `v` and returns `v` (Ruby's `h.default = v`). The checker adds the default's type to the type of `h[k]`.

```ruby
h = Hash.new(0)
p(Hash.default(h))                 # => 0
p(Hash.default(Hash[]))            # => nil
Hash.set_default(h, 5)
p(h["q"])                          # => 5
```

## []

`Hash.[](x, Any)`

The function form of `h[k]`. Returns the value under key `k`, or the default (normally nil) when there is none. That nil is reported only at `--strict=3`, as `index-nil`. The key may be of any type; no value is a static problem. For a Hash made by `Hash.new(default)` the default's type joins the result, so `h[k] + 1` on `Hash.new(0)` passes even at level 3.

```ruby
h = Hash["a" => 1, [1, 2] => "t"]
p(h["a"])                          # => 1
p(h[[1, 2]])                       # => "t"
p(h["zz"])                         # => nil
p(Hash.[](h, "a"))                 # => 1
```

## []=, store

`Hash.[]=(x, Any, Any)`

`Hash.store(x, Any, Any)`

`h[k] = v` and its function form. Binds key `k` to value `v` and returns `v`. A new key goes to the end; an existing key keeps its position and only its value changes. A value that cannot be a key is a `TypeError`. The checker adds the types of `k` and `v` to the Hash's key and value types.

```ruby
h = Hash["a" => 1]
h["b"] = 2
p(Hash.store(h, "a", 10))          # => 10
p(h)                               # => {"a" => 10, "b" => 2}
```

```ruby error
Hash.store(Hash[], /x/, 1)         # !> TypeError: Hash.store: Regexp cannot be a Hash key or Set element
```

## fetch

`Hash.fetch(x, Any, [Any])`

Returns the value under key `k`. When there is none, returns the third argument `default` if given, and otherwise raises `KeyError` (as Ruby's; there is no block form). The default of `Hash.new(default)` is not used. The result type is the union of the value type and the type of `default`, so it is never nil unless a value is: used instead of `h[k]`, it avoids the `index-nil` report of `--strict=3` too.

```ruby
h = Hash["a" => 1]
p(Hash.fetch(h, "a"))              # => 1
p(Hash.fetch(h, "zz", 0))          # => 0
p(Hash.fetch(h, "a") + 1)          # => 2
```

```ruby error
p(Hash.fetch(Hash["a" => 1], "b")) # !> KeyError: Hash.fetch: key not found: "b"
```

## dig

`Hash.dig(x, Any, *Any)`

Digs through nested containers with the keys in order, as Ruby's `dig`: `dig(h, k)` is `h[k]`, and each further key indexes the value found so far (a Hash by key, an Array or a Tuple by position). The result is the value reached, or nil as soon as a key is missing on the way (for a miss in a Hash made by `Hash.new(default)` the default is given, as by `h[k]`, and the checker adds the default's type to the result). That nil is the nil of a miss, as with `h[k]`: using it unchecked is reported only at `--strict=3`, as `index-nil`; level 2 does not report it. The checker follows the keys through the types: a key applied to a value that is not a Hash, an Array, or a Tuple (an Integer, a String, a Record) is a `type` problem statically (`the value must be Array|Hash|Tuple, but is Integer`). A key of the wrong kind for the container reached (a String for an Array) is a `TypeError` at run time (`an index into Array must be Integer, got String`).

```ruby
h = Hash["a" => Hash["b" => Array[10, 20]]]
p(Hash.dig(h, "a", "b", 1))        # => 20
p(Hash.dig(h, "a", "zz", 1))       # => nil
p(Hash.dig(h, "zz"))               # => nil
t = Hash["t" => [1, "x"]]
p(Hash.dig(t, "t", 1))             # => "x"
p(Hash.dig(t, "t", 5))             # => nil
p(Hash.dig(Hash.new(0), "q") + 1)  # => 1
x = Hash.dig(h, "a", "b", 0)
if x
  p(x + 1)                         # => 11
end
```

```ruby error
p(Hash.dig(Hash["a" => 1], "a", "b"))   # !> Hash.dig: the value must be Array|Hash|Tuple, but is Integer
```

## fetch_values

`Hash.fetch_values(x, *Any)`

An Array of the values under the listed keys, in that order. A missing key raises `KeyError` (the default is not used). The element type is the value type; it is never nil.

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.fetch_values(h, "b", "a"))  # => [2, 1]
```

```ruby error
p(Hash.fetch_values(Hash["a" => 1], "a", "zz"))   # !> KeyError: Hash.fetch_values: key not found: "zz"
```

## values_at

`Hash.values_at(x, *Any)`

An Array of the values under the listed keys, in that order. A missing key gives the default (normally nil) at its position. The element type is `value | nil`, so using an element unchecked is reported at level 2.

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.values_at(h, "a", "zz"))    # => [1, nil]
p(Hash.values_at(Hash.new(9), "x"))   # => [9]
```

## key?, has_key?, include?, member?

`Hash.key?(x, Any)`

`Hash.has_key?(x, Any)`

`Hash.include?(x, Any)`

`Hash.member?(x, Any)`

True when key `k` is present, even when its value is nil (this tells it apart from an `h[k]` that gives nil). The four are the same operation.

```ruby
h = Hash["a" => nil]
p(Hash.key?(h, "a"))               # => true
p(Hash.include?(h, "b"))           # => false
p(h["a"])                          # => nil
```

## value?, has_value?

`Hash.value?(x, Any)`

`Hash.has_value?(x, Any)`

True when some value is `==` to `v`.

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.value?(h, 2))               # => true
p(Hash.has_value?(h, 3))           # => false
```

## key

`Hash.key(x, Any)`

The first key whose value equals `v`, or nil (reported at level 2).

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 2]
p(Hash.key(h, 2))                  # => "b"
p(Hash.key(h, 9))                  # => nil
```

## assoc, rassoc

`Hash.assoc(x, Any)`

`Hash.rassoc(x, Any)`

`assoc(h, k)` is the pair `[k, v]` under key `k`; `rassoc(h, v)` is the first pair `[k, v]` whose value is `v`. Both are Tuples, or nil (reported at level 2).

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.assoc(h, "a"))              # => ["a", 1]
p(Hash.rassoc(h, 2))               # => ["b", 2]
p(Hash.assoc(h, "zz"))             # => nil
```

## length, size

`Hash.length(x)`

`Hash.size(x)`

The number of entries (an Integer).

```ruby
p(Hash.size(Hash["a" => 1, "b" => 2]))   # => 2
p(Hash.length(Hash[]))                   # => 0
```

## empty?

`Hash.empty?(x)`

True when there are no entries.

```ruby
p(Hash.empty?(Hash[]))             # => true
p(Hash.empty?(Hash.new(0)))        # => true
p(Hash.empty?(Hash["a" => 1]))     # => false
```

## count

`Hash.count(x) [{ }]`

Without a block, the number of entries (as `size`); with a block, the number of entries for which the block, given `[k, v]`, returns true (an Integer).

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
p(Hash.count(h))                   # => 3
p(Hash.count(h) { |k, v| v >= 2 })   # => 2
```

## keys

`Hash.keys(x)`

A new Array of the keys in insertion order. Its element type is the key type. It is not a typed Array, so values of other types can be pushed onto it.

```ruby
h = Hash["b" => 2, "a" => 1]
p(Hash.keys(h))                    # => ["b", "a"]
p(Hash.keys(Hash[]))               # => []
```

## values

`Hash.values(x)`

A new Array of the values in insertion order. Its element type is the value type.

```ruby
h = Hash["b" => 2, "a" => 1]
p(Hash.values(h))                  # => [2, 1]
```

## to_a

`Hash.to_a(x)`

A new Array of the entries as `[k, v]` Tuples, in insertion order. The inner Arrays of Ruby's `to_a` are Tuples in Sake.

```ruby
h = Hash[1 => "x", 2 => "y"]
p(Hash.to_a(h))                    # => [[1, "x"], [2, "y"]]
Array.each(Hash.to_a(h)) { |k, v| p(k) }   # => 1
                                           # => 2
```

## flatten

`Hash.flatten(x)`

A new Array of the keys and values alternating, `[k1, v1, k2, v2, ...]`. As Ruby's `flatten` at depth 1: an Array or Tuple value is not opened (there is no depth argument). The element type is the union of the key and value types.

```ruby
p(Hash.flatten(Hash[1 => "x", 2 => "y"]))        # => [1, "x", 2, "y"]
p(Hash.flatten(Hash["a" => Array[1, 2]]))        # => ["a", [1, 2]]
```

## to_h

`Hash.to_h(x)`

The Hash itself (as Ruby's `Hash#to_h`; not a copy). There is no block form. For a copy use `Hash.dup`.

```ruby
h = Hash["a" => 1]
p(Hash.to_h(h))                    # => {"a" => 1}
p(Kernel.equal?(Hash.to_h(h), h))  # => true
```

## dup

`Hash.dup(x)`

A new Hash with the same entries (a shallow copy: the key and value objects are shared). The default is kept. A `store` or `delete` on one does not affect the other.

```ruby
h = Hash.new(0)
Hash.store(h, "a", 1)
h2 = Hash.dup(h)
Hash.store(h2, "b", 2)
p(h)                               # => {"a" => 1}
p(h2)                              # => {"a" => 1, "b" => 2}
p(h2["zz"])                        # => 0
```

## first

`Hash.first(x)`

The first inserted entry as a Tuple `[k, v]`, or nil when the Hash is empty (reported at level 2). Ruby's `first(n)` form does not exist; the first n entries are `Hash.take`.

```ruby
p(Hash.first(Hash["a" => 1, "b" => 2]))   # => ["a", 1]
p(Hash.first(Hash[]))                     # => nil
```

## take, drop

`Hash.take(x, Integer)`

`Hash.drop(x, Integer)`

`take(h, n)` is the first n entries, `drop(h, n)` the rest after the first n, as an Array of `[k, v]` Tuples. The Hash does not change. n may exceed the number of entries. A negative n is an `ArgumentError`.

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
p(Hash.take(h, 2))                 # => [["a", 1], ["b", 2]]
p(Hash.drop(h, 2))                 # => [["c", 3]]
p(Hash.drop(h, 5))                 # => []
```

```ruby error
p(Hash.take(Hash["a" => 1], -1))   # !> ArgumentError: Hash.take: attempt to take negative size
```

## each, each_pair

`Hash.each(x) { }`

`Hash.each_pair(x) { }`

Calls the block for each entry in insertion order and returns the Hash itself. The block receives the Tuple `[k, v]` (`|k, v|` takes it apart). The block is required (Ruby's blockless form returning an Enumerator does not exist).

```ruby
h = Hash["a" => 1, "b" => 2]
Hash.each(h) { |k, v| p(k + Integer.to_s(v)) }   # => "a1"
                                                 # => "b2"
Hash.each_pair(h) { |kv| p(kv) }                 # => ["a", 1]
                                                 # => ["b", 2]
r = Hash.each(h) { |k, v| nil }
p(Kernel.equal?(r, h))                           # => true
```

## each_key

`Hash.each_key(x) { }`

Calls the block for each key and returns the Hash itself. The block receives only the key.

```ruby
Hash.each_key(Hash["a" => 1, "b" => 2]) { |k| p(k) }   # => "a"
                                                       # => "b"
```

## each_value

`Hash.each_value(x) { }`

Calls the block for each value and returns the Hash itself. The block receives only the value.

```ruby
Hash.each_value(Hash["a" => 1, "b" => 2]) { |v| p(v * 10) }   # => 10
                                                              # => 20
```

## each_with_object

`Hash.each_with_object(x, Any) { }`

Calls the block for each entry while carrying `memo` along, and returns `memo` at the end. The block receives two things, the Tuple `[k, v]` and `memo`, so it is written `|(k, v), memo|`. The result type is the type of `memo`.

```ruby
h = Hash["a" => 1, "b" => 2]
ks = Hash.each_with_object(h, Array[]) { |(k, v), acc| Array.push(acc, k) }
p(ks)                              # => ["a", "b"]
```

## map

`Hash.map(x) { }`

Calls the block with `[k, v]` for each entry and returns a new Array of the results. As in Ruby the result is an Array, not a Hash (for a Hash use `transform_values` or `to_h`).

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.map(h) { |k, v| k + Integer.to_s(v) })   # => ["a1", "b2"]
p(Hash.map(h) { |kv| kv })                      # => [["a", 1], ["b", 2]]
```

## flat_map

`Hash.flat_map(x) { }`

Calls the block for each entry and returns a new Array of all the Arrays it returned, joined. The block must return an **Array or a Tuple** (a Tuple's elements are joined in like an Array's); a scalar is a `TypeError` at run time (`the block must return an Array or a Tuple, got Integer`; Ruby keeps a non-Array result as one element).

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.flat_map(h) { |k, v| Array[k, v] })   # => ["a", 1, "b", 2]
p(Hash.flat_map(h) { |k, v| [k, v] })        # => ["a", 1, "b", 2]
```

```ruby error
Hash.flat_map(Hash["a" => 1]) { |k, v| v }   # !> TypeError: Hash.flat_map: the block must return an Array or a Tuple, got Integer
```

## filter_map

`Hash.filter_map(x) { }`

Calls the block for each entry and returns a new Array of the results other than nil and false.

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
p(Hash.filter_map(h) { |k, v| v > 1 ? k : nil })   # => ["b", "c"]
```

## select, filter

`Hash.select(x) { }`

`Hash.filter(x) { }`

A new Hash of the entries for which the block returns true (a Hash, as in Ruby). The original does not change. The key and value types are those of the original.

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
p(Hash.select(h) { |k, v| v > 1 })   # => {"b" => 2, "c" => 3}
p(Hash.filter(h) { |k, v| k == "a" })   # => {"a" => 1}
p(h)                                 # => {"a" => 1, "b" => 2, "c" => 3}
```

## reject

`Hash.reject(x) { }`

A new Hash without the entries for which the block returns true. The original does not change.

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
p(Hash.reject(h) { |k, v| v > 1 })   # => {"a" => 1}
```

## partition

`Hash.partition(x) { }`

The entries for which the block returns true and those for which it returns false, each as an Array of `[k, v]` Tuples, in a two-element Tuple `[true ones, false ones]`. Take it with multiple assignment.

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
odd, even = Hash.partition(h) { |k, v| Integer.odd?(v) }
p(odd)                             # => [["a", 1], ["c", 3]]
p(even)                            # => [["b", 2]]
```

## group_by

`Hash.group_by(x) { }`

Calls the block for each entry and returns a new Hash from each block result to the Array of the `[k, v]` Tuples that gave it. The block result must be a value that can be a key.

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
g = Hash.group_by(h) { |k, v| v % 2 }
p(g)                               # => {1 => [["a", 1], ["c", 3]], 0 => [["b", 2]]}
p(Hash.fetch(g, 0))                # => [["b", 2]]
```

## find, detect

`Hash.find(x) { }`

`Hash.detect(x) { }`

The first entry for which the block returns true, as a Tuple `[k, v]`, or nil. At level 2, passing that nil on to multiple assignment or an index is reported, so check with `if`.

```ruby
h = Hash["a" => 1, "b" => 2]
kv = Hash.find(h) { |k, v| v == 2 }
if kv
  k, v = kv
  p(k)                             # => "b"
end
p(Hash.detect(h) { |k, v| v == 9 })   # => nil
```

```ruby error
kv = Hash.find(Hash["a" => 1]) { |k, v| v == 1 }
k, v = kv                          # !> multiple assignment: argument 1 may be nil
```

## min_by, max_by

`Hash.min_by(x) { }`

`Hash.max_by(x) { }`

The entry for which the block result is smallest or largest, as a Tuple `[k, v]`, or nil for an empty Hash. That nil is the nil of a miss (as `Array.min_by`): using it unchecked is reported only at `--strict=3`. The block results must compare with each other: a block whose result type mixes types that cannot be compared (Integer and String) is rejected statically as a `type` problem, and one whose result may be nil as a `nil` problem; when the checker cannot see it (`Float.NAN`) it is an `ArgumentError` at run time.

```ruby
h = Hash["a" => 3, "b" => 1, "c" => 2]
p(Hash.min_by(h) { |k, v| v })     # => ["b", 1]
p(Hash.max_by(h) { |k, v| v })     # => ["a", 3]
p(Hash.max_by(Hash[]) { |k, v| v })   # => nil
```

```ruby error
Hash.min_by(Hash["a" => 1, "b" => "x"]) { |k, v| v }   # !> Hash.min_by: elements compared in order may be (Integer, String), which cannot be compared
```

## sort_by

`Hash.sort_by(x) { }`

The entries in ascending order of the block result, as an Array of `[k, v]` Tuples (an Array, not a Hash, as in Ruby). The block results must compare with each other: a result type that mixes types that cannot be compared is rejected statically (`type`), as with `min_by`. For descending order negate in the block or use `Array.reverse`. A Tuple result sorts in dictionary order ([Tuple](Tuple.md)).

```ruby
h = Hash["a" => 3, "b" => 1, "c" => 2]
p(Hash.sort_by(h) { |k, v| v })    # => [["b", 1], ["c", 2], ["a", 3]]
p(Hash.sort_by(h) { |k, v| -v })   # => [["a", 3], ["c", 2], ["b", 1]]
```

```ruby error
Hash.sort_by(Hash["a" => 1, "b" => "x"]) { |k, v| v }   # !> Hash.sort_by: elements compared in order may be (Integer, String), which cannot be compared
```

## any?, all?, none?

`Hash.any?(x) { }`

`Hash.all?(x) { }`

`Hash.none?(x) { }`

Whether the block returns true for at least one entry (`any?`), for every entry (`all?`), or for none (`none?`). The block is required (Ruby's blockless forms do not exist and are a static error; for emptiness use `empty?`). On an empty Hash `any?` is false and `all?` and `none?` are true.

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.any?(h) { |k, v| v > 1 })   # => true
p(Hash.all?(h) { |k, v| v > 1 })   # => false
p(Hash.none?(h) { |k, v| v > 5 })  # => true
```

```ruby error
p(Hash.any?(Hash["a" => 1]))       # !> Hash.any? requires a block
```

## one?

`Hash.one?(x) { }`

True when the block returns true for exactly one entry. The block is required.

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.one?(h) { |k, v| v == 2 })  # => true
p(Hash.one?(h) { |k, v| v > 0 })   # => false
```

## sum

`Hash.sum(x, [Integer|Float|Rational|Complex]) { }`

Calls the block for each entry and adds the results to `init` (0 when omitted). The block is required (Ruby's blockless form does not exist), and `init` must be a number (a String is a `type` problem statically; to join strings use `reduce`). A block result that is not a number is a `TypeError` at run time (`String can't be coerced into Integer`). The result type follows from `init` and the numeric type of the block results.

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.sum(h) { |k, v| v })        # => 3
p(Hash.sum(h, 0.5) { |k, v| v })   # => 3.5
p(Hash.sum(Hash[]) { |k, v| 1 })   # => 0
```

```ruby error
Hash.sum(Hash["a" => "x"], "") { |k, v| v }   # !> argument 2 must be Integer|Float|Rational|Complex, but is String
```

## reduce, inject

`Hash.reduce(x, Any) { }`

`Hash.inject(x, Any) { }`

Starting from `init`, calls the block as `|acc, (k, v)|` for each entry, feeds the result in as the next `acc`, and returns the last result. The initial value is required (Ruby's form without one does not exist). The result type is the union of the types of `init` and of the block results.

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.reduce(h, 0) { |acc, (k, v)| acc + v })    # => 3
p(Hash.inject(h, "") { |acc, (k, v)| acc + k })   # => "ab"
```

## transform_values

`Hash.transform_values(x) { }`

A new Hash whose values are the block applied to each value. The block receives only the value. The keys stay, and the original does not change. The result's value type is the block's result type, so this is the form for a conversion that changes the type (unlike the in-place `transform_values!`, it does not make a union with the old type).

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.transform_values(h) { |v| Integer.to_s(v) })   # => {"a" => "1", "b" => "2"}
p(h)                                                 # => {"a" => 1, "b" => 2}
```

## transform_keys

`Hash.transform_keys(x) { }`

A new Hash whose keys are the block applied to each key. The block receives only the key, and its result must be a value that can be a key (`TypeError`). When two keys map to the same result, the later entry's value stays. The original does not change. Ruby's Hash-argument form (`transform_keys(a: :b)`) does not exist.

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.transform_keys(h) { |k| String.to_sym(k) })   # => {a: 1, b: 2}
p(Hash.transform_keys(Hash["a" => 1, "A" => 2]) { |k| String.downcase(k) })   # => {"a" => 2}
```

## transform_values!

`Hash.transform_values!(x) { }`

Replaces each value with the block's result and returns the Hash itself. The checker gives a Hash one value type, so a conversion that changes the type (Integer to String) makes the Hash's value type the union `Integer | String`, and operations that fit only one of them are reported from then on as `type` (partial). To change the type, make a new Hash with `transform_values`.

```ruby
h = Hash["a" => 1, "b" => 2]
r = Hash.transform_values!(h) { |v| v * 10 }
p(h)                               # => {"a" => 10, "b" => 20}
p(Kernel.equal?(r, h))             # => true
```

```ruby error
h = Hash["a" => 1]
Hash.transform_values!(h) { |v| Integer.to_s(v) }   # !> argument 1 must be Integer, but can be String
```

## transform_keys!

`Hash.transform_keys!(x) { }`

Replaces each key with the block's result and returns the Hash itself. The result must be a value that can be a key (`TypeError`). As with `transform_values!`, a conversion that changes the type makes the key type a union, and an operation for one of the types, in `Array.each(Hash.keys(h))` say, is a `type` problem. To change the type use `transform_keys`.

```ruby
h = Hash["a" => 1, "b" => 2]
Hash.transform_keys!(h) { |k| String.upcase(k) }
p(h)                               # => {"A" => 1, "B" => 2}
```

```ruby error
h = Hash["a" => 1]
Hash.transform_keys!(h) { |k| String.to_sym(k) }   # !> argument 1 must be String, but can be Symbol
```

## merge

`Hash.merge(x, Hash)`

A new Hash with the entries of both; for a shared key the second argument's value wins. Neither changes. The second argument must be a Hash; passing a Record (`{a: 2}`) is a `type` problem statically. Ruby's block form (deciding the value on a conflict) does not exist. The result's key and value types are the unions of both.

```ruby
a = Hash["a" => 1, "b" => 2]
b = Hash["b" => 20, "c" => 3]
p(Hash.merge(a, b))                # => {"a" => 1, "b" => 20, "c" => 3}
p(a)                               # => {"a" => 1, "b" => 2}
```

```ruby error
p(Hash.merge(Hash["a" => 1], {a: 2}))   # !> Hash.merge: argument 2 must be Hash, but is {a: Integer}
```

## merge!, update

`Hash.merge!(x, Hash)`

`Hash.update(x, Hash)`

Writes the second argument's entries into the first Hash (overwriting shared keys) and returns the first Hash itself. The checker adds the second argument's key and value types to the first's. There is no block form.

```ruby
h = Hash["a" => 1]
Hash.merge!(h, Hash["b" => 2])
p(Hash.update(h, Hash["a" => 10])) # => {"a" => 10, "b" => 2}
p(h)                               # => {"a" => 10, "b" => 2}
```

## replace

`Hash.replace(x, Hash)`

Replaces the whole contents of the first Hash with the second's entries and returns the first Hash itself.

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.replace(h, Hash["z" => 26]))   # => {"z" => 26}
p(h)                                  # => {"z" => 26}
```

## compact

`Hash.compact(x)`

A new Hash without the entries whose value is nil. nil leaves the result's value type.

```ruby
h = Hash["a" => 1, "b" => nil]
p(Hash.compact(h))                 # => {"a" => 1}
p(h)                               # => {"a" => 1, "b" => nil}
```

## compact!

`Hash.compact!(x)`

Removes the entries whose value is nil in place and returns the Hash itself, or nil when nothing was removed (as Ruby's); using the result unchecked is reported at level 2.

```ruby
h = Hash["a" => 1, "b" => nil]
p(Hash.compact!(h))                # => {"a" => 1}
p(Hash.compact!(h))                # => nil
```

```ruby error
p(Hash.size(Hash.compact!(Hash["a" => 1])))   # !> Hash.size: argument 1 may be nil
```

## slice

`Hash.slice(x, *Any)`

A new Hash of the entries under the listed keys only. Missing keys are ignored; the order is the order listed.

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
p(Hash.slice(h, "c", "a", "zz"))   # => {"c" => 3, "a" => 1}
```

## except

`Hash.except(x, *Any)`

A new Hash without the entries under the listed keys. Missing keys are ignored.

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
p(Hash.except(h, "a", "zz"))       # => {"b" => 2, "c" => 3}
```

## invert

`Hash.invert(x)`

A new Hash with the values as keys and the keys as values. The values must be able to be keys (`TypeError`); when a value occurs more than once, the later entry stays. The result's key and value types are the original's value and key types.

```ruby
p(Hash.invert(Hash["a" => 1, "b" => 2]))        # => {1 => "a", 2 => "b"}
p(Hash.invert(Hash["a" => 1, "b" => 1]))        # => {1 => "b"}
```

```ruby error
Hash.invert(Hash["a" => /x/])      # !> TypeError: Hash.invert: Regexp cannot be a Hash key or Set element
```

## delete

`Hash.delete(x, Any)`

Removes the entry under key `k` and returns its value, or nil when there is none, which is reported at level 2 (the default is not used). Ruby's block form does not exist.

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.delete(h, "a"))             # => 1
p(Hash.delete(h, "zz"))            # => nil
p(h)                               # => {"b" => 2}
```

```ruby error
h = Hash["a" => 1]
p(Hash.delete(h, "a") + 1)         # !> the operands may be nil
```

## delete_if

`Hash.delete_if(x) { }`

Removes in place the entries for which the block returns true and returns the Hash itself (never nil, even when nothing was removed; that is the difference from `reject!`).

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
p(Hash.delete_if(h) { |k, v| v > 1 })   # => {"a" => 1}
p(Hash.delete_if(h) { |k, v| false })   # => {"a" => 1}
```

## keep_if

`Hash.keep_if(x) { }`

Keeps in place only the entries for which the block returns true and returns the Hash itself (never nil, even when nothing changed; that is the difference from `select!`).

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
p(Hash.keep_if(h) { |k, v| v > 1 })   # => {"b" => 2, "c" => 3}
```

## select!, filter!

`Hash.select!(x) { }`

`Hash.filter!(x) { }`

Keep in place only the entries for which the block returns true and return the Hash itself, or nil when nothing was removed (as Ruby's); using the result unchecked is reported at level 2. The form that always returns the Hash is `keep_if`.

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
p(Hash.select!(h) { |k, v| v > 1 })   # => {"b" => 2, "c" => 3}
p(Hash.filter!(h) { |k, v| v > 1 })   # => nil
p(h)                                  # => {"b" => 2, "c" => 3}
```

## reject!

`Hash.reject!(x) { }`

Removes in place the entries for which the block returns true and returns the Hash itself, or nil when nothing was removed (reported at level 2). The form that always returns the Hash is `delete_if`.

```ruby
h = Hash["a" => 1, "b" => 2, "c" => 3]
p(Hash.reject!(h) { |k, v| v > 2 })   # => {"a" => 1, "b" => 2}
p(Hash.reject!(h) { |k, v| v > 5 })   # => nil
```

## shift

`Hash.shift(x)`

Removes the first inserted entry and returns it as a Tuple `[k, v]`, or nil when the Hash is empty (the default is not used; reported at level 2).

```ruby
h = Hash["a" => 1, "b" => 2]
p(Hash.shift(h))                   # => ["a", 1]
p(h)                               # => {"b" => 2}
Hash.shift(h)
p(Hash.shift(h))                   # => nil
```

## clear

`Hash.clear(x)`

Removes all entries and returns the Hash itself (now empty). The default is kept.

```ruby
h = Hash["a" => 1]
p(Hash.clear(h))                   # => {}
p(Hash.empty?(h))                  # => true
```

## ==, !=

`Hash.==(x, Any)`

`Hash.!=(x, Any)`

True when the two Hashes have the same set of keys and the values under each key are `==` (`!=` is the negation). Insertion order does not matter, and neither does the default. A right operand that is not a Hash (nil, an Integer, an Array) is never equal, with the function form as with the operator: `Hash.==(h, nil)` is false. A Record `{a: 1}` and `Hash[a: 1]` differ in type and are not equal.

```ruby
a = Hash["a" => 1, "b" => 2]
p(a == Hash["b" => 2, "a" => 1])   # => true
p(a != Hash["a" => 1])             # => true
p(Hash.==(a, Hash[]))              # => false
p(Hash.==(a, nil))                 # => false
p(Hash.!=(a, 1))                   # => true
p(Hash[a: 1] == {a: 1})            # => false
```
