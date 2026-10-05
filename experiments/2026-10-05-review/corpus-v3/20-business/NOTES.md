# 20-business notes (corpus-v2, today's Sake)

All 25 programs run with `--strict=0` and print their `.out` unchanged. No interpreter bugs found in this round.

Still worked around:

- `String.split(s, sep, limit)` is not available. Where the rest of the line must stay whole
  (`date, memo = line.split(" ", 2)` in bank_ledger, timesheet, todo_list) `String.partition` is used.
  Plain Array multiple assignment is no help there: the lengths must match.
- An optional trailing part (`whole, frac = s.split(".")`, frac may be missing) cannot be an Array
  multiple assignment either (length 1 vs 2 is an `ArgumentError`), so bank_ledger keeps `String.partition`.
- No `break` in blocks (customer_loyalty, warehouse_picking: `next if left == 0` in `Array.each`).
- No nested block parameters `|(a, b, c), i|` (event_registration destructures inside the block).
- No array patterns (`in [_, _, :change, day, plan, seats]`): subscription_billing dispatches on `e[2]`
  and destructures inside the branch, since its events have different lengths.
- `@x ||= v` on a field is still `unsupported syntax` (ticket_helpdesk writes the `if @x == nil` form);
  local `x ||= v` and `h[k] ||= v` work.
- `Array.to_h` takes no block (ticket_helpdesk fills a `Hash[]`), `Array.new(n)` is missing
  (appointment_scheduler), `%w[]` is missing (room_reservations), constants are functions.
- Record patterns with a value (`in {kind: :percent, rate:}`) are still rejected; shopping_cart binds
  `kind` first and matches on it.
- Enumerators without a block (`each_cons(2).map { }.max`, `each.with_index(1)`) have no form; a running
  maximum / a counter is kept instead (timesheet, warehouse_picking).
