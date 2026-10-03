# zlib (checksums only)

`require "zlib"` gives Zlib's CRC-32 and Adler-32 checksums, written in Sake over a String's bytes
(`sakelib/zlib.sake`). Compression is not ported.

## API

| Ruby | Sake | |
|---|---|---|
| `Zlib.crc32(s)` | `Zlib.crc32(s)` | same |
| `Zlib.crc32(s, crc)` | `Zlib.crc32(s, crc)` | same (phase 2; was `crc32_with`) |
| `Zlib.adler32(s)` | `Zlib.adler32(s)` | same |
| `Zlib.adler32(s, adler)` | `Zlib.adler32(s, adler)` | same (phase 2; was `adler32_with`) |
| `Zlib.crc32`, `Zlib.adler32`, `Zlib.crc32(nil, crc)` (the initial value) | same | same: 0 and 1, whatever the running value |
| `Zlib.crc32_combine(crc1, crc2, len2)` | `Zlib.crc32_combine(crc1, crc2, len2)` | same for len2 >= 0; a negative len2 raises ArgumentError (Ruby passes it to zlib, whose result depends on the zlib version) |
| `Zlib.adler32_combine(a1, a2, len2)` | `Zlib.adler32_combine(a1, a2, len2)` | same for len2 >= 0 |
| `Zlib.crc_table` | `Zlib.crc_table` | same (an `Integer[]` of 256) |
| `Zlib.deflate`, `inflate`, `gzip`, `gunzip`, `Zlib::GzipReader`/`GzipWriter`, `Deflate`, `Inflate` | | missing (not in this group) |

Also visible: `Zlib.gf2_times`, `Zlib.gf2_square` (helpers of `crc32_combine`; Sake has no private
functions).

Running values out of the 32-bit range are taken as Ruby does (the low 32 bits for CRC-32, the two
16-bit halves for Adler-32); checked against Ruby for -1, 2**32+5, 0xffffffff, 65521, 0xfff1fff1,
and 2**48-1.

## What differs from Ruby, and why

- **crc_table** is computed once per program (`once`) and shared, as Ruby's; the Array can be
  changed by a caller, which Ruby's (a fresh Array per call) cannot.
- `crc32_combine` uses zlib's older GF(2) matrix method; results are the same as Ruby's (zlib
  1.3.1) for len2 >= 0, including len2 = 0 (`crc1 ^ crc2`).

## Verification

Covered by the generated comparison described in `notes/digest.md` (every length 0..300, larger
binary Strings, UTF-8 text, 40 Strings in random pieces through the running value, and the combine
functions): all matched Ruby.

## Speed

Same method and caveats as `notes/digest.md` (local shared machine, load 17-40; CPU time of one
process minus the empty-input run).

| | 16 KiB, bytes/s (3 runs) | 128 KiB, bytes/s (3 runs) | Ruby's C, bytes/s |
|---|---|---|---|
| crc32 | 61,000 82,000 74,000 | about 32,000-62,000 | about 2,300,000,000 |
| adler32 | 78,000 91,000 91,000 | about 35,000-95,000 | about 2,200,000,000 |

At 16 KiB the difference to the empty run is only 0.2 s, close to `time`'s 0.01 s resolution and the
run-to-run spread; the 128 KiB runs spread widely under the machine's load. Read these as "tens of
KB per second", about 10x the digests (one table lookup or two additions per byte, through
`String.each_byte`).

## Built-ins that would help

- `Zlib.crc32` / `adler32` as built-ins, for anything larger than a few hundred KB.

## Friction

- Wanted `def crc32(s)` and `def crc32(s, crc)` → a name is defined once per namespace →
  `crc32_with(s, crc)`.
- `module_function :crc32, ...` listing nine names → a bare `module_function` at the top of the
  module does the same.

## Phase 2

- `crc32(s = nil, crc = 0)` and `adler32(s = nil, adler = 1)` with optional parameters, under Ruby's
  names; `crc32_with` / `adler32_with` are removed (the tests now call Ruby's form, and also the
  no-argument and `nil` forms).
- `crc_table` is `once do ... end`, computed from the polynomial instead of a 256-entry literal
  (36 lines shorter).
- The byte loop stays `String.each_byte`: an index loop over `String.unpack(s, "C*")` was 1.5x
  slower (7.3 s against 4.9 s CPU for 128 KiB), and `Array.each(String.bytes(s))` the same as
  `each_byte`.

Speed (`experiments/2026-10-03-sakelib-port/phase2/bench_zlib.sake`, run by
`run_digest_zlib_prime_matrix.sh`; CPU s user+sys of one `bin/sake --strict` process, 3 runs; local
16-core machine shared with other sessions, load average 33-38 throughout; "before" is commit
af197cd):

| CPU s, 3 runs | before (af197cd) | after |
|---|---|---|
| 0 KiB (start-up, checking) | 0.62 0.63 0.65 | 0.67 0.66 0.67 |
| crc32, 128 KiB | 4.90 4.82 5.00 | 5.08 4.97 5.09 |
| adler32, 128 KiB | 4.08 4.08 3.97 | 4.17 4.12 4.08 |

No change beyond the spread (+2-3%, partly the start-up rows): the per-byte block call is the
cost, and the table was already built once per call before.

Raw: `experiments/2026-10-03-sakelib-port/phase2/results_digest_zlib_prime_matrix.txt`.
