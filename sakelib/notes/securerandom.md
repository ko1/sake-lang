# securerandom (Ruby's `require "securerandom"`)

`sakelib/securerandom.sake`: `module SecureRandom` (module functions), 12 operations of Ruby's
`Random::Formatter` as SecureRandom has them. Test: `test/sakelib/securerandom.{sake,rb}`. The values are
random, so the test prints formats, lengths, ranges and alphabets over many draws; identical output with
`--strict` (also clean at `--strict=1 -c` and `--strict=2 -c`).

Bytes come from `/dev/urandom`, as Ruby's do on Linux. Sake has no `Random.urandom` / getrandom and no
"read n bytes" on a file (`IO.read` reads to the end, which a device never reaches), so `gen_random`
opens the device and appends `IO.gets` lines (random length, about 256 bytes each) until it has n bytes.
It reopens the device per call. Not available in the browser playground.

## API

| Ruby | Sake | |
|---|---|---|
| `SecureRandom.random_bytes(n = nil)`, `bytes(n)`, `gen_random(n)` | same | same (binary String; nil → 16; negative → `ArgumentError: negative string size (or size too big)`) |
| `hex(n = nil)` | same | same (2n lowercase hex digits) |
| `base64(n = nil)`, `urlsafe_base64(n = nil, padding = false)` | same | same (through sakelib's `Base64`) |
| `random_number(n = 0)`, `rand(n = 0)` | same | same: Integer > 0 → 0...n, Float > 0 → [0, n), an Integer or Float Range → a value in it, anything not positive or an empty Range → a Float in [0, 1). Uniform by rejection over just enough bytes (any size: `2 ** 100` works) |
| `random_number("x")` | — | differs: a `type` report before running (case/in has no String branch); Ruby raises `ArgumentError: invalid argument - x` |
| `alphanumeric(n = nil, chars: ALPHANUMERIC)` | same | same; an empty `chars` raises `ArgumentError` (Ruby loops forever) |
| `uuid`, `uuid_v4` | same | same (version 4, RFC 9562 variant) |
| `uuid_v7` | same | same (48-bit Unix milliseconds, then random bits; Ruby's optional `extra_timestamp_bits:` missing) |
| `Random::Formatter::ALPHANUMERIC` | `SecureRandom.alphanumeric_chars` | differs: a function (`once`), no value constants |
| `SecureRandom.random_number` of a Float Range with an endless end | — | `NoMatchingPatternError` from `hi => Float \| Integer` |

## Frictions (wrote first → message → wrote instead)

- `Integer.to_s(n, 16)` → `wrong number of arguments for Integer.to_s (given 2, expected 1)` →
  `format("%x", n)` / `format("%012x", ms)`. Integer has no base argument in `to_s`.
- `Array.map(1..2000) { ... }` in the test (Ruby habit) → `Array.map: argument 1 must be Array, but is
  Range[Integer]` (eight reports at `--strict=1`) → `Range.map(1..2000)`. Clear message.
- `Array[*Range.to_a("A".."Z"), ...]` for the alphabet passed every check and failed at run time:
  `TypeError: Range.to_a: this operation needs a Range that starts with an Integer` →
  `String.chars("ABC...789")`. Repro: `notes/securerandom_bug_string_range_to_a.sake` (the checker knows
  the Range is `Range[String]` but reports nothing even at `--strict=4`).
- `(x).abs` in the test → call on a value → `Integer.abs(x)`.
- No bounded read on an IO: `IO.gets` on a device is the workaround (above).

## Language features used

- **Optional positional parameters with expression defaults** (helped): `def hex(n = nil)`,
  `def random_number(n = 0)`, Ruby's signatures exactly.
- **Keyword argument with an expression default** (helped): `def alphanumeric(n = nil, chars: alphanumeric_chars)`;
  `urlsafe_base64` passes `padding:` on with the shorthand.
- **`once`** (helped): the 62-character alphabet, built once and shared like Ruby's constant.
- **`x => T`** (helped): `n => Integer` in `gen_random` (Ruby raises TypeError for a non-Integer size), and
  `hi => Float | Integer`, which is also the nil check `--strict` asked for on `Range.end`.
- **`case/in` on the argument type**: `random_number` takes Integer, Float, Range, nil in one operation; the
  checker gives `Float | Integer` per call (Ruby's result type also depends on the value).
- Not needed: `initialize`, `private attr_*`, `*rest`, `**opts`, `block_given?`, `&b`.

## Checker findings before the test passed

- `--strict=1 -c`: the eight `Array.map` on a Range reports in the test (above).
- `--strict=2 -c`: `Kernel.Float: argument 1 may be nil (Float | nil) [nil]` in `random_number`, from
  `Range.end` of a Range (an endless Range has a nil end) → `hi => Float | Integer` before `Float(hi)`.

## `--types`

No fields. The only unions: `SecureRandom.random_number` / `rand` results are `Float | Integer` where the
argument is an Integer (0 or a negative Integer gives a Float, as in Ruby), so the test's Arrays of draws
are `Float | Integer`. One `partial` check: `lo => Float` in the Range branch, where `Range.begin` is
`Float | nil`.
