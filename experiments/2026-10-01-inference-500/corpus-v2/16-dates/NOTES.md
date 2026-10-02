# Notes for 16-dates (corpus-v2)

These workarounds remain with today's Sake. No interpreter bugs turned up. All 25 programs pass under `--strict=0`.

- **No value constants.** Ruby constant tables are still zero-argument functions (`def day_names = Array[...]`).
- **No min/max of two values.** There is no `Integer.max`/`min`, and `Array.max` does not accept a Tuple
  (`Array.max([3, 4])` gives "TypeError: Array.max: argument 1 must be Array, got Tuple"). Ruby's `[a, b].max`
  is still written `Array.max(Array[a, b])` (meeting_scheduler, timesheet, parking_fees, billing_cycles, age_calculator,
  recurring_events, calendar_systems).
- **`String.split` has no limit argument.** Ruby's `part.split("/", 2)`, where the step is optional, cannot be destructured
  because the Array length varies. cron_schedule keeps `String.partition` and `String.empty?(step_text)`.
- **`s[start, len]` is rejected** ("takes one index"). iso_week still writes `[0...8]`.
- **No nested block parameters.** `each_with_index do |(name, len), i|` is a static error, so durations keeps `|pair, i|`
  followed by `name, len = pair`.
- **No `Hash.new { |h, k| h[k] = [] }`**, because blocks are not values. iso_week still checks `by_week[key] == nil` first.
- **No Enumerator.** timetable's `each_cons(2).map { ... }.max_by` is still a running maximum inside `Array.each_cons`,
  which now uses `|a, b|`.
- **No case/when.** date_parser's `case String.downcase(s) in "today" ...` still needs `else nil`, because String is an
  open type.
- **calendar_systems.** The mixin's one-line `def jdn(x) = to_jdn(x)` stays. `(Gregorian|Julian|Islamic|LongCount).to_jdn(d)`
  would work, but `CalendarDate.jdn(d)` matches the Ruby version and reads better than listing four types.
