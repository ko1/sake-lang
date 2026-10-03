# digest

`require "digest"` gives MD5, SHA1, SHA256, SHA384, and SHA512, written in Sake over a String's bytes
with Integer bit operations (`sakelib/digest.sake`). Ruby's `Digest::MD5` is the type `MD5`: Sake
cannot write `::` (namespaces do not nest). The shared code is the mixin module `Digest`, which each
type includes, as Ruby's `Digest::Instance`.

## API

| Ruby | Sake | |
|---|---|---|
| `Digest::MD5.hexdigest(s)` (also SHA1, SHA256, SHA384, SHA512) | `MD5.hexdigest(s)` | same |
| `Digest::MD5.digest(s)` | `MD5.digest(s)` | same (a binary String) |
| `Digest::MD5.base64digest(s)` | `MD5.base64digest(s)` | same |
| `Digest::MD5.new` | `MD5.new` | same |
| `md.update(s)`, `md << s` | `MD5.update(md, s)`, `md << s` | same (returns md) |
| `md.digest`, `md.hexdigest`, `md.base64digest` | `MD5.digest(md)`, `MD5.hexdigest(md)`, `MD5.base64digest(md)` | same (md is left as it is) |
| `md.digest!`, `md.hexdigest!`, `md.base64digest!` | `MD5.digest!(md)`, ... | same (returns, then resets) |
| `md.reset` | `MD5.reset(md)` | same |
| `md.to_s`, `"#{md}"` | `MD5.to_s(md)`, `"#{md}"` | same (the hex digest) |
| `p md` | `p(md)` | same (`#<Digest::MD5: ...>`) |
| `md.digest_length`, `md.block_length`, `md.size`, `md.length` | `MD5.digest_length(md)`, ... | same |
| `md1 == md2` | `md1 == md2` | same for two digests of one type |
| `md == "hexstring"` | | differs: false (a String is never equal to an MD5) |
| `Digest::MD5.file(path)` | `MD5.file(path)` | same; a missing file raises `IOError`, not `Errno::ENOENT` |
| `Digest.hexencode(s)` | `Digest.hexencode(s)` | same |
| `md.file(path)` (instance) | | missing: the name is taken by `MD5.file(path)` |
| `md.digest(s)`, `md.hexdigest(s)` (instance, with a String: reset, then digest s) | | missing: `MD5.hexdigest(s)` gives the same value |
| `md.dup`, `md.clone` | | missing |
| `Digest::SHA2.new(bitlen)`, `Digest::RMD160`, `Digest(:MD5)` | | missing |

Also visible, though Ruby has no such names: the functions each algorithm defines for the mixin
(`state`, `store_state`, `initial_state`, `compress`, `word_bytes`, `little_endian?`, `name`), the
mixin's `finish`, `finish_hex`, `finish_base64`, the tables `MD5.k`, `MD5.shifts`, `SHA256.k`, and
the module `SHA2_64` (the compression shared by SHA384 and SHA512). Sake has no private functions.

## What differs from Ruby, and why

- **One name for Ruby's class method and instance method.** Ruby has `Digest::MD5.hexdigest(str)`
  and `md.hexdigest`; in Sake both are `MD5.hexdigest(x)`, one function with `case x in String ...
  in MD5 ...`. The checker still rejects any other argument type before running (the `case` has no
  `else`). The cost is three repeated `case` functions per algorithm.
- **State as separate fields.** `MD5.new` takes no arguments only when every field has a literal
  `default:`. An Array cannot be a default, so the chaining words are fields `h0`..`h7` (Integer)
  and `pending` is a String, not an `Integer[]`. `state(md)` / `store_state(md, h)` convert to an
  `Integer[]` for each update.
- **Tables are functions.** Sake has no value constants, so `def k = Integer[...]` builds the 64 (or
  80) constants again on each call; `compress` calls it once per block.
- **Equality** is Struct equality (same type, same fields: same digest so far and same pending
  bytes). Ruby compares the hex digests, and also accepts a String.
- `SHA384`/`SHA512` work on 64-bit words with arbitrary-precision Integers, masked to 64 bits.
- `base64digest` uses `Array.pack([digest], "m0")`, as Ruby's own `Digest::Instance` does.

## Verification

Besides `test/sakelib/digest.sake`, a generated program compared every algorithm (hexdigest and
base64digest), Zlib.crc32/adler32 with and without a running value, and crc32/adler32_combine with
Ruby's results on: random binary Strings of every length 0..300 (all block boundaries of 64 and 128
bytes) and of 1000, 4096, 6000, 12345 bytes; 5 UTF-8 texts (CJK, accents, emoji x40, NUL); and 40
random Strings fed incrementally in 1-5 random pieces. All 5010 output lines matched Ruby 4.0.2's.
(Generator: a Ruby script writing the .sake program and Ruby's expected output; not kept in the repo,
since the brief limits the files.)

## Speed

Sake is an interpreter written in Ruby; this is about 4-5 orders of magnitude slower than Ruby's C
implementation.

Method: one `bin/sake --strict` process hashing `"abcdefgh" * 2048` (16 KiB) once, minus the same
program with an empty String (start-up and checking, about 0.35 s); user+sys CPU time from
`/usr/bin/time`; 3 runs. Local machine (16 cores), shared: load average 17-40 during the runs, so
the numbers are indicative only (CPU time is less disturbed than wall time; wall time inside the
program varied 2-5x). The bench machine sp4 was leased by another session. Ruby 4.0.2.

| | CPU s for 16 KiB (3 runs) | Sake, bytes/s | Ruby's C (same input, 2000 times), bytes/s |
|---|---|---|---|
| MD5 | 1.21 1.29 1.24 | about 13,000 | about 480,000,000 |
| SHA1 | 2.10 1.85 2.07 | about 8,000 | about 520,000,000 |
| SHA256 | 3.07 3.03 3.13 | about 5,300 | about 190,000,000 |
| SHA512 | 2.22 2.02 2.16 | about 7,700 | about 300,000,000 |

SHA512 is faster per byte than SHA256 despite 64-bit (bignum-sized in Ruby beyond 62 bits)
arithmetic, because it does 80 rounds per 128 bytes against 64 per 64 bytes.

## Built-ins that would help

- `String.unpack(s, "N16")` / `"V16"` (or `String.unpack1`): read 32-bit big/little-endian words
  directly; the byte-by-byte word assembly is a large part of each block.
- `String.byteslice(s, i, n)`: keep the pending bytes without rebuilding the byte Array of
  pending + new on each update.
- Value constants, or a function whose result is computed once: the round constants are rebuilt per
  block.
- A literal `Integer[]` as a field default (`default: {h: Integer[...]}`), or an initializer: the
  state could then be one Array field.
- Optional parameters, or a separate name space for "class methods": to keep Ruby's two
  `hexdigest`s apart without a `case` on the argument's type.
- Digest itself as a built-in (Ruby's is C): at about 10 KB/s, hashing a 1 MB file takes minutes.

## Friction

- `def Digest.hexencode(s)` inside `module Digest` → "`def Digest.hexencode` inside `Digest`:
  write `def hexencode`" → `def hexencode(s)` plus `module_function :hexencode` (a bare
  `module_function` would also turn the mixin functions after it into module functions).
- `md << "ab"` with only `def <<(md, s)` in the mixin → "Bitwise.<<: SHA256 does not include
  Bitwise" → `include Bitwise` in the mixin `Digest`.
- Wanted a field `buf: Integer[]` with a default so that `MD5.new` needs no arguments → defaults
  must be literal numbers, Strings, ... → one Integer field per state word, and a String for the
  pending bytes.
- Wanted `MD5.hexdigest(str)` and `MD5.hexdigest(md)` as two definitions → a name is defined once
  per namespace → one function with `case x in String ... in MD5 ...`.
- At `--strict=3`, each byte read `x[j]` is reported (`index-nil`, 161 reports); level 2 (the test
  level) is clean. Indexes are in range by construction (whole blocks only); `Array.fetch` would
  silence it at a cost per byte.
