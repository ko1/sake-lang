# pqueue

`sakelib/pqueue.sake`: a priority queue on a binary heap, after the pqueue gem. The reference is
`test/sakelib/ref/pqueue.rb` (plain Ruby; it also takes the gem's comparison block, which Sake cannot).
17 operations; the test prints 28 lines, identical to `pqueue.rb`, with queues of Integers, Strings,
Jobs (a Struct type with its own `<=>`) and `[priority, seq, task]` Tuples.

## API

| Ruby | Sake | |
|---|---|---|
| `PQueue.new(elements) { \|a, b\| a > b }` | `PQueue.new(elements, order: :max)` | differs: no comparison block (see below) |
| `PQueue.new(elements) { \|a, b\| a < b }` | `PQueue.new(elements, order: :min)` | differs |
| `PQueue.new { \|a, b\| custom }` | the element type's own `<=>` (`include Comparable`), or Tuple keys | differs |
| `q.push(*xs)`, `q << x` | `PQueue.push(q, *xs)`, `PQueue.<<(q, x)` | same |
| `q.pop`, `q.top` / `q.peek`, `q.shift(n)` | same | same (pop on empty: nil) |
| `q.size`, `length`, `empty?`, `clear`, `merge(other)` | same | same |
| `q.to_a` (pop order), `q.each_pop { }` | same | same |
| `q.inspect` | `#<PQueue max [...]>` | same as the ref |
| `q.replace`, `q.swap`, `q.include?`, Enumerable | | missing |

## What differs from Ruby, and why

- **The order is not a block.** The gem keeps the block given to `new` and calls it on every
  comparison; a Sake block cannot be stored. The order is `order: :max | :min` over the elements'
  `<=>`, and any other order is a type: a Struct type with `include Comparable` and `<=>` (the test's
  `Job` orders by priority, then by name), or Tuples, which compare position by position. This keeps
  "how to compare" on the elements' type, where the checker sees it.
- **The Array given to `new` becomes the queue's storage** and is heapified in place (Ruby copies it).
  See the bug below: an Array made inside the library is one allocation site for every queue type.
- **One queue type per element type.** The checker gives a field one type for all instances of a type,
  so an Integer queue and a Job queue in one program meet in `<=>`: `--strict=2` reports
  `Comparable.<=>: the operands may be (Integer, Job), (Integer, String), ... [mixed]`. The test declares
  `class JobQueue < PQueue; end` (and WordQueue, TaskQueue) and calls `JobQueue.push(...)`: `class B < A`
  works as an instantiation of a generic type, at the cost of naming the type at each call.
- `to_a` sorts by `<=>` (reversed for :max) instead of popping a copy, so elements equal under `<=>`
  keep sort order; the reference does the same.
- `inspect` prints `PQueue` for a `JobQueue` too: a function cannot name its includer's type.

## Friction

1. Integer, String, Job and Tuple queues in one test → five `[mixed]` reports (`Comparable.<=>`,
   `Job.priority`, `Array.push`, multiple assignment) → one `class XQueue < PQueue` per element type.
2. That still failed, with the same reports: `--types` showed `JobQueue.heap: Array@L21[Integer | Job |
   String | ...]`, the Array made by `@heap = Array[]` in `initialize`, one allocation site shared by
   PQueue and all its copies. `sakelib/notes/pqueue_bug_subclass_shares_array_site.sake` →
   heapify the caller's Array in place.
3. `(a <=> b) > 0` → `Comparable.>: the operands may be nil [nil]` (`<=>` gives nil for incomparable
   values) → `c = a <=> b`, raise ArgumentError unless c (as Ruby's sort does).
4. `pop` returns `nil | T`, so `each_pop`'s `yield(pop(q))` and the test's `pr, _, task = pop(tq)` were
   `[nil]` reports → a `take_top` that is called only on a non-empty heap (`Array.fetch`), used by
   `pop`, `shift` and `each_pop`.

## Language features used

- Keyword argument through `T.new`: `PQueue.new(nums, order: :min)` gives the field `order` by name: helped,
  it is the gem's call shape minus the block.
- `initialize` for the order check and the heapify.
- `private attr_reader heap = Array[]`, `attr_reader order = :max` (expression defaults).
- `*xs` rest parameter: `PQueue.push(q, 7, 10)`.
- `class B < A`: one queue type per element type (above); the most useful feature here.
- Multiple assignment to elements: `@heap[i], @heap[p] = ...` swaps.

## Checker findings before the test passed

- `--strict=1`: the `[mixed]` reports as warnings. `--strict=2`: the same as errors plus the two nil
  reports (friction 3, 4).

## Types

- `PQueue.heap: Array[Integer]` (several call-site Arrays), `WordQueue.heap: Array[String]`,
  `JobQueue.heap: Job[]`, `TaskQueue.heap: Array[[Integer, Integer, String]]`: one element type each,
  which is what the per-type queues buy. No partial or unknown checks.
