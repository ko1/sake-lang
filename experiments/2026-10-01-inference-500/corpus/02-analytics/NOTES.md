# NOTES (02-analytics)

## General (found while probing, applies to many tasks)

- Tuples are not comparable: `Hash.sort_by(h) { |w, n| [0 - n, w] }` fails with
  `ArgumentError: Hash.sort_by: cannot compare elements of types Integer` (and `Array.sort` of Tuples:
  `Array.sort: cannot compare elements of types Tuple`). The Ruby idiom "sort by [-count, word]" needs a
  Struct type with `include Comparable` and `<=>` (e.g. `Rank`) in Sake. The Ruby versions use the same
  class-with-`<=>` so the algorithms match.
- Interpreter bug: `Array.join(x)` with no separator crashes with an internal Ruby `NoMethodError`
  (`undefined method 'map' for an instance of String`, stdlib.rb:176) for any Array (the builtin block
  `|a, sep = ""|` auto-splats the single Array argument; exit status 1, but with a Ruby backtrace instead
  of a Sake error). Repro: `p(Array.join(Array["a", "b"]))`. Workaround: always pass the separator
  (`Array.join(x, "")`).
- Unary minus is unsupported: `0 - n` instead of `-n`.

## Per task

### ngram_counts
- `Array.each_cons(t, 2) { |a, b| ... }` (Ruby's natural form) fails at run time:
  `ArgumentError: block takes 2 parameter(s) but was given 1` (the window is an Array, not a Tuple).
  Sake version indexes the window (`window[0]`, `window[1]`).
- Nested block destructuring `|(a, b), c|` over a Hash with Tuple keys is a static error
  (`nested destructuring (a, b) is not supported`); Sake uses `|pair, c|` then `a, b = pair`.

### spell_suggest
- Two-argument string slicing is a static error: `` `word[0, i]` takes one index ``. Sake uses Ranges
  (`word[0...i]`, `word[i..]`, `right[1..]`); the Ruby version keeps `word[0, i]` etc.
- Interpreter bug (spec mismatch): `Set.select` / `Set.reject` / `Set.filter` return an **Array**, though
  spec.md §15 says "a new Set". Repro: `p(Set.select(Set[1,2,3]) { it > 1 })` prints `[2, 3]`. Found
  as `TypeError: Set.empty?: argument 1 must be Set, got Array`. Workaround: build the Set with
  `Set.each` + `Set.add`.
- Slowest program here (~3.5 s in Sake), because of the edit-distance-2 search for one word.

### kwic_concordance
- Ruby sorts collocates with `sort_by { |w, n| [-n, w] }`; Tuple keys are not comparable in Sake
  (see General), so the Sake version sorts by a formatted String key `format("%03d %s", 999 - n, w)`.
- Ruby's `|w, (si, _)|` block parameter becomes `|w, pos|` + `si, wi = pos` (nested destructuring).

### access_log_urls
- Percent-decoding builds the String from bytes with `Integer.chr` + `Array.join(..., "")`; there is no
  `pack`/`force_encoding` in Sake, so (as in the Ruby version, which uses the same algorithm) a decoded
  non-ASCII value is a binary String. Output bytes are identical.
- The per-route accumulator is a Record of Arrays/Sets in Sake (`{hits: Array[], ...}` read back with
  `=> {hits:, ...}`) where Ruby uses a Symbol-keyed Hash (`stats[:hits] << ...`).

### language_guess
- Ruby's `each_with_index { |(g, _), i| ... }` needs nested destructuring; Sake uses `|pair, i|` and
  `pair[0]`. The tie-breaking sort key `[d, langs.index(lang)]` becomes the number `d * 100 + index`.

### rake_keywords
- `words.each_cons(3) do |a, mid, b|` (Ruby) becomes `|tri|` with `tri[0]`, `tri[1]`, `tri[2]`
  (same each_cons issue as ngram_counts). `!x` is rejected (unary operator), written `x == false`.

