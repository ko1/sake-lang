# optparse

`require "optparse"`. Ruby's `OptionParser` stores a block for each option, and the block runs when
the option is seen. Sake's blocks are not values, so they cannot be stored. In the Sake form the options
are data, and parsing fills a Hash. This is Ruby's own `parse(argv, into: h)`, which needs no blocks:

```ruby
op = OptionParser.new
OptionParser.set_banner(op, "Usage: tool [options]")
OptionParser.on(op, "-v", "--[no-]verbose", "Run verbosely")
OptionParser.on_type(op, "-c", "--count N", :Integer, "How many")
OptionParser.on_type(op, "-t", "--type T", Array["text", "binary"], "Select type")
opts = Hash[]
rest = OptionParser.parse(op, argv, opts)    # opts: {verbose: true, count: 3}; rest: non-options
puts(OptionParser.help(op))
```

The keys are the long name as a Symbol (`:verbose`, `:"dry-run"`), or the short letter (`:q`) if
there is no long name. The values are `true`/`false` for flags, a String (or the converted Integer,
Float, or chosen value) for arguments, and `nil` for an optional argument that was left out.

The test (`test/sakelib/optparse.{sake,rb}`) runs 51 argument lists through `parse` and `order!`,
and compares the help text and the errors with Ruby's.

## API

| Ruby | Sake | |
|---|---|---|
| `OptionParser.new` | `OptionParser.new` | same |
| `OptionParser.new { \|o\| ... }` | — | missing (blocks are not values; call `on` after `new`) |
| `op.banner = s` / `op.banner` | `OptionParser.set_banner(op, s)` / `get_banner` | same (`get_banner` is nil until set; `help` then uses Ruby's default) |
| `op.program_name=` | `OptionParser.set_program_name(op, s)` | differs: the default is `"sake"`, not `$0` |
| `op.summary_width=`, `summary_indent=` | `set_summary_width`, `set_summary_indent` | same |
| `op.on("-v", "--[no-]verbose", "desc") { \|v\| ... }` | `OptionParser.on(op, "-v", "--[no-]verbose", "desc")` | differs: no block. The short form, long form, and description are fixed positions, and `""` leaves one out |
| `op.on("-c", "--count N", Integer, "desc")` | `OptionParser.on_type(op, "-c", "--count N", :Integer, "desc")` | differs: the type is a Symbol (`:Integer`, `:Float`, `:String`) |
| `op.on("-t", "--type T", ["a", "b"], "desc")` | `OptionParser.on_type(op, "-t", "--type T", Array["a", "b"], "desc")` | same (exact match, or a unique prefix) |
| `op.on_tail(...)` | `OptionParser.on_tail(op, short, long, desc)` | same, without a block |
| `op.on_head(...)` | — | missing |
| `op.separator(s)` | `OptionParser.separator(op, s)` | same |
| `op.help`, `op.to_s`, `puts op` | `OptionParser.help(op)`, `to_s`, `puts(op)` | same |
| `op.parse(argv, into: h)` | `OptionParser.parse(op, argv, h)` | same; `into` is required |
| `op.parse!(argv, into: h)` | `OptionParser.parse!(op, argv, h)` | same (argv keeps the rest) |
| `op.order(argv, into:)`, `order!` | `OptionParser.order`, `order!` | same (stops at the first non-option) |
| `op.permute`, `permute!` | `OptionParser.permute`, `permute!` | same |
| `op.parse(argv)` (no `into`) | — | differs: without blocks, only `into` keeps the values |
| `op.getopts(argv, "ab:", "foo", "bar:")` | `OptionParser.getopts(op, argv, "ab:", String["foo", "bar:"])` | same (long options as an Array, because a user function takes a fixed number of arguments) |
| `OptionParser::InvalidOption`, `MissingArgument`, `InvalidArgument`, `NeedlessArgument`, `AmbiguousOption`, `AmbiguousArgument` | one type `OptionParserError`, with `get_kind(e)` = `"InvalidOption"`, ... | differs: no hierarchy, so `rescue OptionParserError` stands for `rescue OptionParser::ParseError` |
| `e.message`, `e.args`, `e.reason` | `Exception.message(e)`, `OptionParserError.get_args(e)`, `OptionParserError.reason(e)` | same text |
| `--help`, `--version` handled by OptionParser itself (prints and exits) | — | missing: Sake has no `exit`. Declare `-h`/`--help` yourself and check `opts[:help]` |
| `ARGV`, `ARGV.options`, `ARGV.getopts` | — | missing: Sake has no ARGV, so the arguments are passed as an Array of String |
| acceptors `Numeric`, `DecimalInteger`, `OctalInteger`, `TrueClass`, `Array` (comma lists), `Regexp` patterns, `OptionParser#accept` | — | missing |
| `op.environment`, `op.load`, `op.abort`, `op.warn`, completion scripts | — | missing |

## Differences from Ruby, and why

- **Blocks.** These are not values in Sake ([spec §7](../../docs/spec.md)), so `on` cannot keep one.
  Ruby's `into:` is the form that needs no block, and it becomes the only form. A value that a
  Ruby block would convert (for example `{ |v| v.split(",") }`) is converted after `parse` returns.
- **A fixed number of arguments.** Ruby's `on(*args)` sorts its arguments by their content (`-x`,
  `--xx`, a class, an Array, a description). A Sake function takes a fixed number of arguments, so
  `on` takes short, long, and description in that order, and `on_type` adds the type.
- **The type is a Symbol.** `Integer` is a type name, not a value that can be passed. `on_type`
  takes `:Integer`, `:Float`, or `:String`, or an Array of allowed Strings. The checks for
  Integer and Float use Ruby's own patterns (`0x10`, `1_000`, `-5`, `.5`, `1e3`; `08` and
  `1.5` are rejected for Integer).
- **Exceptions.** There is no hierarchy, and nested names (`OptionParser::InvalidOption`) do not
  exist. One exception type carries the kind as a String, and `message`, `args`, and `reason` are
  Ruby's.
- **Abbreviations.** A long option can be shortened to a prefix that only one name has, counting
  `no-` names. An exact name wins: `--n` is ambiguous between `--name`, `--nice`, and
  `--no-verbose`. Ruby's completion also ignores case and matches parts of words separately
  (`--d-r` for `--dry-run`). Those are not ported.
- **Help.** The help follows Ruby's `Switch#summarize`: a 32-column left part, a long left part
  on its own line, `on_tail` options last, and separators where they were added. One switch has at most
  one short form and one long form (Ruby allows several).
- **Duplicates.** When two switches have the same short letter, the first one declared wins. In
  Ruby the last one wins.

## Built-ins requested

- **`ARGV`** (or `Kernel.argv`): a command-line parser cannot read the command line now.
- **`exit(status)`**: needed for Ruby's built-in `--help`/`--version` and for `op.abort`. Today
  the program has to fall off the end.
- **`$stderr` / `warn`**: usage errors belong on stderr.
- **`$0` / program name**: Ruby's default banner is `Usage: #{File.basename($0, ".*")} [options]`.

## Friction

- `require "optparse"` in `test/sakelib/optparse.sake` → `undefined type or module OptionParser`
  (the require found the test file itself) → `require "../../sakelib/optparse"`. The maintainer
  fixed the loader during the port, and the plain form now works.
- `Array.filter_map(xs) { |it| it in OptionParserSwitch ? it : nil }` → `syntax error: unexpected
  '?'` → `(it in OptionParserSwitch) ? it : nil` (Prism parses it this way, as Ruby does).
- `def new = OptionParser.new(Array[], nil, ...)` inside the class, to give the switch list an
  empty Array → `OptionParser.new is a built-in operation and cannot be redefined`. A default must
  be a literal, so `Array[]` cannot be one. The list's default is `nil`, and `items(op)` creates the
  Array on first use. A constructor-like hook, or `default: {list: Array[]}` making a new Array per
  instance, would remove this pattern.
- `p(opts)` printed `{:"dry-run" => true}`, where Ruby 3.4+ prints `{"dry-run": true}`. This is an
  interpreter bug: [optparse_bug_symbol_key_inspect.sake](optparse_bug_symbol_key_inspect.sake).
  The test prints each key with `#{k}` instead.
