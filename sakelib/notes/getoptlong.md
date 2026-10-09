# getoptlong (GetoptLong)

`require "getoptlong"` → `sakelib/getoptlong.sake`. Test: `test/sakelib/getoptlong.{sake,rb}` (identical output).
Source ported: getoptlong 0.2.1 (`get` is a line-by-line port of Ruby's).

`GetoptLong` is a Struct type whose first field is the argument Array: Ruby's GetoptLong reads and shifts
the global `ARGV`; Sake's `GetoptLong.new(argv, specs)` takes the Array (pass `ARGV` for the program's own)
and shifts it in place, so `GetoptLong.argv(g)` (or the Array the caller holds) is what Ruby's `ARGV`
would be after parsing. Ruby's constants are Symbols: `NO_ARGUMENT` → `:no_argument`,
`REQUIRED_ARGUMENT` → `:required_argument`, `OPTIONAL_ARGUMENT` → `:optional_argument`;
`PERMUTE` → `:permute`, `REQUIRE_ORDER` → `:require_order`, `RETURN_IN_ORDER` → `:return_in_order`.
Ruby's `GetoptLong::Error` and its four subclasses are one exception type `GetoptLongError` with a
`kind` field (`:ambiguous_option`, `:needless_argument`, `:missing_argument`, `:invalid_option`).

## API

| Ruby | Sake | |
|---|---|---|
| `GetoptLong.new(["--name", "-n", REQUIRED_ARGUMENT], ...)` | `GetoptLong.new(argv, Array[Array["--name", "-n", :required_argument], ...])` | differs: the argument Array is the first field; the specs are one Array (`new` takes fields) |
| `GetoptLong.new` | `GetoptLong.new(argv)` | same (specs may follow with `set_options`) |
| `g.set_options(spec, ...)` | `GetoptLong.set_options(g, spec, ...)` | same (Ruby's messages: `no argument-flag`, `an invalid option `x'`, `option redefined `x'`, ...) |
| `g.ordering = PERMUTE` | `GetoptLong.set_ordering(g, :permute)` | differs: name; same errors (`ArgumentError` after the start, as Ruby's `set_error(ArgumentError, ...)`) |
| `g.ordering` | `GetoptLong.ordering(g)` | same (a Symbol) |
| `g.quiet = true` / `g.quiet` / `g.quiet?` | `GetoptLong.set_quiet(g, true)` / `quiet(g)` / `quiet?(g)` | differs: setter name |
| `g.get` / `g.get_option` | `GetoptLong.get(g)` / `get_option(g)` | same: `[name, argument]` or nil; `["", arg]` for a non-option with `:return_in_order` |
| `g.each { \|name, arg\| }` / `g.each_option` | `GetoptLong.each(g) { \|name, arg\| }` / `each_option` | same (returns g; Ruby returns nil) |
| `g.terminate` / `g.terminated?` | `GetoptLong.terminate(g)` / `terminated?(g)` | same (non-option arguments go back to the front of argv) |
| `g.error` / `g.error?` / `g.error_message` | `GetoptLong.error(g)` / `error?(g)` / `error_message(g)` | differs: the error is the kind Symbol, not a class |
| `GetoptLong::InvalidOption` & co. | `rescue GetoptLongError => e`, `GetoptLongError.kind(e)` | differs: one type, a `kind` field |
| `ARGV` after parsing | `GetoptLong.argv(g)` | differs: the Array given to `new` |
| `ENV["POSIXLY_CORRECT"]` | — | missing: Sake has no ENV; the ordering is `:permute` unless set |
| `GetoptLong::VERSION` | — | missing (constant) |

18 operations ported. Error messages are Ruby's (`unrecognized option `--zzz'`, `invalid option -- z`,
`option `--name' requires an argument`, `option requires an argument -- n`, `option `--verbose' doesn't allow an
argument`, `option `--ver' is ambiguous between --verbose, --version`). Unless quiet, the message is also
printed to stderr as `sake: message` (Ruby: `#{$0}: message`).

## What differs, and why

- **argv is a field.** Sake's `ARGV` is an operation giving one shared Array, so a parser could shift it
  as Ruby does; but tests and programs want to parse any Array, and a Struct type has nowhere else to keep
  state. `GetoptLong.new(argv)` is the only constructor (`new` takes fields), so the specs come as one
  Array in the second field or through `set_options(g, *specs)`.
- **No class hierarchy for errors.** `rescue GetoptLongError` with `kind`; `error(g)` returns the kind.
- **Setters** are `set_ordering`, `set_quiet` (no `x.y = v` on values).
- **`get` returns a Tuple or nil.** Ruby's `each` writes `name, arg = get_option` and tests `name == nil`;
  in Sake multiple assignment from nil is a TypeError, so `each` tests the result first.

## Built-ins Sake lacks (requests)

- `ENV` (`Kernel.ENV` as a Hash, or `ENV["X"]`): for `POSIXLY_CORRECT`, which switches the default
  ordering in Ruby.
- `$0` / the program name (`Kernel.PROGRAM_NAME`): Ruby's error line on stderr starts with it; the port
  writes `sake:`.

## Friction

- Wrote Ruby's `ordering=` as it is: `set_error(g, :argument_error, "argument error")` followed by
  `raise RuntimeError, "invoke ordering=, ..."` → the test's `rescue RuntimeError` was rejected before
  running: `rescue RuntimeError: the begin body never raises RuntimeError [rescue]` → the typer knows
  `set_error` always raises, so Ruby's own RuntimeError line is dead code (it is, in getoptlong.rb too:
  the ArgumentError is what callers see). Split into `record_error` + the raise Ruby really makes.
- `name, arg = get(g)` with `get` returning `[String, String] | nil`: avoided the Ruby idiom (destructuring
  nil) and wrote `r = get(g); break if r == nil; name, arg = r`. Fine, but every Ruby loop of this shape
  needs the rewrite.
- `@argv => Array` accepts `String[...]` (an Array of String has the Array type tag), as hoped.
- What felt good: the `get` port is Ruby's code almost line for line (`Regexp.match` for `$1`, `Hash`
  for the two tables, `Array.shift` on the given Array); the first `--strict` run passed except for the
  `rescue` report above, which was a true finding.
