# observer

`sakelib/observer.sake`: Ruby's Observable as two modules, `Observable` (included by the subject) and
`Observer` (included by every observer type, which defines `update(obs, *args)`). 9 functions (8 of Ruby's,
plus the list accessor `observer_peers_list`). The test prints 24 lines, identical to `observer.rb`.

## The design: a dispatch module for the observers, fields in the subject

Ruby's `notify_observers(*args)` calls `observer.send(func, *args)`, with `func` the method name given to
`add_observer` (default `:update`). Sake has no dispatch by name and no callables, so:

- An observer is a value of a type that includes `Observer` and defines `update(obs, *args)`. The module's
  `update` is a required function (`raise NotImplementedError`), and `Observer.update(obs, *args)` in
  `notify_observers` dispatches on the observer's type (spec §5.6). The checker proves at `--strict` that every
  value that reaches the list has an `update`, and that the arguments fit each observer's `update`: the
  first version of the test called `notify_observers(t)` with no arguments while a `Warner` read `args[1] > limit`,
  and the checker reported it before running (Ruby's program crashed at run time with `NoMethodError`
  for `nil > 100`).
- The subject keeps the list where Ruby keeps it, in its own instance: it declares
  `private attr_accessor observer_peers, observer_state` and includes `Observable`. The module's functions
  read `@observer_peers` of the including type (spec §5.5). A type that forgets the fields gets a static error at
  `include Observable`. The fields may stay nil after `initialize`; the functions create the list on first use,
  as Ruby does (`@observer_peers ||= {}`).
- Observers are found by `==`, which compares a Struct value's fields; Ruby uses the observer's hash/identity.
  Two equal observers collapse into one (also in Ruby when the observers are Structs), and a mutable observer stays
  findable in Sake after it changed (in Ruby a Struct observer that changed its fields becomes unfindable in
  `@observer_peers`, which happened in the first draft of the Ruby test). The test uses plain classes on the Ruby side,
  where the two agree.

## API

| Ruby | Sake | |
|---|---|---|
| `add_observer(obs, func = :update)` | `Observable.add_observer(o, obs)` | differs: no `func`; the observer's type defines `update`. Returns the list (Ruby: the Hash) |
| `delete_observer(obs)` | `Observable.delete_observer(o, obs)` | same; by `==`; returns the removed observer or nil (Ruby: `func`) |
| `delete_observers` · `count_observers` | same | same |
| `changed(state = true)` · `changed?` | same | same |
| `notify_observers(*args)` | `Observable.notify_observers(o, *args)` | same: calls `Observer.update(obs, *args)` of each, then clears `changed`; returns nil |
| `observer.update(*args)` | `def update(obs, *args)` in a type that `include Observer` | differs: the observer type must include the module |
| `@observer_peers`, `@observer_state` | `private attr_accessor observer_peers, observer_state` in the subject | differs: declared by the including type |

Missing: the `func` argument of `add_observer` (dispatch by method name).

## Built-ins needed

None.

## Friction

1. `name, price = args` then `price > @limit` in an observer: `Comparable.>: the operands are (nil, Integer),
   (String, Integer) ... [type]`, with the hint naming the call chain through `notify_observers`. The Array
   `args` has one element type, the union of everything any `notify_observers` passes, and destructuring keeps
   that union for each position. Wrote `price = args[1]; if price in Integer ... end` instead. The report was
   right (a no-argument notify reached that observer), but even after fixing the test the union stays, so
   every observer picks its arguments with a pattern. A Tuple would keep positions, but `*args` collects an Array.
2. `return unless price in Integer` does not narrow (the narrowing forms in §11 are for nil); `if price in Integer`
   does.
3. None from `include`: the module's functions found the including type's `@observer_peers` as written.

## Language features used

- Two modules: `Observable` borrowed into the subject (its functions read the subject's fields),
  `Observer` as a dispatch module with a required function (`Observer.update`).
- Splat into a user function's `*rest` (`Observer.update(obs, *args)`): fine, since 2026-10-05.
- `@observer_peers || (@observer_peers = Array[])` for Ruby's lazy `||=` on a field that may be nil.

## Types

- `Ticker.observer_peers: nil | Array[Bell | Recorder | Warner]`, `Ticker.observer_state: true|false | nil`;
  `--types` reports all checks proven.
