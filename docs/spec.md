# Sake Language Specification (v0)

Sake (/seɪk/) is designed for the sake of finding a new place for types. It keeps Ruby's syntax,
but you write the type on each operation, never on a variable.

This document describes the language as implemented by the v0 interpreter (`bin/sake`). Sake is
experimental. Points still open in the design are listed in [§15](#15-not-yet-supported) and in
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
bin/sake FILE.sake            # check, then run
bin/sake --check FILE.sake    # only the static checks
bin/sake --strict FILE.sake   # static checks + report unchecked uses of maybe-nil values, then run
bin/sake --types FILE.sake    # experimental type inference report (does not run the program)
```

| Exit status | Meaning |
|---|---|
| 0 | success |
| 1 | runtime error |
| 2 | static error (nothing was executed) |

## 3. Program structure

A program is a single file. Its top level may contain:

- **Function definitions**: `def name(params) ... end` and `def name(params) = expr`.
- **Namespaced function definitions**: `def Type.name(params) ...`. This is equivalent to defining
  `name` inside `class Type`.
- **Namespaces**: `class Name ... end` and `module Name ... end`. Their bodies may contain only
  `def name(...)` (no receiver).
- **Struct types**: `Name = Struct.new(:field, ...)`.
- **Statements**: any other expression. Statements run in order.

All definitions are collected before anything runs. A function may be called on a line above its
definition.

Rules:

- Namespaces cannot be nested (`A::B` is rejected).
- Classes cannot inherit.
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
| String | `"abc"`, `'abc'` | no interpolation |
| true / false | `true`, `false` | internally one type, `Boolean`, which cannot be written in source |
| nil | `nil` | see [§11](#11-nil) |
| Tuple | `[a, b, ...]` | length and positional types fixed at creation |
| Record | `{x: a, y: b}` | set of (field, type) pairs fixed at creation |
| Array | `Array[a, ...]` | no declared element type |
| Array of T | `T[a, ...]`, e.g. `Float[]`, `Point[p]` | element type T, checked on every write |
| Hash | `Hash["a" => 1, b: 2]`, `Hash.new(0)` | keys are value types ([§12.1](#121-hash-and-set)) |
| Set | `Set[1, 2]` | elements are value types |
| Symbol | `:name` | |
| Range | `1..5`, `1...5`, `1..` | ends are Integer, Float, String, or nil |
| Regexp, MatchData | `/(\d+)-(\d+)/`, `String.match(s, re)` | no interpolation |
| Struct type | `Point.new(x, y)` | record with mutable fields |

- **Truthiness.** Only `nil` and `false` are falsy. Every other value, including `0` and `""`, is
  truthy.
- **Error messages.** `nil`, `true`, and `false` are shown as values (`got nil`). Every other value
  is shown by its type name (`got Integer`).

## 5. Operations and name resolution

### 5.1 Qualified calls

`Type.op(args...)` calls the operation `op` of namespace `Type`. By convention the subject is the
first argument. Both `Type` and `op` must exist, or the program is rejected before running. When
they do not exist, the error offers spelling suggestions and lists other namespaces that define
`op`.

### 5.2 No calls on values

A call with a lowercase receiver, such as `x.op(...)`, `"lit".op`, or `3.times`, is a static error.
The error suggests the qualified form.

- **Chains** are rewritten as a whole: `s.strip.upcase` suggests `String.upcase(String.strip(s))`.
- **Field access** gets the accessor: `p.x` suggests `Point.get_x(p)`, and `p.x = v` suggests
  `Point.set_x(p, v)`.
- **Literal receivers** narrow the suggestions to the literal's type.
- **`x.nil?`** suggests `x == nil`.

### 5.3 Unqualified calls

A call without a receiver, `f(args)`, is resolved statically. The first match wins:

1. the enclosing class or module, including its built-in operations and Struct accessors;
2. top-level functions;
3. `Kernel` (`puts`, `print`, `p`).

An inner definition **shadows** an outer one. It is not an error for the same name to exist at
several levels. An outer definition can always be reached with its namespace (`Kernel.puts`).

Code at the top level has no enclosing namespace, so resolution starts at step 2.

### 5.4 Arity and blocks

The following are checked statically:

- the number of arguments, for both user functions and built-in operations;
- for a user function, a block must be passed **iff** the function contains `yield`;
- a built-in operation either requires a block or rejects one.

## 6. Functions

```ruby
def area(w, h) = w * h
def describe(n)
  return "negative" if n < 0
  Integer.to_s(n)
end
```

- **Parameters.** Only required positional parameters are allowed. Optional, rest, keyword, and
  block parameters (`&b`) are rejected, as are destructuring parameters.
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

- **Not values.** Blocks are second-class. They cannot be stored, returned, or passed with `&`.
  `proc`, `lambda`, and `->` are not available.
- **Parameters.** `|a, b|` lists plain names. `it` and `_1` … `_9` work as in Ruby.
- **Tuple destructuring.** If a block declares two or more parameters and receives a single Tuple,
  the Tuple is destructured.
- **Parameter count.** A block with no parameters ignores its arguments. Otherwise, a block called
  with the wrong number of arguments raises `ArgumentError`.
- **Scope.** A block sees and can assign the enclosing local variables.
- **`next [v]`.** Ends the current block call with value `v` (default `nil`).
- **`return`.** Inside a block, `return` returns from the enclosing **function**, as in Ruby.
- **`break`.** Not allowed inside blocks.

`yield(args...)` calls the block given to the current function. It is a static error outside a
function.

## 8. Operators

### 8.1 Binary operators

`a OP b` means `BinaryOp.OP(a, b)`. The result type depends on the operand types, through a
**closed table**:

| Operator | Rows |
|---|---|
| `+` | (Integer, Integer) → Integer; (Integer, Float), (Float, Integer), (Float, Float) → Float; (String, String) → String |
| `-` `*` `/` `%` `**` | numeric pairs as for `+` |
| `*` | also (String, Integer) → String |
| `<` `<=` `>` `>=` | numeric pairs, (String, String) → true/false |
| `==` `!=` | numeric pairs, (String, String), (Symbol, Symbol), (true/false, true/false), (nil, nil); and (T, nil), (nil, T) for **any** T |
| `&` `\|` `^` `<<` `>>` | (Integer, Integer) → Integer |
| `\|` `&` `-` | (Set, Set) → Set (union, intersection, difference) |
| `=~` | (String, Regexp), (Regexp, String) → Integer or nil; `!~` (String, Regexp) → true/false |
| `%` | (String, Integer / Float / String / Symbol / Tuple / nil / true / false) → String, Ruby's format (`"%d items" % 3`, `"%s-%s" % [a, b]`) |

- **No matching row.** If no row matches the operand types, the operation raises `TypeError`. The
  message lists the rows that do exist. There is no implicit conversion.
- **Integer division.** `/` and `%` on Integers follow Ruby: `7 / 2 == 3` and `-7 / 2 == -4`.
  Dividing an Integer by zero raises `ZeroDivisionError`. Float division by zero follows IEEE.
- **Negative exponent.** `Integer ** negative Integer` raises `ArgumentError`, because Sake has no
  Rational.
- **Equality of compound values.** `==` between Tuples, Arrays, or Struct values is not defined yet.
  Only comparison with `nil` is defined for them.
- **Compound assignment.** `x OP= e` means `x = x OP e`.
- **Typed form.** `Integer.+(a, b)`, `Float.*(a, b)`, `String.+(a, b)`, and so on name the type
  explicitly. Both operands must then have that type. The exception is `String.*(s, n)`, which
  takes `(String, Integer)`.
- **Not operators.** `&&` and `||` short-circuit and return one of their operands, as in Ruby. They
  are not entries in `BinaryOp`.

### 8.2 Indexing

`x[k]` means `Index.[](x, k)`, and `x[k] = v` means `Index.[]=(x, k, v)`. Like `BinaryOp`, `Index`
has a closed table:

| Receiver, index | `x[k]` | `x[k] = v` |
|---|---|---|
| Array, Integer | the element, or nil outside the Array | stores `v` (an Array of T checks `v`) |
| String, Integer | a one-character String, or nil outside the String | not available |
| Tuple, Integer | the element; outside the Tuple, `IndexError` | stores `v` if it has the type of that position |
| Array, Range / String, Range | the slice, or nil | not available |
| Hash, any key | the value, or the default (nil unless made by `Hash.new(default)`) | stores `v`; the key must be a value type |
| MatchData, Integer / String | the group, or nil | not available |

- **Negative indexes** count from the end, as in Ruby.
- **A miss gives `nil`**, as in Ruby, so the static type of `a[i]` is `T | nil`. With `--strict`,
  check the result before using it. `Array.fetch(a, i)` raises `IndexError` instead.
- **Tuples.** A Tuple's length is part of its type, so an index outside it is an `IndexError`.
- **Writing past the end.** Writing past the end of an untyped Array fills the gap with nil, as in
  Ruby. An Array of T raises `IndexError` instead, because nil is not a T.
- **Compound assignment.** `x[k] OP= v` and `x[k] ||= v` evaluate `x` and `k` once.
- **Local `||=`.** `y ||= v` assigns to a local only when it is nil or false.

### 8.3 Not supported

- Unary operators: `!x`, `-x`, `+x`, `~x`.
- `<=>`.

Both are static errors.

## 9. Control flow

- `if` / `elsif` / `else`, `unless` / `else`, and the ternary `c ? a : b`. A missing branch yields
  `nil`.
- `while` and `until`, which yield `nil`. Inside a loop, `break` leaves the loop and `next` starts
  the next iteration. `begin ... end while` is not supported.
- The modifier forms `stmt if c`, `stmt unless c`, `stmt while c`, and `stmt until c`.

## 10. Struct types

```ruby
Point = Struct.new(:x, :y)
```

This defines the namespace `Point` with the following operations:

| Operation | Meaning |
|---|---|
| `Point.new(x, y)` | create; positional arguments, one per field |
| `Point.get_x(p)` | read field `x` |
| `Point.set_x(p, v)` | write field `x` in place; returns `v` |
| `Point[p1, ...]` | an Array of Point ([§12](#12-tuples-and-arrays)) |
| `p == nil`, `p != nil` | comparison with nil |

- **Mutability.** Values are mutable and shared by reference. A change made through one variable
  is visible through every other variable that holds the same value.
- **Adding operations.** Add your own operations in `class Point ... end` or with `def Point.f`.
  Inside them, the accessors can be called unqualified (`get_x(p)`).
- **Field shorthand `@x`.** Inside a function of a Struct type (in `class Point` or `def Point.f`),
  `@x` means field `x` of the function's **first parameter**, which is the subject by convention:

  | Written | Means |
  |---|---|
  | `@x` | `Point.get_x(p)` |
  | `@x = v` | `Point.set_x(p, v)` |
  | `@x OP= v` | `Point.set_x(p, Point.get_x(p) OP v)` |

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
  | `return unless x`, `next unless x`, `break unless x`, and other early exits | non-nil after the statement |

  Field reads (`Node.get_next(n)`) are **not** narrowed, because fields are mutable. Copy the field
  into a local variable first, then test the local.
- **`--strict`.** Reports, before running, every operation that may receive an unchecked `nil`. The
  run does not start.

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

- Its elements are read by multiple assignment, `x, y = t`, and the counts must match.
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
(`Integer`, `Float`, `String`, `Tuple`) or a Struct type.

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

### 12.1 Hash and Set

- **Constructors.** `Hash[k => v, ...]` (also `Hash[name: v]`, whose keys are Symbols), `Hash[]`,
  and `Hash.new(default)` create a Hash. `Set[x, ...]` creates a Set. The literal `{...}` is a
  Record, not a Hash.
- **Keys and elements.** Hash keys and Set elements must be **value types**: Integer, Float,
  String, Symbol, true, false, nil, and Tuples and Records made of these. Anything else is a
  `TypeError`. A Struct, Array, Hash, or Set is not a value type, because equality of those types
  is undecided (protocols).
- **Keys are copied.** A Tuple or Record key is copied when it is stored, so a later write to the
  original does not change the key.
- **Default values.** `Hash.new(default)` gives `default` for a missing key, as in Ruby, and the
  same object is shared, as in Ruby. The block form `Hash.new { ... }` is not available, because
  blocks are not values.
- **Blocks.** A block over a Hash receives `[key, value]` as one Tuple, so `|k, v|` takes it apart.
- **Order.** Iteration follows insertion order, as in Ruby.

## 13. Errors

### 13.1 Static errors

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
- in `--strict` mode, unchecked uses of maybe-nil values.

### 13.2 Runtime errors

The format is:

```
FILE:LINE: in FUNCTION: KIND: MESSAGE
  from FILE:LINE: in CALLER
  hint: SUGGESTION
```

| Kind | Raised by |
|---|---|
| `TypeError` | an operation received a value of the wrong type; a `BinaryOp` row is missing; a typed Array write; multiple assignment from a non-Tuple |
| `IndexError` | a Tuple index outside the Tuple; `Array.fetch` outside the Array; writing past the end of an Array of T |
| `ArgumentError` | Tuple size mismatch in multiple assignment; block parameter count; negative sizes; comparing incomparable values in `sort` |
| `ZeroDivisionError` | Integer `/` or `%` by zero |
| `KeyError` | `Hash.fetch` of a missing key; a Record pattern naming a missing field |
| `RangeError` | an operation that needs a finite Range, given an endless one |
| `RegexpError` | `Regexp.new` with an invalid pattern |
| `IOError` | `File.read` and the like failing |
| `FloatDomainError` | converting NaN or Infinity to Integer |
| `Math::DomainError` | e.g. `Math.sqrt(-1)` |
| `SystemStackError` | recursion deeper than 10,000 |

## 14. Built-in operations

The names follow Ruby's core library. "→" gives the result type. Operations marked "block" require
one.

### Kernel

| Operation | Result | Notes |
|---|---|---|
| `puts(*xs)` | nil | prints like Ruby's `puts`; Arrays and Tuples print one element per line |
| `print(*xs)` | nil | no newline |
| `p(x)`, `pp(x)` | x | prints `x` in Ruby's `inspect` format |
| `format(fmt, *xs)`, `sprintf` | String | Ruby's format; arguments are Integer, Float, String, Symbol, nil, true, false |
| `Integer(x)`, `Float(x)` | Integer, Float | Ruby's strict conversions; `ArgumentError` on bad input |
| `rand`, `rand(n)` | Float, or Integer/Float below n | |

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
| `length`, `size` | Integer |
| `empty?`, `include?(a, x)` | true/false |
| `push(a, *xs)`, `append(a, *xs)`, `concat(a, b)` | a, modified in place |
| `join(a, [sep])` | String |
| `sum(a)` | Integer or Float; elements must be numbers; 0 for an empty Array |
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
| `sum(a) { \|x\| }`, `count(a, [x])` | the block is optional |

### Tuple

| Operation | Result |
|---|---|
| `length`, `size` | Integer |
| `to_a` | Array |

### Symbol

| Operation | Result |
|---|---|
| `to_s` · `length` · `size` | String · Integer · Integer |
| `String.to_sym(s)`, `String.intern(s)` | Symbol |

### Range

Operations that iterate need a Range that starts with an Integer. Operations that need a finite
Range raise `RangeError` on an endless one.

| Operation | Result |
|---|---|
| `each`, `each_with_index`, `step(r, n)` | r (block) |
| `to_a`, `map`, `select`, `filter`, `reject` | Array (block for `map` and the filters) |
| `reduce(r, init)`, `inject` · `sum` · `size` · `count` | accumulated value · Integer · Integer · Integer (block optional) |
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
| `any?`, `all?`, `none?` · `count` · `sum` | true/false · Integer (block optional) · sum of block values |
| `find`, `detect`, `min_by`, `max_by` | `[k, v]` or nil (block) |

### Set

| Operation | Result |
|---|---|
| `Set[...]` | a new Set |
| `length`, `size` · `empty?` · `include?`, `member?` | Integer · true/false · true/false |
| `add(s, x)` · `add?(s, x)` · `delete(s, x)` | s · s or nil · s |
| `to_a` · `each` · `map` | Array · s (block) · Array (block) |
| `select`, `filter`, `reject` · `union`, `intersection`, `difference` | a new Set |
| `subset?`, `superset?`, `disjoint?`, `intersect?` | true/false |

### Regexp and MatchData

| Operation | Result |
|---|---|
| `Regexp.new(s)` · `Regexp.escape(s)` · `Regexp.source(r)` | Regexp · String · String |
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

### Math

| Operation | Result |
|---|---|
| `sqrt`, `cbrt`, `sin`, `cos`, `tan`, `atan`, `exp`, `log`, `log2`, `log10` (Integer or Float) | Float |
| `atan2(y, x)`, `hypot(x, y)` | Float |

### Typed arrays

`Integer[...]`, `Float[...]`, `String[...]`, `Tuple[...]`, and `D[...]` for each Struct type `D`
create an Array whose element type is that type ([§12](#12-tuples-and-arrays)).

## 15. Not yet supported

Each of these is rejected statically. Most wait on a design decision.

- **Writing to Record fields.**
- **`Array.new`.**
- **Unary operators.**
- **String interpolation**, which waits on how values become strings.
- **Protocols.** These are generic operations such as `to_s` and `==` over all types.
- **The type scope `Integer.(a + b)`.**
- **`case`/`when`, `for`, `%w[]`, `%i[]`.**
- **Built-in constants** such as `Math::PI` and `Float::INFINITY`.
- **Rational, Complex, Time.**
- **First-class blocks.**
- **Exceptions** (`raise`, `rescue`).
- **Several files** (`require`).
