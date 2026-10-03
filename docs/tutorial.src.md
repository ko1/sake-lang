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

`bin/sake -c FILE.sake` only checks the program. Exit status is 0 on success, 1 for an error while
running, and 2 for a problem found before running. To try Sake in a browser, with completion and the
inferred types on hover, build the playground in [ide/](../ide/README.md).

How much is checked before running is set with `--strict`:

| Level | How to ask | Also stops before running |
|---|---|---|
| 0 | `--strict=0` | only syntax, names, argument counts, calls on values, and the like |
| 1 | (the default) | **type**: a value whose type (other than nil) does not fit the operation; **rescue**: a rescue of an exception never raised |
| 2 | `--strict` | **nil**: a value that may be nil, used without a check |
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
- Only required positional parameters are supported. Default values, keyword arguments, and
  rest parameters are not.
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

Blocks are not values. You cannot store a block in a variable or pass `&blk`. In return, the
interpreter knows statically which block every `yield` runs, so it can check block use before
running:

@@example block_errors

## 7. Struct types

`Struct.new` creates a named type together with its operations. Ruby's `Data.define` is not used: Ruby's
`Data` is immutable, while Sake's named types are mutable, like Ruby's `Struct`.

`Struct.new` gives the type these operations: `Point.new`, a `get_` operation
for each field, and a `set_` operation for each field. Fields are **mutable**.

To add your own operations to a type, put them inside `class Point`. Inside that body, unqualified
names such as `get_x` refer to `Point`'s operations. `def Point.f` is shorthand for a `def f`
inside `class Point`.

@@example data

A type can also be declared with its settings after `<`:

- `reader:`, `writer:`, and `accessor:` choose which fields have `get_` and `set_` outside the
  class.
- `default:` gives default values, which also fix the type of a field.
- `exception: true` makes an exception type.

Writing `Account.set_owner(a, "eve")` outside the class would be a static error, because `owner` is
read-only there.

Prefer this form, with `reader:` for every field that is not changed from outside: most fields are
never changed after `new`, and with `reader:` every write to a field is in its own class, where the
checker finds its type. List a field under `accessor:` only when code outside the class must change
it. `Struct.new(:x, :y)` is shorthand for `accessor:` on every field.

@@example class_settings

There is no `p.x`. Field access is an operation with a type, like everything else:

@@example data_errors

Inside a function of a Struct type, `@x` is shorthand for field `x` of the function's **first
argument**, which is the subject by convention. `@x` reads the field, `@x = v` writes it, and
`@x += v` updates it. The type comes from the enclosing `class Point`, so `@x` is still an
operation with a type:

@@example data_shorthand

Passing the wrong record is reported before running. The error is inside `length`, and the hint
points back to the call that passes a Point:

@@example data_runtime_error

While running, the same check stops at the exact operation and prints the call chain:

@@run data_runtime_error --strict=0

## 8. Where unqualified names go

An unqualified call is resolved statically, from the inside out:

1. the enclosing class or module
2. the top-level functions
3. `Kernel`

The inner definition wins, so common names such as `open` stay usable. To reach an outer
definition, write its namespace, as in `Kernel.puts(...)`.

@@example scope

### Operators for your own types

An operator belongs to a module: `Arithmetic` (`+ - * / % **`), `Comparable` (`<=>` and
`< <= > >=`), `Bitwise`, and `Indexable` (`[]`, `[]=`). A type joins by including the module and
defining the operator. With `Comparable`, `<=>` alone gives the comparisons and makes `Array.sort`
work:

@@example operators

### Listing the types on the operation

When a value may be one of a few types that have an operation of the same name, list them on the
operation: `(A|B).f(x)` runs the `f` of `x`'s type. The list is checked before running:

@@example union_call

Without the check before running, the same value stops at the call:

@@run union_call --strict=0

### Sharing functions with `include`

`class` adds operations to a type, and `module` is a namespace with no type.

`include M` borrows `M`'s functions, as Ruby's modules do, but statically. Inside a borrowed
function, unqualified names are looked up in the namespace that includes it. So `Summary` below
can use the `each` that `Basket` or `Countdown` provides.

There are two ways to call a module's functions:

- **Module functions.** Functions after `module_function` are called directly, as `Units.km(x)`.
- **Mixin functions.** Calling any other function through the module, as `Summary.total(x)`,
  **dispatches**: it runs the `total` of `x`'s type, which must include `Summary`. This is the one
  place besides operators where the function is picked while running, and the module name says
  so.

@@example modules

A missing requirement is found before running. So are a `class` that is not a type, and a direct
call to a function that needs its includer:

@@example module_errors

A module states what each includer must define with a function whose body is only
`raise NotImplementedError`. A type that includes the module but lacks it is reported where the
function is reached:

@@example required_errors

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
