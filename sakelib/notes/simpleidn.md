# simpleidn (SimpleIDN, IDNA / Punycode RFC 3492)

`require "simpleidn"` → `sakelib/simpleidn.sake`, which requires `sakelib/simpleidn/uts46mapping.sake` (the
mapping table, as the gem's `simpleidn/uts46mapping.rb`). Port of the simpleidn gem 0.2.3.
Test: `test/sakelib/simpleidn.{sake,rb}` (identical output): the gem's examples, RFC 3492 7.1 samples (Arabic,
Chinese, Czech, Japanese, mixed), Greek/Cyrillic/German domains, full-width dots, leading/trailing/only dots,
transitional processing, the UTS #46 mapping (full-width letters, ligatures, circled digits, soft hyphen),
nil, and malformed Punycode.

## API

| Ruby | Sake | |
|---|---|---|
| `SimpleIDN.to_ascii(domain, transitional = false)` | `SimpleIDN.to_ascii(domain, transitional)` | same (nil gives nil) |
| `SimpleIDN.to_unicode(domain, transitional = false)` | `SimpleIDN.to_unicode(domain, transitional)` | same |
| `SimpleIDN.uts46map(str, transitional = false)` | `SimpleIDN.uts46map(str, transitional)` | same |
| `SimpleIDN::Punycode.encode(s)` / `decode(s)` | `SimpleIDN::Punycode.encode(s)` / `decode(s)` | same, same error messages |
| `Punycode.encode_digit` / `decode_digit` / `adapt` | same | same |
| `SimpleIDN::ConversionError` | `SimpleIDN::ConversionError` | differs: not a RangeError (no hierarchy) |
| `UTS64MAPPING` (Hash) | `SimpleIDN.uts46mapping` | differs: a function (Hash parsed once); values are always Arrays of code points |
| `TRANSITIONAL`, `ACE_PREFIX`, `DOT`, `Punycode::BASE`, `TMIN`, … | `SimpleIDN.transitional_mapping`, `ace_prefix`, `dot`, `Punycode.base`, … | differs: functions (constants hold no values) |

All of the gem's API is ported (9 public functions + the constants as functions).

## What differs, and why

- **Encodings.** The gem converts its input to UTF-8 and its result back to the input's encoding
  (`.encode(domain.encoding)`, with a rescue for UTF-16 input). Sake's Strings are UTF-8, so those conversions
  are left out.
- **The mapping table** (6509 entries) is a String of `"codepoint=target.target;"` entries in hex, generated from
  the gem's Hash and parsed once by `SimpleIDN.uts46mapping`. A 6509-entry `Hash[...]` literal would have worked as
  data too, but a String is 75 KB instead of 6500 lines, and it is only parsed when a domain is first mapped.
  Ruby's table mixes `65 => 97` and `168 => [32, 776]`; here every value is an Array, so `uts46map` does not need
  Ruby's `flatten` over Integer | Array.
- `c.chr(Encoding::UTF_8)` per code point and `join` → `Array.pack(codepoints, "U*")`.

## Built-ins Sake lacks

- `Integer.chr` with an encoding (`cp.chr(Encoding::UTF_8)`); `Array.pack(xs, "U*")` does the job.
- `String#encode(other_encoding)`: not needed for UTF-8 only.

## Friction

- `INITIAL_N = 0x80` and the nine other constants → constants hold no values → `def initial_n = 0x80` etc.
  (the body then reads `base - tmin` instead of `BASE - TMIN`; it reads like local variables).
- `mapped.flatten` over `Integer | Array` values → I made all values Arrays up front (`Array.flat_map`), which is
  simpler than Ruby's version anyway.
- The test passed on the first run.

## Size

Ruby: `simpleidn.rb` 283 lines (173 without comments/blank) + `uts46mapping.rb` 6528 lines of data.
Sake: `simpleidn.sake` 217 lines (168 without comments/blank) + `simpleidn/uts46mapping.sake` 717 lines of data.
