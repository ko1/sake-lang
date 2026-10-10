# Kernel

Kernel is the set of operations that any part of a program calls by name alone: `puts(x)`, `Integer(s)`, `loop { }`, without writing `Kernel.puts(x)` (that form works too; a name resolves to the current namespace first, then to the top-level functions, then to Kernel, see [Functions](../04-functions.md)). As with every other namespace, the argument types are checked statically, and a value of the wrong type is a `type` problem.

Here are output and input (`puts`, `print`, `p`, `pp`, `format`, `gets`, `warn`), the strict numeric conversions (`Integer`, `Float`, `Rational`, `Complex`), showing and copying values (`to_s`, `inspect`, `dup`, `equal?`), control (`loop`, `block_given?`, `once`), random numbers and time (`rand`, `srand`, `sleep`), and the process (`exit`, `at_exit`, `system`, `ARGV`, `PROGRAM_NAME`). `raise` is syntax, not an operation: see [Exceptions and errors](../08-exceptions.md). `Math.PI` and `Float.INFINITY` are read as operations too, but belong to the chapters of their namespaces (Sake has no value constants; a named value is made with `once`).

## puts

`Kernel.puts(*Any)`

Writes each argument on its own line to the output and returns nil (Ruby's `puts`). A String is written as is (a newline is added when it has none), nil is an empty line, any other value is written in its `to_s` form. Arrays and Tuples are written one element per line, nested ones flattened (an empty Array is an empty line). Without arguments it writes an empty line. A Struct value is written with its type's own `to_s(x)` when there is one, otherwise in the `#<struct ...>` form that `p` uses ([to_s](#to_s)).

```ruby
puts("a", 1, :sym)
# => a
# => 1
# => sym
puts(Array[1, [2, 3]])
# => 1
# => 2
# => 3
puts(Hash["k" => 1], 1..3)
# => {"k" => 1}
# => 1..3
```

## print

`Kernel.print(*Any)`

Writes each argument in its `to_s` form with no newline between them and returns nil (Ruby's `print`). Arrays and Tuples are written as `[1, 2]` (not one element per line as `puts` does); nil is the empty string.

```ruby
print("a", 1, nil, "\n")        # => a1
print(Array[1, 2], [3, 4], "\n") # => [1, 2][3, 4]
```

## p

`Kernel.p(*Any)`

Writes each argument in its `inspect` form, one per line (Ruby's `p`): Strings quoted, Symbols as `:sym`, Struct values as `#<struct Point x=1, y=2>`, exception values as `#<KeyError: msg>`. The result is Ruby's: the value when there is one argument, a Tuple of the arguments when there are several, nil when there are none (the checker sees it the same way). A Struct value whose type defines `inspect(x)` is written with that.

```ruby
x = p(1, "a")
# => 1
# => "a"
p(x)                             # => [1, "a"]
p(p())                           # => nil
Point = Struct.new(:x, :y)
p(Point.new(1, 2))               # => #<struct Point x=1, y=2>
p(Hash["a" => 1], Set[1], 2r)
# => {"a" => 1}
# => Set[1]
# => (2/1)
```

## pp

`Kernel.pp(Any)`

Writes one value in the form `p` uses and returns the value. Ruby's `pp` wraps long values; in Sake it is the same as `p(x)`.

```ruby
a = pp(Array[1, {k: 2}])        # => [1, {k: 2}]
p(a)                             # => [1, {k: 2}]
```

## format, sprintf

`Kernel.format(String, *Any)`

`Kernel.sprintf(String, *Any)`

Makes a String with Ruby's `format` directives: `%d`, `%f`, `%e`, `%g`, `%x`, `%o`, `%b`, `%c`, `%s`, `%p`, `%%`, with width, precision and the flags `-`, `+`, `0`. `%s` uses a value's `to_s` (a Struct type's own `to_s(x)` included), `%p` its `inspect`. `%<name>d` and `%{name}` take one Hash with Symbol keys (`Hash[a: 1]`); a Record `{a: 1}` is not a Hash and is refused (`ArgumentError: one hash required`). Too few or too many arguments, a value that is not a number for a numeric directive, and a missing key are all `ArgumentError`.

```ruby
p(format("%05.2f|%-4s|%p|%x", 3.14159, :ab, "q", 255))   # => "03.14|ab  |\"q\"|ff"
p(sprintf("%+d %s %s", 3, nil, true))                     # => "+3  true"
p(format("%<n>d-%{s}", Hash[n: 1, s: "x"]))               # => "1-x"
Point = Struct.new(:x, :y)
p(format("%s", Point.new(1, 2)))                          # => "#<struct Point x=1, y=2>"
```

```ruby error
p(format("%d %d", 1))            # !> ArgumentError: Kernel.format: too few arguments
```

## gets

`Kernel.gets()`

Reads one line from standard input and returns it as a String including its trailing newline, or nil at the end of the input. The result is `String | nil`, so `String.chomp(gets)` without a check is stopped by `--strict` (level 2) as a `nil` problem; test it first, `if (line = gets)`. Unlike Ruby's `gets` it takes no separator argument.

```ruby
line = gets
p(line)                          # => "3\n"
if (rest = gets)
  p(String.split(String.chomp(rest), " "))   # => ["1", "2"]
end
p(gets)                          # => nil
```

```ruby error
p(String.chomp(gets))            # !> argument 1 may be nil
```

## warn

`Kernel.warn(*Any)`

Writes each argument to the error output (stderr) in the form `puts` uses and returns nil. Without arguments it writes nothing. Reporting a usage mistake and then calling `exit` is the typical pair.

```ruby error
warn("usage: prog FILE")         # !> usage: prog FILE
exit(2)
```

## Integer

`Kernel.Integer(String|Integer|Float)`

Ruby's strict `Integer()`. A String must be a decimal integer or one with a `0x`, `0b`, `0o` or `0` prefix; `_` separators and surrounding whitespace are allowed, anything else (`"12abc"`, `""`, `"1e3"`) is an `ArgumentError`. A Float is truncated, an Integer returned as is. `String.to_i` silently reads as far as it can; this operation fails unless the whole String is an integer. For a NaN or infinite Float, Ruby's `FloatDomainError` currently escapes and ends the program (it cannot be rescued).

```ruby
p(Integer("42"))                 # => 42
p(Integer(" 0x1f "))             # => 31
p(Integer("1_000"))              # => 1000
p(Integer(3.9))                  # => 3
p(String.to_i("12abc"))          # => 12
```

```ruby error
p(Integer("12abc"))              # !> ArgumentError: Kernel.Integer: invalid value for Integer(): "12abc"
```

## Float

`Kernel.Float(String|Integer|Float)`

Ruby's strict `Float()`. A String must be a decimal real (`"1e3"`, `"1_0.5"`, surrounding whitespace allowed), otherwise `ArgumentError`. An Integer becomes a Float, a Float is returned as is.

```ruby
p(Float("1.5"))                  # => 1.5
p(Float("1e3"))                  # => 1000.0
p(Float(2))                      # => 2.0
```

```ruby error
p(Float("abc"))                  # !> ArgumentError: Kernel.Float: invalid value for Float(): "abc"
```

## Rational

`Kernel.Rational(Integer|Rational|String, [Integer|Rational])`

Ruby's `Rational(a, b = 1)`. `a` is an Integer, a Rational, or a String of the form `"1/3"`, `"0.75"` or `"3"`; `b` is an Integer or a Rational; the result is `a / b` reduced. Floats are not accepted (a `type` problem statically; use `Float.to_r` or `Float.rationalize`). A String that cannot be read is an `ArgumentError`, a `b` of 0 a `ZeroDivisionError`.

```ruby
p(Rational(3, 6))                # => (1/2)
p(Rational("0.75"))              # => (3/4)
p(Rational("1/3"))               # => (1/3)
p(Rational(1r/2, 1r/4))          # => (2/1)
```

```ruby error
p(Rational(1, 0))                # !> ZeroDivisionError: Kernel.Rational: divided by 0
```

## Complex

`Kernel.Complex(Integer|Float|Rational, [Integer|Float|Rational])`

Ruby's `Complex(re, im = 0)`. The real and imaginary parts are real numbers; Strings are not accepted (use `String.to_c`).

```ruby
p(Complex(1, 2))                 # => (1+2i)
p(Complex(1.5))                  # => (1.5+0i)
p(Complex(1r, 2.5))              # => ((1/1)+2.5i)
```

## to_s

`Kernel.to_s(Any)`

The String that `puts`, interpolation `"#{x}"` and `format`'s `%s` use for a value. A String is itself, nil is `""`, a Symbol is its name, numbers use Ruby's `to_s`, and Arrays, Tuples, Hashes, Sets, Records and Ranges are written as `inspect` writes them. A Struct value uses its type's `to_s(x)` when the type defines one (also one that comes from an included module), otherwise `#<struct T ...>`. It corresponds to Ruby's `x.to_s`; since Sake has no method calls on values, this one operation turns a value of any type into a String.

```ruby
class Temp
  attr_reader celsius
  def to_s(t) = "#{@celsius}C"
end
t = Temp.new(21)
p(to_s(t))                       # => "21C"
puts("now #{t}")                 # => now 21C
p(to_s(nil))                     # => ""
p(to_s(Array[1, "a"]))           # => "[1, \"a\"]"
p(to_s(:sym))                    # => "sym"
```

## inspect

`Kernel.inspect(Any)`

The String that `p` writes for a value (Ruby's `x.inspect`): a String with quotes and escapes, a Symbol as `:sym`, nil as `"nil"`, a container with its elements inspected. A Struct value uses its type's `inspect(x)` when the type defines one (also from an included module), otherwise `#<struct T f=v, ...>`; an exception value is `#<E: message>`. `p`, `pp`, `format`'s `%p` and the elements inside a container are shown with it.

```ruby
module Pretty
  def inspect(v) = "<pretty>"
end
class Box
  include Pretty
  attr_reader n
end
p(inspect("a\n"))                # => "\"a\\n\""
p(inspect(nil))                  # => "nil"
p(inspect(Box.new(1)))           # => "<pretty>"
p(Array[Box.new(1)])             # => [<pretty>]
```

## dup

`Kernel.dup(Any)`

A shallow copy of a value (Ruby's `obj.dup`): an Array, Tuple, Hash, Set, Record, Struct value or String becomes a new container holding the same elements (the elements' containers are shared). An Integer, Symbol, nil, true/false or Range is returned as is. The type is the original's. A Struct value whose type defines `dup(x)` gets that function (the result has the function's type). Inside a type's functions, copy an element with `Kernel.dup(@items)`: a bare `dup` resolves to the type's own.

```ruby
a = Array[Array[1], Array[2]]
b = dup(a)
Array.push(b, Array[3])
Array.push(b[0], 9)
p(a)                             # => [[1, 9], [2]]
p(b)                             # => [[1, 9], [2], [3]]
class Box
  attr_accessor items
  def dup(b) = Box.new(Kernel.dup(@items))
end
x = Box.new(Array[1])
y = dup(x)
Array.push(Box.items(y), 2)
p(Box.items(x))                  # => [1]
p(Box.items(y))                  # => [1, 2]
```

## equal?

`Kernel.equal?(Any, Any)`

True when the two arguments are the same value (the same object), Ruby's `a.equal?(b)`. `==` compares contents; this is identity. The result of `dup` is `==` to the original but not `equal?`. Equal Integers, Symbols, nil and true/false are always identical; two String literals written separately are not.

```ruby
a = Array[1]
b = a
p(equal?(a, b))                  # => true
p(a == dup(a))                   # => true
p(equal?(a, dup(a)))             # => false
p(equal?("a", "a"))              # => false
p(equal?(:a, :a))                # => true
```

## loop

`Kernel.loop() { }`

Runs the block until a `break` (Ruby's `loop`). The result is the `v` of `break v` (nil for a bare `break`); the checker sees the union of the values of every `break` in the block. `next` goes on to the next round. A `loop` without a `break` never returns (Sake has no `StopIteration` to end it).

```ruby
i = 0
v = loop do
  i += 1
  next if i < 3
  break i * 10
end
p(v)                             # => 30
p(loop { break })                # => nil
```

## block_given?

`Kernel.block_given?()`

True when the current function was called with a block. A function that checks `block_given?` may be called without one (a function that only `yield`s requires it, see [Functions](../04-functions.md)). The checker folds `block_given?` in a condition to its value for each call, so a branch that reaches `yield` is not run for a call without a block. At the top level it is false.

```ruby
def each_or(x)
  return yield(x) if block_given?
  x
end
p(each_or(1))                    # => 1
p(each_or(1) { |v| v + 10 })     # => 11
p(block_given?)                  # => false
```

## once

`Kernel.once() { }`

The block's value. The block runs once, the first time that place in the program is reached, and the value is kept for the rest of the program: every later evaluation (another call, another thread) gets the same value. Since Sake has no value constants, this is how a table or a named value is computed once: `def table = once { ... }`. What is kept is the value itself; an Array can still be changed afterwards (as Ruby's constants can). A block that reaches its own `once` again while computing it ends the program with `SystemStackError` (not rescuable).

```ruby
def table = once { puts("computing"); Array[1, 2, 3] }
p(table)
# => computing
# => [1, 2, 3]
p(table)                         # => [1, 2, 3]
p(equal?(table, table))          # => true
```

```ruby error
def rec(n) = once { rec(n) }
rec(1)                           # !> SystemStackError: once: the block reached its own once again while computing it
```

## rand

`Kernel.rand([Integer|Float])`

Ruby's `rand`. Without an argument, a Float at least 0.0 and below 1.0. With an Integer `n`, an Integer at least 0 and below `|n|` (the checker sees an Integer; as in Ruby an `n` of 0 gives a Float instead, so do not pass 0). With a Float `x`, a Float at least 0.0 and below `x`. A Range is not accepted (a `type` problem statically).

```ruby
f = rand
p(f >= 0.0 && f < 1.0)           # => true
i = rand(6)
p(i >= 0 && i < 6)               # => true
g = rand(2.5)
p(g >= 0.0 && g < 2.5)           # => true
```

## srand

`Kernel.srand([Integer])`

Sets the seed of the random numbers and returns the previous seed (an Integer), Ruby's `srand`. Without an argument it picks a new seed at random. The same seed gives the same sequence of `rand`.

```ruby
srand(7)
a = Array.map(Array[1, 2, 3]) { rand(1000) }
srand(7)
b = Array.map(Array[1, 2, 3]) { rand(1000) }
p(a == b)                        # => true
p(srand(1))                      # => 7
```

## sleep

`Kernel.sleep([Integer|Float|Rational])`

Pauses for the given number of seconds and returns the seconds slept, rounded to an Integer (Ruby's `sleep`). Without an argument it pauses forever (until another thread wakes it).

```ruby
p(sleep(0))                      # => 0
p(sleep(1r/100))                 # => 0
```

## exit

`Kernel.exit([Integer|Boolean])`

Ends the program with the status `status`: an Integer as is, true as 0, false as 1, 0 when left out. No `rescue` catches it (`rescue => e` lets it through), while the `ensure` clauses on the way out and the `at_exit` blocks run. The checker treats the code after `exit` as unreachable (its type is `[]`: it returns no value).

```ruby
at_exit { puts("at_exit") }
begin
  exit(true)
rescue => e
  puts("not caught")
ensure
  puts("ensure")                 # => ensure
end
puts("not reached")              # => at_exit
```

```ruby error
puts("start")                    # !> start
exit(3)
puts("not reached")
```

## at_exit

`Kernel.at_exit() { }`

Registers the block and returns nil. The registered blocks run when the program ends (normally, by `exit`, or by an uncaught exception), the last registered first (Ruby's `at_exit`).

```ruby
at_exit { puts("bye 1") }
at_exit { puts("bye 2") }
puts("main")
# => main
# => bye 2
# => bye 1
```

## system

`Kernel.system(String, *String)`

Runs a command as a child process and waits for it (Ruby's `system`). One argument goes through the shell; with several, the first is the command and the rest its arguments. The result is true for exit status 0, false for any other status, and nil when the command could not be started (`Boolean | nil`). The child's output goes straight to the output; to get it as a String use `Open3.capture2` or `capture3`.

```ruby
p(system("echo", "hi"))
# => hi
# => true
p(system("false"))               # => false
p(system("/no/such/command"))    # => nil
```

## ARGV

`Kernel.ARGV()`

The program's command-line arguments, an Array of Strings. It is written like Ruby's constant but is an operation, and every use gives the same Array, so shortening it with `Array.shift(ARGV)` or an `OptionParser`'s `parse!` shows in every later `ARGV`. Its Strings are frozen: an operation that changes one in place (`String.concat`, ...) is a `TypeError`.

```ruby
p(ARGV)                          # => []
Array.push(ARGV, "x")
p(ARGV)                          # => ["x"]
p(equal?(ARGV, ARGV))            # => true
```

## PROGRAM_NAME

`Kernel.PROGRAM_NAME()`

The path of the running program (its first file), Ruby's `$0`. Unlike the other Kernel operations, a bare `PROGRAM_NAME` is read as a type name and rejected (`type PROGRAM_NAME cannot be used as a value`), so write `Kernel.PROGRAM_NAME`.

```ruby
p(String.end_with?(Kernel.PROGRAM_NAME, ".sake"))   # => true
```
