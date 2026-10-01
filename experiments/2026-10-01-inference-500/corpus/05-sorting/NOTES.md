# Notes for 05-sorting

## General

- Swapping array elements: `a[i], a[j] = a[j], a[i]` is rejected ("only `a, b = tuple` (local variables, no splat) is supported"); the Sake versions use a temporary.
- `Array.sort` takes no block ("Array.sort does not take a block"); comparator sorts use `sort_by`, a Comparable Struct, or a hand-written sort.
- `Array.sort_by` with a Tuple key fails at run time ("ArgumentError: Array.sort_by: cannot compare elements of types Tuple"), and `==` on Tuples is undefined; multi-key sorts need a Struct with `include Comparable` and `<=>`, or an encoded scalar key.
- `Array == Array` is undefined (`TypeError: Kernel.==: no implementation for (Tuple, Tuple)` for Tuples, same for Arrays), and a `TypeError` cannot be rescued. "Sorted result equals the builtin sort" checks compare `Array.join(..., ",")` strings (heap_scheduler, radix_order_ids, autocomplete_msd, bucket_sort_ratings, shell_sort_gaps, triage_partition, natural_runs_sort).
- Multiple assignment only destructures Tuples, so Ruby's `a, b = str.split(...)` becomes indexing (staff_multikey_sort, meeting_intervals, version_resolver), and `each_cons` blocks index `pair[0]`/`pair[1]`.
- No interpreter bugs found; every difference above is a documented restriction.

## Per task

### merge_sort_inversions
- `KeyError` message differs: Sake's `Exception.message` is `Hash.fetch: key not found: "zed"`, Ruby's is `key not found: "zed"`. The rescue prints its own text instead of the message.
- Ruby sorts the consensus board with `sort_by { [total, name] }`; Sake cannot compare Tuples in `sort_by`, so the key is encoded as `total * 100 + String.ord(name)` (names have distinct first letters).

### quicksort_median3
- The key block is threaded through the recursive helpers by re-wrapping it at each call (`{ |x| yield(x) }`), since blocks are not values (Ruby passes `&key`).

### heap_scheduler
- `Array == Array` is undefined, so comparing the heapsort result with the builtin sort compares `Array.join` strings.
- A zero-parameter type function (`def empty = Heap.new(Array[])`) works as `Heap.empty()`.
### sensor_quickselect
- Ruby groups with `(by_sensor[name] ||= []) << value`; the Sake version tests `Hash.key?` and assigns `Array[]` first (`h[k] ||= Array[]` also works in Sake, but not combined with a push in one expression).
- The pivot's index is looked up within `lo..hi` with `Range.find`, as in Ruby.

### kway_log_merge
- `String.split` takes no limit, so Ruby's `ts, text = line.split(" ", 2)` becomes split + `Array.drop` + `Array.join` in Sake.
### radix_order_ids
- No `Array.new(n, v)` / `Array.new(n)`: count and output arrays are built with `Integer.times` + `Array.push`.
- `Array.each_cons` gives the block an Array, which `|a, b|` does not destructure (only Tuples are); the Sake version indexes `pair[0]`, `pair[1]`.
### autocomplete_msd
- `s[0, n]` (two-argument index) is rejected ("takes one index"); written `s[0...n]` in both versions.
- Ruby picks the most frequent word with `min_by { |w, n| [-n, w] }`; Sake cannot compare Tuples, so it scans the Hash with an explicit tie-break.
### staff_multikey_sort
- `name, dir = String.split(...)` fails at run time: "TypeError: multiple assignment needs a Tuple, got Array". The Sake version indexes the split result.
- Comparator block threaded through recursion as `{ |x, y| yield(x, y) }` (Ruby: `&cmp`).
### meeting_intervals
- Ruby's `h, m = s.split(":").map(&:to_i)` is not available (multiple assignment needs a Tuple); Sake indexes the split parts.
- Merged busy blocks are Tuples `[start, finish]` updated in place through `Array.last(blocks)` (`last[1] = ...`), which works as in Ruby.
### sorted_matrix_search
- No array patterns: Ruby's `case flat_search(...) in nil ... in [row, pos]` becomes `in Tuple` plus indexing `hit[0]`, `hit[1]`.
### probe_count_search
- A Struct type joining `Indexable` with its own `[]` (counting reads) works as in Ruby; `t[i]` dispatches to it.
- `x.inspect` becomes `Kernel.inspect(x)`.
### hashtag_trends
- Ruby sorts climbers with `sort_by { |tag, _, d| [-d, tag] }`; Sake encodes the key as `0 - d * 1000 + String.ord(tag[1])` (no Tuple comparison), which happens to give the same order on this data.
### trail_peak_search
- No unary minus: `Math.exp(-price / 18.0)` is written `Math.exp(0.0 - price / 18.0)` (same in other tasks: `0 - n`).
### version_resolver
- A type-level constructor taking a String (`Version.parse(s)` inside `class Version`) works; Ruby uses `def self.parse`.
- Ruby's `op, text = constraint.split(" ")` again becomes indexing in Sake; `[sa.size, sb.size].max` becomes `Array.max(Array[...])`.
