# tsort (TSort)

`require "tsort"` → `sakelib/tsort.sake`. Test: `test/sakelib/tsort.{sake,rb}` (identical output).
Tarjan's algorithm as Ruby's `tsort.rb` writes it (recursive), so components come out in Ruby's order.

## Design: two forms

1. **Mixin, Ruby's form.** A type includes `TSort` and defines the two required functions:

   ```ruby
   class Build
     attr_reader names, deps
     include TSort
     def tsort_each_node(b) = Array.each(@names) { |n| yield(n) }
     def tsort_each_child(b, name) = Array.each(@deps[name] || String[]) { |d| yield(d) }
   end
   Build.tsort(b)            # static: Build's tsort
   TSort.tsort(b)            # dispatches on b's type (which must include TSort)
   ```

   A built-in type can include it too. Ruby's own doc example works unchanged in shape:
   `class Hash; include TSort; def tsort_each_node(h) = Hash.each_key(h) { |n| yield(n) };
   def tsort_each_child(h, n) = Array.each(Hash.fetch(h, n)) { |c| yield(c) }; end`, then
   `Hash.tsort(h)`.

2. **A Hash graph** (node => Array of children), no include: `TSort.tsort_hash(h)`,
   `TSort.strongly_connected_components_hash(h)`, `TSort.tsort_each_hash(h) { }`,
   `TSort.each_strongly_connected_component_hash(h) { }`. A child that is not a key is a leaf.
   These stand in for Ruby's module functions `TSort.tsort(each_node, each_child)`, which take two
   callables (`h.method(:each_key)`, a lambda); Sake has no first-class blocks. Inside, they wrap the
   Hash in an internal Struct type `TSortHashGraph` that includes TSort.

**Trade-off.** The mixin is the general form: any node source (a field, a computed set, a file),
nodes of any type, and the graph's own representation; the cost is two definitions in the user's
type. It is resolved statically (`Build.tsort` is fixed before running; `TSort.tsort(x)` checks that
`x`'s type includes TSort). The Hash form costs nothing to call but fixes the representation, and
because a Struct field has one type for the whole program, every Hash passed to `tsort_hash` merges
into the field type of `TSortHashGraph.h` (`--types` shows a union of all callers' Hashes); this is
harmless here because nodes are only used as Hash keys and compared with `==`. Making `Hash` include
TSort inside the library would give `Hash.tsort(h)` for free, but it would decide Hash's
`tsort_each_child` for every program (missing key: leaf or KeyError?) and clash with a user's own
`class Hash; include TSort` (a duplicate definition), so the library does not do it; Ruby does not
either. Having one includer inside the library also means a program that requires tsort but never
includes TSort is fine.

## API

| Ruby | Sake | |
|---|---|---|
| `include TSort` + `tsort_each_node(&b)` + `tsort_each_child(n, &b)` | `include TSort` + `def tsort_each_node(g)` + `def tsort_each_child(g, n)` (yield) | same (subject first) |
| `obj.tsort` | `T.tsort(obj)` / `TSort.tsort(obj)` | same |
| `obj.tsort_each { }` | `T.tsort_each(obj) { }` | same |
| `obj.strongly_connected_components` | `T.strongly_connected_components(obj)` | same |
| `obj.each_strongly_connected_component { }` | `T.each_strongly_connected_component(obj) { }` | same |
| `obj.each_strongly_connected_component_from(n, id_map = {}, stack = []) { }` | `T.each_strongly_connected_component_from(obj, n, id_map = Hash[], stack = Array[]) { }` | same (returns the minimum id as Ruby) |
| `obj.tsort_each` (no block → Enumerator) | — | missing (no Enumerator; its `.to_a` is `tsort`, so an Array stand-in would only repeat that) |
| `TSort::Cyclic` | `TSortCyclic` | differs: name (no nested names) |
| `TSort.tsort(each_node, each_child)` and the other module functions on callables | `TSort.tsort_hash(h)`, `strongly_connected_components_hash`, `tsort_each_hash`, `each_strongly_connected_component_hash` | differs: a Hash graph instead of two callables |
| `TSort.each_strongly_connected_component_from(node, each_child, ...)` | — | missing (use the mixin) |

9 operations ported (5 mixin + 4 Hash-graph), plus the exception type.

## Behavior notes

- A self-loop (`{a: [:a]}`) is a one-node component, so `tsort` does not raise for it: Ruby's
  behavior, kept (the test checks it).
- **When components are yielded** (phase 2): after the traversal from each start node ends, not the
  moment each is found as in Ruby. Ruby passes `{ |c| yield c }` down every recursion level, so each
  component climbs back up through all of them; Sake does the same (blocks are not values) at ~10 µs a
  level, which made a 3000-node DAG take 24 s. Components are now collected in an Array and yielded by
  the outer loop. Same components, same order; differs only if `tsort_each_child` has side effects
  that the yield block observes, or the block stops the traversal early (`break`).
- Recursion: a 3000-deep chain works (4500 too after phase 2); 5000 raises `SystemStackError` (Sake's limit of 10,000 calls,
  ~3 calls per level). Ruby 4.0.2's own TSort already fails at 3000 (`stack level too deep`), so
  this is no worse than Ruby. An iterative version would need the children of a node as an Array
  (one `tsort_each_child` call per node), which is possible but was not needed.

## Built-ins Sake lacks

None for the algorithm. Language-level: first-class blocks (Ruby's callable form) and Enumerators
(`tsort_each` without a block). (Optional parameters: added, used in phase 2.)

## Friction

- Wrote `def TSort.tsort_hash(h)` inside `module TSort` (next to the mixin functions) → ``error:
  `def TSort.tsort_hash` inside `TSort`: write `def tsort_hash` `` → following the hint would have made
  them mixin functions (dispatching on `h`'s type, which does not include TSort). Moved the four
  `def TSort.f` definitions after the module body instead. The hint could mention `module_function
  :tsort_hash` or a definition outside the body.
- `--types` lists `Build.tsort_hash`, `Hash.tsort_hash`, ... among the dead functions: the module
  functions defined with `def TSort.f` are also borrowed by every includer (as Ruby's
  `module_function` leaves a private instance copy). Harmless, but `Build.tsort_hash(h)` is callable
  and means the same as `TSort.tsort_hash(h)`.
- Built-in errors carry a prefix Ruby does not have: `Hash.fetch: key not found: 9` (Ruby: `key not
  found: 9`). The test compares the suffix.
- What felt good: the required-function stubs (`def tsort_each_child(g, node) =
  raise(NotImplementedError)`) worked with yielding includers, and `class Hash; include TSort`
  worked, so Ruby's documented usage carried over directly. The first version ran under `--strict`.

## Phase 2

- `each_strongly_connected_component_from(g, node, id_map = Hash[], stack = Array[])` as in Ruby
  (phase 1 had no id_map/stack). The test calls it twice with a shared `id_map`/`stack` and prints them.
- The recursion collects components into an Array instead of chaining a yield block through every
  level (see "When components are yielded").
- No tables, no string scans.
- **Speed** (`experiments/2026-10-03-sakelib-port/phase2/bench_tsort.sake`: `TSort.tsort_hash` of a
  3000-node DAG, each node pointing at the next 3 (depth 3000); `bin/sake --strict`, CPU user+sys,
  3 runs, shared machine at load ~35 on 16 cores): before 24.36 / 24.00 / 23.91 s, after 2.44 / 2.43 / 2.53 s.
  The before time was the O(depth) yield chain: each of the 3000 components went up ~3000 block levels.
