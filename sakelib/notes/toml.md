# toml

`sakelib/toml.sake` parses and generates a subset of TOML 1.0, after the toml-rb gem (`TomlRB.parse` /
`TomlRB.dump`); the reference is `test/sakelib/ref/toml.rb`. `test/sakelib/toml.sake` prints the same 83
lines as `toml.rb` (a full document, numbers, strings, 21 malformed inputs, dump and re-parse).
421 lines, 39 functions.

## API

| Ruby (toml-rb) | Sake | |
|---|---|---|
| `TomlRB.parse(s)`, `(s, symbolize_keys: true)` | `TOML.parse(s)`, `(s, symbolize_keys: true)` | same |
| `TomlRB.load_file(path, symbolize_keys:)` | `TOML.load_file(path, symbolize_keys:)` | same |
| `TomlRB.dump(h)` | `TOML.dump(h)` | same (own layout, below) |
| `TomlRB::ParseError` | `TOMLParseError` (fields `message`, `line`) | differs (name; line as a field) |
| dates, times, offset date-times | | missing (raise `TOMLParseError`) |

Supported: comments; bare, quoted and dotted keys; `[tables]` and `[[arrays of tables]]` (also nested);
basic, literal and multi-line strings with all escapes (`\uXXXX`, `\UXXXXXXXX`, line-ending backslash);
integers (decimal, `0x`, `0o`, `0b`, underscores); floats (exponents, `inf`, `nan`); booleans; arrays over
lines with comments and trailing commas; inline tables. Checked: duplicate keys, a table defined twice,
a key redefined as a table, `[t]` over an array of tables, `[[a]]` over a static array, bad numbers
(`01`, `1.`, `.5`, `0b102`), bad escapes, junk after a value.

`dump`: simple pairs first, then `[table]` sections (a table holding only tables gets no header of its
own), `[[name]]` for an Array of Hashes, other Arrays and Hashes inline (`{ x = 1 }`).

## What differs, and why

- No nested names: `TOMLParseError`, with `line` as a field (`TOMLParseError.line(e)`), since an
  exception type is a Struct type with fields.
- Inline tables are not closed: `a = {b = 1}` followed by `[a.c]` is accepted. The check wants a set of
  Hash *identities*; Sake's Set compares by content (two empty inline tables are one element), so I
  dropped it rather than track paths.

## Frictions

1. `def table?(v) = v in Hash` in a module → `only def, include, ... are allowed in a class/module body`.
   Ruby parses it as `(def ...) in Hash` too; the message points at the class-body rule rather than at
   precedence → `def table?(v) = (v in Hash)`.
2. `elsif table_array?(v)` then `v => Array` → at level 1, `` `=> Array`: the value is Integer | String |
   ... | Range[Integer], which does not match [type] `` (for one recursive call whose Hash has no Arrays).
   A predicate function does not narrow, and the branch is analyzed for a call that never takes it →
   `elsif (v in Array) && table_array?(v)`, which narrows.
3. Wanted a Set of Hashes by identity (closed inline tables) → dropped the check (above).
4. `Integer(body, base)` does not exist (one argument) → `String.oct("0x#{body}")`, which reads 0x/0o/0b
   prefixes as in Ruby.

## New language features used

- `T.new` + `initialize`: `TOMLParser.new(s, symbolize_keys)`; `initialize` checks `@src => String`,
  computes `@len`, sets `@current = @root`. Helped.
- `private attr_reader root = Hash[], current = nil, headers = Set[], array_tables = Set[]` and
  `private attr_accessor pos = 0`: the parser's state, invisible outside, fresh per `new`. Helped.
- Keyword arguments: `TOML.parse(s, symbolize_keys: true)`, passed on with `symbolize_keys:` shorthand.
- `once` for the escape tables; `x => T` (`h => Hash` in `dump`, as `TomlRB.dump` raises on a non-Hash).
- `*rest`, `**opts`, `block_given?`: not needed.

## Checker findings

- `--strict=1`: two `type` reports at `v => Array` (friction 2), fixed by narrowing with `in`.
- `--strict=2`: none after that.

## Types (`--types`)

- `TOMLParser.root`, `current`: the recursive value union `Hash[String | Symbol => true|false | Float |
  Integer | String | Array[...] | Hash[...]]`. Symbol comes from `symbolize_keys:` and leaks into every
  parse, as json's `symbolize_names` does: a flag cannot select a type.
- `headers`, `array_tables`: `Set[String[]]` (key paths). Two `partial` checks: the `t => Hash` in `dump`
  (an Array of tables may hold anything) and `cur => Hash`.
