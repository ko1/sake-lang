# Notes for 05-sorting (corpus-v2)

What still needs a workaround with today's Sake. No interpreter bugs found: every program exits 0
and prints exactly its `.out` with `bin/sake --strict=0`.

- **Swapping elements.** `a[i], a[j] = a[j], a[i]` is still rejected ("only `a, b = tuple` (local
  variables, no splat) is supported"), so every in-place sort (heap_scheduler, kway_log_merge,
  natural_runs_sort, quicksort_median3, sensor_quickselect, shell_sort_gaps, triage_partition)
  keeps a temporary or a `swap` helper. This is the most common remaining workaround in this domain.
- **Optional trailing parts.** Multiple assignment needs the lengths to match, so Ruby's
  `name, dir = "salary".split(" ")` (dir becomes nil) still has to index the split result
  (staff_multikey_sort). The strict length rule is right for `k, v = ...`, but "a, b from 1 or 2
  words" has no short form.
- **Nested block parameters.** `Array.each_with_index(board) { |(name, total), i| }` is rejected
  ("nested destructuring ... is not supported"); merge_sort_inversions takes the pair apart with
  `name, total = pair` inside the block.
- **Splat arguments.** `format(fmt, label, *row)` is rejected ("splat arguments are not
  supported"); shell_sort_gaps passes `row[0], row[1], row[2]`.
- **No array patterns.** `case hit in [row, pos]` is not available; sorted_matrix_search matches
  `in Tuple` and destructures in the branch.
- **No `split` limit.** Ruby's `line.split(" ", 2)` is written with `String.partition` in
  kway_log_merge (same result on this data).
- **Comparator blocks through recursion.** Blocks are not values, so the key/comparator block is
  re-wrapped at each recursive call (`{ |x| yield(x) }` in quicksort_median3,
  `{ |x, y| yield(x, y) }` in staff_multikey_sort); `Array.sort` takes no block, so comparator
  sorts stay hand-written or use a Comparable Struct.
- **Two-number max.** `[a, b].max` becomes `Array.max(Array[a, b])` (version_resolver).
