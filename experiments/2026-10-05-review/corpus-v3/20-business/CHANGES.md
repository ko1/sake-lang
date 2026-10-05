# Changes (20-business, corpus -> corpus-v2)

- appointment_scheduler: unchanged (`Array.new(n)` is still missing; the nil row stays `Array.map(Range.to_a(1..n)) { nil }`)
- bank_ledger: `show(0 - bal)` -> `show(-bal)` (unary `-`); `String.partition` kept (the fraction part is optional, and `split(" ", 2)` has no limit)
- course_enrollment: `Array.empty?(...) == false` -> `!Array.empty?(...)` (unary `!`)
- customer_loyalty: unchanged (`break` in a block is still not allowed; `next if left == 0` stays)
- event_registration: unchanged (nested block parameters `|(date, type, people), i|` are still not available)
- expense_tracker: `String.match?(...) == false` -> `!String.match?(...)` (unary `!`)
- grade_book: `parts = String.split(h, ":")` + `parts[0..2]` -> `name, cat, max = String.split(h, ":")` (multiple assignment from an Array)
- gym_membership: `String.partition(entry, " ")` -> `day_s, who = String.split(entry, " ")` (Array multiple assignment); `max_by { c * 10 - d }` packed key -> `[c, -d]` (Tuple ordering, unary `-`)
- hotel_billing: `0 - owed` -> `-owed` (unary `-`)
- inventory_reorder: unchanged (`Array.max(Array[a, b])` is also what Ruby writes: `[a, b].max`)
- invoice_generator: `parts[0], parts[1], parts[2]` -> `y, m, d = Array.map(String.split(s, "-")) { ... }` (Array multiple assignment)
- library_loans: unchanged
- parking_garage: `h, _sep, m = String.partition(...)` + two `to_i` -> `h, m = Array.map(String.split(hhmm, ":")) { ... }`; packed spot key `rank * 1000 + level * 100 + index` -> `[rank, level, index]` (Tuple ordering)
- payroll: the `Employee` mixin module (accessor wrappers `name`/`id`/`retirement`/`label` and a raising default `gross_pay`) removed; calls are `(Hourly|Salaried).gross_pay(e, h)`, `(Hourly|Salaried).get_name(e)`, etc. (type list on the operation); `0.0 - g` -> `-g`
- rental_fleet: unchanged
- restaurant_orders: unchanged
- room_reservations: packed day-plan key `start * 100 + id` -> `[start, id]` (Tuple ordering); `Array["mon", "tue"]` stays (no `%w`)
- sales_report: `0.0 - v`, `0.0 - total` -> `-v`, `-total` (unary `-`)
- shopping_cart: `Money#*` `case v in Integer ... in Float ... Float.round(v)` -> `Money.new((Integer|Float).round(@cents * k))` (type list on the operation)
- subscription_billing: `0 - subtotal * coupon_off / 100` -> `-subtotal * coupon_off / 100` (unary `-` on Rational); `case e[2]` kept (no array patterns)
- ticket_helpdesk: packed agent key `load * 100 + index` -> `[load, index]` (Tuple ordering)
- timesheet: `a, _dash, b = String.partition(part, "-")` -> `a, b = String.split(part, "-")`; `each_cons(xs, 2) { |pair| pair[0] ... pair[1] }` -> `{ |a, b| }` (block destructuring of an Array), twice
- todo_list: packed Integer sort key and its helper `due_key` removed; `sort_by { [rank, due, id] }` (Tuple ordering, String in a Tuple); `String.partition` for `split(" ", 2)` kept
- vendor_quotes: `min, _at, price = String.partition(t, "@")` -> `min, price = String.split(t, "@")`
- warehouse_picking: `f[0]..f[3]` -> `loc, sku, qty, exp = String.split(...)`; FEFO key String concatenation -> `[expires || "9999-99-99", location]` (Tuple ordering)

18 of 25 programs changed. Chains (`x.T.f`) and `_` were not used: the programs read well as they are, and no
long nested call sequence asked for them.
