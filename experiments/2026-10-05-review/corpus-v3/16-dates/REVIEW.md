# Review: 16-dates (corpus-v3, 2026-10-05)

All 25 programs pass `bin/sake --strict=0` with output identical to `NAME.out` and exit status 0.
Note: the `NAME.rb` symlinks in this directory point to `../../corpus/16-dates/`, which does not exist
from `corpus-v3/`; the Ruby versions were read from `experiments/2026-10-01-inference-500/corpus/16-dates/`.

## Programs

- activity_heatmap: `once` for MONTH_ABBR/DAY_ABBR (the month list had been an `Array[...]` literal rebuilt in every loop iteration); `Integer.between?` for Ruby's `d.between?`; `base /= 3`.
- age_calculator: `class Person` + `attr_reader`; `once` for ZODIAC_CUTOFFS; `Range.sum(1...m) { }` for Ruby's `(1...m).sum { }` (was an accumulator loop); dropped a nil guard Ruby does not have on `cutoffs[(i + 1) % 12]`.
- billing_cycles: `class` + `attr_reader` for Plan/Subscription/Invoice; `class BadAnchor < StandardError` with `attr_reader customer`; `once` for PLANS; `rescue` directly in the `do` block (no `begin`), as Ruby.
- business_days: `class WorkCalendar` with `attr_reader` next to its functions, `class Ticket`; holidays built by a chain `.Array.map { }.Array.to_set` as Ruby's `.map { }.to_set` (was `Set[]` + loop).
- calendar_systems: `attr_reader` in each of the four calendar classes (beside `include CalendarDate`); the module's WEEKDAYS constant is a mixin function `def weekdays = once { ... }` used unqualified, as Ruby; Islamic's MONTHS is `def months = once` inside `class Islamic` (was a top-level `islamic_months`).
- cron_schedule: `class CronError < StandardError`; `Cron` now has Ruby's shape: `Cron.parse` checks the count and calls `Cron.new(text, fields)`, and `initialize(c)` parses `@fields` into `@minutes`, `@hours`, ... (was an 8-argument `Cron.new` built in `parse`); `String.split(part, "/", 2)` and `split(range_text, "-", 2)` (limit argument) replace `String.partition` + `empty?`; `once` for ALIASES; `rescue` in the `do` block.
- date_arith: `class InvalidDate < StandardError`; `once` for WEEKDAY_ABBR; `rescue` in the `do` block.
- date_parser: `class ParseError < StandardError`; `once` for MONTH_NAMES; `rescue` in the `do` block; `Hash.sort_by` instead of `Array.sort_by(Hash.to_a(...))`.
- day_of_week: `once` for DAY_NAMES and MONTH_ABBR (the latter had been a literal inside the loop).
- durations: `class Duration` with `attr_reader secs`; `class BadDuration < StandardError`; UNITS is `def units = once` inside Duration and used by both `parse` (`Array.sum(...) { |num, unit| }`) and `human` (`Hash.filter_map` + `Integer.divmod`, Ruby's shape; was a second, hand-copied unit table and a push loop); ZERO is `once`; nested block parameters `|(name, len), i|` (was `|pair, i|` + `name, len = pair`); `rescue` in the `do` block.
- easter: `class Feast` + `attr_reader`; `once` for MONTH_ABBR; `Hash.sort_by`; inlined a temporary.
- fiscal_quarters: `class Sale`, `class FiscalSpec` with `attr_reader`; RAW_SALES is a `<<~DATA` heredoc, as Ruby (was a flush-left multi-line string); `String.split(line)` (Ruby's `line.split`); the `quarter_of` Tuple is used directly as the Hash key; `grand` hoisted and computed with `Array.sum { }`.
- iso_week: `Array.sum(entries) { }`; `s[0, 8]` (start, length) as Ruby (was `[0...8]`).
- meeting_scheduler: `class Slot` with `attr_accessor start, finish` (Ruby uses attr_accessor: `merge_busy` writes `finish`); `Array.sum { }`.
- month_calendar: `class MonthGrid` + `attr_reader`; `once` for MONTH_NAMES; `Array.new(7)` as Ruby (was `Array[nil, nil, nil, nil, nil, nil, nil]`); `Array.join(cells)`.
- moon_phases: `once` for EPOCH_NEW_MOON (recomputed `days_from_civil` on every call before), PHASES and GLYPHS (were literals inside `phase_name`/`glyph`); the October line is `Range.map { }` + `Array.join`, as Ruby (was `+=` in a loop); `Integer.even?`.
- parking_fees: `class Tariff` with `attr_reader` and `charge_day` together; `class Visit`, `class BadVisit < StandardError`; `once` for WEEKDAY_TARIFF/WEEKEND_TARIFF/RAW_VISITS; the `do` block carries both `rescue` clauses; `Array.sum { }`.
- project_gantt: `class Task` with `attr_reader id, name` / `attr_accessor days` / `attr_reader deps` / `attr_accessor start = 0, finish = 0, late_start = 0`, so `Task.new(id, name, days, deps)` is Ruby's call and the `new_task` helper is gone; `class CycleError < StandardError`.
- public_holidays: `class Rule` (fields with `date_in`/`observe`) and `class Holiday`; `once` for WDAY_NAMES and RULES; `end.Array.sort_by { }` chain for Ruby's `end.sort_by`; `Array.include?(Array[1, 5], ...)` for Ruby's `[1, 5].include?` (was `||`, and a `w = ...; w == 0 || w == 6` block).
- recurring_events: `class Event` + `attr_reader`; `crowded` via `Hash.select` + `Hash.keys`, as Ruby (was Hash.to_a / select / map).
- room_booking: `class Booking` + `attr_reader`; three exception classes `< StandardError`; `once` for DAYS/ROOMS; `Calendar` has `attr_reader bookings = nil, next_id = 1` and `def initialize(cal) = @bookings = Booking[]`, so `Calendar.new` takes no arguments as in Ruby (was `Calendar.new(Booking[], 1)`); the `do` block carries three `rescue` clauses; `Array.sum { }`, `Range.map`.
- shift_rota: `class Shift`; `class Worker` with `attr_reader name, off, assigned = nil, hours = 0` and `initialize` setting `@assigned = Array[]`, so `Worker.new("Ada", Set[5, 6])` as Ruby (was `Worker.new(..., Array[], 0)`); `once` for SHIFTS/DOW_NAMES; a day's row is `Array.map(shifts) do ... if/else value end`, as Ruby (was a push loop).
- time_zones: `class Zone` + `attr_reader`; `once` for ZONES; `next unless w` as Ruby (was `if w ... end`).
- timesheet: `class Punch`, `class Shift`, `class PunchError < StandardError`; LOG_TEXT is a `<<~LOG` heredoc; `String.split(line)`.
- timetable: `class Train` + `attr_reader`; `once` for STATIONS/RAW_TABLE; `next_journey`'s filter is one condition as Ruby (was a temporary); `Array.sum { }`.

25 changed, 0 unchanged. Most used: `class` + `attr_reader` (23 programs), `once` (18), exception classes `< StandardError` (9), `rescue` in a `do` block (7), `initialize` (3: cron_schedule, room_booking, shift_rota; project_gantt needs only defaults).

## Friction

- **`[a, b].max` / `.min`.** Wanted Ruby's two-value max/min → there is no `Integer.max`, and `Array.max` rejects a Tuple → `Array.max(Array[a, b])`, 11 times: age_calculator.sake:33, billing_cycles.sake:52, calendar_systems.sake:77, meeting_scheduler.sake:102, parking_fees.sake:22,74, recurring_events.sake:84,98, timesheet.sake:100,101,128.
- **Derived fields that are not constructor arguments.** Ruby's `Cron#initialize(text, fields)` keeps `@text` and derives `@minutes` ... from `fields`. In Sake, `new`'s arguments are the fields, so `fields` becomes a stored field and every derived one must be declared with a placeholder default (cron_schedule.sake:66-67: `attr_reader minutes = nil, hours = nil, ...`). The same for an Array-valued field: a default must be a literal, so room_booking.sake:41 and shift_rota.sake:13 write `= nil` and set `Booking[]`/`Array[]` in `initialize`. All these fields become readable from outside (`get_next_id`), where Ruby's were private ivars; there is no private field.
- **Field order is constructor order.** Ruby groups `attr_reader :id, :name, :deps` and `attr_accessor :days, ...` independently of `initialize(id, name, days, deps)`. In Sake the attr lines must follow `new`'s order, so project_gantt.sake:4-9 needs four lines alternating reader/accessor.
- **Splat into a user function.** Ruby's `days_from_civil(*ymd(s))` (billing_cycles) and `to_days(*today)` (date_parser) are static errors ("splat arguments go only to built-ins") → `y, m, d = ymd(s)` first (billing_cycles.sake:40, date_parser.sake:76).
- **Nested multiple assignment.** Ruby's `(ry, period), amount = best` is rejected ("`(a, b)` cannot be assigned here", although block parameters may nest) → `key, amount = best; ry, period = key` (fiscal_quarters.sake:115-116).
- **No `Hash.new { |h, k| h[k] = [] }`** → `by_week[key] = Array[] if by_week[key] == nil` (iso_week.sake:84).
- **No Enumerator.** timetable's `deps.each_cons(2).map { ... }.max_by(&:first)` stays a running maximum inside `Array.each_cons` (timetable.sake:107-111).
- **No symbol-to-proc.** `laps.reduce(ZERO, :+)` → `Array.reduce(laps, zero) { |a, b| a + b }` (durations.sake:103); `map(&:name)` is a block everywhere.
- **`Array.to_h` takes no block.** Ruby's `tasks.to_h { |t| [t.id, t] }` stays a loop (project_gantt.sake:46).
- **case on a String needs `else nil`.** Ruby's `case s.downcase when "today" ... end` falls through; Sake's `case`/`in` raises without `else` (date_parser.sake:78-83).

## Ruby comparison

What a Ruby programmer would notice first:

- **The receiver moves into the argument list.** `Duration.clock(d)`, `Zone.local(zn, t)`, `Booking.get_room(b)` instead of `d.clock`, `zn.local(t)`, `b.room`. A type's functions take the instance as an explicit first parameter (`def charge_day(t, from, to)`, parking_fees.sake:10), and reads from outside are `get_x`.
- **Constants are functions.** `MONTH_ABBR[m - 1]` is `month_abbr[m - 1]` with `def month_abbr = once { ... }`; `UNIT`/`SYNODIC` are `def unit = 1000000` (moon_phases.sake:25-26). With `once` the tables are now built once, as Ruby's constants are, but the name is lowercase and the definition is a `def`.
- **Class bodies.** `attr_reader year, month, day` with bare names, and no `initialize` that copies arguments into ivars: `T.new` stores them. Class-level factory methods (`def self.parse`, `def self.from_jdn`) are plain `def parse(text)` in the class, called `Duration.parse(...)`, and build with `Duration.new` rather than `new`.
- **Exceptions.** `class BadVisit < StandardError` with `attr_reader plate` matches Ruby's line count minus the `initialize`/`super`; `e.message` is `Exception.message(e)`, `e.plate` is `BadVisit.get_plate(e)`.
- **Collections are spelled with their type.** `Array[...]`, `Hash[...]`, `Set[...]`, `Integer.times(3)`, `Range.each(1..12)`, `Array.sum(xs) { }` in place of literals and method calls; long chains read inside-out unless written with the `.Array.map` chain form (business_days.sake:78-80, public_holidays.sake:94).
- **Program structure otherwise matches.** Algorithms (`days_from_civil`, Zeller, Meeus), control flow, `case`/`in` on Symbols and Records, `rescue` in `do` blocks, heredocs, and `format` strings are line-for-line the Ruby versions.
