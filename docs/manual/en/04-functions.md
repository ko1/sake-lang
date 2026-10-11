# Functions and blocks

This chapter covers the functions defined with `def` and the blocks passed to calls. Neither carries a type. Since every call's callee is known before running, the number of arguments and the keyword names are checked before running.

## Functions

A function is defined with `def`, and its calls are checked against its parameter count and keyword names. Both the one-line `def f(x) = expr` and the form closed by `end` are available; as in Ruby style, the one-line form is for a short expression, and a body of several steps goes in `def ... end`.

```ruby
def area(w, h) = w * h
def describe(n)
  return "negative" if n < 0
  Integer.to_s(n)
end
p(area(3, 4))        # => 12
p(describe(-1))      # => "negative"
p(describe(7))       # => "7"
```

### Positional parameters and defaults

Required positional parameters come first, then optional ones with a default. As in Ruby, a default is evaluated at the call, after the earlier parameters, when the call does not give that argument. It may use the earlier parameters.

```ruby
def f(a, b = 1, c = b + 1) = [a, b, c]
p(f(10))             # => [10, 1, 2]
p(f(10, 5))          # => [10, 5, 6]
p(f(10, 5, 0))       # => [10, 5, 0]
```

- **Count.** A call gives between the required count and the full count of arguments. Any other count is an error before running.
- **Order.** Arguments are evaluated in the order written.

```ruby error
def area(w, h) = w * h
p(area(3))           # !> wrong number of arguments for area (given 1, expected 2)
```

### Keyword parameters

Keyword parameters come last in the parameter list. Each is required (`w:`) or has a default (`h: w`), and they mix freely with optional positional parameters.

```ruby
def greet(name, greeting = "Hello", punct: "!") = "#{greeting}, #{name}#{punct}"
p(greet("Ruby"))                     # => "Hello, Ruby!"
p(greet("Ruby", punct: "?"))         # => "Hello, Ruby?"
p(greet("Ruby", "Hi", punct: "."))   # => "Hi, Ruby."
punct = "!!"
p(greet("Sake", punct:))             # => "Hello, Sake!!"
```

Since the callee is known before running, the checker delivers `k: v` to its parameter by name. Each of the following is an error before running.

- An unknown keyword, a keyword given twice, or a missing required keyword.
- `k: v` to a function without keyword parameters. There is no implicit Hash argument: write `Hash[k: v]` for a Hash or `{k: v}` for a Record.

```ruby error
def size(w:, h: w) = w * h
p(size(w: 3, d: 2))  # !> size has no keyword parameter `d`
p(size(h: 3))        # !> size needs keyword argument `w:`
```

- **`f(k:)`** passes the variable `k`, as in Ruby.
- **Built-ins.** A few built-ins take Ruby's keywords too, checked the same way: `Time.at(t, in: "+09:00")`, `Dir.glob(pat, base: dir)`. The reference writes them as `[k: T]`.

### `*rest`: the remaining positional arguments

`*rest` after the optional parameters collects the remaining positional arguments in a new Array. A function with `*rest` takes any number of arguments. On the call side, `*xs` spreads a Tuple or an Array into the call.

```ruby
def join(sep, *parts) = Array.join(parts, sep)
p(join("-"))                  # => ""
p(join("-", "a", "b", "c"))   # => "a-b-c"
xs = ["x", "y"]
p(join("+", *xs))             # => "x+y"
```

- **Element type.** `rest` is one Array, so its elements share one type: the union of everything any call passes. To keep a type per position, pass one Tuple: call `notify("stock", ["AAPL", 120])` and take it apart inside with `name, price = event`.
- **Where it is built.** The Array is built at the call, since the callee is known.
- **Order.** The parameters go required, optional, `*rest`, keywords, `**opts`. A positional parameter after `*rest`, and a nameless `*`, are errors before running.
- **Where `*xs` may go.** `*xs` goes only to a `*rest` parameter or to a built-in that takes any number of arguments (`puts`, `format`, `Array[...]`, `Array.push`, ...). It cannot fill required or optional parameters.

```ruby error
def f(*rest, z) = z   # !> parameters after `*rest` are not supported: required, optional, `*rest`, keywords, `**opts`, in that order
```

### `**opts`: the remaining keywords

`**opts` at the end collects the keywords that are not parameter names in a Hash with Symbol keys. It too is built at the call.

```ruby
def tag(name, **opts) = [name, opts]
p(tag("div"))                            # => ["div", {}]
p(tag("div", id: "main", hidden: true))  # => ["div", {id: "main", hidden: true}]
```

- **Misspellings.** A function with `**opts` accepts any keyword, so a misspelled one is no longer an error there.
- **A nameless `**`** is an error before running.
- **Passing on.** Passing the collected keywords on with `f(**opts)` is not available yet.

### The block parameter `&b`

`&b` (or `&` alone) is a parameter whose only use is to pass the function's block on to another call. It is described under "Blocks".

### Agreement among a mixin function's definitions

A module's mixin function dispatches to the definition of its first argument's type ([Program structure and name resolution](02-program.md)). So the types' definitions must agree on the parameter counts, the keyword names, and on having `*rest` / `**opts`. A disagreement is an error before running, at the call.

```ruby error
module Shape
  def area(s) = raise NotImplementedError
end
class Sq
  include Shape
  attr_reader side
  def area(s) = @side * @side
end
class Rect
  include Shape
  attr_reader w, h
  def area(r, scale) = @w * @h * scale
end
p(Shape.area(Sq.new(2)))   # !> Shape.area dispatches to Rect.area, whose arguments or block differ from Shape.area
```

### Return value

A function's value is the value of its last expression, or of `return expr`. `return a, b` returns the Tuple `[a, b]`, so the caller can take it with `a, b = f(...)`.

```ruby
def minmax(xs) = return Array.min(xs), Array.max(xs)
lo, hi = minmax(Array[3, 1, 2])
p([lo, hi])          # => [1, 3]
```

### Polymorphism

Functions are polymorphic. Having no type annotations, a function works on any arguments its operations accept. A type error surfaces at the operation that fails: the checker reports that line, with a hint naming the call that reached it.

```ruby
def twice(x) = x + x
p(twice(2))          # => 4
p(twice("ab"))       # => "abab"
p(twice(1.5))        # => 3.0
```

```ruby error
def twice(x) = x + x   # !> Arithmetic.+: the operands are (:a, :a), which the left operand's type does not support
p(twice(:a))
```

### Local variables

Each function has its own scope. It has no access to the top-level locals.

```ruby error
count = 10
def bump = count + 1   # !> undefined local variable or function `count`
```

As in Ruby, reading a local whose assignment appears earlier in the text but has not run yet gives `nil`.

```ruby
def f
  x = 1 if false
  p(x)               # => nil
end
f
```

### Recursion

Recursion is allowed. A depth over 10,000 calls raises `SystemStackError`. `bin/sake` runs the program on a thread with a large stack, so that this limit applies rather than Ruby's stack. A long backtrace is shortened in the middle.

```ruby
def fact(n) = n <= 1 ? 1 : n * fact(n - 1)
p(fact(20))          # => 2432902008176640000
def down(n) = n == 0 ? 0 : down(n - 1)
p(down(9_000))       # => 0
```

```ruby error
def down(n) = n == 0 ? 0 : down(n - 1)
p(down(20_000))      # !> SystemStackError: stack level too deep
```

## Blocks

A block is passed to a built-in operation or to a user function that yields. Most iteration is written with block-taking operations such as `Array.each`.

```ruby
xs = Array[1, 2, 3]
p(Array.map(xs) { |x| x * 2 })      # => [2, 4, 6]
Hash.each(Hash[a: 1, b: 2]) do |k, v|
  puts "#{k}=#{v}"                  # => a=1
                                    # => b=2
end
Integer.times(3) { p it }           # => 0
                                    # => 1
                                    # => 2
```

### Not values

Blocks are second-class. They cannot be stored in a variable or returned from a function. `proc`, `lambda`, and `->` are not available.

```ruby error
f = proc { |x| x }   # !> undefined function `proc`
```

### Parameters

`|a, b|` lists plain names. `it` and `_1` … `_9` work as in Ruby.

```ruby
p(Array.map(Array[1, 2]) { _1 * 10 })   # => [10, 20]
p(Array.map(Array[1, 2]) { it + 1 })    # => [2, 3]
```

### Destructuring

When a block declares two or more parameters and receives a single Tuple or Array, its elements become the parameters. Missing ones are nil and extra ones are dropped, as in Ruby. A parameter can itself be taken apart with `( )`.

```ruby
pairs = Array[["a", 1], ["b", 2]]
Array.each(pairs) { |name, n| p("#{name}=#{n}") }              # => "a=1"
                                                               # => "b=2"
Array.each_with_index(pairs) { |(name, n), i| p([i, name]) }   # => [0, "a"]
                                                               # => [1, "b"]
p(Array.inject(pairs, 0) { |acc, (k, v)| acc + v })            # => 3
Array.each(Array[[1, 2]]) { |a, b, c| p([a, b, c]) }           # => [1, 2, nil]
```

### Rest parameter

`|a, *rest|` (and `|a, *rest, z|`, `|*all|`) collects the remaining arguments, or the remaining elements of a destructured Tuple or Array, in a new Array, as `a, *rest = x` does. `|*all|` alone does not destructure.

```ruby
Array.each(Array[[1, 2, 3]]) { |a, *rest| p([a, rest]) }      # => [1, [2, 3]]
Array.each(Array[[1, 2, 3]]) { |a, *rest, z| p([a, rest, z]) } # => [1, [2], 3]
Array.each(Array[[1, 2, 3]]) { |*all| p(all) }                # => [[1, 2, 3]]
```

### Parameter count

A block with no parameters ignores its arguments. Otherwise, a block called with the wrong number of arguments raises `ArgumentError` while running. With a rest parameter, only fewer arguments than the other parameters is wrong.

```ruby
Integer.times(2) { puts "hi" }      # => hi
                                    # => hi
```

```ruby error
Array.each_with_index(Array["a"]) { |x| p(x) }   # !> ArgumentError: block takes 1 parameter(s) but was given 2
```

### Scope

A block sees and can assign the enclosing local variables.

```ruby
sum = 0
Array.each(Array[1, 2, 3]) { |x| sum += x }
p(sum)               # => 6
```

### `yield` and optional blocks

`yield(args...)` calls the block given to the current function. A `yield` outside a function is a syntax error. A function that contains `yield` must get a block at every call.

```ruby error
def each_twice(xs)
  Array.each(xs) { |x| yield x; yield x }
end
each_twice(Array[1, 2])   # !> each_twice uses `yield` but no block is given
```

`block_given?` tells whether the current function got a block. A function that checks it may be called without one.

```ruby
def info(msg = nil) = puts(block_given? ? yield : msg)
info("plain")                 # => plain
info { "from block" }         # => from block
```

- **Branch analysis.** The checker knows for each call whether a block was given, so it analyzes only the branch taken. This holds for `block_given?` under `&&`, `||`, and `!` as well.
- **A `yield` that should be unreachable.** A `yield` reached without a block (or `&b` to a call that needs a block) is an error at the `type` level. While running it raises `LocalJumpError`, which cannot be rescued.

### Passing a block on: `&b`

`def f(xs, &b) = Array.map(xs, &b)` passes the function's own block to another call. `&` alone works too. `b` is used only as `&b`.

```ruby
def twice(xs, &b) = Array.map(xs, &b)
p(twice(Array[1, 2]) { |x| x * 2 })      # => [2, 4]
def each_pair(h, &) = Hash.each(h, &)
each_pair(Hash[a: 1]) { |k, v| p([k, v]) }   # => [:a, 1]
```

- **Calling without a block.** As in Ruby, a function that only passes its block on may be called without one. If nothing then reaches a call that needs a block, it is an error at the `type` level.
- **`break`.** A `break` in the passed block ends the call the block was written for (`twice(...)` above).

```ruby error
def twice(xs, &b) = Array.map(xs, &b)   # !> the block passed on is missing here, and this call needs one
p(twice(Array[1, 2]))
```

### `next`, `break`, and `return`

The three ways out are Ruby's.

| Form | What it ends | Value |
|---|---|---|
| `next [v]` | the current block call | `v` (default `nil`) is the block's value |
| `break [v]` | the call the block was given to | `v` (default `nil`) is that call's value |
| `return [v]` | the enclosing **function** | `v` is the function's value |

```ruby
xs = Array[1, 2, 3, 4]
p(Array.map(xs) { |x| next 0 if x % 2 == 0; x })   # => [1, 0, 3, 0]
p(Array.each(xs) { |x| break x if x > 2 })          # => 3
p(Array.each(xs) { |x| x })                         # => [1, 2, 3, 4]
def first_big(xs)
  Array.each(xs) { |x| return x if x > 2 }
  nil
end
p(first_big(xs))                                    # => 3
```

- **Inside a `while`.** Inside a `while` in the block, `break` leaves the `while`.
- **Type.** The checker adds the `break` values to the call's result type.

> [!NOTE]
> A block's parameters and locals belong to the enclosing function's frame. When a block is handed to a function that runs it **later, on a thread** (a concurrent-ruby style `post { ... }`), it reads the values as they are when the thread runs (the last value of a loop variable). In Ruby a block's parameters are fresh for each call. The difference is observable only with threads (see `TODO.md`).

## once

`once { ... }` gives the block's value. The block runs the first time that place in the program is reached, and later passes through it give the same value, for the whole program and every thread. It is Sake's way to compute a table or a named value once, since there are no value constants.

```ruby
def table = once { puts "computing"; Array.map(Array[1, 2, 3]) { |i| i * i } }
p(table)             # => computing
                     # => [1, 4, 9]
p(table)             # => [1, 4, 9]
Array.push(table, 16)
p(table)             # => [1, 4, 9, 16]
```

- **Shared.** The value is shared, as Ruby's constants are. As above, an Array kept by `once` can still be changed.
- **Re-entry.** A block that reaches its own `once` again while computing it is a program error: `SystemStackError`.
- **Type.** For the checks before running, its type is the union of the block's results over every call that may compute it.

```ruby error
def loop_once = once { loop_once }
p(loop_once)         # !> SystemStackError: once: the block reached its own once again while computing it
```
