# collections: generic containers in Sake

A binary heap, an LRU cache, and a ring-buffer deque, each meant to work for any element type. The
main question was: what does the checker infer when one library type is used with several element
types in one program?

Short answer: **a Struct field has one type per program, not one per value.** A `Heap` that holds
Integers in one place and Strings in another is, to the checker, a heap of `Integer | String`
everywhere. The way out that works is **one type per element type, all including a shared mixin
module**. The checker then infers each includer exactly (`TaskQueue.items: Task[]`,
`IntHeap.items: Integer[]`), and the program checks clean at level 2. The library is built around
that.

Files: `lib.sake`, `client_{scheduler,memo,window,stress,shared}.sake`, `build.sh` (writes
`out/<client>.sake` and runs it with `--strict`), the limit repros `limit_*.sake`, and the
checker-gap repro `bug_required_unqualified.sake`.

## API sketch

```ruby
module HeapOps            # includer fields: items (Array), seq (Integer)
  with_items(items)       # -> new includer value around an Array the caller made (Task[], Integer[])
  push(h, x)  pop(h)  peek(h)  size(h)  empty?(h)
  push_with(h, key, v)  pop_value(h)   # order by key only; stores [key, seq, v]
  drain(h) { |x| }        # yields in order, emptying the heap
class Heap                # ready-made: Heap.create, includes HeapOps

module LruNodeOps         # node includer fields: key, value, prev, nxt
module LruOps             # includer fields: capacity, index (Hash), head, tail, hits, misses
  make_node(c, k, v)      # required (raise NotImplementedError): build the includer's node
  with_index(hash, capacity)
  get(c, k)  put(c, k, v)  fetch(c, k) { |k| compute }  evict(c)  each(c) { |k, v| }  stats(c)
class LruNode, LRU        # ready-made: LRU.create(capacity)

module DequeOps           # includer fields: buf (Array), start, count
  with_buf(buf)
  push_back push_front pop_back pop_front front back at(d, i) each size capacity
class Deque               # ready-made: Deque.create
```

Using a container with a second element type means declaring a type (copied from the client):

```ruby
class TaskQueue < {reader: [items], accessor: [seq]}
  include HeapOps
end
tasks = TaskQueue.with_items(Task[])
```

## What the typer infers (the focus)

| Program | What was written | Inferred (from `--types`) | Level-2 reports |
|---|---|---|---|
| `limit_generic_field.sake` | one `Box`, used with Integers and with Strings | `Box.items: Array@L4[Integer \| String]` | 1 (`Comparable.<` on `(Integer, String)`) |
| `limit_generic_typed_field.sake` | the same, but each Box gets its own `Integer[]` / `String[]` from the caller | `Box.items: Integer[]@L9 \| String[]@L12` | 2, including `Array.push: an element must be Integer, but can be Integer \| String` on a push of the literal `3` |
| `limit_mixin_alloc_site.sake` | `IntBox` and `StrBox` include one mixin whose `create` does `new(Array[])` | `IntBox.items: Array@L2[Integer \| String]`, and the same for `StrBox` | 0 here, but the types are wrong |
| `client_scheduler.sake`, first version | the ready-made `Heap` holding Tasks, Integers, Strings, Tuples, and `push_with` entries | every heap holds the union of all five | 11 |
| `client_shared.sake` | ready-made `Heap`, `LRU`, `Deque`, each with two element types | `Heap.items: [Integer \| String]`, `LruNode.value: Integer \| String`, `Deque.buf: [Float \| String]` | 9 (3 inside the library) |
| final clients | one includer type per element type, with the Array/Hash made by the caller | exact: `TaskQueue.items: Task[]`, `ParseNode.value: [Integer, Integer]`, `CellHeap.items: Tuple[]`, ... | 0 |

What I learned about the rules (from these repros, not from the docs):

- Function **parameters** are polymorphic per call, but **fields** are inferred once per type
  definition. Giving each value its own typed Array does not help, because the field holds the union
  of the Arrays.
- A function borrowed through `include` is checked **per includer**: `@items` inside `HeapOps`
  resolves to `IntHeap.items` or `TaskQueue.items`, and calls to `new(...)` resolve to the
  includer's constructor. This is what makes the mixin pattern work.
- An Array or Hash **allocated inside** a borrowed function is one allocation site for all includers,
  so it merges again. The caller has to allocate (`with_items(Task[])`).
- Values that pass through a block are per call. `drain(h) { |x| }` gives `x: Task` for a
  TaskQueue and `x: Integer` for an IntHeap. An Array built and returned inside a mixin function
  would merge, so the API yields instead of returning Arrays.

## Friction log

- [language-limit / type-check-false-report] Used the ready-made `Heap` for Tasks, Integers,
  Strings, and Tuples in one program → 11 reports, such as `Comparable.<: the operands may be
  (Integer, String), (Integer, Task), ... ([Integer, Integer, {cmd: String, id: Integer}], Task),
  which the left operand's type does not support [type]` (one message is about 1,500 characters) and
  `Task.get_priority: argument 1 must be Task, but can be nil | Integer | String | ...`, inside
  `Task.<=>` → **partly**: the unions are listed, but nothing says they come from the shared field
  `Heap.items` or names the other pushes; I found that with `--types` → an includer type per element
  type (mixin) → 3 attempts (minimal repro, then a typed Array per instance, which failed, then
  mixins).
- [type-check-false-report] Gave each instance its own `Integer[]` / `String[]` →
  `Array.push: an element must be Integer, but can be Integer | String [type]` on
  `Box.add(ints, 3)` (`limit_generic_typed_field.sake`) → **no**: the push is a literal Integer into
  an `Integer[]`, so the message reads as wrong → gave up on this route → 1.
- [ruby-habit] Swapped heap slots with `items[i], items[p] = items[p], items[i]`, and moved the last
  element with `last = Array.pop(items); items[0] = last` → nothing at the line itself, but `nil`
  showed up in every `Comparable.<` operand list (`(nil, Integer), (nil, nil), ...`), because
  `a[k]` and `Array.pop` give `T | nil` and writing that into an untyped Array adds nil to its
  element type → **partly**: no hint said where the nil entered → `Array.fetch` on both sides of
  the swap, and `Array.fetch(items, -1)` before `Array.pop` → 2 attempts.
- [language-limit] A shared `create` in the mixin (`def create = new(Array[])`) merged the element
  types of all includers (`limit_mixin_alloc_site.sake`) → no report; seen only in `--types` → **no**
  → the caller passes the container: `with_items(Integer[])`, `with_index(Hash[], 2)` → 1.
- [type-check-false-report] `def drain(h) = until empty?(h); yield(pop(h)); end` →
  `Task.get_deadline: argument 1 may be nil (nil | Task) [nil]`, in the client's block →
  **yes** → loop on the popped local (`x = pop(h); while x != nil; yield(x); x = pop(h); end`) → 1.
  The program was correct; the check `empty?` is not linked to `pop`'s nil.
- [ruby-habit] `while (b = IndexDeque.back(q)) && Array.fetch(xs, b) <= x` →
  `Array.fetch: argument 2 may be nil (Integer | nil) [nil]` → **yes** → assign before the loop and
  again at the end of its body → 1. An assignment inside a condition is not narrowed.
- [bug] In `LruOps.put`, an unqualified call `make_node(c, key, value)` to a required function
  (body `raise(NotImplementedError)`): an includer that does not define it is **not** reported
  before running; it fails while running with `NotImplementedError: NotImplementedError`
  (`bug_required_unqualified.sake`) → **no** → written qualified, `LruOps.make_node(...)`, which
  is reported statically with a good hint (`C2 includes LruOps but does not define make_node ...
  hint: define def make_node(...) in class C2`) → 1.
- [message] Forgot `include Comparable` on Task → `Comparable.<: Task does not include Comparable`
  with `hint: add include Comparable and def <(a, b) to class Task` → **yes**, but the hint names
  `<`, while the docs say defining `<=>` is the way.
- [message] An includer missing the `seq` field → `include HeapOps in Q: HeapOps.push_with uses
  @seq, but Q is not a Struct type with field seq (line 30)`, reported twice (lines 30 and 31) →
  **yes**. Every includer must declare every field the module uses, even for functions it never
  calls.
- [language-limit] No stored comparator (blocks are not values), so the order is always `<` of the
  element. A max-heap or a custom order needs a key: `push(h, [-String.size(w), w])`, or
  `push_with(h, key, v)`, which stores `[key, seq, v]` so that values are never compared. A
  descending heap of Strings would need a wrapper type with a reversed `<=>`. Its field would
  again have one type per program, so it would need one wrapper per element type.
- [language-limit] `new` takes every field positionally, internal ones included
  (`ParseCache.new(2, Hash[], nil, nil, 0, 0)` leaked head, tail, hits, and misses to the client) →
  fixed by a constructor in the mixin (`with_index(index, capacity)`) → 1.
- [tooling] Concatenating files: an error in a client is at `out` line N+288, while the library's
  lines match. A hint chain mixes both (`reached by the call at line 295 → line 27`: 295 is the
  client, 27 is the library). `build.sh` prints the offset, but I still did the subtraction each time.
- [tooling] `--types` lists about 90 "dead functions" (every unused library function, once per
  includer), which buries the fields section that answers the question.

## What felt good

- **The mixin pattern works, and the checker understands it exactly.** `@items` inside
  `module HeapOps` means the includer's field, `new(...)` means the includer's constructor, and
  `--types` showed `TaskQueue.items: Task[]`, `IntHeap.items: Integer[]`,
  `ParseNode.value: [Integer, Integer]`. The LRU's doubly linked list, with `nil | ParseNode` in
  every prev/next field, passed level 2 the first time: 103 checks proven, 0 partial.
- **A typed Array at the constructor pays.** With `TaskQueue.with_items(Task[])`, a stray
  `TaskQueue.push(tasks, "oops")` is reported at the library's push (`Array.push: an element must
  be Task, but is String`) with `reached by the call at line 300`. With an untyped Array, the same
  kind of mistake (a Tuple pushed) appeared as 5 reports deep inside sift_up and `Task.<=>`.
- `fetch(c, key) { |k| compute }` with `yield` is a natural memoize API. Recursion through it
  (`ways(30)`) needed no help.
- `client_stress` (20,000 random operations per container against Array/Hash references, and
  Dijkstra on a 40x40 grid, checked against a Ruby Bellman-Ford) passed level 2 on the first run.

## What felt bad (top 3)

1. **Every element type costs a type declaration** that repeats the container's field list: 3 lines
   per heap or deque, and 7 lines for an LRU (a node type, a cache type, and `make_node`). The
   scheduler client spends 9 of its 42 code lines on this. The obvious Ruby-style use (one `Heap`
   for everything) runs correctly, but gives 9 to 11 reports, which cost me most of the first
   20 minutes to understand.
2. **Hidden merges.** An allocation inside a shared function, or nil written in by a swap, changes
   inferred types with no report at the point where it happens. I only found both through `--types`
   or through very long operand lists far away. This cost about 15 minutes and two repro files.
3. **The required-function check depends on how the call is written** (unqualified: runtime
   `NotImplementedError`; `Module.f(...)`: a static report). It is easy to write it the unchecked way
   inside the module itself.

## Library design under Sake

- In Ruby: `PriorityQueue.new { |a, b| ... }` or `.new(by: ->(x) { ... })`, `LRU.new(100)` used for
  anything, and `Deque` returning Arrays from `to_a`. In Sake:
  - no comparator, so the order is `<`, with a Tuple key or `push_with` for custom orders.
  - the containers are mixin modules, and each element type needs a type that includes them. The
    ready-made `Heap`, `LRU`, and `Deque` are for programs with one element type.
  - constructors take the storage from the caller (`with_items(Task[])`), since an allocation
    inside the library would merge.
  - iteration is by `yield` (`drain`, `each`) rather than by returning Arrays.
  - required functions are called qualified (`LruOps.make_node`) so that the check works.
- Struct settings: `reader:`/`accessor:` helped (internals like `seq`, `head`, `hits` are not
  settable from outside), but `reader: [items]` still hands out the mutable Array itself. Each
  includer has to repeat the module's field settings exactly, and nothing ties them to the module
  except the "uses @seq" check.
- Typed Arrays: `Task[]`, `Integer[]`, `String[]`, and `Tuple[]` at the constructor all worked, and
  made the includer's types exact. The first Deque took a "filler" value to fix the element type,
  because `Array.new(n, nil)` would have typed every slot nil. Growing from an empty typed Array
  removed that.

## Numbers

- Lines (code, without blanks and comments / total): lib 217 / 287. Clients: scheduler 42/52,
  memo 34/44, window 46/56, stress 102/115, shared 24/32.
- Static reports before each program ran clean:
  - scheduler: 11, 11, then 3, then clean. 9 came from the shared field (limit or false reports),
    2 were nil from `pop_value` (correct by the rules), and the 3 were nil from `drain` (correct
    program, false report).
  - memo: 0.
  - window: 1 (assignment in a `while` condition).
  - stress: 0.
  - Real mistakes of mine that the checker caught: 0. Of five deliberate mistakes (missing field,
    missing `make_node`, missing `Comparable`, a String pushed into `Task[]`, a Tuple pushed into an
    untyped queue), 4 were reported before running. `make_node` was not, until the call was
    qualified.
- Level-2 reports I could not remove: `client_shared.sake` has 9 at both level 1 and level 2, and
  runs only with `--strict=0`. The 6 in the client can be removed with `if x in Integer`. The 3
  `Comparable.<` reports inside `HeapOps.sift_up` and `sift_down` cannot be removed from the client.
  That program exists to show the limit; the other four run clean with `--strict`.
- Running time: `client_stress` takes about 11 s (5,000-element heap sort, plus 20,000 operations on
  each of the LRU and the deque).

## Suggestions

1. **Field types per allocation site, or per instance, for Struct types** (or a way to state
   "generic in this field"), so that one `Heap` type with several element types checks the way Ruby
   code would be written. (friction: shared `Heap`, typed Array per instance)
2. **When a report's union comes from a field, name the field and the writes that widened it**, for
   example: `hint: Heap.items holds Integer (pushed at line 287) and String (line 289); all Heap
   values share one element type`. Also cut the long operand-pair lists to the pairs that differ.
   (friction: the 1,500-character `Comparable.<` message)
3. **Check required functions however they are called**: an unqualified call inside the module
   should get the same "includer does not define" report as `Module.f(...)`.
   (`bug_required_unqualified.sake`)
4. **Say where a `nil` entered a container's element type** (`a[i]` or `Array.pop` written back into
   the same Array), or narrow an `a[i]` that is known to be in range in a swap. (friction: the swap
   idiom)
5. **Tooling for several files**: either `require`, or a `# line` directive that `build.sh` could
   emit so that messages name `client_x.sake:N`. Also a way to hide "dead functions" in `--types`.
   (friction: line offsets, `--types` noise)
