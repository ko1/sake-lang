# Notes (06-linked, corpus-v2)

What still needs a workaround with today's Sake:

- **No identity comparison.** Ruby's `a.equal?(b)` is still written `a == b` (Struct equality, which walks
  the fields and the rest of the list), compared by a unique field (circular_playlist: titles; cycle_detection:
  `id`), or by `!=` on cyclic Structs (josephus_circle, markup_tag_checker, browser_history, singly_linked_list).
  Correct only because the compared values happen to differ in some field.
- **Structs cannot be Set elements / Hash keys.** cycle_detection keeps a Set of ids:
  `Set[N.new(1, nil)]` -> "TypeError: Set[]: N cannot be a Hash key or Set element".
- **Record patterns cannot match a value.** two_stack_print_queue still writes `in {peek:}` for Ruby's
  `in {peek: true}`: `case r in {peek: true} ...` -> "only Record patterns that bind fields are supported".
- **No `max`/`min` on a Tuple.** Ruby's `[a, x].max` is `x > a ? x : a` (list_toolkit);
  `Array.max([3, 4])` -> "Array.max: argument 1 must be Array, got Tuple". `Array.max(Array[a, x])` works but is no clearer.
- **No `Array.new(n, x)`, no `loop`/`break` in blocks** (unchanged from v1): push loops in ring_buffer_metrics,
  skip_list_index, free_list_pool, monotonic_stack_prices, sparse_matrix_rows; a flag `while` in skip_list_index.
- **No destructuring block parameters** (`|(name, value), t|`): ring_buffer_metrics takes the pair apart on the next line.

No interpreter bugs found in this round. The default-level check (`bin/sake -c`) reports the same number of
problems for every v2 program as for its v1 version.
