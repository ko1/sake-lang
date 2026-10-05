# Notes: 18-collections (v2)

All 25 programs exit 0 with `--strict=0` and print their `.out` byte for byte. No interpreter bugs found.

## Still worked around

- **No nested block destructuring.** `|acc, (n, s)|` (word_pipeline), `each_with_index do |(name, pts), i|`
  (leaderboard, sales_pivot, lottery) are static errors (`nested destructuring (n, s) is not supported`);
  the code takes the Tuple whole and adds `n, s = kv`. This is now the most common leftover.
- **Multiple assignment needs an exact length.** `target, rest = String.split("fetch:", ":")` raises
  `ArgumentError: multiple assignment of 2 variables from Array of size 1` where Ruby gives `rest = nil`.
  build_order keeps `String.split(line, ":")[0]` / `[1]` for that reason (contact_dedupe's `f[3] || ""` likewise).
- **No Array `+` / `-`, no splat, no `[x] * n`.** `Array[1, 2] + Array[3]` is a `TypeError`; rows are built
  with `Array.concat` / `Array.push` (sales_pivot), `Array.difference` (contact_dedupe), and
  `Array.map(Range.to_a(0...n)) { c }` (word_rack).
- **No `[a, b].max` / `.min`.** A literal pair is a Tuple and Tuple has no `max`; room_bookings and range_set
  keep ternaries.
- **No `break` in blocks.** room_bookings (`next if found`) and prime_sets (`next if p > n / 2`) still scan
  the whole Array.
- **String Ranges cannot iterate.** `Range.reject("a".."z") { }` is still a `TypeError`; word_pipeline uses
  `String.upto`, word_rack the chars of an alphabet String.
- **No `Set.dup` / `Hash.dup`, no block for `Hash.merge`, `Hash.new { }`, or `to_h { }`.** Copies are
  `Set.union(s, Set[])` / `Hash.merge(h, Hash[])`; `||=`-style inserts stay `unless Hash.key?`.
- **Records have no indexing**, so cart_discounts still writes one `cat[sku] => {cents:}` pattern per read.
- `String.squeeze` takes no argument (contact_dedupe keeps `String.gsub(s, / +/, " ")`).

## Resolved since v1

- The doc mismatch reported for `Set.select` is gone: spec.md §15 now says it returns an Array.
- Tuple sort keys, unary minus, Array multiple assignment, block destructuring of Arrays, and Set `==` all
  worked first time wherever they were tried.
