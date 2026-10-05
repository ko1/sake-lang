# event_emitter

`sakelib/event_emitter.sake`: Node's EventEmitter with snake_case names (`on`, `once`, `off`, `emit`,
`prepend_listener`, `remove_all_listeners`, `listener_count`, `listeners`, `event_names`), as the Ruby
event_emitter gems have it. The reference is `test/sakelib/ref/event_emitter.rb`, where a listener is
anything with `call` (a block or an object). 14 functions; the test prints 29 lines, identical to
`event_emitter.rb`.

## The design: listeners are values of types that include Listener

A Ruby listener is a block the emitter keeps. Sake cannot keep a block, so a listener is a **value of
a Struct type that includes the module `Listener`** and defines `call(listener, args)`:

```ruby
class Counter
  attr_accessor count = 0
  include Listener
  def call(c, args) = @count += 1
end
EventEmitter.on(e, :data, Counter.new)
EventEmitter.emit(e, :data, 1, 2)        # Listener.call(counter, [1, 2])
```

- The type is the code; its fields are what a block would have captured (`Printer.prefix`,
  `Recruiter.emitter`, a `Counter`'s running count, which the caller reads afterwards).
- `emit` calls `Listener.call(l, args)`, a mixin function, so it **dispatches** on the listener's type
  (§5.6). The checker verifies that every value that reaches the emitter's list includes `Listener`, and
  a type that includes it without `call` is reported before running.
- `off` finds a listener by `==`, which compares a Struct value's fields; Ruby finds a block by identity.
  `off(e, :tick, Counter.new("a"))` removes one of two equal counters (the most recent, as Node).
- The args reach `call` as one Array: a user function cannot be called with `*args` (§5.8), so
  `emit(e, event, *args)` collects them and passes the Array.

This is the "command object" pattern (Ruby's objects responding to `call`). The other designs
considered: Symbols as listeners with a block at `emit` that dispatches on them (the handling code then
lives at every emit site, not where the listener is added), and one required `handle(emitter, event,
args)` per emitter type (no per-listener state, one handler per type). The test's Ruby side uses Structs
with `call(*args)`; in Ruby a block would also do.

## API

| Node / Ruby | Sake | |
|---|---|---|
| `on(event, &block)`, `add_listener` | `EventEmitter.on(e, event, listener)` | differs: a Listener value, not a block |
| `once`, `prepend_listener`, `prepend_once_listener` | same, with a listener value | differs (same) |
| `off(event, listener)`, `remove_listener` | same | same; found by `==` |
| `emit(event, *args)` → true/false | same | same; an `:error` event without listeners raises RuntimeError `Unhandled error. (...)` |
| `remove_all_listeners(event = nil)`, `listener_count`, `listeners`, `event_names` | same | same |
| `set_max_listeners`, `'newListener'` events, async listeners | | missing |

## Friction

1. None from the checker: `--strict=1` and `--strict=2` passed on the first run.
2. The listener receives `args` as an Array (no `*args` into a user function); the test's `Printer`
   joins them, `Summer` sums the Integers with `a in Integer`.
3. A listener that needs the emitter (the test's `Recruiter`, which adds a listener while an event is
   emitted) holds it in a field: there is no closure.

## Language features used

- Mixin dispatch over includers (`Listener.call`) with a required function: the whole design; helped.
- `*args` in `emit(e, event, *args)`: helped; calls read as Node's.
- Optional parameter `event = nil` in `remove_all_listeners`.
- `private attr_reader handlers = Hash[]`: the listener table, with `[listener, once?]` Tuples.

## Types

- `EventEmitter.handlers: Hash[Symbol => Array[[Counter | Printer | Recruiter | Summer, true|false]]]`:
  the union of the listener types, all of which include `Listener`, so `Listener.call` is proven for each.
  No partial or unknown checks.
