# Overview and running programs

Sake (/seɪk/) is an experimental language designed for the sake of finding a new place for types. It keeps Ruby's syntax, but you write the type on each **operation**, never on a variable, a parameter, a return value, or a field.

```ruby
name = "sake"
puts(String.upcase(name))      # => SAKE
```

Ruby's spelling, `name.upcase`, is a static error, and its hint gives the form above.

```ruby error
name = "sake"
puts(name.upcase)              # !> method call on a value `name.upcase` is not allowed
```

This book is the reference manual of the language as implemented by the v0 interpreter (`bin/sake`). For a guided introduction see [tutorial.md](https://github.com/ko1/sake-lang/blob/main/docs/tutorial.md); for a short summary to hand to a language model, [cheatsheet.md](https://github.com/ko1/sake-lang/blob/main/docs/cheatsheet.md) (about 10k tokens). The design notes and their reasons are in `DESIGN.md` (in Japanese).

## Principles

Nearly every property of Sake follows from four principles. Each chapter of this part works out their consequences.

1. **Ruby syntax.** A Sake program is a Ruby program as parsed by Prism. Sake accepts a subset of Ruby's syntax and gives some constructs a different meaning.
2. **Types are written on operations, not on bindings.** An operation is called with its type, `Type.op(subject, args...)`. Variables, parameters, return values, and fields carry no type annotations.
3. **Call targets are fixed before running.** `String.upcase(s)` names one function. A module's mixin function `M.f(x)`, a listed call `(A|B).f(x)` and an operator `a + b` choose by the type of the first argument, but the set of candidates is fixed before running. The candidates are the types that include `M`, the listed types, or the operator table. A type outside the set is reported before running. Nothing searches the receiver at run time (no `method_missing`, no reflection), so a misspelled name (`String.upcse`) or a wrong number of arguments is also reported for the whole program before it starts.
4. **Values carry type tags, and every operation checks them.** A wrong type is reported as an error at the operation that received it, with the line number. These checks are always enabled.

The checks of principle 4 catch what the checks before running let through. In the next example, `h["b"]` gives nil for the missing key, and `String.upcase` stops at that line.

```ruby error
h = Hash["a" => "x"]
puts(String.upcase(h["b"]))    # !> TypeError: String.upcase: argument 1 must be String, got nil
```

## Running

`bin/sake` checks a program first and runs it when no problem is found. Options select checking only, or how strictly to check.

```
bin/sake FILE.sake              # check, then run
bin/sake -c FILE.sake           # check only
bin/sake --strict FILE.sake     # check more strictly (level 2), then run
bin/sake --strict=3 FILE.sake   # levels 0-4, or items: --strict=type,nil
bin/sake --types FILE.sake      # experimental: print the inferred types instead of running
bin/sake --dump=ast FILE.sake   # print the resolved program (SakeAST)
```

| Exit status | Meaning |
|---|---|
| 0 | success |
| 1 | runtime error |
| 2 | problem found before running (nothing was executed) |

The interpreter is written in Ruby and needs Ruby 4.0 (tested with 4.0.2 and Prism 1.9.0). It has no other dependencies.

## Strictness (`--strict`)

`--strict` sets which problems stop the program before it runs. The checker infers the types of the whole program and sorts the problems it finds into **items** (`type`, `nil`, ...). A level is a set of items that stop the program. Whatever is not reported is still checked while running.

| Level | Option | Items added | Stops |
|---|---|---|---|
| 0 | `--strict=0` | (none) | what is always checked |
| 1 | default | `type`, `rescue` | a type that does not fit; a useless `rescue` |
| 2 | `--strict` | `nil`, `mixed` | an unchecked nil; types that met in a field |
| 3 | `--strict=3` | `index-nil`, `exhaustive` | the nil of a missed index; a `case` that is not exhaustive |
| 4 | `--strict=4` | `unrescued` | a `raise` that reaches the top level |

Each level includes the items of the levels below it.

### Always checked (level 0)

These problems stop the program before running at every level: syntax, names, argument counts, blocks, calls on values, forbidden syntax, and the literal types in `T[...]`.

### `type` (level 1)

A value whose type, other than nil, does not fit the operation. It is reported both when the type is certain (`"" + 1`) and when the value may have a type that does not fit (`pick() + 1` where `pick` returns 1 or `""`).

```ruby error
def half(n) = n / 2
puts(half("ten"))              # !> the operands are (String, Integer), which the left operand's type does not support [type]
```

The report points at `n / 2` inside `half`. Its hint, `reached by the call at line 2`, names the call that led there.

### `rescue` (level 1)

A `rescue` of an exception the begin body never raises. It covers the exception types the program declares, and `RuntimeError`. Built-in kinds such as `KeyError` and `ZeroDivisionError` can come from ordinary operations, so they are always assumed possible and never reported.

```ruby error
class ParseError < StandardError
end
begin
  p(10 / 2)
rescue ParseError              # !> the begin body never raises ParseError [rescue]
  p(0)
end
```

### `nil` (level 2)

A value that may be nil, used without a check. What is a `TypeError` while running at level 1 is reported before running at level 2.

```ruby error
words = String.split("a b", " ")
w = Array.find(words) { |x| x == "c" }
puts(String.upcase(w))         # !> argument 1 may be nil (nil | String) [nil]
```

The nil of a miss is excepted. A miss is the nil given by an index `x[k]`, by `Array.dig`, `Hash.dig`, `MatchData.begin`/`end`, and by these operations on an empty collection: `Array.first`, `last`, `pop`, `shift`, `min`, `max`, `minmax`, `at`, `slice`, `sample`, `delete_at`, `Set.first`, `min`, `max`, `min_by`, `max_by`. The `index-nil` item of level 3 covers them. How a nil is narrowed away is described in [Values and types](03-values.md).

### `mixed` (level 2; a warning at level 1)

`mixed` is a kind of `type` report. It is given when the failing types all appear, together with fitting ones, in one field of a class. The elements of a container held in a field count as well.

The checker gives a field one type per construction site ([Classes](07-classes.md)). When instances made at one place are used for different values, the types meet in that field. In the next example, the Heap that `make()` builds is used for Integers and for Strings.

```ruby error
class Heap
  attr_accessor items
  def initialize(h)
    @items = Array[]
  end
  def push(h, x) = Array.push(@items, x)
  def top(h) = Array.first(@items)
end
def make() = Heap.new(nil)
ints = make()
Heap.push(ints, 1)
strs = make()
Heap.push(strs, "a")
p(Heap.top(ints) + 1)          # !> the operands may be (nil, Integer), (String, Integer), which the left operand's type does not support [mixed]
```

Such a report is likely a meeting rather than a mistake, so it stops the program from level 2, and at level 1 it is printed as a warning. At level 1 the example above prints the warning, runs, and prints `2`.

The cost of this heuristic: a field that really got a wrong type at the same place is also `mixed`. For example, `Config.new("h", port)` where `port` is 80 on one call and `"eighty"` on another. Check such a value where it is stored, in `initialize` (`@port => Integer`).

### `index-nil` (level 3)

The nil of a miss (above), used without a check. The next program runs up to level 2 and prints `2`.

```ruby
xs = Array[1, 2, 3]
x = xs[0]
p(x + 1)                       # => 2
```

At level 3 it stops before running.

```
$ bin/sake --strict=3 index.sake
index.sake:3:3: error: Arithmetic.+: the operands may be nil, because x[k] (or `a, b = array`) gives nil when the element is missing [index-nil]
  hint: check the value first: `if x`, `while x`, `return unless x`, or `x != nil`
  hint: or use Array.fetch / Hash.fetch, which raise instead
```

### `exhaustive` (level 3)

A `case`/`in` that may get a value of an open type that no literal branch takes. An open type is one whose values cannot be listed: String, Integer, a Symbol not written as a literal, and so on. The next program runs up to level 2.

```ruby
def kind(s)
  case s
  in "a" then 1
  in "b" then 2
  end
end
p(kind(String.downcase("A")))  # => 1
```

```
$ bin/sake --strict=3 kind.sake
kind.sake:2:3: error: case/in: no `in` branch matches some values of String [exhaustive]
  hint: add an `else`, or `in` branches for the other values
  hint: reached by the call at line 7
```

### `unrescued` (level 4)

A `raise` that may reach the top level without being rescued. The item is meant for a program; a library's raises are meant for its callers, so it does not suit a library.

```ruby
def check(n)
  raise ArgumentError, "negative" if n < 0
  n
end
p(check(1))                    # => 1
```

```
$ bin/sake --strict=4 check.sake
check.sake:2:3: error: raise: ArgumentError may reach the top level without being rescued [unrescued]
  hint: rescue it, or check with a level below 4
```

### Naming items

Items can be named instead of a level.

- `--strict=type,nil` selects exactly these items.
- `--strict=2,index-nil` adds an item to a level.
- `--strict=3,-index-nil` removes an item from a level.

Each report ends with its item, such as `[type]`, which tells you which item to add or remove.

### How reports behave

- **Errors inside functions.** A report inside a polymorphic function adds a hint naming the call that led there (the `half` example above).
- **Unreached branches.** Branches are not evaluated, so a problem in a branch that never runs is still reported, as in Erlang's Dialyzer.
- **Internal errors.** If the type inference itself fails, the type checks are skipped with a warning, and the program runs.
- **Too many element pairs.** Comparing Arrays or Tuples (`<`, `<=>`, sorting) checks that each pair of element types can be compared. When the element types of one comparison make more than 50,000 pairs, that comparison's elements are not checked, with a warning at the comparison. The other checks are unaffected.

## Format of static errors

Static errors are reported all together, sorted by position, and nothing runs. Each line gives the file, the line, the column and the message; the `hint:` lines that follow suggest a fix.

```
FILE:LINE:COLUMN: error: MESSAGE
  hint: SUGGESTION
```

The `name.upcase` example at the top of this chapter prints:

```
greet.sake:2:11: error: method call on a value `name.upcase` is not allowed
  hint: String.upcase(name)
  hint: Symbol.upcase(name)
  hint: name.String.upcase
```

## Format of runtime errors

A runtime error prints the line of the operation that stopped and the chain of calls that led there (the `from` lines).

```
FILE:LINE: in FUNCTION: KIND: MESSAGE
  from FILE:LINE: in CALLER
  hint: SUGGESTION
```

```ruby error
def third(xs) = Array.fetch(xs, 2)
p(third(Array[1, 2]))          # !> IndexError: Array.fetch: index 2 outside of array bounds: -2...2
```

```
third.sake:1: in third: IndexError: Array.fetch: index 2 outside of array bounds: -2...2
  from third.sake:2: in <main>
```

The kinds are listed in [Exceptions and errors](08-exceptions.md).
