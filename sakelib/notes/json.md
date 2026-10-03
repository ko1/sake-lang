# json

`sakelib/json.sake` ports the commonly used API of Ruby's json gem (checked against json 2.20.0 on Ruby
4.0.2). Values are plain Sake values, as in Ruby: an object is a Hash, an array an Array, then String,
Integer, Float, true/false, and nil. The parser and generator are written in Sake. They follow the C
extension's behavior, including its error messages (`unexpected character: 'x' at line 1 column 4`),
its float format (`1e+20`, `0.00000015`), its nesting limits, and its acceptance of comments.
`test/sakelib/json.sake` prints the same 109 lines as `json.rb`, including 42 malformed inputs with
their messages.

Earlier work reused: the overall shape of `experiments/2026-10-03-libraries/json/lib.sake` (a parser
state class with `@pos`, `case c in "{" ...`, plain values). The parser was rewritten to match Ruby's
order of checks and messages.

## API

| Ruby | Sake | |
|---|---|---|
| `JSON.parse(s)` | `JSON.parse(s)` | same |
| `JSON.parse(s, symbolize_names: true, allow_nan:, allow_trailing_comma:, max_nesting:)` | `JSON.parse_with(s, {symbolize_names: true, ...})` | differs (no keyword arguments) |
| `JSON.parse(s, object_class:, array_class:, decimal_class:, create_additions:, freeze:)` | | missing |
| `JSON.parse(s, allow_control_characters:, allow_invalid_escape:, allow_duplicate_key:)` | | missing (easy to add) |
| `JSON.parse!(s)` | | missing |
| `JSON.generate(obj)` | `JSON.generate(obj)` | same |
| `JSON.generate(obj, indent:, space:, space_before:, object_nl:, array_nl:, allow_nan:, max_nesting:)` | `JSON.generate_with(obj, {...})` | differs |
| `JSON.generate(obj, script_safe:, ascii_only:, strict:)` | | missing |
| `JSON.fast_generate(obj)` | `JSON.fast_generate(obj)` | same |
| `JSON.pretty_generate(obj)` | `JSON.pretty_generate(obj)` | same |
| `JSON.pretty_generate(obj, opts)` | `JSON.pretty_generate_with(obj, {...})` | differs |
| `JSON.dump(obj)` | `JSON.dump(obj)` | same (NaN allowed, no nesting limit) |
| `JSON.dump(obj, io)` | | missing (no IO values) |
| `JSON.load(s)` | `JSON.load(s)` | same for a String or nil (blank input gives nil, NaN allowed); no proc, no IO |
| `JSON.load_file(path)` | `JSON.load_file(path)` | same |
| `obj.to_json` | `Hash.to_json(h)`, `Array.to_json(a)`, `String.to_json(s)`, `Integer.to_json(n)`, `Float.to_json(f)` | differs; `nil.to_json`, `true.to_json` missing (nil and true/false have no namespace) |
| `JSON[s]`, `JSON(s)` | | missing (`JSON[...]` would be a typed-Array literal) |
| `JSON::ParserError` | `JSONParserError` | differs (no nested names) |
| `JSON::NestingError` | raised as `JSONParserError`, Ruby's message | differs (no subtype; Ruby's NestingError is a ParserError, so `rescue JSONParserError` catches it as in Ruby, also from `generate`) |
| `JSON::GeneratorError` | `JSONGeneratorError` | differs (name) |
| `JSON::ParserError#line`, `#column` | | missing (only in the message) |
| `JSON::Fragment`, `JSON::Coder`, `json/add/*`, `to_json(state)` protocol | | missing |

Generating takes nil, true, false, Integer, Float, String, Symbol (as a String), Array, Tuple (as an
array), Hash (keys by `to_s`, as Ruby), and anything else by its `to_s` as a JSON string. That last case
matches Ruby's `Object#to_json`, for example a Struct value gives `"#<struct Point x=1, y=2>"`. A
Record raises `JSONGeneratorError`, because Sake cannot list a Record's fields. A binary String that is
valid UTF-8 is accepted, as in json 2.20 (without the deprecation warning). Any other binary String
raises with Ruby's message.

## What differs from Ruby, and why

- **Options.** Sake has no keyword arguments and no optional parameters, so each option-taking call
  is a separate `_with` operation that takes a Record, as `csv` does. A missing field takes Ruby's
  default. The fields are read with `(o in {allow_nan: x}) ? x == true : d`.
- **Exception names.** `JSON::ParserError` cannot be written, because namespaces do not nest. Sake also
  has no exception hierarchy, so `NestingError` is not its own type: it is raised as
  `JSONParserError`, which is what `rescue JSON::ParserError` catches in Ruby anyway.
- **`to_json` per type.** Ruby's `obj.to_json` is dispatch on the receiver. In Sake it is one operation
  per built-in type (`class Hash; def to_json(h)`). nil, true, and false have no namespace to add it to.
- **Error columns** are byte columns, as in Ruby. The quoted fragment is cut at 32 bytes on character
  boundaries, which matches Ruby's trimming of a trailing multibyte character. It was checked on the
  inputs in the test, not proven equal in general.
- **Floats.** json 2.20 prints floats with its own fpconv/grisu2 code, not `Float#to_s`. The port takes
  the shortest digits from `Float.to_s` and applies fpconv's layout rules. grisu2 is not always
  shortest, so a rare float may print differently.
- **Speed.** The test (about 60 parses and 30 generates of small documents) runs in about 6 s, most of it
  in checking.

## Typing note

`parse` and `parse_with` share one parser, so even `JSON.parse(s)` is inferred as `Hash[String | Symbol
=> ...]`: the Symbol keys of `symbolize_names` leak into every call. A caller that treats a key as a
String must narrow it first. Avoiding this would take two copies of the parser, because a flag value
cannot select a type. As with the earlier library, a parsed value is the full recursive union, and
callers narrow with `if v in Hash`. The test's config example does this.

## Built-ins needed but missing

- `String.index(s, t, start)` (Ruby's optional start offset): scanning for `*/` and `\n` from a
  position needs it. I used `String.index(src[pos, len - pos], t)` plus the offset, which copies the
  rest of the string.
- `Float::NAN` / `Float::INFINITY` (or `Float.nan` / `Float.infinity`): needed for `allow_nan`. I
  used `0.0 / 0.0` and `1.0 / 0.0`.
- A way to list a Record's fields (`Record.to_h`): without it, `JSON.generate({a: 1})` cannot work.
  Ruby code writes `{a: 1}` for a Hash, and in Sake that is a Record.
- `String.b(s)` (a binary copy): checking a binary String as UTF-8 needed a copy first, which I wrote
  as `String[s].Array.join("")`.
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
8. When I made the generator's nesting error a `JSONParserError` (as Ruby's), the test's
   `rescue JSONGeneratorError` around `generate(deep)` was reported:
   `the begin body never raises JSONGeneratorError [rescue]`. This was a real catch, reported before
   running.
9. `--strict=3`: `c = @src[@pos]` after a `@pos >= @len` guard gave `[index-nil]` (the guard is on a
   field, and `x[k]` is not narrowed by it), and `mant, ex = String.split(t, "e")` did too →
   `while (c = @src[@pos]) && c != "\""`, and `String.partition` (a Tuple) instead of `split`. The
   library is now clean at `--strict=3`. At `--strict=4`, the expected `[unrescued]` reports for its
   raises remain.
