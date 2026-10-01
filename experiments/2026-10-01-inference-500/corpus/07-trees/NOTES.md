# Notes (07-trees)

## heap_scheduler
- Ruby's `items[i], items[j] = items[j], items[i]` is a static error in Sake: "only `a, b = tuple` (local variables, no splat) is supported". Written with a temp variable. (Local swap `a, b = b, a` works.)
- `name, pri, arr, dur = String.split(line, ",")` fails at run time: "TypeError: multiple assignment needs a Tuple, got Array". Workaround: index the Array (`f[0]`, `f[1]`, ...). (Recurring in other tasks; not repeated below.)
- A zero-argument constructor helper is written `def create = MinHeap.new(Array[])` in the class and called as `MinHeap.create`; Ruby uses `initialize` with no args.

## trie_autocomplete
- `Array.sort_by(found) { |w, f| [0 - f, w] }` fails: "ArgumentError: Array.sort_by: cannot compare elements of types Tuple" (Tuples have no ordering). Workaround: a String sort key `format("%08d %s", 99999999 - f, w)`. Ruby keeps `[-f, w]`.
- No unary minus: `-f` written `0 - f` (recurring; not repeated below).

## segment_tree_stats
- No `Array.new(n, 0)`: written `Range.map(0...(4 * n)) { 0 }`.
- No value constants: Ruby's `DAYS = %w[...]` becomes `def day_name(i) = Array[...][i % 7]`.

## expression_tree
- `if l in BinOp && prec(...) < ...` is a syntax error ("unexpected '&&', expecting end-of-input") since `in` binds loosely in Ruby's grammar; Sake needs `(l in BinOp) && ...`. Ruby uses `is_a?`.
- No `case`/`when`: dispatch on operator strings written as `if/elsif` chains; node kinds use `case e in Num ...`.

## huffman
- **Interpreter bug**: `Array.join` without the separator crashes the interpreter with a Ruby NoMethodError
  (`stdlib.rb:176: undefined method 'map' for an instance of String`). Repro: `p(Array.join(Array["a","b"]))`.
  With a separator (`Array.join(a, "")`) it works. Workaround used everywhere: always pass the separator.
- Ruby `sort_by { |c, code| [code.size, c] }` → String key `format("%03d%s", ...)` (Tuples are not ordered).
- Leaf/Internal share `weight`/`order`; Ruby duck-types `n.weight`, Sake needs `case n in Leaf ... in Internal ...` helper functions.

## spanning_tree
- Records as a bundle of three Arrays (`{parent:, up_km:, depth:}`) taken apart with `rooted => {parent:, up_km:, depth:}`; Ruby uses a Hash and `values_at`.

## taxonomy_lca
- A nested literal `[[["b","a"], ...], ...]` passed where an Array is iterated: "TypeError: Array.each: argument 1 must be Array, got Tuple". Fixed by writing the inner lists as `Array[...]` (pairs stay Tuples).
- Ruby's `index.fetch(name) { raise KeyError, ... }`: `Hash.fetch` takes no block in Sake; written as `[]` + nil check + raise.
- A Struct type with 9 fields all filled by a `build` function, since there is no `initialize`; the Ruby constructor computes them.

## btree
- `all == Array.sort(all)` fails: "TypeError: Kernel.==: no implementation for (Array, Array)" (Array equality is undecided). Sortedness checked with `Range.all?(1...n) { |i| all[i - 1] <= all[i] }`; Ruby keeps `all == all.sort`.
- Ruby's `each_key(&block) = walk(root, &block)` (block forwarding) becomes `walk(@root) { |k| yield(k) }`.

## dom_tree
- Ruby's `*parts, last = selector.split(" ")` (splat) → `Array.pop(parts)`; `tag, klass, id = m.captures` → `m[1]`, `m[2]`, `m[3]`.
- Ruby's early-exit `parts.reverse.all? { ... }` with a mutated anchor → `Array.each` with an `ok` flag (no `break` in blocks).
- Observation: `==`/`!=` on Struct values is structural, so two distinct Element nodes with equal fields compare equal
  (`E.new("p", Array[], r) == E.new("p", Array[], r)` is true), unlike Ruby objects. The program only compares a node
  with the root (`current != root`), where both agree.

## quadtree
- Ruby constants `CAPACITY = 3`, `MAX_DEPTH = 5` → `def capacity = 3`, `def max_depth = 5` (no value constants).
- A mutable counter passed through recursion is a `Hash[visited: 0]` in both versions (Records have no field writes).

## traversals
- Ruby's auto-vivifying `Hash.new { |h, k| h[k] = [] }` is not available (blocks are not values): `cols[col] = Array[] unless Hash.key?(cols, col)`.
- Ruby's `frontier.flat_map{...}.compact.select { |m| seen.add?(m.label) }` chain written as nested loops.

## merkle_sync
- `Integer.to_s(n, 16)` is rejected ("wrong number of arguments for Integer.to_s (given 2, expected 1)"); both versions use `format("%08x", h)`.
- Ruby duck-types `lo`/`hi`/`hash` across MLeaf and MNode; Sake needs `case`/`in`-based helpers (`node_hash`, `lo_of`, `hi_of`).
- Ruby's `each_slice(2).map { |a, b| ... }` and `reduce(...) { |acc, (side, sib)| ... }` → `Array.each_slice` (block gets an Array; index it) and explicit loops.

## ip_route_trie
- Ruby's `node.zero ||= BitNode.new` (attribute `||=`) and `node&.route` have no Sake form; written as `BitNode.set_zero(node, ...) if BitNode.get_zero(node) == nil` and an `if node` check.
- Ruby `addr, len = cidr.split("/")` → indexing (Array, not Tuple).

