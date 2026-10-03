# base64

`sakelib/base64.sake` ports all of Ruby's `Base64` module (base64 0.3, a bundled gem in Ruby 4.0).
Encoding and decoding are written in Sake over `String.bytes` and `Array.pack(bytes, "C*")`. They
follow `pack("m")` / `unpack1("m")` and the strict `"m0"` forms of Ruby's pack.c, including how
`decode64` skips characters and stops at `=`, and when `strict_decode64` raises.
`test/sakelib/base64.sake` covers empty input, line wrapping at 60 characters, all 256 byte values,
lenient and strict decoding of 22 malformed inputs, and UTF-8 text. Its output is identical to
`base64.rb`.

## API

| Ruby | Sake | |
|---|---|---|
| `Base64.encode64(s)` | `Base64.encode64(s)` | same |
| `Base64.decode64(s)` | `Base64.decode64(s)` | same (binary String) |
| `Base64.strict_encode64(s)` | `Base64.strict_encode64(s)` | same |
| `Base64.strict_decode64(s)` | `Base64.strict_decode64(s)` | same (`ArgumentError: invalid base64`) |
| `Base64.urlsafe_encode64(s)` | `Base64.urlsafe_encode64(s)` | same |
| `Base64.urlsafe_encode64(s, padding: false)` | `Base64.urlsafe_encode64_with(s, {padding: false})` | differs (no keyword arguments) |
| `Base64.urlsafe_decode64(s)` | `Base64.urlsafe_decode64(s)` | same |
| `include Base64` then `encode64(s)` | | missing (Base64's functions are module functions; a Sake type can `include Base64` but gains nothing it needs) |

## What differs from Ruby, and why

- **The padding option** is a `_with` operation that takes a Record, because Sake has no keyword
  arguments. This follows the convention `csv` uses.
- **Encodings.** Ruby's encoders return US-ASCII Strings. Sake's return UTF-8 Strings with the same
  ASCII content, and they compare equal. Decoders return ASCII-8BIT, as Ruby's do.
- **Speed.** Decoding builds a 256-entry table on each call, and each byte goes through the
  interpreter. The test, which encodes 256 bytes and about 60 small strings, runs in about 3 s.

## Built-ins needed but missing

- `String.unpack1(s, fmt)` / `String.unpack(s, fmt)`. `Array.pack` exists (and already passes `"m"`
  through to Ruby, although the docs list only `"C*"` and `"U*"`), but there is no inverse, so decoding
  had to be written by hand. With both built-ins, this library would be 7 one-line functions, as
  Ruby's is.
- `String.b(s)`: the test compares a decoded value with the input's bytes, which I wrote as
  `Array.pack(String.bytes(s), "C*")`.

## Friction

1. `String.each_char(alphabet).Array.each_with_index { ... }` → `String.each_char requires a block`
   → `String.chars(alphabet).Array.each_with_index`. In Ruby, `each_char` without a block returns an
   Enumerator. The message is clear.
2. No other static reports. The library passed `--strict=3` on the first run, and the test output
   matched Ruby's on the first run.
