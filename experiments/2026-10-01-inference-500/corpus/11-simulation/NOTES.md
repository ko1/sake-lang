# Notes for 11-simulation

## elevator_scan
- Tuple sort keys are not comparable: `Array.min_by(cars) { |c| [cost, id] }` fails with
  "ArgumentError: Array.min_by: cannot compare elements of types Car" (the message names the element
  type, not the key type: misleading). Repro: `p(Array.sort_by(Array[3, 1, 2]) { |x| [x, "k"] })` ->
  "Array.sort_by: cannot compare elements of types Integer". Workaround: key on cost only (min_by keeps
  the first minimum, so the result is the same); Ruby keeps `[cost, id]`.
- `Set.select` returns an Array (as in Ruby), although spec.md §15 Set table says "a new Set".
  Set has no `min_by`; used `Array.min_by(Set.to_a(s))`.
- Ruby uses `partition` to split riders/pending; Sake uses `select` + `delete_if` with the same predicate.
## teller_queue_des
- No `case/when`: Ruby's `case ev.kind when :arrive` became `case ... in :arrive`. Ruby's
  `while (ev = events.pop)` became a pop before the loop and at its end. Ruby's `loop do ... break`
  became `while true ... break` (no `break` in blocks).
## traffic_intersection
- No value constants: Ruby's `OPPOSITE = {north: :south, ...}` became a nested ternary at the use
  site (a Hash-returning function would also do). Ruby's `filter_map` with a modifier-if body was
  written as `each` + `push` (Sake has `filter_map` too, but `[a, b] if c` gives nil-or-Tuple; kept it simple).
## life_torus
- Same Tuple-key limitation: Ruby's `sort_by { |name, n| [-n, name] }` became a String key
  `format("%06d %s", 100000 - n, name)`. (No unary minus either: `0 - n`.)
## vending_machine
- Record events dispatched with `case event in {insert: coin} ... in {cancel:}` work as in Ruby.
  (Ruby pitfall, not a Sake one: in the Ruby version `in { cancel: } then cancel` binds a local
  `cancel` that shadows the method; Ruby uses `{ cancel: _ }`. Sake's `cancel(m)` is always a call.)
- Ruby's `ACCEPTED = [...]` constant is an inline `Array[5, 10, 25, 100]` in Sake.
## parking_garage
- Ruby's lookup constants `SIZE_RANK = {compact: 1, ...}` / `NEEDED_SIZE` became functions with
  `case ... in :compact then 1` (no value constants).
- Ruby's `min_by { |s| [rank, level, number] }` became an Integer composite key
  `rank * 1000 + level * 100 + number` (Tuples are not comparable).
## epidemic_network
- `Hash.new { |h, k| h[k] = [] }` is not available (blocks are not values); Sake checks
  `graph[a] == nil` and stores `String[]` first.
- Ruby `sort_by { [-deg, name] }` -> String key `format("%03d %s", 100 - deg, name)`.
## cpu_scheduler
- Policies are Struct types including a `Scheduler` module; `Scheduler.report(policy, specs)`
  dispatches on the policy's type (Ruby: `policy.report(specs)`). Fieldless policy types are
  written `class Fcfs < {reader: []}`, `Fcfs.new`.
- Block params cannot destructure nested (`|(name, w), i|`); used `|pair, i|` + `name, w = pair`.
- Ruby `current.first_run ||= clock` on a field became an explicit nil check + setter.
- Tuple min_by keys -> `remaining * 100 + arrival`.
## thermostat_house
- Ruby's constant tables `OUTDOOR` (Array) and `SCHEDULE` (Array of Hashes) became data built inside
  `outdoor(hour)` / `setpoint(room, hour)` on every call (no value constants), so Sake rebuilds them
  ~600 times; run time ~1.1 s user. Schedule entries are Records, read with
  `entry => {rooms:, hours:}` inside the `find` block (Ruby: `entry[:rooms]`).
## forest_fire
- `Array.new(h) { Array.new(w) { ... } }` is not available (`Array.new` unsupported); built with
  nested `Integer.times` + `Array.push`. Ruby's `initialize` that fills the grid became a factory
  `Forest.create(...)` that calls `Forest.new` and then fills `get_cells(f)` (inside `create`, `@cells`
  would refer to the first parameter, an Integer).
- `GLYPHS`/`NEIGHBORS` constants: a `glyph(c)` function with `case/in`, and an inline Tuple Array.
- Wrote `puts(Array.join(Array.map(row) do |c| ... end, ""))` first; replaced it with a helper to
  avoid do/end binding ambiguity (not tested whether Sake handles it).
- ~2 s user time (grid scans in `count` each step).
## checkout_lanes
- Customers are Records `{id:, arrive:, items:}` read with `c => {items:}` (also inline inside a
  block: `{ |c| c => {items:}; service_time(l, items) }`). Ruby uses Hashes and `c[:items]`.
- `Array.inspect` does not exist; `Kernel.inspect(balked)`.
- Ruby block param `|id, (lane, wait, done)|` -> `|id, info|` + `lane, wait, done = info`.
## langton_ants
- `DX`/`DY` constants became `def dx(dir) = Integer[0, 1, 0, -1][dir]` (rebuilt per call).
- `Array.uniq` on an Array of Tuples works (Tuple equality is used there, though `==` on Tuples
  is documented as undefined).
- Highway run is 10200 steps (~2.5 s in Sake); 11000 was ~3 s.
## car_rental
- `CLASSES` constant Hash of CarClass values became `def classes` returning a fresh Hash each call;
  comparisons still work because CarClass `<=>` compares ranks (via `include Comparable`).
## runway_ops
- Ruby's `<=>` via `[urgency, scheduled, callsign] <=> [...]` (Array comparison) became a chained
  comparison of the three fields. Ruby's `waiting -= out` became `Array.delete_if` + `Array.include?`
  (no `-` operator on Arrays in Sake).
## bakery_shift
- `retry` inside a `begin/rescue` nested in an `Array.each` block, and `next` inside the rescue
  clause, behave as in Ruby. `Array.delete(deliveries, tuple)` works with a Tuple argument.
- `RECIPES` constant -> `def recipes` (rebuilt per order).
## sandpile
- `Array.new(n) { Array.new(n, 0) }` -> `Pile.create(n)` with nested `Integer.times`/`Array.push`
  into `Integer[]` rows. `row[x] += k` on a typed row works.
- While writing this task, `bin/sake` briefly failed with a SyntaxError in `lib/sake/resolver.rb`
  (the file was being edited concurrently by someone else); a rerun a minute later was fine.
## hotel_bookings
- Nights are `Time` values (`Time.new(2026, 12, 15) + i * 86400`); `Array.include?` on Times and
  `(Time - Time) / 86400` -> Float -> `Float.to_i` behave as in Ruby. `DAY_SECS`/`BASE_RATE`
  constants -> `def day_secs` and a `case/in` function.
- Ruby block params `|_guest, k, first, nights|` on `find_index` -> `|w|` + multiple assignment
  (kept the same in Sake; 4-param destructuring would also work).
## ring_road_traffic
- Heaviest task: first version (7 densities x 3 probabilities x 50 steps) took 5.8 s user in Sake;
  cut to 4 densities x 40 steps (~2.6 s). `Array.new(@length, ".")` -> `Integer.times` + push.
- Ruby `min_by { |c| [c.laps, c.pos] }` -> `laps * 100 + pos`.
## packet_network
- Routing helpers are `module Routing; module_function` and are called as `Routing.table(...)`
  in both versions. Ruby's `in_flight.partition` -> `select` + `delete_if`.
- My first draft declared `delivered = Packet[]` but pushes `[pkt, t]` Tuples into it; noticed
  before running and changed it to `Array[]` (a typed Array would raise on the push).
