# 08-graphs review (corpus-v3, 2026-10-05)

All 25 programs run with `bin/sake --strict=0` and match `NAME.out` (exit 0). The `.rb` files in this
directory are dangling symlinks; the Ruby originals were read from
`experiments/2026-10-01-inference-500/corpus/08-graphs/`.

- astar_terrain: `Terrain`, `Node` from `Struct.new` to `class` + `attr_reader` (as Ruby).
- bellman_ford: `class NegativeCycle < StandardError` + `attr_reader cycle`; `Arc` as `class` + `attr_reader`.
- centrality: unchanged
- course_schedule: `CycleError`, `UnknownCourse` as `class < StandardError` + `attr_reader`; `Course` as `class` + `attr_reader`; `credits_s, prereq_s = String.split(rest, "|")` (multiple assignment now gives nil for the missing part, as Ruby) replaces `fields[0]`/`fields[1]`.
- critical_links: `Grid` as `class` + `attr_reader`, `Scan` as `class` + `attr_accessor` (as Ruby); `disc[u] = low[u] = ...` chained assignment; `Array.new(n)`, `Array.new(n, 0)`, `Array.new(n) { Array[] }` replace `Range.map(0...n) { ... }`.
- critical_path: `Task` as `class` with `attr_reader id, title, days, deps` + `attr_accessor early, late` (as Ruby); `class CycleFound < StandardError`; the `starts` temporary folded into `Array.max(...) || 0` as Ruby writes it.
- currency_paths: `class RateError < StandardError`; `path + Array[nb]` (Array `+`) replaces `Array.push(Array.dup(path), nb)`.
- dijkstra_routes: `MinHeap` as `class` with `attr_reader items = nil` and `def initialize(h) = @items = Array[]`, so `MinHeap.new` takes no argument as in Ruby (the `create` factory is gone); swap by `@items[i], @items[j] = @items[j], @items[i]`; `prio_at` is `@items[i][0]`.
- dot_stats: `class ParseError < StandardError`; `Graph` as `class` + `attr_reader` with `add_node` inside it; `Hash.count(pairs) { |(a, b), c| ... }` (nested block destructuring, as Ruby); `Array.sum(edges) { ... }`.
- euler_itinerary: `class NoItinerary < StandardError`.
- exam_slots: `Exam` as `class` with `attr_reader course, students` + `attr_accessor slot` (as Ruby); `Array.sum(in_slot) { ... }`.
- floyd_transit: `Array.new(n) { |i| Array.new(n) { |j| ... } }` (as Ruby) replaces nested `Range.map`; `dist[i][j] = dist[j][i] = w`; `Range.map/select/reject(0...n)` instead of `Array.x(Range.to_a(...))`.
- friend_groups: unchanged
- intern_matching: `Intern`, `Project` as `class` + `attr_reader`; `Range.reject(0...n)`.
- kruskal_network: `UnionFind` as `class` with `attr_reader sets` and `initialize` building `@parent`/`@rank` from `@sets`, so `UnionFind.new(n)` as in Ruby (`create` gone); `@parent[x], x = root, @parent[x]` (element target in multiple assignment, as Ruby); `ra, rb = rb, ra if ...` modifier; `Edge` as `class` + `attr_reader`; `Array.sum(tree) { ... }`.
- land_islands: `Islands` as `class` with `attr_reader width, height, count = 0` and `initialize` making the two Hashes, so `Islands.new(10, 7)` as in Ruby (`create` gone); `|(x, y), step|` nested block destructuring.
- make_rebuild: `class MissingTarget < StandardError`; `FileTarget`/`PhonyTarget` as `class` + `attr_reader` (the module `Target` and its dispatch kept, since Ruby relies on it); `Target.label` calls the accessor `get_name(t)`, so the two `def name(t) = @name` wrappers are gone.
- maze_bfs: `Maze` as `class` + `attr_reader`; `neighbors` with `Array.filter_map` (as Ruby) instead of push into a result Array.
- metro_transfers: `Line` as `class` + `attr_reader`.
- org_chart_lca: `OrgTree` as `class` + `attr_reader`; `emp, boss = Array.map(String.split(line, "<")) { ... }` ("founder" has no boss: the missing part is nil, as Ruby); `Array.new(n, 0)`, `Array.new(levels) { Array.new(n) { ... } }`; `Range.each(1...levels)`, `Range.reject`, `Range.max_by`; `Array.sum(@children[v]) { ... }`.
- pipeline_flow: `FlowNet` as `class` whose `initialize` makes `@cap`, `@flow`, `@nodes`, so `FlowNet.new` takes no argument (as Ruby); `min_cut` is `Hash.filter_map(@cap) { |(a, b), c| ... }` (as Ruby); `Array.sum(cut) { ... }`.
- prim_cables: `Point`, `Site` as `class` + `attr_reader`; `Array.new(n, false)`, `Array.new(n)`; `Range.map(0...6)`.
- rival_teams: `left + Array[common] + Array.reverse(right)` (Array `+`, as Ruby) replaces `Array.concat(Array.push(...), ...)`.
- tarjan_scc: `Tarjan` as `class` with `attr_reader graph` plus defaulted internal fields and `initialize` making the collections, so `Tarjan.new(graph)` as in Ruby; `@index[v] = @low[v] = @counter`; `Array.sum(cycles) { ... }`.
- word_ladder: unchanged

Changed 22, unchanged 3.

## Friction

- **Internal state that Ruby's `initialize` creates has to be a declared, defaulted field.** Ruby's
  `def initialize; @items = []; end` (dijkstra_routes.rb:4) or `initialize(n)` building `@parent`/`@rank`
  (kruskal_network.rb:4) has no Sake counterpart where the constructor takes other arguments than
  the fields. Wanted: `MinHeap.new` with the field made inside. Could not: `C.new` takes the fields
  positionally and a default must be a literal (`= Array[]` is not allowed). Wrote: `attr_reader items
  = nil` plus `def initialize(h) = @items = Array[]` (dijkstra_routes.sake:2-3); likewise
  kruskal_network.sake:3-9, land_islands.sake:3-8, pipeline_flow.sake:2-7, tarjan_scc.sake:3-11. The
  placeholder `nil` default is a lie about the field (it is never nil after `new`), and the field is
  public (`get_parent`) where Ruby kept it private. It also only works when the constructor's
  parameters are a prefix of the fields; kruskal's `UnionFind.new(n)` works because `n` happens to be
  the `sets` field.
- **No value patterns inside Record patterns** (rival_teams.sake:62): Ruby's
  `case result in {ok: true, side:} ... in {ok: false, cycle:}` is still rejected
  (`only Record patterns that bind fields are supported`); kept `result => {ok:, side:, cycle:}` + `if ok`.
- **No `Hash.new { |h, k| h[k] = [] }`** (centrality.sake:4, 55; course_schedule.sake:44;
  critical_path.sake:51; dijkstra_routes.sake:55; metro_transfers.sake:38; rival_teams.sake:6;
  euler_itinerary.sake:35; word_ladder.sake:15): every grouping needs `h[k] ||= Array[]` and a second
  statement to push.
- **A type's class method and instance method cannot share a name.** Ruby's
  `def self.run(graph) = new(graph).run` + `def run` (tarjan_scc.rb:4,16): Sake has one namespace per
  class, so `Tarjan.run(graph)` (tarjan_scc.sake:13) does both.
- **`attr_reader name` is `get_name`, not `name`.** A mixin written against Ruby's reader
  (make_rebuild.rb:14 `"#{name}#{kind}"`) becomes `get_name(t)` (make_rebuild.sake:6); fine, but the
  module's requirement is now spelled through an accessor naming convention.
- **No `Math::PI`** (prim_cables.sake:14): `def pi = 3.141592653589793`.
- **No `Hash#dup`/`Hash#to_h { }`** (make_rebuild.sake): `Hash.merge(mtimes, Hash[])` for `dup`,
  and a loop filling a new Hash for `targets.to_h { |name, deps| ... }`.

## Ruby comparison

- Every call names its type: `Array.each(xs) { }`, `Hash.key?(h, k)`, `Node.get_x(n)`. This is the
  first and dominant difference in every file.
- Field access is `C.get_x(c)` from outside and `@x` inside the class; instance functions take the
  instance as an explicit first parameter (`def find(uf, x)`), and there is no `private` section.
- Growable collections are `Array[]`/`Hash[]`/`Set[]`; `[...]` literals are fixed-size Tuples used
  as positions and keys (`[x, y]`), which reads the same as Ruby there.
- Exceptions read the same now (`class E < StandardError` + `attr_reader`), but the message is
  `Exception.message(e)` and fields `E.get_field(e)`.
- Constructors whose arguments are not the fields (`MinHeap.new`, `UnionFind.new(n)`,
  `FlowNet.new`, `Tarjan.new(graph)`) look the same at the call site, but the class body carries extra
  `attr_reader ... = nil` lines a Ruby programmer would not expect.
