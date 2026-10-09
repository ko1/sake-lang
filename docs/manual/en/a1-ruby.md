# Differences from Ruby and what is not supported

## From Ruby to Sake

| Ruby | Sake | Why |
|---|---|---|
| `s.upcase` | `String.upcase(s)`, `s.String.upcase` | the type is written on the operation; a call on a value is a static error whose hint gives this form |
| `p.x`, `p.x = v` | `Point.x(p)`, `p.Point.x = v` (`@x`, `@x = v` inside the type's functions) | field reads and writes name their type too |
| `def self.f` | `def f` (the value-first form is the same function); in a module, `module_function` | one name in a type's namespace is one function |
| `class B < A` (inheritance) | `class B < A` copies A's definitions into B; no subtyping | every call target is static |
| `attr_reader :x` | `attr_reader x` | field names are written bare |
| `def initialize(x) = @x = x` | `C.new(x)` stores the field; `initialize(c)` only checks and converts | the parameter is the new instance |
| `@items = []` (a default) | `@items = Array[]` inside `initialize` | fields have no default values |
| `[1, 2]` (a growable array) | `Array[1, 2]`; `[1, 2]` is a Tuple (fixed length) | a literal's shape fixes its type |
| `{a: 1}` (a Hash) | `{a: 1}` is a Record; a Hash is `Hash[a: 1]` | same |
| `PI = 3.14` | `def pi = 3.14`; a table is `once { ... }` | no value constants |
| `Math::PI`, `ARGV`, `$stdout` | `Math.PI`, `ARGV`, `IO.stdout` (operations) | same |
| `case x when Integer` | `case x in Integer` | there is no `===` |
| `x.nil?` | `x == nil` | |
| `$1`, `$~` | `m = String.match(s, re)`, then `m[1]` | no global variables |
| `proc`, `lambda`, `->`, `&:sym`, `method(:f)` | none; a block is only passed, with `yield` or `&b` | blocks are second-class |
| `obj.send(:f)`, `define_method`, `method_missing`, `eval` | none | call targets are static |
| `f(**opts)` | none (pass the Hash positionally) | an open design question (D11) |
| `rescue A` with a hierarchy | `rescue A, B` (no hierarchy); `rescue => e` catches all | exception types are Struct types |
| `1 + money` | define `coerce(m, other)` in Money | the left operand decides |
| `Data.define` | `Struct.new` | named types are mutable |
| `for x in xs` | `Array.each(xs) { \|x\| }` | |
| `%w[a b]`, `%i[a b]` | `String["a", "b"]`, `Symbol[:a, :b]` | |

## Not yet supported

Each of these is rejected statically. Most wait on a design decision.

- **Writing to Record fields.**
- **The type scope `Integer.(a + b)`.**
- **`case`/`when`** (use `case`/`in`), **`%w[]`, `%i[]`.**
- **`for`**: not planned for now. Iterate with an operation such as `Range.each(1..3) { |i| ... }`.
- **Patterns other than those in [Control flow and patterns](06-control.md)**: `*rest` in a Tuple pattern, find patterns, pins, guards.
- **Nested names** such as `URI::HTTP` (only the built-in constants `Math::PI` & co. are read).
- **First-class blocks** (storing a block, `proc`, `lambda`).
- **Passing collected keywords on** with `f(**opts)`.
- **`begin ... end while`.**

## Design material

- `DESIGN.md` (Japanese): the design notes, with the reasons behind each decision.
- `TODO.md`: open items and design questions (D1 to D13).
- `experiments/`: each experiment with its method, results, and limits (README).
