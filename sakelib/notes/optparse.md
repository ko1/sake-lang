# optparse

`require "optparse"`. Ruby's `OptionParser` stores a block for each option, and the block runs when
the option is seen. Sake's blocks are not values, so they cannot be stored. In the Sake form the options
are data, and parsing fills a Hash. This is Ruby's own `parse(argv, into: h)`, which needs no blocks:

```ruby
op = OptionParser.new
OptionParser.set_banner(op, "Usage: tool [options]")
OptionParser.on(op, "-v", "--[no-]verbose", "Run verbosely")
OptionParser.on(op, "-c", "--count N", :Integer, "How many")
OptionParser.on(op, "--type T", Array["text", "binary"], "Select type")
opts = Hash[]
rest = OptionParser.parse(op, ARGV, opts)    # opts: {verbose: true, count: 3}; rest: non-options
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
| `op.version=`, `op.ver` | `OptionParser.set_version(op, v)`, `OptionParser.ver(op)` | same (`ver` is `"prog 1.2"`, or nil); no `release` |
| `op.summary_width=`, `summary_indent=` | `set_summary_width`, `set_summary_indent` | same |
| `op.on("-v", "--[no-]verbose", "desc") { \|v\| ... }` | `OptionParser.on(op, "-v", "--[no-]verbose", "desc")` | differs: no block. Up to four arguments, each sorted by content as Ruby does (`-x` short, `--xx` long, a type, else the description), so `on(op, "--dry-run", "Dry run")` and `on(op, "-q")` work (phase 2) |
| `op.on("-c", "--count N", Integer, "desc")` | `OptionParser.on(op, "-c", "--count N", :Integer, "desc")` | differs: the type is a Symbol (`:Integer`, `:Float`, `:String`) |
| `op.on("-t", "--type T", ["a", "b"], "desc")` | `OptionParser.on(op, "-t", "--type T", Array["a", "b"], "desc")` | same (exact match, or a unique prefix) |
| `op.on_tail(...)` | `OptionParser.on_tail(op, ...)` | same, without a block |
| `op.on_head(...)` | — | missing |
| `op.separator(s)` | `OptionParser.separator(op, s)` | same |
| `op.help`, `op.to_s`, `puts op` | `OptionParser.help(op)`, `to_s`, `puts(op)` | same |
| `op.parse(argv, into: h)` | `OptionParser.parse(op, argv, into: h)` | same |
| `op.parse` / `op.parse(argv)` (ARGV, no `into`) | `OptionParser.parse(op)` / `OptionParser.parse(op, argv)` | same for the rest; without `into` or blocks the values are dropped (phase 2) |
| `op.parse!(argv, into: h)` | `OptionParser.parse!(op, argv, into: h)` | same (argv keeps the rest) |
| `op.order(argv, into: h)`, `order!` | `OptionParser.order(op, argv, into: h)`, `order!` | same (stops at the first non-option) |
| `op.permute(argv, into: h)`, `permute!` | `OptionParser.permute(op, argv, into: h)`, `permute!` | same |
| `op.getopts(argv, "ab:", "foo", "bar:")` | `OptionParser.getopts(op, argv, "ab:", String["foo", "bar:"])` | same (long options as an optional Array; no rest parameters). Stops at the first non-option, as Ruby (fixed in phase 2; phase 1 permuted) |
| `op.getopts("ab:")` (ARGV) | — | differs: argv is required here (it comes before the short spec) |
| `OptionParser::InvalidOption`, `MissingArgument`, `InvalidArgument`, `NeedlessArgument`, `AmbiguousOption`, `AmbiguousArgument` | one type `OptionParserError`, with `get_kind(e)` = `"InvalidOption"`, ... | differs: no hierarchy, so `rescue OptionParserError` stands for `rescue OptionParser::ParseError` |
| `e.message`, `e.args`, `e.reason` | `Exception.message(e)`, `OptionParserError.get_args(e)`, `OptionParserError.reason(e)` | same text |
| `--help`, `--version` handled by OptionParser itself (prints and exits) | same | same (phase 2): an undeclared `--help` (or a prefix, `--he`) prints the help and exits 0; `--version` prints `ver` and exits, or aborts with `prog: version unknown`. Declared options win, as Ruby |
| `op.warn(msg)`, `op.abort(msg)` | `OptionParser.warn(op, msg)`, `OptionParser.abort(op, msg)` | same: `prog: msg` on stderr (`IO.stderr`); abort exits 1. The message is required (Ruby defaults to `$!`) |
| `ARGV` as the default argv | `parse(op)`, `parse!(op)`, ... | same, but `parse!(op)` cannot shorten ARGV: Sake's `ARGV` gives a new Array at each use ([optparse_bug_argv_copy.sake](optparse_bug_argv_copy.sake)). Write `args = ARGV; OptionParser.parse!(op, args)` |
| `ARGV.options`, `ARGV.getopts` | — | missing |
| acceptors `Numeric`, `DecimalInteger`, `OctalInteger`, `TrueClass`, `Array` (comma lists), `Regexp` patterns, `OptionParser#accept` | — | missing |
| `op.environment`, `op.load`, completion scripts, `on_head` | — | missing |

## Differences from Ruby, and why

- **Blocks.** These are not values in Sake ([spec §7](../../docs/spec.md)), so `on` cannot keep one.
  Ruby's `into:` is the form that needs no block, and it becomes the only form. A value that a
  Ruby block would convert (for example `{ |v| v.split(",") }`) is converted after `parse` returns.
- **Keyword arguments.** `into:` is a keyword parameter, as in Ruby (it was a third positional
  argument in phase 2). Ruby's `parse(*argv, into:)` also takes the arguments spread out; Sake takes
  one Array (no rest parameters). A misspelled keyword is a static error:
  `OptionParser.parse(op, argv, in: h)` → `error: OptionParser.parse has no keyword parameter `in``,
  and the old positional form `parse(op, argv, h)` → `wrong number of arguments ... (given 3,
  expected 1..2)`.
- **Up to four arguments.** Ruby's `on(*args)` sorts its arguments by their content (`-x`,
  `--xx`, a class, an Array, a description). Sake has optional parameters but no rest parameters, so
  `on` takes up to four (`on(op, a, b = "", c = "", d = "")`) and sorts them the same way. One switch
  has one short and one long form.
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

- ~~`ARGV`, `exit`, `warn`~~: added; used in phase 2. `ARGV` as one shared, changeable Array is still
  wanted (see the bug repro above).
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

## Phase 2

- **One `on` again**: `on_type` is gone. `on(op, a, b = "", c = "", d = "")` and `on_tail` sort their
  arguments by content as Ruby, so the type goes in any position and `""` placeholders are no longer
  written (`on(op, "--nodesc")`, `on(op, "-q", "Quiet")`).
- **Defaults**: `parse`/`order`/`permute` and their `!` forms take `argv = ARGV, into = Hash[]`;
  `getopts(op, argv, short, long = String[])`.
- **Built-ins used**: `exit` for Ruby's officious `--help` and `--version`, `warn` for `OptionParser.warn`
  / `abort`, `ARGV` as the default argv. New accessor `version` and `ver`.
- **Fix**: `getopts` used `parse!` (permute); Ruby's stops at the first non-option. The new test
  case (`"-a", "x", "-b"`) caught it.
- No tables or scans to change: the parser works on whole arguments already. 

Speed (600 parses of 12 arguments, 30 help texts). CPU s (user+sys) of `bin/sake` on `experiments/2026-10-03-sakelib-port/phase2/bench_optparse.sake`, the phase-1 library (`phase2/before/`) and this one interleaved, 3 runs each, by `phase2/run_date_optparse_logger_benchmark.sh` (raw: `result_date_optparse_logger_benchmark.txt`; base commit af197cd). The machine was shared, load average about 36 on 16 CPUs. Startup with the four libraries loaded and nothing run is 0.69-0.70 s of each run.

| | run 1 | run 2 | run 3 |
|---|---|---|---|
| before | 3.22 | 3.18 | 3.11 |
| after | 3.35 | 3.35 | 3.33 |

Result: about 5% slower, outside the spread; nothing on the parse path changed except calls through functions with optional parameters, so that is the likely cost (not isolated).

## Keyword arguments

- `parse`, `order`, `permute` and their `!` forms take `argv = ARGV, into: Hash[]`; the internal
  call in `getopts` and the test use `into: h`, as `optparse.rb` does. New test cases:
  `permute`, `order`, `permute!` with `into:`.

## IO and optional blocks

`warn` and `abort` write `prog: msg` with `IO.puts(IO.stderr, ...)` (Ruby: `Kernel#warn`, so
`$stderr`); the built-in `--help` and `--version` print with `IO.print(IO.stdout, ...)` (Ruby:
`puts`, so `$stdout`). Writing to `IO.stderr` flushes stdout first, so the order of the lines is
kept. Blocks for `on` and `OptionParser.new { }` are still missing: `block_given?` makes a block
optional, but a block still cannot be stored for `parse` to call later.

## Review 2026-10-05 (class body, initialize)

- Fields reordered to Ruby's `OptionParser.new(banner = nil, width = 32, indent = " " * 4)`, so
  `OptionParser.new("Usage: x")` sets the banner as in Ruby. `def initialize(op)` creates the list of
  switches (was: `list = nil` and a lazy `items(op)`); `--types` now shows `OptionParser.list` as an
  Array, no longer `nil | Array`.
- `getopts` declares its switches with the optional arguments left out (`on(g, "-#{c}")`).
- Still missing: `OptionParser.new { |o| ... }` (`new` takes no block); the exception hierarchy
  (`InvalidOption < ParseError`) is one type with a `kind`, built by `OptionParserError.make`
  because `message` is the first field and is computed from the others.
