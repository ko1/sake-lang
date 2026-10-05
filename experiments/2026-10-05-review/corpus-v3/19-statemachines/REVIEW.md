# Review: 19-statemachines (corpus-v3, 2026-10-05)

All 25 programs run with `bin/sake --strict=0`: exit 0, stdout identical to `NAME.out`.
22 changed, 3 unchanged. (The `.rb` files here are dangling symlinks to `../../corpus/...`; the Ruby
versions were read from `experiments/2026-10-01-inference-500/corpus/19-statemachines/`.)

- bank_queue_sim: class + attr: `Heap` (`attr_reader items = nil` + `initialize` makes the Array, `Heap.new`), `Lcg` (one `class` in place of `Struct.new` + `class`); index-target multiple assignment `@items[a], @items[b] = @items[b], @items[a]` in place of the `tmp` swaps (x2). `while true` stays (no `loop`).
- bracket_checker: class + attr_reader: `Frame`, `Problem` (was `Struct.new`).
- button_debounce: class + attr_reader: `Edge`, `Gesture`; `Debouncer`'s `edges` made by `initialize`, so `Debouncer.new(threshold)` as in Ruby (was `Debouncer.new(threshold, Array[])`).
- circuit_breaker: exception classes: `ServiceError`, `CircuitOpen` (`class < StandardError` + `attr_reader`); class + attr defaults + `initialize`: `Breaker.new(3, 6)` replaces the `Breaker.create` factory, `Service.new(outcomes)` (`calls = 0`); unused `=> e` dropped in `rescue ServiceError` as in Ruby.
- csv_parser: exception class `CsvError`; `Array[header] + good` (Array concatenation) replaces `Array[header]` + `Array.concat`.
- dfa_minimize: class + attr_reader `Dfa`; `if !Set.include?` -> `unless` (as Ruby).
- divisibility_dfa: class + attr_reader `Dfa` (one `class`; `divisible_by`/`product` stay module-style functions of the class). `to_base` stays.
- elevator: class + attr defaults + `initialize`: `Elevator.new` replaces `Elevator.idle`; class + attr_reader `Call`; nested block destructuring `|who, (at, floor)|` replaces `at, floor = req`.
- enemy_ai: class + attr defaults: `Enemy.new(name, pos, patrol)` replaces the `Enemy.spawn` factory (fields reordered so the defaulted ones come last); `@pos += d` (field compound assignment) for `@pos = @pos + d`; `|(px, py), t|` block destructuring.
- event_sourcing: class + attr_reader for the five events, `class Account` with `attr_accessor` (merges `Struct.new` + `class`); exception class `Rejected`.
- expr_lexer: class + attr_reader `Token`, exception class `LexError`; `once` for `two_char_ops`.
- http_parser: class + attr defaults + `initialize`: `Request.new` / `HttpParser.new` replace `HttpParser.start` and the `Request.new("", "", "", Hash[], "")` repeated twice; exception class `HttpError`; `progress = step(hp) while progress` (modifier, as Ruby).
- job_pipeline: class + attr_accessor defaults: `Job.new(name, deps, dur, fails, retries)` replaces `Job.define`; exception class `CycleError`; `path + Array[name]` replaces `Array.push(Array.dup(path), name)`.
- keypad_lock: unchanged
- machine_mixin: class + attr defaults + `initialize` for `Door`/`Light`/`Ticket` (`Door.new("front")`, fields read-only as in Ruby); in the mixin, `@state = target` and `Array.push(@log, ...)` (field shorthand inside an included module function) replace `set_state(m, ...)`/`get_log(m)` — Ruby writes `@state = target` there too.
- markdown_blocks: class + attr defaults + `initialize`: `Renderer.new` replaces `Renderer.fresh`.
- morse_decoder: `once` for `morse_table` (was rebuilt on every call, including inside the per-letter loop); `letter || "?"` as Ruby.
- order_workflow: class + attr_reader `LineItem`; `Order` with defaults + `initialize` (`Order.new(id, items)`); exception class `WorkflowError`; `once` for `allowed`, with `pending:` labels as Ruby's literal.
- regex_nfa: class + attr: `NState` (`attr_accessor ... out1 = nil, out2 = nil`, so `NState.new(kind, ch)`), `Frag`, `Nfa`; exception class `RegexSyntaxError`; `holes + holes` / `holes + Array[[s, 2]]` (Array `+`) replace `Array.concat` / an in-place `Array.push`; two `while`/`if` blocks as modifiers, as Ruby.
- shell_words: class + attr_reader `Word`; exception class `ShellSyntaxError`.
- smtp_session: class + attr_reader `Message`; `Session` with defaults + `initialize` calling `reset(s)` (as Ruby's), `Session.new` replaces `Session.fresh`; `once` for `local_domains`.
- tcp_states: exception class `InvalidTransition`; `Conn` with defaults + `initialize` (`@history = Array[@state]`), `Conn.new(name)` replaces `Conn.open`; `once` for `transitions` (it was rebuilt per `fire` and per BFS step); nested block destructuring `|(from, _ev), (to, _reply)|` (x2) as Ruby.
- traffic_light: class + attr_reader `Phase`; `Controller` with defaults + `initialize`, `Controller.new`; `once` for `phases` (rebuilt on every `current` call), `ns_green:` labels.
- turnstile: class + attr defaults, `Turnstile.new` replaces `Turnstile.fresh`. The nested `case @state` / `if event` stays.
- vending_machine: exception class `VendError`; `Machine` with defaults + `initialize` (`Machine.new(products)` replaces `Machine.build`); `once` for `accepted_coins`. `Product` stays `Struct.new` (Ruby: `attr_accessor`, written from outside).

## Friction

- **A field whose initial value is a new collection or object.** Ruby's `initialize` sets
  `@log = []`, `@coins = Hash.new(0)`, `@paid = Money.new(0)`. A default must be a literal, so I
  wrote `log = nil` in the `attr_*` line and the real value in `initialize` (15 classes, e.g.
  circuit_breaker.sake:20-21, smtp_session.sake:8-12, order_workflow.sake:32-36,
  vending_machine.sake:9-14). Side effect: each such field becomes a trailing optional argument of
  `new`, so `Machine.new(products, :broken)` is accepted although the Ruby constructor takes only
  `products`. There is no way to declare a field that `new` does not take.
- **Field order is constructor order.** Ruby's `Enemy#initialize(name, pos, patrol)` sets `hp` and
  `state` between `pos` and `patrol`; to get `Enemy.new(name, pos, patrol)` the fields had to be
  reordered (enemy_ai.sake:12), which changes the `p` output order (not printed here). Same in
  circuit_breaker.sake:20 (`threshold, cooldown` first).
- **Compound assignment on another object's field.** `acct.balance += x`, `t.served += 1`,
  `product.stock -= 1`, `@request.body += piece` → `Account.set_balance(acct, Account.get_balance(acct) + x)`
  (event_sourcing.sake:49-61, bank_queue_sim.sake:78/87, vending_machine.sake:55,
  http_parser.sake:77/90, job_pipeline.sake:49). `@x += v` only works on the subject.
- **Array patterns** are still rejected: turnstile's `case [@state, event] in [:locked, :coin]`
  stays a `case @state` with `if event == :coin` inside (turnstile.sake:5-25).
- **No `loop`**: `loop do ... break ... end` stays `while true` (bank_queue_sim.sake:34,
  job_pipeline.sake:34).
- **`[a, b].max` / `.min`**: no `Tuple.max`, no `Integer.max`; `Array.min(Array[@hp + 15, 100])`
  (enemy_ai.sake:80) and an `if` (csv_parser.sake:97).
- **`Integer#to_s(base)`** still takes no base: hand-written `to_base` and `digit_chars`
  (divisibility_dfa.sake:1-12).
- **`dup` of a Struct value**: Ruby's `transform_values(&:dup)` → a hand-written `Account.copy`
  listing every field (event_sourcing.sake:30).
- **`once` with a multi-line table** reads as `def allowed = once do ... end` (order_workflow.sake:19,
  morse_decoder.sake:1, tcp_states.sake:5, traffic_light.sake:5); it works, but it is one more wrapper
  than Ruby's `ALLOWED = {...}`, and every use is a call (`allowed[@state]`).

## Ruby comparison

- Every method takes its subject as an explicit first parameter (`def press(k, now, key)`,
  keypad_lock.sake:3), and every call names the class (`Keypad.press(pad, now, key)`); a Ruby
  reader notices this first, more than the `get_`/`set_` accessors.
- Field access from outside is `Order.get_state(o)` rather than `o.state`; reads of another
  object's fields inside a method are `Event.get_time(b)` (bank_queue_sim.sake:5) where Ruby says
  `other.time`.
- Constructors: `attr_* x = default` lines replace the assignments in Ruby's `initialize`, and
  `initialize(c)` only holds what a literal cannot express. The factory functions (`create`,
  `fresh`, `start`, `build`, `spawn`, `define`, `open`, `idle`) of the previous version are gone;
  every type is now made with `T.new` as in Ruby.
- Exceptions are `class E < StandardError` with `attr_reader` and no `initialize`/`super`; the
  message is the implicit first field, so `E.new(msg, field)` is called exactly as in Ruby.
- Constant tables are `def name = once { ... }` functions (5 programs); Ruby's `CONST.include?`
  becomes `Array.include?(name, x)`.
- The mixin (machine_mixin.sake) now writes `@state = target` like Ruby, but still reads through
  `get_state(m)` where Ruby calls the reader `state`.
