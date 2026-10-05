# REVIEW (09-dp, corpus-v3)

All 25 programs pass `bin/sake --strict=0` with stdout identical to `.out` and exit 0.
The `.rb` files here are broken symlinks (`../../corpus/09-dp/...` does not exist); the Ruby
reference was read from `experiments/2026-10-01-inference-500/corpus/09-dp/`.

- coin_change: `Exception.new(:amount)` -> `class InvalidAmount < StandardError` + `attr_reader amount`; `Array.fill(Range.to_a(0..n), 0)` -> `Array.new(amount + 1, 0)`; `amount %= c`; `g && r && ...` as in Ruby
- company_party: `Struct.new`/`Exception.new` -> `class Employee` + `attr_reader`, `class OrgError < StandardError`; hand-written memo check -> `memo[k] ||= begin ... end`; ternary max -> `Array.max(Array[with, without])`; `headcount` uses `Array.sum(xs) { }`
- critical_path: classes + `attr_reader` (Task, CycleError); `chains` via `Array.sum(deps) { }` instead of an accumulator; `Array.reverse_each`; `order.to_h { }` as `Array.map { [k, v] }.Array.to_h` (two Hash-filling loops removed)
- decode_ways: `Array.new(n + 1, 0)` (2x); memo -> `memo[i] ||= begin ... end`
- dice_odds: `class Die` + `attr_reader`; `Array.new(size + 1, 0r)`; `fudge` local restored instead of three literal copies
- digit_counting: entry functions pass `digits_of(limit)`/`Hash[]` inline; `memo.key?` check as in Ruby (`Hash.key?`); `memo[key] = Range.sum(0..top) { }` and `Array.select(...).Array.sum { }` instead of accumulators; `brute` -> `Range.count`
- edit_distance: `Array.new(n + 1) { |i| Array.new(m + 1) { |j| ... } }`; push with a ternary as Ruby
- egg_drop: `Array.new(e + 1) { Array.new(f + 1, 0) }`; `1 + Array.max(Array[...])` instead of a manual max; `columns` local restored
- floyd_warshall: `class NegativeCycle < StandardError`; `Array.new(n) { |i| Array.new(n) { |j| ... } }`; `ecc` via `Range.map`
- grid_paths: `class Grid` + `attr_reader`; `Array.new(h) { Array.new(w) }`; `compress` as a chain (`.Array.map ... .Array.join`); `Range.map(1..n)`
- held_karp: `class City` + `attr_reader`; `Array.new(full + 1) { Array.new(n) }`; `mask ^= ...`; `Array + Array` in `names` and `each_cons(order + Array[0], 2)`; `Range.reject`
- house_robber: `class House` + `attr_reader`; parallel assignment `take, skip = skip + v, Array.max(...)` as Ruby; ternary maxes -> `Array.max(Array[...])`
- interval_scheduling: `class Clock`/`class Booking` with `attr_reader` (Comparable kept); `Range.map(0...n)`; `Array.sum(chosen) { }`
- knapsack_01: `class Item` + `attr_reader`
- lcs_diff: `class Edit` + `attr_reader`; `Array.new` table; ternary max -> `Array.max(Array[...])`
- line_breaking: `class TooLongWord < StandardError` + `attr_reader word, width`; `Array.new`; inner `while` -> `Range.each(i...n)` with `break` in the block (as Ruby); `** 3`; `Array.sum(xs) { }`; `raggedness` -> `Array.sum(lines[0...-1]) { }`; `String.empty?`
- longest_increasing: `class Envelope` + `attr_reader`; `Array.new(n, 1)`, `Array.new(n)`; `while k`
- matrix_chain: `class Shape` (with `include Arithmetic`) + `attr_reader`; `class DimensionError < StandardError`; `Array.new` tables; `left_to_right` -> `Array.reduce`; `Range.map` for names
- optimal_bst: `class Node` + `attr_reader`; `Array.new` tables; `freq_of = Array.zip(keys, freq).Array.to_h`
- palindromes: `Array.new` tables; `s[best_i, best_len]` (two-index slice, as Ruby); modifier `if`; ternary DP cell as Ruby; `Array.sum(pal) { |row| Array.count(row, true) }`
- sequence_alignment: `class Scoring`/`class Alignment` + `attr_reader`; `identity` via `Range.count`; `marker` as `Range.map do ... end.Array.join`; `Array.new` tables; `row.fill(:stop)` as `Array.each(move) { |row| Array.fill(row, :stop) } if local`
- stock_trading: `class Trade` + `attr_reader`; `Array.new`; manual maxes -> `Array.max(Array[...])`, `[hold, rest - p].compact.max` as `Array.max(Array.compact(Array[...]))`; `Array.sum(trades) { }`
- subset_partition: `Array.new(total + 1, false)`, `Array.new(total + 1)`; `Range.reject`; `Set.map(...).Array.each`; temp locals removed
- viterbi: `class Model` + `attr_reader`; first column pushed directly; `Array.join(xs)` with no separator; `Array.zip(...).Array.map`
- word_break: `Set[*String.split(...)]` (splat, as Ruby); `Set.map(dict) { }.Array.max`; `Array.new`; `lo = Array.max(Array[i - longest, 0])`; modifier `if`; `dict | Set[...]`

Changed: 25. Unchanged: 0. No program in this domain has a Ruby constant table, an optional or
keyword parameter, `is_a?` checks, or `block_given?`, so `once`, `def f(a, b = 1)`, `x => T`, and
`&b` found no use here.

## Friction

- **Two-value max/min.** Ruby's `[a, b].max` has to be `Array.max(Array[a, b])`: a literal `[a, b]`
  is a Tuple, and Tuple has no `max`. This is the most frequent noise left in DP code
  (stock_trading.sake:16-17,45-48,56-57; house_robber.sake:10-12,22,43,51; lcs_diff.sake:19;
  egg_drop.sake:13; word_break.sake:12; company_party.sake:45,87,95). In house_robber.sake:92-93
  `tree_best(root).max` (a returned Tuple) needs a destructure and then `Array.max(Array[...])`.
- **No enumerator chains.** `digits_of(n).each_cons(2).none? { |a, b| a == b }` (digit_counting.rb:62)
  stays as `Array.each_cons(..., 2) { |a, b| return false if a == b }` + `true`
  (digit_counting.sake:62-63); `names.each_with_index.map { }` (matrix_chain.rb:70) stays as a
  push loop (matrix_chain.sake:57).
- **No `to_h` with a block.** `order.to_h { |id| [id, total] }` (critical_path.rb:91,98) is written
  `Array.map(order) { ... }.Array.to_h` (critical_path.sake:80,88; also viterbi.sake:13,40-46).
- **No `loop do`, no `String#prepend`/`<<`.** sequence_alignment.sake:60 uses `while true`, and
  builds strings with `top = s[i - 1] + top` (lines 63-73); lcs_diff.sake:64 and palindromes.sake:74
  use `out += a[i]` for Ruby's `out << a[i]`.
- **`case`/`when` is `case`/`in`.** sequence_alignment.sake:61-77; works, but a Ruby reader notices.
- **`%w[]`.** Word lists are `String.split("...", " ")` or `Array["a", "b", ...]`
  (edit_distance.sake:71-72, palindromes.sake:88, decode_ways.sake:85).
- **`&:sym` blocks.** `picked.map(&:weight).sum`, `dice.map(&:to_s)`, `bookings.min_by(&:start)`
  all spell the block out with the qualified getter (knapsack_01.sake:45, dice_odds.sake:65,
  interval_scheduling.sake:93).

## Ruby comparison

- Every field read is `Type.get_x(v)` instead of `v.x` (e.g. interval_scheduling.sake:45
  `Clock.get_minutes(Booking.get_finish(b))` for `b.finish.minutes`); with `attr_reader` the class
  bodies now read like Ruby's, but call sites do not.
- `def self.parse` / `def self.build` become plain `def parse(text)` in the class, called as
  `Grid.parse`, and they build with `Grid.new(...)` rather than `new(...)` (grid_paths.sake:4-7,
  floyd_warshall.sake:7-18).
- Ruby's `initialize(message, field)` + `super(message)` for exception classes disappears:
  `class E < StandardError` with `attr_reader field` gives `E.new(msg, field)` directly, and
  `e.field` becomes `E.get_field(e)` (line_breaking.sake:88).
- Typed arrays `Item[...]`, `City[...]`, `Edit[]`, `Trade[]` where Ruby has `[...]`
  (knapsack_01.sake:56, held_karp.sake:77).
- Integer iteration is `Integer.upto(1, n)` / `Integer.downto(n - 1, 0)` rather than
  `1.upto(n)`, and `(0...n).map` is `Range.map(0...n)`.
