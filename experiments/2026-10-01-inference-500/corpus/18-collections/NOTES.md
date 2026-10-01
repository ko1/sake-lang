# Notes: 18-collections

## course_overlap
- Ruby sorts by a composite key `[-j, x, y]`; Sake stopped with
  `ArgumentError: Array.sort_by: cannot compare elements of types Tuple` (Tuple has no ordering).
  Workaround: a formatted String key, `format("%.4f %s %s", 1.0 - j, x, y)`.
- No unary minus: `-c.size` is written `0 - Course.size(c)`, `-j` as `1.0 - j` inside the key.

## room_bookings
- `h, m = String.split(s, ":")` stopped with `TypeError: multiple assignment needs a Tuple, got Array`.
  Multiple assignment only takes a Tuple; split result is indexed instead (`parts[0]`, `parts[1]`).
- Ruby uses `break` out of `each` once a room is found; Sake has no `break` in blocks, so the loop
  uses `next if found`.
- `[a, b].max` (Ruby) became a ternary, since `[a, b]` is a Tuple and has no `max`.

## word_pipeline
- `Range.reject("a".."z") { ... }` stopped with `TypeError: Range.reject: this operation needs a Range
  that starts with an Integer, got "a".."z"`. Workaround: `String.upto("a", "z") { |l| ... }` pushing
  into an `Array[]`.
- Composite sort key `[-c, w]` again written as a String key `format("%05d %s", 100000 - c, w)`.
- `vocab.reduce(Set[]) { |acc, (n, s)| ... }` (nested block destructuring) is not available; the
  Sake block takes `kv` and indexes `kv[0]`, `kv[1]`.

## inventory_diff
- No notable problems. (Own mistake: wrote `String[](s, 0..1)`, which is a syntax error; `s[0..1]` works.)

## prime_sets
- Doc mismatch: spec.md §15 (Set table) says `select`, `filter`, `reject` give "a new Set", but
  `Set.select(Set[1, 2, 3]) { |x| x > 1 }` returns the Array `[2, 3]` (which matches Ruby 4.0, where
  `Set#select` returns an Array). Both versions convert with `to_set`.
- Ruby `break` inside `primes.each` (stop at n/2) became `next if p > n / 2` in Sake (no `break` in
  blocks); same result, more iterations.

## tag_recommender
- Worked first time. Sorting by a Tuple key (`sort_by { |k, n| k }` / `[-n, a.id]` in Ruby) again
  needed a String or Integer key in Sake; the Comparable `Match` type sorted fine with `Array.sort`.
- Ruby's `(tag_index[t] ||= Set[]) << id` became an explicit `unless Hash.key?` + `Set.add`.

## sales_pivot
- `Array[header] + rows` and `[reg, *cells, total]` stopped with `TypeError: Arithmetic.+: no
  implementation for (Array, Array)`. Arrays have no `+` and there is no splat; rows are built with
  `Array.push(Array.concat(Array[reg], cells), total)` and `Array.unshift(Array.dup(rows), header)`.
- Ruby's `each_cons(2) do |(m1, t1), (m2, t2)|` and `(region, month), v = ...` (nested destructuring)
  became indexing plus one level of multiple assignment (`m1, t1 = win[0]`, `k[0]`).
- Ruby rows are Hashes with Symbol keys; Sake rows are Records read with `r => {units:, price:}`.

## role_permissions
- No `Set.dup`; a copy of a Set is made with `Set.union(s, Set[])`. `path + [name]` (Array `+`)
  became `Array.push(Array.dup(path), name)`.

## friend_graph
- Ruby builds the graph with `Hash.new { |h, k| h[k] = Set[] }`; Sake has no block form of
  `Hash.new` (blocks are not values), so each insert is preceded by `g[a] = Set[] unless Hash.key?(g, a)`.

## latency_buckets
- Worked first time. Ruby's `verb, path, ms = entry.split(" ")` is again indexing in Sake.

## contact_dedupe
- `String.squeeze` takes no argument in Sake (Ruby: `name.squeeze(" ")`); used
  `String.gsub(s, / +/, " ")`. (My first try, `String.squeeze(s)`, silently squeezed letters too:
  "Ann" became "An".)
- `names - [best]` (Array `-`) became `Array.difference(names, Array[best])`; `a + b` of two
  mapped Arrays became `Array.concat`.
- `@parent[x] = root` (index-assignment into a Hash field through `@`) works.

## ip_ranges
- Worked first time. `addr, bits = text.split("/")` was written as
  `addr, bits = parts[0], String.to_i(parts[1])` style (multiple right-hand values are a Tuple).
- Sake's Range.size of a 2^24 block and the bsearch over `Range.to_a(0...n)` were fast enough (~0.6 s run).

## grade_book
- No problems. `!r[0].nil?` (unary `!`) is written `r[0] != nil`; `all.count(0)` used the block form
  `Array.count(all) { |s| s == 0 }`. `lo, hi = Array.minmax(all)` works (minmax gives a Tuple).

## sparse_vectors
- Worked first time. No `Hash.dup`; copied with `Hash.merge(h, Hash[])`. Ruby's `reduce(:&)` became
  a reduce with a `nil` start value and `acc == nil ? s : acc & s`.

## build_order
- Worked first time. `transform_values(&:dup)` on Sets became `Set.union(ds, Set[])` (no `Set.dup`).

## word_rack
- Worked first time. Ruby idioms rewritten: `[c] * n` (Array repetition) as
  `Array.map(Range.to_a(0...n)) { c }`; `("a".."z").to_set` as the chars of an alphabet String (String
  Ranges cannot iterate in Sake); `max_by { [score, size] }` as an Integer key `score * 100 + size`.

## access_log
- Worked first time. Ruby's `case code / 100 when 2 then ...` is `case ... in 2 then ...` in Sake
  (no `case`/`when`). The regexp constant `LINE_RE` became a function `def line_re = /.../`
  (no value constants).

## leaderboard
- Ruby's `total.merge(round) { |k, a, b| a + b }` has no Sake form (`Hash.merge` takes no block);
  written as a copy plus `out[name] = Hash.fetch(out, name, 0) + pts`.
- `sorted.each_with_index.map do |(name, pts), i|` (enumerator chaining + nested destructuring)
  became `Array.each_with_index` pushing into an `Array[]`; `flags.each_with_index.filter_map`
  became `Range.filter_map(1..n) { |i| flags[i - 1] ... }`.

## paginate
- Worked first time. Ruby's `loop do ... break ... end` is `while true ... break ... end` in Sake.
  Ruby's page Hash (`pg[:items]`) is a Record taken apart with `pg => {number:, items:, ...}`.

## survey_venn
- Worked first time. Ruby's `all.to_h { |u| [u, ...] }` (no `Set.to_h` / `Array.to_h` with a block in
  Sake) became a `Hash.new(0)` filled in `Set.each`.

## range_set
- Worked first time. Ruby class methods `self.empty` / `self.of` are ordinary functions of
  `class RangeSet` (`def empty = RangeSet.new(Array[])`, called `RangeSet.empty`). Set-like operators
  need two modules: `|` and `&` come from `Bitwise`, `-` from `Arithmetic`.

## sensor_merge
- Worked first time. Ruby builds Hashes with `to_h { |x| [k, v] }`; Sake has no block form of
  `to_h`, so a `Hash[]` is filled in `Array.each`.

## lottery
- `pair[0] == pair[1]` on two Sets stopped with `TypeError: Kernel.==: no implementation for (Set, Set)`
  (equality of Sets is undecided). Workaround: `Set.subset?(a, b) && Set.superset?(a, b)`.
- `draws.each_with_index do |(draw, bonus), i|` (nested destructuring) became `|pair, i|` and
  `draw, bonus = pair`.

## cart_discounts
- Ruby reads catalog entries as `cat[sku][:cents]`; Sake Records have no indexing, so each read is a
  pattern `cat[sku] => {cents:, cat: c}` (one per block, which makes the Sake code more verbose).
- The `case rule in {bogo:} ... in {bundle:, cents:}` dispatch on Record shape is the same in both.

## library_loans
- Worked once the data was right. `Report.summary(lib)` / `Report.summary(member)` dispatches the
  mixin to two different types (Ruby: `lib.summary`). Ruby's `case action when "lend"` is
  `case action in "lend"`. Ruby's `initialize(today)` with empty containers is a Sake function
  `Library.open(today)` calling `Library.new(Hash[], Hash[], Array[], Hash[], today)`.
- `(@queues[book_id] ||= [])` became `@queues[k] = Array[] unless Hash.key?(@queues, k)`.
