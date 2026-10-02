# NOTES (09-dp, corpus-v2)

Still worked around (all reproduce with `bin/sake --strict=0`):

- `Array + Array` is not defined (`TypeError: Arithmetic.+: no implementation for (Array, Array)`).
  held_karp still builds `order + [0]` as `Array.push(Array.dup(order), 0)`.
- `break` in a block is a static error (`break` is only supported directly inside `while`/`until`).
  line_breaking keeps its `while` loop.
- `s[start, len]` is a static error (`takes one index`); palindromes keeps `s[i...(i + len)]`.
- Splat arguments are rejected, so `Set[*words]` stays `Array.to_set(words)` (word_break).
- `Array.to_h` takes no block; viterbi now writes `Array.map { [k, v] }.Array.to_h`, which is fine.
- No `Array.new(n, v)` / `Array.new(n) { }`: tables stay `Array.fill(Range.to_a(0..n), v)` and
  `Range.map(0..n) { Range.map(0..m) { 0 } }`. This is the most frequent remaining noise in DP code.

Possible bug (diagnostic only): `p(Array.new(3, 0))` reports `undefined function Array.new` with
`hint: did you mean Array.new[]?`, which is not valid Sake; `Array[]` or `Array.fill` would help more.

Packed sort keys in edit_distance (`dist * 100 + size`) and held_karp (`d * 100 + k`) were left
alone because the Ruby versions use the same keys.
