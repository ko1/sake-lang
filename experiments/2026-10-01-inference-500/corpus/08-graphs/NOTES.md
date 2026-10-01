# 08-graphs notes

## General (hit in several tasks)

- `==` on Tuples is not defined (`TypeError: Kernel.==: no implementation for (Tuple, Tuple)`),
  as spec.md says. Positions as `[x, y]` Tuples are compared with a helper that destructures both.
- **Interpreter bug:** `Array.join(a)` without a separator crashes the interpreter with a Ruby
  `NoMethodError` (not a Sake error). Repro: `puts(Array.join(Array[1, 2]))` ->
  `stdlib.rb:176: undefined method 'map' for an instance of Integer (NoMethodError)`.
  `Array.join(a, "")` works. Used the explicit `""` everywhere.

## maze_bfs

- `cur == goal` on `[x, y]` Tuples failed (see above); replaced by `same_pos?(cur, goal)`.

## dijkstra_routes

- `Array.sort_by` with a Tuple key `[dist, name]` fails:
  `ArgumentError: Array.sort_by: cannot compare elements of types String` (the message names String,
  although the keys are Tuples). Tuples have no ordering in Sake. Workaround in Sake only: a String
  key `format("%08d %s", dist, name)`, which sorts the same way.

## course_schedule

- `code, rest = String.split(line, ":")` fails: `TypeError: multiple assignment needs a Tuple, got Array`.
  Multiple assignment only takes Tuples; `split` gives an Array. Rewritten as `parts = String.split(...)`
  with `parts[0]`, `parts[1]` (which keeps Ruby's nil for a missing part).

## kruskal_network

- No `Array.new(n, 0)`: the rank array is `Range.map(0...n) { 0 }`. (`<=>` as an expression works
  inside a user `<=>`, despite spec §8.3 listing it as unsupported.)

## rival_teams

- `case result in {ok: true, side:} ... in {ok: false, cycle:}` is rejected statically:
  `error: only Record patterns that bind fields are supported: \`in {x:, y: name}\``. Value patterns
  inside a Record pattern are not available; rewritten as `result => {ok:, side:, cycle:}` and `if ok`.
- `unless ... elsif` is not Ruby; there is no `!`, so the "not yet colored" test was turned around
  (`if Hash.key?(side, nb) ... else ...`). Ruby's `Hash.new { |h, k| h[k] = [] }` became `adj[a] ||= Array[]`.

## tarjan_scc

- My mistake, but worth noting: in `Tarjan.run(graph)`, which builds the Tarjan value `t`, I wrote
  `@index` meaning `t`'s field; `@x` always refers to the first parameter (`graph`, a Hash), so it failed
  at run time with `TypeError: Tarjan.get_index: argument 1 must be Tarjan, got Hash`. Used
  `get_index(t)` there. The Ruby version's `@index` in a `new`-ed instance has no such counterpart.

## astar_terrain

- `break if cur == start` (Tuples) rewritten as a component-wise comparison (Tuple `==` is undefined).
- Picking the best node: in Ruby, `Comparable` makes `==` come from `<=>`, so `open.index(open.min)`
  can find a different node with the same f/g; Sake's Struct `==` compares fields. To avoid the
  divergence both versions scan for the index of the minimum.

## intern_matching

- Again `name, skills, wishes = line.split(";").map(&:strip)` needs indexing in Sake (`fields[0]` ...),
  since `split`/`map` give an Array, not a Tuple.

## exam_slots

- Ruby's `sort_by { |n| [-graph[n].size, n] }` needs both a unary minus and a Tuple key; Sake has
  neither. Used a String key `format("%03d %s", 999 - size, n)`.

## land_islands

- Ruby's `history.each_cons(2).count { |a, b| b < a }` uses an Enumerator; Sake's `Array.each_cons`
  needs a block and blocks cannot `break`/return a count, so the Sake version counts with an index loop.

## currency_paths

- Array `+` is not in the operator table, so Ruby's `path + [nb]` is `Array.push(Array.dup(path), nb)`.
  Ruby's `Hash.new { |h, k| h[k] = {} }` (no block-form default in Sake) became `graph[k] ||= Hash[]`.

## make_rebuild

- `Target.deps(t)` (dispatch through the module) was rejected: `error: undefined function \`Target.deps\``
  with the hint that `deps` exists in `FileTarget` and `PhonyTarget`. Dispatch only reaches functions
  the module itself defines, so `Target` got a placeholder `def deps(t) = Array[]` that both types
  override. In Ruby the module does not need it (duck typing).
- `t.is_a?(FileTarget)` is `t in FileTarget`; `mtimes.dup` is `Hash.merge(mtimes, Hash[])` (no `Hash.dup`).

## prim_cables

- No `Math::PI` (no built-in constants, no value constants): `def pi = 3.141592653589793`, the same
  double as Ruby's `Math::PI`.

## centrality

- `Array.count(Array.combination(ns, 2)) { |a, b| ... }` fails at run time:
  `ArgumentError: block takes 2 parameter(s) but was given 1`. `combination` yields Arrays, not Tuples,
  and only Tuples are destructured into block parameters. Used `{ |pair| ... pair[0] ... pair[1] }`.
  (Same for any Array-of-Arrays; Ruby destructures both.)
