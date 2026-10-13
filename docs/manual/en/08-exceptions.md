# Exceptions and errors

Exceptions in Sake are written as in Ruby: `raise` throws one, `begin`/`rescue`/`else`/`ensure` receives it, and `retry` starts over. Two things differ. An exception type is an ordinary class, and types are grouped by a module, not by inheritance. And the checker tracks, before the program runs, which exceptions may leave each function. The first half of this chapter is how to write exceptions; the second half lists the kinds of static and runtime error. The format of the reports is in [Overview](01-overview.md).

## Exceptions

```ruby
ParseError = Exception.new(:line)        # fields: message, line

def parse(s)
  raise ParseError.new("empty", 1) if s == ""
  Integer(s)
end

begin
  parse("")
rescue ParseError => e
  p(ParseError.line(e))                  # => 1
rescue KeyError, IndexError => e
  p(Exception.message(e))
rescue => e                              # any rescuable exception
  raise                                  # re-raise
else
  p(:ok)                                 # when nothing was raised
ensure
  p(:ensure)                             # => :ensure
end
```

The shape is Ruby's. The sections below go through declaring an exception type, the forms of `raise` and `rescue`, what the checker looks at, and what happens when nothing catches an exception.

### Declaring an exception type

An exception type is a class ([Classes](07-classes.md)). Its first field is `message`, followed by the fields you declare. As for any other class, `Name.new("msg", ...)`, `Name.message(e)`, `Name.field(e)`, and `@field` inside a function all work.

```ruby
class ParseError < Exception
  attr_reader line
end

e = ParseError.new("empty", 1)
p(ParseError.message(e))                 # => "empty"
p(ParseError.line(e))                    # => 1
p(e)                                     # => #<ParseError: empty line=1>
```

- **Two spellings.** `class Name < Exception` with `attr_reader field` lines, and its shorthand `Name = Exception.new(:field, ...)`, declare the same thing.
- **Grouped by a module.** `class B < A` is a copy, and `rescue A` does not catch B. To group exception types, include a module in them and write `rescue M` ([below](#grouping-with-a-module)). The built-in types follow Ruby's parents: `rescue IndexError` also catches `KeyError`, `rescue IOError` `EOFError`, `rescue RangeError` `FloatDomainError`, and `rescue ArgumentError` `Math::DomainError`. A class declared under a built-in exception, such as `class ConvError < RangeError`, is caught by `rescue RangeError` too.
- **Built-in exception types.** These are raised by built-in operations, and each has only `message`: `RuntimeError`, `ArgumentError`, `TypeError`, `KeyError`, `IndexError`, `ZeroDivisionError`, `RangeError`, `IOError`, `EOFError`, `RegexpError`, `FloatDomainError`, `EncodingError`, `ThreadError`, `NoMatchingPatternError`, `Math::DomainError`. Each is described in the reference's [Exceptions](ref/Exceptions.md).

### Forms of raise

`raise` is syntax, not an operation. It has four forms.

| Written | Raises |
|---|---|
| `raise "msg"` | `RuntimeError` |
| `raise T, "msg"` | `T.new("msg")`; T has no fields besides `message` |
| `raise value` | that exception value |
| `raise` (inside a rescue clause) | the exception being handled, again |

```ruby
begin
  raise "boom"
rescue => e
  p(e)                                   # => #<RuntimeError: boom>
end
begin
  raise KeyError, "no such key"
rescue KeyError => e
  p(e)                                   # => #<KeyError: no such key>
end
begin
  raise IndexError.new("out")
rescue IndexError => e
  p(Exception.message(e))                # => "out"
end
```

A type with fields besides `message` cannot be raised with `raise T, "msg"`. Build the value and write `raise T.new(...)`.

```ruby error
E = Exception.new(:code)
raise E, "msg"                           # !> E has fields besides message; raise it with `raise E.new(...)`
```

### rescue

`rescue A, B => e` catches the listed types. A name that is a module catches the exception types that include it, and a built-in parent (`IndexError` and the others) also catches its Ruby subclasses.

To catch everything, write `rescue => e`. `rescue StandardError => e` and `rescue Exception => e` mean the same. The type of `e` is then a union, so to handle each type differently, narrow it with `case e in A ...` ([Control flow and patterns](06-control.md)).

```ruby
def check(x)
  raise ArgumentError, "negative" if x < 0
  x
end
begin
  check(-1)
rescue ArgumentError, ZeroDivisionError => e
  v = case e
      in ArgumentError then "argument"
      in ZeroDivisionError then "zero"
      end
  p(v)                                   # => "argument"
end
```


### Grouping with a module

A Ruby library makes its exceptions children of `class Error < StandardError` and catches them together with `rescue MyLib::Error`. In Sake the parent is a module that each exception type includes. `rescue M => e` catches every exception type that includes M (also through a module that includes M), and `e` is their union. A function of the module, `M.f(e)`, dispatches to each type's definition.

```ruby
module ParseFailure
  def describe(e) = "parse: " + Exception.message(e)
end
class BadToken < StandardError
  include ParseFailure
end
class Unclosed < StandardError
  include ParseFailure
  attr_reader line
end
def parse(s)
  raise BadToken, "bad token" if s == "?"
  raise Unclosed.new("unclosed", 3) if s == "("
  s
end
begin
  parse("(")
rescue ParseFailure => e
  p(ParseFailure.describe(e))            # => "parse: unclosed"
  case e
  in Unclosed then p(Unclosed.line(e))   # => 3
  in BadToken then p("token")
  end
end
```

A module is not raised (`raise ParseFailure, "x"` is a static error). When the Ruby code raises the parent class itself, add one concrete type that includes the module. Level 1 stops a `rescue A` for a type an earlier `rescue M` already catches; a `rescue M` whose begin body raises none of the module's types is an `unused-rescue` warning.

```ruby error
module ParseFailure
end
class BadToken < StandardError
  include ParseFailure
end
def parse(s)
  raise BadToken, "bad token" if s == "?"
  s
end
begin
  parse("?")
rescue ParseFailure => e
  p(1)
rescue BadToken => e                     # !> rescue BadToken: an earlier rescue (ParseFailure) already catches it [rescue]
  p(2)
end
```

### Reading the message

`Exception.message(e)` reads the message of an exception value of any type. Use it when the type of `e` is a union. When the type is known, `ParseError.message(e)` does the same.

The message of an exception raised by a built-in operation is Ruby's text. The report of one that ends the program unrescued also names the operation (`ZeroDivisionError: Arithmetic./: divided by 0`).

```ruby
begin
  p(1 / 0)
rescue ZeroDivisionError => e
  p(Exception.message(e))                # => "divided by 0"
end
```

### Backtrace and cause

`Exception.backtrace(e)` gives the calls in effect when the exception was raised, as an Array of Strings in Ruby's form `"FILE:LINE:in 'FUNCTION'"`, innermost first. It is nil for an exception value that was never raised (made with `E.new` only). Raising it again with `raise e` or a bare `raise` keeps the backtrace of the first raise.

`Exception.cause(e)` gives the exception a rescue clause was handling when `e` was raised, or nil. Both may be nil, so under `--strict` check them before use.

Unlike Ruby, lines inside built-in operations (Ruby's `'Integer#/'` and the like) are not in the list.

```ruby
def parse(s)
  Integer(s)
rescue ArgumentError
  raise "not a number: #{s}"
end

begin
  parse("x")
rescue => e
  bt = Exception.backtrace(e)
  p(Array.map(bt) { |l| String.sub(l, /\A.*?:/, "") }) if bt   # => ["4:in 'parse'", "8:in '<main>'"]
  c = Exception.cause(e)
  p(c) if c                                # => #<ArgumentError: invalid value for Integer(): "x">
end
p(Exception.backtrace(RuntimeError.new("not raised")))   # => nil
```

### Program errors

`SystemStackError`, `LocalJumpError`, and `NotImplementedError` are program errors and cannot be rescued. Naming one in `rescue` is a static error.

```ruby error
begin
  p(1)
rescue SystemStackError => e             # !> SystemStackError cannot be rescued: it is a program error, which the checks before running report
  p(e)
end
```

`TypeError` (an operation given a value of the wrong type) and `NoMatchingPatternError` can be rescued, as in Ruby. Most of the type mistakes they report, however, are stopped by the checks before running ([Overview](01-overview.md)). The next example stops before running at the default level, as a `type` problem. Run with `--strict=0`, `len(1)` raises a `TypeError`, which is rescued like any other exception, and the message is `"argument 1 must be String, got Integer"`.

```ruby error
def len(x)
  String.length(x)                       # !> String.length: argument 1 must be String, but is Integer [type]
end
begin
  len(1)
rescue TypeError => e
  p(Exception.message(e))
end
```

### Other forms

`def f ... rescue ... end`, the modifier `expr rescue fallback`, and `retry` work as in Ruby. `ensure` runs once, when the begin block is left. It runs when `return` or `exit` leaves the block, too.

```ruby
def safe_div(a, b)
  a / b
rescue ZeroDivisionError
  0
end
p(safe_div(6, 0))                        # => 0

n = Integer("x") rescue -1
p(n)                                     # => -1

tries = 0
begin
  tries += 1
  raise "again" if tries < 3
rescue RuntimeError
  retry
end
p(tries)                                 # => 3
```

### Checking the flow of exceptions

The checker tracks which explicitly raised types may leave each function. Two items use this (the levels are in [Overview](01-overview.md)).

- **`unused-rescue` (a warning at every level).** The checker reports a rescue clause for a type that the begin body never raises. Built-in kinds such as `ZeroDivisionError` can come from ordinary operations, so they are always assumed possible and never reported. The program still runs: a defensive `rescue` is normal, and whether anything raises depends on the whole program (a library's `rescue` for what only some apps raise). `--strict=2,unused-rescue` makes it an error. The related `rescue` item (level 1) stops a clause an earlier clause already covers.
- **`unrescued` (level 4).** The checker reports a `raise` that may reach the top level without being rescued, as `raise: RuntimeError may reach the top level without being rescued [unrescued]`.

```ruby
ParseError = Exception.new(:line)
begin
  p(Integer("1"))                        # => 1
rescue ParseError => e                   # warning: the begin body never raises ParseError [unused-rescue]
  p(e)
end
```

### Uncaught exceptions

An exception nothing rescues ends the program in the same form as a runtime error: `FILE:LINE: in FUNCTION: ParseError: message`. The exit status is 1.

```ruby error
def check(x)
  raise ArgumentError, "x must be positive" if x <= 0   # !> ArgumentError: x must be positive
  x
end
check(0)
```

### Deadlock

When every thread is waiting, the program ends with Sake's `ThreadError`. A `Queue.pop` with nothing left to push, a `Mutex.synchronize` taken again inside itself, and `Thread.join`s waiting for each other are the cases ([Built-in operations](09-builtins.md)).

```ruby error
q = Queue.new
Queue.pop(q)                             # !> ThreadError: deadlock: every thread is waiting
```

## Kinds of static error

Static errors are reported all together, sorted by position, and nothing runs. The exit status is 2. The format is in [Overview](01-overview.md).

| Kind | Example |
|---|---|
| syntax error | anything Prism cannot parse |
| undefined type, operation, or function | `String.upcse(s)` |
| wrong argument count | |
| block mismatch | a block passed where none is taken, or missing where one is required |
| a call on a value | `name.upcase` |
| forbidden construct | see below |
| unsupported syntax | appendix [Differences from Ruby](a1-ruby.md) |
| duplicate definition | |
| literal type mismatch in `T[...]` | `Integer["a"]` |
| an item selected by `--strict` | by default, a value whose type does not fit |

The forbidden constructs are `send`, `public_send`, `__send__`, `method_missing`, `define_method`, the `eval` family, `instance_variable_get`/`set`, `const_get`/`set`, `binding`, `self`, and `@x` outside a function of a class. Each either leaves the callee undecided until run time or names a concept Sake does not have (instance state).

## Kinds of runtime error

A runtime error stops the program at the line of the operation. The exit status is 1. Each is an exception, so it can be rescued. The exceptions are `SystemStackError` and the deadlock detected when every thread is waiting (the `ThreadError` of re-entering `Mutex.synchronize` can be rescued).

| Kind | Raised by |
|---|---|
| `TypeError` | an operation given a value of the wrong type (see below) |
| `IndexError` | an index outside the bounds (see below) |
| `ArgumentError` | block parameter count; negative sizes; `Integer ** negative`; comparing incomparable values in `sort` |
| `ZeroDivisionError` | Integer `/` or `%` by zero |
| `KeyError` | `Hash.fetch` of a missing key; a Record pattern naming a missing field |
| `RangeError` | an operation that needs a finite Range, given an endless one |
| `RegexpError` | `Regexp.new` with an invalid pattern |
| `IOError` | a file, directory, or socket operation failing (see below) |
| `EOFError` | raised by no built-in (see below) |
| `EncodingError` | an operation on Strings whose encodings do not fit |
| `FloatDomainError` | converting NaN or Infinity to Integer |
| `Math::DomainError` | e.g. `Math.sqrt(-1)` |
| `SystemStackError` | recursion deeper than 10,000 |
| `ThreadError` | deadlock |

- **`TypeError`.** An operation received a value of the wrong type. An operator not supported by the left operand's type. A write of another type into a typed Array. Multiple assignment from a value other than a Tuple or an Array.
- **`IndexError`.** A Tuple index outside the Tuple. `Array.fetch` outside the Array. Writing past the end of an Array of T (`xs[5] = 3`; the gap would be nil).
- **`IOError`.** `File.read`, `Dir.mkdir`, and the like failing. In Ruby these are `Errno::ENOENT` and co., and the message is Ruby's. Socket errors (refused, reset, unknown host) are `IOError` too.
- **`EOFError`.** No built-in raises it. A read at the end gives nil or `""`, and Ruby's EOFError is folded into `IOError`. The type exists, so it can be named in `rescue`.

```ruby error
h = Hash["a" => 1]
p(Hash.fetch(h, "b"))                    # !> KeyError: Hash.fetch: key not found: "b"
```
