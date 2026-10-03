# zlib (checksums only)

`require "zlib"` gives Zlib's CRC-32 and Adler-32 checksums, written in Sake over a String's bytes
(`sakelib/zlib.sake`). Compression is not ported.

## API

| Ruby | Sake | |
|---|---|---|
| `Zlib.crc32(s)` | `Zlib.crc32(s)` | same |
| `Zlib.crc32(s, crc)` | `Zlib.crc32_with(s, crc)` | differs: another name (no optional parameters) |
| `Zlib.adler32(s)` | `Zlib.adler32(s)` | same |
| `Zlib.adler32(s, adler)` | `Zlib.adler32_with(s, adler)` | differs: another name |
| `Zlib.crc32`, `Zlib.adler32` (no argument: the initial value) | | missing: write 0 and 1 |
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

- **Optional running value.** Sake functions take only required parameters, and a name is defined
  once per namespace, so `Zlib.crc32(s, crc)` is `Zlib.crc32_with(s, crc)`.
- **crc_table** is built from a literal on each call to `crc32_with` (no value constants).
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

- Optional parameters (or another way to keep Ruby's `crc32(s, crc = 0)` under one name).
- Value constants, for `crc_table`.
- `Zlib.crc32` / `adler32` as built-ins, for anything larger than a few hundred KB.

## Friction

- Wanted `def crc32(s)` and `def crc32(s, crc)` → a name is defined once per namespace →
  `crc32_with(s, crc)`.
- `module_function :crc32, ...` listing nine names → a bare `module_function` at the top of the
  module does the same.
