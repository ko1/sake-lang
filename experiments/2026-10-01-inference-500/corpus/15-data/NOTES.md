# Notes: data processing and reports

Recurring points (details per task below):
- Multi-key sorts: Tuples are not comparable, so `sort_by { [a, b] }` needs a padded String key or a Comparable Struct.
- Array destructuring (`a, b = str.split(...)`, `|(a, b), c|`, splats) is unavailable; `Array.fetch` instead.
- Mixed-type `==` (`value == ""` on Integer | String) raises TypeError; narrow with `in String` first.
- Unions from Ruby-polymorphic calls (`Array.sum` of nothing gives Integer 0 next to Rational sums; `Float.round`
  on Integer | Float) need `case ... in` branches.
- Struct `==` is structural in Sake but identity for the plain Ruby classes the brief prescribes (fulfillment_report).
- Interpreter crash: `Array.join` with no separator (expense_pivot); no longer reproduces at the end of the run.

## sales_by_region
- `ArgumentError: Hash.sort_by: cannot compare elements of types Integer` (the key was the Tuple `[0 - amt, rep]`):
  Tuples are not comparable, so a multi-key sort cannot use a Tuple key. Workaround: a zero-padded String key
  `format("%012d %s", 1_000_000_000 - amt, rep)`.
- Multiple assignment from an Array (`region, rep, ... = fields`) is a TypeError in Sake (only Tuples
  destructure); written as `a, b = Array.fetch(fields, 0), Array.fetch(fields, 1), ...`.
- `Hash[]` value that is a mutable pair: Ruby `mix[k] ||= [0, 0]`; in Sake a Tuple position can be
  updated (`entry[0] += ...`) but I used `Integer[0, 0]` with an explicit nil check.

## expense_pivot
- `error: wrong number of arguments for String.[] (given 3, expected 2)`: `s[start, len]` is not available;
  written with a Range, `ym[5..6]`, `date[0...7]`.
- Ruby's `each_cons(2) do |(am, at), (bm, bt)|` (nested destructuring params) has no Sake form; the block
  receives an Array and the pairs are taken apart with `Array.fetch` and multiple assignment.
- `%w[...]` is unsupported; `String.split("Jan Feb ...", " ")`.
- Interpreter bug: `Array.join` without a separator crashes the interpreter with a Ruby exception
  (`stdlib.rb:176: undefined method 'map' for an instance of String (NoMethodError)`).
  Minimal repro: `p(Array.join(Array["a", "b"]))`. Workaround: `Array.join(xs, "")`. Re-checked at the end of
  the run: the repro now prints `"ab"` (lib/ changed during the run), so the bug appears fixed.

## invoice_totals
- `TypeError: Float.round: argument 1 must be Float, got Integer`: Ruby's `Money#*` does `(cents * k).round` for
  both an Integer quantity and a Float rate. In Sake the rounding operation names its type, so `Money.*`
  branches with `case k in Integer ... in Float ...`.

## access_log_report
- Ruby's `LINE_PATTERN = /.../` constant becomes `def line_pattern = /.../` (no value constants).
- Multi-key sort `sort_by { [-hits, p, m] }` again needs a String key (`format("%05d %s %s", 99999 - hits, p, m)`).

## metric_anomalies
- `TypeError: multiple assignment needs a Tuple, got Array` for `y, m, d = Array.map(String.split(s, "-")) { ... }`
  (as expected from the spec); rewritten with `Array.fetch(parts, i)`.
- `DAY_SECONDS = 86400` becomes `def day_seconds = 86400`.

## cohort_retention
- Ruby's `(active[uid] ||= Set.new) << m` becomes `Set.add(active[uid] ||= Set[], m)`; `each_slice(2) do |uid, date|`
  receives an Array in Sake (not a Tuple), so the pair is read with `Array.fetch`.

## customer_dedupe
- Ruby reads the merged-row Hash with `m[:ids]`; the Sake row is a Record, read with `m => {ids:}` (inside
  one-line blocks as `{ |m| m => {ids:}; Array.size(ids) > 1 }`).

## budget_variance
- `TypeError: Array.each: argument 1 must be Array, got Hash`: iterating the result of `Array.group_by` with
  `Array.each` (a Ruby habit: `.each` works on both). Same slip in inventory_diff. Fixed with `Hash.each`.
- `Hash.dig` takes one key only, so Ruby's `plan.dig(d, line) || 0` is `(plan[d] || Hash[])[line] || 0`.
- Ruby's block parameter `|(d, l)|` has no Sake form; `{ |key| d, l = key; ... }`.

## bank_reconcile
- First version computed day numbers with `Time.to_i(t) / 86400` and printed with `Time.at`, which depends on
  the local time zone (wrong day under TZ=Asia/Tokyo). Changed both versions to days since a local `Time.new(2026, 1, 1)`.

## timesheet_payroll
- Ruby's `week, who, *rest = line.split` (splat) and `rest.each_slice(2).map do |day, span|` become
  `Array.fetch`/`Array.drop` and `Array.each_slice` with `Array.fetch` on the slice.
- `[m, 8 * 60].min` becomes `Array.min(Array[m, 8 * 60])`, whose result may be nil to a checker.

## survey_crosstab
- Responses are Ruby Hashes with Symbol keys read by `r[:age]`; in Sake they are Records read by pattern
  (`r => {answer:, age:}`), which forces multi-statement blocks such as `{ |r| r => {region:}; region }`.

## fx_conversion
- `TypeError: Rational.to_f: argument 1 must be Rational, got Integer`: `Array.sum` of an empty selection gives
  Integer `0`, while non-empty sums are Rational. Ruby's `r.to_f` works on both; in Sake the formatter branches
  with `case r in Rational ... in Integer ...`.
- Ruby builds the rate table with `to_h` and `date, *pairs = line.split`; Sake uses explicit Hash writes and
  `Array.drop`.

## quality_rules
- `error: undefined function Rule.describe`: only functions defined in the module dispatch, so a default
  `describe` was added to `Rule` (each rule type's own `describe` wins); the Ruby module got the same default.
- `error: include Rule in RequiredRule: Rule.run needs field`: inside the mixin, a field reader is `get_field(rule)`,
  not `field(rule)`.
- The rule type for numeric bounds cannot be called `Range` (built-in); named `RangeRule` in both versions.

## league_standings
- Ruby's `form.last(5)` has no Sake form (`Array.last` takes no count); a top-level `last_n` helper with
  `Array.drop` replaces it.
- `_round, games = line.split(": ")` becomes `Array.fetch(parts, 1)`.

## fulfillment_report
- Output differed (`post 6 parcels` vs Ruby `post 7 parcels`): the program called `shipments` twice, and
  `Array.include?(stray, s)` compared Structs by fields in Sake but plain Ruby objects by identity. Fixed in both by
  calling `shipments` once (`all_shipments`). Struct `==` being structural in Sake differs from the plain-class
  Ruby translation the brief asks for.
- Ruby's `catalog.fetch(sku)` with `rescue KeyError` maps directly to `Hash.fetch` + `rescue KeyError`.

## table_renderer
- `TypeError: Kernel.==: no implementation for (Integer, String)`: Ruby's `value.nil? || value == ""` on a cell
  that may be Integer, Float, or String. Sake's `==` has no row for mixed types, so the check became
  `(value in String) && String.empty?(value)`.
- Ruby's `cols.each_with_index.map` (Enumerator chain) has no Sake form; a helper
  `with_index(a) = Array.zip(a, Range.to_a(0...Array.size(a)))` gives `[x, i]` Tuples.
- Ruby's `body + [totals]` (Array `+`) is `Array.dup` then `Array.push`.

## clickstream_sessions
- `!Session.bounce?(it)` (unary `!`) is rejected; written as `Array.reject(...)` and `... == false`.

## etl_star_schema
- `TypeError: Array.fetch: argument 1 must be Array, got Tuple`: dimension attributes are stored as Tuple literals
  (`[name, region]`), so they are read with `t[0]`, not `Array.fetch`. (Ruby uses `fetch`/`[]` interchangeably.)
- The JSON field helper returns String | Integer | nil; the web extractor narrows with `qty in Integer` and
  `(day in String) && ...`, the same in both versions.
- The exception type is `LoadError_` in both versions because Ruby already has `LoadError`.
