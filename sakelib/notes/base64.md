# base64

`sakelib/base64.sake` ports all of Ruby's `Base64` module (base64 0.3, a bundled gem in Ruby 4.0).
Since phase 2 each function is one call of `Array.pack(Array[s], "m")` / `String.unpack1(s, "m")`
(and the strict `"m0"` forms), as Ruby's own base64.rb is. Phase 1 had written pack.c's encoder and
decoders in Sake.
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
| `Base64.urlsafe_encode64(s, padding: false)` | `Base64.urlsafe_encode64(s, padding: false)` | same |
| `Base64.urlsafe_decode64(s)` | `Base64.urlsafe_decode64(s)` | same |
| `include Base64` then `encode64(s)` | | missing (Base64's functions are module functions; a Sake type can `include Base64` but gains nothing it needs) |

## What differs from Ruby, and why

- **Keyword arguments.** `padding:` is a keyword parameter, as in Ruby. Since the callee is known
  when the program is checked, a misspelling is a static error instead of being ignored, as the
  former Record option (`{paddin: false}`) was:
  `Base64.urlsafe_encode64("a", paddin: false)` → `error: Base64.urlsafe_encode64 has no keyword
  parameter `paddin`` with `hint: did you mean `padding:`?`.
- **Encodings.** Ruby's encoders return US-ASCII Strings. Sake's return UTF-8 Strings with the same
  ASCII content, and they compare equal. Decoders return ASCII-8BIT, as Ruby's do.
- **Error message.** `String.unpack1(s, "m0")` raises `String.unpack1: invalid base64`;
  `strict_decode64` rescues it and raises Ruby's `invalid base64` (repro:
  `sakelib/notes/base64_bug_unpack1_message.sake`).

## Built-ins needed but missing

- None. (`String.unpack1` and `String.b`, requested in phase 1, now exist.) Under `--strict`,
  `String.unpack1(s, "m")` is typed `String | nil`, although `"m"` always gives a String, so
  `decode64` adds `|| ""`.

## Friction

1. `String.each_char(alphabet).Array.each_with_index { ... }` → `String.each_char requires a block`
   → `String.chars(alphabet).Array.each_with_index`. In Ruby, `each_char` without a block returns an
   Enumerator. The message is clear.
2. No other static reports. The library passed `--strict=3` on the first run, and the test output
   matched Ruby's on the first run.

## Phase 2

- `urlsafe_encode64_with(s, o)` → `urlsafe_encode64(s, o = {padding: true})`; the test calls it with
  `{padding: false}` and `{padding: true}`. The test compares with `String.b(s)` instead of
  `Array.pack(String.bytes(s), "C*")`.
- The hand-written encoder, both decoders and the 256-entry decode table (built on every call) are
  gone: 149 → 41 lines.
- Speed (`experiments/2026-10-03-sakelib-port/phase2/bench_base64.sake`: encode64, decode64, strict
  and urlsafe round trips of 6 KB; CPU s of the whole `bin/sake --strict` run, 3 runs, machine load
  about 37 on 16 cores): before 4.31 / 4.69 / 4.31, after 0.71 / 0.72 / 0.73. The work itself went
  from about 4 s to under 10 ms; what is left is startup and checking.

## Review 2026-10-05

No change: `urlsafe_encode64(bin, padding: true)` is already Ruby's keyword; every function is one pack/unpack, as Ruby's. No class, no initialize, no type check Ruby does by hand. `--strict=1`/`2`: 0 reports before and after.

## 2026-10-05

Checked against the new features; nothing applies. Ruby's only keyword (`padding:`) was already a keyword; there is no type with state. No change to the library or the test.
