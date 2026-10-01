# Notes (06-linked)

## General

- `x.inspect` inside interpolation is a call on a value; written `Kernel.inspect(x)` (static error at first, my slip).
- Sake has no identity comparison (`equal?`). Node identity checks (`node.equal?(@tail)` in Ruby) are
  written `node == @tail`, which on Struct values compares type and fields (recursively through `next`).
  Same result for these programs, but not the same meaning (and it walks the rest of the list).

## singly_linked_list

- See General (`==` for identity).

## rpn_stack_calculator

- `Float.round(x, 4).to_s` slipped in: "method call on a value `Float.round(x, 4).to_s` is not allowed"; fixed to `Float.to_s(...)`.
- No unary minus: Ruby `-stack.pop(tok)` is `0 - Stack.pop(stack, tok)`. `case op when "+"` is `case op in "+"`.
  The Ruby `%w[...]` constant (`BINARY`) is a helper function with an `Array[...]` literal (no value constants).

## markup_tag_checker

- `Array.sort_by` with a Tuple key (`[line, col]`) fails at run time:
  "ArgumentError: Array.sort_by: cannot compare elements of types Issue". The message names the
  element type, not the key type (Tuples have no ordering). Minimal repro:
  `p(Array.sort_by(Array[3, 1, 2]) { |x| [x, 0] })` -> "cannot compare elements of types Integer".
  Workaround: an Integer key `line * 10000 + col`.
- `break` out of a `while` inside a block is fine; Ruby's `until top.equal?(found)` became `while top != found` (Struct equality, see General).

## two_stack_print_queue

- `in {peek: true}` (a value inside a Record pattern): "only Record patterns that bind fields are
  supported: `in {x:, y: name}`". Sake uses `in {peek:}` and ignores the binding; Ruby keeps `{ peek: true }`.
- Ruby's `private def shift_over` has no Sake counterpart; it is an ordinary `TwoStackQueue.shift_over`.

## ring_buffer_metrics

- No `Array.new(n, x)`: the slots are a `Float[]` filled by `Integer.times`. Ruby's `include Enumerable`
  (giving `sum`/`map`) is replaced by the Ring's own `each`/`to_a`/`mean`. Ruby's value constant
  `READINGS` is a function `readings`.

## deque_sliding_window

- `!window.empty?` is written `Deque.empty?(window) == false`; `-i` as `0 - i`. Ruby's `@front&.value` is a ternary.

## merge_log_streams

- Ruby's `lists.each_slice(2).map { ... }` (an enumerator) becomes `Array.each_slice` with a block that pushes into a new Array.

## sparse_polynomial

- Ruby's `c.abs` on a coefficient that may be Integer or Rational: Sake has no polymorphic `abs`
  (only `Integer.abs`, `Rational.abs`), so it is `c < 0 ? 0 - c : c`. Ruby's `def self.from_pairs` is `Poly.from_pairs` in the class body.

## josephus_circle

- Cycle termination needs identity (`cur.equal?(loop_start)` in Ruby); Sake's `cur != loop_start` is
  Struct equality, which Sake (like Ruby's Struct) evaluates safely on cyclic structures — checked with two
  separate one-node cycles: `a == b` is true in both. Correct here only because names are distinct.
- `sort_by { [-n, name] }` (Tuple key, see markup_tag_checker) became a String key `format("%03d %s", 100 - n, name)`.

## undo_redo_editor

- `from, to = String.split(arg, "|")`: "TypeError: multiple assignment needs a Tuple, got Array" (run time).
  Rewritten as `parts = String.split(...)` and `parts[0]`, `parts[1]` (Ruby: `replace_all(*arg.split("|"))`).
- Ruby's `case cmd when Insert` (class `===`) is `case cmd in Insert` in Sake.
- `String.[]` takes one index argument only, so `s[0, pos]` is written with Ranges (`s[0...pos]`) in both versions.
- `String.index` has no start-offset argument; the search continues on `@text[start..]` and adds `start` (both versions).
- First draft used fields named `undo`/`redo` (Ruby keyword `redo`); renamed to `undos`/`redos` before running.

## skip_list_index

- `Array.new(n)` / `Array.new(n, head)` become push loops. Ruby's `loop do ... break unless ... end`
  (no `loop` in Sake, no `break` in blocks) is a `while` with a flag variable.

## bank_teller_sim

- Naming the type `Queue` broke only the Ruby side (`Thread::Queue` is reopened: "not initialized (TypeError)");
  renamed to `WaitQueue` in both. The `Walkable` mixin (size/to_list over the includer's `each`) is called
  both statically (`WaitQueue.size`) and through the module (`Walkable.size(...)`, dispatch).

## digit_list_bignum

- `a == b` on BigNat: Ruby goes through Comparable's `<=>`; Sake compares Struct fields (the digit lists),
  which agrees after trimming. Ruby class methods (`self.parse`, `self.trim`) live in `class BigNat` with no subject.

## cycle_detection

- Identity is an `id` field: `Node.get_id(a) == Node.get_id(b)` in Sake where Ruby uses `a.equal?(b)`, and the
  visited Set holds ids because a Struct cannot be a Set element (Ruby puts the nodes themselves in the Set).
- My bug, found at run time: "TypeError: Node.get_id: argument 1 must be Node, got nil" — `fast` can be nil after
  `fast = next(next(fast))`; Ruby's `slow.equal?(fast)` tolerates nil. Added `fast &&`.
- Record field read `floyd(head)[:cyclic]` (Ruby Hash) is a pattern `floyd(head) => {cyclic: still}`.

## free_list_pool

- `Array.new(capacity) { |i| ... }` and `Array.new(capacity, x)` are a single `Integer.times` loop filling
  `String[]`, `Integer[]`, and an untyped `Array[]` for the booleans (true/false has no typed-array name).

## circular_playlist

- `target.equal?(@now)` is compared by title in Sake (titles are unique); `target ||= t if ...` became
  `target = t if ... && target == nil` (written out; not tried with `||=`).

## sparse_matrix_rows

- A user `[]`/`[]=` with a Tuple index (`m[[r, c]]`) and `out[[r, c]] += v` both work. Ruby's `(0...n).sum { }`
  has no Sake form (`Range.sum` takes no block), so it is `Array.sum(Array.map(Range.to_a(0...n)) { })`;
  `[1] * n` became a push loop.

## chained_hash_table

- Ruby's `sort_by { |k, v| [-v, k] }` again needs a String key in Sake (Tuple keys cannot be compared).

## monotonic_stack_prices

- Ruby's `prices.each_with_index.map` (enumerator without a block) has no Sake form; the Sake version pushes
  into an Array inside `Array.each_with_index`. `Array.new(n, -1)` is a push loop.

## list_toolkit

- Ruby's `trail&.head` is a ternary; `[a, x].max` in a block is `x > a ? x : a`.
