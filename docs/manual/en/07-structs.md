# Struct types

## Declaring a type: class and attr_*

```ruby
class Account
  attr_reader owner
  attr_accessor balance
  def initialize(a)
    @balance = 0 if @balance == nil
  end
end
```

Every `class` is a type. Its fields are declared in the body of its first `class` (a later `class Account` adds functions only), with the field names written bare:

| Line | Meaning |
|---|---|
| `attr_accessor x, ...` | fields with a reader `C.x(c)` and a writer `C.set_x(c, v)` |
| `attr_reader x, ...` | fields with the reader only; inside the type's functions, `@x = v` still writes them |
| `attr_writer x, ...` | fields with the writer only; inside the type's functions, `@x` still reads them |
| `private attr_... x` | the reader and writer are for the class's own functions only (on any of its values: `@x`, or `T.x(other)`); `new` still takes it |

- **Field order.** Fields are in the order written, across lines; it is the order of `C.new`'s arguments.
- **`new`.** `C.new` takes the fields positionally, whatever their access, or by name (prefer the names for a type with several fields: a positional `new` is not checked against the field order): `Logger.new(io, level: :warn)` gives the first field by position and `level` by keyword (an unknown name and a field given twice are errors). Without `initialize`, every field must be given. With it, trailing fields may be left out (or skipped for a later keyword): they are nil when initialize starts, and initialize sets them, as Ruby's `@items = []` (`@level = :info if @level == nil` keeps a value `new` gave). An exception type's fields after `message` may always be left out (`raise E, "msg"` gives the message only).
- **No default values.** `attr_reader items = Array[]` is an error: a field's first value is set in `initialize`, the one place that runs for each new instance, where it can read the other fields (`@len = String.bytesize(@src)`). The checker follows the fields through initialize, so a field it always sets is not nil afterwards.
- **Reserved words.** A field named like a reserved word is declared as a Symbol, `attr_accessor :next` (written bare it would not parse); its reader is `Node.next(n)` and `@next` as usual.
- **`initialize`.** `def initialize(c)` in a class runs after `C.new` has stored the fields, with the new instance: the place for first values (`@items = Array[]`), checks (`@port => Integer`) and conversions (`@celsius = Float(@celsius)`), as in Ruby. It takes exactly that one parameter, and calling `C.initialize` directly is an error. The checker analyzes it for each `C.new` call, where `@x` reads the value that call gave, so a wrong argument is reported for that call; the fields hold what initialize leaves in them.

> [!WARNING]
> Ruby's `def initialize(x) = @x = x` is a static error in Sake: `x` is the new instance, not a value, so this would store the instance in its own field. `C.new(...)` has already stored the fields; initialize only checks or converts them.

- **One type per construction.** For the checker, each `C.new` is its own type: instances made at different places (or by one place in a function called with different argument types, such as `expect(42)` and `expect("x")`) keep their own field types, so a `Heap` of Integers and a `Heap` of Jobs do not mix, and a generic wrapper (`Ok.new(yield(@value))` in `Result.map`) is one type per caller. Messages name such a type with its site (`Heap@L7`) only when the type has several. Values built from values (`Value.new(a + b)` inside a function taking Values) stay one type per place.
- **`class B < A`.** Shorthand for writing A's definitions in B: A's fields come first (then B's), A's functions are B's too (with unqualified names and `@x` inside them meaning B's), and A's `include`s are B's. B's own definition of a function wins over A's. Nothing relates A and B afterwards: a B is not an A, and `A.f(b)` is a type error. `<` takes a class of the program (or a `Struct.new` type); a module is included with `include`.
- **`class E < Exception`** (or `< StandardError`) declares an exception type: `message` is its first field, then the fields of its `attr_*` lines.
- **`Struct.new(:x, :y)`.** Shorthand for `class C` with `attr_accessor x, y`.
- **`Exception.new(:line)`.** Shorthand for `class C < Exception` with `attr_accessor line`.
- **Errors.** `attr_reader :x` (a Symbol), fields in a later `class C`, a default value, and a write from outside to a read-only field are static errors. The old form `class C < {reader: [...]}` is an error whose hint gives the `attr_*` lines.

## The operations of Struct.new

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
| `Point[p1, ...]` | an Array of Point |
| `p == nil`, `p != nil` | comparison with nil |

- **Mutability.** Values are mutable and shared by reference. A change made through one variable is visible through every other variable that holds the same value.
- **Adding operations.** Add your own operations in `class Point ... end` or with `def Point.f`. Inside them, the readers and writers can be called unqualified (`x(p)`, `set_x(p, v)`). A function named like a field (`def x(p) = ...`) replaces its reader, as a method after `attr_reader` does in Ruby; `@x` still reads the field.
- **Field shorthand `@x`.** Inside a function of a Struct type (in `class Point` or `def Point.f`), `@x` means field `x` of the function's **first parameter**, which is the subject by convention:

  | Written | Means |
  |---|---|
  | `@x` | `Point.x(p)` |
  | `@x = v` | `Point.set_x(p, v)` |
  | `@x OP= v` | `Point.set_x(p, Point.x(p) OP v)` |
  | `@x \|\|= v` | `Point.x(p) \|\| Point.set_x(p, v)` |

  - `p` is the first parameter's current value, even inside a block whose parameter has the same name.
  - The usual runtime check applies: the first argument must be a Point.
  - `@x` is a static error in each of these cases: outside a function of a Struct type, in a function with no parameters, and when the field does not exist.
- **Printing.** `p` prints a Struct value as `#<struct Point x=1, y=2>`. `puts` prints it the same way.
- **`Struct.new` restrictions.** It must be assigned to a top-level constant. It takes symbols only, and no block.
- **No `Data.define`.** `Data.define` is rejected with a hint to use `Struct.new`. Ruby's `Data` is immutable, but Sake's named types are mutable, which is what Ruby's `Struct` provides.
- **`Kernel.dup(x)`.** A shallow copy (new containers and Struct values, the same elements). A type that defines `dup` gets its own.
