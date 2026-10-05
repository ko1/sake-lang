# Review of 05-sorting (2026-10-05)

All 25 programs run with `bin/sake --strict=0` and print exactly `NAME.out` (exit 0).
Note: the `NAME.rb` files in corpus-v3 are dangling symlinks (`../../corpus/...`); the Ruby
reference was read from `experiments/2026-10-01-inference-500/corpus/05-sorting/`.

- autocomplete_msd: unchanged
- bisect_on_answer: `Plan` is `class` + `attr_reader`; `Array.sum(loads) { ... }` (block form, as Ruby's `sum(&:sum)`) replaces sum of a map.
- bucket_sort_ratings: `Rating` is `class` + `attr_reader`; `bucket_sort(items, n, &key)` passes the block on to `insertion_sort!(b, &key)` (as Ruby) instead of re-wrapping it in `{ |x| yield(x) }`; `Array.new(n) { Array[] }` and `Array.flat_map` replace times+push and each+concat.
- external_sort_sim: `Record` is `class` + `attr_reader`; `Disk` is `class` + `attr_accessor` (as Ruby); `BadLine` is `class BadLine < Exception` + `attr_reader line_no`; `do |bad| ... rescue BadLine => e ... end` (rescue in a do-block, as Ruby) replaces the inner `begin`.
- gift_two_pointers: `Item` is `class` + `attr_reader`; `Array.sum(trio) { ... }` replaces sum of a map.
- gradebook_insertion: `Student` is `class` + `attr_reader`.
- hashtag_trends: `Tally` is `class` + `attr_reader`.
- heap_scheduler: `Job` is `class` + `attr_reader`; `Heap` gets its empty Array in `def initialize(h)`, so `Heap.new` replaces the helper `Heap.empty()` (Ruby's `Heap.new`); swaps are `a[i], a[j] = a[j], a[i]`; `each_with_index { |(prio, name), seq| }` and `Array.new(4) { Heap.pop(queue) }` as in Ruby.
- kway_log_merge: `Entry` is `class` + `attr_reader`, `Cursor` is `class` + `attr_accessor` (as Ruby); swaps by multiple assignment.
- leaderboard_insert: `Entry` is `class` + `attr_reader`; `Board` is `class` + `attr_reader` with `def initialize(b)` making the Array and Hash, so `Board.new` replaces the helper `Board.create()`; unused index dropped from `show`.
- library_catalog: `Book` is `class` + `attr_reader`; `NotFound` is `class NotFound < Exception` + `attr_reader query`; rescue in the do-block instead of `begin`.
- log_time_bisect: `Event` is `class` + `attr_reader`.
- meeting_intervals: `Meeting` is `class` + `attr_reader`; `InvalidMeeting` is `class ... < Exception` + `attr_reader title`; rescue in the do-block; `Array.sum(xs) { ... }` twice.
- merge_sort_inversions: unchanged
- natural_runs_sort: `Run` is `class` + `attr_reader`, `Stats` is `class` + `attr_accessor` (as Ruby); swap by multiple assignment.
- probe_count_search: `Table` is `class` + `attr_reader` (Ruby's reader; `@reads += 1` stays inside the class).
- quicksort_median3: `Product` is `class` + `attr_reader`, `Stats` is `class` + `attr_accessor`; the key block is passed on with `&key` through `sort_by_key`/`quicksort`/`median3`/`insertion`/`less` (12 `{ |x| yield(x) }` re-wrappings gone, now the same shape as Ruby); swap by multiple assignment.
- radix_order_ids: `Shipment` is `class` + `attr_reader`; `Array.new(max_key + 1, 0)` and `Array.new(n)` replace times+push loops; `Array.sum(xs) { ... }`.
- sensor_quickselect: swap by multiple assignment (as Ruby).
- shell_sort_gaps: swap by multiple assignment (as Ruby).
- sorted_matrix_search: unchanged
- staff_multikey_sort: `Employee` is `class` + `attr_reader`; `merge_sort(a, &cmp)` passes the comparator on; `name, dir = String.split(...)` replaces `words[0]`/`words[1]`.
- trail_peak_search: `Trail` is `class` + `attr_reader`; `NotUnimodal` is `class ... < Exception` + `attr_reader trail`; rescue in the do-block.
- triage_partition: `Patient` is `class` + `attr_reader`; `swap` by multiple assignment.
- version_resolver: `Version` is `class` + `attr_reader`; `keep[-1] += 1` as Ruby; rescue in the do-block.

Counts: 22 changed, 3 unchanged. Most used: `class` + `attr_reader` in place of `Struct.new`
(20 programs), `class E < Exception` + `attr_reader` (4), rescue directly in a do-block (5),
`&block` passing (3), `initialize` (2), multiple-assignment swaps (7).

## Friction

- **Compound update of an accessor field from outside the class.** Ruby writes `disk.reads += chunk.size`
  (external_sort_sim.rb:71), `stats.swaps += 1` (quicksort_median3.rb:27), `stats.runs += 1`
  (natural_runs_sort.rb:27), `c.pos += 1` (kway_log_merge.rb:73). `@x += v` works only inside the
  class, so Sake writes `Disk.set_reads(disk, Disk.get_reads(disk) + Array.size(chunk))`
  (external_sort_sim.sake:56, 75-76), quicksort_median3.sake:14,18, natural_runs_sort.sake:15-18,
  kway_log_merge.sake:61. Moving the helper into the class would work but changes the Ruby shape.
- **A field set only by `initialize` still needs a default.** Ruby's `def initialize; @items = []; end`
  takes no arguments. In Sake `new` takes every field without a default, and a default must be a
  literal, so `Array[]` cannot be it: heap_scheduler.sake:16 writes `attr_reader items = nil` and
  leaderboard_insert.sake:16 `attr_reader entries = nil, scores = nil, moves = 0`, each with a
  placeholder `nil` that `initialize` immediately overwrites. The `nil` is visible to a reader (and
  probably to the checker) although no instance ever holds it.
- **`&:sym` has no counterpart.** `lower_bound(log, from, &:ts)` (log_time_bisect.rb:43),
  `sort_by(&:cents)`, `map(&:name)` everywhere become `{ |e| Event.get_ts(e) }`
  (log_time_bisect.sake:37-38, gift_two_pointers.sake:95). Expected under the design (the block
  must name the type), but it is the most frequent length difference in the domain.
- **No enumerator chains.** `records.each_slice(memory).map { ... }` (external_sort_sim.rb:70),
  `ms.each_cons(2).select { ... }.map { ... }` (meeting_intervals.rb:120), `each_with_index.map`
  (gradebook_insertion.rb:48) become an `Array[]` plus push inside the block-taking form
  (external_sort_sim.sake:54-60, 87; meeting_intervals.sake:110-115; gradebook_insertion.sake:43-52).
- `Array.concat(out, a, b)` with two arrays (staff_multikey_sort.rb:51) is two `concat` calls
  (staff_multikey_sort.sake:41-42); minor.

## Ruby comparison

- Every field access names its type: `Item.get_cents(items[i])` for `items[i].cents`; this, not the
  declarations, is what a Ruby programmer sees first in every program here.
- The type declarations now read like Ruby (`class Rating` / `attr_reader product, stars, votes`);
  the only visible differences are bare names instead of symbols and no `initialize` that copies
  arguments into fields.
- Instance functions take the instance as an explicit first parameter (`def <=>(a, b)`,
  `def score(r)`), and `@x` refers to that parameter; `def self.parse` becomes plain `def parse`
  inside the class (version_resolver.sake:10).
- Hash/Array/Tuple literals are spelled `Hash[...]`, `Array[...]`; a bare `[a, b]` is a fixed Tuple.
- `loop do` is `while true` (merge_group, sift_down, quicksort).
