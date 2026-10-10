# Values and types

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
| class | `Point.new(x, y)` | record with mutable fields |

- **Truthiness.** Only `nil` and `false` are falsy. Every other value, including `0` and `""`, is truthy.
- **Error messages.** `nil`, `true`, and `false` are shown as values (`got nil`). Every other value is shown by its type name (`got Integer`).

## Showing values

Every value can be shown, in two forms:

| Form | Used by | Built-in form |
|---|---|---|
| `to_s` | `puts`, `print`, `"#{x}"`, `Array.join`, `format`'s `%s`, `:"#{x}"`, `/#{x}/` | as Ruby's `to_s`: `nil` shows as empty, Arrays and Tuples as `inspect` |
| `inspect` | `p`, `Kernel.inspect`, `format`'s `%p`, and elements inside an Array, Tuple, Hash, or Record | as Ruby's `inspect`: `#<struct Point x=1, y=2>` |

- **Your own form.** A class can define its own `to_s` and `inspect` in its body: `def to_s(p) = "(#{@x}, #{@y})"`. Each takes one required argument, the value (parameters with defaults may follow: `to_s(n, base = 10)`), and must return a String; a non-String result is a `type` problem before running, and a `TypeError` while running.
- **Which one runs.** The set of types is closed, so which `to_s` runs is known whenever the value's type is.

## Tuples, Records, and arrays

**Literals and constructors.** A literal (`[...]`, `{...}`) has no operation with a type, so its shape fixes its type at creation. A growable collection is made by an operation with a type (`Array[...]`, `T[...]`).

- **Contents are mutable.** The contents of a literal may be replaced by values of the same type, and each write is checked. Tuples are written with `t[i] = v`. Records have no write syntax yet.
- **Length is fixed.** The length is part of the type, so an empty `[]` cannot grow.
- **nil.** A position created with `nil` has the type nil. To leave room for a value, create it with a placeholder of the intended type, such as `0` or `""`.

**Tuple.** The literal `[a, b, ...]` is a Tuple.

- Its elements are read by multiple assignment, `x, y = t`. Multiple assignment also takes an Array apart (`key, value = String.split(s, "=")`). As in Ruby, missing elements are nil and extra elements are dropped; a variable that may get a missing element has the type `nil | T` from `x[k]` (the `index-nil` item, level 3). The targets may also be elements and fields: `a[i], a[j] = a[j], a[i]` swaps, `@done, @rest = Array.partition(xs) { ... }`. Their receivers and indexes are evaluated first, then the right side.
- `first, *rest = xs` puts the remaining elements in a new Array, as in Ruby (`a, *mid, z = xs` too; `x, * = xs` drops them). Only a local variable takes the rest. A splat inside `[...]` is rejected, since a Tuple's length must be known; `Array[*xs, 1]` makes an Array.
- `t[0]` reads a position and `t[0] = v` replaces it with a value of the same type.
- `Tuple.size` and `Tuple.length` give the number of elements. `Tuple.max([a, b])` is Ruby's `[a, b].max` (the length is known, so the result is never nil).

**Record.** The literal `{x: a, y: b}` is a Record.

- **Type.** The type of a Record is its set of (field, type) pairs, for example `{x: Integer, y: Integer}`. Two Records with the same set have the same type.
- **Field order.** Order does not matter: `{y: 2, x: 1}` is printed as `{x: 1, y: 2}`.
- **Not a class value.** A Record is never a value of a class, even when the fields match: classes are nominal, and Record types are structural.
- **Reading fields.** Take fields apart with a pattern, `r => {x:, y: name}`. This binds the local `x` to field `x` and the local `name` to field `y`. Listing only some of the fields is allowed. A field the Record does not have raises `KeyError`; a value that is not a Record raises `TypeError`. `Record.to_h(r)`, `Record.keys(r)`, and `Record.values(r)` exist too.
- **Restrictions.** Field names are written as labels (`x:`). An empty `{}` and `{key => value}` are static errors (a Hash is `Hash[...]`).

**Array.** `Array[a, ...]` creates an Array with no declared element type. Any value can be added to it.

**Array of T.** `T[a, ...]` creates an Array whose element type is T. T is a built-in type (`Integer`, `Float`, `Rational`, `Complex`, `String`, `Symbol`, `Tuple`) or a class.

- **Write checks.** Every write is checked: creation, `Array.push`, `Array.append`, and `Array.concat`. A mismatch raises `TypeError`. There is no implicit conversion, so an Integer cannot go into `Float[]`.
- **Static check.** If a literal argument of `T[...]` has another type, the error is reported before running. This catches `Point[1, 2]`, Ruby's spelling of `Point.new(1, 2)`.
- **Untyped results.** Arrays returned by `map`, `select`, `sort`, and similar operations have no declared element type.

Arrays are mutable and shared by reference.

**Ruby habits.** A Tuple or Record passed where an Array is expected, such as `result = []` followed by `Array.push(result, x)`, fails with a hint to write `Array[]`.

- **In-place operations that change the element type.** The checker gives a container one element type for the whole program, so after `Array.map!(xs) { |x| Integer.to_s(x) }` or `Hash.transform_keys!(h) { |k| ... }` it takes the container to hold both the old and the new type, and reports operations that fit only one of them as `type` (partial). Use the in-place forms for a mapping within one type, and `Array.map` / `Hash.transform_keys` (a new container) to change it.

## Hash and Set

- **Constructors.** `Hash[k => v, ...]` (also `Hash[name: v]`, whose keys are Symbols), `Hash[]`, and `Hash.new(default)` create a Hash. `Set[x, ...]` creates a Set. The literal `{...}` is a Record, not a Hash.
- **Keys and elements.** Hash keys and Set elements compare as Ruby's `eql?` does: by value, with the type included, so `1` and `1.0` are different keys (`Hash[1 => "a"][1.0]` is nil; `Set[1, 1.0]` has two elements), while `1 == 1.0` is true. Allowed: Integer, Float, String, Symbol, true, false, nil, Time, and Tuples, Records, Arrays, Hashes, Sets, and values of a class made of these. Not allowed (`TypeError`): Regexp, Range, and values of a class that defines its own equality (`==`, or `Comparable` with `<=>`), whose keys could disagree with that equality. As in Ruby, changing an Array, Hash, Set, or Struct value after using it as a key makes it unfindable.
- **Keys are copied.** A Tuple or Record key is copied when it is stored, so a later write to the original does not change the key.
- **Default values.** `Hash.new(default)` gives `default` for a missing key, as in Ruby, and the same object is shared, as in Ruby. The block form `Hash.new { ... }` is not available, because blocks are not values.
- **Blocks.** A block over a Hash receives `[key, value]` as one Tuple, so `|k, v|` takes it apart.
- **Order.** Iteration follows insertion order, as in Ruby.

## nil

`nil` is an ordinary value. A value that may be absent has the type `nil | T`, and there is no Option wrapper.

- **Run time.** An operation that receives `nil` where it needs T raises `TypeError ... got nil`. The interpreter then runs the static analysis, on the error path only, and adds hints naming the fields that may hold `nil` and the lines that store it.
- **Narrowing.** The static analysis narrows a **local variable** in the following places:

  | Form | Where `x` is narrowed |
  |---|---|
  | `if x` / `while x` / `x && …` | non-nil in the branch taken when `x` is truthy |
  | `x != nil` / `x == nil` | nil or non-nil in the matching branch |
  | `!x` / `unless x` | the same, with the branches swapped (`if !x … else` is non-nil in the else) |
  | `return unless x`, `next unless x`, `break unless x`, and other early exits | non-nil after the statement |
  | `String.size(x)`, or any built-in operation taking `x` as an argument | after the call, a type that the operation accepts (it checks its arguments while running) |
  | `x in T` / `x => T` / `case x in T` | the matching types ([Control flow and patterns](06-control.md)) |

  Field reads (`Node.next(n)`) are **not** narrowed, because fields are mutable. Copy the field into a local variable first, then test the local.
- **`--strict`.** Level 2 reports, before running, every operation that may receive an unchecked `nil`. Level 3 also covers results of `x[k]`.

## Ruby's other types

- **Range.** Operations that iterate need a Range that starts with an Integer or a String (`"A".."Z"` walks with `String#succ`, as Ruby's); `step`, `sum`, and `size` need an Integer. The checker reports a Range of another type (`1.0..2.0`) at `type`. Two Ranges are `==` when their ends and `exclude_end?` are; two Regexps when their source and options are. Operations that need a finite Range raise `RangeError` on an endless one.
- **Regexp and MatchData.** Globals such as `$1` and `$~` do not exist; keep the MatchData in a variable and index it (`m[1]`). `String.sub`, `gsub`, `index`, and `split` also take a Regexp. `/.../n` is a byte regexp, as in Ruby.
- **Time.** A zone is a fixed UTC offset, as Ruby's: `"+09:00"`, `"-0500"`, `"Z"`, `"UTC"`, a military letter, or seconds (`3600`). `Time.new`, `Time.at`, and `Time.now` also take it as the keyword `in:`. `Time.utc(t)` and `Time.localtime(t, zone)` give a converted copy (Ruby's `utc` and `localtime` change the receiver).
- **IO.** `IO.stdin`, `IO.stdout`, and `IO.stderr` give the program's streams as values of type `IO` (Sake has no `$stdout` or `STDOUT`; as with `ARGV`, a value comes from an operation). `File.open(path, mode = "r")` gives an `IO` too; with a block it gives the block's value and closes the file after the block. There is one type for files and streams, so one function can write to either. `IO` can be matched (`in IO`), and two IO values are `==` when they are the same stream or file.
- **Encodings.** Strings of incompatible encodings meeting (a byte from `Integer.chr(227)` next to UTF-8 text) raise `EncodingError`, which can be rescued.
