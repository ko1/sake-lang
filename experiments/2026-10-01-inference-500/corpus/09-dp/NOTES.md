# NOTES (09-dp)

General observations (apply to several tasks):
- `==` between Tuples is not defined (`TypeError: Kernel.==: no implementation for (Tuple, Tuple)`), and
  `Array.max` on Tuples fails (`ArgumentError: Array.max: cannot compare elements of types Tuple`).
  (Found while probing Sake before writing; the programs avoid comparing whole Tuples.)
- No unary minus on variables (`-x`): written `0 - x`. No `!x`: written `x == false` or swapped branches.
- No `Array.new(n) { ... }`: 2D tables are `Range.map(0..n) { Range.map(0..m) { 0 } }`.
- No `Array.new(n, 0)` either: 1D tables are `Array.fill(Range.to_a(0..n), 0)` or grown with `Array.push`.
- No `break` in blocks, and no `case/when`; see the tasks below.

## grid_paths
- Ruby's `Array.new(h) { Array.new(w) }` (nil-filled) became `Range.map(0...h) { Range.map(0...w) { nil } }`.

## longest_increasing
- Ruby's `sort_by { |e| [e.w, -e.h] }` (Tuple sort key) fails in Sake:
  `ArgumentError: Array.sort_by: cannot compare elements of types Tuple`. Workaround: a combined Integer
  key `w * 10000 - h`.

## word_break
- `Set[*String.split(words, " ")]`: `error: splat arguments are not supported`. Written
  `Array.to_set(String.split(words, " "))`.

## palindromes
- `s[start, len]`: `error: \`s[best_i, best_len]\` takes one index`. Written with a Range,
  `s[best_i...(best_i + best_len)]`.

## line_breaking
- The inner scan stops at the first line that overflows; Ruby uses `(i...n).each { ... break ... }`, but
  `break` is not allowed in Sake blocks, so the Sake version uses a `while` loop with `break`.

## held_karp
- `Array + Array` is not defined: `TypeError: Arithmetic.+: no implementation for (Array, Array)`.
  Built the list with `Array.push` (on an `Array.dup` where the original must not change).
- `Array.each_cons(a, 2) do |a, b|` fails at run time: `ArgumentError: block takes 2 parameter(s) but
  was given 1` (each window is an Array, not a Tuple, so it is not destructured). Written `|pair|` with
  `pair[0]`, `pair[1]`.

## interval_scheduling
- `client, span, fee = String.split(line, ",")`: `TypeError: multiple assignment needs a Tuple, got Array`.
  Written with indexing (`fields[0]`, `fields[1]`, ...).

## viterbi
- Ruby's `states.to_h { |s| [s, ...] }` has no Sake equivalent (`Array.to_h` takes no block); the Sake
  version fills a `Hash[]` in an `Array.each` loop.

## sequence_alignment
- The traceback dispatches on a Symbol; Ruby's `case ... when :diag` is written `case ... in :diag` (no
  `case/when` in Sake), and Ruby's `loop do ... break` became `while done == false`.

## digit_counting
- The first version (brute-force checks up to 5432 and limits up to 10**18) took about 16 s wall-clock
  in Sake on a loaded machine; the brute-force ranges and the large limits were reduced (now about 3 s
  user time). Ruby's `each_cons(2).none? { |a, b| ... }` became a `while` loop with an early `return`.
