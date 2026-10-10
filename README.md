# Sake-lang

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

The motivation was to make a language that is easy for AI to write. **The evaluation did not
support it (2026-10-08); development continues at a small scale**, from what using the language turns
up. See [Status](#status).

> **Writing Sake with a language model?** Give it [docs/cheatsheet.md](docs/cheatsheet.md): the
> rules on four pages plus the compact list of operations, about 10k tokens, and all a model needs
> (raw: <https://raw.githubusercontent.com/ko1/sake-lang/main/docs/cheatsheet.md>). The full
> reference manual and the playground are at <https://ko1.github.io/sake-lang/>.

## A taste

```ruby
class Point
  attr_reader x, y
  def norm2(p) = @x * @x + @y * @y        # @x is Point.x(p): p is the first argument
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
bin/sake --dump=ast FILE.sake   # print the SakeAST (the resolved program that runs)
```

The exit status is 0 on success, 1 for an error while running, and 2 for a problem found before
running.

### Native code through Rust (experimental)

`bin/sabic` compiles a program to a native executable by way of Rust, for the subset whose types
the generator can fix: Integer (as 64-bit, an overflow is an error), Float, true/false, nil as
`Option`, String, Array, Tuple, classes, blocks, unions of classes as a Rust `enum` with mixin calls
as a `match`, and `case`/`in` on values and types. Anything outside the subset is reported with its
line, and the program still runs on the interpreter.

```
bin/sabic FILE.sake            # writes FILE.rs and builds FILE with rustc -O
bin/sabic FILE.sake --emit     # only the Rust source
```

On three micro benchmarks (loops, fib, levenshtein) the compiled program ran 3 to 21 times faster than
Ruby 4.0 with YJIT, 8 to 53 times faster than Ruby without it, and within 0.9 to 1.6 times of Rust
written by hand ([experiments/2026-10-10-rust-backend/](experiments/2026-10-10-rust-backend/README.md)).
A mixin call dispatched on the argument's type costs 0.12 ns, about the same as a hand-written `enum`
and an eighth of Rust's `dyn Trait`. Against [Spinel](https://github.com/matz/spinel), the Ruby AOT
compiler, the same programs ran at the same speed on loops and levenshtein and 8 times faster on
the dispatch benchmark, with an analyzer of 1,100 lines of Ruby where Spinel's is 107,000 lines of C,
because Sake's rules do that work in the language. `bin/ceec` does the same through C, on the same
type inference, and runs at the same speed as the Rust output; against hand-written C, the remaining
gap is the overflow check on every Integer operation (fib: 0.186 s with it, 0.065 s without, hand C 0.064). The interpreter is 150 to 760 times slower than
Ruby with YJIT.

## Documentation

- [docs/tutorial.md](docs/tutorial.md): a tour with small programs. Every output in it was produced
  by running the program.
- [docs/spec.md](docs/spec.md): the language as implemented.
- [docs/builtins.md](docs/builtins.md): all built-in operations, generated from the interpreter.
- [docs/cheatsheet.md](docs/cheatsheet.md): the rules on four pages plus the compact list of
  operations, about 10k tokens, for a language model (or a Ruby programmer) writing Sake. Its
  examples are run on every build.
- [docs/guide.html](docs/guide.html): the tutorial and the specification on one page. It is also
  published at <https://claude.ai/artifact/EdrbscXRGUtkKppprRKohP>.
- [docs/manual/](docs/manual/): the reference manual in Japanese and English, a [ligarb](https://github.com/ko1/ligarb)
  book (`docs/manual/build.sh` builds `docs/manual/build/index.html`). Part 2 documents every built-in
  operation, one chapter per type, with examples that `ruby tools/check_reference.rb` runs and compares.
  GitHub Pages serves the built book at <https://ko1.github.io/sake-lang/manual/>, the guide at
  <https://ko1.github.io/sake-lang/guide.html> and the playground at
  <https://ko1.github.io/sake-lang/playground/>; the front page <https://ko1.github.io/sake-lang/> is
  this README (`.github/workflows/pages.yml` and `tools/gen_site.rb`, no Jekyll).
- [ide/](ide/README.md): the playground, a browser IDE on ruby.wasm with completion, diagnostics as
  you type, and the inferred types on hover.
- [DESIGN.md](DESIGN.md): the design notes, with the reasons behind each decision (in Japanese).
- [docs/comparison.md](docs/comparison.md): what is new in Sake and what is not, axis by axis against
  Elm, Crystal, Rust, Elixir, TypeScript, Clojure and the type-inference literature (in Japanese).

## What is in the language

- **Values**: Integer, Float, Rational, Complex, String, Symbol, true/false, nil, Tuple `[a, b]`,
  Record `{x: 1}`, Array, Hash, Set, Range, Regexp, and Time.
- **Named types**: `class C` with `attr_reader` / `attr_accessor` lines for its fields (`Struct.new(:x, :y)`
  is the shorthand), and exception types `class E < Exception`.
- **Operators**: `a + b` runs the `+` of `a`'s type, and `a[i]` its `[]`. Your own types join by
  including `Arithmetic`, `Comparable`, `Bitwise`, or `Indexable`.
- **Chains**: `x.T.f(args)` is `T.f(x, args)`, and `_` is the previous statement's value, so a
  sequence of operations reads in order while each step still names its type.
- **Functions and blocks**: functions are polymorphic and take no annotations. Blocks are passed
  with `yield`.
- **Modules**: `module` with `include` works like Ruby's modules, resolved statically. Namespaces
  nest (`A::B`). There is no inheritance.
- **nil**: a value that may be nil has the type `nil | T`, narrowed by `if x`, `x != nil`, and
  early returns.
- **Patterns**: `x in Integer` and `case x in ...` narrow types, and the checker verifies that a
  `case` is exhaustive.
- **Exceptions**: `raise`, `rescue`, `ensure`, and `retry`, plus inference of which exceptions may
  escape a function.
- **Built-in library**: about 550 operations, named after Ruby's core library. `Enum` (the prelude)
  is Enumerable under a short name: `Enum.map(x) { }` dispatches to Array, Hash, Set or Range, and a
  class joins with `include Enum` and `def each`.

Not yet: `case`/`when`, first-class blocks, and built-in constants such as `Math::PI`.

## Repository layout

```
bin/sake                 the command
bin/sabic                the compiler to native code through Rust (sabi, 錆, is rust)
bin/ceec                 the compiler to native code through C
lib/sake/                resolver (checks before running), lower (Prism AST to SakeAST), interpreter
                         and typer (type inference), both on SakeAST, the Rust and C backends (rust.rb, c.rb),
                         standard library (stdlib*.rb)
test/                    golden tests (test/samples/*.sake with *.expected) and CLI tests
examples/                example programs by category, each with its expected output (examples/README.md)
docs/                    tutorial, specification, built-in list, one-page guide, examples
tools/                   generators for the docs (they run the examples)
experiments/             experiments, each with its method, results, and limits in a README
```

Run the tests with:

```
ruby test/test_samples.rb       # UPDATE=1 rewrites the expected outputs
ruby test/test_cli.rb           # the command line, and whether the generated docs are up to date
ruby test/test_examples.rb      # examples/**/*.sake print their *.expected (UPDATE=1 rewrites them)
ruby test/test_sakelib.rb       # the library ports: each test/sakelib/X.sake prints what X.rb prints
ruby test/test_sake_suite.rb    # Sake's test suite written in Sake (test/sake/*_test.sake, on sakelib/minitest.sake)
ruby test/test_ide.rb           # the playground's Ruby side (lib/sake/ide.rb)
ruby test/test_rust.rb          # the Rust backend: test/native/*.sake compiled and compared with the interpreter (needs rustc)
ruby test/test_c.rb             # the C backend: the same programs through bin/ceec (needs cc)
ruby tools/check_reference.rb   # the built-in reference (docs/manual/*/ref): signatures, coverage, and every example
```

## Status

**The evaluation concluded on 2026-10-08. Development goes on at a small scale: fixes and features
that come from using the language (on 2026-10-10, about 40 findings of the built-in reference, and
nested namespaces).**

This was a research prototype. The hypothesis was that writing types on **operations** is better
than writing them on **variables**, for AI to write and to understand code. The evaluation
([experiments/2026-10-05-ai-writability/](experiments/2026-10-05-ai-writability/README.md), in
Japanese; summary page: <https://claude.ai/artifact/NaxNc5iropLucuvhawKETD>) could not separate
that from a larger effect: Sake is a language no model has seen before.

What the evaluation showed:

- **A capable model uses a new language at about twice the cost.** Claude Sonnet 5.5 had never
  seen Sake, and got only its documents (about 45k tokens, or an 8k-token cheat sheet). It still
  wrote, changed, read, and fixed programs as correctly as in Ruby, up to a SQL engine of 4,000
  lines grown in 6 stages. It almost never called an operation that does not exist. The cost was
  1.1 to 2.4 times Ruby's output tokens depending on the task: reading was cheap, writing was
  expensive. Borrowing Ruby's syntax and Ruby's names probably helped (not tested).
- **A smaller model cannot.** With Claude Haiku 4.5, Sake passed 26% of the hidden tests against
  Ruby's 77%, and better documents or instructions did not close the gap.
- **Where to write types did not show up.** On the SQL engine, all 12 runs in Ruby, Java, Haskell,
  Scheme, Ruby with Steep, and Sake passed 366 to 368 of the 369 hidden tests, and no type checker
  prevented a bug that the others shipped. The output tokens, against Ruby, were Java 1.06,
  Haskell 1.18, Scheme 1.22, Steep (types on every variable and method) 1.48, and Sake 1.71.
  Apart from Steep, which pays for writing every type, the order roughly follows how well-known
  the language is. Sake's overhead did not shrink as one agent wrote
  more programs, or with a shorter document. So the cost of an unfamiliar language is paid in
  every task, and it hides any difference between operations and variables.
- **Not compared: understanding and fixing code, against a language with types on variables.**
  Reading and changing were compared only with plain Ruby. A fair test would need a language with
  types on variables that models know as little as Sake, and such a language is hard to find or
  to make.

What would justify reopening it: a task where Sonnet-class models fall clearly below the ceiling,
*and* static type checks (in any language) are seen to stop errors that the dynamically typed
solutions ship.

**Not measured: whether people read Sake more easily**, for example when reviewing code that AI
wrote. "One line tells you which function runs" is also a claim about a human reader, and the
evaluation only had AI read. Testing it needs people: review the same AI-written changes with
planted bugs in Ruby and in Sake, and compare how many bugs are found and how long it takes. The
reviewers already know Ruby, so the comparison is biased against Sake.

The design notes and their reasons are in [DESIGN.md](DESIGN.md).

### Known issues (not fixed)

- Checking a 4,400-line program takes about 3 seconds with YJIT, which `bin/sake` turns on (4.5 before the
  shape keys of 2026-10-09, `experiments/2026-10-09-typer-shape-keys/`; it took
  190 before 2026-10-08; see `experiments/2026-10-09-typer-speed/`), and starting a program takes about 0.3 seconds for 2,500
  lines, about 5 times Ruby.
- Fixed on 2026-10-08: the checker did not terminate for mutually recursive functions that use
  `Array + Array` (each `+` made a new array type per instantiation). A container made in the context
  of a container this function made is now shared, so the chain stops.

## License

[MIT](LICENSE)
