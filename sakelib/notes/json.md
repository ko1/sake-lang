# json

`sakelib/json.sake` ports the commonly used API of Ruby's json gem (checked against json 2.20.0 on Ruby
4.0.2). Values are plain Sake values, as in Ruby: an object is a Hash, an array an Array, then String,
Integer, Float, true/false, and nil. The parser and generator are written in Sake. They follow the C
extension's behavior, including its error messages (`unexpected character: 'x' at line 1 column 4`),
its float format (`1e+20`, `0.00000015`), its nesting limits, and its acceptance of comments.
`test/sakelib/json.sake` prints the same 137 lines as `json.rb`, including 42 malformed inputs with
their messages.

Earlier work reused: the overall shape of `experiments/2026-10-03-libraries/json/lib.sake` (a parser
state class with `@pos`, `case c in "{" ...`, plain values). The parser was rewritten to match Ruby's
order of checks and messages.

## API

| Ruby | Sake | |
|---|---|---|
| `JSON.parse(s)` | `JSON.parse(s)` | same |
| `JSON.parse(s, symbolize_names: true, allow_nan:, allow_trailing_comma:, max_nesting:)` | `JSON.parse(s, symbolize_names: true, ...)` | same |
| `JSON.parse(s, {symbolize_names: true})` (opts Hash) | | missing (keywords only) |
| `JSON.parse(s, object_class:, array_class:, decimal_class:, create_additions:, freeze:)` | | missing |
| `JSON.parse(s, allow_control_characters:, allow_invalid_escape:, allow_duplicate_key:)` | | missing (easy to add) |
| `JSON.parse!(s)` | `JSON.parse!(s)` | same (NaN allowed, no nesting limit; 2026-10-05) |
| `JSON.generate(obj)` | `JSON.generate(obj)` | same |
| `JSON.generate(obj, indent:, space:, space_before:, object_nl:, array_nl:, allow_nan:, max_nesting:)` | `JSON.generate(obj, indent: ..., ...)` | same |
| `JSON.generate(obj, opts)` (opts Hash or State) | | missing (keywords only) |
| `JSON.generate(obj, script_safe:, ascii_only:, strict:)` | | missing |
| `JSON.fast_generate(obj)`, `(obj, array_nl: " ", ...)` | `JSON.fast_generate(obj)`, `(obj, array_nl: " ", ...)` | same |
| `JSON.pretty_generate(obj)` | `JSON.pretty_generate(obj)` | same |
| `JSON.pretty_generate(obj, indent: "\t", ...)` | `JSON.pretty_generate(obj, indent: "\t", ...)` | same |
| `JSON.dump(obj)` | `JSON.dump(obj)` | same (NaN allowed, no nesting limit) |
| `JSON.dump(obj, io)` | `JSON.dump(obj, io)` | same: writes to the IO and returns it (phase 3) |
| `JSON.load(s)`, `JSON.load(io)` | `JSON.load(s)`, `JSON.load(io)` | same for a String, an IO (read to its end), or nil; `""` gives nil, blank `"  "` raises ParserError, NaN allowed; no proc |
| `JSON.load_file(path)`, `(path, symbolize_names: true, ...)` | `JSON.load_file(path)`, `(path, symbolize_names: true, ...)` | same |
| `obj.to_json` | `Hash.to_json(h)`, `Array.to_json(a)`, `String.to_json(s)`, `Integer.to_json(n)`, `Float.to_json(f)` | differs; `nil.to_json`, `true.to_json` missing (nil and true/false have no namespace) |
| `JSON[s]`, `JSON(s)` | | missing (`JSON[...]` would be a typed-Array literal) |
| `JSON::ParserError` | `JSON::ParserError` | same name (nested since 2026-10-10; was `JSONParserError`) |
| `JSON::NestingError` | raised as `JSON::ParserError`, Ruby's message | differs (no subtype; Ruby's NestingError is a ParserError, so `rescue JSON::ParserError` catches it as in Ruby, also from `generate`) |
| `JSON::GeneratorError` | `JSON::GeneratorError` | same name (was `JSONGeneratorError`) |
| `JSON::ParserError#line`, `#column` | `JSON::ParserError.line(e)`, `e.JSON::ParserError.column` | same (nil for a nesting error, as Ruby; 2026-10-05) |
| `JSON::Fragment`, `JSON::Coder`, `json/add/*`, `to_json(state)` protocol | | missing |

Generating takes nil, true, false, Integer, Float, String, Symbol (as a String), Array, Tuple (as an
array), Hash (keys by `to_s`, as Ruby), and anything else by its `to_s` as a JSON string. That last case
matches Ruby's `Object#to_json`, for example a Struct value gives `"#<struct Point x=1, y=2>"`. A
Record raises `JSON::GeneratorError`, because Sake cannot list a Record's fields. A binary String that is
valid UTF-8 is accepted, as in json 2.20 (without the deprecation warning). Any other binary String
raises with Ruby's message.

## What differs from Ruby, and why

- **Keyword arguments.** The options are keyword parameters with Ruby's defaults
  (`pretty_generate` has its own: `indent: "  "`, `space: " "`, `object_nl: "\n"`, `array_nl: "\n"`).
  A misspelled option, which the former Record argument ignored silently, is now a static error:
  `JSON.parse(s, symbolize_name: true)` → `error: JSON.parse has no keyword parameter
  `symbolize_name`` / `hint: did you mean `symbolize_names:`?`. Ruby's positional opts Hash is not
  taken (`k: v` to a Sake function is always a keyword).
- **Exception names.** `JSON::ParserError` and `JSON::GeneratorError` are nested in `module JSON` as in
  Ruby (since 2026-10-10; before that they were `JSONParserError` / `JSONGeneratorError`), and the two
  state types are `JSON::Parser` / `JSON::State`, Ruby's names (were `JSONParserState` /
  `JSONGeneratorState`). Sake has no exception hierarchy, so `NestingError` is not its own type: it is
  raised as `JSON::ParserError`, which is what `rescue JSON::ParserError` catches in Ruby anyway.
- **`to_json` per type.** Ruby's `obj.to_json` is dispatch on the receiver. In Sake it is one operation
  per built-in type (`class Hash; def to_json(h)`). nil, true, and false have no namespace to add it to.
- **Error columns** are byte columns, as in Ruby. The quoted fragment is cut at 32 bytes on character
  boundaries, which matches Ruby's trimming of a trailing multibyte character. It was checked on the
  inputs in the test, not proven equal in general.
- **Floats.** json 2.20 prints floats with its own fpconv/grisu2 code, not `Float#to_s`. The port takes
  the shortest digits from `Float.to_s` and applies fpconv's layout rules. grisu2 is not always
  shortest, so a rare float may print differently.
- **Speed.** The parser works in byte positions (phase 2), so reading at a position does not
  re-count characters on non-ASCII text, but each token still costs dozens of interpreted operations:
  parsing 15 KB takes about 3 s of CPU (see Phase 2).

## Typing note

`parse` with and without `symbolize_names:` is one parser, so even `JSON.parse(s)` is inferred as `Hash[String | Symbol
=> ...]`: the Symbol keys of `symbolize_names` leak into every call. A caller that treats a key as a
String must narrow it first. Avoiding this would take two copies of the parser, because a flag value
cannot select a type. As with the earlier library, a parsed value is the full recursive union, and
callers narrow with `if v in Hash`. The test's config example does this.

## Built-ins needed but missing

- `Float::NAN` / `Float::INFINITY` (or `Float.nan` / `Float.infinity`): needed for `allow_nan`. I
  used `0.0 / 0.0` and `1.0 / 0.0`.
- A way to list a Record's fields (`Record.to_h`): without it, `JSON.generate({a: 1})` cannot work.
  Ruby code writes `{a: 1}` for a Hash, and in Sake that is a Record.
- `Integer.chr(cp, "UTF-8")`: I used `format("%c", cp)` instead, as the earlier library did.

## Friction

1. `M.f(s, symbolize_names: true)` → `keyword arguments are not supported` → `JSON.parse_with(s, {symbolize_names: true})`.
2. `if opts in {symbolize_names: true}` → `only Record patterns that bind fields are supported: in {x:, y: name}`
   → `(o in {symbolize_names: x}) ? x == true : d`. A pattern with a literal value would read better.
3. `max_nesting in Integer ? max_nesting : 0` → Prism syntax error (`unexpected '?'`), the same as in
   Ruby → `(max_nesting in Integer) ? ...`.
4. `String.index(@src, "\n", @pos)` → `wrong number of arguments for String.index (given 3, expected 2)`
   → search a slice, then add the offset.
5. `String.sub(msg, "%s", frag)` printed `'` for the fragment `'\'`. The backslash in the replacement
   was read as a back reference, which Ruby does too (my bug, not Sake's) → split around `%s` instead.
6. In the test, `cfg["server"]["port"]` on a parsed document →
   `Indexable.[]: the receiver may be true|false | Float | Integer | nil, which cannot be indexed` and
   `the index must be Integer, but is String` → `if cfg in Hash` / `if server in Hash`. This is
   correct, but the second message reads oddly for a Hash lookup (as the earlier library's notes say).
7. `Array.size(JSON.parse(...))` → a 300-character union in the message → assign it to a local and
   narrow with `if x in Array`.
8. When I made the generator's nesting error a `JSON::ParserError` (as Ruby's), the test's
   `rescue JSON::GeneratorError` around `generate(deep)` was reported:
   `the begin body never raises JSON::GeneratorError [rescue]`. This was a real catch, reported before
   running.
9. `--strict=3`: `c = @src[@pos]` after a `@pos >= @len` guard gave `[index-nil]` (the guard is on a
   field, and `x[k]` is not narrowed by it), and `mant, ex = String.split(t, "e")` did too →
   `while (c = @src[@pos]) && c != "\""`, and `String.partition` (a Tuple) instead of `split`. The
   library is now clean at `--strict=3`. At `--strict=4`, the expected `[unrescued]` reports for its
   raises remain.

## Phase 2

- Names restored: `parse_with` → `parse(s, o = nil)`, `generate_with` → `generate(v, o = nil)`,
  `pretty_generate_with` → `pretty_generate(v, o = nil)`; `load_file(path, o = nil)` and
  `fast_generate(v, o = nil)` gained Ruby's options argument. The old names are removed; the test
  calls `JSON.parse(s, {symbolize_names: true})` exactly as `json.rb` does, and also
  `load_file(path, {...})` (with `File.delete`) and `fast_generate(v, {...})`.
- The parser now keeps byte positions (`String.byteslice`, `String.getbyte`, `String.byteindex`):
  whitespace, `//` and `/* */` comments, string bodies (to the next `"`, `\`, or control
  character), escapes (to the next `\`), and digit runs are each one `byteindex` instead of a loop
  over characters, with no copies of the rest of the source. A number whose run of number
  characters matches the JSON grammar is converted at once; anything else takes the old checks, so
  the messages are unchanged. `hex4` matches `\G\h{4}` at the position.
- Generator: the per-character escape loop is one `String.gsub(s, re, escapes)` with a Hash built
  once (`def escapes = once { ... }`); `String[s].Array.join("")` became `String.b(s)`.
- The test gained 8 malformed and commented inputs with non-ASCII text before the error, to check
  the byte columns and fragments; output is identical to `json.rb`.
- Speed (`phase2/bench_json.sake`: parse and generate a 15 KB document of 150 objects with escaped
  and Japanese strings; CPU s of the whole `bin/sake --strict` run, about 1.0 s of it checking;
  3 runs, load about 37 on 16 cores): before 4.76 / 5.05 / 4.98, after 4.67 / 4.70 / 4.62. Only
  about 5%: the time is the interpreter's cost per operation (about 20-30 µs per call or loop step
  measured on this machine), and a token still takes dozens of them; the old per-character reads were
  not the main cost at this size.
- Found: `String.match` on a String cut inside a character by `String.byteslice` crashes the
  interpreter with Ruby's internal backtrace instead of raising a catchable `ArgumentError`
  (`sakelib/notes/json_bug_match_broken_string.sake`). The parser avoids matching byte slices that may
  cut a character.

## Keyword arguments

- `parse`, `load_file`, `generate`, `fast_generate`, `pretty_generate` take Ruby's keywords instead of
  a Record (`o = nil`); the `opt_bool` / `opt_str` / `opt_nesting` readers are gone. The test and
  `json.rb` now write the same calls (`JSON.parse(s, symbolize_names: true)`), and add cases for
  keywords in another order, `max_nesting: false` / `nil`, and `generate(..., max_nesting: 1)`.
- Passing keywords on needs `k: k` (Ruby 3.1's shorthand `k:` is `unsupported syntax: implicit `k:``).

## IO and optional blocks (phase 3)

- `JSON.dump(obj, io = nil)`: with an IO (`IO.stdout`, a `File.open`), writes the text and returns
  the IO, as Ruby; without, returns the String.
- `JSON.load(source)` takes a String, an IO, or nil. Fix found by the test: `JSON.load("  ")` gave
  nil (the input was stripped); Ruby's json 2.20 gives nil only for `""` and raises ParserError for
  blank text, and now so does the port.
- Two IO problems found, worked around: `in IO` is rejected ("`IO` is not a type",
  `json_bug_io_not_a_pattern_type.sake`), so `load` matches `nil` and `String` and treats the rest as
  an IO; and an IO is not `==` to itself (`json_bug_io_equality.sake`), so the test prints the IO
  `dump` returns (`#<File:...>`) instead of comparing it.
- No optional block: Ruby's `JSON.load(s, proc)` takes a proc, not a block.

## Review against the 2026-10-05 language

- `JSON::Parser` / `JSON::State` convert their options in `initialize` (flags to
  true/false, `max_nesting` false/nil to 0, the source's byte size), as Ruby's `JSON::Parser.new` /
  `JSON::State.new`; `pos`/`depth` have defaults, so `JSON.parse` passes only the source and options.
- `JSON.load` matches `in IO` (the workaround for `json_bug_io_not_a_pattern_type.sake`, fixed, is
  gone). The test still prints the IO `dump` returns rather than comparing it (the .rb does the same).
- Keywords passed on with the `k:` shorthand (`load_file`, `fast_generate`, `pretty_generate`).
- Still unlike Ruby: no `**opts`, so `fast_generate`/`pretty_generate` repeat all keywords
  (json.sake:501, 507); `nil.to_json` / `true.to_json` have no namespace (json.sake:565-583).

## 2026-10-05

- Internal state is private: `JSON::Parser` and `JSON::State` declare their fields with
  `private attr_reader` / `private attr_accessor`, so no reader leaks outside. The parse driver
  (`skip_ws`, `value`, the end-of-stream check), which `JSON.parse` wrote with
  `JSON::Parser.pos(ps)` / `len(ps)`, moved into `JSON::Parser.parse(ps)`.
- The states take their options by keyword, with Ruby's names and defaults on the fields:
  `JSON::Parser.new(s, symbolize_names:, allow_nan:, allow_trailing_comma:, max_nesting:)`,
  `JSON::State.new(indent:, space:, ...)`, as Ruby's `JSON::Parser.new(src, **opts)` /
  `JSON::State.new(**opts)`.
- New: `JSON.parse!(s)`, and `JSON::ParserError` has Ruby's `line` / `column` fields (nil for a nesting
  error). The test checks both.
- `Float::NAN` / `Float::INFINITY` replace `0.0 / 0.0` / `1.0 / 0.0` in the parser and the test.
- Still not Ruby's API: `fast_generate` / `pretty_generate` / `load_file` / `parse!` still repeat the
  keyword list. They could take `**opts`, but a Hash cannot be spread into a call (`g(v, **opts)` is
  "`**` is not supported"), and reading options from the Hash would lose the static check of a
  misspelled keyword. No `NestingError` subtype, `nil.to_json`, `JSON[...]`, or opts Hash argument.
- Bug: a field default cannot read an earlier field, unlike a parameter default
  (`json_bug_field_default_reads_earlier_field.sake`); `len` is still set in `initialize`.
