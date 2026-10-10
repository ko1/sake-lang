# monitor

`sakelib/monitor.sake`: Ruby's Monitor (reentrant lock), its condition variables (Ruby's
`MonitorMixin::ConditionVariable`, the same name here since 2026-10-10, `MonitorCond` before), `MonitorMixin`, and the exception type `ThreadError`.
Monitor: 18 functions (12 of Ruby's API plus aliases and 3 internal ones); MonitorMixin::ConditionVariable: 6; MonitorMixin: 10.
The test (threads, a bounded buffer, broadcast, the mixin) prints 29 lines, identical to `monitor.rb`, in 5 of 5 runs.

## What Sake has and what the port is built from

Sake's built-ins are `Mutex.new`/`Mutex.synchronize`, `Queue`, `Thread.new/join/value/alive?`, `sleep`.
There is no `Mutex.lock/unlock/try_lock/locked?`, no condition variable, and **no way to name the running
thread** (no `Thread.current`). So:

- A Monitor is a Mutex guarding its state (`locked`, `owner`, `count`) plus a list of waiters, each a
  `[Queue, me]`. `enter` on a taken monitor registers a Queue and blocks in `Queue.pop`; `exit` hands the
  lock over to the first waiter (sets owner and count, then pushes), so the lock never becomes free while
  someone waits and `try_enter` cannot steal it. Every state change is under the Mutex.
- A condition variable's `wait` registers a Queue in the cond (while holding the monitor), releases the monitor
  entirely (saving the re-entry count), blocks on the Queue, re-enters, restores the count. `signal`/`broadcast`
  (holding the monitor, as Ruby requires) push to the Queues. No lost wakeups: registration is under the monitor.
- **Reentrancy needs the thread's identity.** The caller may pass one, `me`, as a trailing optional argument:
  any value equal only to itself across threads (a Symbol, the loop index):
  `Monitor.synchronize(m, :worker1) { ... }`. Under the same `me`, a nested enter is counted, as Ruby.
  Without `me`, the Monitor cannot tell the holder from another thread: a nested enter waits forever
  (Ruby's Monitor re-enters; Ruby's Mutex raises). `mon_owned?(m, me)` requires `me`.
  This is what "Ruby uses Thread.current, Sake has none" costs; it is also what makes the single-thread part of
  the test deterministic (`:main`).

## API

| Ruby | Sake | |
|---|---|---|
| `Monitor.new` | same | same |
| `m.enter`, `mon_enter` | `Monitor.enter(m, me = nil)` | differs: `me` for reentrancy |
| `m.exit`, `mon_exit` | `Monitor.exit(m, me = nil)` | same; `ThreadError "current fiber not owner"` when not held (or, with `me`, held by another) |
| `m.try_enter`, `mon_try_enter`, `try_mon_enter` | `Monitor.try_enter(m, me = nil)` | same (true on re-entry under `me`) |
| `m.synchronize { }`, `mon_synchronize` | `Monitor.synchronize(m, me = nil) { }` | same; releases on exception |
| `m.mon_locked?` | same | same |
| `m.mon_owned?` | `Monitor.mon_owned?(m, me)` | differs: asks about `me`, not the current thread |
| `m.mon_check_owner` | `Monitor.mon_check_owner(m, me = nil)` | same |
| `m.new_cond` | `Monitor.new_cond(m)` → MonitorMixin::ConditionVariable | same |
| `cond.wait(timeout = nil)` | `MonitorMixin::ConditionVariable.wait(c, me = nil)` | differs: no timeout (`Queue.pop` has none) |
| `cond.wait_while { }`, `wait_until { }` | `MonitorMixin::ConditionVariable.wait_while(c, me = nil) { }`, `wait_until` | same |
| `cond.signal`, `broadcast` | `MonitorMixin::ConditionVariable.signal(c, me = nil)`, `broadcast` | same; `ThreadError` unless the monitor is held |
| `include MonitorMixin` (`mon_initialize`) | `private attr_accessor mon_data`, `@mon_data = Monitor.new` in initialize, `include MonitorMixin` | differs: the field is declared and set by the type; the checker reports a type that forgets to set it (nil at `Monitor.enter`) |
| `mon_enter`, `mon_exit`, `mon_try_enter`, `try_mon_enter`, `mon_synchronize`, `synchronize`, `mon_locked?`, `mon_owned?`, `mon_check_owner`, `new_cond` on the includer | `Account.mon_enter(a, me = nil)` etc. | same, with `me` |
| `Monitor#wait_for_cond(cond, timeout)` | `Monitor.release_for_wait`, `restore_count` (internal) | differs |
| `MonitorMixin.extend_object`, `mon_initialize`, `ThreadError` subclasses, `cond.wait(timeout)` | | missing |

## Built-ins needed (requests)

- **`Thread.current`** (a Thread value, `==` to itself) or `Thread.current_id` → Integer: the one thing that
  separates this Monitor from Ruby's. With it `me` goes away, `mon_owned?` works as Ruby's, and a nested
  `synchronize` without identity re-enters instead of hanging.
- `Mutex.lock(m)`, `Mutex.unlock(m)`, `Mutex.try_lock(m)`, `Mutex.locked?(m)`, `Mutex.owned?(m)`: Ruby's Mutex
  has them; `mutex_m` and `try_enter` would use the real thing instead of a hand-over lock.
- `Queue.pop(q, timeout:)` (or `ConditionVariable`): for `cond.wait(timeout)` and `Thread.join(t, limit)`.
- A deadlock should end as a Sake error, not Ruby's `fatal: No live threads left. Deadlock?` with a Ruby
  backtrace (`notes/monitor_bug_deadlock_ruby_fatal.sake`).

## Friction

1. `q, me = Array.shift(@waiters)` → `multiple assignment: argument 1 may be nil (nil | [Queue, :t] | ...) [nil]`,
   although the branch had just tested `Array.empty?`. Wrote `q, me = Array.fetch(@waiters, 0); Array.shift(@waiters)`:
   `fetch` raises instead of returning nil, so its type has no nil. (The hint, "check the value first", would
   have cost a second local and a nil test for a value that cannot be nil there.)
2. `raise ThreadError, "current thread not owner"`: Ruby 3.x/4 says "current fiber not owner"; found by the diff.
3. The design time went into the hand-over lock, not into Sake: with no thread identity and a `synchronize`-only
   Mutex, a lock with `try_enter` and `mon_locked?` has to be written from a Queue per waiter. It was 50 lines
   and passed on the first full run; the typer accepted the blocking-under-Queue shapes without a comment.
4. `--strict=4` (`unrescued`) reports every `raise ThreadError` in the library, since the test's top level does
   not rescue all of them; expected, but it means a library cannot be checked at level 4 on its own.
5. Nothing from threads: a `Thread.new` block inside a function that `yield`s (used in `Timeout`) and a `while`
   loop reading a local that another thread sets both worked as in Ruby.

## Language features used

- Optional trailing parameter before a block: `synchronize(m, me = nil) { }`; passing a block on with `&b`
  from the aliases (`mon_synchronize(m, me = nil, &b) = synchronize(m, me, &b)`).
- A module whose functions read the includer's field (`@mon_data`), as `Observable` does.
- `Mutex.synchronize(@lock) do ... end` returning a value (`try_enter`, `mon_locked?`).
- `ensure` in `synchronize`.

## Types

- `Monitor.owner: Integer | nil | :consumer | :main | :producer | :t` (every identity the program passes),
  `Monitor.waiters: Array[[Queue[true|false], me] ...]`, `MonitorMixin::ConditionVariable.waiters: Array[Queue[true|false]]`.
  All checks proven at `--types`.

## Later the same day (2026-10-09)

Thread.current, Thread.join(t, limit), Mutex.lock/unlock/try_lock/locked?/owned?, Queue.pop(q, timeout) and the exception type ThreadError are built in; a deadlock is reported as a Sake ThreadError. This file still uses its hand-over lock; it could now be a wrapper over the built-in Mutex.
