# Review: 06-linked (corpus-v3, 2026-10-05)

All 25 programs run with `bin/sake --strict=0` and print exactly `NAME.out` (exit 0).
The `.rb` symlinks in this directory dangle (they point to `2026-10-05-review/corpus/`); the Ruby
originals were read from `experiments/2026-10-01-inference-500/corpus/06-linked/`.

## Programs

- adjacency_list_courses: exception type (`class CycleError < Exception` + `attr_reader stuck`); `Graph.create` factory -> `Graph.new` with `initialize` building the four collections (fields declared `= nil`).
- bank_teller_sim: `WaitQueue` fields `attr_accessor head, tail` -> `attr_reader head = nil, tail = nil` (defaults); `WaitQueue.create` -> `WaitQueue.new`.
- browser_history: `Tab` fields `current, opened` accessor -> `attr_reader` (only written inside `Tab`); `opened = 1` default.
- chained_hash_table: fields `size, resizes` accessor -> `attr_reader` with defaults `= 0`, `probes = 0`; `Array.new(n)` replaces two `Integer.times { push(nil) }` loops (create, grow).
- circular_playlist: `attr_reader name, now = nil, count = 0` (defaults; dropped an unused `repeat` field); `Playlist.create` -> `Playlist.new` as in Ruby.
- cycle_detection: unchanged
- deque_sliding_window: `attr_reader front = nil, back = nil, length = 0` (defaults); `Deque.create` -> `Deque.new`.
- digit_list_bignum: `Array[0] * shift` replaces a push loop (Ruby `[0] * shift`); `total += ...`, `acc *= ...` compound assignment on a Struct type's operator, as Ruby.
- free_list_pool: two exception types as `class X < Exception` + `attr_reader`; `Pool.new(5)` with `initialize` building the arrays by `Array.new(n, v)` / `Array.new(n) { }` (was a 4-way push loop in a `create` factory); `capacity` becomes a field.
- josephus_circle: unchanged
- lfu_cache_buckets: `LFU.new(cap)` with `initialize` creating `items`/`log`; `lowest`/`log` accessor -> `attr_reader`.
- list_toolkit: unchanged
- lru_cache: `LRUCache.new(cap)` with `initialize` creating `index`/`evicted`; all accessor fields -> `attr_reader` with defaults.
- markup_tag_checker: `Frame`, `Issue` as `class` + `attr_reader` (Ruby's readers); `void_tags` table -> `once { Set[...] }` (Ruby `VOID_TAGS`).
- merge_log_streams: unchanged
- monotonic_stack_prices: `Frame` as `class` + `attr_reader`; `attr_reader top = nil, size = 0`, `MinMaxStack.new`; `Array.new(size, -1)` replaces a push loop (Ruby has it).
- ring_buffer_metrics: exception type as class; `Ring.new(cap, overwrite)` with `initialize` making `slots` by `Array.new(cap, 0.0)`; `each` via `Integer.times { yield }` (Ruby's shape); `READINGS` -> `def readings = once do ... end`; `|(name, value), t|` destructuring; `windows[name] ||= Ring.new(...)`.
- rpn_stack_calculator: `Cell` and two exception types as classes with `attr_reader`; `attr_reader top = nil, depth = 0`, `Stack.new`; `BINARY` -> `def binary_ops = once { Array[...] }` used with `Array.include?` as in Ruby.
- singly_linked_list: `attr_reader head = nil, tail = nil, size = 0`; `LinkedList.new`.
- skip_list_index: `SkipList.new(6)` with `initialize` making the head node; defaults for `level/seed/size/steps`; `Array.new(n, v)` / `Array.new(n)` replace three push loops.
- sparse_matrix_rows: exception type as class; `Sparse.new(nrows, ncols)` with `initialize` making `rows` (the `zero` factory and `nrows` function are gone; `nrows` is a field as in Ruby's constructor); `Array[1] * n` replaces a push loop.
- sparse_polynomial: `attr_reader terms = nil`, `Poly.new` (was `Poly.new(nil)`); `result *= poly`, `sum += ...`.
- triage_priority_list: exception type as class; `attr_reader first = nil, count = 0`, `WaitList.new`.
- two_stack_print_queue: `Link`, `Job` as `class` + `attr_reader` (Job's `to_s`/`cost` merged into that class); defaults on `TwoStackQueue`, `TwoStackQueue.new`.
- undo_redo_editor: `Cell`, `Insert`, `Delete`, `Replace` and the exception as classes with `attr_reader`; `Editor.new(text)` with defaults replaces the `Editor.open` factory.

Most used: `attr_reader` defaults to replace `create` factories (15), `class` + `attr_reader`
records (8 files), `class E < Exception` (8 files), `initialize` that builds collections (7), `Array.new(n[, v])`
(6), `once` (3).

## Friction

- **A field named `next` cannot be declared.** adjacency_list_courses.sake:1: Ruby's `Edge` is
  `attr_reader :to, :next`. I wanted `class Edge; attr_reader to, next; end`, but bare `next` is the keyword
  (`syntax error: Invalid next`), and `:next` is rejected ("write the field's name without `:`").
  I kept `Edge = Struct.new(:to, :next)` (accessor, not reader). Every linked-node type here has a `next`
  field (15 of 25 files), so none of them could take the class form even where Ruby uses readers.
- **Building collections in `initialize` needs placeholder fields.** Ruby's `initialize(capacity)` sets
  `@index = {}` and the like. Sake's `initialize(c)` takes only the instance, and a default must be a literal,
  so each such field is first declared `= nil` and then set in `initialize`:
  lru_cache.sake:4-9, lfu_cache_buckets.sake:39-44, adjacency_list_courses.sake:9-15,
  free_list_pool.sake:11-20, ring_buffer_metrics.sake:8-10, skip_list_index.sake:4-7,
  sparse_matrix_rows.sake:8-12. They also become `new`'s optional trailing arguments, which Ruby does not expose.
- **`initialize` cannot take arguments that are not fields.** browser_history.sake:5: Ruby
  `Tab.new(name, url)` turns `url` into the first `Page`. chained_hash_table.sake:8: Ruby `Table.new(3)` uses
  3 only as the bucket count. Neither argument is a field, so both keep a `create` factory.
- **No identity comparison** (still). browser_history.sake:51 and markup_tag_checker.sake:50 use
  `==`/`!=` on Structs (field-wise and recursive) for Ruby's `equal?`; cycle_detection.sake:20 compares `id` fields.
- **No `max`/`min` on two values.** list_toolkit.sake:145 and rpn_stack_calculator.sake:68-69 write
  `x > a ? x : a` for Ruby's `[a, x].max` (Tuple has no `max`; `Array.max(Array[a, x])` is no clearer).
- **Record patterns cannot match a value.** two_stack_print_queue.sake:80 writes `in {peek:}` for Ruby's
  `in { peek: true }`.
- **No `loop`.** skip_list_index.sake:11-17 keeps a flag `while` for Ruby's `loop do ... break unless ... end`.
- **No `Enumerable`.** ring_buffer_metrics.sake:40-52 writes `to_a` and `mean` by hand where Ruby's `Ring`
  includes `Enumerable` and calls `sum`/`map`; singly_linked_list.sake:45 likewise.

## Ruby comparison

- Every operation names its type, so a linked-list program reads `Node.get_next(n)` / `Node.set_next(a, b)`
  where Ruby has `n.next` / `a.next = b`; this dominates the files (e.g. lfu_cache_buckets.sake:20-25).
- The instance is an explicit first parameter (`def push(s, v)`) and methods are called `Stack.push(st, v)`;
  Ruby's chaining `d.push_back(2).push_back(3)` becomes separate statements (deque_sliding_window.sake:115-118).
- Ruby's `private` helpers are ordinary class functions here (chained_hash_table `slot`/`grow`, lru_cache
  `unlink`/`link_front`); internal state such as `@ids`, `@heads` is declared with `attr_reader`, so it is readable from outside.
- Records whose Ruby class has `attr_accessor` stay `X = Struct.new(...)` (equivalent); exceptions and reader-only records now look like Ruby's classes.
