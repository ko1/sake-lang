# Sake-lang Tutorial

Sake (/seɪk/) is designed for the sake of finding a new place for types. It keeps **Ruby's
syntax**, but you write the type on each **operation**, never on a variable.

```ruby
String.upcase(s)      # Sake
s.upcase              # Ruby — an error in Sake
```

Because every operation names its type, a single line tells you which function runs, and the
interpreter can check every name before the program starts. You never write a type on a variable,
a parameter, or a return value.

This tutorial walks through the language with small programs. **Every output below was produced by
running the program** (`tools/gen_tutorial.rb` regenerates this file). The precise rules are in
[spec.md](spec.md).

Run a program with:

```
bin/sake FILE.sake
```

A program can be split into files: `require "lib/web"` at the top of a file reads `lib/web.sake`
next to it, once. The argument is a string literal, so the files are known before running, and
messages name the file of each line. `bin/sake -c FILE.sake` only checks the program. Exit status is 0 on success, 1 for an error while
running, and 2 for a problem found before running. To try Sake in a browser, with completion and the
inferred types on hover, build the playground in [ide/](../ide/README.md).

How much is checked before running is set with `--strict`:

| Level | How to ask | Also stops before running |
|---|---|---|
| 0 | `--strict=0` | only syntax, names, argument counts, calls on values, and the like |
| 1 | (the default) | **type**: a value whose type (other than nil) does not fit the operation; **rescue**: a rescue of an exception never raised |
| 2 | `--strict` | **nil**: a value that may be nil, used without a check; **mixed**: a type report where values of different types met in a field (a warning at level 1) |
| 3 | `--strict=3` | **index-nil**: the result of `x[k]`, used without a check; **exhaustive**: a `case` whose literal branches may miss some value |
| 4 | `--strict=4` | **unrescued**: a `raise` that may reach the top level |

Items can also be named: `--strict=type,nil`, or `--strict=3,-index-nil`. Whatever is not checked
before running is still checked while running, by each operation.

## 1. Hello

@@example hello

`"#{expr}"` interpolates as in Ruby. A type can define its own `to_s` (used by `puts`, `print`,
`"#{...}"`, `Array.join`, and `format`'s `%s`) and `inspect` (used by `p`); section 7 shows one.

`puts`, `print`, and `p` are the built-in functions you call without a type. They come from
`Kernel` and accept any value. Your own top-level functions are also called without a type
(section 4).

## 2. Operations carry their type

In Ruby you would write `name.upcase`. Sake rejects calls on values and tells you how to write
them with the type. Chains are rewritten as a whole:

@@example method_call

All names are checked before the program runs, so a misspelled operation or type never gets the
chance to fail halfway through:

@@example typo

Nested calls read inside out. Two forms let them read in order instead, with every step still
naming its type: `x.T.f(...)` is `T.f(x, ...)`, and `_` is the value of the previous statement:

@@example chains

Sake's standard library uses **Ruby's names** (`Integer.to_s`, `String.include?`,
`Array.each`), so the names you already know work. Names from other languages do not
(`Integer.to_string` above).

## 3. Numbers and operators

Operators work as in Ruby: `a + b` runs the `+` of `a`'s type. For the built-in types, a fixed table
gives the result for each pair of operand types. Mixing Integer and Float gives a Float.

@@example numbers

A pair that is not in the table is reported before running. The error names the operation, the
line, and the types:

@@example binop_error

Every operation also checks its arguments while running. With `--strict=0`, nothing is checked
ahead, and the same mistake stops when it runs:

@@run binop_error --strict=0

Writing the operator with a type, as in `Integer.+(a, b)`, runs Integer's `+` directly: the left
operand must be an Integer, and the right one any type that `+` takes with it:

@@example typed_op_error

`==` compares any two values: by content for Tuples, Arrays, Hashes, Sets, Records and Structs, and
`false` between different types. Tuples and Arrays are ordered element by element, so a Tuple makes a
sort key of several parts. `-x` runs the `-@` of `x`'s type, and `!x` is `x ? false : true`:

@@example comparing

## 4. Functions

Functions have no type annotations, and do not need them: what a function accepts follows from its
operations (`String.upcase(s)` needs a String), and each call is checked with the types it is given. A
function that does not pin down a type works with any type its operations accept. In the example
below, `square` works on both Integer and Float.

@@example functions

- `def f(x) = expr` is the one-line form.
- `return a, b` and the literal `[a, b]` both make a **Tuple**. `x, y = t` takes it apart.
- Parameters may have defaults, and keyword parameters come last, as in Ruby:
  `def greet(name, greeting = "Hello", punct: "!")`, called as `greet("Ruby", punct: "?")`. The callee
  of every call is known when the program is checked, so a misspelled or missing keyword is an error
  before running. `*rest` and `**opts` collect the remaining positional arguments (an Array) and the
  other keywords (a Hash). `T.new` takes fields by keyword too: `Logger.new(io, level: :warn)`.
- `first, *rest = xs` and `|a, *rest|` collect the rest in an Array. `*xs` in arguments spreads
  only into built-ins that take any number of them: `puts(*lines)`, `format(fmt, *row)`,
  `Array[*xs, 0]`.

## 5. Control flow

`if`/`elsif`/`else`, `unless`, `while`, `until`, the modifier forms, and the ternary operator all
work as in Ruby. Only `nil` and `false` are falsy.

@@example control

### Matching by type

`x in Integer` tests a value's type. `case x` with `in` branches picks the branch by type, literal,
or Record shape. Inside a matching branch, the variable has the matching type, so a value that may
be an Integer or a String can be used without a type report:

@@example patterns

`x => Integer` asserts the type (it raises `NoMatchingPatternError` otherwise); after it, `x` is an
Integer. Since types are never written on variables or fields, this is the way to state "a port is
an Integer" where the value is stored:

@@example pattern_assert

The set of types is closed, so a `case` that may match nothing is found before running:

@@example patterns_exhaustive

## 6. Blocks

Operations that take a block are called like any other operation, with the subject as the first
argument. Inside a block, you can name the single parameter `it` or `_1`, as in Ruby 3.4.

@@example blocks

Your own functions receive a block through `yield`.

- When a block has several parameters and receives one Tuple or Array, it is destructured.
- `next` gives the block's value; `break` ends the call the block was given to, whose value it becomes.
- `return` inside a block leaves the enclosing function.
- A parameter can be taken apart, `|(name, n), i|`, and `|head, *rest|` collects the rest.

@@example yield

@@example blocks_more

Blocks are not values. You cannot store a block in a variable; `&blk` only passes a function's
block on (`def f(xs, &b) = Array.map(xs, &b)`), and `block_given?` lets a function be called with or
without one. In return, the interpreter knows statically which block every `yield` runs, so it can
check block use before running:

@@example block_errors

## 7. Types and instances

A `class` declares a type with fields; its values are **instances**. The fields are declared in
the body with `attr_reader`, `attr_accessor`, and `attr_writer`, as in Ruby but with the names
written bare. The type's operations are its own functions, called with the type's name and the
instance first:

@@example instances

| In the body | Fields it declares |
|---|---|
| `attr_reader x, y` | `C.x(c)` from anywhere; written only inside `class C` (with `@x = v`) |
| `attr_accessor n` | `C.n(c)` and `C.set_n(c, v)` from anywhere |
| `attr_writer w` | `C.set_w(c, v)` from anywhere; read only inside the class |
| `def initialize(c)` | runs after `new` stored the fields: set the others there (`@items = Array[]`); with it, `new` may leave out trailing fields, which are nil until initialize sets them. Fields have no default values |
| `private attr_reader pos` | no `C.pos` outside the class (inside: `@pos`, or `C.pos(other)` for another C); `new` still takes it |
| `class E < Exception` | an exception type: `message` comes first |

Use `attr_reader` for every field that is not changed from outside, which is most of them: every
write to a field is then in its own class, where the checker finds its type. `C = Struct.new(:x, :y)`
is shorthand for a `class C` with `attr_accessor x, y`.

`def initialize(c)` runs after `C.new` has stored the fields, as in Ruby: the place to check
(`@port => Integer`) or convert (`@celsius = Float(@celsius)`). The checker runs it for each `new`
call with that call's values:

@@example initialize

`class B < A` is shorthand for writing A's definitions in B: A's fields first, A's functions as B's
(where unqualified names and `@x` mean B's), B's own definitions winning. It is not inheritance:
afterwards a B is not an A.

- **Instances.** `C.new(a, b)` takes one argument per field. Fields are **mutable**, and instances
  are **shared**, not copied: after `d = c`, a change through `d` is seen through `c`.
- **Equality.** `==` compares the fields, unless the type defines `==` (or `Comparable` with `<=>`).
- **Showing.** `p` shows `#<struct Point x=4, y=6>`, as Ruby does. A type's own `to_s(c)` is used
  by `puts` and `"#{...}"`, and its own `inspect(c)` by `p`.
- **Functions of a type.** Inside `class C`, `@x`, `@x = v`, and `@x += v` read and write field `x`
  of the function's **first argument**; there is no `self`. Unqualified names refer to C's
  operations first. `def C.f(c)` outside the class is shorthand for a `def f(c)` inside it.

The same with `Struct.new` and the reader `C.x(c)` / writer `C.set_x(c, v)` spelled out:

@@example data

`@x` refers to the first argument, whatever it is; passing something else is reported:

@@example data_shorthand

There is no `p.x`, a read-only field is not written from outside, a field that does not exist is
not read, and `new` takes every field:

@@example instance_errors

Passing the wrong instance is reported before running. The error is inside `length`, and the hint
points back to the call that passes a Point. While running, the same check stops at the exact
operation and prints the call chain:

@@example data_runtime_error
@@run data_runtime_error --strict=0

## 8. Modules

A `module` is a namespace of functions with no type and no instances. It is used in two ways: as a
home for plain functions (`module_function`), and as a **mixin** that types include.

| | `class C` | `module M` |
|---|---|---|
| Is a type | Yes: `C.new`, fields, `x in C` | No |
| Functions | C's operations, instance first | module functions, or mixin functions for the types that include M |
| Called as | `C.f(c)` | `M.f(x)`: directly (`module_function`), or dispatched to `x`'s type |
| Combined by | `include M` (no inheritance) | `include` of other modules |

@@example class_module

- **Module functions.** Functions after `module_function` are called directly, as
  `Geometry.dist2(...)`, like Ruby's `Math`.
- **Mixins.** `include M` borrows M's functions, as Ruby's modules do, but statically. Inside a
  borrowed function, unqualified names are looked up in the class that includes it, so
  `Shape.describe` uses the `area` of Square or of Disc.
- **Dispatch.** Calling a mixin function through its module, as `Shape.describe(x)`, runs the
  function of `x`'s type, which must include the module. This is the one place besides operators
  where the function is picked while running, and the module name says so.

@@example modules

A module states what each includer must define with a function whose body is only
`raise NotImplementedError`. A missing definition, a `class` that is not a type, and a direct call
to a function that needs its includer are reported before running:

@@example required_errors
@@example module_errors

### Operators for your own types

An operator belongs to a module: `Arithmetic` (`+ - * / % **`, unary `-` and `+`), `Comparable`
(`<=>` and `< <= > >=`), `Bitwise`, and `Indexable` (`[]`, `[]=`). A type joins by including the
module and defining the operator. With `Comparable`, `<=>` alone gives the comparisons, `==`, and
`Array.sort`:

@@example operators

### Listing the types on the operation

When a value may be one of a few types that have an operation of the same name, list them on the
operation: `(A|B).f(x)` runs the `f` of `x`'s type. The list is checked before running:

@@example union_call

Without the check before running, the same value stops at the call:

@@run union_call --strict=0

### Unqualified names

An unqualified call is resolved statically, from the inside out:

1. the enclosing class or module (and what it includes)
2. the top-level functions
3. `Kernel`

The inner definition wins, so common names such as `open` stay usable. To reach an outer
definition, write its namespace, as in `Kernel.puts(...)`.

@@example scope

## 9. Tuples, Records, and arrays

A literal has no operation with a type, so its shape fixes its type when it is created. A growable
collection is made by an operation with a type:

- **Tuple.** A literal `[a, b]` is a Tuple of fixed size. Take it apart with multiple assignment
  (`a, b = t`; an Array too, where missing elements are nil, as in Ruby).
- **Record.** A literal `{x: a, y: b}` is a Record. Its type is its set of fields and their
  types. Take it apart with a pattern.
- **Array.** `Array[...]` builds an Array with no declared element type.
- **Typed Array.** `T[...]` builds an Array whose element type is T. The element type is checked
  on every write.

@@example collections

A Record is read with a pattern. `r => {mean:, count: n}` binds `mean` and `n`:

@@example records

In Sake, `[]` and `{}` are not growable collections. Ruby code that grows them stops with a hint:

@@example ruby_habits
@@example empty_braces

`x[k]` runs the `[]` of `x`'s type, and `x[k] = v` its `[]=`. Array, Hash, String, Tuple, and
MatchData have them.

- **A miss gives `nil`**, as in Ruby. `Array.fetch` raises an error instead.
- **Tuples.** A Tuple's length is part of its type, so reading outside it is an error.
- **Writing a Tuple position** requires a value of that position's type.

@@example indexing

`Point[1, 2]` means "an Array of Point". It does **not** mean `Point.new(1, 2)` as it does in Ruby.
When the mistake is visible in the source, it is reported before running:

@@example typed_array_errors

More on Arrays: `Array.new(n, v)` and `Array.new(n) { |i| ... }`, `+ - *` as in Ruby, element
assignment as a multiple-assignment target (a swap), two indexes `s[start, length]`, and a start
value for `sum`, which an empty Array gives instead of the Integer 0:

@@example arrays_more

### Tuples tagged by a Symbol

An Array of Tuples whose first element is a Symbol tag keeps each kind apart. Testing the tag, after
`|kind, arg|` takes a Tuple apart (or with `case t[0]`), tells the type of the rest:

@@example tagged

### Where a type is worth writing

A function needs no type: its operations say what it accepts. A Struct's field needs none either:
its type comes from the values written to it, which `T.new` and `T.set_x` show. The one place a type
pays is an Array that is filled later. Made with `Array[]`, its element type is whatever gets pushed,
so a wrong value is reported where the elements are used, far from where it went in:

@@example elements_untyped

Made with its element type, `Integer[]` (or `Float[]`, `Point[]`, `Tuple[]`), every push is checked
where it happens. The type is written on the operation that makes the Array, not on a variable:

@@example elements_typed

## 10. Ruby's other types

Hash, Set, Symbol, Range, and Regexp work as in Ruby. Their operations carry the type like
everything else (`Hash.each`, `Range.to_a`, `String.match`), while `h[k]`, `1..5`, `:name`, and
`/re/` are written as in Ruby.

- `Hash[k => v]` and `Hash.new(0)` make a Hash, because `{...}` is a Record.
- A missing key gives `nil`, or the default given to `Hash.new`.
- A block over a Hash receives `[key, value]`, which `|k, v|` takes apart.

@@example ruby_types

Hash keys and Set elements compare as `==` does: numbers, Strings, Symbols, `true`, `false`, `nil`,
Time, and Tuples, Records, Arrays, Hashes, Sets and Struct values made of these. A Struct type that
defines its own `==` (or `<=>` with `Comparable`) cannot be a key, since its keys could disagree with
it.

## 11. nil

A value that may be absent is simply `nil`. Check it with `if x`, `while x`, `x != nil`, or
`return unless x`. When a `nil` reaches an operation that needs something else, the error says
where that `nil` can come from:

@@example nil

By default (level 1), a value that might be `nil` is checked when it runs. `--strict` (level 2)
reports every unchecked use before running. A local variable you have tested counts as checked
(`second_checked`). A field you read again does not, because fields are mutable:

@@example strict
@@run strict --strict

## 12. Exceptions

`raise`, `rescue`, `else`, `ensure`, and `retry` work as in Ruby. An exception type is declared with
`Exception.new`: it is a Struct type whose first field is `message`. There is no hierarchy, so a
`rescue` lists the types it catches.

@@example exceptions

The checker tracks which exceptions each function may raise. By default it reports a `rescue`
that can never match. Level 4 also reports a `raise` that nothing rescues:

@@run exceptions_flow --strict=4

## 13. What Sake rejects

Sake rejects anything that would hide which code runs, or that it has not decided yet:

- `self`, and `@x` outside a function of a Struct type
- `eval`, `send`, and similar

All of these are reported together, before running:

@@example forbidden

For a named value such as `PI`, define a function (`def pi = 3.14159`).

## 14. Looking at the types (experimental)

`--types` runs a whole-program type inference without running the program. It reports, for every
operation that checks its argument, one of the following:

- **proven**: the check always passes.
- **partial**: the value's type is a union, so the check is still needed at run time.
- **error**: the check always fails.
- **unknown**: the inference could not tell.

It also prints the element type of every Array and the type of every field. No types were written
anywhere. The playground ([ide/](../ide/README.md)) shows the same results in its Types tab and on
hover:

@@example types
@@run types --types

In the `strict` program from section 11, the inference finds the one unchecked use:

@@run strict --types

## 15. Putting it together

A bank account with a transaction history. Its fields are read-only from outside (`reader:`); the
functions in its class change them through `@balance` and `@history`. The history is made with
`Tuple[]` and holds `[kind, amount]` Tuples tagged by a Symbol, which a `do |kind, amount|` block
takes apart.

@@example bank

## Next

- [spec.md](spec.md): the full rules and the complete list of built-in operations.
- [../DESIGN.md](../DESIGN.md): the design notes behind the decisions (in Japanese).
