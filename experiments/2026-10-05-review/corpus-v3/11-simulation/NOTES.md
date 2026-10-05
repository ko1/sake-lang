# Notes for 11-simulation (corpus-v2)

Remaining workarounds with today's Sake (none of them looks like an interpreter bug):

- **Multiple assignment only to locals.** `leaving, @riders = Array.partition(@riders) { ... }`
  (elevator_scan) and `@items[i], @items[j] = @items[j], @items[i]` (teller_queue_des swap) are
  rejected: "only `a, b = tuple` (local variables, no splat) is supported". elevator_scan keeps
  `select` + `delete_if` for `@riders`; the heap swap keeps a temporary.
- **No nested block destructuring.** `|(at, items), i|` is rejected ("nested destructuring `(a, b)`
  is not supported"), so checkout_lanes and cpu_scheduler keep `|pair, i|` + `a, b = pair`.
- **No `||=` on a field.** `@first_run ||= clock` is "unsupported syntax"; cpu_scheduler keeps an
  explicit nil check + setter.
- **No value constants** (OPPOSITE, DX/DY, RECIPES, SCHEDULE, ...): still functions or inline data,
  rebuilt per call (thermostat_house rebuilds its schedule ~600 times).
- **No `Array.new(n) { ... }`**: grids are still built with `Integer.times` + `Array.push`
  (forest_fire, sandpile, ring_road_traffic).
- **No `Hash.new { |h, k| h[k] = [] }`**: epidemic_network still checks `graph[a] == nil` first.
- **No Array `-`**: runway_ops keeps `delete_if` + `include?` for Ruby's `waiting -= out`
  (`Array.difference` would also do; not changed, since it was available before).
- **Set has no `min_by`**: elevator_scan keeps `Array.min_by(Set.to_a(stops))`.
- **No `Array.inspect`**: `Kernel.inspect(xs)` is used (checkout_lanes, car_rental).
