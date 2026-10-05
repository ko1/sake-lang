# Notes: data processing and reports (corpus-v2)

17 of 25 programs changed; all exit 0 and match `<slug>.out` with `bin/sake --strict=0`.

Still worked around:
- **Nested block destructuring** (`|(rep, amt), i|`, `|(am, at), (bm, bt)|`, `|acc, (t, v, r)|`) is rejected
  ("nested destructuring `(a, b)` is not supported"), so `each_with_index` over pairs and `reduce` over triples
  still take the element apart in a separate statement (sales_by_region, grade_book, fx_conversion, access_log_report).
- **Splat in multiple assignment** (`week, who, *rest = tokens`, `date, *pairs = line.split`) has no form;
  written as `Array.take`/`Array.drop` (timesheet_payroll, fx_conversion).
- **Mixed-type `==`**: `value == ""` on Integer | Float | String still raises
  `TypeError: Kernel.==: no implementation for (Integer, String)`; table_renderer keeps
  `(value in String) && String.empty?(value)`. Repro: `x = Array.first(Array[1, 2]); p(x == "")`.
- **Array `+`** is not defined (`Array[1] + Array[2]` -> TypeError), so `body + [totals]` stays `Array.dup` + `Array.push`.
- **Index iteration in `map`**: no `each_with_index.map` / `map.with_index`; table_renderer keeps its
  `with_index` helper built from `Array.zip`.
- **`Array.last(a, n)`** takes no count; league_standings keeps its `last_n` helper.
- **Record fields** are still read only by pattern, so one-line blocks become `{ |r| r => {region:}; region }`
  (survey_crosstab, customer_dedupe).
- Formatting that really differs by type (`show`/`cell` printing a Float with `%.2f` and an Integer with `to_s`)
  stays a `case ... in Float ... in Integer`; `(A|B).f` only helps when the same-named operation is wanted.

No interpreter bugs found in this round; the `Array.join` crash noted in v1 no longer reproduces.
