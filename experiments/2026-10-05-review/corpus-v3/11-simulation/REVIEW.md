# REVIEW (11-simulation, corpus-v3)

All 25 programs run with `bin/sake --strict=0` and match their `.out` with exit status 0.
(The `.rb` symlinks in this directory dangle; the Ruby versions were read from
`experiments/2026-10-01-inference-500/corpus/11-simulation/`.)

- bakery_shift: Recipe/Order/Oven `Struct.new` -> `class` + `attr_reader`/`attr_accessor` with defaults (`ready_at = nil`, `busy_until = 0, batches = 0`), so `Order.new(...)`/`Oven.new("deck")` take Ruby's arguments; `OutOfStock` -> `class < StandardError` + `attr_reader`; `RECIPES` -> `def recipes = once do ... end` (was rebuilt per lookup); `[busy_until, mix_done].max` -> `Array.max(Array[...])`.
- bank_ledger: exception types -> `class < StandardError` + `attr_reader`; `Array.sum(xs) { }` instead of `sum(map)`; `Hash.each_value`; `Hash.sort_by`.
- car_rental: Booking -> class with `attr_accessor car = nil, price = 0, upgraded = false`; Car/Fleet -> `attr_*` + `initialize` creating `@bookings`/`@log` (so `Car.new`/`Fleet.new` take Ruby's arguments); `NoCarAvailable` -> exception class; `CLASSES` -> `once`; `sum { }`, `reject`.
- checkout_lanes: Lane -> class (`queue = nil` + `initialize` for `[]`, `busy_until = 0, served = 0, open = true`); `SPECS` -> `once`; nested block destructuring `|(at, items), i|` and `|id, (lane, wait, done)|` (was `|spec, i|` + assignment); `sum { }`.
- cpu_scheduler: Job -> class, `initialize` sets `@remaining = @burst` (Ruby's `@remaining = burst`); results as one `Array[...]` literal instead of five pushes; `|(name, w), i|`.
- ecosystem_patches: Patch/Census -> classes (field order kept as Ruby's `new`); `GROWTH_RATES` -> `once`; `to_h` via `Array.map { [k, v] }.Array.to_h`; `Array.sum(patches) { }`.
- elevator_scan: Rider/Car -> classes with defaults + `initialize` (`Car.new("A", 0)` as in Ruby); `leaving, @riders = Array.partition(...)` (field target in multiple assignment, was select + delete_if); `case @dir in :up/:down` as Ruby's `case/when`.
- epidemic_network: Person -> class with defaults; Lcg -> class; `values.map(&:state).tally` + `fetch(.., 0)` as in Ruby (was a hand loop into `Hash.new(0)`); `Hash.sort_by`.
- forest_fire: Struct + `Forest.create` factory -> `Forest.new(24, 10, 78, seed)` with `initialize` building `@cells` by `Array.new(h) { Array.new(w) { ... } }`; `GLYPHS`/`NEIGHBORS` -> `once` (glyph `case` -> `Hash.fetch(glyphs, c)`); `sum { }`.
- hotel_bookings: Stay/Room/Hotel -> classes (`status = :booked`, `initialize` for `[]`s, `next_ref = 0` read-only); `BookingError` -> exception class; `BASE_RATE` -> `once` Hash (was a `case` function); `Range.map`/`Range.sum { }` (was `Array.map(Range.to_a(..))`); penalty back to Ruby's `if/elsif/else` expression.
- inventory_reorder: Item/PurchaseOrder/Backorder -> classes; Warehouse `initialize` (so `Warehouse.new(items)`); `[a, b].min` -> `Array.min(Array[...])`; `select ... .Array.sum { }`.
- langton_ants: Ant -> class with `steps = 0`; `DX`/`DY` -> `once` (were functions rebuilding the Array per step).
- library_loans: Title/Member/Loan -> classes (defaults + `initialize` for `holds`/`loans`), `LoanRefused` -> exception class; `Library.new` with no arguments; block-level `rescue` in `do ... end` as in Ruby (was `begin/rescue` inside); `Hash.map`.
- life_torus: World -> class + `attr_reader`; `Hash[sig => 0]`; `if first`; `Hash.sort_by`.
- order_book: Order/Trade -> classes, `InvalidOrder` -> exception class; Book `initialize` (`Book.new`); `[a, b].min` -> `Array.min` (was `Integer.clamp`, a different idiom); `rest(b, o) if ...`; `Array.reverse_each`; `sum { }`.
- packet_network: Packet (`initialize`: `@hops = Array[@src]`), Link (`up = true`), Router (`initialize` for queue, counters default 0), InFlight -> classes; `to_h { }` via map + `Array.to_h`; `Integer.times(40) do |t|` + `if (ev = events[t])` as in Ruby (was a `while` counter).
- parking_garage: Spot/Ticket -> classes, `GarageFull` -> exception class, Garage `initialize`; `SIZE_RANK`/`NEEDED_SIZE` -> `once` Hashes with `Hash.fetch` (were `case` functions); `rate = case kind in ... else 400 end`; `[x, y].min`.
- ring_road_traffic: Vehicle/Road -> classes; `Road.setup` factory -> `Road.new(60, n, seed, p)` with `initialize` using `Array.new(n) { |i| ... }`; `Array.new(@length, ".")`; `Range.map`; `sum { }`.
- runway_ops: Flight -> class with `done_at = nil, emergency = false`; `waiting -= out` (Array `-`, was `delete_if` + `include?`); schedule as `Array[...].Array.map { }`.
- sandpile: `Pile.create` -> `Pile.new(9)` with `initialize` (`Array.new(n) { Array.new(n, 0) }`); `NEIGHBORS` -> `once`; `@grid[y][x] += k` directly; `Array.count(sizes, 0)`; `sum { }`.
- teller_queue_des: Event/Customer/Rng/Heap -> classes (Heap `initialize`, `Heap.new`); heap swap `@items[i], @items[j] = @items[j], @items[i]`; `while (ev = Heap.pop(events))`; `k, v = Hash.min_by(...)`.
- thermostat_house: Room -> class with `heating = false, on_minutes = 0`; `OUTDOOR`/`SCHEDULE` -> `once` (schedule was rebuilt ~600 times); `lows[name] == nil || t < lows[name]` as Ruby.
- traffic_intersection: Vehicle/Phase -> classes; Controller `initialize`-free defaults (`Controller.new(phases)`); `OPPOSITE` -> `once` Hash (was a nested ternary); `filter_map`; `Integer.times(duration)`; `results = Array.map { }`; `Array.sum(Hash.values(..))`.
- vending_machine: exceptions/Slot -> classes; Machine defaults + `initialize`, `state`/`credit` read-only as in Ruby; `ACCEPTED` -> `once`; `return ... unless`; `Array.reverse_each`; `Hash.select { }.Hash.map { }`; `sum { }`.
- water_tanks: Tank/Pipe/Pump -> classes with `overflowed = 0.0, drawn = 0.0`, `running = false`; `STORMS` -> `once`; `[v, volume].min`; `if (ev = events[hour])`.

## Friction

- **`initialize` takes only the instance.** A Ruby constructor argument that is used but not
  stored had to become a field: `density` (forest_fire.sake:5, Ruby `Forest.new(w, h, density, seed)`
  never keeps it) and `n` (ring_road_traffic.sake:9). Wanted `def initialize(f, density)`; wrote an
  extra `attr_reader` field.
- **Defaults are literals only.** Every Ruby `@queue = []` / `@stays = []` / `@hops = [src]` needs a
  `= nil` placeholder field plus an `initialize` that overwrites it: checkout_lanes.sake:2-4,
  car_rental.sake:28-30, hotel_bookings.sake:23,34-40, library_loans.sake:5,12,29-35,
  packet_network.sake:5,16, sandpile.sake:4-5, teller_queue_des.sake:25, vending_machine.sake:17-22,
  parking_garage.sake:18-23, order_book.sake:16-22, inventory_reorder.sake:18-25,
  elevator_scan.sake:19-24, cpu_scheduler.sake:3-4 (`remaining = burst`). This is the most frequent
  remaining noise in the domain; `attr_reader queue = Array[]` (evaluated per `new`) is what was wanted.
- **No private fields.** Ruby's plain ivars (`@rng`, `@seed`, `@state`, `@index`, `@elapsed`,
  `@next_ref`, `@inserted`) must be declared with `attr_reader` and so become public getters and
  `new` arguments: epidemic_network.sake:7, teller_queue_des.sake:16, traffic_intersection.sake:10,
  hotel_bookings.sake:34, forest_fire.sake:5 (`rng`).
- **No enumerators.** `timeline.each_cons(2).count { }` -> counter + `each_cons` block
  (cpu_scheduler.sake:47-48); `sizes.each_with_index.map { }` / `SPECS.each_with_index.map`
  -> push loops (parking_garage.sake:78, checkout_lanes.sake:36-38).
- **`case/in` needs an `else`** where Ruby's `case/when` just yields nil: empty `else` at
  elevator_scan.sake:53 and forest_fire.sake:50.
- **`@x ||= v` only inside the class.** `current.first_run ||= clock` stays
  `Job.set_first_run(current, clock) if Job.get_first_run(current) == nil` (cpu_scheduler.sake:29).
- **No `Hash.new { |h, k| h[k] = [] }`** (blocks are not values): epidemic_network.sake:17-18 keeps
  the nil checks.
- **Record field read needs a pattern.** Ruby `hit ? hit[:target] : 16.0` -> `return 16.0 if ...;
  hit => {target:}` (thermostat_house.sake:32-33, water_tanks.sake:38-39).
- Smaller: no `loop do` (teller_queue_des.sake:46 `while true`); no `Array.reject!`
  (elevator_scan.sake:70 `delete_if`); no `Set#min_by` (elevator_scan.sake:40 `Set.to_a` first);
  no `Array.to_h { }` / `Array.map.with_index` (packet_network.sake:63,76, ecosystem_patches.sake:42 use
  `map { [k, v] }.Array.to_h`).

## Ruby comparison

- Every field read is `Type.get_x(v)` and every write from outside `Type.set_x(v, w)`: Ruby's
  `oven.batches += 1` is `Oven.set_batches(oven, Oven.get_batches(oven) + 1)` (bakery_shift.sake:69),
  `car.km += km` is `Car.set_km(car, Car.get_km(car) + km)` (car_rental.sake:70). This dominates
  the look of every simulation; only code inside the owning class gets `@x += v`.
- Class methods take the instance as an explicit first parameter (`def step(r)`,
  `Road.step(road)`), and a Ruby mixin that uses `self` (cpu_scheduler `Scheduler#report`) is called
  as `Scheduler.report(Fcfs.new, specs)` (cpu_scheduler.sake:109-113).
- Fields are listed in `new`'s argument order, so readers and accessors interleave where Ruby
  groups them (`attr_reader name; attr_accessor temp; attr_reader mass, ...`,
  thermostat_house.sake:2-5; inventory_reorder.sake:2-5).
- Constants are `def name = once { ... }` functions, and `CONST[k]` reads as `name[k]`
  (`opposite[approach]`, traffic_intersection.sake).
- `Hash[...]`/`Array[...]` for literals, `{...}` is a Record (vending_machine events), and
  `&:sym` blocks are spelled out (`Array.sum(trades) { Trade.get_qty(it) }`).
