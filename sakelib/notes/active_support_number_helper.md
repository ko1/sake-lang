# active_support_number_helper (ActiveSupport::NumberHelper)

`require "active_support_number_helper"` → `sakelib/active_support_number_helper.sake`. Test:
`test/sakelib/active_support_number_helper.{sake,rb}` (identical output; the `.rb` uses activesupport 8.1.3).

`ActiveSupport::NumberHelper.number_to_currency(n, options)` is `NumberHelper.number_to_currency(n, **keywords)`:
Ruby's options Hash is keyword parameters whose defaults are ActiveSupport's en defaults (`separator: "."`,
`delimiter: ","`, `precision: 2` for currency, `format: "%u%n"`...). A Record argument (`{precision: 3}`) was
considered and rejected: a Record is read by a pattern that raises `KeyError` for a missing field, so every call
would have to spell out all the options; keyword parameters give the defaults and a static `did you mean` for
a misspelled one.

## API

| Ruby | Sake | |
|---|---|---|
| `number_to_delimited(n, delimiter:, separator:)` (= ActionView `number_with_delimiter`) | both names | same |
| `number_to_rounded(n, precision: 3, significant:, strip_insignificant_zeros:, separator:, delimiter:, round_mode:)` (= `number_with_precision`) | both names | same, including `precision: nil` and BigDecimal rounding of Floats (1.005 → "1.01") |
| `number_to_currency(n, unit:, format:, negative_format:, precision: 2, ...)` | same keywords | same (negative zero rounds to "$0.00"; "-x" → "-$x") |
| `number_to_percentage(n, format: "%n%", precision: 3, ...)` | same | same |
| `number_to_human_size(n, precision: 3, significant: true, strip_insignificant_zeros: true, ...)` | same, plus `format:` | same ("1 Byte", "0 Bytes", "5120 ZB") |
| `number_to_human(n, units: {...}, format:, ...)` | `units:` a Hash unit name => label | same; missing: `units:` as an I18n scope String, pluralized unit labels (`one:`/`other:`) |
| `number_to_phone(n, area_code:, delimiter:, extension:, country_code:, pattern:)` | same | same |
| `locale:` on every helper | — | missing: no I18n; the en defaults are the keyword defaults |
| `delimiter_pattern:` on `number_to_delimited` | — | missing (the default `/(\d)(?=(\d\d\d)+(?!\d))/` only) |
| `round_mode:` | `:default`/`:half_up`, `:half_even`/`:banker`, `:half_down`, `:up`, `:down`/`:truncate`, `:ceiling`/`:ceil`, `:floor` | same |

9 operations ported (7 helpers + 2 ActionView names); 3 options missing.

## できたこと / できなかったこと

- できた: all seven converters, identical on 140 inputs including the edge cases (invalid Strings given back,
  nil → nil, `1e20`, `Rational(1, 3)`, 30-digit currency Strings, negative rounding to zero, `significant:` with
  `precision` below the digit count).
- **BigDecimal without BigDecimal.** ActiveSupport rounds a `BigDecimal(number.to_s)`, so `1.005` rounds to
  `1.01` (Float#round gives 1.0). Sake has no BigDecimal; the same arithmetic is exact on `Rational`:
  `String.to_r(Float.to_s(f))` reads the Float's shortest decimal form, `round_decimal(r, digits, mode)` rounds
  with integer `floor` and a half comparison (all nine BigDecimal modes in one `case`), and `decimal_string`
  prints `to_s("F")`. The number pipeline is then `Rational` all the way to the String, and the checker knows it
  (`Rational.abs`, `Rational.to_f`).
- できなかった: I18n. `locale:` and `units: "scope"` are lookups in a translation tree; nothing in Sake plays that
  role, and the gem's own defaults are the only data, so they are the keyword defaults.

## 書き心地

- Ruby's converters merge one `options` Hash over `DEFAULTS` and read `options[:precision]` everywhere. That shape
  was not tried: a Hash of mixed values (`Hash[precision: 2, unit: "$"]`) would be `Integer | String` at every read.
  Keyword parameters type each option at the definition, and `rounded(number, precision, significant, ...)` takes
  them positionally so the seven converters share one implementation, which is how Ruby's
  `NumberToRoundedConverter` is called from the others anyway.
- Wrote `return number if number in String && to_decimal(number) == nil` →
  `error: && applies to the whole ... if ... here, not to its condition / hint: write the condition as (x in T) && ...` →
  `(number in String) && ...`. Ruby parses this the same surprising way; Sake named it and the hint was the fix.
- Wrote `Regexp.new(src, Regexp::MULTILINE)` → `wrong number of arguments for Regexp.new (given 2, expected 1)` and
  `undefined function Regexp.MULTILINE` → `Regexp.new("(?m)" + src)`.
- `NumberHelper.number_to_currency(1, precison: 3)` → `error: NumberHelper.number_to_currency has no keyword
  parameter precison / hint: did you mean precision:?`. ActiveSupport ignores an unknown option silently; this is
  the one place the port is stricter than the gem, and better for it.
- Wrote `Kernel.Float(r)` for a Rational → `Kernel.Float: argument 1 must be String|Integer|Float, but is Rational` →
  `Rational.to_f(r)`. Conversions are operations of the source type; `Float()` is the parser.
- What helped: the whole converter chain was written against the Ruby source and ran identical the first time
  under `--strict` once the two syntax messages above were fixed; nil handling (`return nil if number == nil`)
  came out as the first line of each helper, and the checker's `[nil]` item would have reported a forgotten one.

## Built-ins requested

- `Regexp.new(src, flags)` (an Integer or a String of letters) — see active_support_inflector.md.
- `Float.to_s` as the shortest round-trip decimal is what the BigDecimal emulation relies on; a `Float.to_r_exact`
  is `Float.to_r`, and a `Float.to_d`-like "decimal Rational from the printed form" would name the intent
  (`String.to_r(Float.to_s(f))` today).
- `Math.log10` for a `Rational` argument exists; a `Rational.floor_log10` is not needed. Nothing else was missing.
