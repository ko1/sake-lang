# Notes for 17-encodings

General: Sake has no `Integer.to_s(n, base)` and no `String.to_i(s, base)` (arity errors); binary/hex output goes through `format("%b"/"%x")`, and parsing through `String.hex` or a manual loop.

## run_length
- `==` between Arrays is undefined in Sake, so the bitmap row roundtrip check compares `Array.join(back, "") == Array.join(bits, "")`; Ruby compares the arrays directly.

## huffman
- A first-line comment containing "coding:" ("# Huffman coding: ...") is taken as a Ruby magic encoding comment by Prism, in both Sake and Ruby: `syntax error: unknown or invalid encoding in the magic comment`. Reworded the comment.
- `Array.sort_by` with a Tuple key (`[n, sym]`, Ruby's usual tie-break) fails at run time: `ArgumentError: Array.sort_by: cannot compare elements of types Tuple`. Workaround: a zero-padded String key, `format("%06d %s", n, sym)`.

## protobuf_wire
- `delta_s = delta in Integer ? a : b` is a syntax error (`unexpected '?'`), as in Ruby; written `(delta in Integer) ? a : b`. Ruby version uses `is_a?`.
- Ruby `case wire when 0` is not available (no `case`/`when`); Sake uses an `if`/`elsif` chain there (and `case`/`in` with integer literals in `encode_field`).

## transposition
- Tuple sort keys again (`[key[i], i]`, `[pattern[i], i]`): replaced with `format("%s%03d", key[i], i)` and `pattern[i] * n + i`.
- No `Array.new(n, x)` (spec §16); used `Array.map(Range.to_a(0...n)) { "" }`.

## rolling_sync
- Ruby's `Hash.new { |h, k| h[k] = [] }` has no Sake form (blocks are not values); the Sake version looks up, creates and stores the list explicitly.

## percent_encoding
- Same magic-comment trap as huffman: "# URL percent-encoding: ..." on line 1 is read as an encoding declaration. Reworded.
- Ruby compares two Hashes of Arrays with `==`; Sake (no Array/Hash equality) compares sizes and joined value lists per key.

## frame_parser
- Ruby prints the stats with `p`; since the brief asks for a plain class (not `Struct.new`) in Ruby, the Ruby class defines `inspect` to print Sake's `#<struct Stats ...>` form.

## general
- No unary minus or `!`: written `0 - n` (zigzag, `n & (0 - n)` in bitset) and `x == false`.
- No value constants: lookup tables and alphabets (Morse table, Base64 alphabet, letter frequencies, CRC catalogue) are zero-argument functions, rebuilt on each call unless the caller keeps the result.
- Run time was measured while the machine had a load average around 36 on 16 cores. The slowest programs were bloom_filter (about 4.9 s) and xor_breaker (about 2 s). To keep them in budget, bloom_filter's stranger set was cut to 150 words and xor_breaker searches printable key bytes only.
- No interpreter bugs found. Every error I hit was my own mistake or a documented restriction.
