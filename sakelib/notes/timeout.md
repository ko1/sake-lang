# timeout

`sakelib/timeout.sake`: `Timeout.timeout(sec, klass = nil, message = nil) { }` and the exception type
`TimeoutError` (Ruby's `Timeout::Error`). 1 function. The test prints 14 lines, identical to `timeout.rb`
(times are checked with generous margins and printed as pass/fail).

## The gap: Sake cannot interrupt a block

Ruby's `timeout` runs the block in the calling thread and has a watcher thread `Thread#raise` into it when the
time is up: the block stops where it is. Sake has no `Thread.raise`, `Thread.kill`, or `Thread.join(t, limit)`.
The port runs **the block in a Thread of its own** and polls `Thread.alive?` (sleeping ≤ 5 ms between polls)
until the deadline:

- finished in time: `Thread.value` gives the block's value, or raises the exception the block raised, as itself
  (`rescue RuntimeError`, `ArgumentError` around the call work as in Ruby);
- not finished: `TimeoutError` ("execution expired", or `message`) is raised in the caller, and **the block
  keeps running** in its thread until it ends by itself or the program ends. Its side effects after the
  deadline still happen (Ruby's would not), and a block that never ends keeps a thread busy. The test does not
  print anything that depends on this (it would differ from Ruby by design).

Because the block runs in a thread: `break` and `return` out of it are errors (`LocalJumpError`, spec §15
Threads), and the locals of the *blocks* around the call are copies, while the enclosing function's locals
are shared (`collect(n)` in the test fills an Array of the function). `sec` nil or 0 runs the block in the
calling thread, as Ruby.

## API

| Ruby | Sake | |
|---|---|---|
| `Timeout.timeout(sec) { }` | same | differs: the block is not interrupted (above); the caller returns at the deadline |
| `Timeout.timeout(sec, klass) { }` | `klass` accepted as nil only | missing: an exception type is not a value, so one cannot be passed to raise; `ArgumentError` otherwise |
| `Timeout.timeout(sec, nil, message) { }` | same | same |
| `Timeout.timeout(nil) { }`, `(0) { }` | same | same: no limit |
| negative `sec` | `ArgumentError "Timeout sec must be a non-negative number"` | same |
| `Timeout::Error` | `TimeoutError` | differs: no nested names |
| `Timeout::ExitException`, `Timeout.timeout` inside `Timeout.timeout` cancelling the outer | inner raises first, outer thread keeps waiting on the inner's thread | partial |

## Built-ins needed (requests)

- **`Thread.raise(t, exception)`** or **`Thread.kill(t)`**: to stop the block, which is the whole point of
  `timeout`; without it the port is "give up waiting", not "stop".
- `Thread.join(t, limit)` → t or nil (Ruby's): would replace the `alive?`/`sleep` polling loop with one
  blocking call and remove the ≤ 5 ms latency.
- A way to run a block in the calling thread with interruption, which is what Ruby's `timeout` really does;
  with `Thread.raise` and `Thread.current` it can be written in Sake exactly as Ruby's.

## Friction

1. `Integer("x")` inside the block: Ruby's message is `invalid value for Integer(): "x"`, Sake's is
   `Kernel.Integer: invalid value for Integer(): "x"` (the operation's name is prefixed). The test raises its own
   `ArgumentError` instead. Not a port problem, but a message that differs in every test that prints a built-in's error.
2. `yield` inside `Thread.new { yield }` in a module function: worked the first time; the thread's block carries the
   function's block.
3. `--types` lists each `raise` in the library under `unrescued` (level 4): expected for a library.
4. `sleep(remaining < 0.005 ? remaining : 0.005)`: there is no `Float.min(a, b)`; `Tuple.min([a, b])` would do, the
   ternary reads better. `Comparable.clamp` exists but needs both bounds.

## Later the same day (2026-10-09)

Thread.join(t, limit) is built in (it would replace the polling loop). Thread.raise/kill are still missing.
