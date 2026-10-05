# time (Ruby's `require "time"`)

`sakelib/time.sake`: operations added to the built-in `Time` (`class Time`): `Time.parse`,
`Time.strptime`, `Time.xmlschema`, `Time.httpdate`, `Time.rfc2822` / `rfc822` (each both the parser,
given a String, and the formatter, given a Time), `Time.zone_offset`; helpers in `module TimeCore` and a
`TimeParts` class (Ruby's `Date._parse` hash). 7 operations covering 13 Ruby methods. Test:
`test/sakelib/time.{sake,rb}`, identical output with `--strict` (also clean at `--strict=1 -c` and
`--strict=2 -c`), and also identical with `TZ=Asia/Tokyo`, `America/New_York`, `Australia/Lord_Howe`.

## Representation: a Time has no fixed offset

Sake's built-in Time is local or UTC (`Time.utc(t)` converts); there is no `Time.new(..., "+09:00")` or
`getlocal(off)`. So a string with an offset (`"+09:00"`, `"EST"`) gives **the same instant as a local
Time**, where Ruby keeps the offset: `Time.to_s(Time.parse("2024-01-02 03:04:05 +09:00"))` is
`2024-01-01 18:04:05 +0000` on a UTC machine, Ruby's is `2024-01-02 03:04:05 +0900`. A UTC zone
(`Z`, `UTC`, `UT`, `-00:00`, `-0000`; not `GMT` or `+00:00`, as Ruby's `zone_utc?`) gives a UTC Time, and
`httpdate` always does, as in Ruby. The test therefore prints each parsed Time as its instant in UTC plus
`utc?`. Times are built from the civil fields by integer arithmetic (days from civil) and `Time.at`, so
fractions (`Rational`) and overflow (`2024-02-30` is March 1, `24:00:00` and `23:59:60` roll over) follow
Ruby's `Time.local` / `Time.utc`.

## API

| Ruby | Sake | |
|---|---|---|
| `Time.parse(s, now = Time.now)` | same | differs: the common forms only: `Y-M-D` and `Y/M/D` anywhere, `YYYYMMDD[THHMMSS][zone]`, `D Mon [Y]`, `Mon D[,] [Y]`, asctime (year at the end), times `H:M[:S[.frac]]` with `am/pm` and a zone, `3pm`. Ruby's `Date._parse` heuristics (`M/D/Y`, era names, week dates, `limit:`) are missing. Missing fields come from `now` (in the string's zone, or local), as Ruby's `make_time`. Errors same: `no time information in "..."`, `mon out of range`, `hour out of range`, `min out of range`, `argument out of range` |
| `Time.strptime(s, fmt, now = Time.now)` | same | same for `Y C y m d e j H k I l M S L N s Q p P z Z b B h a A u w n t %` and `F T D R r c x X +`; text after the format is ignored, as Ruby. Error `invalid date or strptime format - 's' 'fmt'` same. `%U %W %G %V` missing |
| `Time.iso8601(s)`, `Time.xmlschema(s)` | `Time.xmlschema(s)` | differs: `Time.iso8601` is a built-in (the formatter) and cannot be redefined, so the parser is reached by `xmlschema` only. Same forms and errors (`invalid xmlschema format: "..."`) |
| `t.xmlschema(n = 0)`, `t.iso8601(n)` | `Time.xmlschema(t, n = 0)`, built-in `Time.iso8601(t, n)` | same |
| `Time.httpdate(s)` / `t.httpdate` | `Time.httpdate(s)` / `Time.httpdate(t)` | same (RFC 1123, RFC 850, asctime) |
| `Time.rfc2822(s)`, `rfc822` / `t.rfc2822` | same | same (`-0000` for a UTC Time) |
| `Time.zone_offset(zone)` | same | same, including the local zone's own abbreviation (`JST` under `TZ=Asia/Tokyo`); `year` argument missing |
| `Time#to_date`, `to_time`, `Time.json_create` ... | — | missing |
| result of `Time.parse` with an offset | a local Time | differs (above) |

## Frictions (wrote first → message → wrote instead)

- `def iso8601(x)` for the parser → a built-in cannot be redefined → the parser is only `Time.xmlschema(s)`.
  Ruby's class method / instance method pairs (`Time.iso8601(str)` vs `t.iso8601`) collide in one namespace;
  for the user-defined ones (`xmlschema`, `httpdate`, `rfc2822`), one operation takes either.
- `if x in Time; return ...; end; x => String; ...parse...` → callers got `Time | String` back
  (`Time.to_i: argument 1 must be Time, but can be String`, `--strict=1`) → `case x in Time then ... in String
  then TimeCore.parse_xmlschema(x) end`, which the checker narrows per call (date.md found the same).
- `Regexp.new(src, Regexp::IGNORECASE)` → `wrong number of arguments for Regexp.new (given 2, expected 1)`
  and `undefined function Regexp.IGNORECASE` → `Regexp.new("(?i)...")`.
- `Hash[...].fetch(m, m)` inside a block → call on a value → `Hash.fetch(table, m, m)` with the table from
  `once`.
- `def directive_re(c) = once do ... end[c]` (index the once'd Hash inline) → split into `directive_table`
  (once) and `directive_re(c) = directive_table[c]`.
- `Integer(sec, 10)` → `Kernel.Integer` takes one argument → `String.to_i`.
- Ruby's `now.getlocal(off)` (fill missing fields from `now` in the string's zone) → no fixed-offset Time
  → `Time.utc(Time.at(Time.to_i(now) + off))` and read its fields. Found only by running the test under
  `TZ=Asia/Tokyo` (the default UTC machine hides it).

## Language features used

- **Optional parameters with an expression default** (helped): `def parse(date, now = Time.now)`, Ruby's
  signature; `def xmlschema(x, fraction_digits = 0)`.
- **`attr_accessor` with `nil` defaults** (helped): `TimeParts.new`
  with no arguments for the parsers that fill fields one by one, `TimeParts.new(y, m, d, nil, h, mi, s)` for
  the fixed formats.
- **`once`** (helped): every regexp and the zone, month and strptime-directive tables, e.g.
  `def zone_table = once do ... end`.
- **`x => T`** (helped): `date => String` at the top of `parse` / `strptime`, as Ruby's TypeError.
- **`return` from inside a block** in `zone_offset` (`Array.each(...) { |t| return ... if ... }`) worked as in Ruby.
- Not needed: `initialize`, `private attr_*`, `*rest`, `**opts`, `block_given?`, `&b`.

## Checker findings before the test passed

- `--strict=1 -c`: `Time.to_i: argument 1 must be Time, but can be String` (the `if x in Time ... return`
  form above).
- `--strict=2 -c`: nothing beyond that. Fields of `TimeParts` are copied to locals and checked
  (`year ||= 1970`, `if yday`) before use.

## `--types`

- Fields: every `TimeParts` field is `Integer | nil` (`frac`: `nil | Rational`, `zone`: `nil | String`,
  `seconds`: `Integer | nil | Rational` for `%s` / `%Q`). nil means "not in the string", which is what
  `make_time` tests; a separate "found" flag per field would be noisier than Ruby's hash.
- No unknowns; no union results: `Time.xmlschema(s)` etc. are `Time` and `Time.xmlschema(t)` is `String`
  per call.
