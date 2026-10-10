# Sake-lang Specification (v0)

Sake (/seɪk/) is designed for the sake of finding a new place for types. It keeps Ruby's syntax,
but you write the type on each operation, never on a variable.

This document describes the language as implemented by the v0 interpreter (`bin/sake`). Sake is
experimental. Points still open in the design are listed in [§16](#16-not-yet-supported) and in
[../DESIGN.md](../DESIGN.md) (in Japanese). For a guided introduction, see [tutorial.md](tutorial.md).

## 1. Principles

1. **Ruby syntax.** A Sake program is a Ruby program as parsed by Prism. Sake accepts a subset of
   Ruby's syntax and gives some constructs a different meaning.
2. **Types are written on operations, not on bindings.** An operation is called with its type,
   `Type.op(subject, args...)`. Variables, parameters, return values, and fields carry no type
   annotations.
3. **Every call target is known before running.** There is no dispatch on the receiver, no
   `method_missing`, and no reflection. Name errors are reported for the whole program before
   execution starts.
4. **Values carry type tags, and every operation checks them.** A wrong type is reported as an
   error at the operation that received it, with the line number. These checks are always
   enabled.

## 2. Running programs

```
bin/sake FILE.sake              # check, then run
bin/sake -c FILE.sake           # check only
bin/sake --strict FILE.sake     # check more strictly (level 2), then run
bin/sake --types FILE.sake      # experimental: print the inferred types instead of running
```

| Exit status | Meaning |
|---|---|
| 0 | success |
| 1 | runtime error |
| 2 | problem found before running (nothing was executed) |

### 2.1 Strictness

`--strict` sets which problems stop the program before it runs. Each item is reported from the
whole-program type inference; whatever is not reported is still checked while running.

| Level | Option | Items | Stops before running |
|---|---|---|---|
| 0 | `--strict=0` | (none) | syntax, names, argument counts, blocks, calls on values, forbidden syntax, literal types in `T[...]` (always checked) |
| 1 | default | `type`, `rescue` | a value whose type, other than nil, does not fit (`"" + 1`, or `pick() + 1` where `pick` returns 1 or ""); a `rescue` of an exception the begin body never raises |
| 2 | `--strict` | `type`, `rescue`, `nil`, `mixed` | also a value that may be nil, used without a check (except the nil of a miss: `x[k]`, `Array.dig`, `Hash.dig`, `MatchData.begin`/`end`, and `Array.first`, `last`, `pop`, `shift`, `min`, `max`, `minmax`, `at`, `slice`, `sample`, `delete_at`, `Set.first`, `min`, `max`, `min_by`, `max_by` on an empty collection); and a `mixed` report (below) |
| 3 | `--strict=3` | `type`, `rescue`, `nil`, `mixed`, `index-nil`, `exhaustive` | also the nil of a miss (`x[k]`, `Array.first` and the others above), used without a check; a `case`/`in` that may get a value of an open type (String, Integer, a Symbol not written as a literal, ...) that no literal branch takes |
| 4 | `--strict=4` | all of the above, `unrescued` | also a `raise` that may reach the top level without being rescued (for a program; a library's raises are meant for its callers) |

- **`mixed`.** A type report whose failing types all appear, together with fitting ones, in one field
  (or in the elements of a container held in a field) of a Struct type. The typer gives a field one type
  for all instances, so instances of one type used for different values (an Integer heap and a Job heap
  sharing `Heap.items`) meet there; the report is likely such a meeting rather than a mistake. It stops
  the program from level 2; at level 1 it is printed as a warning. The cost of the heuristic: a field
  that really got a wrong type (`Config.new("h", "eighty")` for an Integer port) is also `mixed`; check
  such a value where it is stored, in `initialize` (`@port => Integer`).
- **Naming items.** `--strict=type,nil` selects exactly these items. `--strict=2,index-nil` adds an
  item to a level, and `--strict=3,-index-nil` removes one.
- **Labels.** Each report ends with its item, such as `[type]`.
- **Errors inside functions.** A report inside a polymorphic function adds a hint naming the call
  that led there.
- **Unreached branches.** Branches are not evaluated, so a problem in a branch that never runs is
  still reported, as in Erlang's Dialyzer.
- **Internal errors.** If the type inference itself fails, the type checks are skipped with a
  warning, and the program runs.
- **Too many element pairs.** Comparing Arrays or Tuples (`<`, `<=>`, sorting) checks that each pair
  of element types can be compared. When the element types of one comparison make more than 50,000
  pairs, that comparison's elements are not checked, with a warning at the comparison; the other
  checks are unaffected.

## 3. Program structure

A program is a file and the files it requires. Its top level may contain:

- **`require "path"`**: reads `path.sake` (the extension may be left out), relative to the
  directory of the file that requires it. The argument must be a **string literal**, and `require`
  must be a statement at the **top level** of a file: the files of a program are decided before
  running. Each file is read once, whatever requires it, and a cycle stops at a file already read.
  A required file's top-level statements run before those of the file that requires it (all
  `require`s of a file are read first). Definitions of every file are collected together, so names
  may be used across files in any order; defining a name in two files is an error, as in one file.
  Messages name the file of each line (`lib/units.sake:4`, `from lib/broken.sake:3`).

- **Function definitions**: `def name(params) ... end` and `def name(params) = expr`.
- **Namespaced function definitions**: `def Type.name(params) ...`. This is equivalent to defining
  `name` inside `class Type`.
- **Namespaces**: `class Name ... end` and `module Name ... end`. Their bodies may contain only
  `def name(...)` (no receiver), `include Module`, and in a class `attr_reader`/`attr_accessor`/
  `attr_writer` lines (§10.1).
  - `class` declares a **type** (a Struct type) or adds operations to one, or to a built-in type
    such as `String`.
  - `module` is a namespace with **no type**; `module` on a type is a static error with a hint.
- **Struct types**: `class Name` with `attr_*` lines, or `Name = Struct.new(:field, ...)`.
- **Statements**: any other expression. Statements run in order.

All definitions are collected before anything runs. A function may be called on a line above its
definition.

Rules:

- Namespaces cannot be nested (`A::B` is rejected).
- Classes do not inherit. `class B < A` is shorthand for writing A's definitions in B (§10.1);
  afterwards A and B are unrelated types, and `A.f` takes only A's.
- `def self.x` is rejected, because Sake has no `self`.
- Defining the same name twice in one namespace is an error. Redefining a built-in operation is
  also an error.
- Constants can only be assigned from `Struct.new`. Sake has **no value constants**. For a named
  value, define a function (`def pi = 3.14159`) and call it (`pi`). `PI = 3.14` is a static error
  whose hint gives that function, and each use of `PI` gets the hint `pi`.

## 4. Values and types

| Type | Literals / constructors | Notes |
|---|---|---|
| Integer | `42`, `-7` | arbitrary precision |
| Float | `1.5`, `2.0` | |
| String | `"abc"`, `'abc'`, `"a#{x}"` | interpolation uses `to_s` ([§4.1](#41-showing-values)) |
| true / false | `true`, `false` | internally one type, `Boolean`, which cannot be written in source |
| nil | `nil` | see [§11](#11-nil) |
| Tuple | `[a, b, ...]` | length and positional types fixed at creation |
| Record | `{x: a, y: b}` | set of (field, type) pairs fixed at creation |
| Array | `Array[a, ...]` | no declared element type |
| Array of T | `T[a, ...]`, e.g. `Float[]`, `Point[p]` | element type T, checked on every write |
| Hash | `Hash["a" => 1, b: 2]`, `Hash.new(0)` | keys compare as `==` ([§12.1](#121-hash-and-set)) |
| Set | `Set[1, 2]` | elements compare as `==` |
| Symbol | `:name` | |
| Range | `1..5`, `1...5`, `1..` | ends are Integer, Float, String, or nil |
| Regexp, MatchData | `/(\d+)-(\d+)/`, `/#{x}/`, `String.match(s, re)` | |
| Rational, Complex | `2r`, `1/3r`, `Rational(1, 3)`, `2i`, `Complex(1, 2)` | Ruby's numeric tower |
| Time | `Time.now`, `Time.at(0)`, `Time.new(2026, 10, 1)` | |
| Struct type | `Point.new(x, y)` | record with mutable fields |

- **Truthiness.** Only `nil` and `false` are falsy. Every other value, including `0` and `""`, is
  truthy.
- **Error messages.** `nil`, `true`, and `false` are shown as values (`got nil`). Every other value
  is shown by its type name (`got Integer`).

### 4.1 Showing values

Every value can be shown, in two forms:

| Form | Used by | Built-in form |
|---|---|---|
| `to_s` | `puts`, `print`, `"#{x}"`, `Array.join`, `format`'s `%s`, `:"#{x}"`, `/#{x}/` | as Ruby's `to_s`: `nil` shows as empty, Arrays and Tuples as `inspect` |
| `inspect` | `p`, `Kernel.inspect`, `format`'s `%p`, and elements inside an Array, Tuple, Hash, or Record | as Ruby's `inspect`: `#<struct Point x=1, y=2>` |

- **Your own form.** A Struct type can define its own `to_s` and `inspect` in its class:
  `def to_s(p) = "(#{@x}, #{@y})"`. Each takes exactly one argument and must return a String;
  a non-String result is a `type` problem before running, and a `TypeError` while running.
- **Which one runs.** The set of types is closed, so which `to_s` runs is known whenever the
  value's type is.

## 5. Operations and name resolution

### 5.1 Qualified calls

`Type.op(args...)` calls the operation `op` of namespace `Type`. By convention the subject is the
first argument. Both `Type` and `op` must exist, or the program is rejected before running. When
they do not exist, the error offers spelling suggestions and lists other namespaces that define
`op`.

### 5.2 Chains and `_`

Two forms let a sequence of operations read from left to right, top to bottom, with every step
still naming its type:

- **Chain.** `x.T.f(args...)` is `T.f(x, args...)`: the step `.T` names a type or module, and the
  value to its left becomes the first argument. Steps can follow one another, also with the dot at
  the start of the next line. `x.T` with no operation after it is a static error.

  ```ruby
  String.split(line, ",")
    .Array.map { |s| String.strip(s) }
    .Array.join("|")
  ```

- **`_`** is the value of the previous statement in the same body (a function, a block, a
  branch, or the top level). Reading `_` in the first statement of a body, or right after a
  definition, is a static error. In parentheses and in string interpolation, the first statement
  reads the `_` of the enclosing statement. `_` may still be bound as a name to ignore (`|_, v|`,
  `a, _ = t`), but a `_` that names a local variable cannot be read.

  ```ruby
  String.split(line, ",")
  Array.map(_) { |s| String.strip(s) }
  Array.join(_, "|")
  ```

### 5.3 No calls on values

A call with a lowercase receiver, such as `x.op(...)`, `"lit".op`, or `3.times`, is a static error.
The error suggests the qualified form, and for a single step also the chain form (`x.T.op(...)`).

- **Chains** are rewritten as a whole: `s.strip.upcase` suggests `String.upcase(String.strip(s))`.
- **Field access** gets the reader: `p.x` suggests `Point.x(p)` (or `p.Point.x`), and `p.x = v`
  suggests `p.Point.x = v`.
- **Literal receivers** narrow the suggestions to the literal's type.
- **`x.nil?`** suggests `x == nil`.

### 5.4 Unqualified calls

A call without a receiver, `f(args)`, is resolved statically. The first match wins:

1. the enclosing class or module, including its built-in operations, Struct accessors, and the
   functions it includes ([§5.5](#55-include));
2. top-level functions;
3. `Kernel` (`puts`, `print`, `p`).

An inner definition **shadows** an outer one. It is not an error for the same name to exist at
several levels. An outer definition can always be reached with its namespace (`Kernel.puts`).

Code at the top level has no enclosing namespace, so resolution starts at step 2.

### 5.5 include

`include M` in a class or module body borrows the functions of the module `M`. This is Ruby's
module, resolved statically:

- **Borrowing.** Each function `f` of `M` becomes `X.f` in the including namespace `X`, unless `X`
  already has `f`, in which case `X`'s own definition wins. Modules included by `M` are borrowed
  too.
- **Order.** Modules are searched in Ruby's ancestor order: the module included **last** comes
  first. With `include A` then `include B`, a `bar` in both comes from B, as in Ruby.
- **Resolution in the includer.** Inside a borrowed function, unqualified names are resolved in
  `X`, so `M` can use functions that `X` provides, such as `each`. Nothing is dispatched at run
  time: each `X.f` is fixed before running. `@x` refers to a field of `X` when `X` is a Struct
  type.
- **Requirements.** If `X` lacks a name that `M`'s functions need, `include M` is a static error.
  Calling such a function directly, as in `M.total(x)`, is a static error too, with a hint to call
  it through an includer.
- **Restrictions.** Only modules can be included, and include cycles are errors.
- **Not inheritance.** `include` adds no subtype relation.

### 5.6 Calling a module's functions: module_function and dispatch

A name in a type or module is one function: Sake has no `def self.f` next to `def f`, because the
"instance" form only means that the value comes first (`T.f(x, ...)`). Where Ruby has both a class
method and an instance method of one name (`Net::HTTP.get(uri)` and `http.get(path)`), one of them
takes another name, or one function tells the forms apart by the type of its first argument.

A module's functions are of two kinds, as in Ruby:

| Kind | How it is declared | `M.f(args)` |
|---|---|---|
| module function | after `module_function`, by `module_function :f`, or with `def M.f` | runs `M`'s own `f` (static) |
| mixin function | any other function of a module | **dispatches**: runs the `f` of the first argument's type, which must include `M` |

- **No subject.** A mixin function cannot be called without arguments (`M.foo`), because there
  is nothing to dispatch on. Calling one when no type includes `M` is also a static error, with a
  hint to use `module_function`.
- **Type check.** The type inference checks that the first argument's possible types all include
  `M`, and reports one that does not as a `type` problem. While running, a type that does not
  include `M` raises `TypeError`.
- **Static calls.** A type's own namespace is always static: `Basket.total(b)` runs Basket's
  `total`, whether defined in Basket or borrowed from `Summary`. `Summary.total(x)` is the
  dispatching form.
- **Kernel.** Every type includes `Kernel`. `Kernel.to_s(x)` and `Kernel.inspect(x)` dispatch to a
  type's own `to_s` and `inspect`, or use the built-in form. `"#{x}"`, `puts`, and `p` are
  shorthands for them.

**Required functions.** A module function whose body is only `raise NotImplementedError` (with or
without a message) is required: each type that includes the module defines it, and `M.f(x)`
dispatches to that definition. Whether it takes a block comes from the types' definitions. A type
that includes the module without defining it is a `type` problem wherever a call can reach it, and
`NotImplementedError` while running. `NotImplementedError` is a program error and cannot be rescued.
(`raise T` with an exception type and no message gives the type's name as the message.)

### 5.7 Listing the types: `(A|B).f(x)`

`(A|B).f(x, args...)` lists, on the operation itself, the types that `x` may have. While running, the
type of `x` picks `A.f` or `B.f`; any other type raises `TypeError`. Before running, every listed
type must have `f` (a static error otherwise), and the checker reports a value of `x` whose type is
not listed. The result is the union of the results.

```ruby
def weight(t) = (Leaf|Node).weight(t)   # a field of the same name in two Struct types
def size_of(x) = (String|Array|Hash).size(x)
```

- The list names types: built-in types (`IO` among them), and Struct types, each at most once.
  `nil` cannot be listed; check for nil first.
- The listed functions may differ in shape: a user function's `*rest` is packed for its branch
  (`(IO|StringIO).print(io, a, b)`). A function that takes keywords cannot be listed; dispatch on
  the type with `case`.
- Unlike a module's dispatch ([§5.6](#56-calling-a-modules-functions-module_function-and-dispatch)),
  nothing has to be declared: the call site states the set, and it covers types that share an
  operation's name without sharing a module, such as built-in types or same-named fields.

### 5.8 Arity and blocks

The following are checked statically:

- the number of arguments, for both user functions and built-in operations;
- for a user function, a block must be passed **iff** the function contains `yield` (or takes `&b`),
  except that a function that checks `block_given?` may be called without one;
- a built-in operation either requires a block or rejects one.

**Splat arguments.** `*xs` spreads a Tuple or an Array (anything else raises `TypeError`), but only
into a rest parameter: a built-in's (`puts(*lines)`, `format(fmt, *row)`, `Array[*xs, 0]`,
`Set[*xs]`, `Array.push(a, *xs)`) or a user function's `*rest` (`join(*parts)`, §6). The arguments
before it are written out, so their count is still checked. A splat into a function without
`*rest`, or one that would fill a required or optional parameter, is a static error, as are splats
into `Array.zip`/`Range.zip` (their Tuples are as long as the argument list) and `Hash[...]`. In the typer, a Tuple spreads position by position; an Array stands for any number of
arguments of its element types.

## 6. Functions

```ruby
def area(w, h) = w * h
def describe(n)
  return "negative" if n < 0
  Integer.to_s(n)
end
```

- **Parameters.** Required positional parameters, then optional ones with a default
  (`def f(a, b = 1, c = b + 1)`), as in Ruby: a default is evaluated at the call, after the earlier
  parameters, when the call gives fewer arguments. Keyword parameters come last, required (`w:`) or
  with a default (`h: w`), and mix freely with optional positional ones:
  `def greet(name, greeting = "Hello", punct: "!")` is called as `greet("Ruby", punct: "?")`. Since
  every call's callee is known before running, `k: v` goes to its parameter by name when the program
  is checked: an unknown or repeated keyword, or a missing required one, is an error, and `k: v` to a
  function without keyword parameters is an error (there is no implicit Hash argument; write
  `Hash[k: v]` or a Record `{k: v}`). A few built-ins take Ruby's keywords too, checked the same way
  (`Time.at(t, in: "+09:00")`, `Dir.glob(pat, base: dir)`; builtins.md lists them as `[k: T]`).
  `f(k:)` passes the variable `k`, as in Ruby. Arguments are
  evaluated in the order written. A block parameter `&b` (or `&`) may only be passed on (§7).
  `*rest` after the optional parameters collects the remaining positional arguments in a new Array
  (so its elements share one type, the union of everything any call passes; to keep a type per
  position, pass a Tuple: `notify(stock, ["AAPL", 120])`, then `name, price = event`),
  and `**opts` at the end the keywords that are not parameters in a Hash of Symbol keys; both are
  built at the call, since the callee is known (a function with `**opts` accepts any keyword, so a
  misspelled one is no longer an error there). Parameters after `*rest` and nameless `*` / `**` are
  rejected. A call gives between the required positional count and all of them (any number with
  `*rest`); a mixin function's definitions must agree on the counts, the keyword names, and on having
  `*rest` / `**opts`.
- **Return value.** The value of the last expression, or of `return expr`. `return a, b` returns
  the Tuple `[a, b]`.
- **Polymorphism.** Functions are polymorphic. A function works on any arguments its operations
  accept. Type errors surface at the operation that fails.
- **Local variables.** Each function has its own scope, with no access to top-level locals. As in
  Ruby, reading a local before its first assignment gives `nil`.
- **Recursion.** Allowed. A depth over 10,000 calls raises `SystemStackError`. `bin/sake` runs the
  program on a thread with a large stack so that this limit, not Ruby's stack, applies. Long
  backtraces are shortened.

## 7. Blocks

A block can be passed to a built-in operation or to a user function that yields.

```ruby
Array.map(xs) { |x| x * 2 }
Array.each(pairs) do |k, v| ... end
Integer.times(3) { p it }
```

- **Not values.** Blocks are second-class. They cannot be stored or returned. `proc`, `lambda`, and
  `->` are not available.
- **Passing on.** `def f(xs, &b) = Array.map(xs, &b)` passes the function's own block to another
  call (`&` alone works too). `b` is used only as `&b`; a `break` in the block ends the call the
  block was written for. As in Ruby, a function that only passes its block on may be called without
  one; passing none to a call that needs a block is then an error at the `type` level.
- **Optional blocks.** `block_given?` tells whether the current function got a block. A function
  that checks it may be called without one: `def info(msg = nil) = puts(block_given? ? yield : msg)`.
  The checker knows for each call whether a block was given, so it analyzes only the branch taken;
  a `yield` (or `&b` to a call that needs a block) reached without a block is an error at the
  `type` level, and raises `LocalJumpError` (not rescuable) when it runs.
- **Parameters.** `|a, b|` lists plain names. `it` and `_1` … `_9` work as in Ruby.
- **Destructuring.** If a block declares two or more parameters and receives a single Tuple or
  Array, its elements become the parameters (missing ones are nil, extra ones are dropped, as in Ruby).
  A parameter can also be taken apart itself: `|(name, n), i|`, `|acc, (k, v)|`.
- **Rest parameter.** `|a, *rest|` (and `|a, *rest, z|`, `|*all|`) collects the remaining arguments,
  or the remaining elements of a destructured Tuple or Array, in a new Array, as `a, *rest = x` does.
  `|*all|` alone does not destructure.
- **Parameter count.** A block with no parameters ignores its arguments. Otherwise, a block called
  with the wrong number of arguments (fewer than its other parameters, with a rest parameter) raises
  `ArgumentError`.
- **Scope.** A block sees and can assign the enclosing local variables.
- **`next [v]`.** Ends the current block call with value `v` (default `nil`).
- **`return`.** Inside a block, `return` returns from the enclosing **function**, as in Ruby.
- **`break`.** Inside a block, `break` (or `break v`) ends the call the block was given to, whose
  value is then `v` (or nil), as in Ruby: `Array.each(xs) { |x| break x if x > 10 }`. Inside a
  `while` in the block, `break` leaves the `while`. The checker adds the break values to the call's
  result type.

`yield(args...)` calls the block given to the current function. It is a static error outside a
function.

## 8. Operators

### 8.1 Binary operators

An operator dispatches on the type of its **left operand**: `a OP b` runs `T.OP(a, b)`, where `T` is
the type of `a`. Each operator belongs to a module, and `a OP b` is shorthand for calling the
operator through that module ([§5.6](#56-calling-a-modules-functions-module_function-and-dispatch)):

| Module | Operators | Built-in types that include it |
|---|---|---|
| `Arithmetic` | `+ - * / % **`, unary `-x` `+x` (`-@` `+@`) | Integer, Float, Rational, Complex, String, Time, Set |
| `Comparable` | `<=> < <= > >=` | Integer, Float, Rational, String, Time, Tuple, Array |
| `Bitwise` | `& \| ^ << >>`, unary `~x` | Integer, Set |
| `Indexable` | `[]`, `[]=` ([§8.2](#82-indexing)) | Array, Hash, String, Tuple, MatchData |
| `Kernel` | `== != =~ !~` | every type |

- **Your own types.** A Struct type joins an operator by including the module and defining the
  operator in its class, such as `include Arithmetic` with `def +(a, b)`. With `include Comparable`,
  defining `<=>` is enough: `<`, `<=`, `>`, and `>=` come from it, and `Array.sort`, `min`, and `max`
  use it too.
- **A built-in on the left.** `2 + money` dispatches on Integer, which has no row for Money. A
  Struct type that defines `coerce(b, a)`, giving a Tuple `[left, right]` as Ruby's protocol does,
  has the pair converted first and the operator run on it: `def coerce(m, other) = [Money.new(other * 100), m]`
  makes `2 + money` into `Money.new(200) + money`. The checker follows the conversion.
- **Equality.** `==` on Struct values compares the type and the fields, as Ruby's Struct does,
  unless the type defines its own `==`. A type that includes `Comparable` and defines `<=>` (and not
  `==`) is equal to a value of the same type when `<=>` gives 0, as Ruby's `Comparable#==`; a value
  of another type, such as nil, is never equal, and `<=>` is not called. `Array.include?`, `index`, and similar operations use the
  same equality.
- **Explicit forms.** `Arithmetic.+(a, b)` dispatches the same way. `Integer.+(a, b)` calls
  Integer's `+` directly; it requires `a` to be an Integer, and `b` may be any type that Integer's
  `+` accepts.
- **Errors.** Using an operator whose module the left operand's type does not include, or does not
  define, is a `type` problem before running and a `TypeError` while running.

For the built-in types, the result type depends on both operand types, through a **closed
table**:

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

- **No matching row.** If no row matches the operand types, the operation raises `TypeError`. The
  message lists the rows that do exist. There is no implicit conversion.
- **Integer division.** `/` and `%` on Integers follow Ruby: `7 / 2 == 3` and `-7 / 2 == -4`.
  Dividing an Integer by zero raises `ZeroDivisionError`. Float division by zero follows IEEE.
- **Negative exponent.** `Integer ** negative Integer` raises `ArgumentError`, so that the type of
  `a ** b` does not depend on the value of `b`. Write `2r ** -1` for a Rational.
- **Complex.** A Complex has no ordering, so `<` and the like are not defined for it.
- **Time.** `Time ± number` gives a Time; `Time - Time` gives a Float of seconds; two Times compare.
- **Values of different types** are never equal: `1 == :a` and `struct == "x"` are false, as in Ruby
  (a Struct type's own `==` decides for its values).
- **Collections.** Tuples, Arrays, Sets, Hashes, and Records are equal when their contents are
  (two Records also need the same fields). Tuples and Arrays are ordered element by element, as
  Ruby's Arrays are; when two elements cannot be compared, `<` and the like raise `ArgumentError`
  and `<=>` gives nil. Before running, the checker reports element types that cannot be compared.
- **`!x`** is `x ? false : true`: it works on any value and is not an operation of a type.
- **Compound assignment.** `x OP= e` means `x = x OP e`.
- **Not operators.** `&&` and `||` short-circuit and return one of their operands, as in Ruby.

### 8.2 Indexing

`x[k]` means `Indexable.[](x, k)`, and `x[k] = v` means `Indexable.[]=(x, k, v)`: they run the
`[]` and `[]=` of `x`'s type. A Struct type joins with `include Indexable` and `def [](x, k)` /
`def []=(x, k, v)`; with two indexes, `m[r, c]` calls `def [](m, r, c)` and `m[r, c] = v` calls `def []=(m, r, c, v)`. The built-in types behave as follows:

| Receiver, index | `x[k]` | `x[k] = v` |
|---|---|---|
| Array, Integer | the element, or nil outside the Array | stores `v` (an Array of T checks `v`) |
| String, Integer | a one-character String, or nil outside the String | not available |
| Tuple, Integer | the element; outside the Tuple, `IndexError` | stores `v` if it has the type of that position |
| Array, Range / String, Range | the slice, or nil | not available |
| Array, Integer, Integer / String, Integer, Integer (`s[start, length]`) | the slice, or nil | not available |
| Hash, any key | the value, or the default (nil unless made by `Hash.new(default)`) | stores `v`; see §12.1 for keys |
| MatchData, Integer / String | the group, or nil | not available |

- **Negative indexes** count from the end, as in Ruby.
- **A miss gives `nil`**, as in Ruby, so the static type of `a[i]` is `T | nil`. With `--strict`,
  check the result before using it. `Array.fetch(a, i)` raises `IndexError` instead.
- **Tuples.** A Tuple's length is part of its type, so an index outside it is an `IndexError`.
- **Writing past the end.** Writing past the end of an untyped Array fills the gap with nil, as in
  Ruby. An Array of T raises `IndexError` instead, because nil is not a T.
- **Compound assignment.** `x[k] OP= v` and `x[k] ||= v` evaluate `x` and `k` once.
- **Local `||=`.** `y ||= v` assigns to a local only when it is nil or false.

## 9. Control flow

- `if` / `elsif` / `else`, `unless` / `else`, and the ternary `c ? a : b`. A missing branch yields
  `nil`.
- `while` and `until`, which yield `nil`. Inside a loop, `break` leaves the loop and `next` starts
  the next iteration. `begin ... end while` is not supported.
- The modifier forms `stmt if c`, `stmt unless c`, `stmt while c`, and `stmt until c`.

### 9.1 Pattern matching

`x in P` is true when `x` matches the pattern `P`. `x => P` asserts it: it raises
`NoMatchingPatternError` when `x` does not match, and binds a Record pattern's fields. `case x`
followed by `in P then ...` branches runs the first branch whose pattern matches. If no branch
matches and there is no `else`, it raises `NoMatchingPatternError`.

| Pattern | Matches |
|---|---|
| a type name: `Integer`, `String`, `Tuple`, `Hash`, `Point`, `Record`, ... | a value of that type (its type tag) |
| `nil`, `true`, `false`, `1`, `"s"`, `:ok` | an equal value of the same type |
| `P \| Q` | either |
| `{x:, y: name}` | a Record with those fields; binds the locals `x` and `name` |
| `[P, Q]` | a Tuple of that length whose positions match `P` and `Q` (nested patterns allowed) |
| `x` (a bare name inside `[...]`, or alone) | anything; binds the local `x` |

- **No dispatch.** Matching compares type tags and values. There is no `===`, so `case`/`when` is
  not supported.
- **Narrowing.** In `if x in Integer`, and in each `in` branch of `case x`, a local `x` is narrowed
  to the matching types. The `else` branch, and each later branch, sees the types that are left.
  This is how a union such as `Integer | String` is used without a `type` report.
- **Exhaustiveness.** A `case` without `else` that may leave a **type** unmatched is reported as
  `type` ([§2.1](#21-strictness)): the set of types is closed, so this can be checked. Symbol
  literals are tracked as values, so `case op in :add ... in :sub` is complete when `op` only ever
  holds those literals. When literal branches may leave some **values** of an open type (some
  String, Integer, or a Symbol made at run time), the report is the `exhaustive` item (level 3):
  the program may well be correct, and `NoMatchingPatternError` still stops it if not.
- **Assertion.** After `x => P`, a local `x` (and, inside `initialize`, a field `@x` of the new
  instance) is narrowed to the matching types, as in an `in` branch. A value that surely does not match is reported as `type` (level 1); one that may not match
  (another type may come) is checked when it runs, and reported only as `exhaustive` (level 3).
  The failure is `NoMatchingPatternError`, which can be rescued, as in Ruby. `x => P` is itself a check for nil, like `Array.fetch` for a
  missing index, so a value that may be nil is not reported. It is how a fact such as "a port is an
  Integer" is written where the value is stored: `p => Integer`, then `@port = p`.
- **Parentheses.** As in Ruby, `x in P` must be in parentheses when it is an argument:
  `p((x in Integer))`.

## 10. Struct types

### 10.1 Declaring a type: class and attr_*

```ruby
class Account
  attr_reader owner
  attr_accessor balance = 0
  ...
end
```

Every `class` is a type. Its fields are declared in the body of its first `class` (a later
`class Account` adds functions only), with the field names written bare:

| Line | Meaning |
|---|---|
| `attr_accessor x, ...` | fields with a reader `C.x(c)` and a writer `C.set_x(c, v)` |
| `attr_reader x, ...` | fields with the reader only; inside the type's functions, `@x = v` still writes them |
| `attr_writer x, ...` | fields with the writer only; inside the type's functions, `@x` still reads them |
| `private attr_... x` | the reader and writer are for the class's own functions only (on any of its values: `@x`, or `T.x(other)`); `new` still takes it |

- **Field order.** Fields are in the order written; it is the order of `C.new`'s arguments.
- **`new`.** `C.new` takes the fields positionally, whatever their access, or by name (prefer the
  names for a type with several fields: a positional `new` is not checked against the field order):
  `Logger.new(io, level: :warn)` gives the first field by position and `level` by keyword (an unknown
  name and a field given twice are errors). Without `initialize`, every field must be given. With it,
  trailing fields may be left out (or skipped for a later keyword): they are nil when initialize
  starts, and initialize sets them, as Ruby's `@items = []` (`@level = :info if @level == nil` keeps a
  value `new` gave). An exception type's fields after `message` may always be left out (`raise E,
  "msg"` gives the message only).
- **No default values.** `attr_reader items = Array[]` is an error: a field's first value is set in
  `initialize`, the one place that runs for each new instance, where it can read the other fields
  (`@len = String.bytesize(@src)`). The checker follows the fields through initialize, so a field it
  always sets is not nil afterwards.
- **Reserved words.** A field named like a reserved word is declared as a Symbol, `attr_accessor :next`
  (written bare it would not parse); its reader is `Node.next(n)` and `@next` as usual.
- **`initialize`.** `def initialize(c)` in a class runs after `C.new` has stored the fields, with the
  new instance: the place for first values (`@items = Array[]`), checks (`@port => Integer`) and
  conversions (`@celsius = Float(@celsius)`), as in Ruby. It takes exactly that one parameter, and calling `C.initialize` directly is an error.
  The checker analyzes it for each `C.new` call, where `@x` reads the value that call gave, so a
  wrong argument is reported for that call; the fields hold what initialize leaves in them.
- **One type per construction.** For the checker, each `C.new` is its own type: instances made at
  different places (or by one place in a function called with different argument types, such as
  `expect(42)` and `expect("x")`) keep their own field types, so a `Heap` of Integers and a `Heap` of
  Jobs do not mix, and a generic wrapper (`Ok.new(yield(@value))` in `Result.map`) is one type per
  caller. Messages name such a type with its site (`Heap@L7`) only when the type has several. Values
  built from values (`Value.new(a + b)` inside a function taking Values) stay one type per place.
- **`class B < A`.** Shorthand for writing A's definitions in B: A's fields come first (then B's),
  A's functions are B's too (with unqualified names and `@x` inside them meaning B's), and A's
  `include`s are B's. B's own definition of a function wins over A's. Nothing relates A and B
  afterwards: a B is not an A, and `A.f(b)` is a type error. `<` takes a class of the program (or a
  `Struct.new` type); a module is included with `include`.
- **`class E < Exception`** (or `< StandardError`) declares an exception type: `message` is its first
  field, then the fields of its `attr_*` lines.
- **`Struct.new(:x, :y)`.** Shorthand for `class C` with `attr_accessor x, y`; `class C < Struct.new(:x, :y)`
  (Ruby's form) declares those fields first and then the body's `attr_*` lines and functions.
- **`Exception.new(:line)`.** Shorthand for `class C < Exception` with `attr_accessor line`.
- **Errors.** `attr_reader :x` (a Symbol), fields in a later `class C`, a default value, and a write from outside to a read-only field are static errors. The old form
  `class C < {reader: [...]}` is an error whose hint gives the `attr_*` lines.

### 10.2 Struct.new

```ruby
Point = Struct.new(:x, :y)
```

This defines the namespace `Point` with the following operations:

| Operation | Meaning |
|---|---|
| `Point.new(x, y)` | create; positional arguments, one per field |
| `Point.x(p)`, `p.Point.x` | read field `x` (the reader has the field's name) |
| `Point.set_x(p, v)`, `p.Point.x = v` | write field `x` in place; returns `v` |
| `p.Point.x += v`, `\|\|=`, `&&=` | `p.Point.x = p.Point.x + v` with `p` evaluated once |
| `Point[p1, ...]` | an Array of Point ([§12](#12-tuples-and-arrays)) |
| `p == nil`, `p != nil` | comparison with nil |

- **Mutability.** Values are mutable and shared by reference. A change made through one variable
  is visible through every other variable that holds the same value.
- **Adding operations.** Add your own operations in `class Point ... end` or with `def Point.f`.
  Inside them, the readers and writers can be called unqualified (`x(p)`, `set_x(p, v)`). A function
  named like a field (`def x(p) = ...`) replaces its reader, as a method after `attr_reader` does in
  Ruby; `@x` still reads the field.
- **Field shorthand `@x`.** Inside a function of a Struct type (in `class Point` or `def Point.f`),
  `@x` means field `x` of the function's **first parameter**, which is the subject by convention:

  | Written | Means |
  |---|---|
  | `@x` | `Point.x(p)` |
  | `@x = v` | `Point.set_x(p, v)` |
  | `@x OP= v` | `Point.set_x(p, Point.x(p) OP v)` |
  | `@x \|\|= v` | `Point.x(p) \|\| Point.set_x(p, v)` |

  - `p` is the first parameter's current value, even inside a block whose parameter has the same
    name.
  - The usual runtime check applies: the first argument must be a Point.
  - `@x` is a static error in each of these cases: outside a function of a Struct type, in a function
    with no parameters, and when the field does not exist.
- **Printing.** `p` prints a Struct value as `#<struct Point x=1, y=2>`. `puts` prints it the same way.
- **`Struct.new` restrictions.** It must be assigned to a top-level constant. It takes symbols
  only, and no block.
- **No `Data.define`.** `Data.define` is rejected with a hint to use `Struct.new`. Ruby's `Data` is
  immutable, but Sake's named types are mutable, which is what Ruby's `Struct` provides.

## 11. nil

`nil` is an ordinary value. A value that may be absent has the type `nil | T`, and there is no
Option wrapper.

- **Run time.** An operation that receives `nil` where it needs T raises `TypeError ... got nil`.
  The interpreter then runs the static analysis, on the error path only, and adds hints naming the
  fields that may hold `nil` and the lines that store it.
- **Narrowing.** The static analysis narrows a **local variable** in the following places:

  | Form | Where `x` is narrowed |
  |---|---|
  | `if x` / `while x` / `x && …` | non-nil in the branch taken when `x` is truthy |
  | `x != nil` / `x == nil` | nil or non-nil in the matching branch |
  | `!x` / `unless x` | the same, with the branches swapped (`if !x … else` is non-nil in the else) |
  | `return unless x`, `next unless x`, `break unless x`, and other early exits | non-nil after the statement |
  | `String.size(x)`, or any built-in operation taking `x` as an argument | after the call, a type that the operation accepts (it checks its arguments while running) |

  Field reads (`Node.next(n)`) are **not** narrowed, because fields are mutable. Copy the field
  into a local variable first, then test the local.
- **`--strict`.** Level 2 reports, before running, every operation that may receive an unchecked
  `nil`. Level 3 also covers results of `x[k]` ([§2.1](#21-strictness)).

## 12. Tuples, Records, and arrays

**Literals and constructors.** A literal (`[...]`, `{...}`) has no operation with a type, so its
shape fixes its type at creation. A growable collection is made by an operation with a type
(`Array[...]`, `T[...]`).

- **Contents are mutable.** The contents of a literal may be replaced by values of the same type,
  and each write is checked. Tuples are written with `t[i] = v`. Records have no write syntax yet.
- **Length is fixed.** The length is part of the type, so an empty `[]` cannot grow.
- **nil.** A position created with `nil` has the type nil. To leave room for a value, create it
  with a placeholder of the intended type, such as `0` or `""`.

**Tuple.** The literal `[a, b, ...]` is a Tuple.

- Its elements are read by multiple assignment, `x, y = t`. Multiple
  assignment also takes an Array apart (`key, value = String.split(s, "=")`). As in Ruby, missing
  elements are nil and extra elements are dropped; a variable that may get a missing element has the
  type `nil | T` from `x[k]` (the `index-nil` item, level 3). The targets may also be
  elements and fields: `a[i], a[j] = a[j], a[i]` swaps, `@done, @rest = Array.partition(xs) { ... }`.
  Their receivers and indexes are evaluated first, then the right side.
- `first, *rest = xs` puts the remaining elements in a new Array, as in Ruby (`a, *mid, z = xs`
  too; `x, * = xs` drops them). Only a local variable takes the rest. A splat inside `[...]` is
  rejected, since a Tuple's length must be known; `Array[*xs, 1]` makes an Array.
- `t[0]` reads a position and `t[0] = v` replaces it with a value of the same type
  ([§8.2](#82-indexing)).
- `Tuple.size` and `Tuple.length` give the number of elements.

**Record.** The literal `{x: a, y: b}` is a Record.

- **Type.** The type of a Record is its set of (field, type) pairs, for example
  `{x: Integer, y: Integer}`. Two Records with the same set have the same type.
- **Field order.** Order does not matter: `{y: 2, x: 1}` is printed as `{x: 1, y: 2}`.
- **Not a Struct.** A Record is never a Struct value, even when the fields match: Struct types are
  nominal, and Record types are structural.
- **Reading fields.** Take fields apart with a pattern, `r => {x:, y: name}`. This binds the local
  `x` to field `x` and the local `name` to field `y`. Listing only some of the fields is allowed.
  - A field the Record does not have raises `KeyError`.
  - A value that is not a Record raises `TypeError`.
- **Restrictions.** Field names are written as labels (`x:`). An empty `{}` and `{key => value}`
  are static errors, because a Hash is not available yet.

**Array.** `Array[a, ...]` creates an Array with no declared element type. Any value can be added
to it.

**Array of T.** `T[a, ...]` creates an Array whose element type is T. T is a built-in type
(`Integer`, `Float`, `Rational`, `Complex`, `String`, `Symbol`, `Tuple`) or a Struct type.

- **Write checks.** Every write is checked: creation, `Array.push`, `Array.append`, and
  `Array.concat`. A mismatch raises `TypeError`. There is no implicit conversion, so an Integer
  cannot go into `Float[]`.
- **Static check.** If a literal argument of `T[...]` has another type, the error is reported
  before running. This catches `Point[1, 2]`, Ruby's spelling of `Point.new(1, 2)`.
- **Untyped results.** Arrays returned by `map`, `select`, `sort`, and similar operations have no
  declared element type.

Arrays are mutable and shared by reference.

**Ruby habits.** A Tuple or Record passed where an Array is expected, such as `result = []`
followed by `Array.push(result, x)`, fails with a hint to write `Array[]`.

- **In-place operations that change the element type.** The checker gives a container one element type
  for the whole program, so after `Array.map!(xs) { |x| Integer.to_s(x) }` or `Hash.transform_keys!(h) { |k| ... }`
  it takes the container to hold both the old and the new type, and reports operations that fit only one
  of them as `type` (partial). Use the in-place forms for a mapping within one type, and `Array.map` /
  `Hash.transform_keys` (a new container) to change it.

### 12.1 Hash and Set

- **Constructors.** `Hash[k => v, ...]` (also `Hash[name: v]`, whose keys are Symbols), `Hash[]`,
  and `Hash.new(default)` create a Hash. `Set[x, ...]` creates a Set. The literal `{...}` is a
  Record, not a Hash.
- **Keys and elements.** Hash keys and Set elements compare as Ruby's `eql?` does: by value, with the type
  included, so `1` and `1.0` are different keys (`Hash[1 => "a"][1.0]` is nil; `Set[1, 1.0]` has two elements),
  while `1 == 1.0` is true. Allowed: Integer, Float,
  String, Symbol, true, false, nil, Time, and Tuples, Records, Arrays, Hashes, Sets, and Struct values
  made of these. Not allowed (`TypeError`): Regexp, Range, and values of a Struct type that defines
  its own equality (`==`, or `Comparable` with `<=>`), whose keys could disagree with that equality.
  As in Ruby, changing an Array, Hash, Set, or Struct value after using it as a key makes it
  unfindable.
- **Keys are copied.** A Tuple or Record key is copied when it is stored, so a later write to the
  original does not change the key.
- **Default values.** `Hash.new(default)` gives `default` for a missing key, as in Ruby, and the
  same object is shared, as in Ruby. The block form `Hash.new { ... }` is not available, because
  blocks are not values.
- **Blocks.** A block over a Hash receives `[key, value]` as one Tuple, so `|k, v|` takes it apart.
- **Order.** Iteration follows insertion order, as in Ruby.

## 13. Exceptions

```ruby
ParseError = Exception.new(:line)        # fields: message, line

begin
  raise ParseError.new("empty", 1)
rescue ParseError => e
  ParseError.line(e)
rescue KeyError, IndexError => e
  Exception.message(e)
rescue => e                              # any rescuable exception
  raise                                  # re-raise
else
  ...                                    # when nothing was raised
ensure
  ...                                    # always, once
end
```

- **Exception types.** `class Name < Exception` with `attr_reader field` (or
  `Name = Exception.new(:field, ...)`) declares an exception type. It is a Struct type whose first
  field is `message`, so `Name.new("msg", ...)`, `Name.message`, `Name.field`, and `@field`
  work as for other Struct types. Exception types have no hierarchy.
- **Built-in exception types.** These are raised by operations, each with only `message`:
  `RuntimeError`, `ArgumentError`, `KeyError`, `IndexError`, `ZeroDivisionError`, `RangeError`,
  `IOError`, `RegexpError`, `FloatDomainError`, `Math::DomainError`.
- **`raise` forms:**
  - `raise "msg"` raises `RuntimeError`.
  - `raise T, "msg"` raises `T.new("msg")`, where T has no fields besides `message`.
  - `raise value` raises an exception value.
  - A bare `raise` re-raises inside a rescue clause.
- **`rescue`.** `rescue A, B => e` catches the listed types only, since there is no hierarchy.
  `rescue => e` catches every rescuable exception; `e` is a union, so narrow it with
  `case e in A ...`.
- **Reading the message.** `Exception.message(e)` reads the message of any exception value. For an
  exception raised by a built-in operation it is Ruby's text (`divided by 0`); the report of an
  unrescued one also names the operation (`ZeroDivisionError: Arithmetic./: divided by 0`).
- **Program errors.** `SystemStackError`, `LocalJumpError`, and `NotImplementedError` cannot be
  rescued, and naming them in `rescue` is a static error. `TypeError` (an operation given a value of
  the wrong type) and `NoMatchingPatternError` can be rescued, as in Ruby: the checks before running
  stop the type mistakes they report (§2.1), and a run-time check that fails, for instance in a
  program run with `--strict=0`, raises an exception like any other.
- **Other forms.** `def f ... rescue ... end`, `expr rescue fallback`, and `retry` work as in Ruby.
  `ensure` runs once, when the begin block is left.
- **Exception flow.** The type inference tracks which explicitly raised types may leave each
  function:
  - `rescue` (level 1) reports a rescue clause for a type that the begin body never raises.
    Built-in kinds such as `ZeroDivisionError` can come from ordinary operations, so they are
    always assumed possible.
  - `unrescued` (level 4) reports a `raise` that may reach the top level.
- **Uncaught exceptions.** An uncaught exception ends the program like a runtime error:
  `FILE:LINE: in FUNCTION: ParseError: message`.

## 14. Errors

### 14.1 Static errors

Static errors are reported all together, sorted by position, and nothing runs. The format is:

```
FILE:LINE:COLUMN: error: MESSAGE
  hint: SUGGESTION
```

The kinds of static error are:

- syntax errors (from Prism);
- undefined types, operations, and functions;
- wrong argument counts;
- a block passed where none is taken, or missing where one is required;
- calls on values;
- forbidden constructs: `send`, `public_send`, `__send__`, `method_missing`, `define_method`, the
  `eval` family, `instance_variable_get`/`set`, `const_get`/`set`, `binding`, `self`, and `@x`
  outside a function of a Struct type;
- unsupported syntax;
- duplicate definitions;
- literal type mismatches in `T[...]`;
- the items selected by `--strict` ([§2.1](#21-strictness)): by default, values whose type does not fit.

### 14.2 Runtime errors

The format is:

```
FILE:LINE: in FUNCTION: KIND: MESSAGE
  from FILE:LINE: in CALLER
  hint: SUGGESTION
```

| Kind | Raised by |
|---|---|
| `TypeError` | an operation received a value of the wrong type; an operator not supported by the left operand's type; a typed Array write; multiple assignment from a value other than a Tuple or an Array |
| `IndexError` | a Tuple index outside the Tuple; `Array.fetch` outside the Array; writing past the end of an Array of T |
| `ArgumentError` | block parameter count; negative sizes; `Integer ** negative`; comparing incomparable values in `sort` |
| `ZeroDivisionError` | Integer `/` or `%` by zero |
| `KeyError` | `Hash.fetch` of a missing key; a Record pattern naming a missing field |
| `RangeError` | an operation that needs a finite Range, given an endless one |
| `RegexpError` | `Regexp.new` with an invalid pattern |
| `IOError` | `File.read`, `Dir.mkdir`, and the like failing (Ruby: `Errno::ENOENT` & co.; the message is Ruby's) |
| `FloatDomainError` | converting NaN or Infinity to Integer |
| `Math::DomainError` | e.g. `Math.sqrt(-1)` |
| `SystemStackError` | recursion deeper than 10,000 |

## 15. Built-in operations

The tables below are a guide to the most used operations. **The complete list, generated from the
interpreter, is [builtins.md](builtins.md).** The names follow Ruby's core library. "→" gives the result type. Operations marked "block" require
one.

### Kernel

| Operation | Result | Notes |
|---|---|---|
| `puts(*xs)` | nil | prints like Ruby's `puts`; Arrays and Tuples print one element per line |
| `print(*xs)` | nil | no newline |
| `p(x)`, `p(x, y)`, `pp(x)` | x · `[x, y]` · x | prints each argument in Ruby's `inspect` format, one per line; `p()` gives nil |
| `format(fmt, *xs)`, `sprintf` | String | Ruby's format; arguments are Integer, Float, String, Symbol, nil, true, false |
| `Integer(x)`, `Float(x)` | Integer, Float | Ruby's strict conversions; `ArgumentError` on bad input |
| `rand`, `rand(n)` | Float, or Integer/Float below n | |
| `loop { }` | the value of a `break` | runs the block until a `break` |
| `dup(x)` | a copy of x | Ruby's `obj.dup`: new containers and Struct values, the same elements; a type that defines `dup` gets its own |

`Math::PI`, `Math::E`, `Float::INFINITY`, `Float::NAN`, `Float::EPSILON`, `Float::MAX`, `Float::MIN` are read as
operations (`Math.PI`), as `ARGV` is: Sake has no value constants, and no other nested names.

`Arithmetic.round(x)`, `floor`, `ceil`, `truncate` (with an optional digit count), `abs`, `to_f`, `to_i`, `zero?`
take any real number (Integer, Float, Rational), as Ruby's `x.round` does; the result's type follows x's (round
without digits gives an Integer). `Float.round` names a Float only.

### Integer

| Operation | Result |
|---|---|
| `+ - * / % **` (Integer, Integer) | Integer |
| `< <= > >= == !=` (Integer, Integer) | true/false |
| `to_s`, `to_f`, `abs`, `succ`, `pred` | String, Float, Integer, Integer, Integer |
| `even?`, `odd?`, `zero?` | true/false |
| `times(n) { \|i\| }` | n (block) |
| `upto(a, b) { \|i\| }`, `downto(a, b) { \|i\| }` | a (block) |
| `& \| ^ << >>` (both Integer) | Integer |
| `divmod(a, b)` | `[quotient, remainder]` Tuple |
| `gcd`, `lcm`, `pow(a, b, [mod])`, `bit_length`, `sqrt(n)`, `clamp(n, lo, hi)` | Integer |
| `digits` · `chr` · `between?(n, lo, hi)` | Array of Integer · String · true/false |

### Float

| Operation | Result |
|---|---|
| `+ - * / % **` (Float, Float) | Float |
| `< <= > >= == !=` (Float, Float) | true/false |
| `to_s` | String |
| `to_i`, `floor`, `ceil` | Integer |
| `round(f)` / `round(f, digits)` | Integer / Float |
| `abs` | Float |
| `nan?` · `finite?` · `infinite?` | true/false · true/false · 1, -1, or nil |
| `truncate` · `divmod(a, b)` · `clamp(f, lo, hi)` | Integer · `[Float, Float]` Tuple · Float |

### String

| Operation | Result |
|---|---|
| `+(a, b)`, `*(s, n)` | String |
| `== != < <= > >=` (String, String) | true/false |
| `length`, `size`, `count(s, chars)`, `to_i` | Integer |
| `to_f` | Float |
| `upcase`, `downcase`, `capitalize`, `swapcase`, `reverse`, `strip`, `lstrip`, `rstrip`, `chomp`, `to_s` | String |
| `sub(s, from, to)`, `gsub(s, from, to)` | String (plain-string patterns) |
| `ljust(s, n, [pad])`, `rjust(s, n, [pad])` | String |
| `empty?`, `include?(s, t)`, `start_with?(s, t)`, `end_with?(s, t)` | true/false |
| `chars`, `lines`, `split(s, [sep])` | Array of String |
| `index(s, t)` | Integer or nil |
| `center(s, n, [pad])`, `tr(s, a, b)`, `delete(s, chars)`, `squeeze`, `succ`, `next` | String |
| `ord` · `hex` · `oct` · `bytes` | Integer · Integer · Integer · Array of Integer |
| `casecmp?(s, t)` | true/false |
| `each_line(s) { \|l\| }` | s (block) |
| `each_char(s) { \|c\| }` | s (block) |

### Array

| Operation | Result |
|---|---|
| `Array[...]` | a new Array |
| `first(a, n)` · `last(a, n)` · `fetch(a, i, default)` | the first / last n elements (a new Array) · the element, or default |
| `each_cons(a, n)` · `each_slice(a, n)` · `each_with_index(a)` without a block | an Array of the slices, or of `[element, index]` Tuples (Ruby's enumerators, as Arrays: `Array.map(Array.each_cons(xs, 2)) { \|a, b\| ... }`) |
| `Array.new(n)` · `Array.new(n, v)` · `Array.new(n) { \|i\| ... }` | n nils · n times the same v (as in Ruby, one object) · the block's values |
| `length`, `size` | Integer |
| `empty?`, `include?(a, x)` | true/false |
| `push(a, *xs)`, `append(a, *xs)`, `concat(a, b)` | a, modified in place |
| `join(a, [sep])` | String |
| `sum(a, [init])` | the sum; elements must be numbers. An empty Array gives `init` (default 0, an Integer), so a Float sum that may be empty is `Integer \| Float` unless written `sum(a, 0.0)` (as Ruby) |
| `reverse`, `sort`, `take(a, n)`, `drop(a, n)` | a new Array |
| `each(a) { \|x\| }`, `each_with_index(a) { \|x, i\| }` | a (block) |
| `map`, `select`, `filter`, `reject`, `sort_by` | a new Array (block) |
| `any?`, `all?`, `none?` | true/false (block) |
| `count(a) { \|x\| }` | Integer (block) |
| `reduce(a, init) { \|acc, x\| }`, `inject(a, init) { \|acc, x\| }` | the accumulated value; `init` is required (block) |
| `at(a, i)`, `first`, `last`, `min`, `max`, `pop`, `shift` | an element, or nil (`pop` and `shift` remove it) |
| `fetch(a, i)` | the element, or `IndexError` |
| `unshift(a, *xs)` | a, changed in place |
| `find`, `detect`, `min_by`, `max_by` | an element, or nil (block) |
| `index(a, x)`, `find_index(a) { \|x\| }` | Integer or nil |
| `zip(a, *bs)` · `product(a, b)` | Array of Tuples |
| `each_slice(a, n)`, `each_cons(a, n)` | a (block receives an Array) |
| `flatten`, `compact`, `uniq`, `rotate(a, [n])`, `shuffle`, `dup` | a new Array |
| `sample` · `delete(a, x)` · `delete_at(a, i)` | an element or nil |
| `delete_if` · `insert(a, i, *xs)` · `clear` | a, changed in place |
| `tally` · `group_by` · `to_h` | Hash (block for `group_by`; `to_h` takes `[k, v]` Tuples) |
| `partition` | `[matching, rest]` Tuple of Arrays (block) |
| `flat_map` | Array; the block returns an Array |
| `each_with_object(a, memo) { \|x, memo\| }` | memo (block) |
| `sum(a, [init]) { \|x\| }`, `count(a, [x])` | the block is optional |

### Tuple

| Operation | Result |
|---|---|
| `length`, `size` | Integer |
| `to_a` | Array |
| `max`, `min` | the largest / smallest element: `Tuple.max([a, b])` is Ruby's `[a, b].max`. A Tuple's length is known, so the result is never nil (except for `[]`); its type is the union of the element types |
| `minmax` | `[min, max]` |

### Rational, Complex

| Operation | Result |
|---|---|
| `Rational(a, [b])` · `Integer.to_r` · `Float.to_r` · `Float.rationalize` | Rational |
| `Rational.numerator`, `denominator`, `to_i`, `floor`, `ceil`, `round`, `truncate` · `to_f` · `abs` | Integer · Float · Rational |
| `Complex(re, [im])` · `Complex.real`, `imaginary` · `abs`, `arg` · `conjugate` | Complex · a real number · Float · Complex |
| `Complex.rectangular` · `Complex.polar` | `[re, im]` · `[abs, arg]` Tuples |
| `Integer.fdiv(a, b)` | Float |

### Time

| Operation | Result |
|---|---|
| `Time.now` · `Time.at(seconds)` · `Time.new(y, [m, d, h, min, s, zone])` · `Time.utc(t)`, `getutc` | Time |
| `Time.getlocal(t, [zone])`, `Time.localtime(t, [zone])` | Time (the same instant, local or at that offset) |
| `year`, `month`, `day`, `hour`, `min`, `sec`, `wday`, `yday`, `to_i`, `utc_offset` | Integer |
| `to_f` · `to_s` · `strftime(t, fmt)` · `zone` · `utc?` | Float · String · String · String or nil · true/false |

A zone is a fixed UTC offset, as Ruby's: `"+09:00"`, `"-0500"`, `"Z"`, `"UTC"`, a military letter, or
seconds (`3600`). `Time.new`, `Time.at`, and `Time.now` also take it as the keyword `in:`
(`Time.at(0, in: "+09:00")`); `%z` and `%:z` show it. A bad zone raises `ArgumentError`. `Time.utc(t)`
and `Time.localtime(t, zone)` give a converted copy (Ruby's `utc` and `localtime` change the receiver).

### Symbol

| Operation | Result |
|---|---|
| `to_s` · `length` · `size` | String · Integer · Integer |
| `String.to_sym(s)`, `String.intern(s)` | Symbol |

### Range

Operations that iterate need a Range that starts with an Integer or a String (`"A".."Z"` walks
with `String#succ`, as Ruby's); `step`, `sum` and `size` need an Integer. The checker reports a
Range of another type (`1.0..2.0`) at `type`. Two Ranges are `==` when their ends and
`exclude_end?` are; two Regexps when their source and options are. Operations that need a finite
Range raise `RangeError` on an endless one.

| Operation | Result |
|---|---|
| `each`, `each_with_index`, `step(r, n)` | r (block) |
| `to_a`, `map`, `select`, `filter`, `reject` | Array (block for `map` and the filters) |
| `reduce(r, init)`, `inject` · `sum(r, [init])` · `size` · `count` | accumulated value · Integer · Integer · Integer (block optional) |
| `any?`, `all?`, `none?` · `find`, `detect` | true/false · an element or nil (block) |
| `include?`, `cover?`, `member?` · `exclude_end?` | true/false |
| `first`, `last`, `min`, `max`, `begin`, `end` | an element or nil (`first(r, n)`, `last(r, n)` give an Array) |

### Hash

| Operation | Result |
|---|---|
| `Hash[k => v, ...]` · `Hash.new([default])` | a new Hash |
| `length`, `size` · `empty?` | Integer · true/false |
| `key?`, `has_key?`, `include?`, `member?` · `value?`, `has_value?` | true/false |
| `fetch(h, k, [default])` | the value, the default, or `KeyError` |
| `dig(h, k)` · `delete(h, k)` · `key(h, v)` | value or nil · removed value or nil · key or nil |
| `store(h, k, v)` · `clear` · `merge(a, b)` · `invert` | v · h · a new Hash · a new Hash |
| `keys` · `values` · `to_a` | Array · Array · Array of `[k, v]` Tuples |
| `each`, `each_pair` · `each_key` · `each_value` | h (block) |
| `map` · `sort_by` | Array · Array of `[k, v]` (block) |
| `select`, `filter`, `reject` · `transform_values` · `transform_keys` | a new Hash (block) |
| `any?`, `all?`, `none?` · `count` · `sum(h, [init])` | true/false · Integer (block optional) · sum of block values |
| `find`, `detect`, `min_by`, `max_by` | `[k, v]` or nil (block) |

### Set

| Operation | Result |
|---|---|
| `Set[...]` | a new Set |
| `length`, `size` · `empty?` · `include?`, `member?` | Integer · true/false · true/false |
| `add(s, x)` · `add?(s, x)` · `delete(s, x)` | s · s or nil · s |
| `to_a` · `each` · `map` | Array · s (block) · Array (block) |
| `select`, `filter`, `reject` | a new Array (block), as in Ruby |
| `union`, `intersection`, `difference` | a new Set |
| `subset?`, `superset?`, `disjoint?`, `intersect?` | true/false |

### Regexp and MatchData

| Operation | Result |
|---|---|
| `Regexp.new(s, flags = "")` · `Regexp.escape(s)` · `Regexp.source(r)` | Regexp · String · String (flags: letters of `imx`) |
| `Regexp.match(r, s)`, `String.match(s, r)` | MatchData or nil |
| `Regexp.match?(r, s)`, `String.match?(s, r)` | true/false |
| `String.scan(s, r)` | Array of String (Array of Tuples when the pattern has groups) |
| `MatchData.captures` · `named_captures` · `names` · `to_a` | Array · Hash · Array · Array |
| `MatchData.to_s`, `pre_match`, `post_match` · `begin(m, i)`, `end(m, i)` | String · Integer |

`String.sub`, `String.gsub`, `String.index`, and `String.split` also take a Regexp. Globals such as
`$1` and `$~` do not exist; keep the MatchData in a variable and index it (`m[1]`).

### File and input

| Operation | Result |
|---|---|
| `gets` (Kernel) | String or nil |
| `File.read(path)` · `File.readlines(path)` | String · Array of String (lines keep their newline) |
| `File.write(path, s)` · `File.exist?(path)` | Integer · true/false |
| `File.directory?`, `file?`, `symlink?`, `zero?`, `empty?`, `readable?`, `writable?`, `executable?`, `absolute_path?` | true/false |
| `File.size(path)` · `File.mtime(path)`, `atime` · `File.ftype(path)` | Integer · Time · String |
| `File.rename(a, b)` · `File.symlink(a, b)`, `link` · `File.readlink(path)` · `File.unlink(*paths)` · `File.chmod(mode, *paths)` · `File.utime(atime, mtime, *paths)` | 0 · 0 · String · Integer · Integer · Integer |
| `File.basename(p, [suffix])`, `dirname(p, [levels])`, `extname`, `join(*parts)`, `expand_path(p, [dir])`, `absolute_path`, `realpath` · `File.split(p)` | String · `[dir, base]` Tuple |
| `Dir.children(path)`, `entries` · `Dir.glob(pattern or patterns, [base: dir])` | Array of String (glob's sorted, as Ruby's) |
| `Dir.each_child(path) { \|name\| }` · `Dir.exist?`, `empty?` · `Dir.mkdir(path, [mode])`, `rmdir` · `Dir.pwd`, `home` | nil · true/false · 0 · String |
| `Dir.mktmpdir([prefix, [dir]])` · `Dir.mktmpdir { \|dir\| }` | the new directory's path · the block's value (the directory and its contents removed after the block) |
| `Array.pack(a, fmt)` · `String.force_encoding(s, enc)` | String (as Ruby: `"C*"` bytes give a binary String, `"U*"` codepoints UTF-8) · s's bytes as enc |
| `String.valid_encoding?(s)` · `String.encoding(s)` | true/false · the encoding's name |

Strings of incompatible encodings meeting (a byte from `Integer.chr(227)` next to UTF-8 text) raise
`EncodingError`, which can be rescued.

### IO values

`IO.stdin`, `IO.stdout`, and `IO.stderr` give the program's streams as values of type `IO` (Sake has
no `$stdout` or `STDOUT`; as with `ARGV`, a value comes from an operation). `IO.stdout` writes where
`puts` does; writing to `IO.stderr` flushes stdout first, so their lines keep their order.
`File.open(path, mode = "r")` gives an `IO` too; with a block it gives the block's value and closes
the file after the block. There is one type, `IO`, for files and streams, so one function can write
to either. `IO` can be matched (`in IO`), and two IO values are `==` when they are the same stream or
file.

| Operation | Result |
|---|---|
| `IO.puts(io, ...)` · `IO.print(io, ...)` · `IO.write(io, s)` | nil · nil · Integer |
| `IO.gets(io)` · `IO.read(io)` · `IO.readlines(io)` | String or nil · String · Array of String |
| `IO.each_line(io) { \|line\| }` · `IO.eof?(io)` · `IO.flush(io)` | io · true/false · io |
| `IO.close(io)` · `IO.closed?(io)` | nil · true/false |

Reading from or writing to a closed IO, or one not opened for it, raises `IOError`.

### Program arguments, exit, warn

- `ARGV` is the Array of the program's arguments (`bin/sake prog.sake a b` gives `["a", "b"]`). It is
  written like Ruby's constant, but it is an operation (`Kernel.ARGV`): Sake has no value constants. Every use gives the same
  Array, so `Array.shift(ARGV)` (or an option parser's `parse!`) removes an argument for later uses, as in Ruby.
- `exit(status)` (Integer, or true for 0 / false for 1; default 0) ends the program with that exit
  status; `ensure` clauses run on the way out. Code after a call to `exit` is not reached, for the
  checks before running too.
- `warn(x, ...)` prints to the error stream, as `puts` does to the output.
- `File.delete(path)` removes a file.

### once

`once { ... }` gives the block's value. The block runs the first time that place in the program is
reached, and later calls there give the same value, for the whole program and every thread. It is
Sake's way to compute a table or a named value once, since there are no value constants:
`def crc_table = once { ... }`. The value is shared, as Ruby's constants are (an Array kept by
`once` can still be changed). A block that reaches its own `once` again while computing it is a
program error (`SystemStackError`). For the checks before running, its type is the union of the
block's results over every call that may compute it.

### Positions, bytes, replacements

| Operation | Result |
|---|---|
| `String.index(s, t, [start])` · `String.rindex(s, t, [start])` | Integer or nil (t a String or a Regexp) |
| `Regexp.match(re, s, [pos])` · `String.match(s, re, [pos])` · `match?` likewise | MatchData or nil · true/false; `\G` anchors at pos |
| `String.byteindex(s, t, [start])` · `String.byteslice(s, i, [n])` · `String.b(s)` | byte positions as Ruby |
| `String.unpack(s, fmt)` · `String.unpack1(s, fmt)` | an Array · one value; the element type follows a literal format (`"N*"`: Integer, `"a*"`: String) |
| `String.sub(s, pat, repl)` · `String.gsub(...)` | repl: a String (with `\1`), a Hash (match => replacement), or a block `{ \|m\| ... }` giving the replacement |

### Threads and sockets

| Operation | Result |
|---|---|
| `Thread.new { ... }` | a Thread running the block concurrently |
| `Thread.value(t)` · `Thread.join(t)` · `Thread.alive?(t)` | the block's value (waits; an error in the thread is raised here) · t (waits) · true/false |
| `Mutex.new` · `Mutex.synchronize(m) { ... }` | a Mutex · the block's value, run while holding m |
| `Queue.new` · `Queue.push(q, x)` · `Queue.pop(q)` | a Queue · q · the oldest element (waits; nil once the queue is closed and empty) |
| `Queue.close(q)` · `Queue.size(q)` · `Queue.empty?(q)` · `Queue.closed?(q)` | q · Integer · true/false · true/false |
| `TCPServer.new(host, port)` · `TCPServer.accept(s)` · `TCPServer.port(s)` · `TCPServer.close(s)` | a TCPServer (port 0 picks a free one) · a Socket (waits) · Integer · nil |
| `Socket.connect(host, port)` · `Socket.gets(s)` · `Socket.read(s, n)` | a Socket · String or nil · String or nil (at most n bytes) |
| `Socket.write(s, str)` · `Socket.close_write(s)` · `Socket.close(s)` | Integer · nil · nil |

- **Variables in a thread.** A block shares the variables around it, as every block does. For a
  thread, the variables of the blocks around `Thread.new` (their parameters and locals), and the
  thread block's own, are copied when the thread starts; the function's variables stay shared. So
  `Array.map(xs) { |w| Thread.new { ... w ... } }` gives each thread its own `w`, and a shared
  counter is a function variable updated inside `Mutex.synchronize`.
- **Leaving a thread block.** `break` and `return` out of a `Thread.new` block are errors
  (`LocalJumpError`); `next v` ends it with `v`.
- **Errors.** An error inside a thread is raised by `Thread.value` or `Thread.join`. A thread that is
  never joined ends silently when it fails, and every thread stops when the main program ends.
- **Checking.** The typer runs a thread's block once, at `Thread.new`: its value is the type of
  `Thread.value`; a Queue's element type is the union of what is pushed (`Queue.pop` adds nil).
  Interleavings are not analyzed; each operation still checks its arguments while running.
- **Where.** Not available in the browser playground (ruby.wasm has neither threads nor sockets).
- Socket errors (refused, reset, unknown host) raise `IOError`.

### Math

| Operation | Result |
|---|---|
| `sqrt`, `cbrt`, `sin`, `cos`, `tan`, `atan`, `exp`, `log`, `log2`, `log10` (Integer or Float) | Float |
| `atan2(y, x)`, `hypot(x, y)` | Float |

### Typed arrays

`Integer[...]`, `Float[...]`, `Rational[...]`, `Complex[...]`, `String[...]`, `Symbol[...]`,
`Tuple[...]`, and `D[...]` for each Struct type `D` create an Array whose element type is that type ([§12](#12-tuples-and-arrays)).

## 16. Not yet supported

Each of these is rejected statically. Most wait on a design decision.

- **Writing to Record fields.**
- **The type scope `Integer.(a + b)`.**
- **`case`/`when`** (use `case`/`in`), **`%w[]`, `%i[]`.**
- **`for`**: not planned for now. Iterate with an operation such as `Range.each(1..3) { |i| ... }`.
- **Patterns other than those in [§9.1](#91-pattern-matching)**: `*rest` in a Tuple pattern, find patterns, pins, guards.
- **Nested names** such as `URI::HTTP` (only the built-in constants `Math::PI` & co. are read).
- **First-class blocks** (storing a block, `proc`, `lambda`): see §7 for what blocks can do.
