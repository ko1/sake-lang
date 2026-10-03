# csvtable: a CSV + text-table library in Sake

Files: `lib.sake` (library), `client_sales.sake` (typical: sales report), `client_clean.sake`
(cleaning pass: trim, convert, report bad rows/cells, write back), `client_pivot.sake` (stress/unusual:
generate 2000 rows, round-trip, region x quarter pivot), `client_edge.sake` (CSV edge cases, mixed
cells), `client_timing.sake` (per-phase time on 2000 rows), `build.sh` (concatenates lib + client into
`out/`), `bug_types_raise_error.sake` (repro). Outputs of the last run: `out/client_*.txt`.

All five clients run cleanly with `bin/sake --strict out/X.sake` (level 2). No level-2 report had to
be left in place.

## API sketch

```ruby
CsvError = Exception.new(:line)                       # message, line
Csv.parse(text)        # -> Array of String[] rows; quotes, "" escapes, quoted newlines, CRLF
Csv.generate(rows)     # rows of cells -> CSV text (quotes only when needed)
Num.parse(s)           # "1,234" / "$12.50" / "3" -> Integer | Float | nil
Num.format_int(n)      # 1234567 -> "1,234,567";  Num.format_float(x, digits)

class Table < {reader: [headers, rows]}               # a cell: String | Integer | Float | nil
Table.from_csv(text) / Table.from_csv_lenient(text, problems)   # problems: Tuple[] of [line, msg]
Table.index_of(t, name)  Table.cell(t, row, name)  Table.column(t, name)  Table.size(t)
Table.string_at(t, row, name) -> String     Table.number_at(t, row, name) -> Float   # raise TypeError
Table.select(t, names)  Table.filter(t) { |row| }  Table.sort_by_column(t, name, descending)
Table.map_column!(t, name) { |cell| }   Table.group_sum(t, key, value_cols)
Table.render(t, digits)  # aligned text table: header, rule, numbers right-aligned with separators
Table.to_csv(t)
```

## Friction log

- [missing-builtin] `w = Integer.max(w, String.size(c))` → "undefined function `Integer.max`" with
  "hint: `max` is defined in `Array.max`, `Range.max`, `Set.max`" → yes → `n = ...; w = n if n > w`
  → 1. (Ruby has no `Integer#max` either; the hint was exactly right.)
- [type-check-caught-bug] `Csv.parse` built each row as `String[]`; `Table.map_column!` then wrote
  numbers into those rows: `r[i] = yield(r[i])` → "Indexable.[]=: an element must be String, but is
  Float | Integer | nil" (reported in the lib, "reached by the call at line 282") → yes → `from_csv`
  copies rows into plain Arrays (`Array.map(r) { it }`) → 1. This would have been a runtime
  TypeError on the first conversion. The best moment of the session.
- [type-check-caught-bug] `Array.shift(all)` after an `Array.empty?` check → "Array.size: argument 1
  may be nil (nil | String[]@L15 | String[]@L49) [nil]" → yes → `raise ... unless header` on the
  local → 1. The emptiness check does not narrow `shift`, which is fair.
- [language-limit] After `Table.map_column!(t, "units") { |s| Num.parse(s) }`, the same call for
  `"price"` → "String.strip: argument 1 must be String, but can be Float | nil | Integer" → partly
  (true for the program as typed, but the price column was all Strings at that moment) → every
  conversion block became `{ |s| (s in String) ? Num.parse(s) : s }` → 1. All cells of all rows share
  one element type, so converting one column changes the type of every column. This is the core cost
  of "rows of mixed column types": there is no way to say "column 3 is Float".
- [language-limit] `r[ui] * r[pi]` on converted cells → "Arithmetic.*: the operands may be (Float,
  nil), (Float, String), (nil, Float), (nil, nil), (nil, Integer), (nil, String), (Integer, nil),
  (Integer, String), (String, Float), (String, nil), (String, String), which the left operand's type
  does not support" → yes, but the 11-pair list is hard to read; "the left operand may be nil or
  String" would say it → added typed accessors to the library (`Table.number_at`,
  `Table.string_at`, which narrow with `case`/`raise` and return one type) → 1.
- [language-limit] `String.include?(Table.cell(sales, r, "product"), "Widget")` → "argument 1 must be
  String, but can be Float | nil | Integer" → yes → `Table.string_at` → 1 (same fix as above).
- [ruby-habit] `{ |s| s in String ? Num.parse(s) : s }` → four raw parser errors "syntax error:
  unexpected '?', expecting end-of-input" / "unexpected ':'" → partly (no hint; Ruby rejects it too)
  → `(s in String) ? ... : s` → 1.
- [ruby-habit] `Array.reject(Array.each_with_index(rows).to_a) { ... }` (enumerator chain) →
  "Array.each_with_index requires a block" plus "method call on a value ... .to_a" with six `to_a`
  hints (Tuple/Hash/MatchData/Range/Set...) → yes for the first, the six hints were noise → explicit
  `Array.each_with_index(...) { |r, n| Array.push(kept, r) unless ... }` → 1.
- [ruby-habit] `r[i] == nil || r[i] in Integer | Float` parses as `(r[i] == nil || r[i]) in
  Integer | Float` (Ruby precedence) → no message; numeric columns with an empty cell were silently
  left-aligned → found by reading the table output → parenthesize → 1. Not detectable as written
  (`true in Integer` is legal), but `in` with a Boolean | T left side might deserve a lint.
- [type-check-caught-bug] pivot: `Integer.to_i(Table.number_at(t, r, "month"))` → "Integer.to_i:
  argument 1 must be Integer, but is Float" → yes (I forgot my own accessor returns Float) →
  `Float.to_i` → 1.
- [tooling] Every message points into `out/<client>.sake`; client lines are offset by the lib length
  (305 at the end). `build.sh` prints "client starts at line N" so I could subtract by hand. Name
  clashes are reported well: a client redefining `Num.parse` gets "`Num.parse` is already defined at
  line 124", and `Table.set_rows` from a client gets "field `rows` of Table is read-only (reader)".
- [message] `bin/sake --types`: every `raise` that can reach the top level is listed as
  `error   L64 raise arg CsvError: want a rescue, got CsvError`, and counted in `error=9`, though the
  tutorial defines "error" as "the check always fails" and the program is accepted at level 2 (it is
  only an `[unrescued]` report at level 4). Repro: `bug_types_raise_error.sake` (`error=1` for a raise
  that is never even reached). Also its `partial ... Arithmetic.+ arg pair: want table row` uses "table
  row" for the operator table, which collided confusingly with my own "table rows".
- [missing-builtin] number conversion: `Kernel.Integer("thirty")` raises and `String.to_i("thirty")`
  is 0, with no `exception: false` (no keyword args). I wrote `Num.parse` with two regexps
  (`/\A[-+]?\d+\z/`, a float regexp) returning `Integer | Float | nil`. That worked well, and the nil
  in the result type is then enforced at level 2, which is what a cleaning pass wants.
- [tooling] Speed: the char-by-char parser took several seconds for 2000 rows (55 KB). I added a fast
  path (records without quotes go through `String.split(rec, ",", -1)`, and only quoted records go
  through the state machine). The machine was shared (load average ~31), so these numbers are rough:
  parse of 2000 all-quoted rows went from ~7 s to ~1.4 s, `render` ~0.9 s, whole pivot client ~20 s
  wall before the fast path. Not a careful benchmark.

Runtime-only mistakes the checker could not have caught: the precedence one above, a bad PRNG in the
pivot generator (`seed % 4` of a power-of-two LCG is constant), and a test row with an unquoted
`1,204.0` that `from_csv` rejected for width (which led to `from_csv_lenient`).

## What felt good

- The `String[]` row caught a real design bug (rows typed as Strings, then filled with numbers) before
  running, and pointed at the line inside the library with the client call as a hint.
- `Num.parse` returning `Integer | Float | nil` is natural, and level 2 then makes every consumer
  deal with the nil. `case v in nil / String / Integer / Float` in `format_cell`, `cell_text`,
  `sort_key` reads well and is exhaustive by construction.
- `Tuple[]` for `[line, message]` problems and `Issue[]` (a Struct) for bad cells: pushes are
  checked, and `Array.each(problems) { |line, msg| ... }` destructures.
- `reader:` on `Table`: the client cannot `Table.set_rows`, and the error says what to do instead.
  `def Table.width(t) = ...` from a client extends the type with no ceremony.
- Tuple sort keys (`[1, Integer.to_f(v), ""]`) let `sort_by_column` sort a mixed column (nil, numbers,
  strings) without a comparator callback.
- `client_edge.sake` (CRLF, quoted newlines, `""`, empty fields, mixed cells) passed level 2 on the
  first try.

## What felt bad (top 3)

1. **Mixed column types collapse to one cell type.** Every cell is `String | Integer | Float | nil`
   everywhere, so each use needs a `case`/`in` or a library accessor that raises. Cost: 3 of the 5
   first-run errors, the two `string_at`/`number_at` functions (~20 lines), and a `(s in String) ? ...
   : s` guard in each of 5 conversion blocks. In Ruby I would just write `r[ui] * r[pi]`.
2. **No per-file library.** Concatenation works, but every message is in `out/` line numbers, offset
   by 305 lines. Small, constant friction on every error (maybe 10 s each, ~15 messages).
3. **Interpreter speed for character-level work.** A straightforward state machine was too slow for a
   2000-row file, so the parser gained a second (split-based) path, ~25 lines, which is code that
   exists only for speed.

## Library design under Sake

- **Rows are plain Arrays of a union cell type, not typed.** A typed element can only be a built-in
  type or a Struct, so there is no `Cell[]` or "Array of String[]". In Ruby I would do the same, but
  there the union is invisible; here it shows up at every use site, so the API grew typed accessors
  (`string_at`, `number_at`) that Ruby would never need.
- **Callbacks via `yield` worked fine** for `filter` and `map_column!`. What I could not offer is a
  stored formatter/converter per column (e.g. `Table.render(t, formats: {price: ->(x) {...}})`): blocks
  are not values and there are no keyword arguments. Formatting options became one positional
  `digits` argument; alignment is automatic (all-number column → right).
- **No `Enumerable`-style row objects.** In Ruby rows would be `CSV::Row` / hashes with
  `row["price"]`. A per-file Struct cannot be generated from the header at run time, so rows are
  index-addressed and names go through `Table.index_of`. A Hash row would have the same union-value
  problem.
- **`descending` is a positional Boolean** (`sort_by_column(t, "revenue", true)`) because there are no
  keyword arguments; at the call site `true` says little.
- **Lenient parsing takes an out-parameter** (`problems = Tuple[]`) rather than returning a pair, so
  the element type is declared by the caller and checked on each push. A Tuple return
  `[table, problems]` would also have worked.
- **Exceptions:** `CsvError = Exception.new(:line)` carries the line as a typed field; nice compared
  with parsing the message.

## Numbers

- Lines (incl. comments/blank): lib 329 (272 non-blank/comment), clients 86 + 73 + 34 + 32 + 29 = 254.
- Static errors before each program ran clean:

  | Program | Mine (incl. habits) | False reports | Notes |
  |---|---|---|---|
  | lib (alone) | 1 (`Integer.max`) | 0 | |
  | client_sales | 2 + 8 syntax lines from one habit | 0 | plus 3 "language-limit" union reports (correct for the types, not for the data) |
  | client_clean | 2 (one habit, two messages) | 0 | then 1 runtime CsvError from my test data |
  | client_pivot | 1 (caught bug) | 0 | |
  | client_edge, client_timing | 0 | 0 | |

  Caught real bugs: 3 (String[] rows, unchecked `shift`, Integer/Float accessor). Strict false reports:
  0, if the union reports count as honest; 1 if you count the `price` conversion (the data could not
  have been a number there, but nothing in the types says so).
- Level-2 reports I could not remove: none. At `--strict=3` each program has 9–13 `index-nil`
  reports (`chars[i]`, `widths[i]`, `cells[i]`); I did not pursue them.

## Suggestions

1. **A way to give an Array a union element type**, e.g. `(String|Integer|Float)[]`, or an Array of a
   typed Array (`String[][]`). It would not solve per-column types, but would let `Csv.parse` return
   rows whose cell type is declared where they are made (friction: String[] rows, mixed columns).
2. **Shorter union-operand messages**: instead of listing 11 operand pairs, say which side may be what
   ("the left operand may be nil or String; the right may be nil or String") (friction: `r[ui] * r[pi]`).
3. **Several files, or at least `# line` remapping**: a `--prelude lib.sake` option, or honoring a
   `#line 1 "client.sake"` marker emitted by a build script, so messages point at the source file
   (friction: out/ line numbers).
4. **`--types` should not label unrescued raises as `error`**, or should put them in their own
   category (e.g. `raises`), and avoid "table row" for the operator table (friction: `--types`,
   repro `bug_types_raise_error.sake`).
5. **A non-raising number conversion**, e.g. `String.to_i?`/`Kernel.Integer?` returning `Integer | nil`
   (Ruby's `Integer(s, exception: false)` without keyword args), so data cleaning does not need
   hand-written regexps (friction: number conversion).
