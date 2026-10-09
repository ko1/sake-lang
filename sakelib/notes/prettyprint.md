# prettyprint (PrettyPrint)

`require "prettyprint"` → `sakelib/prettyprint.sake`. Test: `test/sakelib/prettyprint.{sake,rb}` (identical output:
Oppen's tree example from Ruby's own test at 24 widths, nested groups, tail groups, fill, nest, custom
separators and widths, another newline, single-line mode, `new`/`flush`).

Ruby's algorithm is ported line by line: a buffer of `Text` and `Breakable` entries, a stack of `Group`s and a
`GroupQueue` by depth that breaks the outermost group first. The printer `q` is a Struct type `PrettyPrint`;
Ruby's `q.text(s)` is `PrettyPrint.text(q, s)`. The nested classes `PrettyPrint::Text`, `::Breakable`, `::Group`,
`::GroupQueue` are the top-level types `Text`, `Breakable`, `Group`, `GroupQueue` (Sake has no nested names);
they are internal, as in Ruby.

## API

| Ruby | Sake | |
|---|---|---|
| `PrettyPrint.format(out = '', width = 79, nl = "\n", genspace) { \|q\| }` | `PrettyPrint.format(out = "", width = 79, nl = "\n") { \|q\| }` | same but `genspace` (indent is always spaces); `out` is a String |
| `PrettyPrint.singleline_format(out = '') { \|q\| }` | `PrettyPrint.singleline_format(out = "") { \|q\| }` | same output; `q` is a PrettyPrint in single-line mode, not a `SingleLine` (below) |
| `PrettyPrint.new(out = '', width = 79, nl = "\n", &genspace)` | `PrettyPrint.new(out = "", width = 79, nl = "\n", singleline = false)` | differs: 4th argument |
| `q.text(s, width = s.length)` | `PrettyPrint.text(q, s, width = String.length(s))` | same |
| `q.breakable(sep = ' ', width = sep.length)` | `PrettyPrint.breakable(q, sep = " ", width = ...)` | same |
| `q.fill_breakable(sep, width)` | `PrettyPrint.fill_breakable(q, sep, width)` | same |
| `q.group(indent = 0, open = '', close = '', open_w, close_w) { }` | `PrettyPrint.group(q, indent = 0, open = "", close = "", open_w, close_w) { }` | same |
| `q.group_sub { }` | `PrettyPrint.group_sub(q) { }` | same |
| `q.nest(indent) { }` | `PrettyPrint.nest(q, indent) { }` | same |
| `q.flush` | `PrettyPrint.flush(q)` | same |
| `q.output`, `q.maxwidth`, `q.newline`, `q.indent`, `q.group_queue` | `PrettyPrint.output(q)`, ... | same (readers) |
| `q.genspace` | — | missing: a lambda; indentation is `" " * n` |
| `q.current_group` | `PrettyPrint.current_group(q)` | same |
| `q.break_outmost_groups` | `PrettyPrint.break_outmost_groups(q)` | same (internal) |
| `PrettyPrint::SingleLine` | `PrettyPrint.singleline` (a flag) | differs, see below |
| `Group#break`, `break?`, `breakables`, `depth` | `Group.break(g)`, `break?`, `breakables`, `depth` | same (`Group.break(g)` is a fine qualified call although `break` is a keyword) |
| `Group#first?`, `SingleLine#first?` | — | missing: used by nothing in prettyprint; PP's `seplist` keeps its own flag |
| `Text#add`, `Text#output(out, w)`, `Breakable#output(out, w)` | `Text.add(t, s, w)`, `(Text\|Breakable).output(data, q, w)` | differs: takes the printer, not the output (below) |
| `GroupQueue#enq`, `deq`, `delete` | `GroupQueue.enq(gq, g)`, `deq`, `delete` | same |
| `PrettyPrint::VERSION` | — | missing (no value constants) |

16 operations of PrettyPrint, 13 of the internal types.

## What differs from Ruby and why

- **Single-line mode is a flag, not a class.** Ruby's `singleline_format` yields a `PrettyPrint::SingleLine`,
  which has the same methods and is used by the same block through duck typing. In Sake the block names the
  type of every call (`PrettyPrint.text(q, s)`), so a second type would need every block to be written for
  `(PrettyPrint|SingleLine).text(q, s)`. The flag keeps one API: `breakable` writes its separator, nothing is
  buffered, so `text` goes straight to the output and `group`/`nest` are harmless. The `first?` stack of
  `SingleLine` is not ported (nothing uses it).
- **Groups carry an `id`.** Ruby's `GroupQueue#delete` and `Breakable#output` use `Array#delete`, which for a
  Group means identity (no `==` defined). Sake's Struct `==` compares fields, so two open-and-empty groups at
  the same depth are equal and `Array.delete` would remove a sibling that still needs breaking. Each group gets
  a serial from the printer, and deletion is `Array.delete_if { Group.id(g) == id }`. (Checked afterwards:
  Struct `==` over the Group ↔ Breakable cycle does terminate; the problem is only the structural equality.)
- **`output(data, q, w)` takes the printer.** Ruby's `Breakable` keeps a reference to its printer (`@pp`) for
  the newline, the indentation and the group queue. Passing `q` at output time avoids a printer → buffer →
  breakable → printer cycle in the values (which `p` on a printer would follow forever).
- **The output is a String.** Ruby accepts anything with `<<`. Sake's version appends with `String.concat`; `pp`
  (the library) writes to an `IO` by building the String first.
- **`genspace`** is a lambda in Ruby; blocks are not values, so indentation is always `" " * indent`.
- **`PrettyPrint.new("", "wide")`** is a static `type` error at the `@maxwidth => Integer` line (hint: the
  caller's line). Ruby fails later, at the first comparison inside `breakable`.

## Built-ins Sake lacks (requests)

- None needed. (A `Record` cannot be iterated, but prettyprint does not need it; see `pp.md`.)

## Friction

- Wrote `Breakable.output(b, out, w)` with `@pp` like Ruby → nothing from the checker, but the value graph
  gets a cycle, and `Kernel.inspect` of a printer would never end → passed the printer as an argument instead
  (no message; a design choice after reading spec §8.1 on Struct equality).
- Expected `def break(g)` to be rejected (keyword) and wrote `break!` first → tried it afterwards: the definition
  and `Group.break(g)` are accepted, only the unqualified `break(g)` is the keyword → renamed back to Ruby's.
- `data = Array.shift(@buffer)` then `(Text|Breakable).output(data, ...)`: the shift result may be nil for the
  checker, so `data => Text | Breakable` is needed first (it is also the dispatch list). `Array.fetch(stack, -1)`
  for Ruby's `stack.last` for the same reason. Both fit the `--strict` rules, no messages at the end.
- A Ruby user's `q.text("x")` → `error: method call on a value `q.text` is not allowed / hint:
  PrettyPrint.text(q, "x") / hint: q.PrettyPrint.text("x")`: a good hint; every block in a port is this
  rewrite.
- What felt good: the whole algorithm, with its `ensure`s, nested yields (`group_sub(q) { nest(q, indent) {
  yield } }`), early `return` from inside two nested blocks (`GroupQueue.deq`) and `until` loops, ran
  identically to Ruby on the first run under `--strict`, with no report. `(Text|Breakable).width(data)` for two
  same-named fields reads naturally.
