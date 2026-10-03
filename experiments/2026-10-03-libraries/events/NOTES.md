# events: an event bus and a state machine in Sake

Files: `lib.sake` (library), `client_turnstile.sake` (typical), `client_tokenizer.sake` (unusual:
an Fsm as a lexer), `client_orders.sake` (workflow: handlers that drive machines that publish
events), `client_stress.sake` (200 self-removing handlers, a 2000-step chain of queued events, two
hook types on one bus). `./build.sh` writes `out/<client>.sake`; `out/<client>.txt` is the output of
`bin/sake --strict out/<client>.sake`. All four run clean at level 2 (and at level 3, except one
`index-nil` in client_orders).

## API sketch

```ruby
module Handler                 # the "callback" interface for the bus
  def handle(h, bus, ev) = raise(NotImplementedError)   # ev is [name Symbol, data]
end
Recorder.create / Recorder.names(r)               # a ready-made Handler that stores events
Bus.create
Bus.on(bus, pattern, handler) -> id               # pattern :* = every event
Bus.off(bus, id) -> count removed
Bus.publish(bus, name, data) -> deliveries        # events published by handlers are queued
Bus.subscribers(bus, name)

module Hooks                   # the "callbacks" of a machine; every one has a default
  guard?(hk, guard_name, fsm, data) = true;  act(hk, action_name, fsm, data) = nil
  enter(hk, state, fsm, data); leave(hk, state, fsm, data); rejected(hk, event, fsm, data)
end
NoHooks                                            # a Hooks that does nothing
Fsm.create(name, initial, hooks) / Fsm.plain(name, initial)
Fsm.allow(fsm, from, event, to, guard, action)     # from :* = any; to :* = stay; :none = no guard/action
Fsm.fire(fsm, event, data) -> new state or nil
Fsm.attach(fsm, bus)          # publish :fsm_moved / :fsm_rejected Records on the bus
Fsm.events_from(fsm, state)
```

**What replaced callbacks.** Two things together:

1. **A handler is a value of a Struct type that includes a library module** (`Handler`, `Hooks`).
   The library stores the value and calls `Handler.handle(h, ...)`, which dispatches on h's type.
   This is the Java "listener object" pattern, not Ruby's block. The handler's state (an audit log,
   a credit counter) lives in its fields instead of in captured locals.
2. **Guards and actions are named by Symbols** in the transition table (`:paid`, `:take_coin`), and
   the hooks type maps names to code with `case name in :paid then ...`. That is a `send`-free
   version of Ruby's `guard: :paid?` option.

## Friction log

- [language-limit] First instinct: `Bus.on(bus, :coin) { |ev| ... }` storing the block, i.e.
  `def on(subs, name, &blk)` (kept in `ruby_habit_store_block.sake`) → `block parameter `&blk` is
  not supported; use `yield``, plus two cascade errors (`wrong number of arguments for on (given 2,
  expected 0)`, `on does not take a block`) → partly: "use yield" is the wrong advice for a block
  that must be kept for later; nothing points at the module-dispatch pattern → designed `Handler`
  + `Handler.handle` dispatch instead → 1 attempt (I knew the answer from the tutorial §8).
- [missing-builtin] `Array[]` of Symbols written as `Symbol[]` (Fsm history) → `undefined function
  `Symbol.new[]`` followed by a 20-item hint listing `Integer.new[]`, `RuntimeError.new[]`, ... →
  partly: the spec does list which `T[]` exist, but the message names a function nobody wrote
  (`new[]`) → `Array[]` → 1. Repro: `bug_symbol_typed_array.sake`.
- [type-check-false-report] Queue loop `while Array.size(@queue) > 0; ev = Array.shift(@queue);
  ev_name, _ = ev` → `multiple assignment: argument 1 may be nil (nil | [:fsm_moved, {event: :coin,
  from: :locked, machine: String, to: :locked} | ... 12 Record variants ...]) [nil]`, reported twice
  (in the lib and again in a client handler) → yes, the hint says what to do; the size test cannot
  imply that `shift` is non-nil, fair enough → see next entry → 3 attempts.
- [type-check-false-report] `while (ev = Array.shift(@queue))` → same `may be nil` report: an
  assignment in a `while` condition does not narrow the variable (spec §11 only lists `while x`) →
  no → `while true; ev = Array.shift(@queue); break unless ev` → 1. Repro:
  `bug_while_assign_narrow.sake`.
- [message] The nil report above printed the type of the queue element as a union of 12 Records
  (each Symbol literal in `{from:, to:, event:}` makes its own Record type), ~900 characters on one
  line. The useful part was "nil |" at the start.
- [type-check-false-report] client_tokenizer uses only the Fsm, not the Bus →
  `Handler.handle is a mixin function, and no type includes Handler` *inside the library* (and the
  same for 5 `Hooks.*` calls in a scratch client with no hooks type) → partly: the hint
  (`module_function`) is wrong for an interface module → the library ships a type that includes
  each module (`Recorder`, `NoHooks`), which turned out useful anyway → 1. Repro:
  `bug_unused_mixin_dispatch.sake`. This is the cost of "a program is one file": unused library
  code must still type-check against the client.
- [type-check-false-report] Order handler `Stock` subscribes to `:placed` only, so its `case name
  in :placed` has no other branch → `case/in: no `in` branch matches :fsm_moved | :fsm_rejected |
  :reserved | :short [type]` → yes (the message is clear) → `else nil` with a comment, in every
  handler that handles a subset of events (4 handlers) → 1. The checker sees every event reach every
  handler, because subscriptions are run-time data. In Ruby the subscription itself selects the
  code, so no such branch exists.
- [type-check-false-report] stress: two machines with different hooks types; `Parity.get_flips(
  Fsm.get_hooks(parity))` → `Parity.get_flips: argument 1 must be Parity, but can be Light [type]`
  → yes → keep the Parity value in a local instead of reading it back from the Fsm → 1. A field's
  type is the union over all instances, so a generic container gives back a union. Repro:
  `bug_field_union_across_instances.sake` (a limit, not a bug).
- [language-limit] `Bus.off(bus, handler)` removed by `h == handler`. Struct `==` compares
  contents and there is no `equal?`/`object_id`, so two empty `Recorder`s were both removed (found
  by a test, not by the checker) → `on` now returns an Integer id and `off` takes the id; a
  self-removing handler stores its id in a field (`Once.subscribe`) → 1. Repro:
  `limit_no_identity.sake`.
- [ruby-habit] `src.inspect` → `method call on a value ... hint: Kernel.inspect(src)` → yes → 1.
- [bug in my lib, not caught] Unsubscribing during delivery (`Array.each(@subs)` while a handler
  runs `Array.delete_if(@subs)`) skipped other subscribers: the 2000-step tick chain stopped after 2.
  Same as Ruby; fixed by iterating `Array.dup(@subs)`. And `to = :*` meant "stay" to me but the lib
  set the state to `:*`; now it is a documented feature.
- [message] Wrong arity in a handler (`def handle(al, ev)`) → `Handler.handle dispatches to
  Alarm.handle, whose arguments or block differ from Handler.handle` at the library's call line →
  partly: it does not say 2 vs 3 or point at the client's `def`.
- [type-check-gap] A block whose parameter count differs from `yield`'s argument count
  (`yield` with no argument, block `|e|`) is an `ArgumentError` at run time even at `--strict=4`,
  although the tutorial says each yield's block is known statically. Repro:
  `bug_yield_arity_runtime_only.sake`. (Not on my main path; found while trying the Ruby habit.)
- [tooling] Concatenation: error lines are in `out/X.sake`; build.sh prints where the client
  starts (line 134 now; it moved from 112 to 121 to 131 to 134 as the lib grew) and I subtracted by hand. Name clashes between lib and client are reported
  clearly (`Recorder is already defined`), and a client can reopen a lib class to add functions.
  Every change to `lib.sake` shifts the offset, so line numbers in my log went stale.

## What felt good

- **A typo in a guard name is caught before running.** Changing `:paid` to `:payd` in one
  `Fsm.allow` row gives `case/in: no `in` branch matches :payd [type]`, pointing at the hooks'
  `case`. Swapping the guard and action columns is caught the same way (`:take_coin` reaches
  `guard?`). In Ruby, `guard: :payd?` is a `NoMethodError` (or a silently false guard) when that
  transition is first tried. This was the best moment: Symbol literals are tracked as values across
  the table, the library, and the dispatch.
- Subscribing a value that is not a handler (`Bus.on(bus, :x, turnstile)`) is reported:
  `Handler.handle dispatches on its first argument, which can be Turnstile; the types that include
  Handler are Recorder, Audit, Alarm`. Forgetting `include Handler` is caught too.
- Default hooks are just module functions the includer may override. "Only define the callbacks
  you need" came for free, like Ruby's optional callbacks.
- `{reader: [...]}` for everything: I first wrote `accessor:` for counters out of habit, then turned
  every type to `reader:` only and all four programs still ran. Every state change goes through a
  function inside the class (`@credit += data`), so `accessor` was never needed.
- client_orders ran clean at level 2 on the first try, including handlers that fire machines that
  publish back onto the bus.

## What felt bad (top 3)

1. **The checker does not know which handler gets which event.** Subscriptions are data, so every
   handler is typed as receiving every event: an `else nil` in each partial handler (4 places), and
   the payload is a union of every event's data, which I take apart with `data => {id:}` under the
   tag. In Ruby the block for `:placed` only ever sees `:placed`. Cost: ~8 lines, and the feeling
   that the types describe the bus, not my program.
2. **Library code is checked against each client, including the parts the client does not use.**
   The two "no type includes ..." errors forced two helper types into the library (`Recorder`,
   `NoHooks`, ~12 lines) before a bus-less client could run. Plus manual line-offset arithmetic
   for every message.
3. **No identity, no generics.** `off` by handler value was wrong (content equality), so the API
   grew subscription ids and the handler had to store its own id (~8 lines, one design change).
   `Fsm.get_hooks` gives back a union of all hook types in the program, so clients keep their own
   reference.

Smaller: the nil-in-a-queue loop (3 tries), and level-2/`-c` checking takes 1.4–1.7 s on the two
larger programs (0.24 s at level 0); the stress run itself takes ~1.8 s for 13k deliveries.

## Library design under Sake

- **Ruby version** would be `bus.on(:placed) { |data| ... }`, `fsm.on_enter(:paid) { ... }`,
  `transition from: :new, to: :paid, on: :pay, if: -> { paid? }`. Handlers are closures, so they
  capture local state, can be registered per event, and need no type.
- **Sake version**: a handler is a named Struct type including `Handler`; the state a closure would
  capture becomes fields (`Audit.lines`, `Canceller.orders`); a guard/action is a Symbol, resolved
  by a `case` in one hooks type. One `handle` per type, so the per-event split is a `case name`
  inside it rather than one block per subscription.
- **What I could not offer**: anonymous one-off handlers (`bus.on(:x) { puts it }` needs a new
  type of ~5 lines); per-subscription filtering that the checker understands; removing a handler
  by identity; a typed container for "the hooks of *this* machine".
- **What I offered differently, and liked**: transitions as a plain table of Symbol Tuples, which
  makes `Fsm.events_from` and the audit trail trivial and lets the checker see every guard/action
  name; default hook implementations via a mixin module; a queue instead of nested publish (Ruby
  would allow re-entrant publish by accident).
- Overall the Sake design is closer to Java listeners + a `switch` on enum names than to Ruby. It
  costs more lines for small handlers and less debugging for wrong names.

## Numbers

- Lines: lib 132; clients 62 (turnstile) + 61 (tokenizer) + 132 (orders) + 111 (stress) = 366.
- Static errors before each program ran clean (level 2):

  | Program | Mine | False reports | Rounds |
  |---|---|---|---|
  | turnstile (first, also shook out the lib) | 1 (`Symbol[]`) | 4 (2 nil reports × 2 rounds: shift, while-assign) | 4 |
  | orders | 0 | 1 (handler `case` without `else`; I removed the `else` to see) | 1 |
  | tokenizer | 1 (`src.inspect`) | 1 (no type includes Handler) | 2 |
  | stress | 0 | 1 (hooks field is a union) | 2 |

  Plus 5 `no type includes Hooks` in a scratch program, and 2 library logic bugs found by the
  stress run (not by the checker), plus 1 found by a test (`off` by `==`).
- Level-2 reports I could not remove: none. `--strict=3` leaves one `index-nil` in client_orders
  (`need[sku]` from `Array.tally`), which I left at level 2 as the brief asks.
- `--types` on client_orders: proven=109 partial=1 unknown=2; the unknowns are the Record patterns
  in the Mailer handler (`data => {machine:, to:}` under `in :fsm_moved`). It also lists
  `Handler.handle` and the `Hooks.*` defaults as "dead functions", which reads oddly for an interface.

## Suggestions

1. **When `&blk`/`proc`/`->` is rejected, point at the replacement for a stored callback**: e.g.
   "blocks cannot be stored; for a callback, define a type that includes a module and call
   `M.f(x)`", and drop the cascade errors at the call site. (friction: storing a block)
2. **Do not report "no type includes M" for a dispatch that no call reaches** (or make it a
   warning). A library with an interface module cannot be used by a program that does not
   implement the interface. (friction: unused mixin dispatch)
3. **Narrow `x` in `while (x = expr)` / `if (x = expr)`**, the Ruby idiom for draining a queue.
   (friction: while-assign)
4. **Shorten long union types in messages**: show `nil | [Symbol, Record]` or the first 2 variants
   and "+10 more". (friction: 900-character nil report)
5. **A way to say "this handler only gets these events"**: e.g. let `case` in a dispatched
   function be checked against the event names reaching it through `Bus.on(bus, :placed, h)`, or
   (simpler) a level-3 `exhaustive`-style item instead of a `type` error when the unmatched values
   are Symbols flowing through a data structure. Also an identity test (`Kernel.equal?`) for
   values kept in lists. (friction: partial handlers, `off` by `==`)
