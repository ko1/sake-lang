# Program structure and name resolution

This chapter covers what a program is made of and how the names in it are resolved. One idea runs through it: every definition is collected before anything runs, and every call's callee is decided before running. So a function may be called on a line above its definition, and a misspelled name is reported before running.

## Files and `require`

A program is a file and the files it `require`s. The top level of a file holds definitions and statements. Definitions are collected together before running; statements run from top to bottom.

```ruby
puts(greet("Sake"))                  # => Hello, Sake
def greet(name) = "Hello, #{name}"   # callable from a line above its definition
def String.shout(s) = String.upcase(s) + "!"
puts(String.shout("hi"))             # => HI!
Point = Struct.new(:x, :y)
class Point
  def to_s(p) = "(#{@x}, #{@y})"
end
module Util
  module_function
  def origin = Point.new(0, 0)
end
puts(Util.origin)                    # => (0, 0)
```

### What the top level may contain

- **`require "path"`**: reads another file. See the next section.
- **Function definitions**: `def name(params) ... end` and `def name(params) = expr`.
- **Namespaced function definitions**: `def Type.name(params) ...`, equivalent to defining `name` inside `class Type`.
- **Namespaces**: `class Name ... end` and `module Name ... end`.
- **Classes**: `class Name` with `attr_*` lines, or `Name = Struct.new(:field, ...)`.
- **Statements**: any other expression. Statements run in order.

### `require`

`require "path"` reads `path.sake`. The extension may be left out, and the path is relative to the directory of the file that requires it.

```ruby
# lib/units.sake
puts("loading units")
def km_to_m(km) = km * 1000
```

```ruby
# main.sake
require "lib/units"          # => loading units
puts("main")                 # => main
puts(km_to_m(3))             # => 3000
```

- **Decided before running.** The argument must be a string literal, and `require` must be a statement at the top level of a file. The files of a program are decided before running.
- **Once.** Each file is read once, whatever requires it. A cycle stops at a file already read.
- **Order.** A required file's top-level statements run before those of the file that requires it. All `require`s of a file are read first. That is why `loading units` comes before `main` above.
- **One collection of definitions.** The definitions of every file are collected together, so names may be used across files in any order. Defining a name in two files is an error, as it is in one file.
- **Messages.** Error messages name the file of each line (`lib/units.sake:4`, `from lib/broken.sake:3`).
- **Library.** A name with no sibling file, such as `require "json"`, is looked up in the [library](10-library.md) shipped with the interpreter (`sakelib/`).

### Namespaces: `class` and `module`

`class Name ... end` and `module Name ... end` open a namespace. `class` declares a **type** (a class) or adds operations to an existing one, including a built-in type such as `String`. `module` is a namespace with **no type**.

The body of a namespace may contain only the following.

- `def name(...)` (no receiver)
- `include Module`
- `module_function` (in a module; see "Calling a module's functions" below)
- a nested `class` / `module`, or `Name = Struct.new(...)`
- in a class, `attr_reader` / `attr_accessor` / `attr_writer` lines ([Classes](07-classes.md))

Any other statement in a body is a static error. `module` on a type is a static error too, with a hint that gives `class`.

```ruby error
module String                # !> `module String`: String is a type; add operations to a type with class
  def shout(s) = String.upcase(s)
end
```

### Namespaces nest

`class B` (or `module B`, or `B = Struct.new(...)`) written inside `module A` declares `A::B`. `class A::B` at the top level opens the same namespace, so either spelling adds operations to the same class.

```ruby
module Geo
  Point = Struct.new(:x, :y)
  class Point
    def norm2(p) = @x * @x + @y * @y
  end
  module Util
    module_function
    def origin = Point.new(0, 0)      # Point here is Geo::Point
  end
end
class Geo::Point                       # the Ruby spelling opens the same class
  def to_s(p) = "(#{@x}, #{@y})"
end
pt = Geo::Point.new(3, 4)
p(Geo::Point.norm2(pt))                # => 25
p(pt.Geo::Point.norm2)                 # => 25
puts(Geo::Util.origin)                 # => (0, 0)
p((pt in Geo::Point))                  # => true
```

- **The full name outside.** Write `A::B.f(x)`, `x.A::B.f`, `include A::M`, `class C < A::B`, `x in A::B`, `(A::B|C).f(x)`, `rescue A::E`.
- **The short name inside.** Inside `A`, a bare `B` means `A::B`. As in Ruby, the lookup starts at the innermost namespace, and falls back to the top-level `B`.
- **No `def A::B.f`.** It is not Ruby syntax. A module function of a nested module is defined inside it (`module A::B` + `module_function`).
- **A namespace is not a value.** `p(A::B)` is an error, and `A::B` alone has no meaning.

```ruby error
module Geo
  Point = Struct.new(:x, :y)
end
p(Geo::Point)                # !> type `Geo::Point` cannot be used as a value
```

### Classes do not inherit

For any class, `class B < A` is shorthand for writing A's definitions in B. Afterwards A and B are unrelated types, and `A.f` takes only A's values ([Classes](07-classes.md)).

```ruby
class A
  attr_reader x
  def double(a) = @x * 2
end
class B < A
  attr_reader y
end
b = B.new(1, 2)
p(B.double(b))               # => 2
p((b in A))                  # => false
```

```ruby error
class A
  attr_reader x
  def double(a) = @x * 2     # !> A.x: argument 1 must be A, but is B [type]
end
class B < A
  attr_reader y
end
p(A.double(B.new(1, 2)))
```

### No `self`

`def self.x` is rejected, because Sake has no `self`. A `def x` inside a class already defines `A.x`.

```ruby error
class A
  attr_reader x
  def self.make = A.new(1)   # !> `def self.make` inside `A`: write `def make` (it defines A.make)
end
```

### One definition per name

Defining the same name twice in one namespace is an error. Redefining a built-in operation is also an error.

```ruby error
def f = 1
def f = 2                    # !> `f` is already defined at line 1
```

```ruby error
def String.upcase(s) = s     # !> `String.upcase` is a built-in operation and cannot be redefined
```

### No value constants

Constants can only be assigned from `Struct.new`. For a named value, define a function (`def pi = 3.14159`) and call it (`pi`). `PI = 3.14` is a static error whose hint gives that function, and each use of `PI` gets the hint to call `pi`. `once { ... }` computes a value once ([Built-in operations](09-builtins.md)).

```ruby
def pi = 3.14159
p(pi * 2)                    # => 6.28318
```

```ruby error
PI = 3.14                    # !> Sake has no value constants; only a class made with Struct.new can be assigned to a constant
p(PI * 2)                    # !> `PI` is not defined (Sake has no value constants)
```

## Qualified calls

`Type.op(args...)` calls the operation `op` of namespace `Type`. By convention the subject is the first argument. Both `Type` and `op` must exist, or the program is rejected before running. The error offers spelling suggestions and lists other namespaces that define `op`.

```ruby error
puts(String.upcse("a"))      # !> undefined function `String.upcse`
```

```ruby error
puts(Strng.upcase("a"))      # !> undefined type or module `Strng`
```

```ruby error
puts(Integer.upcase("a"))    # !> undefined function `Integer.upcase`
```

The hint of the last one is `` `upcase` is defined in `String.upcase`, `Symbol.upcase` ``.

## Chains and `_`

Two forms let a sequence of operations read from left to right, top to bottom. In both, every step still names its type.

### Chains

`x.T.f(args...)` is `T.f(x, args...)`: the step `.T` names a type or module, and the value to its left becomes the first argument. Steps can follow one another, also with the dot at the start of the next line.

```ruby
line = "a, b ,c"
r = String.split(line, ",")
  .Array.map { |s| String.strip(s) }
  .Array.join("|")
p(r)                         # => "a|b|c"
```

`x.T` with no operation after it is a static error.

```ruby error
s = "x"
p(s.String)                  # !> `s.String` needs an operation after the type: `s.String.op(...)`
```

### `_`

`_` is the value of the **previous statement** in the same body (a function, a block, a branch, or the top level).

```ruby
line = "a, b ,c"
String.split(line, ",")
Array.map(_) { |s| String.strip(s) }
Array.join(_, "|")
p(_)                         # => "a|b|c"
```

`_` refers to a statement, not an expression, because a statement is unambiguous. An expression-level `_` would have to pick one of the sub-expressions of the line before, and there is no natural answer to which one. "The statement before" is one thing.

- **Not in a first statement.** Reading `_` in the first statement of a body, or right after a definition, is a static error.
- **Parentheses and interpolation.** In parentheses and in string interpolation, the first statement reads the `_` of the enclosing statement.
- **`_` as a name.** `_` may still be bound as a name to ignore (`|_, v|`, `a, _ = t`). But a `_` that names a local variable cannot be read.

```ruby
String.upcase("sake")
puts("got #{_}")             # => got SAKE
Array[1, 2]
p((Array.size(_) + 1))       # => 3
```

```ruby error
def f(x)
  p(_)                       # !> `_` is the previous statement's value, and no statement precedes it here
end
f(1)
```

```ruby error
a, _ = [1, 2]
p(_)                         # !> `_` is the previous statement's value, but here it names a local variable
```

## No calls on values

A call with a lowercase receiver, such as `x.op(...)`, `"lit".op`, or `3.times`, is a static error. The error suggests the qualified form, and for a single step also the chain form (`x.T.op(...)`).

```ruby error
s = " a "
puts(s.strip.upcase)         # !> method call on a value `s.strip.upcase` is not allowed
```

- **Chains** are rewritten as a whole: `s.strip.upcase` suggests `String.upcase(String.strip(s))`. In the chain form, it is `s.String.strip.String.upcase`.
- **Field access** gets the reader: `p.x` suggests `Point.x(p)` (or `p.Point.x`), and `p.x = v` suggests `p.Point.x = v`. With a setter function, write `Point.set_x(p, v)`.
- **Literal receivers** narrow the suggestions to the literal's type: `"lit".upcase` suggests only `String.upcase("lit")`.
- **`x.nil?`** suggests `x == nil`.

```ruby error
Point = Struct.new(:x, :y)
pt = Point.new(1, 2)
p(pt.x)                      # !> method call on a value `pt.x` is not allowed
```

```ruby error
3.times { puts("hi") }       # !> method call on a value `3.times` is not allowed
```

## Unqualified calls

A call without a receiver, `f(args)`, is resolved before running. The search goes in this order, and the first match wins.

1. The enclosing class or module, including its built-in operations, Struct accessors, and the functions it includes.
2. Top-level functions.
3. `Kernel` (`puts`, `print`, `p`).

```ruby
def size(x) = "top-level size"
class Box
  attr_reader items
  def size(b) = Array.size(@items)
  def describe(b) = "#{size(b)} items"   # Box.size
end
b = Box.new(Array[1, 2])
puts(Box.describe(b))        # => 2 items
puts(size(b))                # => top-level size
```

- **Shadowing.** An inner definition shadows an outer one. It is not an error for the same name to exist at several levels.
- **The outer one, qualified.** An outer definition can always be reached with its namespace (`Kernel.puts`).
- **Top level.** Code at the top level has no enclosing namespace, so resolution starts at step 2.

```ruby
class Logger
  attr_reader prefix
  def puts(l, msg) = Kernel.puts("#{@prefix}#{msg}")
  def run(l) = puts(l, "start")          # Logger.puts
end
Logger.run(Logger.new("> "))             # => > start
puts("done")                             # => done
```

## include

`include M` in a class or module body copies the functions of the module `M` into the includer. This is Ruby's module, resolved statically.

```ruby
module Summary
  def total(x) = Array.inject(items(x), 0) { |a, v| a + v }
  def report(x) = "total=#{total(x)}"
end
class Basket
  include Summary
  attr_reader items
end
b = Basket.new(Array[1, 2, 3])
puts(Basket.report(b))       # => total=6
puts(Summary.total(b))       # => 6
```

### Copying

Each function `f` of `M` becomes `X.f` in the including namespace `X`. If `X` already has `f`, `X`'s own definition wins. Modules included by `M` are copied too.

```ruby
module A
  def bar(x) = "A"
  def baz(x) = "A"
end
class C
  include A
  attr_reader v
  def bar(x) = "C"
end
p(C.bar(C.new(1)))           # => "C"
p(C.baz(C.new(1)))           # => "A"
```

### Order

Modules are searched in Ruby's ancestor order: the module included **last** comes first. With `include A` then `include B`, a `bar` in both comes from B.

```ruby
module A
  def bar(x) = "A"
end
module B
  def bar(x) = "B"
end
class C
  include A
  include B
  attr_reader v
end
p(C.bar(C.new(1)))           # => "B"
```

### Resolution in the includer

Inside a copied function, unqualified names are resolved in `X`. So `M` can use functions that `X` provides, such as `each`. Nothing is dispatched at run time: each `X.f` is fixed before running. `@x` refers to a field of `X` when `X` is a class.

```ruby
module Named
  def label(x) = "<#{@name}>"
end
class Cat
  include Named
  attr_reader name
end
puts(Cat.label(Cat.new("tama")))   # => <tama>
```

### Requirements

The unqualified names that the bodies of `M`'s functions call (`each(x)`, say) and the fields `@x` they read, minus what `M` itself, the top level and `Kernel` define, are `M`'s requirements. Nothing is declared; they are collected from the bodies.

- **Missing in the includer.** If `X` lacks one (no `each`, no field `x`), `include M` is a static error. It names the function and what it needed.
- **Called directly.** Calling a function with requirements directly, as in `M.total(x)`, without going through an includer, is a static error too. The hint gives the call through an includer. This concerns a module function `total`; for a mixin function, `M.total(x)` is the dispatch of the next section.

```ruby error
module Summary
  def total(x) = Array.inject(items(x), 0) { |a, v| a + v }
end
class Empty
  include Summary            # !> `include Summary` in Empty: Summary.total needs `items`, which Empty does not define (used at line 2)
  attr_reader v
end
```

```ruby error
module Summary
  module_function
  def total(x) = Array.inject(items(x), 0) { |a, v| a + v }
end
class Basket
  include Summary
  attr_reader items
end
puts(Summary.total(Basket.new(Array[1])))   # !> Summary.total needs `items` from a namespace that includes Summary
```

### Restrictions

- Only modules can be included. Including a class is a static error.
- Include cycles are errors.
- **Not inheritance.** `include` adds no subtype relation. A value of a type that includes `M` does not become a value of `M`.

```ruby error
class A
  attr_reader x
end
class B
  include A                  # !> `include A`: A is not a module
  attr_reader y
end
```

## Calling a module's functions: module_function and dispatch

A name in a type or module is one function: Sake has no `def self.f` next to `def f`, because the "instance" form only means that the value comes first (`T.f(x, ...)`). Where Ruby has both a class method and an instance method of one name (`Net::HTTP.get(uri)` and `http.get(path)`), one of them takes another name, or one function tells the forms apart by the type of its first argument.

A module's functions are of two kinds, as in Ruby.

| Kind | How it is declared | `M.f(args)` |
|---|---|---|
| module function | after `module_function`, by `module_function :f`, or with `def M.f` | runs `M`'s own `f` (static) |
| mixin function | any other function of a module | **dispatches**: runs the `f` of the first argument's type, which must include `M` |

```ruby
module Describe
  def describe(x) = "#{prefix}#{name(x)}"   # a mixin function
  def prefix = "* "
  module_function :prefix                   # a module function
end
class Cat
  include Describe
  attr_reader name
end
class Dog
  include Describe
  attr_reader name
end
p(Describe.prefix)                          # => "* "
puts(Describe.describe(Cat.new("tama")))    # => * tama
puts(Describe.describe(Dog.new("pochi")))   # => * pochi
puts(Cat.describe(Cat.new("tama")))         # => * tama
```

### No subject

A mixin function cannot be called without arguments (`M.foo`), because there is nothing to dispatch on. Calling one when no type includes `M` is also a static error, with a hint to use `module_function`.

```ruby error
module Greeting
  def hello(x) = "hello"
end
puts(Greeting.hello(1))      # !> Greeting.hello is a mixin function, and no type includes Greeting
```

### Type check

The type inference checks that the first argument's possible types all include `M`, and reports one that does not as a `type` problem. While running, a type that does not include `M` raises `TypeError`.

```ruby error
module Describe
  def describe(x) = "#{name(x)}"
end
class Cat
  include Describe
  attr_reader name
end
Dog = Struct.new(:name)
def pick(flag) = flag ? Cat.new("tama") : Dog.new("pochi")
puts(Describe.describe(pick(true)))   # !> Describe.describe dispatches on its first argument, which can be Dog; the types that include Describe are Cat [type]
```

### Static calls

A type's own namespace is always static. In the example above, `Cat.describe(c)` runs Cat's `describe` (copied from `Describe`); `Describe.describe(x)` is the dispatching form.

### Kernel

Every type includes `Kernel`. `Kernel.to_s(x)` and `Kernel.inspect(x)` dispatch to a type's own `to_s` and `inspect`, or use the built-in form. `"#{x}"`, `puts`, and `p` are shorthands for them.

```ruby
class Temp
  attr_reader deg
  def to_s(t) = "#{@deg} C"
end
t = Temp.new(20)
puts(t)                      # => 20 C
puts("now #{t}")             # => now 20 C
puts(Kernel.to_s(t))         # => 20 C
p(Kernel.to_s(5))            # => "5"
```

### Required functions

A function of a module whose body is only `raise NotImplementedError` (with or without a message) is required: each type that includes the module defines it, and `M.f(x)` dispatches to that definition. Whether it takes a block comes from the types' definitions.

```ruby
module Shape
  def area(s) = raise NotImplementedError
  def describe(s) = "area=#{area(s)}"
end
class Sq
  include Shape
  attr_reader side
  def area(s) = @side * @side
end
puts(Shape.describe(Sq.new(3)))   # => area=9
puts(Shape.area(Sq.new(2)))       # => 4
```

- **A type that does not define it.** A type that includes the module without defining it is a `type` problem wherever a call can reach it, and `NotImplementedError` while running.
- **Not rescued.** `NotImplementedError` is a program error and cannot be rescued.
- **Message.** `raise T` with an exception type and no message gives the type's name as the message.

```ruby error
module Shape
  def area(s) = raise NotImplementedError
  def describe(s) = "area=#{area(s)}"   # !> Shape.area: Blob includes Shape but does not define area, which Shape requires (`raise NotImplementedError`) [type]
end
class Blob
  include Shape
  attr_reader v
end
puts(Shape.describe(Blob.new(1)))
```

## Listing the types: `(A|B).f(x)`

`(A|B).f(x, args...)` lists, on the operation itself, the types that `x` may have. While running, the type of `x` picks `A.f` or `B.f`; any other type raises `TypeError`. The result is the union of the results.

```ruby
Leaf = Struct.new(:weight)
Node = Struct.new(:weight, :kids)
def weight(t) = (Leaf|Node).weight(t)   # a field of the same name in two classes
p(weight(Leaf.new(2)))                  # => 2
p(weight(Node.new(5, Array[])))         # => 5
def size_of(x) = (String|Array|Hash).size(x)
p(size_of("abc"))                       # => 3
p(size_of(Array[1, 2]))                 # => 2
```

Two things are checked before running.

- **Every listed type has `f`.** Otherwise it is a static error.
- **No unlisted type arrives.** The checker reports a value of `x` whose type is not listed as a `type` problem.

```ruby error
def shout(x) = (String|Integer).upcase(x)   # !> Integer has no `upcase`, so `(String|Integer).upcase` cannot dispatch to it
p(shout("abc"))
```

```ruby error
def size_of(x) = (String|Array).size(x)   # !> (String|Array).size: argument 1 must be String or Array, but is Integer [type]
p(size_of(5))
```

- **The list names types.** Built-in types (`IO` among them) and classes, each at most once. `nil` cannot be listed; check for nil first.
- **The shapes may differ.** The listed functions may differ in shape: a user function's `*rest` is packed for its branch (`(IO|StringIO).print(io, a, b)`). A function that takes keywords cannot be listed; dispatch on the type with `case`.
- **Relation to mixin dispatch.** A mixin function's dispatch `M.f(x)` is the same selection as `(A|B|...).f(x)` listing every class that includes `M`. The difference is where the set is stated: `include` declares it on each class, `(A|B)` states it at the call. So nothing has to be declared, and it covers types that share an operation's name without sharing a module, such as built-in types or same-named fields.

## Arity and blocks

Since the callee is decided before running, the number of arguments and the presence of a block are checked before running.

- **Argument count.** Checked for both user functions and built-in operations.
- **A block to a user function.** A block is passed **iff** the function contains `yield` (or takes `&b`), except that a function that checks `block_given?` may be called without one.
- **A block to a built-in.** A built-in operation either requires a block or rejects one.

```ruby error
def area(w, h) = w * h
p(area(3))                   # !> wrong number of arguments for area (given 1, expected 2)
```

```ruby error
def twice(x) = x * 2
p(twice(3) { 1 })            # !> twice does not take a block (it has no `yield`)
```

```ruby error
p(Array.map(Array[1]))       # !> Array.map requires a block
```

### Splat arguments

`*xs` spreads a Tuple or an Array; anything else raises `TypeError`. It goes only into a rest parameter: a built-in's (`puts(*lines)`, `format(fmt, *row)`, `Array[*xs, 0]`, `Set[*xs]`, `Array.push(a, *xs)`) or a user function's `*rest` (`join(*parts)`, [Functions and blocks](04-functions.md)).

```ruby
def join(sep, *parts) = Array.join(parts, sep)
xs = Array["a", "b"]
p(join("-", *xs))            # => "a-b"
t = [1, 2]
p(Array[*t, 0])              # => [1, 2, 0]
puts(*xs)                    # => a
                             # => b
```

- **The arguments before it are written out.** So their count is still checked.
- **Static errors.** A splat into a function without `*rest`, or one that would fill a required or optional parameter, is a static error. So are splats into `Array.zip` / `Range.zip` (their Tuples are as long as the argument list) and `Hash[...]`.
- **In the typer.** A Tuple spreads position by position; an Array stands for any number of arguments of its element types.

```ruby error
def two(a, b) = a + b
t = [1, 2]
p(two(*t))                   # !> `*t`: splat arguments go only to a `*rest` parameter or to built-ins that take any number of arguments (puts, format, Array[...], Set[...], Array.push, ...)
```
