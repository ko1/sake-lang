# csv

`sakelib/csv.sake` ports Ruby's `csv` (checked against csv 3.3.5 on Ruby 4.0.2): parsing (quotes, `""`
escapes, quoted newlines, `\r\n`/`\r` row separators, Ruby's error messages and line numbers),
the options people actually pass, headers (`CSVRow`, `CSVTable`), converters, generating, and files.
Test: `test/sakelib/csv.sake` vs `csv.rb` (identical output, `--strict`).

## Conventions

- **Keyword options become a Record argument of a `_with` operation.** Sake has neither keyword
  arguments nor optional parameters, so each Ruby method that takes options has two names:
  `CSV.parse(s)` and `CSV.parse_with(s, {col_sep: ";", headers: true})`. A field left out of the
  Record takes Ruby's default. The library reads the Record with `case o in {col_sep:} ... else ","`;
  the checker specializes this per Record type, so the type of the result follows the options given.
- **`headers:` decides the result type by its presence.** `CSV.parse_with(s, {headers: ...})` returns
  a `CSVTable`; without the field it returns an Array of rows. Both are known before running (the
  Record's type picks the branch), so there is no `Array | CSVTable` union at the call site.
- **Cells.** An unquoted empty field is `nil`, as in Ruby, so a row is an Array of `String | nil`
  (`String[]` cannot hold nil). With `converters:`, cells become `String | Integer | Float | nil`,
  and `--strict` asks for a `case`/`in` before arithmetic, which is the honest type.
- **Names.** `CSV::Row` → `CSVRow`, `CSV::Table` → `CSVTable`, `CSV::MalformedCSVError` →
  `MalformedCSVError` (no nested namespaces). Its `line_number` is a field:
  `MalformedCSVError.get_line_number(e)`; the message is Ruby's (`"Illegal quoting in line 2."`).
- `CSV` is a type: the writer that `CSV.generate { |csv| csv << row }` yields. `<<` is its operator
  (`include Bitwise`), so `csv << [1, "a"]` reads as in Ruby. Rows may be Arrays, Tuples, `CSVRow`s,
  or Hashes (with `headers:`).

## API

| Ruby | Sake | |
|---|---|---|
| `CSV.parse(s)` | `CSV.parse(s)` | same |
| `CSV.parse(s, **opts)` | `CSV.parse_with(s, {opts})` | differs (Record) |
| `CSV.parse(s, headers: true)` | `CSV.parse_with(s, {headers: true})` → CSVTable | differs (Record) |
| `CSV.parse(s) { \|row\| }` | — | missing (use `Array.each(CSV.parse(s))`) |
| `CSV.parse_line(s[, **opts])` | `CSV.parse_line(s)`, `CSV.parse_line_with(s, o)` | same / differs |
| `CSV.read(path[, **opts])`, `readlines` | `CSV.read(p)`, `read_with(p, o)`, `readlines`, `readlines_with` | same / differs |
| `CSV.foreach(path[, **opts]) { }` | `CSV.foreach(p) { }`, `CSV.foreach_with(p, o) { }` | same / differs |
| `CSV.table(path)` | `CSV.table(path)` | same |
| `CSV.generate { \|csv\| csv << row }` | same | same |
| `CSV.generate(**opts) { }` | `CSV.generate_with(o) { }` | differs |
| `CSV.generate(str) { }` (append to str) | — | missing |
| `CSV.generate_line(row[, **opts])` | `generate_line(row)`, `generate_line_with(row, o)` | same / differs |
| `CSV.generate_lines(rows[, **opts])` | `generate_lines`, `generate_lines_with` | same / differs |
| `CSV.open(path, "w"/"a") { \|csv\| }` | `CSV.open(path, mode) { }`, `open_with(path, mode, o) { }` | same (write modes only) |
| `CSV.open(path, "r")`, `CSV.new(io)`, `#shift`, `#gets`, `#each`, `#lineno` | — | missing |
| `csv << row`, `add_row`, `puts` | `csv << row`, `CSV.add_row(c, r)`, `CSV.puts(c, r)` | same |
| `"a,b".parse_csv`, `[..].to_csv` | `String.parse_csv(s)`, `Array.to_csv(a)`, `Tuple.to_csv(t)` | same |
| `Row.new(headers, fields)` | `CSVRow.new(hs, fs)` (no padding), `CSVRow.pad(hs, fs)` (Ruby's padding) | differs |
| `row[h]`, `row[i]`, `row[h] = v`, `row.field(h)` | same with `CSVRow.` / indexing | same |
| `row.fetch(h)` | `CSVRow.fetch(r, h)` (KeyError "key not found: h") | same |
| `row.fetch(h, default)`, `row.fetch(h) { }`, `row.dig` | — | missing |
| `headers fields to_a to_h to_hash each size length empty? index values_at delete << to_s to_csv == inspect` | `CSVRow.` same names (`values_at` takes an Array) | same |
| `header? has_key? include? key? member? field? header_row? field_row?` | same | same |
| `table.headers size length empty? each map select find to_a to_s to_csv delete values_at << push inspect` | `CSVTable.` same names (`values_at` takes an Array) | same |
| `table[i]`, `table[h]`, `table[i] = row`, `table[h] = v / [vs]` | same | same |
| `table.by_col`, `by_row`, `mode`, `dig`, `each` in column mode | — | missing |
| Enumerable on Table (`sort_by`, `group_by`, ...) | via `CSVTable.get_rows(t)` + Array ops | differs |

Options supported: parsing `col_sep` (any length), `row_sep` (`:auto` or a String), `quote_char`,
`headers` (`true`, Array/Tuple, or a header line String), `converters` (`:integer`, `:float`,
`:numeric`, `:all`, or a list of these), `header_converters` (`:downcase`, `:symbol`, `:symbol_raw`),
`skip_blanks`, `skip_lines` (Regexp), `nil_value`, `empty_value`; generating `col_sep`, `row_sep`,
`quote_char`, `force_quotes`, `quote_empty`, `headers`, `write_headers`.

## What differs from Ruby, and why

- `_with` names and Record options: no keyword arguments, no optional parameters (one name, one
  arity).
- **A misspelled option is silently ignored** (`{colsep: ";"}` parses with `,`). Ruby raises
  `ArgumentError: unknown keyword`. A function cannot list a Record's fields, so the library cannot
  check them.
- `headers: false` raises ArgumentError ("use CSV.parse"): the result type is chosen by the presence of
  the field, so `{headers: false}` would have to return a table.
- `CSVRow.new` is the Struct constructor and does not pad; `CSVRow.pad` does what Ruby's `Row.new` does.
- `CSV.read` of a missing file raises `IOError` (Ruby: `Errno::ENOENT`), as Sake's `File.read` does.
- `values_at` takes one Array (user functions have no rest parameters).

## Not ported, and why

- **Custom converters** (`converters: ->(f) { ... }`, `CSV::Converters[:x] = ...`): blocks are not
  values. Convert after parsing with `Array.map`.
- **`:date`, `:date_time`, `:time` converters**: no Date/DateTime type, and no `Time.parse`.
- **Reader objects** (`CSV.new(io)`, `shift`, `each`, `lineno`, `CSV.open(path, "r")`): the
  instance `read`/`readlines` would collide with the module functions `CSV.read(path)` of the same
  name in one namespace (it could dispatch on String vs CSV, but there is no IO type to read from
  either). `CSV.parse` / `CSV.foreach` cover the use.
- **Block form of `CSV.parse`**: a user function either always or never takes a block.
- `strip:`, `liberal_parsing:`, `field_size_limit:`, `return_headers:`, `write_converters:`,
  `write_nil_value:`, encodings, `CSV.instance`, `CSV.filter`, table column mode: not common enough
  for the time budget.

## Built-ins I would have used

- **A way to list a Record's fields** (or a checked "Record of these optional fields" type): an
  options Record with a misspelled field is silently ignored; Ruby rejects unknown keywords.
- **`String.index(s, t, start)` (or a StringScanner)**: the quoted-field parser walks `String.chars`
  one by one because there is no "find from position". 2000 rows with quoted fields parse in ~1.2 s
  (2000 plain rows, which take the `String.split` path, in ~0.2 s), on a shared machine (load ~16), so rough.
- **`File.delete`**: the test leaves `/tmp/sakelib_csv_test.csv` behind.
- **Typed Arrays with a union element type** (`(String|nil)[]`): rows are untyped Arrays because nil
  must fit; the previous CSV library in `experiments/2026-10-03-libraries/csvtable/` asked the same.

## Friction

- `require "csv"` in `test/sakelib/csv.sake` → the whole test failed with "undefined type or module
  `CSV`" on every line → the test is itself `csv.sake` next to the requiring file, so `require "csv"`
  finds the test, not `sakelib/csv.sake` (and stops at the cycle silently). Wrote
  `require "../../sakelib/csv"` instead. **Every group's test has this problem**; `require` could
  skip the requiring file itself, or `test/sakelib/` could use other names.
- `CSV.parse(s, col_sep: ";")` → "keyword arguments are not supported" → `CSV.parse_with(s, {col_sep: ";"})`.
- `case o in {converters: :numeric}` → "only Record patterns that bind fields are supported" →
  `in {converters:} then converters == :numeric ? ...`.
- `v in String ? a : b` (known Ruby precedence trap, noted by the csvtable author) → wrote
  `(v in String) ? a : b` throughout before running.
- Using results at `--strict` (what a user hits, not the library): `String.upcase(row[0])` after
  `CSV.parse` → "argument 1 may be nil (nil | String)"; `row["v"] + 1` after `converters: :numeric` →
  "the operands may be (nil, Integer), (String, Integer)". Both are true of Ruby's CSV as well
  (empty fields are nil; a converter leaves non-numbers as Strings); Sake makes them visible.
- Nothing in the library needed a change for `--strict` (level 2) once written. At `--strict=3` the
  test gets 16 `index-nil` reports, all located inside `sakelib/csv.sake`: 2 are the parser's
  `chars[i]` lookups, and 14 come from the test's `r = t[0]` (a CSVRow or nil) reaching
  `CSVRow.get_fields` etc. Those 14 are the caller's nil, but the message points into the library
  (the "reached by" hint names the call).

## Surprises

- Record options worked better than expected: the checker specializes per Record shape, so
  `{headers: true}` gives a `CSVTable` and `{converters: :numeric}` adds Integer | Float only where
  it is given.
- A user-defined `[]` that returns a row for an Integer and a column for a String is typed per call
  (`t[0]` is a CSVRow, `t["age"]` an Array), with no union.
