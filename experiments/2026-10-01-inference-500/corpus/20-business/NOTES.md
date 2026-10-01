# 20-business notes

## General (found while probing, applies to several tasks)

- Sorting by a composite key: `Array.sort_by(xs) { |x| [a, b] }` fails at run time with
  `ArgumentError: Array.sort_by: cannot compare elements of types Integer` (the message names the
  element type of the Tuple, not "Tuple"; `Array.sort` on Tuples says `... of types Tuple`).
  Tuples are not comparable. Workaround used: pack the keys into one Integer (or String), or define
  a Struct with `include Comparable` and `<=>`. The Ruby versions keep the natural `[a, b]` key.
- Most frequent workaround: multiple assignment from an Array (`a, b = s.split(x)`) is a run-time
  `TypeError: multiple assignment needs a Tuple, got Array`; hit in grade_book, gym_membership,
  parking_garage, timesheet, warehouse_picking, vendor_quotes, bank_ledger. Fixed with
  `String.partition` (which returns a Tuple) or by indexing.
- No unary `-`/`!`: `0 - x`, `x == false`; no `break` in blocks; no value constants (functions).
- Ties in `sort_by`/`max_by` are avoided (keys made unique, e.g. by adding the id), because the
  order of ties is not guaranteed to agree between Ruby and Sake.

## todo_list

- `String.split(s, " ", 2)` (limit argument) is not available (`String.split(x, [String|Regexp])`).
  Used `cmd, _sep, rest = String.partition(line, " ")`.
- Priority order (`[rank, due, id]` in Ruby) is packed into one Integer key in Sake.

## shopping_cart

- Record patterns with a value (`in {kind: :three_for_two}`, `in {kind: :percent, rate:}`) are
  rejected: `only Record patterns that bind fields are supported: \`in {x:, y: name}\``.
  Sake: `promo => {kind:}`, then `case kind in :percent` and `promo => {rate:}` inside the branch.
- `Money * k` with k Integer or Float: Ruby's `(cents * k).round` works for both; in Sake
  `Float.round` rejects an Integer (`Float.round: argument 1 must be Float, got Integer`), so the
  product is matched with `case v in Integer ... in Float ...`.

## grade_book

- Multiple assignment from an Array is a run-time error: `TypeError: multiple assignment needs a
  Tuple, got Array` (for `name, cat, max = String.split(h, ":")`). Sake indexes the parts
  (`parts[0]`, `parts[1]`, ...).

## room_reservations

- Day-plan order `[start, id]` packed into one Integer key in Sake (Tuple keys do not sort).
- `%w[mon tue]` is not available in Sake; written `Array["mon", "tue"]`.

## inventory_reorder

- No two-argument max: Ruby's `[eoq, rop - have].max` is written `Array.max(Array[eoq, rop - have])`.

## payroll

- Two employee kinds (Hourly, Salaried) share a mixin module `Employee`; Ruby's duck-typed
  `e.gross_pay(h)` / `e.name` become dispatching calls `Employee.gross_pay(e, h)` /
  `Employee.name(e)`. The module needs its own `gross_pay` (a default that raises) for
  `Employee.gross_pay` to exist; each type's own definition wins. Accessors such as `get_name` are
  not module functions, so the module wraps them (`def name(e) = get_name(e)`).
- First attempt had a typo that produced `get_Employee.retirement(e)`; the checker's hint
  (`Employee.retirement(get_Employee, e)`) was confusing but the error was mine.
- Unary minus: `sort_by { -g }` written `0.0 - g`. `is_a?(Hourly)` written `x in Hourly`.

## invoice_generator

- Ruby's `Time.new(*s.split("-").map(&:to_i))` (splat) and `y, m, d = array` are not available;
  Sake indexes the parts. Dates use `Time.new` (machine TZ is UTC, so day arithmetic with
  `+ n * 86400` is deterministic here).
- Money is kept as Rational (`150r`, `String.to_r`, `Rational.round`); `Array.sum` with a block over
  Rationals works.

## expense_tracker

- `!s.match?(re)` written `String.match?(s, re) == false` (no unary `!`).
- `date[0, 7]` (start, length) is not available; `date[0...7]` (Range) works in both languages.
- `Kernel.Float(s) rescue nil` works as in Ruby.
- Constants (`RULES`, `BUDGETS`) become zero-argument functions; Regexp literals with `/i` work.

## restaurant_orders

- No notable problems. `while (l = f(...))`, `@tables[n] ||= ...` and `Integer.divmod` with
  Tuple destructuring all work as in Ruby.

## gym_membership

- `day_s, who = entry.split(" ")` again needs a Tuple: `day_s, _sep, who = String.partition(entry, " ")`.
- `max_by { |d, c| [c, -d] }` (tie-break) packed into `c * 10 - d`.

## parking_garage

- `h, m = hhmm.split(":").map(&:to_i)` -> `h, _sep, m = String.partition(hhmm, ":")` (Array
  multiple assignment again).
- Spot choice `min_by { [rank, level, index] }` packed into one Integer.

## appointment_scheduler

- `Array.new(n)` is not available; a row of n nils is `Array.map(Range.to_a(1..n)) { nil }`.

## customer_loyalty

- `break` inside a block is not allowed; the FIFO redemption loop uses `next if left == 0`
  inside `Array.each` where Ruby uses `break if left == 0`.

## sales_report

- Tuple keys in a Hash (`cells[[region, quarter]] += ...` with `Hash.new(0.0)`) work.
- Sorting by descending revenue uses `0.0 - v` (no unary minus).

## timesheet

- First version parsed clock parts with `Kernel.Integer("08")`, which raises ArgumentError (same as
  Ruby: "08" is invalid octal); Ruby would use `Integer(h, 10)` but `Kernel.Integer` takes no base.
  Switched both versions to a regexp check plus `to_i`.
- `Array.each_cons(xs, 2) { |a, b| }` fails at run time: `ArgumentError: block takes 2 parameter(s)
  but was given 1` (the window is an Array, not a Tuple, so it is not destructured). Sake uses
  `|pair|` with `pair[0]`, `pair[1]`. Ruby's `each_cons(2).map { ... }.max || 0` (enumerator
  without a block) has no Sake form; Sake keeps a running maximum in the block.
- `line.split(" ", 2)` and `part.split("-")` destructuring -> `String.partition`.

## rental_fleet

- No notable problems. Arrays of Ranges, `Range.overlap?`, `Range.count` with a block and
  `?`-suffixed top-level functions work as in Ruby.

## ticket_helpdesk

- `@first_reply_at ||= at` is rejected: `unsupported syntax: instance variable or write
  \`@first_reply_at ||= at\`` (although `@x += v` is supported). Written
  `@first_reply_at = at if @first_reply_at == nil && (...)`.
- Least-loaded agent `min_by { [load, index] }` packed into `load * 100 + index`.
- `@agents.to_h { |a| [a, 0] }` (to_h with a block) is not available; Sake fills a `Hash[]` with `Array.each`.

## bank_ledger

- `whole, frac = s.split(".")` with `(frac || "")` becomes `String.partition` (empty String when
  there is no dot). `-bal` written `0 - bal`.

## course_enrollment

- `while promoted.nil? && !c.waitlist.empty?` -> `while promoted == nil && Array.empty?(...) == false`.
- Ruby's `@courses[code] or raise ...` is written as a local plus `raise ... unless c`.

## event_registration

- Ruby's nested block parameters `each_with_index do |(date, type, people), i|` are not
  available; Sake takes `|order, i|` and destructures with `date, type_name, people = order`.
- Optional company (`nil` or String) with `@company || "Independent"` works.

## hotel_billing

- `Folio` joins `Indexable` with `def [](f, category)`, so `f[:minibar]` works as in Ruby.
- Time arithmetic (`t + i * 86400`, `Time.friday?`, `strftime`) relies on the machine TZ (UTC).

## warehouse_picking

- `Array.sort_by(codes) { |c| Location.parse(c) }` with a Struct that includes Comparable and
  defines `<=>` works, as do `<` and `Array.max` on it.
- `loc, sku, qty, exp = line.split(/\s+/)` -> indexing `f[0]`..`f[3]` (Array multiple assignment).
- `each.with_index(1)` (enumerator) has no Sake form; a counter is kept instead.
- FEFO key `[expires || "9999-99-99", location]` is concatenated into one String in Sake.

## subscription_billing

- Events are Tuples of different lengths in one Array (`[m, who, :change, day, plan, seats]`,
  `[m, who, :card, false]`); `e[2]` dispatch plus Tuple multiple assignment in the branch works.
  Ruby would naturally use array patterns (`in [_, _, :change, day, plan, seats]`), which Sake lacks;
  both versions use `case e[2]`.
- `PLANS` constant becomes `def plans`, which builds new Plan values on each call.

## vendor_quotes

- `q == best` on Struct values (fields include an Array of Tuples) works; Ruby's plain class
  compares identity, which gives the same answer here because quotes are distinct.
- `min, price = t.split("@")` -> `String.partition`. `costs.count(nil)` -> `Array.count(costs, nil)`.
