# graph: a Sake-lang graph library, and how it felt

Files: `lib.sake` (library), `client_routes.sake`, `client_build.sake`, `client_maze.sake`,
`client_stress.sake` (clients), `build.sh` (concatenates lib + client into `out/`), `bug_*.sake`
(minimal repros), `probe_*.sake` (deliberate mistakes, to see what is caught). `out/*.txt` hold the
`--strict` output of each program, `out/*.types` the `--types` output.

All four clients run clean with `bin/sake --strict out/client_*.sake` (level 2) and with the default
level. No level-2 report was left in place.

## API sketch

```
Graph.directed_graph / Graph.undirected_graph        -> Graph   (class Graph < {reader: [directed, adj]})
Graph.add_node(g, v)  Graph.add_edge(g, a, b, w)  Graph.connect(g, a, b)   # connect = weight 1
Graph.nodes(g) Graph.size(g) Graph.has_node?(g, v) Graph.neighbors(g, v) Graph.out_edges(g, v)
Graph.predecessors(g, v) Graph.has_edge?(g, a, b) Graph.weight(g, a, b) -> w | nil
Graph.edges(g) -> Tuple[] of [from, to, w]  (each undirected edge once)
Graph.each_bfs(g, s) { |v, depth| }   Graph.bfs(g, s) -> Array
Graph.each_dfs(g, s) { |v| }          Graph.dfs(g, s) -> Array
Graph.bfs_path(g, a, b) -> Array | nil                 # fewest edges
Graph.dijkstra(g, s) -> [dist Hash, prev Hash]
Graph.shortest_path(g, a, b) -> [cost, Array] | nil    # cheapest
Graph.topo_sort(g) -> Array, raises CycleError (field `cycle`: the nodes of one cycle)
Graph.acyclic?(g)  Graph.components(g) -> Array of Arrays (weakly connected, union-find)
module Implicit: include it, define each_neighbor(x, v) { yield(n, w) }, get X.bfs_path(x, a, b)
Heap (internal): binary min-heap of Tuples
```

Node types used by the clients: String (cities), a Struct `Task` (build order), `[row, col]` Tuples
(maze), Integer / Symbol / String / Tuple and a mixed-type graph in one program (stress).
Weights: Integer (km, seconds) and Float (terrain cost).

## Friction log

- [type-check-false-report] (the main one) Dijkstra's heap held `[dist, seq, node]`, and a Tuple
  compares element by element. `seq` is unique, so nodes are never actually compared. Each graph in
  client_stress has one node type, but different graphs in the same program use different types →
  `lib.sake:18:16: error: Comparable.<=: elements compared in order may be (Integer, String),
  (Integer, Symbol), (Integer, [Integer, Integer]), (String, Integer), ... which cannot be compared
  [type]` (3 such errors, also at the **default** level). Was the message enough? **partly**: it
  named the line and the pairs, but not where the union came from. `--types` showed it:
  `Graph.adj: Hash[Integer | String | Symbol | [Integer, Integer] => ...]`. A field's type is one type
  for the whole Struct type, not one per value, so the node types of every Graph in the program are
  merged. Two node types are enough (`bug_field_type_per_struct.sake`, a 14-line repro without the
  library). Fix: change the heap to `[dist, seq]` and keep the nodes in a side Array `queued`,
  indexed by `seq`, so the library never compares nodes. 3 attempts (diagnose, make the repro,
  redesign). See "Library design".
- [type-check-false-report] `Heap.pop`: `last = Array.pop(a)` and then `a[0] = last`, after a
  check that the heap is not empty → `Indexable.[]=: argument elem may be nil (nil | [Integer,
  Integer, String]) [nil]`. Enough? yes. Changed the guard to `return top if last == nil ||
  Array.empty?(a)`. 1 attempt. The value is nil only when the heap is empty, which the caller rules
  out, but a check on the Array does not narrow what `Array.pop` returns.
- [type-check-false-report] `while (v = Array.shift(queue))` does not narrow `v` inside the loop →
  `multiple assignment: argument 1 may be nil (nil | [Integer, Integer]) [nil]`, reported inside the
  client's `each_neighbor` with a hint chain. Enough? **partly**: the hint says to use `while x`,
  which is what I thought I had written. Rewrote it as `until Array.empty?(q); v = Array.shift(q);
  next unless v`. 2 attempts. Repro: `bug_while_assign_no_narrowing.sake`.
- [type-check-caught-bug] (borderline) In `topo_visit`, `Array.drop(path, Array.index(path, n))` →
  `Array.drop: argument 2 may be nil (Integer | nil) [nil]`. Enough? yes. Added `|| 0`. 1 attempt.
  It cannot actually be nil (a gray node is on the path), so this is an invariant the checker cannot
  see, not a bug. Notably, client_routes had already run "clean" under `--strict` with this same
  lib, because it never calls `topo_sort`. The report appeared only once a client reached it.
- [type-check-caught-bug] In client_build, `last, total = Hash.max_by(finish) { ... }` →
  `multiple assignment: argument 1 may be nil (nil | [Task, Integer]) [nil]`. Enough? yes. This is a
  real edge case (an empty graph); I added an early return. 1 attempt.
- [ruby-habit] `Array.map(Array.each_with_index(String.chars(row)).Array.to_a) { ... }` (an
  enumerator without a block) → `Array.each_with_index requires a block` and `undefined function
  Array.to_a` (hint: `to_a is defined in Tuple.to_a, Hash.to_a, ...`). Enough? yes. The line was dead
  code anyway, so I deleted it. 1 attempt.
- [language-limit] There is no `block_given?` and no optional block, so a Ruby-style
  `bfs(g, s)` that yields when given a block and returns an Array otherwise cannot be written. No
  message: this was a design decision. Each traversal comes as a pair, `each_bfs`/`bfs` and
  `each_dfs`/`dfs` (about 10 extra lines).
- [language-limit] No callbacks: Dijkstra cannot take a weight function, A* cannot take a
  heuristic, and a search cannot take "the neighbors of v" as a function. As the replacement I tried
  a mixin, `module Implicit`, whose includer defines `each_neighbor` (client_maze's `Grid`). It
  works, and it reads well, but it ran into the next two entries.
- [bug] A required function stub, `def each_neighbor(s, v) = raise(NotImplementedError)`, which the
  module calls with a block → `Implicit.each_neighbor does not take a block (it has no yield)`,
  even though the includer's `each_neighbor` yields. Enough? **partly**: it is true of the stub but
  not of the includer's function, which is the one that runs. Workaround: a stub with a dead yield,
  `raise(NotImplementedError); yield(v, 0)`. 3 attempts. Repro: `bug_required_block_function.sake`.
- [bug] With no stub at all (as the tutorial's `Summary`/`each` example does), every program that
  never includes `Implicit` fails: client_build got `undefined function each_neighbor` at a line of
  lib.sake that it never calls. Enough? **no**: nothing points to "no type includes Implicit". So
  one optional, unused part of a library breaks every client. Repro:
  `bug_unused_mixin_undefined.sake`. The dead-yield stub above avoids both problems.
- [tooling] `build.sh` concatenates the lib and a client, so every line number is a line of `out/X.sake`.
  Errors in the library show the library's line, with `reached by the call at line 289 → line 190`
  pointing into the client. I wrote a marker line, `# ---- client_x.sake starts at line N (client
  line = line - M)`, and did the subtraction by hand every time. There were no name clashes, since
  everything is under `Graph.`/`Heap.`/`Implicit.`, but a client's top-level `def cost`/`def tasks` shares
  one namespace with the library's top level.
- [tooling] The library cannot be checked on its own. A function nobody calls is not checked at
  all: `probe_dead_code_unchecked.sake` contains `String.upcase(1)` in an uncalled function and
  passes `--strict` with exit 0. `--types` lists such functions as "dead functions", which is useful,
  but for a library author it means the clients are the test suite. Each client checks only the
  slice of the API it reaches (see the `topo_visit` entry).
- [missing check] A Struct with its own `<=>` used as a node (`probe_custom_equality_node.sake`) is
  rejected only while running: `TypeError: Hash.store: Money cannot be a Hash key or Set element: it
  defines its own equality`. The rule depends only on the type, so it could be reported before
  running. The message itself is clear.
- [message] A client mistake, a String weight `"5"` (`probe_wrong_weight.sake`), is caught before
  running, but it is reported at `lib.sake`'s `w < 0` and `d + w`, with the client line only in the
  hint chain. Enough? partly: you have to know to read the last hop of the chain.

## What felt good

- **Node types needed no work.** The same `Graph` took Strings, `Task` structs, `[r, c]` Tuples,
  Symbols, and even a graph mixing `1`, `"one"`, `:one`, and `[1, 1]` (topo_sort and components ran fine).
  In Ruby, a Struct node needs nothing extra either. In Sake, `Task` nodes printed through my
  `Task.to_s` inside `Array.join`, and `Hash`/`Set` keys on Structs and Tuples just worked.
- **`--types` described each client's use of the library without being asked:**
  `Graph.adj: Hash[String => Tuple[]]` (routes), `Hash[[Integer, Integer] => Tuple[]]` (maze),
  `Hash[Task => Tuple[]]` and `CycleError.cycle: Array[Task]` (build). It also inferred
  `Task.name: :compile_app | :compile_lib | ... | :test`, the exact set of 8 Symbols. Its "dead
  functions" line lists which part of the API each client uses.
- **Nil results became client obligations.** `bfs_path` and `shortest_path` return `nil` when
  there is no path. `probe_forgot_nil.sake` uses them unchecked, and `--strict` rejects both uses
  before running. In Ruby, that is a NoMethodError at some later date.
- **The whole-program check found the stress problem in the first place.** It was a false report,
  but it was right that my heap compared nodes. Only an invariant (`seq` is unique) kept that from
  going wrong.
- **Lines that read well:** `Graph.each_bfs(roads, "Tokyo") do |city, depth| break if depth > 2`;
  `d, seq = Heap.pop(heap)`; `Array[*needs, [:fetch, :package]]`; the multi-target swap in the heap
  (`a[parent], a[i] = a[i], a[parent]`).
- `class Graph < {reader: [directed, adj]}` plus `@adj` inside the class was pleasant. Writing
  `@directed` inside a block inside a class function just worked.

## What felt bad (top 3)

1. **Generic containers are not generic per value.** All Graphs in a program share one field type,
   so two node types in one program turn every node operation in the library into a union. Cost:
   about 30 minutes, including the diagnosis and the repro, and a less obvious Dijkstra (a side Array
   of queued nodes instead of storing the node in the heap entry). In general, a library cannot
   compare, add, or otherwise operate on a client's values without risking this report once a
   second client type appears in the same program.
2. **No callbacks, and the mixin replacement has rough edges.** Paired `each_x`/`x` functions,
   no weight function or heuristic, and the `Implicit` mixin needed a stub with a dead `yield` to get
   past two separate rejections (two bug repros). Cost: about 20 minutes and a 3-line comment
   explaining the hack.
3. **Single-file programs.** Every error message needed a line subtraction. The library is only
   checked through whichever clients reach it. A part of the library that a client does not use can
   still break that client (`bug_unused_mixin_undefined.sake`). Cost: small per message, but it
   happened on every error.

The interpreter is slow but not a blocker. Dijkstra over a grid took 0.24 s at 400 nodes, 1.09 s at
1,600, 2.75 s at 3,600 and 4.75 s at 6,400; BFS took 0.05 to 0.66 s over the same graphs. That is
roughly n log n, measured on the local machine with single runs. The first heap version, with
3-Tuples, took 15.4 s at 3,600 nodes. I did not isolate why. client_stress uses 1,600 nodes.

## Library design under Sake

- **Constructors and defaults.** There are no keyword arguments or defaults, so I wrote
  `Graph.directed_graph`/`Graph.undirected_graph` instead of `Graph.new(directed: true)`, and
  `connect(g, a, b)` instead of `add_edge(g, a, b, w = 1)`.
- **Never operate on nodes beyond `==` and use as a Hash key.** This is the lesson from the
  per-type field: the heap entry became `[dist, seq]` and the node went into a side Array. In Ruby I
  would have stored `[dist, node]` and let ties compare the nodes. Weights are the client's values
  too (`w < 0`, `d + w`). Integer and Float weights mix fine, but a program that also used, say,
  Rational or Time weights elsewhere could hit the same merged-type report (untested).
- **Traversals come as two functions** (`each_bfs` with a block, `bfs` returning an Array), instead
  of Ruby's `return enum_for(...) unless block_given?`.
- **No pluggable behavior.** In Ruby, `dijkstra(g, s, &weight)` or `astar(g, s, t) { |v| h(v) }`.
  In Sake, the only extension point is a mixin module with required functions (`Implicit`), which
  makes the client define a type (`Grid`) even when a lambda would do.
- **Typed arrays.** `Tuple[]` for edge lists and the heap was easy. However, `Tuple[]` does not
  say *which* Tuple (`[node, weight]`), and `--types` shows only `Tuple[]@L52`. Node collections
  (`queue`, `out`, `path`) had to be `Array[]`, because the node type belongs to the client. The
  client could write `Task[...]` for its own data. It caused no trouble, but it caught nothing
  either, since I made no mistake there.
- **Records vs `class C < {reader: ...}`.** `reader:` stops `Graph.set_adj` from outside, but the
  Hash it returns from `Graph.get_adj` is still mutable, so it protects the slot, not the content.
  It did not get in the way. For `Task`, `reader: [name, secs]` was exactly right.
- **Errors.** `CycleError = Exception.new(:cycle)` carries the cycle as data, and clients rescue it
  by name. This felt as good as Ruby.

## Numbers

| file | lines | non-blank, non-comment |
|---|---|---|
| lib.sake | 258 | 241 |
| client_routes.sake | 29 | 28 |
| client_build.sake | 66 | 61 |
| client_maze.sake | 83 | 81 |
| client_stress.sake | 62 | 57 |

Static errors before each program ran clean (level 2):

| program | my mistakes | false reports | notes |
|---|---|---|---|
| client_routes | 0 | 1 | Heap.pop nil |
| client_build | 1 | 1 | max_by nil (real); topo index nil (invariant); later 1 `undefined function each_neighbor` (bug, from Implicit) |
| client_maze | 2 | 2 | 2 from the enumerator habit; `each_neighbor` stub has no yield (bug); `while (v = ...)` narrowing |
| client_stress | 0 | 3 | all from the per-type field union |

In total: 3 of my mistakes and 8 false reports or bugs. Level-2 reports I could not remove: 0.
At `--strict=3`, the clients still have 5, 12, 13, and 12 `index-nil` reports. I did not attempt
level 3: `h[k]` on Hashes I just filled is everywhere in graph code.

## Suggestions

1. **Field types per value for a type used as a container** (friction: the per-type field union,
   `bug_field_type_per_struct.sake`). At least, when a comparison fails on a union that comes from a
   field, say so: "Graph.adj has keys Integer | String because of Graph values made at lines X and
   Y". That would have saved most of the 30 minutes.
2. **Required functions that yield.** Let a `raise NotImplementedError` stub be called with a
   block, or take the block-ness from the includers (`bug_required_block_function.sake`). Also,
   do not reject a mixin function that nobody can reach because no type includes its module
   (`bug_unused_mixin_undefined.sake`). Today a library with an optional mixin breaks unrelated
   clients.
3. **Narrow `while (x = expr)`** like `while x` (`bug_while_assign_no_narrowing.sake`). It is the
   idiomatic Ruby queue loop.
4. **Several files, or at least line mapping.** A `require`, or a directive such as
   `# line 1 "client.sake"` that the messages honor. With it, library errors would name `lib.sake:174`,
   and the call chain would name the client file. Related: an option to check uncalled functions
   (`probe_dead_code_unchecked.sake`) so a library can be checked without clients.
5. **Report a custom-equality Struct used as a Hash key or Set element before running**
   (`probe_custom_equality_node.sake`). The rule depends only on the type.
