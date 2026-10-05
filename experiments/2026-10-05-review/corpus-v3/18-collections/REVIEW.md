# Review of 18-collections (2026-10-05)

Every program was run as `bin/sake --strict=0 NAME.sake`. All exit with status 0, and stdout is byte-identical to `NAME.out`.
The `.rb` files in this directory are dangling symlinks (`../../corpus/18-collections/NAME.rb`). The Ruby
versions were read from `experiments/2026-10-01-inference-500/corpus/18-collections/`.

- access_log: `Entry = Struct.new` -> `class Entry` + `attr_reader` (Ruby's class with readers).
- build_order: `Exception.new(:nodes)` / `Exception.new(:step, :dependency)` -> `class CycleError < StandardError` / `class MissingDependency < StandardError` with `attr_reader`; `target, rest = String.split(line, ":")` instead of splitting twice and indexing; `do |..| ... rescue ... end` block body (as Ruby) instead of a nested `begin`.
- cart_discounts: `UnknownItem = Exception.new(:sku)` -> `class UnknownItem < StandardError` + `attr_reader sku`.
- contact_dedupe: `Contact = Struct.new` -> `class Contact` + `attr_reader`.
- course_overlap: `Course = Struct.new` plus a reopened `class Course` -> one `class Course` with `attr_reader` and its functions.
- friend_graph: unchanged
- grade_book: unchanged
- inventory_diff: `ParseError = Exception.new(:line_no)` -> `class ParseError < StandardError`; `Item = Struct.new` plus a separate `class Item` (value) -> one `class Item` with `attr_reader`; rescue in the block body (as Ruby) instead of a nested `begin`.
- ip_ranges: `Block = Struct.new` -> `class Block` + `attr_reader`; `InvalidAddress = Exception.new(:text)` -> `class InvalidAddress < StandardError`; rescue in the block body (as Ruby).
- latency_buckets: unchanged
- leaderboard: block parameter taken apart `|(name, pts), i|` (as Ruby) instead of `|pair, i|` + multiple assignment; `history[Array.size(history) - 2]` -> `history[-2]`.
- library_loans: Book/Member/Loan `Struct.new` -> classes with `attr_reader` (Loan's `returned` as `attr_accessor`, as Ruby); Member's reopened class merged into one; `LoanRefused` -> `class ... < StandardError`; `Library.open(today)` factory -> `Library.new(40)` with `def initialize(lib)` filling the four collections (as Ruby's `initialize(today)`); `reserve` uses `q = (@queues[book_id] ||= Array[])`; rescue in the block body (as Ruby).
- lottery: `|(draw, bonus), i|` block destructuring instead of `|pair, i|` + `draw, bonus = pair`.
- paginate: `Product = Struct.new` -> `class Product` + `attr_reader`.
- prime_sets: `break_now = p > n / 2; next if break_now` -> `break if p > n / 2` (as Ruby; `break` in a block ends the call).
- range_set: unchanged
- role_permissions: two `Exception.new` -> `class ... < StandardError` + `attr_reader`; Role/User `Struct.new` -> classes; `Array.push(Array.dup(path), name)` -> `path + Array[name]` (Ruby's `path + [name]`); rescue in the block body (as Ruby).
- room_bookings: `Booking = Struct.new` -> class; `merged[Array.size(merged) - 1] =` -> `merged[-1] =`; the search loop uses `break` (as Ruby) instead of `next if found`.
- sales_pivot: rows built with `Array[reg, *cells, total]` (Ruby's `[reg, *cells, total]`) instead of `Array.push(Array.concat(...))` three times; `|(name, s), i|` and `|(m1, t1), (m2, t2)|` block destructuring.
- sensor_merge: unchanged
- sparse_vectors: unchanged
- survey_venn: unchanged
- tag_recommender: `Article = Struct.new` -> class; `|(x, y), n|` destructuring; `Set.add(tag_index[t] ||= Set[], id)` (Ruby's `(tag_index[t] ||= Set[]) << id`) instead of key?/store/add.
- word_pipeline: `Hash.reduce(vocab, Set[]) { |acc, (n, s)| ... }` (as Ruby) instead of a `do |acc, kv|` block with multiple assignment.
- word_rack: `Array.map(Range.to_a(0...n)) { |_i| c }` -> `Array[c] * n` (Ruby's `[c] * n`).

Totals: 19 changed, 6 unchanged. The most used feature was `class` + `attr_reader`, in 13 programs (12 Struct
types, 9 exception types). Block destructuring `|(a, b), i|` came next (6 programs), then rescue in a `do` block body (5). `initialize` was used once.
`once`, optional/keyword parameters, `x => T` and `&b` did not apply: no Ruby program here uses them, and its
table functions are `def`s in Ruby too.

## Friction

- **No `Hash.new { |h, k| h[k] = ... }`.** Wanted: Ruby's `Hash.new { |h, k| h[k] = Set[] }` (friend_graph.rb:4). Why not:
  blocks are not values. Written instead: two `g[a] = Set[] unless Hash.key?(g, a)` lines (friend_graph.sake:6-7).
  `x[k] ||= v` now covers the tag_recommender case (tag_recommender.sake:72).
- **`Array.to_h` takes no block.** Wanted: `defs.to_h { |n, g, i| [n, Role.new(...)] }`
  (role_permissions.rb:50, sensor_merge.rb:4/12, course_overlap.rb:37, grade_book.rb:43). Written instead:
  `h = Hash[]` with an `each` that stores, and `h` (role_permissions.sake:20-31, sensor_merge.sake:3-23,
  course_overlap.sake:30-31, grade_book.sake:43-50). `Array.to_h(Array.map(...))` would also work, but nobody wrote it.
- **`Hash.merge` takes no block.** Wanted: `total.merge(round) { |k, a, b| a + b }` (leaderboard.rb:13). Written instead:
  a copy with `Hash.merge(total, Hash[])`, then an each/fetch loop (leaderboard.sake:12-16).
- **No `dup` for Set or Hash.** Wanted: `ds.dup` / `@entries.dup` (build_order.rb:136, role_permissions.rb:59,
  sparse_vectors.rb:21). Written instead: `Set.union(ds, Set[])` (build_order.sake:31, role_permissions.sake:39)
  and `Hash.merge(@entries, Hash[])` (sparse_vectors.sake:19). These say "copy" only indirectly.
- **`reduce` needs an initial value; no `reduce(:&)`.** Wanted: `rounds.map { ... }.reduce(:&)` (leaderboard.rb:68,
  sparse_vectors.rb:96). Written instead: `reduce(xs, nil) { |acc, s| acc == nil ? s : acc & s }`
  (leaderboard.sake:73, sparse_vectors.sake:97).
- **No nested target in multiple assignment.** Wanted: `(region, month), v = pivot.max_by { ... }` (sales_pivot.rb:85).
  Why not: "`(x, y)` cannot be assigned here". Written instead: `k, v = ...` then `region, month = k` (sales_pivot.sake:96-97).
  The same nesting is allowed in block parameters.
- **No `loop do`.** Wanted: `loop do ... end` (paginate.rb:76). Written instead: `while true` (paginate.sake:69).
- **A field default must be a literal.** Wanted: Ruby's `def initialize(today)`, which fills `@books = {}` and the
  other collections (library_loans.rb:64-70). Why not: `attr_reader books = Hash[]` is not allowed, and `new` takes
  every field. Written instead: `attr_reader today, books = nil, members = nil, loans = nil, queues = nil`, then
  `initialize` replaces the nils (library_loans.sake:36-43). This needs the trailing nil defaults only so that
  `Library.new(40)` can leave the fields out. A Ruby reader sees nil fields that are never nil after construction.
- **`String.squeeze` takes no character set.** Ruby's `squeeze(" ")` (contact_dedupe.rb:81) stays
  `String.gsub(f[1], / +/, " ")` (contact_dedupe.sake:66).
- **Members are not min/max over a literal pair.** Ruby's `[lo, x.begin].min` (range_set.rb:27-28,64-65,
  room_bookings.rb:32/90) is written as a ternary or `if <` (range_set.sake:25-26,62-63, room_bookings.sake:25,90).
  `Array.min(Array[a, b])` would work but reads worse than the ternary. This is a Ruby idiom without a cheap equivalent.

## Ruby comparison

- **Qualified calls everywhere.** Every field read is `Entry.get_ip(e)`, not `e.ip` (access_log.sake:57-85), and `&:sym`
  shorthands become full blocks (`{ |e| Entry.get_hour(e) }`, access_log.sake:54). A Ruby programmer notices this
  first. One-liner pipelines such as `paths.sort_by { ... }.take(3).each { ... }` turn inside out
  (access_log.sake:65).
- **Explicit subjects.** Methods of a type take their subject first (`def find(u, x)`, contact_dedupe.sake:9; `def +(a, b)`,
  sparse_vectors.sake:18). Calls inside the class pass it on (`find(u, a)`, contact_dedupe.sake:21).
  Ruby's `self.empty` / `self.of` factories are ordinary functions (range_set.sake:9-15).
- **Constructors.** `class C` + `attr_reader` now matches Ruby's declaration line for line. But `C.new` still takes
  every field positionally, so Ruby classes whose `initialize` takes fewer arguments than fields need nil
  defaults (library_loans.sake:36).
- **Literals.** `Array[...]`, `Hash[...]`, `Set[...]` replace `[]`/`{}` (a `[...]` is a fixed Tuple; `{...}` is a Record).
  Ruby's Hash-of-Symbol rows become Records read with `r => {units:, price:}` (sales_pivot.sake:34,
  latency_buckets.sake:47,62).
- **Exceptions.** `class E < StandardError` + `attr_reader` now reads like Ruby, without the `initialize`/`super`
  boilerplate. Reading a field still takes `CycleError.get_nodes(e)` and `Exception.message(e)` rather than
  `e.nodes` / `e.message` (build_order.sake:114).
- **`case`/`when` -> `case`/`in`** (access_log.sake:36, library_loans.sake:114).
- **Sets of type operations stay explicit:** `Set.size(a & b)`, `Array.to_set(Hash.keys(h))` for Ruby's `h.keys.to_set`.
