# Control flow and patterns

Sake's control flow is Ruby's. `if` and `while`, the modifier forms, an early `return`, and `case` are written as in Ruby. There are three differences. Iteration is written with block-taking operations such as `Array.each`, not with `for`. `case` branches on patterns with `in`, not with `when`. And a condition does more than test a value: it **narrows** the type the checker tracks for a variable. This narrowing is how a value that may be nil, or a union such as `Integer | String`, is used.

The `# => value` comments in this chapter are the real output of `bin/sake --strict=2`.

## Conditions

`if` / `elsif` / `else`, `unless` / `else`, and the ternary `c ? a : b` are as in Ruby. Each is an expression whose value is that of the branch taken. When no branch is taken, the value is `nil`.

```ruby
n = 5
r = if n > 10 then "big" elsif n > 3 then "mid" else "small" end
p(r)                                 # => "mid"
p(if n > 10 then "big" end)          # => nil
p(unless n > 10 then "not big" end)  # => "not big"
p(n > 3 ? "yes" : "no")              # => "yes"
```

### Truthiness

Only `nil` and `false` are false. Every other value is true, including `0`, `""`, and an empty Array. `&&`, `||`, and `!` are as in Ruby; `&&` and `||` return the last operand they evaluated.

```ruby
p(0 ? "truthy" : "falsy")            # => "truthy"
p("" ? "truthy" : "falsy")           # => "truthy"
p(nil ? "truthy" : "falsy")          # => "falsy"
p(nil || "default")                  # => "default"
p(0 && "zero is truthy")             # => "zero is truthy"
```

### Modifier forms

A condition may follow the statement: `stmt if c`, `stmt unless c`, `stmt while c`, and `stmt until c`.

```ruby
n = 5
puts("positive") if n > 0            # => positive
i = 0
i += 1 while i < 3
p(i)                                 # => 3
i -= 1 until i == 0
p(i)                                 # => 0
```

## Loops

`while` and `until` are as in Ruby. Inside a loop, `break` leaves the loop and `next` starts the next iteration. The value of a loop is `nil`, except that `break v` leaves it with the value `v`.

```ruby
i = 0
out = Array[]
r = while i < 10
  i += 1
  next if i % 2 == 0
  break if i > 7
  Array.push(out, i)
end
p(out)                               # => [1, 3, 5, 7]
p(r)                                 # => nil
```

### Iteration is a block-taking operation

`for` is not supported. To walk a sequence, write a block-taking operation such as `Array.each`, `Integer.times`, or `Range.each` ([Functions and blocks](04-functions.md)). Inside the block, `break v` ends the call the block was given to, with the value `v`; `next v` ends the current block call with `v`.

```ruby
xs = Array[3, 8, 12, 5]
big = Array.each(xs) { |x| break x if x > 10 }
p(big)                               # => 12
squares = Array[]
Integer.times(4) { |i| next if i == 0; Array.push(squares, i * i) }
p(squares)                           # => [1, 4, 9]
```

`loop { ... }` repeats until a `break`, and the value of the `break` is its value.

```ruby
i = 0
r = loop do
  i += 1
  break i * 10 if i == 3
end
p(r)                                 # => 30
```

### Forms that are not supported

`for` and `begin ... end while` are static errors.

```ruby error
for i in 1..3                        # !> `for` is not supported; iterate with an operation
  p(i)
end
```

## Leaving a function early

`return` ends the function at once. `return v` makes `v` the function's value, and `return a, b` returns the Tuple `[a, b]`. The modifier form `return v if c` is the way to dispose of a precondition before the main case. A `return` inside a block also returns from the enclosing **function**, not from the block ([Functions and blocks](04-functions.md)).

```ruby
def sign(n)
  return "negative" if n < 0
  return "zero" if n == 0
  "positive"
end
p(sign(-2))                          # => "negative"
p(sign(0))                           # => "zero"
p(sign(7))                           # => "positive"
```

## case / in

`case x` followed by `in P then ...` branches runs the first branch whose pattern matches. A branch's body may follow `then` on the same line or start on the next line. When no branch matches and there is no `else`, the result is the runtime error `NoMatchingPatternError`.

```ruby
def kind(v)
  case v
  in nil then "nothing"
  in true | false then "bool"
  in Integer | Float then "number"
  in String
    "text"
  end
end
p(kind(nil))                         # => "nothing"
p(kind(true))                        # => "bool"
p(kind(2.5))                         # => "number"
p(kind("s"))                         # => "text"
```

`case`/`when` is not supported. Ruby's `when` dispatches on the receiver's `===`; Sake has no `===`, and a match compares type tags and values. What can be written as a pattern is the table in the last section of this chapter, "Pattern matching".

```ruby error
x = 1
case x                               # !> `case`/`when` is not supported (Ruby's `===` dispatches on the receiver); match with `case x` / `in Type`
when 1 then puts("one")
end
```

## Narrowing by a condition

The checker infers the type of each local variable over the whole program. A condition **narrows** that type inside the branch taken: inside `if x`, `x` is not nil; inside `if x in Integer`, `x` is an Integer. This is how a value that may be nil (`nil | String`) or a union (`Integer | String`) is used without a `type` or `nil` report.

### Removing nil

A local variable `x` is narrowed in the following places (the same table as in the nil section of [Values and types](03-values.md)).

| Form | Where `x` is narrowed |
|---|---|
| `if x` / `while x` / `x && …` | non-nil in the branch taken when `x` is truthy |
| `x != nil` / `x == nil` | nil or non-nil in the matching branch |
| `!x` / `unless x` | the same, with the branches swapped (`if !x … else` is non-nil in the else) |
| `return unless x`, `next unless x`, `break unless x`, and other early exits | non-nil after the statement |
| `String.size(x)`, or any built-in operation taking `x` as an argument | after the call, a type that the operation accepts (it checks its arguments while running) |

```ruby
def greet(name = nil)
  if name
    "Hello, " + String.upcase(name)
  else
    "Hello"
  end
end
p(greet("ko1"))                      # => "Hello, KO1"
p(greet())                           # => "Hello"
```

Without the `if name`, the checker reports the call `greet()`. It analyzes a function for each call, so the report names the call that led there.

```ruby error
def greet(name = nil)
  String.upcase(name)                # !> String.upcase: argument 1 must be String, but is nil [type]
end
p(greet("ko1"))
p(greet())
```

An early exit is a common way to remove nil. `while x` narrows the same way.

```ruby
def size_or_zero(xs)
  x = Array.first(xs)
  return 0 unless x
  String.size(x)
end
p(size_or_zero(Array["abc"]))        # => 3
p(size_or_zero(Array[]))             # => 0
```

### Fields are not narrowed

Only **local variables** are narrowed. A field read such as `Node.next(n)` is mutable, so a second read inside `if Node.next(n)` may still be nil. Copy the field into a local variable first, then test the local.

```ruby
class Node
  attr_accessor value, :next
end
def next_value(n)
  nx = Node.next(n)
  if nx
    Node.value(nx)
  else
    0
  end
end
a = Node.new(1, nil)
b = Node.new(2, a)
p(next_value(b))                     # => 1
p(next_value(a))                     # => 0
```

```ruby error
class Node
  attr_accessor value, :next
end
def next_value(n)
  if Node.next(n)
    Node.value(Node.next(n))         # !> Node.value: argument 1 must be Node, but is nil [type]
  else
    0
  end
end
p(next_value(Node.new(1, nil)))
```

### Narrowing to a type

`x in Integer` is true when `x` is an Integer, and inside that branch `x` is narrowed to Integer. `elsif` and `else` see the types that are left. The `in` branches of `case x` work the same way.

```ruby
def pick(flag) = flag ? 1 : "one"
def describe(x)
  if x in Integer
    x + 1
  elsif x in String
    String.size(x)
  else
    x
  end
end
p(describe(pick(true)))              # => 2
p(describe(pick(false)))             # => 3
```

### Which level reports it

A value that may be nil, passed to an operation without a check, is reported as the `nil` item at level 2 (`--strict`). The nil of a miss (`x[k]`, `Array.first`, `Hash.dig`, and the like) is the `index-nil` item at level 3. The levels and items are in [Overview and running](01-overview.md). A nil that was not reported still stops the program at run time, with a `TypeError` from the operation that received it.

## Pattern matching

`x in P` is true when `x` matches the pattern `P`. `x => P` asserts it: it raises `NoMatchingPatternError` when `x` does not match, and binds a Record pattern's fields. The `in P` branches of `case x` take the same patterns.

| Pattern | Matches |
|---|---|
| a type name: `Integer`, `String`, `Tuple`, `Hash`, `Point`, `Record`, `IO`, ... | a value of that type (its type tag) |
| `nil`, `true`, `false`, `1`, `"s"`, `:ok` | an equal value of the same type |
| `P \| Q` | either |
| `{x:, y: name}` | a Record with those fields; binds the locals `x` and `name` |
| `[P, Q]` | a Tuple of that length whose positions match `P` and `Q` (nested patterns allowed) |
| `x` (a bare name inside `[...]`, or alone) | anything; binds the local `x` |

Patterns outside this table (`*rest`, find patterns, pins `^x`, guards, and the `Integer => n` form) are not supported and are static errors ([Differences from Ruby](a1-ruby.md)).

### No dispatch

A match compares type tags and values. There is no `===`, so `case`/`when` is not supported. A type-name pattern looks at the value's type tag only; the B of `class B < A` does not match `A` ([Classes](07-classes.md)).

### Binding

Record and Tuple patterns take the elements out into local variables. `{x:}` binds field `x` to a local of the same name; `{y: name}` binds field `y` to the local `name`.

```ruby
pt = {x: 3, y: 4}
pt => {x:, y: why}
p(x)                                 # => 3
p(why)                               # => 4
pair = [1, "one"]
case pair
in [n, s] then p([s, n])             # => ["one", 1]
end
p((pair in [Integer, String]))       # => true
p((pair in [String, Integer]))       # => false
```

### Narrowing

In `if x in Integer`, and in each `in` branch of `case x`, a local `x` is narrowed to the matching types. The `else` branch, and each later branch, sees the types that are left. This is how a union such as `Integer | String` is used without a `type` report ("Narrowing to a type" in the previous section).

```ruby
def pick(flag) = flag ? 1 : "one"
def f(x)
  case x
  in Integer then x + 1
  else String.size(x)
  end
end
p(f(pick(true)))                     # => 2
p(f(pick(false)))                    # => 3
```

### Exhaustiveness

A `case` without `else` that may leave a possible **type** unmatched is reported as `type`. The set of types is closed, so the checker can check this.

```ruby error
def show(x)
  case x                             # !> case/in: no `in` branch matches String [type]
  in Integer then "int"
  end
end
p(show(41))
p(show("abc"))
```

Symbol literals are tracked as values. When `op` only ever holds those literals, `case op in :add ... in :sub` is complete.

```ruby
def name(op)
  case op
  in :add then "plus"
  in :sub then "minus"
  end
end
p(name(:add))                        # => "plus"
p(name(:sub))                        # => "minus"
```

When literal branches may leave some **values** of an open type unmatched (some String, Integer, or a Symbol made at run time), the report is the `exhaustive` item (level 3). The program may well be correct, and `NoMatchingPatternError` still stops it if not. The next example runs at level 2 and is reported at `--strict=3`.

```ruby error
def name(op)
  case op                            # !> case/in: no `in` branch matches some values of String [exhaustive]
  in "add" then "plus"
  in "sub" then "minus"
  end
end
p(name("add"))
p(name(String.downcase("SUB")))
```

### Assertion: x => P

After `x => P`, a local `x` is narrowed to the matching types, as in an `in` branch. Inside `initialize`, a field `@x` of the new instance is narrowed the same way. It is how a fact such as "a port is an Integer" is written where the value is stored: `p => Integer`, then `@port = p`.

- A value that surely does not match is reported as `type` (level 1).
- A value that may not match (another type may come) is checked when it runs, and reported only as `exhaustive` (level 3). The failure is `NoMatchingPatternError`, which can be rescued, as in Ruby.
- `x => P` is itself a check for nil, so a value that may be nil is not reported. It is treated like `Array.fetch`, which checks for a missing index.

```ruby error
x = "abc"
x => Integer                         # !> `=> Integer`: the value is String, which does not match [type]
```

```ruby
def pick(flag) = flag ? 1 : nil
x = pick(true)
x => Integer
p(x + 1)                             # => 2
```

### Parentheses

As in Ruby, `x in P` must be in parentheses when it is an argument: `p((x in Integer))`. `x in T ? a : b` and `cond && x in T` also parse differently from what they look like; write `(x in T)`.

```ruby
x = 1
p((x in Integer))                    # => true
r = (x in Integer) ? "int" : "other"
p(r)                                 # => "int"
p(x > 0 && (x in Integer))           # => true
```

```ruby error
x = 1
p(x in Integer)                      # !> syntax error: unexpected 'in'; expected a `)` to close the arguments
```
