# Functions and blocks

## Functions

```ruby
def area(w, h) = w * h
def describe(n)
  return "negative" if n < 0
  Integer.to_s(n)
end
```

- **Parameters.** Required positional parameters, then optional ones with a default (`def f(a, b = 1, c = b + 1)`), as in Ruby: a default is evaluated at the call, after the earlier parameters, when the call gives fewer arguments. Keyword parameters come last, required (`w:`) or with a default (`h: w`), and mix freely with optional positional ones: `def greet(name, greeting = "Hello", punct: "!")` is called as `greet("Ruby", punct: "?")`. Since every call's callee is known before running, `k: v` goes to its parameter by name when the program is checked: an unknown or repeated keyword, or a missing required one, is an error, and `k: v` to a function without keyword parameters is an error (there is no implicit Hash argument; write `Hash[k: v]` or a Record `{k: v}`). A few built-ins take Ruby's keywords too, checked the same way (`Time.at(t, in: "+09:00")`, `Dir.glob(pat, base: dir)`; the built-in list shows them as `[k: T]`). `f(k:)` passes the variable `k`, as in Ruby. Arguments are evaluated in the order written. A block parameter `&b` (or `&`) may only be passed on (below).
- **`*rest` and `**opts`.** `*rest` after the optional parameters collects the remaining positional arguments in a new Array (so its elements share one type, the union of everything any call passes; to keep a type per position, pass a Tuple: `notify(stock, ["AAPL", 120])`, then `name, price = event`). `**opts` at the end collects the keywords that are not parameters in a Hash of Symbol keys. Both are built at the call, since the callee is known (a function with `**opts` accepts any keyword, so a misspelled one is no longer an error there). Parameters after `*rest` and nameless `*` / `**` are rejected; passing the collected keywords on with `f(**opts)` is not available yet. A call gives between the required positional count and all of them (any number with `*rest`); a mixin function's definitions must agree on the counts, the keyword names, and on having `*rest` / `**opts`.
- **Return value.** The value of the last expression, or of `return expr`. `return a, b` returns the Tuple `[a, b]`.
- **Polymorphism.** Functions are polymorphic. A function works on any arguments its operations accept. Type errors surface at the operation that fails.
- **Local variables.** Each function has its own scope, with no access to top-level locals. As in Ruby, reading a local before its first assignment gives `nil`.
- **Recursion.** Allowed. A depth over 10,000 calls raises `SystemStackError`. `bin/sake` runs the program on a thread with a large stack so that this limit, not Ruby's stack, applies. Long backtraces are shortened.

## Blocks

A block can be passed to a built-in operation or to a user function that yields.

```ruby
Array.map(xs) { |x| x * 2 }
Array.each(pairs) do |k, v| ... end
Integer.times(3) { p it }
```

- **Not values.** Blocks are second-class. They cannot be stored or returned. `proc`, `lambda`, and `->` are not available.
- **Passing on.** `def f(xs, &b) = Array.map(xs, &b)` passes the function's own block to another call (`&` alone works too). `b` is used only as `&b`; a `break` in the block ends the call the block was written for. As in Ruby, a function that only passes its block on may be called without one; passing none to a call that needs a block is then an error at the `type` level.
- **Optional blocks.** `block_given?` tells whether the current function got a block. A function that checks it may be called without one: `def info(msg = nil) = puts(block_given? ? yield : msg)`. The checker knows for each call whether a block was given, so it analyzes only the branch taken (also under `&&`, `||`, and `!`); a `yield` (or `&b` to a call that needs a block) reached without a block is an error at the `type` level, and raises `LocalJumpError` (not rescuable) when it runs.
- **Parameters.** `|a, b|` lists plain names. `it` and `_1` … `_9` work as in Ruby.
- **Destructuring.** If a block declares two or more parameters and receives a single Tuple or Array, its elements become the parameters (missing ones are nil, extra ones are dropped, as in Ruby). A parameter can also be taken apart itself: `|(name, n), i|`, `|acc, (k, v)|`.
- **Rest parameter.** `|a, *rest|` (and `|a, *rest, z|`, `|*all|`) collects the remaining arguments, or the remaining elements of a destructured Tuple or Array, in a new Array, as `a, *rest = x` does. `|*all|` alone does not destructure.
- **Parameter count.** A block with no parameters ignores its arguments. Otherwise, a block called with the wrong number of arguments (fewer than its other parameters, with a rest parameter) raises `ArgumentError`.
- **Scope.** A block sees and can assign the enclosing local variables.
- **`next [v]`.** Ends the current block call with value `v` (default `nil`).
- **`return`.** Inside a block, `return` returns from the enclosing **function**, as in Ruby.
- **`break`.** Inside a block, `break` (or `break v`) ends the call the block was given to, whose value is then `v` (or nil), as in Ruby: `Array.each(xs) { |x| break x if x > 10 }`. Inside a `while` in the block, `break` leaves the `while`. The checker adds the break values to the call's result type.

`yield(args...)` calls the block given to the current function. It is a static error outside a function.

> [!NOTE]
> A block's parameters and locals belong to the enclosing function's frame. When a block is handed to a function that runs it **later, on a thread** (a concurrent-ruby style `post { ... }`), it reads the values as they are when the thread runs (the last value of a loop variable). In Ruby a block's parameters are fresh for each call. The difference is observable only with threads (see `TODO.md`).

## once

`once { ... }` gives the block's value. The block runs the first time that place in the program is reached, and later calls there give the same value, for the whole program and every thread. It is Sake's way to compute a table or a named value once, since there are no value constants: `def crc_table = once { ... }`. The value is shared, as Ruby's constants are (an Array kept by `once` can still be changed). A block that reaches its own `once` again while computing it is a program error (`SystemStackError`). For the checks before running, its type is the union of the block's results over every call that may compute it.
