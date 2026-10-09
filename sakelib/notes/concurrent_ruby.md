# concurrent-ruby

`require "concurrent_ruby"` → `sakelib/concurrent_ruby.sake`. Test: `test/sakelib/concurrent_ruby.{sake,rb}`
(the .rb uses the real gem, concurrent-ruby 1.3.7; identical output, 3 of 3 runs). Built on the built-ins
`Thread` (new/join with limit/value/kill/alive?), `Mutex` (synchronize), `Queue` (pop with timeout).

Nested names are flattened: `Concurrent::Future` → `ConcurrentFuture`, `Concurrent::Promise` →
`ConcurrentPromise`, `Concurrent::Atom` → `ConcurrentAtom`, `Concurrent::Map` → `ConcurrentMap`,
`Concurrent::Event` → `ConcurrentEvent`; `AtomicFixnum`, `AtomicBoolean`, `AtomicReference`,
`CountDownLatch`, `Semaphore`, `FixedThreadPool`, `IVar`, `ScheduledTask` keep their names.
14 types / modules, 121 functions (about 95 of the gem's API, the rest aliases and internals).

## API

| Gem | Sake | |
|---|---|---|
| `Future.execute { }` | `ConcurrentFuture.execute { }` | same (a thread per future) |
| `f.value`, `f.value(timeout)`, `f.value!` | `ConcurrentFuture.value(f, [timeout])`, `value!` | same (nil when rejected / not yet) |
| `f.wait`, `wait(timeout)` | `ConcurrentFuture.wait(f, [timeout])` | same |
| `f.state`, `fulfilled?`, `rejected?`, `pending?`, `processing?`, `complete?`, `incomplete?`, `reason` | same names, `f` first | same; the state while running is `:processing`, as the gem's |
| `f.cancel`, `add_observer { }`, `Future.new { }` + `execute` | — | missing: a block cannot be kept until `execute`; observers are stored blocks |
| `Promise.execute { }` | `ConcurrentPromise.execute { }` | same |
| `p.then { \|v\| }` | `ConcurrentPromise.then(p) { \|v\| }` | same: a child promise whose thread waits for p; rejection passes through |
| `p.rescue { \|r\| }`, `on_error`, `catch` | `ConcurrentPromise.rescue(p) { \|r\| }`, `on_error`, `catch` | same |
| `Promise.zip(*ps)` | `ConcurrentPromise.zip(*ps)` | same (value: an Array) |
| `Promise.fulfill(v)`, `Promise.reject(r)` | `ConcurrentPromise.fulfilled(v)`, `rejected(r)` | differs: name (the gem's class and instance methods share `fulfill`/`reject`; Sake flattens them, so the constructors are renamed) |
| `Promise.new { }`, `execute` later, `p.set`, `flat_map`, `then(rescuer, &block)` | — | missing (stored blocks; two blocks) |
| `IVar.new`, `set`, `try_set`, `fail`, `value`, `wait`, states | `IVar.new`, `IVar.set(iv, v)`, ... | same; `MultipleAssignmentError` is `ConcurrentMultipleAssignmentError` |
| `ScheduledTask.execute(delay) { }`, `value`, `cancel`, `cancelled?`, `pending?` | `ScheduledTask.execute(delay) { }`, ... | same, except `cancelled?`: true after `cancel` here (the gem's `cancel` completes the task as `:rejected`, so its `cancelled?` is false) |
| `Delay.new { }`, `TimerTask`, `Agent`, `Actor`, `Channel`, `Promises.future` | — | missing: `Delay` keeps a block until the first `value`; the rest are built on stored blocks or large |
| `Atom.new(v)`, `value`, `swap { \|old\| }`, `compare_and_set`, `reset` | `ConcurrentAtom.new(v)`, ... | same (`swap` runs the block once, under the lock; the gem retries on a lost race) |
| `AtomicFixnum.new([n])`, `increment([d])`, `decrement`, `value`, `value=`, `compare_and_set`, `update { }`, `up`, `down` | same; `value=` is `set_value` | same |
| `AtomicBoolean.new([b])`, `value`, `value=`, `true?`, `false?`, `make_true`, `make_false` | same; `set_value` | same |
| `AtomicReference.new(v)`, `get`, `set`, `value`, `get_and_set`, `compare_and_set`, `update { }` | same | differs: `compare_and_set` compares with `==`, the gem with `equal?` (identity) |
| `Map.new`, `[]`, `[]=`, `get`, `put`, `put_if_absent`, `compute_if_absent { }`, `compute_if_present { }`, `compute { }`, `merge_pair { }`, `fetch([default]) [{ }]`, `fetch_or_store`, `get_and_set`, `replace_if_exists`, `replace_pair`, `delete`, `delete_pair`, `key?`, `key`, `value?`, `keys`, `values`, `size`, `empty?`, `clear`, `each_pair { }`, `each`, `each_key`, `each_value` | `ConcurrentMap.*`; `m[k]`, `m[k] = v` via `include Indexable` | same (`fetch(m, k)` / `fetch(m, k, d)` by a rest parameter: nil is a value) |
| `Map.new(initial_capacity:)`, `Map.new { \|m, k\| }` (default block), `marshal_dump`, `to_a` | — | missing (default block) / `to_a` added |
| `CountDownLatch.new(n)`, `count`, `count_down`, `wait([timeout])` | same | same (`count_down` gives nil, the gem its latch) |
| `Semaphore.new(n)`, `acquire([n])`, `try_acquire([n, [timeout]])`, `release([n])`, `available_permits`, `drain_permits`, `reduce_permits` | same | same; FIFO hand-over of permits |
| `Event.new`, `set`, `set?`, `try?`, `reset`, `wait([timeout])` | `ConcurrentEvent.*` | same |
| `FixedThreadPool.new(n)`, `post { }`, `<<`, `shutdown`, `kill`, `wait_for_termination([t])`, `running?`, `shutdown?`, `shuttingdown?`, `length`, `queue_length`, `scheduled_task_count`, `completed_task_count`, `max_length` | same | differs in mechanism: `post` starts a thread at once that first takes one of n permits (a Semaphore); see below |
| `CachedThreadPool`, `ThreadPoolExecutor.new(opts)`, `fallback_policy`, `Future.execute(executor:)`, `global_io_executor` | — | missing |
| `Concurrent::Array`, `Concurrent::Hash`, `Concurrent::Set` | — | not needed: on MRI they are plain Array/Hash (the GVL); Sake's are the built-ins |

## できたこと / できなかったこと

- **できた**: everything whose block runs *now* (Future, Promise.execute, Atom.swap, Map.compute_if_absent,
  AtomicFixnum.update) and everything that is state under a lock (Map, atomics, latch, semaphore, event, IVar).
  The waiting primitives are a Queue per waiter: `wait` registers a Queue under the Mutex and pops it (with
  the timeout); the completing side pushes to every registered Queue under the same Mutex, so no wake-up is
  lost. `Queue.pop(q, timeout)` (built in since 2026-10-09) gives every `value(timeout)` / `wait(timeout)` /
  `try_acquire(n, timeout)`.
- **できた by changing the shape**: a block that must run *later* is given to a thread that waits first,
  because `Thread.new { }` is the one built-in that keeps a block:
  - `ConcurrentPromise.then(p) { |v| }` starts a thread that `wait`s for p, then runs the block (the gem
    stores the block in the child and runs it on the parent's completion; same observable behaviour).
  - `ScheduledTask.execute(delay) { }`: a thread that sleeps, checks `cancel`, runs.
  - `FixedThreadPool.post(pool) { }`: a thread per posted block that first `acquire`s one of `n` permits of
    a Semaphore, so at most `n` blocks run at a time and the others wait in the semaphore's FIFO. There is
    no queue of blocks (a Queue cannot hold a block) and no reused worker threads; the pool is a bound, not
    a pool. What differs from the gem: one OS thread per pending task, and FIFO is the order in which the
    task threads reached the semaphore, not the order of `post` (two blocks posted back to back may swap).
- **できなかった** (stored blocks): `Delay` (a block kept until first `value`), `Future.new { }` + `execute`
  later, `add_observer { }`, `Map.new { default block }`, `TimerTask`, `Agent`, `Promises` (the new API is
  all stored callbacks). The rule: "Blocks are second-class. They cannot be stored or returned" (spec §7).
- **できなかった** (two blocks): `Promise#then(rescuer) { }`.
- **Mixin over fields**: the gem's `Obligation` is the mixin `Obligation` here, over the fields `lock, status,
  result, error, waiters` that each of Future / Promise / IVar / ScheduledTask declares and sets in
  `initialize`. The fields had to be named apart from the operations: a `private attr_accessor value` is
  `T.value(x)`, and it shadows the mixin's `value(o, timeout)` ("X's own definition wins", spec §5.5).

## 書き心地

1. **`def ConcurrentFuture.execute` inside `class ConcurrentFuture`** → `error: write def execute (it
   defines ConcurrentFuture.execute)`. Wrote `def execute` (no subject) in the class. Clear message; one
   edit per constructor.
2. **The field named like the operation.** `private attr_accessor lock, state, value, reason, waiters` plus
   `include Obligation` (which defines `value(o, timeout)`, `state(o)`, `reason(o)`) → every
   `ConcurrentFuture.value(f)` in the test: `field value of ConcurrentFuture is private`. The reader won over
   the borrowed function. Renamed the fields `status`, `result`, `error`. Ruby lets `@value` and `def value`
   coexist; in Sake the field *is* an operation `T.value`, so it cannot share the name with another.
3. **Class method vs instance method of the same name.** `Promise.fulfill(v)` (class) and `promise.fulfill(v)`
   (Obligation, instance) flatten to one namespace: `fulfill(v)` in `ConcurrentPromise` shadowed Obligation's
   `fulfill(o, v)` inside the class (`fulfill(child, value(p))` → wrong arity). The constructors became
   `fulfilled(v)` / `rejected(r)`.
4. **A generic field is one type for the program.** The test's `ConcurrentPromise.then(pr) { |v| v * 2 }` →
   `Arithmetic.*: the operands may be nil ([Integer | nil | String | Array ...]) [nil]` (and `[mixed]`): the
   promise's `result` field holds every value any promise in the program ever had (Integers, the
   `"rescued bad"` String, zip's Array, nil). The block states its type: `v => Integer; v * 2`. Honest, and
   it is the price of a container type written as a Struct; a user of a typed language would expect
   `Promise<Integer>`. Same story as `Heap.items` in spec §2.1.
5. **`timeout == nil && Queue.pop(q)` does not narrow.** `return true if timeout == nil && Queue.pop(q);
   Queue.pop(q, timeout) == true` → `Queue.pop: argument 2 must be Integer|Float|Rational, but is nil [type]`.
   The checker narrows `if x == nil` branches, not a `&&` whose left operand was the test. Rewrote as
   `if timeout == nil ... return true end`. Two more lines, and the flow is plainer.
6. **A bug found by the test (not by the checker)**: the pool's six posted blocks all pushed `25`. A block
   given to `post` is yielded from a thread later, and reads the caller's loop variable `i` as it is *then*
   (5); Ruby's block parameters are fresh per call, so Ruby gives 0..5. Minimal repro:
   `notes/concurrent_ruby_bug_yield_in_thread_loop_var.sake` (the spec's copy rule covers blocks lexically
   around `Thread.new`, not a block yielded from the thread). Workaround: pass `i` through a function
   parameter (`def post_square(pool, ..., i) = FixedThreadPool.post(pool) { ... i ... }`): a function's
   locals are per call.
7. **Where it read well**: `include Indexable` gives `m[k]` / `m[k] = v` on `ConcurrentMap`;
   `Mutex.synchronize(@lock) { @value += delta }` is `AtomicFixnum.increment` in one line; `rescue => e`
   inside the Thread block of `settle` rejected the obligation with the exception value, which `reason` then
   gives back, exactly as the gem. The waiting code (register a Queue under the lock, pop it outside) typed
   without a comment, including `q` being `nil | Queue` and narrowed by `if q != nil`.
8. **The thread exception rule bit once in a probe**: `rescue RuntimeError` around `Thread.value(t)` of a
   thread that raises → `the begin body never raises RuntimeError [rescue]`; the typer does not carry a
   thread's raises to `Thread.value`. `rescue => e` is accepted.
9. **Gem quirks the diff found**: `completed_task_count` counts only tasks that did not raise;
   `shutdown?` is false while posted tasks still run (`shuttingdown?`); `ScheduledTask#cancelled?` is false
   after a successful `cancel`; `IVar#set` twice raises with the class name as message. Matched the first
   two, kept Sake's `cancelled?` true (not compared).

## Built-ins requested

- **A Queue (or any container) that can hold a block, or a callable value**: the one thing between this
  file and a real thread pool, `Delay`, observers. Everything else of the gem is reachable with threads.
- **Per-call block parameters when a block is yielded from a thread** (bug above): without it, every
  "run this later" API needs the function-parameter workaround.
- `Thread.join(t, limit)` returning `nil` on timeout is used; a `Thread.status` / `Thread.stop?` would let
  `FixedThreadPool.length` count running (not merely alive) threads.
- A `ConditionVariable` would halve the waiting code (the Queue-per-waiter pattern appears 6 times here);
  not necessary.
