# Notes for 16-dates

General: Sake has no value constants, so Ruby constant tables (`DAY_NAMES = [...]`) become
zero-argument functions (`def day_names = Array[...]`) in every Sake version below.

General: no unary minus, so Ruby's `-x` is written `0 - x` in Sake (negative literals like `-1` are fine).

## date_arith
- `Date#-` takes an Integer or a Date; in Sake this is one `def -(dt, other)` with `case other in Integer ... in Date`,
  which mirrors the Ruby version. Worked first time.
## iso_week
- `s[0, 8]` (start, length) is rejected statically: "`fmt_week(year, week, 1)[0, 8]` takes one index". Used `s[0...8]`.
- `y, m, d = Array.map(...)` fails at run time: "TypeError: multiple assignment needs a Tuple, got Array".
  Index the Array instead (`parts[0]`, ...).
- `Array.sort` on `[year, week]` Tuple keys: "ArgumentError: Array.sort: cannot compare elements of types Tuple".
  Used `Array.sort_by { |year, week| year * 100 + week }`.
- Ruby's `Hash.new { |h, k| h[k] = [] }` has no Sake form (blocks are not values); Sake checks `by_week[key] == nil`
  and stores a fresh `Array[]`.
## easter
- `orthodox_easter(yy) == [m, d]`: "TypeError: Kernel.==: no implementation for (Tuple, Tuple)". Destructured and
  compared the components.
- `sort_by { |k, n| [-n, k] }` (Tuple sort key): "ArgumentError: Array.sort_by: cannot compare elements of types Tuple".
  Encoded the key as one Integer, `(0 - n) * 10000 + k`.
## meeting_scheduler
- `a, b = String.split(text, "-")`: "TypeError: multiple assignment needs a Tuple, got Array". Used
  `a, _sep, b = String.partition(text, "-")`, which returns a Tuple.
- No `Integer.max`/`Integer.min` (two-argument); `[a, b].max` becomes `Array.max(Array[a, b])` in both versions.
- `Array.combination` yields Arrays, which a `|a, b|` block does not destructure ("block takes 2 parameter(s) but was
  given 1"); the Sake version takes `pair` and indexes it, Ruby destructures.
## timetable
- Ruby's `deps.each_cons(2).map { ... }.max_by(&:first)` uses an Enumerator; Sake's `Array.each_cons` needs a
  block, so the Sake version keeps a running maximum inside `Array.each_cons(deps, 2) { |pair| ... }`.
## recurring_events
- Recurrence rules are Records of different shapes (`{every_days:}`, `{nth:, wd:}`, ...) dispatched with
  `case rule in {every_days:} ...`, the same as Ruby's Hash patterns. Worked first time.
- Ruby's `%w[...]` is not available; written as `Array["Sun", ...]`.
## date_parser
- Ruby's `case s.downcase when "today" ...` (case/when) is not supported; written as `case ... in "today" then ...`
  with an `else nil` branch. Ruby's `to_days(*today)` splat is written `ty, tm, td = today`.
## durations
- Ruby's nested block parameters `each_with_index do |(name, len), i|` are not available (no destructuring
  parameters); Sake takes `|pair, i|` and does `name, len = pair`.
- Ruby keeps the unit table as a class constant `UNITS`; Sake builds the Hash inside `parse` and uses a Tuple list in `human`.
## cron_schedule
- The first version took 11 s under Sake (0.1 s in Ruby): `next_after` re-sorted the hour/minute Sets on every
  call and the firing count ran over a whole month (792 calls). Sorted once at parse time (both versions) and
  counted two weeks instead; now ~1.6 s.
- Ruby's `part.split("/", 2)` (nil when no step) is written with `String.partition`, which always gives a 3-Tuple;
  "no step" is `String.empty?(step_text)`.
## fiscal_quarters
- `date, region, amount = String.split(line, " ")` again needs indexing (`fields[0]`...); Ruby's heredoc data
  became a multi-line string literal returned by a function; Ruby's nested destructuring `(ry, period), amount = best`
  is two assignments in Sake. `Array.sort` on Tuple keys again replaced by `sort_by` with an Integer key.
## billing_cycles
- Ruby's `loop do ... next ... break ... end` is `while true` in Sake (`next`/`break` work in `while`).
## project_gantt
- Ruby's `Task#initialize` sets start/finish/late_start to 0 itself; with `Struct.new` every field is positional,
  so Sake adds a `new_task` helper (a `default:` setting would also work).
## moon_phases
- Possible inconsistency (not a blocker): `Array.index(a, [3, 4])` and `Array.include?(a, [3, 4])` compare Tuples by
  content and succeed, while `[3, 4] == [3, 4]` raises "TypeError: Kernel.==: no implementation for (Tuple, Tuple)"
  (see easter). Repro: `a = Array[[1, 2], [3, 4]]; p(Array.index(a, [3, 4])); p([3, 4] == [3, 4])` prints 1, then fails.
  This program relies on the `Array.index` form, which matches Ruby.
## calendar_systems
- The shared behaviour is a mixin `module CalendarDate` (needs `to_jdn`/`to_s` from the includer) called as
  `CalendarDate.describe(date)` over a heterogeneous list, i.e. dispatch on the first argument. Calling
  `CalendarDate.to_jdn(date)` is not possible because `to_jdn` belongs to the types, not the module, so the module
  got a one-line `def jdn(x) = to_jdn(x)` (Ruby has the same `jdn` method for symmetry).
- During the first run the interpreter itself failed to load (a syntax error in `lib/sake/resolver.rb` while
  someone was editing it); a rerun a minute later passed. Not a problem in this program.
