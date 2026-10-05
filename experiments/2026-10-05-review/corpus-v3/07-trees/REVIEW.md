# Review: 07-trees (corpus-v3, 2026-10-05)

All 25 programs run with `bin/sake --strict=0` and print their `.out` exactly (exit 0).
The `.rb` files here are dangling symlinks; the Ruby reference read was
`experiments/2026-10-01-inference-500/corpus/07-trees/NAME.rb`.

- avl_tree: `class AvlNode` + `attr_accessor key, height = 1, left = nil, right = nil` (defaults) replaces `Struct.new` + a `make(key)` factory; `AvlNode.new(key)` as Ruby.
- bill_of_materials: `class CycleError/UnknownPart < StandardError` + `attr_reader` (exception types); `cost` memoizes with `@memo[part] ||= Array.sum(...) { }` as Ruby; the broken-catalog loop uses `do ... rescue ... end` instead of `begin` inside the block.
- bst_basic: `class Node` + `attr_accessor`; `each_inorder(node, &block)` passes the block on instead of re-yielding through `{ |k, v| yield(k, v) }`.
- btree: `class BNode` + `attr_accessor`; `BTree` gets `attr_accessor root = nil, splits = 0` and `def initialize(bt)` building the empty root, so `BTree.new(t)` replaces `BTree.create(t)`; `each_key`/`walk` pass `&block` on (`Array.each(keys, &block)`); duplicates counted with `Array.count { !insert }` as Ruby.
- decision_tree: `class Leaf`/`class Split` + `attr_reader`; `count_nodes` is Ruby's `map + reduce([1, 0]) { |(t, l), (t2, l2)| ... }` (nested block parameters); `load` is `header, *lines = ...` + `Array.to_h(Array.zip(header, values))` (splat assignment).
- dom_tree: `class Element/Text` + `attr_reader`; `class MarkupError < StandardError`; `VOID_TAGS` is `def void_tags = once { ... }`; `each_element(node, &block)`; `*parts, last = String.split(...)` replaces `Array.pop`; `do ... rescue` in the bad-markup loop.
- expression_tree: `class Num/Var/BinOp` + `attr_reader`; `ParseError`/`UnboundError` as exception classes; `Parser` has `attr_reader tokens, pos = 0` and `Parser.new(String.scan(...))` (the `tokenize` factory is gone); both loops use `do ... rescue`.
- fenwick_ranks: `attr_reader size, tree = nil` + `def initialize(f) = @tree = Array.new(@size + 1, 0)`, so `Fenwick.new(n)` as Ruby (was a `create` factory with `Range.map { 0 }`).
- filesystem_du: `Dir` has `subdirs = nil, files = nil` filled in `initialize` (`Dir.new(name, parent)` as Ruby); `mkdir_p` is `Array.reduce(parts, root) { |d, name| subdirs[name] ||= Dir.new(name, d) }`; `each_dir(d, &block)` moved into `class Dir`; `FileEntry`/`NotFound` as classes; `*parts, name = Array.drop(..., 1)`; `do ... rescue`.
- heap_scheduler: `MinHeap` has `attr_reader items = nil` + `initialize` (`MinHeap.new`); `swap` is `@items[i], @items[j] = @items[j], @items[i]`.
- huffman: `class Leaf`/`class Internal` + `attr_reader`.
- interval_bookings: `class Booking` (fields and functions in one body), `class INode` + `attr_accessor`, `class Conflict < StandardError`; `Room` has `attr_accessor root = nil, count = 0` so `Room.new("Orion")`; `do ... rescue`.
- ip_route_trie: `class BitNode` + `attr_accessor zero = nil, one = nil, route = nil` (`BitNode.new`); `class Route` with its `to_s`; `class BadAddress < StandardError`; `RouteTable` has `attr_reader root = nil, size = 0` + `initialize` (`RouteTable.new`); `add` walks with `Integer.times(len)` and `get_zero(node) || set_zero(node, BitNode.new)` (Ruby's `node.zero ||= BitNode.new`); `each_route`/`walk` pass `&block`; lookups loop uses `do ... rescue`.
- kd_tree: `class Place/KdNode/Search` with `attr_reader`/`attr_accessor`.
- lazy_seat_inventory: `class SoldOut < StandardError`; `Array.new(4 * n, 0)` and `Array.new(days, seats)` replace `Range.map { 0 }`; `do ... rescue`.
- merkle_sync: `class MLeaf/MNode` + `attr_reader`; MLeaf defines `get_lo`/`get_hi` (Ruby's `def lo = index`), so `lo_of`/`hi_of` are `(MLeaf|MNode).get_lo(n)`; `build` uses `Array.each_slice(level, 2) { |a, b| b == nil ? a : ... }` (short last slice now gives `b = nil`); `verify` and the edits are `reduce` with `|acc, (side, sib)|` / `|text, (from, to)|` (nested block parameters).
- org_chart: `class Employee` with `attr_accessor reports = nil` + `initialize` (`Employee.new` without the `Array[]` argument), functions in the same body; `class OrgError < StandardError`; `do ... rescue`.
- quadtree: `class Rect/Pt` + `attr_reader`; `class OutOfBounds < StandardError`; `Quad` has `attr_reader bounds, depth, points = nil, kids = nil` + `initialize`, so `Quad.new(bounds, depth)` as Ruby (the `create` factory is gone).
- rope_editor: `class RLeaf/RNode` + `attr_reader`; `each_leaf(r, &block)`; `do ... rescue`.
- segment_tree_stats: `Array.new(4 * n, 0)`; `DAYS` is `def days = once { ... }`; `do ... rescue`.
- spanning_tree: `DisjointSet` has `attr_reader sets, parent = nil, rank = nil` + `initialize`, so `DisjointSet.new(n)` (field order changed so the one argument comes first); `class Edge`; `Array.new(n, -1)` / `Array.new(n) { Array[] }`.
- taxonomy_lca: `Array.new(n, 0)` / `Array.new(n) { Array[] }`; both error loops use `do ... rescue`.
- traversals: `class BT` + `attr_reader`; `vertical` groups with `Array.push(cols[col] ||= Array[], ...)` (for Ruby's `Hash.new { |h, k| h[k] = [] }`).
- tree_codec: `class TNode` + `attr_accessor`; `class DecodeError < StandardError`; `do ... rescue` in both loops.
- trie_autocomplete: `TrieNode` with `attr_accessor children = nil, terminal = false, freq = 0, pass = 0` + `initialize` (`TrieNode.new`), `Trie` with `attr_reader root = nil, words = 0` + `initialize` (`Trie.new`); insert uses `child = (TrieNode.get_children(node)[c] ||= TrieNode.new)`.

No program was left unchanged.

## Friction

- **A default must be a literal, so a field that starts as `[]`, `{}`, or another object is written
  `= nil` and then set in `initialize`.** I wanted `attr_reader subdirs = Hash[]` (Ruby:
  `@subdirs = {}` in `initialize`). That is not allowed because a default is a literal number, String,
  Symbol, true, false, or nil. What I wrote: `subdirs = nil, files = nil` plus
  `def initialize(d) ... @subdirs = Hash[]` (filesystem_du.sake:2-7; also btree.sake:10-12,
  heap_scheduler.sake:12-14, org_chart.sake:3-5, quadtree.sake:21-26, ip_route_trie.sake:31-33,
  trie_autocomplete.sake:2-10). It reads like Ruby, but the `= nil` only exists so that `new` can
  leave the field out.
- **`new` takes the fields, not Ruby's constructor parameters.** I wanted `LazyTree.new(values)`,
  `SegTree.new(values)`, `Taxonomy.new(pairs)`, `Train.new(name, days, seats)`, and
  `Catalog.new`. In Ruby, `initialize` takes inputs that are not fields and derives the fields from
  them. In Sake, `C.new` stores fields positionally, and `initialize(c)` takes only the instance. So
  the factories `LazyTree.build`, `Train.open` (lazy_seat_inventory.sake:7, 95),
  `SegTree.build` (segment_tree_stats.sake:3), and `Taxonomy.build` (taxonomy_lca.sake:3) stay, as
  does `Catalog.new(Hash[], Hash[], Hash[])` (bill_of_materials.sake:12). Where the parameter is a
  field, I reordered the fields so that it comes first and the rest can take defaults
  (spanning_tree.sake:2 `sets, parent = nil, rank = nil`; quadtree.sake:21 moves `depth` before
  `points`/`kids`). This changes the order that `p` would show.
- **No attribute `+=`/`||=` from outside the class.** Ruby's `st.rotations += 1` becomes
  `Stats.set_rotations(st, Stats.get_rotations(st) + 1)` (avl_tree.sake:20, 30), and
  `node.zero ||= BitNode.new` becomes `get_zero(node) || set_zero(node, BitNode.new)`
  (ip_route_trie.sake:43-45). `@x OP= v` exists only inside the type's own functions.
- **No `&.`.** Ruby's `best = node.route if node&.route` stays an `if node` with a nested
  local (ip_route_trie.sake:62-65).
- **`case`/`in` without `else` raises on nil.** Ruby's `case r when RLeaf ... when RNode ... end`
  silently does nothing for nil. Sake needs `in nil then nil` (rope_editor.sake:79).
- **A same-named reader on a second type has to be written out by hand.** For
  `(MLeaf|MNode).get_lo`, MLeaf defines `def get_lo(l) = @index` (merkle_sync.sake:5-6). This
  imitates the accessor naming convention in user code.
- **`each_slice(n)` without a block** (Ruby `blocks.each_slice(2).map`, `chars.each_slice(n).map(&:join)`)
  is still a static error ("requires a block"), so `blocks_of` in merkle_sync keeps its index loop.

## Ruby comparison

- **Shape a Ruby programmer notices first.** Each operation names its type, so
  `Node.get_left(node)` stands where Ruby has `node.left`, and every method takes its subject as an
  explicit first parameter (`def peek(ps) = @tokens[@pos]`). Bodies that are chains of attribute
  reads get 2-3x longer (bst_basic, avl_tree, kd_tree).
- **Class bodies.** With the new `attr_*` lines, the class bodies now match Ruby's: fields and
  functions sit in one `class`, and exceptions are `class X < StandardError` with `attr_reader`. The
  remaining differences are the `initialize(c)` subject parameter, the absence of
  `private`, and `new` taking fields (see Friction).
- **`case node when Leaf`** becomes **`case node in Leaf`**, and `is_a?` becomes `x in T`.
  Ruby's `[a, b].max`/`.compact.min` idioms stay as `Array.max(Array[...])` or ternaries
  (lazy_seat_inventory.sake:72-74, segment_tree_stats `pull`).
- **`==` on Struct values is structural.** Ruby's `a.equal?(b)` in tree_codec `same?`
  (tree_codec.sake:81) is `a == b`. The two agree here only because one side is nil.
