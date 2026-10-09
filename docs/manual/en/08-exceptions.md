# Exceptions and errors

## Exceptions

```ruby
ParseError = Exception.new(:line)        # fields: message, line

begin
  raise ParseError.new("empty", 1)
rescue ParseError => e
  ParseError.line(e)
rescue KeyError, IndexError => e
  Exception.message(e)
rescue => e                              # any rescuable exception
  raise                                  # re-raise
else
  ...                                    # when nothing was raised
ensure
  ...                                    # always, once
end
```

- **Exception types.** `class Name < Exception` with `attr_reader field` (or `Name = Exception.new(:field, ...)`) declares an exception type. It is a Struct type whose first field is `message`, so `Name.new("msg", ...)`, `Name.message`, `Name.field`, and `@field` work as for other Struct types. Exception types have no hierarchy.
- **Built-in exception types.** These are raised by operations, each with only `message`: `RuntimeError`, `ArgumentError`, `TypeError`, `KeyError`, `IndexError`, `ZeroDivisionError`, `RangeError`, `IOError`, `EOFError`, `RegexpError`, `FloatDomainError`, `EncodingError`, `ThreadError`, `NoMatchingPatternError`, `Math::DomainError`.
- **`raise` forms:**
  - `raise "msg"` raises `RuntimeError`.
  - `raise T, "msg"` raises `T.new("msg")`, where T has no fields besides `message`.
  - `raise value` raises an exception value.
  - A bare `raise` re-raises inside a rescue clause.
- **`rescue`.** `rescue A, B => e` catches the listed types only, since there is no hierarchy. `rescue => e`, `rescue StandardError => e`, and `rescue Exception => e` catch every rescuable exception; `e` is a union, so narrow it with `case e in A ...`.
- **Reading the message.** `Exception.message(e)` reads the message of any exception value. For an exception raised by a built-in operation it is Ruby's text (`divided by 0`); the report of an unrescued one also names the operation (`ZeroDivisionError: Arithmetic./: divided by 0`).
- **Program errors.** `SystemStackError`, `LocalJumpError`, and `NotImplementedError` cannot be rescued, and naming them in `rescue` is a static error. `TypeError` (an operation given a value of the wrong type) and `NoMatchingPatternError` can be rescued, as in Ruby: the checks before running stop the type mistakes they report ([Overview](01-overview.md)), and a run-time check that fails, for instance in a program run with `--strict=0`, raises an exception like any other.
- **Other forms.** `def f ... rescue ... end`, `expr rescue fallback`, and `retry` work as in Ruby. `ensure` runs once, when the begin block is left.
- **Exception flow.** The type inference tracks which explicitly raised types may leave each function:
  - `rescue` (level 1) reports a rescue clause for a type that the begin body never raises. Built-in kinds such as `ZeroDivisionError` can come from ordinary operations, so they are always assumed possible.
  - `unrescued` (level 4) reports a `raise` that may reach the top level.
- **Uncaught exceptions.** An uncaught exception ends the program like a runtime error: `FILE:LINE: in FUNCTION: ParseError: message`.
- **Deadlock.** When every thread is waiting (a `Queue.pop` with nothing left to push, a `Mutex.synchronize` inside itself), the program ends with Sake's `ThreadError`.

## Kinds of static error

Static errors are reported all together, sorted by position, and nothing runs.

- syntax errors (from Prism);
- undefined types, operations, and functions;
- wrong argument counts;
- a block passed where none is taken, or missing where one is required;
- calls on values;
- forbidden constructs: `send`, `public_send`, `__send__`, `method_missing`, `define_method`, the `eval` family, `instance_variable_get`/`set`, `const_get`/`set`, `binding`, `self`, and `@x` outside a function of a Struct type;
- unsupported syntax;
- duplicate definitions;
- literal type mismatches in `T[...]`;
- the items selected by `--strict` (by default, values whose type does not fit).

## Kinds of runtime error

| Kind | Raised by |
|---|---|
| `TypeError` | an operation received a value of the wrong type; an operator not supported by the left operand's type; a typed Array write; multiple assignment from a value other than a Tuple or an Array |
| `IndexError` | a Tuple index outside the Tuple; `Array.fetch` outside the Array; writing past the end of an Array of T |
| `ArgumentError` | block parameter count; negative sizes; `Integer ** negative`; comparing incomparable values in `sort` |
| `ZeroDivisionError` | Integer `/` or `%` by zero |
| `KeyError` | `Hash.fetch` of a missing key; a Record pattern naming a missing field |
| `RangeError` | an operation that needs a finite Range, given an endless one |
| `RegexpError` | `Regexp.new` with an invalid pattern |
| `IOError` | `File.read`, `Dir.mkdir`, and the like failing (Ruby: `Errno::ENOENT` & co.; the message is Ruby's); socket errors (refused, reset, unknown host) |
| `EOFError` | a read at the end of the stream (`IO.read(io, n)` and the like) |
| `FloatDomainError` | converting NaN or Infinity to Integer |
| `Math::DomainError` | e.g. `Math.sqrt(-1)` |
| `SystemStackError` | recursion deeper than 10,000 |
| `ThreadError` | deadlock |
