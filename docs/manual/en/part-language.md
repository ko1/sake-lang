# The language

This part describes the language Sake itself, as the v0 interpreter (`bin/sake`) implements it, in ten chapters and one appendix. It is written for readers who know Ruby, people and language models alike. The syntax is Ruby's, so what the part explains is the meaning Sake gives to Ruby's spelling, and the rules Ruby does not have.

## One idea

A Sake program is written in Ruby's syntax, but instead of `name.upcase` you write `String.upcase(name)`. Only an **operation** names its type; a variable, a parameter, a return value or a field carries nothing.

```ruby
words = String.split("the cat and the hat", " ")
counts = Hash.new(0)
Array.each(words) { |w| counts[w] += 1 }
p(Hash.to_a(counts).Array.sort_by { |w, n| -n }.Array.first(2))   # [["the", 2], ["cat", 1]]
```

Nearly every property of the language follows from this one rule.

- **One line is enough to read it.** `Array.each(words)` says which `each` runs without a declaration to look up; in a chain `x.Array.sort_by { }`, each step names its type too.
- **Every call target is known before running.** There is no dispatch on the receiver, so a misspelled name (`String.upcse`) or a wrong number of arguments is reported for the whole program before it starts.
- **Types are inferred, never written.** The checker infers the types of the whole program and reports a value that does not fit an operation (`"" + 1`, an unchecked nil) before running; how much of that stops a run is chosen with `--strict`, levels 0 to 4.
- **Run-time checks remain.** Values carry type tags and every operation checks its arguments, so what the checks before running miss still stops at that operation's line.

A few spellings mean something else than in Ruby. `[a, b]` is a Tuple and `{x: 1}` a Record; an Array and a Hash are written `Array[...]` and `Hash[...]`. Inside a `class`, `@x` is "field x of the first argument", not an instance's own state. `class B < A` is shorthand for writing A's definitions in B, not inheritance. The chapters of this part take up these differences one by one.

## The chapters

| Chapter | Contents |
|---|---|
| [Overview and running programs](01-overview.md) | The four principles, the command and its exit status, the `--strict` levels 0 to 4 and their items (`type`, `nil`, `mixed`, `index-nil`, `exhaustive`, `rescue`, `unrescued`), the format of static and runtime errors. |
| [Program structure and name resolution](02-program.md) | Files and `require`, qualified calls `T.f(x)`, chains `x.T.f` and `_`, why there are no calls on values, unqualified calls (your own functions, `puts`, `p`), `include`, `module_function` and dispatch, listing the types `(A\|B).f(x)`, arity and blocks. |
| [Values and types](03-values.md) | How values print, Tuple versus Record versus Array, Hash and Set, nil and the narrowing of `nil \| T`, Ruby's other types (Symbol, Range, Regexp, Time, Rational, Complex). |
| [Functions and blocks](04-functions.md) | Polymorphic functions without annotations, optional and keyword parameters, blocks passed with `yield`, `once`. |
| [Operators and indexing](05-operators.md) | `a + b` is short for `Arithmetic.+(a, b)`, resolved by the type of the left operand; `Arithmetic`, `Comparable`, `Bitwise` and `Indexable` give your own types operators; `a[i]` and `a[i] = v`. |
| [Control flow and patterns](06-control.md) | `if`, `while`, `case`/`in`, narrowing with `x in T`, the exhaustiveness check of a `case`. |
| [Classes](07-classes.md) | Declaring a type with `class` and `attr_*` lines (`Struct.new` is the shorthand), what `@x` means, `initialize`, `class B < A`, one type per construction site. |
| [Exceptions and errors](08-exceptions.md) | `raise`, `rescue`, `ensure`, `retry`, declaring exception types, the inference of which exceptions escape a function, the kinds of static and runtime error. |
| [Built-in operations](09-builtins.md) | A survey of the about 550 built-in operations (named after Ruby's core library) and typed arrays `T[...]`. The exact signature and examples of each operation are in the [Built-in reference](part-reference.md). |
| [The library (sakelib)](10-library.md) | Ports of the standard library and of gems, minitest, how to write tests. |
| Appendix [Differences from Ruby and what is not supported](a1-ruby.md) | Ruby's spelling against Sake's, the syntax and features not supported, the design material. |

## How to read it

- **If you know Ruby and want to start writing**, read [Overview and running programs](01-overview.md), [Program structure and name resolution](02-program.md), [Values and types](03-values.md) and [Operators and indexing](05-operators.md) in that order, and keep the appendix's table at hand: it explains most static errors you will meet. Read [Classes](07-classes.md) when you declare a type.
- **If a language model is to write Sake**, hand it [cheatsheet.md](https://github.com/ko1/sake-lang/blob/main/docs/cheatsheet.md), which compresses the rules of this part into four pages (about 10k tokens). A guided introduction is [tutorial.md](https://github.com/ko1/sake-lang/blob/main/docs/tutorial.md).
- **To try things**, the [playground](https://ko1.github.io/sake-lang/playground/) runs in the browser, with completion, diagnostics as you type, and the inferred types on hover.
- **Conventions.** A `# value` in an example is the real output of `bin/sake`. A "static error" is reported before running, and nothing runs; a "runtime error" stops at that operation. "Level n" means `--strict=n`.
