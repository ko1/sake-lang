# Review of 20-business against today's Sake

All 25 programs run with `bin/sake --strict=0`: exit 0, stdout byte-identical to `NAME.out`.
The `.rb` files in this directory are dangling symlinks (`../../corpus/20-business/...` does not exist
from here); the Ruby versions were read from `experiments/2026-10-01-inference-500/corpus/20-business/`.

"class + attr" below means: `X = Struct.new(...)` became `class X` with `attr_reader` lines (and
`attr_accessor` for the fields Ruby writes from outside), and `E = Exception.new(...)` became
`class E < StandardError` with `attr_reader`.

- appointment_scheduler: class + attr (Doctor, Request); `day_names` table in `once`; `Array.new(slots_per_day)` in place of `Array.map(Range.to_a(1..n)) { nil }`; `cancel` iterates `Array.compact(grid)` as Ruby does, dropping `next unless row`.
- bank_ledger: class + attr (Account reader/accessor split, Journal, LedgerError); `chart` in `once`; `amount` is `whole, frac = String.split(s, ".")` with `frac || ""` (multiple assignment now gives nil for a missing part); `date, memo = String.split(line, " ", 2)` (split limit) replaces `String.partition`; do-block `rescue` (no `begin`) as Ruby.
- course_enrollment: class + attr (Student, EnrollError); Course gets `roster = nil, waitlist = nil` and an `initialize` that makes the two Arrays, so `Course.new` takes the six arguments Ruby's does.
- customer_loyalty: class + attr (Lot, NotEnoughPoints); Customer gets `tier = :bronze, spend = 0.0` defaults and an `initialize` for `lots`/`history`, so `Customer.new(id, name)` as in Ruby; `tiers`, `multiplier`, `rewards` tables in `once` (the `case`-based `multiplier` and the `reward_cost` helper are gone, `Hash.fetch` as Ruby); `break if left == 0` (break in a block) replaces `next`; `Integer.between?(left, 0, 30)`; `name, _min = Array.find(...)` directly.
- event_registration: class + attr (TicketType with `attr_accessor sold`, Registration, SoldOutError); `|(date, type_name, people), i|` nested block parameter replaces the destructuring line.
- expense_tracker: class + attr (Txn, Rule); `rules` (a `Rule[...]` rebuilt per call) and `budgets` in `once`.
- grade_book: class + attr (Assignment, Student); `weights` in `once`.
- gym_membership: class + attr (Member, punches as the only accessor); `class AccessDenied < StandardError` with `raise AccessDenied, "msg"` as Ruby.
- hotel_billing: class + attr (Stay, Charge, BillingError); `base_rate` becomes a `once` Hash (as Ruby's `BASE_RATE`) instead of a `case` function; Folio's `open` constructor replaced by `initialize` making `charges`/`payments`, so `Folio.new(s)` as in Ruby.
- inventory_reorder: class + attr (Item, Supplier, StockError); `Array.push(orders[k] ||= Array[], ...)` as Ruby's `(orders[k] ||= []) << ...`; do-block `rescue`.
- invoice_generator: class + attr (Client, Entry, Expense, InvoiceLine); `staff_roles`, `standard_rates` in `once`.
- library_loans: class + attr (Book, Member, Loan, LoanError, each with Ruby's accessor); Library's `create` replaced by fields defaulting to nil and an `initialize`, so `Library.new` with no arguments.
- parking_garage: class + attr (Spot, Ticket, GarageFull, TicketError with `raise TicketError, "msg"`); `size_rank` and `size_codes` become `once` Hashes (Ruby's `SIZE_RANK`, `SIZE_CODES`); `seq` is a field with default 100; do-block `rescue`. `Garage.build(layout)` is kept (see Friction).
- payroll: class + attr (Hourly, Salaried, Stub, PayrollError); `brackets` in `once`; Ruby's `module Employee` is back: `label` as a mixin function using `@id`/`@name`, and `gross_pay` as a required function (`raise NotImplementedError`), called as `Employee.gross_pay(e, h)` and `Employee.label(e)`; do-block `rescue`.
- rental_fleet: class + attr (Car with Ruby's reader/accessor split, Rental, NoCarAvailable); `classes`, `daily_rate` in `once` (`daily_rate` was a function that rebuilt the Hash per call); Fleet takes only `cars` in `new`, `rentals`/`next_id` set by `initialize`/default; do-block `rescue`.
- restaurant_orders: class + attr (MenuItem, OrderLine, Table, SoldOut); Restaurant's `create` replaced by `initialize`, `Restaurant.new(menu)`; do-block `rescue`.
- room_reservations: class + attr (Room, Booking, ConflictError, RequestError with `raise RequestError, "msg"`); Schedule's `create` replaced by `initialize` and `last_id = 0`, `Schedule.new(rooms)`.
- sales_report: class + attr (Sale; its functions moved into the one class, as in Ruby).
- shopping_cart: class + attr (Product, Line, CartError); Cart's `create` replaced by `initialize` and `coupon = nil`, `Cart.new(catalog)`; `disc += amount`.
- subscription_billing: class + attr (Plan, Subscription with Ruby's reader/accessor split, PaymentDeclined); `plans` in `once` (it used to make new Plan values on every call).
- ticket_helpdesk: class + attr (InvalidTransition); Ticket declares `status = :new`, `agent = nil`, ... and an `initialize` for `log`, so `Ticket.new(id, subject, priority, at)` as in Ruby; `@first_reply_at ||= at if ...` (field `||=`); `transitions`, `sla` in `once` (`sla` was a `case` function); Desk `new(agents)` with `initialize`; `load = Array.to_h(Array.map(...))`; do-block `rescue`.
- timesheet: class + attr (Shift with Ruby's `minutes`, EntryError); `rates` in `once`; `day, rest = String.split(line, " ", 2)`.
- todo_list: class + attr (Todo, CommandError); `priority_rank` becomes a `once` Hash (Ruby's `PRIORITY_RANK`); TodoList `initialize`, `TodoList.new`; `cmd, rest = String.split(line, " ", 2)`; line numbers from `each_with_index` as Ruby.
- vendor_quotes: class + attr (Quote, Need); `fx` in `once`.
- warehouse_picking: class + attr (Bin, Pick, Location); `break if left == 0` replaces `next`.

25 of 25 changed. Most used: class + attr_reader/attr_accessor (25 programs), `class E < StandardError`
(18), `once` tables (15), `initialize` in place of a `create`/`build`-style constructor or of
placeholder arguments (10), do-block `rescue` without `begin` (7), `split(s, sep, 2)` (3), `break` in a
block (2).

## Friction

- **A constructor whose arguments are not the fields.** Ruby's `Garage.new(layout)` builds `@spots`
  from `layout` and stores no `layout`. Sake's `new` takes the fields and `initialize(c)` takes only
  the instance, so either a `layout` field is stored or the conversion overloads `@spots`. I kept a
  separate `Garage.build(layout)` (parking_garage.sake:36, :80).
- **Defaults are literals only.** Ruby's `@lines = []`, `@tickets = {}` cannot be a field default, so
  each such class declares `x = nil` and assigns in `initialize`: course_enrollment.sake:2-6,
  customer_loyalty.sake:16-20, hotel_billing.sake:28-34, library_loans.sake:29-35,
  restaurant_orders.sake:33-38, rental_fleet.sake:33-35, room_reservations.sake:30-32,
  shopping_cart.sake:39-42, ticket_helpdesk.sake:22-26 and :49-51, todo_list.sake:22-24.
  I wanted `attr_reader lines = Array[]`; the `= nil` lines read as if nil were a legal value.
- **Private state must be a field.** Ruby's `@seq`, `@next_id`, `@last_id` have no accessor; in Sake
  they are `attr_reader` fields (parking_garage.sake:35, rental_fleet.sake:33, room_reservations.sake:30,
  todo_list.sake:22), so they get a `get_` and are a (defaulted) positional argument of `new`.
- **Field order is `new`'s argument order.** Where Ruby lists readers then accessors, Sake must
  interleave lines to keep Ruby's argument order: rental_fleet.sake:2-5, warehouse_picking.sake:1-5,
  gym_membership.sake:1-4, customer_loyalty.sake:1-4 (accessor `points` first), and Ticket in
  ticket_helpdesk.sake:22-24, whose defaulted fields must also come last.
- **Record patterns with a value.** Ruby's `in {kind: :percent, rate:}` is rejected; shopping_cart.sake:78-84
  binds `kind` with `promo => {kind:}` and then asserts `promo => {rate:}` inside a symbol `case`.
- **No array patterns.** subscription_billing.sake:84 dispatches on `e[2]` and destructures inside
  the branch (Ruby does the same, but `in [_, _, :change, day, plan, seats]` was the natural wish).
- **`Array.to_h` takes no block.** subscription_billing.sake:65 fills `by_name` by hand
  (Ruby `subs.to_h { |s| [s.customer, s] }`); ticket_helpdesk.sake:59 maps first.
- **No enumerator without a block.** timesheet.sake:43-47 keeps a running maximum for Ruby's
  `each_cons(2).map { ... }.max || 0`; warehouse_picking.sake:88 a counter for `each.with_index(1)`.
- **Accessors across two types.** payroll.sake:59, :60, :91 still write `(Hourly|Salaried).get_name(e)`;
  the Employee module carries `label` but a module cannot declare the shared fields.
- **Required function vs Ruby's default.** Ruby's `Employee#gross_pay` raises a RuntimeError with a
  message; Sake's required form is `raise NotImplementedError` (payroll.sake:13), which is a program
  error, not a rescuable one. Same intent, different contract.

## Ruby comparison

- Every field read is `Type.get_x(v)` where Ruby has `v.x`; `map(&:name)` becomes
  `Array.map(xs) { |x| T.get_name(x) }`. This is still the first thing a Ruby reader notices.
- Tables are `def name = once { ... }` and read as calls with `Hash.fetch(table, k)`
  (hotel_billing.sake:49, customer_loyalty.sake:27), or `size_rank[k]` (parking_garage.sake:48);
  Ruby's `CONSTANT.fetch(k)` reads the same, only the name is lower case.
- Functions take the instance first (`def post(f, night, ...)`) and use `@x` for its fields; with
  `attr_*` lines in the class body and `initialize`, the class bodies now look like Ruby's apart from
  that extra first parameter.
- Exception classes are one line each (`class E < StandardError` + `attr_reader`), shorter than Ruby's
  hand-written `initialize(message, ...)` + `super`.
- Ruby's do-block `rescue` works unchanged; the earlier versions had wrapped those bodies in
  `begin ... end`, now removed in the seven programs where Ruby uses it.
