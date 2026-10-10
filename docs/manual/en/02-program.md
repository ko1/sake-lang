# Program structure and name resolution

## Files and `require`

A program is a file and the files it requires. Its top level may contain:

- **`require "path"`**: reads `path.sake` (the extension may be left out), relative to the directory of the file that requires it. The argument must be a **string literal**, and `require` must be a statement at the **top level** of a file: the files of a program are decided before running. Each file is read once, whatever requires it, and a cycle stops at a file already read. A required file's top-level statements run before those of the file that requires it (all `require`s of a file are read first). Definitions of every file are collected together, so names may be used across files in any order; defining a name in two files is an error, as in one file. Messages name the file of each line (`lib/units.sake:4`, `from lib/broken.sake:3`).
  - A name with no sibling file, such as `require "json"`, is looked up in the [library](10-library.md) shipped with the interpreter (`sakelib/`).
- **Function definitions**: `def name(params) ... end` and `def name(params) = expr`.
- **Namespaced function definitions**: `def Type.name(params) ...`, equivalent to defining `name` inside `class Type`.
- **Namespaces**: `class Name ... end` and `module Name ... end`. Their bodies may contain only `def name(...)` (no receiver), `include Module`, and in a class `attr_reader`/`attr_accessor`/`attr_writer` lines.
  - `class` declares a **type** (a class) or adds operations to one, or to a built-in type such as `String`.
  - `module` is a namespace with **no type**; `module` on a type is a static error with a hint.
- **Classes**: `class Name` with `attr_*` lines, or `Name = Struct.new(:field, ...)`.
- **Statements**: any other expression. Statements run in order.

All definitions are collected before anything runs, so a function may be called on a line above its definition.

Rules:

- Namespaces cannot be nested (`A::B` is rejected).
- Classes do not inherit. For any class, `class B < A` is shorthand for writing A's definitions in B; afterwards A and B are unrelated types, and `A.f` takes only A's ([Classes](07-classes.md)).
- `def self.x` is rejected, because Sake has no `self`.
- Defining the same name twice in one namespace is an error. Redefining a built-in operation is also an error.
- Constants can only be assigned from `Struct.new`. Sake has **no value constants**. For a named value, define a function (`def pi = 3.14159`) and call it (`pi`). `PI = 3.14` is a static error whose hint gives that function. `once { ... }` computes a value once ([Built-in operations](09-builtins.md)).

## Qualified calls

`Type.op(args...)` calls the operation `op` of namespace `Type`. By convention the subject is the first argument. Both `Type` and `op` must exist, or the program is rejected before running; the error offers spelling suggestions and lists other namespaces that define `op`.

## Chains and `_`

Two forms let a sequence of operations read from left to right, top to bottom, with every step still naming its type:

- **Chain.** `x.T.f(args...)` is `T.f(x, args...)`: the step `.T` names a type or module, and the value to its left becomes the first argument. Steps can follow one another, also with the dot at the start of the next line. `x.T` with no operation after it is a static error.

  ```ruby
  String.split(line, ",")
    .Array.map { |s| String.strip(s) }
    .Array.join("|")
  ```

- **`_`** is the value of the previous statement in the same body (a function, a block, a branch, or the top level). Reading `_` in the first statement of a body, or right after a definition, is a static error. In parentheses and in string interpolation, the first statement reads the `_` of the enclosing statement. `_` may still be bound as a name to ignore (`|_, v|`, `a, _ = t`), but a `_` that names a local variable cannot be read.

  ```ruby
  String.split(line, ",")
  Array.map(_) { |s| String.strip(s) }
  Array.join(_, "|")
  ```

## No calls on values

A call with a lowercase receiver, such as `x.op(...)`, `"lit".op`, or `3.times`, is a static error. The error suggests the qualified form, and for a single step also the chain form (`x.T.op(...)`).

- **Chains** are rewritten as a whole: `s.strip.upcase` suggests `String.upcase(String.strip(s))` (in the chain form, `s.String.strip.String.upcase`).
- **Field access** gets the reader: `p.x` suggests `Point.x(p)` (or `p.Point.x`), and `p.x = v` suggests `p.Point.x = v` (or a setter function `Point.set_x(p, v)`).
- **Literal receivers** narrow the suggestions to the literal's type.
- **`x.nil?`** suggests `x == nil`.

## Unqualified calls

A call without a receiver, `f(args)`, is resolved statically. The first match wins:

1. the enclosing class or module, including its built-in operations, Struct accessors, and the functions it includes;
2. top-level functions;
3. `Kernel` (`puts`, `print`, `p`).

An inner definition **shadows** an outer one. It is not an error for the same name to exist at several levels; an outer definition can always be reached with its namespace (`Kernel.puts`). Code at the top level has no enclosing namespace, so resolution starts at step 2.

## include

`include M` in a class or module body copies the functions of the module `M`. This is Ruby's module, resolved statically:

- **Copying.** Each function `f` of `M` becomes `X.f` in the including namespace `X`, unless `X` already has `f`, in which case `X`'s own definition wins. Modules included by `M` are copied too.
- **Order.** Modules are searched in Ruby's ancestor order: the module included **last** comes first. With `include A` then `include B`, a `bar` in both comes from B.
- **Resolution in the includer.** Inside a copied function, unqualified names are resolved in `X`, so `M` can use functions that `X` provides, such as `each`. Nothing is dispatched at run time: each `X.f` is fixed before running. `@x` refers to a field of `X` when `X` is a class.
- **Requirements.** The unqualified names that the bodies of `M`'s functions call (`each(x)`, say) and the fields `@x` they read, minus what `M` itself, the top level and `Kernel` define, are `M`'s requirements. Nothing is declared; they are collected from the bodies. If `X` lacks one (no `each`, no field `x`), `include M` is a static error naming the function and the name. Calling a function with requirements directly, as in `M.total(x)`, is a static error too, with a hint to call it through an includer.
- **Restrictions.** Only modules can be included, and include cycles are errors.
- **Not inheritance.** `include` adds no subtype relation.

## Calling a module's functions: module_function and dispatch

A name in a type or module is one function: Sake has no `def self.f` next to `def f`, because the "instance" form only means that the value comes first (`T.f(x, ...)`). Where Ruby has both a class method and an instance method of one name (`Net::HTTP.get(uri)` and `http.get(path)`), one of them takes another name, or one function tells the forms apart by the type of its first argument.

A module's functions are of two kinds, as in Ruby:

| Kind | How it is declared | `M.f(args)` |
|---|---|---|
| module function | after `module_function`, by `module_function :f`, or with `def M.f` | runs `M`'s own `f` (static) |
| mixin function | any other function of a module | **dispatches**: runs the `f` of the first argument's type, which must include `M` |

- **No subject.** A mixin function cannot be called without arguments (`M.foo`), because there is nothing to dispatch on. Calling one when no type includes `M` is also a static error, with a hint to use `module_function`.
- **Type check.** The type inference checks that the first argument's possible types all include `M`, and reports one that does not as a `type` problem. While running, a type that does not include `M` raises `TypeError`.
- **Static calls.** A type's own namespace is always static: `Basket.total(b)` runs Basket's `total`, whether defined in Basket or copied from `Summary`. `Summary.total(x)` is the dispatching form.
- **Kernel.** Every type includes `Kernel`. `Kernel.to_s(x)` and `Kernel.inspect(x)` dispatch to a type's own `to_s` and `inspect`, or use the built-in form. `"#{x}"`, `puts`, and `p` are shorthands for them.

**Required functions.** A module function whose body is only `raise NotImplementedError` (with or without a message) is required: each type that includes the module defines it, and `M.f(x)` dispatches to that definition. Whether it takes a block comes from the types' definitions. A type that includes the module without defining it is a `type` problem wherever a call can reach it, and `NotImplementedError` while running. `NotImplementedError` is a program error and cannot be rescued. (`raise T` with an exception type and no message gives the type's name as the message.)

## Listing the types: `(A|B).f(x)`

`(A|B).f(x, args...)` lists, on the operation itself, the types that `x` may have. While running, the type of `x` picks `A.f` or `B.f`; any other type raises `TypeError`. Before running, every listed type must have `f` (a static error otherwise), and the checker reports a value of `x` whose type is not listed. The result is the union of the results.

```ruby
def weight(t) = (Leaf|Node).weight(t)   # a field of the same name in two classes
def size_of(x) = (String|Array|Hash).size(x)
```

- The list names types: built-in types (`IO` among them) and classes, each at most once. `nil` cannot be listed; check for nil first.
- The listed functions may differ in shape: a user function's `*rest` is packed for its branch (`(IO|StringIO).print(io, a, b)`). A function that takes keywords cannot be listed; dispatch on the type with `case`.
- A mixin function's dispatch `M.f(x)` is the same selection as `(A|B|...).f(x)` listing every class that includes `M`. The difference is where the set is stated: `include` declares it on each class, `(A|B)` states it at the call. So nothing has to be declared, and it covers types that share an operation's name without sharing a module, such as built-in types or same-named fields.

## Arity and blocks

The following are checked statically:

- the number of arguments, for both user functions and built-in operations;
- for a user function, a block must be passed **iff** the function contains `yield` (or takes `&b`), except that a function that checks `block_given?` may be called without one;
- a built-in operation either requires a block or rejects one.

**Splat arguments.** `*xs` spreads a Tuple or an Array (anything else raises `TypeError`), but only into a rest parameter: a built-in's (`puts(*lines)`, `format(fmt, *row)`, `Array[*xs, 0]`, `Set[*xs]`, `Array.push(a, *xs)`) or a user function's `*rest` (`join(*parts)`). The arguments before it are written out, so their count is still checked. A splat into a function without `*rest`, or one that would fill a required or optional parameter, is a static error, as are splats into `Array.zip`/`Range.zip` (their Tuples are as long as the argument list) and `Hash[...]`. In the typer, a Tuple spreads position by position; an Array stands for any number of arguments of its element types.
