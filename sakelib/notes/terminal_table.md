# terminal_table

`sakelib/terminal_table.sake`: render rows as a text table, after the terminal-table gem: headings, a
title, separators, per-column alignment, and three border styles (`:ascii` as the gem's default,
`:unicode` box drawing, `:markdown`). The reference is `test/sakelib/ref/terminal_table.rb`. 17
functions; the test prints 46 lines, identical to `terminal_table.rb`.

## API

| Ruby (terminal-table) | Sake | |
|---|---|---|
| `Terminal::Table.new(title:, headings:, rows:)` | `TerminalTable.new(title:, headings:, rows:)` | differs: no nested names |
| `style: {border: :unicode, alignment: :center}` | `border: :unicode, alignment: :center` | differs: two keywords |
| `t.add_row(row)`, `t << row`, `t.add_separator` | `TerminalTable.add_row(t, row)`, `TerminalTable.<<(t, row)`, `add_separator` | same |
| `t.align_column(i, :right)` | same | same |
| `t.to_s`, `puts t` | `to_s` of the type, `puts t` | same |
| `t.number_of_columns`, `title`, `headings`, `rows` | same | same |
| `Terminal::Table.new { \|t\| t << row }` (block form), multi-line cells, colspan, `style.width`, padding | | missing |

## What differs from Ruby, and why

- The style's border and alignment are fields given as keywords to `new`, not a `style:` Hash: a field
  is named in `new`, so a misspelled `bordr:` is an error before running.
- `Terminal::Table.new do |t| ... end` keeps the table in a block (`instance_eval`): not ported.
- Widths count characters: a wide (CJK) character counts as one column (the gem uses display width).
  The test's `日本` row shows the misalignment, in both outputs.
- The output follows the reference, not the gem byte for byte (the gem also needs its unicode-display_width).

## Friction

1. `Array.reject(@rows) { |r| r in Symbol }` → `--strict=2`: `Array.fetch: argument 1 must be Array, but can
   be :separator [mixed]`: narrowing inside a filter's block does not narrow the result's element type →
   `Array.filter_map(@rows) { |r| (r in Symbol) ? nil : r }`, where the `else` branch is narrowed.
2. The border characters as a Record per style, taken apart with a pattern:
   `chars(@border) => {h:, v:, top:, mid:, bottom:}` and `l, _, r = top`: no friction, and it reads like
   Ruby's Hash destructuring.
3. A separator is the Symbol `:separator` in the rows (rows are `Array | Symbol`), told apart with
   `if r in Symbol`.

## Language features used

- `T.new` keywords for all fields with defaults: `TerminalTable.new(title: "Population", headings: ...,
  rows: rows)`: the gem's own call shape; helped most here.
- `initialize` for validation (border, alignment, no title in markdown) and for copying the rows.
- Expression defaults (`headings = Array[]`, `rows = Array[]`, `border = :ascii`); `private attr_reader
  aligns = Hash[]`.
- Record pattern `=> {h:, v:, ...}`; `case a in :left ... in :center` (exhaustive over the literals).
- The type's own `to_s`, so `puts t` prints the table.

## Checker findings before the test passed

- `--strict=1`: the `[mixed]` warning of friction 1. `--strict=2`: the same, as an error.

## Types

- `TerminalTable.rows`: a union of Arrays of the test's rows (`Array[Integer | String]`, `Array[Float |
  Integer | nil]`, ...) and `:separator`; cells are shown with `Kernel.to_s`, which takes anything.
- `TerminalTable.border: Symbol`, `alignment: Symbol` (not literal unions: the error tests pass `:fancy`).
- partial: the three `case ... in :left` over an alignment whose type is `Symbol` (from those error
  tests), so the cases are reported only at `--strict=3` (`exhaustive`). No unknowns.
