# Sake

**Sake** (/seɪk/, as in "for the sake of") is an experimental programming language. It is designed
for the sake of finding a new place for types. It keeps **Ruby's syntax**, but you write the type
on each **operation**, never on a variable, a parameter, or a field:

```ruby
String.upcase(name)        # Sake
name.upcase                # Ruby: an error in Sake, reported with the fix above
```

Because every operation names its type:

- **One line is enough to read it.** A line tells you which function runs, without looking up
  declarations.
- **Names are checked before running.** A misspelled operation or type is reported before the
  program starts.
- **Types are inferred, never written.** The whole-program inference catches values that cannot
  fit an operation, and the strictness level chooses how much of that stops a run.
- **Run-time checks remain.** Every operation still checks its arguments while running, so what
  the checks before running miss still stops at the exact operation.

The motivation is to make a language that is easy for AI to write. An experiment comparing Sake
with Ruby, with and without type signatures, is planned (see [DESIGN.md](DESIGN.md), in
Japanese).

## A taste

```ruby
Point = Struct.new(:x, :y)

class Point
  def norm2(p) = @x * @x + @y * @y        # @x is Point.get_x(p): p is the first argument
end

words = String.split("the cat and the hat", " ")
counts = Hash.new(0)
Array.each(words) { |w| counts[w] += 1 }
p(counts)
puts(Point.norm2(Point.new(3, 4)))
```

```
$ bin/sake readme.sake
{"the" => 2, "cat" => 1, "and" => 1, "hat" => 1}
25
```

Mistakes are reported before anything runs, each with a fix:

```ruby
name = "sake"
puts(name.upcase)
puts(String.upcse(name))
```

```
$ bin/sake mistakes.sake
mistakes.sake:2:11: error: method call on a value `name.upcase` is not allowed
  hint: String.upcase(name)
  hint: Symbol.upcase(name)
mistakes.sake:3:13: error: undefined function `String.upcse`
  hint: did you mean `String.upcase`?
```

## Getting started

The interpreter is written in Ruby, parses with [Prism](https://github.com/ruby/prism), and walks
the AST. It needs **Ruby 4.0** (tested with 4.0.2 and Prism 1.9.0) and has no other dependencies.

```
bin/sake FILE.sake              # check, then run
bin/sake -c FILE.sake           # check only
bin/sake --strict FILE.sake     # check more strictly before running (level 2)
bin/sake --strict=3 FILE.sake   # levels 0-4, or items: --strict=type,nil
bin/sake --types FILE.sake      # experimental: print the inferred types
```

The exit status is 0 on success, 1 for an error while running, and 2 for a problem found before
running.

## Documentation

- [docs/tutorial.md](docs/tutorial.md): a tour with small programs. Every output in it was produced
  by running the program.
- [docs/spec.md](docs/spec.md): the language as implemented.
- [docs/builtins.md](docs/builtins.md): all built-in operations, generated from the interpreter.
- [docs/guide.html](docs/guide.html): the tutorial and the specification on one page. It is also
  published at <https://claude.ai/artifact/EdrbscXRGUtkKppprRKohP>.
- [DESIGN.md](DESIGN.md): the design notes, with the reasons behind each decision (in Japanese).

## What is in the language

- **Values**: Integer, Float, Rational, Complex, String, Symbol, true/false, nil, Tuple `[a, b]`,
  Record `{x: 1}`, Array, Hash, Set, Range, Regexp, and Time.
- **Named types**: `Struct.new` types, and exception types made with `Exception.new`.
- **Operators**: `a + b` means `BinaryOp.+(a, b)`, and `a[i]` means `Index.[](a, i)`. Both look up
  a closed table.
- **Functions and blocks**: functions are polymorphic and take no annotations. Blocks are passed
  with `yield`.
- **Modules**: `module` with `include` works like Ruby's modules, resolved statically. There is no
  inheritance.
- **nil**: a value that may be nil has the type `nil | T`, narrowed by `if x`, `x != nil`, and
  early returns.
- **Patterns**: `x in Integer` and `case x in ...` narrow types, and the checker verifies that a
  `case` is exhaustive.
- **Exceptions**: `raise`, `rescue`, `ensure`, and `retry`, plus inference of which exceptions may
  escape a function.
- **Built-in library**: about 550 operations, named after Ruby's core library.

Not yet: protocols or generic functions (for example `to_s` or `==` across types), string
interpolation, unary operators, and built-in constants such as `Math::PI`.

## Repository layout

```
bin/sake                 the command
lib/sake/                resolver (checks before running), interpreter, typer (type inference),
                         standard library (stdlib*.rb)
test/                    golden tests (test/samples/*.sake with *.expected) and CLI tests
docs/                    tutorial, specification, built-in list, one-page guide, examples
tools/                   generators for the docs (they run the examples)
experiments/             experiments, each with its method, results, and limits in a README
```

Run the tests with:

```
ruby test/test_samples.rb       # UPDATE=1 rewrites the expected outputs
ruby test/test_cli.rb           # the command line, and whether the generated docs are up to date
```

## Status

This is a research prototype, built to see how far "types on operations" can go. The design is
still moving: decisions and open questions are kept in [DESIGN.md](DESIGN.md).
