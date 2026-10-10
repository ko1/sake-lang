# Exceptions

The built-in exception types. Built-in operations raise them when they fail at run time, and a program raises them itself with `raise E, "msg"`. Each is declared as a Struct type with the single field `message` ([Struct types](../07-structs.md)), so the operations of any Struct type apply:

- `E.new(message)` makes an exception value (`message` is usually a String; its type is not checked). `raise E, "msg"` is short for `raise E.new("msg")`, and `raise E` uses the type's name as the message. `raise "msg"` raises a `RuntimeError`. `raise` is syntax, described in [Exceptions and errors](../08-exceptions.md).
- `E.message(e)` reads the message and `E.set_message(e, s)` replaces it (`e.E.message` is the same read). The old `E.get_message` is rejected with a hint to use `E.message`. `Exception.message(e)` reads the message of an exception value of any type: use it where the type is a union, as after `rescue => e`.
- `rescue E => e` catches the listed types only. Exception types have no hierarchy, so `rescue IOError` does not catch `EOFError` and `rescue IndexError` does not catch `KeyError` (unlike Ruby). Several types are `rescue A, B => e`; every type is `rescue => e` (`rescue StandardError` and `rescue Exception` mean the same).
- `p(e)` prints `#<E: message>`, and `==` compares the fields.
- The message of an exception raised by a built-in operation is Ruby's text (`divided by 0`); the report of one that ends the program also names the operation (`ZeroDivisionError: Kernel.Rational: divided by 0`).
- A Ruby exception raised inside a built-in operation never escapes as a raw Ruby error with a backtrace: it becomes the Sake exception of the same kind, rescuable like any other, with Ruby's message (`Tuple` in place of Ruby's `Sake::Tuple`). Ruby's `EOFError`, `Errno::*` and `ClosedQueueError` become `IOError`, `FrozenError` becomes `TypeError`, `Math::DomainError` stays `Math::DomainError`, and Ruby's own `RuntimeError` (`String.undump` of a bad String) becomes `ArgumentError`, so that Sake's `RuntimeError` comes only from a program's `raise`.

`Math::DomainError` is a built-in exception type too: it can be written in `rescue Math::DomainError => e` and `raise Math::DomainError, "msg"`, but being a nested name it cannot be written as `Math::DomainError.new(...)` or `Math::DomainError.message(e)` (read it with `Exception.message(e)`). `Math.sqrt(-1)`, `Math.log(-1)`, `Integer.sqrt(-1)`, `Integer.digits(-1)` and `x ** 0.5` with a negative Float `x` (`-8.0 ** 0.5 is not a real number (a negative base with a fractional exponent)`; Ruby gives a Complex) raise it. `SystemStackError` (too deep a recursion, a `once` reaching itself), `LocalJumpError` and `NotImplementedError` are program errors: they cannot be rescued, and naming them in `rescue` is a static error.

Most type mistakes (`TypeError`) and pattern misses (`NoMatchingPatternError`) are stopped before running as `type` problems, so at run time they reach only the places the checker could not see (an operation taking `Any`, a program run with `--strict=0`).

```ruby
begin
  Integer("x")
rescue ArgumentError, TypeError => e
  puts(Exception.message(e))       # => invalid value for Integer(): "x"
end
e = KeyError.new("missing")
p(e)                               # => #<KeyError: missing>
p(KeyError.message(e))             # => "missing"
KeyError.set_message(e, "other")
p(Exception.message(e))            # => "other"
p(e == KeyError.new("other"))      # => true
```

## RuntimeError

`RuntimeError.new(message)`

The type that `raise "msg"` (a `raise` without a type) raises. No built-in operation raises it on its own: only `Thread.raise(t, msg)` does, in the other thread, where `Thread.value(t)` or `Thread.join(t)` deliver it (a Ruby `RuntimeError` inside an operation, as from `String.undump`, becomes `ArgumentError`). It is the type for a program's "other failures". Accordingly the checker rejects a `rescue RuntimeError` whose body cannot raise one (`the begin body never raises RuntimeError [rescue]`, with the hint that `Thread.value` / `Thread.join` count only in a program that calls `Thread.raise`).

```ruby
begin
  raise "plain"
rescue RuntimeError => e
  p(e)                             # => #<RuntimeError: plain>
end
```

```ruby error
begin
  String.undump("\"abc")
rescue RuntimeError => e           # !> rescue RuntimeError: the begin body never raises RuntimeError [rescue]
  p(e)
end
```

## ArgumentError

`ArgumentError.new(message)`

An argument's value is not acceptable. Raised by: `Integer`, `Float` and `Rational` for a String they cannot read; `format` for too few or too many arguments, a value that is not a number, or a missing key; `rand(0)` and a negative bound; a negative size (`Array.first(a, -1)`); `Integer ** negative Integer`; `Regexp.new(s, flags)` with bad flags; `Time.new`, `Time.at`, `Time.now` with a value out of range or a bad zone; `Integer.to_s(n, base)` with a bad base; `String.unpack` with a bad format; `String.ljust` with an empty pad, `tr` with a reversed range, `String.undump` of a String that is not a dumped one (`unterminated dumped string`, Ruby's RuntimeError); `ENV.set("", v)` and `Process.clock_gettime(999)` (an argument the OS refuses); `Zlib` on damaged data (`incorrect header check`); a block called with the wrong number of arguments. Elements that cannot be compared (`Array.sort`, `max`, `min`, `Tuple.max`, `Set.sort`, and the `*_by` forms through their block's results) are a static `type` problem when the checker sees the element types; the run-time `ArgumentError` is reached only where it cannot, as with a NaN.

```ruby
begin
  Array.sort(Array[1.0, Float.NAN])
rescue ArgumentError => e
  puts(Exception.message(e))       # => cannot compare elements of types Float
end
begin
  2 ** -1
rescue ArgumentError => e
  puts(Exception.message(e))       # => Integer ** negative Integer (2 ** -1) is an error; for a Rational, write 2r ** -1
end
begin
  String.undump("\"abc")
rescue ArgumentError => e
  puts(Exception.message(e))       # => unterminated dumped string
end
```

```ruby error
Array.sort(Array[1, "a"])          # !> Array.sort: elements compared in order may be (Integer, String), which cannot be compared [type]
```

## TypeError

`TypeError.new(message)`

A value of the wrong type: an operation given an argument of another type, an operator the left operand's type does not support, a write of another type into a typed Array (`Integer[]`, ...), multiple assignment from a value that is neither a Tuple nor an Array, an in-place change of a frozen String (a Hash key, a Set element, a Symbol's name, an element of `ARGV`: `cannot change this String in place: it is a Hash key, a Set element, a Symbol's name, or a program argument`), `Exception.message` given a value that is not an exception. A Ruby `TypeError` or `NoMethodError` inside an operation is this type too, where the checker could not see the element types: `Array.pack(Array["a"], "C")` (`no implicit conversion of String into Integer`), `Range.first(1.0..2.0, 2)` (`can't iterate from Float`), `ENV.replace` with a non-String key or value under `--strict=0` (`keys and values must be String, got String => Integer`). The checks before running stop most of these statically; at run time only the places the checker let through reach it.

```ruby
begin
  Exception.message(1)
rescue TypeError => e
  puts(Exception.message(e))       # => Exception.message: argument 1 must be an exception, got Integer
end
begin
  Array.pack(Array["a"], "C")
rescue TypeError => e
  puts(Exception.message(e))       # => no implicit conversion of String into Integer
end
```

```ruby error
Array.push(Integer[], "a")         # !> Array.push: an element must be Integer, but is String
```

## KeyError

`KeyError.new(message)`

A missing key: `Hash.fetch` (without a default and a block), `Hash.fetch_values`, `ENV.fetch`, a Record pattern naming a field the Record lacks. A missing key in `format`'s `%<name>` is an `ArgumentError`.

```ruby
h = Hash["a" => 1]
begin
  Hash.fetch(h, "b")
rescue KeyError => e
  puts(Exception.message(e))       # => key not found: "b"
end
p(Hash.fetch(h, "b", 0))           # => 0
```

## IndexError

`IndexError.new(message)`

An index out of range: `Array.fetch`; an index outside a Tuple that reaches run time (a literal index is stopped statically); a write past the end of an Array of T (`Integer[1, 2][5] = 1`, since the gap would be nil); `Array.insert` past the end (`index 3 is past the end of the Array (length 1); the gap would be nil`, where Ruby fills the gap); `MatchData.begin(m, 5)` for a group the Regexp lacks (`index 5 out of matches`); `Array.transpose` with rows of different lengths; `String.byteindex` with an offset inside a character. `x[k]` gives nil outside the range and never raises.

```ruby
def at(t, i) = t[i]
begin
  at([1, 2], 5)
rescue IndexError => e
  puts(Exception.message(e))       # => index 5 is outside a Tuple of length 2
end
begin
  Array.fetch(Array[3, 1], 9)
rescue IndexError => e
  puts(Exception.message(e))       # => index 9 outside of array bounds: -2...2
end
```

## ZeroDivisionError

`ZeroDivisionError.new(message)`

Division of an Integer (or a Rational) by zero: `/`, `%`, `Integer.divmod`, `div`, `modulo`, `remainder`, `ceildiv`, `Rational(a, 0)`, `Rational.quo`. A Float's `1.0 / 0` is Infinity, as in Ruby, not an exception.

```ruby
begin
  7 % 0
rescue ZeroDivisionError => e
  puts(Exception.message(e))       # => divided by 0
end
p(1.0 / 0)                         # => Infinity
```

## RangeError

`RangeError.new(message)`

A value outside what can be represented: an endless Range given to an operation that needs a finite one (`Range.to_a(1..)`, `Range.last(1..)`, `Range.sort`, ...), a beginless one to `Range.first` (`cannot get the first element of beginless range`), an Integer that is no character in `Integer.chr` (`256 out of char range`), a negative exponent in `Integer.pow(2, -1, 7)`, a Complex initial value in `Range.sum`.

```ruby
begin
  Range.to_a(1..)
rescue RangeError => e
  puts(Exception.message(e))       # => cannot do this on an endless Range 1..
end
begin
  Integer.chr(256)
rescue RangeError => e
  puts(Exception.message(e))       # => 256 out of char range
end
```

## FloatDomainError

`FloatDomainError.new(message)`

NaN or Infinity turned into an Integer or a Rational: `Float.to_i`, `Arithmetic.to_i`, `Arithmetic.round`, `floor`, `ceil`, `truncate`, `Float.to_r`, `Float.rationalize`, `Float.numerator`, `denominator`, `Kernel.Integer(x)`, `Kernel.Rational(x)`. The message is the value's name. All of them are rescuable.

```ruby
begin
  Float.to_i(Float.INFINITY)
rescue FloatDomainError => e
  puts(Exception.message(e))       # => Infinity
end
begin
  Float.to_r(Float.NAN)
rescue FloatDomainError => e
  puts(Exception.message(e))       # => NaN
end
begin
  Integer(Float.NAN)
rescue FloatDomainError => e
  puts(Exception.message(e))       # => NaN
end
```

## IOError

`IOError.new(message)`

A failure of input or output: the File and Dir operations (`File.read`, `File.write`, `File.open`, `Dir.mkdir`, `Dir.children`, ...; Ruby's `Errno::ENOENT` and company become this one type, with Ruby's message), an operation on a closed IO, `IO.size` of a stream that is not a file (`not a file`), the terminal operations (`IO.winsize`, ...) on an IO that is not a terminal (`not a terminal`), socket errors (connection refused, reset, a name that does not resolve, timeout), `Queue.push` to a closed Queue. A Ruby `EOFError` inside an operation becomes this type too, not Sake's `EOFError`.

```ruby
begin
  File.read("no-such-file")
rescue IOError => e
  puts(Exception.message(e))       # => No such file or directory @ rb_sysopen - no-such-file
end
begin
  IO.size(IO.stdin)
rescue IOError => e
  puts(Exception.message(e))       # => not a file
end
q = Queue.new
Queue.close(q)
begin
  Queue.push(q, 1)
rescue IOError => e
  puts(Exception.message(e))       # => push to a closed Queue
end
```

## EOFError

`EOFError.new(message)`

A read at the end of the input. Ruby's `IO#readline` and the like raise it, but Sake's reading operations (`IO.read(io, n)`, `IO.gets`, `IO.getc`, `gets`) return nil at the end, so no built-in operation raises it (a Ruby `EOFError` inside an operation becomes `IOError`). A program can use it for its own "no more input". It is a type of its own, which `rescue IOError` does not catch.

```ruby
def next_token(xs) = Array.shift(xs) || raise(EOFError, "no more tokens")
begin
  next_token(Array[])
rescue EOFError => e
  puts(Exception.message(e))       # => no more tokens
end
```

## EncodingError

`EncodingError.new(message)`

A mistake in a String's encoding: a byte that `String.encode` cannot convert, concatenating or comparing Strings of incompatible encodings, and whatever else makes Ruby raise an `EncodingError` (`Encoding::UndefinedConversionError`, ...) inside an operation.

```ruby
begin
  String.encode("\xff", "UTF-16")
rescue EncodingError => e
  puts(Exception.message(e))       # => "\xFF" on UTF-8
end
```

## RegexpError

`RegexpError.new(message)`

An invalid regular expression: a literal with interpolation `/#{s}/` whose pattern is invalid, `Regexp.new(s)` with an invalid pattern, a String operation given an invalid pattern String (`String.match?("a+c", "+")`). A pattern written directly in a literal is a syntax error, stopped before running.

```ruby
s = "("
begin
  r = /#{s}/
rescue RegexpError => e
  puts(Exception.message(e))       # => end pattern with unmatched parenthesis: /(/
end
begin
  Regexp.new("(")
rescue RegexpError => e
  puts(Exception.message(e))       # => end pattern with unmatched parenthesis: /(/
end
begin
  String.match?("a+c", "+")
rescue RegexpError => e
  puts(Exception.message(e))       # => target of repeat operator is not specified: /+/
end
```

## NoMatchingPatternError

`NoMatchingPatternError.new(message)`

No branch of a `case`/`in` matches the value and there is no `else`, or `x => pattern` does not match. The checker finds from the value's type that no branch can match and stops the program as a `type` problem (the example below), so it is raised at run time only where the checker let the code through, for instance in a program run with `--strict=0`. The message describes the value that did not match.

```ruby error
def kind(x)
  case x
  in Integer then "int"
  end
end
kind("s")                          # !> case/in: no `in` branch matches String
```

## ThreadError

`ThreadError.new(message)`

A mistake in the use of threads: `Mutex.lock` or `Mutex.synchronize` on a Mutex the thread already holds, `Mutex.unlock` on a Mutex it does not hold, `Thread.join` of the current thread. A deadlock, every thread waiting, also ends the program with Sake's `ThreadError` ([Exceptions and errors](../08-exceptions.md)).

```ruby
m = Mutex.new
Mutex.lock(m)
begin
  Mutex.lock(m)
rescue ThreadError => e
  puts(Exception.message(e))       # => deadlock; recursive locking
end
begin
  Mutex.unlock(Mutex.new)
rescue ThreadError => e
  puts(Exception.message(e))       # => Attempt to unlock a mutex which is not locked
end
begin
  Thread.join(Thread.current)
rescue ThreadError => e
  puts(Exception.message(e))       # => Target thread must not be current thread
end
```
