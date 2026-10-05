# Review: 15-data (corpus-v2 -> corpus-v3)

22 of 25 programs changed; all 25 exit 0 and match `NAME.out` with `bin/sake --strict=0`.
(The `.rb` files here are symlinks to `../../corpus/15-data/`, which does not exist under
`2026-10-05-review/`; the Ruby versions were read from `experiments/2026-10-01-inference-500/corpus/15-data/`.)

- access_log_report: `class Request` + `attr_reader` (was `Struct.new`); `Hash.map(endpoints) do |(meth, path), list|` (nested block destructuring) instead of `Array.map(Hash.to_a(...))` + `meth, path = key`.
- bank_reconcile: `class Entry` with `attr_reader source, day, amount, memo` + `attr_accessor matched` (Ruby's split); `class ParseError < Exception` + `attr_reader source, text` (was `Exception.new(:source, :text)`).
- budget_variance: unchanged.
- clickstream_sessions: `class Event` / `class Session` with `attr_reader` (was `Struct.new` + a reopened `class Session`).
- cohort_retention: `class User` + `attr_reader`; `known = Array.to_set(Array.map(...))` (Ruby's `map(&:id).to_set`) instead of `Set[]` + `Array.each { Set.add }`.
- csv_import_validation: `class RowError < Exception` + `attr_reader line, column`; `class Order` + `attr_reader`.
- customer_dedupe: `class Contact` + `attr_reader`; `UnionFind` now `attr_reader parent = nil, size = nil` + `def initialize(uf)` creating the Hashes, called as `UnionFind.new` (Ruby's no-argument `initialize`), removing the `UnionFind.create` factory.
- employee_dept_join: `class Employee` / `class Department` + `attr_reader`; `used = Array.to_set(...)`.
- etl_star_schema: `class Fact` + `attr_reader`; `Dimension` gets `initialize` filling `by_natural`/`rows` and is built with `Dimension.new(name)` (was `Dimension.create`); `class LoadError_ < Exception` + `attr_reader`; `extract_web` uses a rescue clause on the `do` block (as the Ruby version) instead of `begin ... end` inside it.
- expense_pivot: `Pivot` `initialize` replaces `Pivot.create` (`Pivot.new`); `each_cons ... do |(am, at), (bm, bt)|` (nested destructuring) instead of two unpacking statements.
- fulfillment_report: `Product`, `Order`, `OrderLine`, `Shipment` as `class` + `attr_reader`; `order_ids = Array.to_set(...)`.
- fx_conversion: `class Txn` + `attr_reader`; `class RateMissing < Exception`; `date, *pairs = String.split(line)` (splat assignment) instead of `fetch(0)` + `drop(1)`; `reduce ... { |acc, (t, v, r)| ... }`; `Hash.sort_by(by_cur)` instead of `Array.sort_by(Hash.to_a(by_cur))`.
- grade_book: `class Assignment` / `class Student` + `attr_reader`; `each_with_index ... do |(name, s), i|`.
- groupby_query: `class Query` + `attr_reader`; `class QueryError < Exception`; `Hash.map(groups)`.
- inventory_diff: `class Item` / `class Change` + `attr_reader` (Ruby's hand-written `Item#==` is the Struct equality Sake gives by default, so not added).
- invoice_totals: `class LineItem` (fields + `total` in one class) and `class Invoice` with `attr_reader`.
- league_standings: `class Team` with `attr_reader` (Ruby has `attr_accessor`, but every write is `@x += ...` inside `record!`, so reader per the brief).
- metric_anomalies: `class Point` + `attr_reader`.
- quality_rules: unchanged (already `class` + `attr_reader` with `include Rule`).
- sales_by_region: `class Sale` + `attr_reader`; `parse_sales` is `Array.filter_map` with `next if` (as Ruby) instead of push into `Sale[]`; `Hash.map(by_region) do |region, list|` instead of `keys` + `fetch`; `|(rep, amt), i|` and `|product, (units, amt)|`.
- size_histogram: unchanged.
- survey_crosstab: unchanged.
- table_renderer: `class Column` + `attr_reader`; `value == nil || value == ""` (mixed-type `==` now works) instead of `(value in String) && String.empty?(value)`; `all_cells = body + Array[...]` (Array `+`) instead of `Array.dup` + `Array.push`.
- timesheet_payroll: `class Worker` / `class Shift` + `attr_reader`; `week, who, *rest = String.split(line)` instead of `take(2)` / `drop(2)`.
- top_products: `class Product` / `class Review` + `attr_reader`; `reviews` is `Hash.flat_map` + `Array.map` (as Ruby) instead of nested `each` pushing into `Review[]`; `each_with_index ... do |(p, s), i|`.

## Friction

- **Fields set only by `initialize`.** Ruby's `UnionFind.new` / `Pivot.new` / `Dimension.new(name)` take fewer
  arguments than there are fields, with `initialize` creating the empty Hash/Array. In Sake a field left out of
  `new` needs a literal default, and a Hash/Array is not a literal, so the fields are declared `= nil` only to be
  omittable and then overwritten: `customer_dedupe.sake:6`, `expense_pivot.sake:2`, `etl_star_schema.sake:6`. Wanted
  `attr_reader parent` with no constructor argument (or a non-literal default such as `= Hash[]`).
- **No `each_with_index.map` / `map.with_index`.** `table_renderer.sake:68` keeps a `with_index` helper built from
  `Array.zip` (used at :73, :79, :84); `league_standings.sake:47-51` (`ranks`) and `etl_star_schema.sake:72` (Ruby
  `each_with_index.map`) build the result by pushing in an `each_with_index` loop.
- **`Array.last(a, n)` takes no count.** `league_standings.sake:43` keeps `last_n` for Ruby's `form.last(5)`.
- **No block form of `to_h`.** Ruby's `products.to_h { |p| [p.sku, p] }` (fulfillment_report.sake:62), `line.split.to_h
  do ... end` (groupby_query.sake:23, quality_rules.sake:70) and `text.lines.to_h` (fx_conversion.sake:30) stay as
  `Hash[]` + a loop assigning keys. `Array.to_h(Array.map(...))` works (top_products.sake:43) but nests one level more.
- **`each_slice` / `each_cons` need a block.** Ruby's `rest.each_slice(2).map` (timesheet_payroll.sake:40-46) and
  `flat_map` over lines become `Array.each` + `Array.push(shifts, ...)` into a typed `Shift[]`.
- **Records read only by pattern.** One-line blocks over Records take a statement to read one field:
  `customer_dedupe.sake:115,122`, `survey_crosstab.sake:61,66,67` (`{ |r| r => {region:}; region }` for Ruby's `r[:region]`).

## Ruby comparison

- Every record type is still a `class` with an `attr_reader` line but no `initialize`; the Ruby versions spell out
  the same field order in `initialize(...)` and the assignments. Sake's `C.new` is positional over the field order.
- Field reads are `Type.get_field(x)` everywhere (`Request.get_status(it)` vs `r.status`); `&:field` has no form, so
  `reqs.sum(&:bytes)` becomes `Array.sum(reqs) { Request.get_bytes(it) }` (access_log_report.sake:61).
- Exception types are `class E < Exception` with `attr_reader`; Ruby needs `super(message)` in `initialize`, Sake puts
  `message` first implicitly (`RowError.new("...", line, col)` reads the same in both).
- The Ruby `Hash` results with Symbol keys (customer_dedupe, sales_by_region) are Records in Sake, taken apart with
  `r => {ids:, name:, ...}` instead of `r[:ids]`.
- Ruby constants (`LINE_PATTERN`, `DAY_SECONDS`) are zero-argument functions (`def line_pattern = /.../`); none in this
  domain builds a table worth `once`.
