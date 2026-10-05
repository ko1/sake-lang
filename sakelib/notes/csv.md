# csv

`sakelib/csv.sake` ports Ruby's `csv` (checked against csv 3.3.5 on Ruby 4.0.2): parsing (quotes, `""`
escapes, quoted newlines, `\r\n`/`\r` row separators, Ruby's error messages and line numbers),
the options people actually pass, headers (`CSVRow`, `CSVTable`), converters, generating, and files.
Test: `test/sakelib/csv.sake` vs `csv.rb` (identical output, `--strict`).

## Conventions

- **Keyword arguments**, as in Ruby: `CSV.parse(s, col_sep: ";", headers: true)`. Each option is a
  keyword parameter with Ruby's default (phase 1 had `_with` names, phase 2 an optional Record).
  A misspelled keyword is a static error (see "Keyword arguments" below).
- **`headers:` decides the result type.** Its default is nil (Ruby's is false; both mean "no
  headers"), and nil is a type of its own, so `case headers in nil` selects the branch when the
  program is checked: `CSV.parse(s)` is an Array of rows, `CSV.parse(s, headers: true)` a
  `CSVTable`, with no `Array | CSVTable` union at the call site. `true` and `false` share one type,
  so `headers: false` cannot select Arrays; it raises ArgumentError ("omit headers:").
- **Cells.** An unquoted empty field is `nil`, as in Ruby, so a row is an Array of `String | nil`
  (`String[]` cannot hold nil). With `converters:`, cells become `String | Integer | Float | nil`,
  and `--strict` asks for a `case`/`in` before arithmetic, which is the honest type.
- **Names.** `CSV::Row` → `CSVRow`, `CSV::Table` → `CSVTable`, `CSV::MalformedCSVError` →
  `MalformedCSVError` (no nested namespaces). Its `line_number` is a field:
  `MalformedCSVError.line_number(e)`; the message is Ruby's (`"Illegal quoting in line 2."`).
- `CSV` is a type: the writer that `CSV.generate { |csv| csv << row }` yields. `<<` is its operator
  (`include Bitwise`), so `csv << [1, "a"]` reads as in Ruby. Rows may be Arrays, Tuples, `CSVRow`s,
  or Hashes (with `headers:`).

## API

| Ruby | Sake | |
|---|---|---|
| `CSV.parse(s)` | `CSV.parse(s)` | same |
| `CSV.parse(s, col_sep: ";", ...)` | `CSV.parse(s, col_sep: ";", ...)` | same |
| `CSV.parse(s, headers: true)` | `CSV.parse(s, headers: true)` → CSVTable | same |
| `CSV.parse(s, **opts) { \|row\| }` | `CSV.parse(s, **opts) { \|row\| }` | same (phase 3, `block_given?`): yields Arrays, or CSVRows with `headers:`, and gives nil |
| `CSV.parse_line(s, **opts)` | `CSV.parse_line(s, **opts)` | same (only the first row is parsed, as Ruby); no `headers:` / `header_converters:` |
| `CSV.read(path, **opts)`, `readlines` | `CSV.read(p, **opts)`, `readlines(p, **opts)` | same |
| `CSV.foreach(path, **opts) { }` | `CSV.foreach(p, **opts) { }` | same |
| `CSV.foreach(path, mode, **opts) { }` | `CSV.foreach(path, mode, **opts) { }` | same (phase 3); the file is read whole, not streamed |
| `CSV.foreach(path)` without a block (Enumerator) | — | missing (no Enumerators) |
| `CSV.table(path)` | `CSV.table(path)` | same |
| `CSV.generate { \|csv\| csv << row }` | same | same |
| `CSV.generate(**opts) { }` | `CSV.generate(**opts) { }` | same |
| `CSV.generate(str, **opts) { }` | `CSV.generate(str, **opts) { }` | same result; `str` itself is not changed |
| `CSV.generate_line(row, **opts)` | `CSV.generate_line(row, **opts)` | same |
| `CSV.generate_lines(rows, **opts)` | `CSV.generate_lines(rows, **opts)` | same |
| `CSV.open(path, "w"/"a", **opts) { \|csv\| }` | `CSV.open(path, mode, **opts) { }` | same (phase 3): rows go to the file's IO as they are added; the file is closed after the block, whose value is returned |
| `csv = CSV.open(path, "w")`, `csv.close` | `c = CSV.open(path, "w")`, `CSV.close(c)` | same (phase 3) |
| `CSV.open(path, "r")`, `CSV.new(io)`, `#shift`, `#gets`, `#each` | — | missing: `CSV.open` with a read mode raises ArgumentError; read with `CSV.read`/`foreach`/`parse` |
| `csv.lineno`, `csv.inspect` | `CSV.lineno(c)`, `CSV.inspect(c)` | same for writers (the StringIO's `encoding:` is not shown) |
| `csv << row`, `add_row`, `puts` | `csv << row`, `CSV.add_row(c, r)`, `CSV.puts(c, r)` | same |
| `"a,b".parse_csv`, `[..].to_csv` | `String.parse_csv(s)`, `Array.to_csv(a)`, `Tuple.to_csv(t)` | same |
| `Row.new(headers, fields)` | `CSVRow.new(hs, fs)` | same (2026-10-05: copies and pads in `initialize`; `CSVRow.pad` is gone) |
| `row[h]`, `row[i]`, `row[h] = v`, `row.field(h)` | same with `CSVRow.` / indexing | same |
| `row.fetch(h)` | `CSVRow.fetch(r, h)` (KeyError "key not found: h") | same |
| `row.fetch(h, default)`, `row.fetch(h) { }`, `row.dig` | — | missing |
| `headers fields to_a to_h to_hash each size length empty? index values_at delete << to_s to_csv == inspect` | `CSVRow.` same names (`values_at` takes an Array) | same |
| `header? has_key? include? key? member? field? header_row? field_row?` | same | same |
| `table.headers size length empty? each map select find to_a to_s to_csv delete values_at << push inspect` | `CSVTable.` same names (`values_at` takes an Array) | same |
| `table[i]`, `table[h]`, `table[i] = row`, `table[h] = v / [vs]` | same | same |
| `table.by_col`, `by_row`, `mode`, `dig`, `each` in column mode | — | missing |
| Enumerable on Table (`sort_by`, `group_by`, ...) | via `CSVTable.rows(t)` + Array ops | differs |

Options supported: parsing `col_sep` (any length), `row_sep` (`:auto` or a String), `quote_char`,
`headers` (`true`, Array/Tuple, or a header line String), `converters` (`:integer`, `:float`,
`:numeric`, `:all`, or a list of these), `header_converters` (`:downcase`, `:symbol`, `:symbol_raw`),
`skip_blanks`, `skip_lines` (Regexp), `nil_value`, `empty_value`; generating `col_sep`, `row_sep`,
`quote_char`, `force_quotes`, `quote_empty`, `headers`, `write_headers`.

## What differs from Ruby, and why

- **Keyword arguments.** In the table, `**opts` stands for the keywords listed above, not a rest
  parameter. Each function takes the keywords that apply to it: parsing ones for `parse`, `read`,
  `readlines`, `foreach` (and `parse_line`, without `headers:`/`header_converters:`), writing ones
  for `generate*` and `open`. Ruby accepts every option everywhere. An unknown keyword is a static
  error, where Ruby raises `ArgumentError: unknown keyword` while running and the former Record
  argument ignored it: `CSV.parse(s, col_seps: ";")` → `error: CSV.parse has no keyword parameter
  `col_seps`` / `hint: did you mean `col_sep:`?`.
- `headers: false` raises ArgumentError ("omit headers:"): `true` and `false` are one type, so a
  `false` could not give an Array where `true` gives a table.
- ~~`CSV.foreach(path, mode)` has no mode argument.~~ It has one (phase 3).
- ~~`CSVRow.new` is the Struct constructor and does not pad.~~ It pads in `initialize` (2026-10-05).
- `CSV.read` of a missing file raises `IOError` (Ruby: `Errno::ENOENT`), as Sake's `File.read` does.
- `values_at` takes one Array (user functions have no rest parameters).

## Not ported, and why

- **Custom converters** (`converters: ->(f) { ... }`, `CSV::Converters[:x] = ...`): blocks are not
  values. Convert after parsing with `Array.map`.
- **`:date`, `:date_time`, `:time` converters**: no Date/DateTime type, and no `Time.parse`.
- **Reader objects** (`CSV.new(io)`, `shift`, `each`, `lineno`, `CSV.open(path, "r")`): the
  instance `read`/`readlines` would collide with the module functions `CSV.read(path)` of the same
  name in one namespace (it could dispatch on String vs CSV; an IO type exists since phase 3, but
  `CSV.new` is the Struct's constructor). `CSV.parse` / `CSV.foreach` cover the use.
- ~~**Block form of `CSV.parse`**: a user function either always or never takes a block.~~ Ported
  in phase 3 with `block_given?`.
- `strip:`, `liberal_parsing:`, `field_size_limit:`, `return_headers:`, `write_converters:`,
  `write_nil_value:`, encodings, `CSV.instance`, `CSV.filter`, table column mode: not common enough
  for the time budget.

## Built-ins I would have used

- ~~A way to list a Record's fields~~: keyword parameters now check option names.
- ~~`String.index(s, t, start)`~~: added; phase 2 parses with `Regexp.match(re, s, pos)`.
- ~~`File.delete`~~: added (the test still leaves `/tmp/sakelib_csv_test.csv`: the .rb must print the same).
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
  `CSVRow.fields` etc. Those 14 are the caller's nil, but the message points into the library
  (the "reached by" hint names the call).

## Surprises

- Record options worked better than expected: the checker specializes per Record shape, so
  `{headers: true}` gives a `CSVTable` and `{converters: :numeric}` adds Integer | Float only where
  it is given.
- A user-defined `[]` that returns a row for an Integer and a column for a String is typed per call
  (`t[0]` is a CSVRow, `t["age"]` an Array), with no union.

## Phase 2

- **Names.** The `_with` operations are gone: `parse`, `parse_line`, `read`, `readlines`, `foreach`,
  `generate`, `generate_line`, `generate_lines`, `open` take the options as an optional last Record
  (`o = nil`). The test now calls the Ruby-shaped forms and adds `generate_lines`/`readlines` with
  options.
- **Parser.** The record splitter (`String.split` by row_sep, re-joining pieces while a quote is open,
  re-parsing the joined text) and the per-character quoted-field loop (`String.chars`, `field + c`)
  are replaced by one pass over the text: per field one `Regexp.match(re, text, pos)` with
  `\G(?:"((?:[^"]++|"")*+)"|((?:(?!SEP|ROWSEP)[^"])*+))(SEP|ROWSEP|\z)?`, built from the options. A
  missing delimiter group names the error (quoted field followed by text, quote inside an unquoted
  field, unclosed quote).
- **Fixed on the way.** Error line numbers now count records, as Ruby's lineno (phase 1 counted
  row_seps, so an error after a multi-line quoted field was off; new tests). `parse_line` stops after
  the first row, as Ruby (a malformed second line no longer raises).
- **Speed** (`experiments/2026-10-03-sakelib-port/phase2/bench_csv.sake`: `CSV.parse` of 2000 rows of
  5 fields, 3 quoted, one with `""` and a comma; `bin/sake --strict`, CPU user+sys, 3 runs, shared
  machine at load ~35 on 16 cores): before 5.36 / 5.87 / 5.94 s, after 2.61 / 2.50 / 2.44 s. Startup is ~0.7 s.

## Keyword arguments

- `parse`, `parse_line`, `read`, `readlines`, `foreach`, `generate`, `generate_line`,
  `generate_lines`, `open` take Ruby's keywords instead of `o = nil`; `generate` gained Ruby's
  leading `str`. The `opt_*` readers are gone: the API passes the values to the helpers, with one
  internal Record `{nil_value:, empty_value:, converters:}` for the per-row conversion. The test and
  `csv.rb` write the same calls, plus a "keyword arguments" section (keywords in another order,
  `open`/`foreach` with `col_sep: ";"` and headers, `generate(str, ...)`).
- The default `headers: nil` (not false) is what keeps the result type static; see Conventions.

## IO and optional blocks (phase 3)

- `CSV.open(path, mode = "r", **opts)` opens the file with `File.open(path, mode)`, and `csv << row`
  (or `CSV.add_row`, `CSV.puts`) writes each line to that IO; phase 2 collected the lines and wrote
  them after the block, and appended by reading and rewriting the file. With a block the file is
  closed after it and the block's value is returned; without one the writer is returned, to be
  closed with `CSV.close`. Any mode starting with "w" or "a" is accepted.
- `CSV.parse(s) { |row| }` and `CSV.foreach(path, mode = "r", ...)`: `parse` checks `block_given?`.
  `foreach` reads through `File.open` + `IO.read`, not `IO.each_line`: a quoted field may span lines
  and the error messages count lines over the whole text, so line-by-line reading would need a
  resumable parser.
- `return result unless block_given?` left the rest of the function typed for the block-less call
  (result `nil | Array`, and a `yield` there "no block is given"); `if block_given? ... else ... end`
  works (`csv_bug_return_unless_block_given.sake`).
- Not done: reading through a CSV object (`CSV.new(io)`, `CSV.open(path, "r")`, `shift`, `each`).
  `CSV.new` is the Struct's constructor, so it cannot take an IO and options.
- The test's new section uses `csv_test_io.tmp` in the test directory, deleted by both programs.

## Review against the 2026-10-05 language

- `MalformedCSVError` is `class MalformedCSVError < Exception` with `attr_reader line_number` (was
  `Exception.new(:line_number)`), as Ruby's class.
- `CSVRow.new(headers, fields)` copies both Arrays and pads the shorter with nil in `initialize`, as
  Ruby's `Row.new`; `CSVRow.pad` and the callers' `Array.dup` are gone.
- Keywords passed on with the `k:` shorthand (`read`, `readlines`, `foreach`); `foreach` and
  `CSVTable.each/map/select/find` pass their block on with `&b`.
- Still unlike Ruby: no `**opts`, so `read`/`readlines`/`foreach` repeat the 11 keywords
  (csv.sake:199-220); `CSV.new` is the Struct constructor (9 positional fields), so `writer`
  (csv.sake:273) stands in for Ruby's `CSV.new(io, **opts)`.
