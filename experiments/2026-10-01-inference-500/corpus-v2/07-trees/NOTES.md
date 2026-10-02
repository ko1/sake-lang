# Notes (07-trees, corpus-v2)

What still needs a workaround with today's Sake:

- **Swapping two Array slots.** `a[i], a[j] = a[j], a[i]` is still a static error ("only `a, b = tuple`
  (local variables, no splat) is supported"); heap_scheduler keeps a temp variable.
- **Splat in multiple assignment.** `*parts, last = String.split(s, " ")` (dom_tree) and
  `*parts, name = ...` (filesystem_du) stay as `Array.pop` / `Array.shift`.
- **Nested block parameters.** `reduce(x) { |acc, (side, sib)| ... }` is rejected ("nested destructuring
  `(s, n)` is not supported"); merkle_sync keeps `Array.each` with an outer accumulator.
- **`each_slice` with a short last slice.** `Array.each_slice(xs, 2) { |a, b| }` raises
  `ArgumentError: block takes 2 parameter(s) but was given 1` on an odd length (Ruby gives `b = nil`).
  merkle_sync keeps `|pair|` + `Array.size(pair) == 1`, and destructures only the full pair.
  Repro: `Array.each_slice(Array[1, 2, 3], 2) { |a, b| p([a, b]) }`.
- **Same-named fields under different names.** `(A|B).f(x)` needs the same operation name; MLeaf's
  `index` vs MNode's `lo`/`hi` (merkle_sync) still need `lo_of`/`hi_of` helpers with `in`.
- **Still missing:** `Array.new(n, v)` (`Range.map(0...n) { v }`), value constants (`def capacity = 3`),
  `Hash.new { |h, k| ... }` (traversals), `Hash.fetch` with a block (taxonomy_lca),
  attribute `||=` / `&.` (ip_route_trie), enumerators such as `each_slice(n).map` (merkle_sync
  `blocks_of`), `Integer.to_s(n, 16)`.
- **Observation (unchanged):** `==` on Struct values is structural (dom_tree, tree_codec `same?`), unlike
  Ruby object identity; the programs only compare where both agree.

The `Array.join` crash without a separator, recorded in the first round, is fixed.
