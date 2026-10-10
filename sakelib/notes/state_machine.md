# state_machine

`sakelib/state_machine.sake`: an AASM-like state machine for Struct types: states with enter/exit
callbacks, events with one or more transitions (from one state or several, guard, after callback),
`fire` / `fire!` / `may_fire_event?` / `permitted_events`, and AASM's `InvalidTransition` message. The
reference is `test/sakelib/ref/state_machine.rb`, a small AASM in plain Ruby. 17 functions; the test
prints 27 lines, identical to `state_machine.rb`, with two machines (a Job with a guard and callbacks,
and a traffic light) driven through the module's dispatch.

## How callbacks are expressed without stored blocks

AASM keeps the blocks of its DSL (`aasm do ... event :run do transitions ... end end`) and calls guards
and callbacks by name with `send` (`guard: :ready?`, `after: :notify`). Sake has neither stored blocks
nor `send`. The design:

- The machine is **data**: `AASM::StateMachine` (the gem's name; `AASMMachine` before 2026-10-10) holds the states, and per event a list of `AASM::Core::Transition` (the gem's name; was `AASMTransition`)
  values whose guard and callbacks are **Symbols**. The model builds it once, in its own required
  function `def aasm(j) = once do ... end` (AASM builds it once per class too).
- The model's type `include AASM` and gives **one function per kind of hook**, receiving the Symbol:
  `def aasm_guard(j, name)` and `def aasm_callback(j, name)`, written with `case name in :ready? then
  @ready end`. This is the `send(name)` of AASM turned into a `case` the checker can see: for `case name
  in :ready?`, the checker knows which Symbols reach it (they are literals in the machine), so the `case`
  needs no `else` at `--strict=2`.
- The module gives **defaults** (`aasm_guard` → true, `aasm_callback` → nil); the includer's own
  definitions win (§5.5), so a machine without guards (the traffic light) defines neither.
- The current state is the includer's field `aasm_state` (AASM's column name), written by the module's
  `fire` with `@aasm_state = ...`.

In Ruby the same model defines `def ready? = @ready` and `def notify`; the reference's defaults are
`aasm_guard(name) = send(name)`.

## API

| Ruby (AASM) | Sake | |
|---|---|---|
| `include AASM; aasm do state :sleeping, initial: true ... end` | `include AASM; def aasm(j) = once do m = AASM::StateMachine.new(:sleeping); ...; m end` | differs (data, not a DSL) |
| `state :running, enter: :start, exit: :stop` | `AASM::StateMachine.state(m, :running, enter: :start, exit: :stop)` | same options |
| `event :run do transitions from: :a, to: :b, guard: :g, after: :f end` | `AASM::StateMachine.event(m, :run, from: :a, to: :b, guard: :g, after: :f)` (once per transition) | same options |
| guard / callback methods called by `send` | `aasm_guard(j, name)`, `aasm_callback(j, name)` with `case name in ...` | differs |
| `job.run!`, `job.run`, `job.may_run?` (generated) | `Job.fire!(j, :run)`, `Job.fire(j, :run)`, `Job.may_fire_event?(j, :run)` (AASM's `aasm.fire!(:run)` ...) | differs: no generated methods |
| `job.sleeping?`, `job.aasm.current_state` | `Job.is?(j, :sleeping)`, `Job.current_state(j)` | differs / same |
| `aasm.states`, `aasm.events`, `aasm.events(permitted: true)` | `states(j)`, `events(j)`, `permitted_events(j)` | same content |
| `AASM::InvalidTransition` (`event_name`, `originating_state`) | `AASM::InvalidTransition` (`event`, `state`), same message | same type name (nested since 2026-10-10; was `AASMInvalidTransition`); the field names differ |
| event-level `before`/`after`/`success`, `after_commit`, `whiny_transitions`, multiple machines per class | | missing |

`AASM.fire!(x, :next)` dispatches to the includer's `fire!` (the test drives a Job and a TrafficLight
through `AASM.current_state(x)` and friends).

## Friction

1. None blocking: `--strict=1` and `--strict=2` passed on the first run of the test.
2. `from: :a` or `from: Array[:a, :b]` → `(from in Symbol) ? Symbol[from] : Symbol[*from]` (Ruby's
   `Array(from)`); `from in Symbol ? ...` without parentheses is a syntax error, as in Ruby.
3. `once` is per place in the program, so each includer's `def aasm = once do ... end` is its own machine:
   exactly AASM's per-class machine. (A machine defined in the module would be one for all types.)

## Language features used

- Mixin with defaults that the includer overrides (`aasm_guard`, `aasm_callback`) and a required function
  (`aasm`, `raise NotImplementedError`): the core of the design; helped.
- `@aasm_state` inside a module function (a field of the includer): helped.
- Keyword parameters (`enter:`, `exit:`, `from:`, `to:`, `guard:`, `after:`): the AASM option names.
- An exception type with fields (`class AASM::InvalidTransition < Exception; attr_reader event, state`):
  `AASM::InvalidTransition.new(msg, event, st)`.
- `once` for the per-type machine; `case name in :sym` exhaustive over literal Symbols.

## Types

- `Job.aasm_state` and `TrafficLight.aasm_state`: `nil | :b | :cleaning | :failed | :green | :red | ...`,
  the union of every machine's states: the module's `fire` writes `AASM::Core::Transition.to(t)`, and
  `AASM::Core::Transition.to` is one field for all machines. Harmless (only compared), but the checker cannot
  tell that a traffic light is never `:sleeping`.
- `AASM::Core::Transition.guard: nil | :ready?`, `AASM::Core::Transition.after: nil | :alert | :notify`,
  `AASM::StateMachine.events: Hash[Symbol => AASM::Core::Transition[]]`. No partial or unknown checks.
