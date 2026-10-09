# awesome_print (ap / ai)

`require "awesome_print"` → `sakelib/awesome_print.sake`. Test: `test/sakelib/awesome_print.{sake,rb}` (identical
output). The gem is not installed, so the Ruby side is `test/sakelib/ref/awesome_print.rb`, a plain-Ruby rewrite of
the gem's formatters (Inspector, Formatter, ArrayFormatter, HashFormatter, Indentator, Colors, awesome_print 1.9)
for Arrays, Hashes and scalars, written from the gem's source as remembered, **not checked against the gem**.
The layout rules it encodes (indices right-aligned to the widest, keys right-aligned to `max key width +
indentation`, `outdent` of the closing bracket, `plain_single_line` keys, `[ a, b ]` / `{ k => v }` on one line,
the `\e[1;Nm` / `\e[0;Nm` colour codes per type) are the gem's; a case the gem formats differently would be a
bug in both files at once.

`AwesomePrint.ai(v, options...)` gives the String (Ruby: `v.ai(options)`); `AwesomePrint.ap(v, options...)`
prints it and gives `v` back (Ruby: `ap v`). The options are keyword parameters, which read as the gem's option
Hash: `AwesomePrint.ai(h, plain: true, indent: 2)`.

## API

| Ruby (awesome_print gem) | Sake | |
|---|---|---|
| `ap(obj, options = {})` → obj | `AwesomePrint.ap(v, indent: 4, plain: false, index: true, multiline: true, sort_keys: false, ruby19_syntax: false)` → v | same |
| `obj.ai(options = {})` → String | `AwesomePrint.ai(v, ...)` → String | same (a module function, no method on the value) |
| `indent:` (negative: left-aligned keys; 0: after the indent) | `indent:` | same |
| `plain:` | `plain:` | same; without it colours are always written (the gem checks `STDOUT.tty?`; see below) |
| `index:`, `multiline:`, `sort_keys:`, `ruby19_syntax:` | the same keywords | same |
| `html:`, `limit:`, `raw:`, `color: {type => name}`, `object_id:` | — | missing |
| Array → `[0] item` lines | `in Array`, `in Tuple` (as its Array), `in Set` (as its Array, as the gem) | same |
| Hash → `key => value` aligned | `in Hash`; a Record as `Record.to_h` (Symbol keys) | same |
| String, Symbol, Integer, Float, Rational, nil, true, false | `Kernel.inspect` / `to_s` with the gem's colour per type | same |
| Range, Regexp, Complex, Time | `Kernel.inspect`, no colour | same for Range/Regexp/Complex; the gem formats Time with `strftime` in green |
| Struct instances (StructFormatter: members one per line) | `Kernel.inspect` in the `struct` colour, one piece | differs |
| arbitrary objects (ObjectFormatter: `@ivar = value` lines), Class, Method, File, Dir, BigDecimal | — | missing: no reflection on a value; nothing but Struct types exist |
| `ap obj.methods` (the methods table) | — | missing (no `methods`) |
| `AwesomePrint.defaults`, `~/.aprc`, `AwesomePrint.force_colors!`, `Kernel#ai` monkey patch, IRB/Pry/Rails hooks | — | missing |

2 module functions with 6 options; the walk is 11 operations of the Struct type `AwesomeInspector`.

## できたこと / できなかったこと

- **Done.** The layout for every built-in value: arrays, hashes with any key type (a Tuple key prints as `[ 1, 2 ]`
  on one line, as the gem prints an Array key), nesting, the three `indent` modes, one-line mode, `sort_keys`,
  `ruby19_syntax`, colours. The gem's `Inspector` keeps the current indentation and the options in an object; here
  that is the Struct type `AwesomeInspector`, and `indented(ai) { ... }` is the gem's `indented` block (a function
  that yields, with `ensure` restoring the level). `plain_single_line` flips two fields and restores them.
- **Dispatch by type tag.** `awesome(ai, v)` is `case v in Array ... in Hash ... in String ...` as `pp.sake`'s
  walk is. The gem's `cast` (by `object.class`) and `awesome_#{type}` by `send` have no counterpart; the closed
  set of types makes the `case` complete, and `else` is exactly "a Struct value", so there is no unknown object to
  format.
- **Not done, by rule.** `ObjectFormatter` (instance variables of any object) and the `methods` table: no
  reflection. `StructFormatter` (`attr_accessor :x = 1` lines): would need the field names of an arbitrary Struct
  type, which only `Kernel.inspect` sees; the brief asked for `Kernel.inspect`, so a Struct value is one piece in the
  `struct` colour (the gem prints the members on separate lines). A user's type cannot have its own `awesome`: a
  mixin would reach only types that include it, not the Integers and Strings inside the same Array, as pp.md
  explains for `pretty_print`. `html:` needs `CGI.escapeHTML` (cgi.sake has it; left out for the budget).
  `colorize?` (colours only on a tty): Sake has no `IO.tty?`, so `plain:` is the switch.
- **Records.** A Record prints as the Hash of its fields (`Record.to_h`), which is what Ruby would print for the
  Hash literal that a Sake Record replaces. The gem never sees one.

## 書き心地

- The whole library ran under `--strict` on its first run, and the output matched the reference on the first
  diff. The code is almost a transliteration of the gem's formatters: `width += @indentation if @indent > 0`,
  `String.rjust(value, width)`, `"[\n" + Array.join(lines, ",\n") + "\n" + outdent(ai) + "]"`.
- Written by reflex, from the strscan notes: `align(ai, String.[](k, 1..) || "", width - 1)` and
  `(String.[](indent_s(ai), 0, @indentation + @indent) || "")`. Checked afterwards: without the `|| ""`, `--strict`
  (level 2) still accepts them, because the nil of a slice is "the nil of a miss", reported only at level 3. So the
  `|| ""` is for level 3 and for the reader; the habit of writing it comes from a lower-level library and is not
  what the checker asked for here.
- The option state in a Struct type with `private attr_accessor indentation` reads well: `@indentation +=
  Integer.abs(@indent)` in `indented`, `@plain = true` in `plain_single_line`. `attr_reader` fields are still
  writable from inside the type's functions, which `plain_single_line` needs (the gem does the same with
  `@options[:plain] = true` and a restore).
- Blocks as the gem uses them (`indented { ... }`, `plain_single_line { ... }`) are passed, never stored, so the
  shape survived unchanged: `def indented(ai) ... yield ... ensure ... end`.
- Keyword parameters carry the gem's option Hash one for one. `ap` repeats `ai`'s six keywords to pass them on
  (`ai(v, indent: indent, plain: plain, ...)`): `f(**opts)` is "`**` is not supported" (an open design question, recorded in
  `csv_bug_double_splat_pass_on.sake`), so the signature is written twice.
- `case v ... in Range | Regexp | Complex | Time | IO | MatchData then Kernel.inspect(v) ... else` - the `else` is
  "Struct values" only because the list of built-in types is closed and written out; a new built-in type would
  silently fall into the `struct` colour. A type pattern for "any Struct type" would make the intent explicit.

## Built-ins requested

- `IO.tty?(io)`: the gem's `colorize?` (colours only on a terminal), so `ap` could default like the gem.
- A pattern for "a value of any Struct type" (the complement of the built-in types) for `case v`.
- `**opts` pass-through (`ai(v, **opts)`), to write the option list once.
