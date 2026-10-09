# Operators and indexing

## Binary operators

An operator dispatches on the type of its **left operand**: `a OP b` runs `T.OP(a, b)`, where `T` is the type of `a`. Each operator belongs to a module, and `a OP b` is shorthand for calling the operator through that module ([module functions and dispatch](02-program.md)):

| Module | Operators | Built-in types that include it |
|---|---|---|
| `Arithmetic` | `+ - * / % **`, unary `-x` `+x` (`-@` `+@`) | Integer, Float, Rational, Complex, String, Time, Set |
| `Comparable` | `<=> < <= > >=` | Integer, Float, Rational, String, Time, Tuple, Array |
| `Bitwise` | `& \| ^ << >>`, unary `~x` | Integer, Set |
| `Indexable` | `[]`, `[]=` (see "Indexing") | Array, Hash, String, Tuple, MatchData |
| `Kernel` | `== != =~ !~` | every type |

- **Your own types.** A Struct type joins an operator by including the module and defining the operator in its class, such as `include Arithmetic` with `def +(a, b)`. With `include Comparable`, defining `<=>` is enough: `<`, `<=`, `>`, and `>=` come from it, and `Array.sort`, `min`, and `max` use it too.
- **A built-in on the left.** `2 + money` dispatches on Integer, which has no row for Money. A Struct type that defines `coerce(b, a)`, giving a Tuple `[left, right]` as Ruby's protocol does, has the pair converted first and the operator run on it: `def coerce(m, other) = [Money.new(other * 100), m]` makes `2 + money` into `Money.new(200) + money`. The checker follows the conversion.
- **Equality.** `==` on Struct values compares the type and the fields, as Ruby's Struct does, unless the type defines its own `==`. A type that includes `Comparable` and defines `<=>` (and not `==`) is equal to a value of the same type when `<=>` gives 0, as Ruby's `Comparable#==`; a value of another type, such as nil, is never equal, and `<=>` is not called. `Array.include?`, `index`, and similar operations use the same equality.
- **Explicit forms.** `Arithmetic.+(a, b)` dispatches the same way. `Integer.+(a, b)` calls Integer's `+` directly; it requires `a` to be an Integer, and `b` may be any type that Integer's `+` accepts.
- **Errors.** Using an operator whose module the left operand's type does not include, or does not define, is a `type` problem before running and a `TypeError` while running.

For the built-in types, the result type depends on both operand types, through a **closed table**:

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

- **No matching row.** If no row matches the operand types, the operation raises `TypeError`. The message lists the rows that do exist. There is no implicit conversion.
- **Integer division.** `/` and `%` on Integers follow Ruby: `7 / 2 == 3` and `-7 / 2 == -4`. Dividing an Integer by zero raises `ZeroDivisionError`. Float division by zero follows IEEE.
- **Negative exponent.** `Integer ** negative Integer` raises `ArgumentError`, so that the type of `a ** b` does not depend on the value of `b`. Write `2r ** -1` for a Rational.
- **Complex.** A Complex has no ordering, so `<` and the like are not defined for it.
- **Time.** `Time ± number` gives a Time; `Time - Time` gives a Float of seconds; two Times compare.
- **Values of different types** are never equal: `1 == :a` and `struct == "x"` are false, as in Ruby (a Struct type's own `==` decides for its values).
- **Collections.** Tuples, Arrays, Sets, Hashes, and Records are equal when their contents are (two Records also need the same fields). Tuples and Arrays are ordered element by element, as Ruby's Arrays are; when two elements cannot be compared, `<` and the like raise `ArgumentError` and `<=>` gives nil. Before running, the checker reports element types that cannot be compared.
- **`!x`** is `x ? false : true`: it works on any value and is not an operation of a type.
- **Compound assignment.** `x OP= e` means `x = x OP e`.
- **Not operators.** `&&` and `||` short-circuit and return one of their operands, as in Ruby.

## Indexing

`x[k]` means `Indexable.[](x, k)`, and `x[k] = v` means `Indexable.[]=(x, k, v)`: they run the `[]` and `[]=` of `x`'s type. A Struct type joins with `include Indexable` and `def [](x, k)` / `def []=(x, k, v)`; with two indexes, `m[r, c]` calls `def [](m, r, c)` and `m[r, c] = v` calls `def []=(m, r, c, v)`. The built-in types behave as follows:

| Receiver, index | `x[k]` | `x[k] = v` |
|---|---|---|
| Array, Integer | the element, or nil outside the Array | stores `v` (an Array of T checks `v`) |
| String, Integer | a one-character String, or nil outside the String | not available |
| Tuple, Integer | the element; outside the Tuple, `IndexError` | stores `v` if it has the type of that position |
| Array, Range / String, Range | the slice, or nil | not available |
| Array, Integer, Integer / String, Integer, Integer (`s[start, length]`) | the slice, or nil | not available |
| Hash, any key | the value, or the default (nil unless made by `Hash.new(default)`) | stores `v` |
| MatchData, Integer / String | the group, or nil | not available |

- **Negative indexes** count from the end, as in Ruby.
- **A miss gives `nil`**, as in Ruby, so the static type of `a[i]` is `T | nil`. With `--strict`, check the result before using it. `Array.fetch(a, i)` raises `IndexError` instead.
- **Tuples.** A Tuple's length is part of its type, so an index outside it is an `IndexError`.
- **Writing past the end.** Writing past the end of an untyped Array fills the gap with nil, as in Ruby. An Array of T raises `IndexError` instead, because nil is not a T.
- **Compound assignment.** `x[k] OP= v` and `x[k] ||= v` evaluate `x` and `k` once.
- **Local `||=`.** `y ||= v` assigns to a local only when it is nil or false.
