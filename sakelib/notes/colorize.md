# colorize

`require "colorize"` → `sakelib/colorize.sake`, after the colorize gem (1.1.0; not installed here, so the
twin is the plain-Ruby reference `test/sakelib/ref/colorize.rb`, written from the gem's
`instance_methods.rb` / `class_methods.rb`). Test: `test/sakelib/colorize.{sake,rb}`, 68 identical lines.
57 operations: `colorize`, `uncolorize`, `colorized?`, the tables and their lookups (`colors`, `modes`,
`color`, `background_color`, `mode`, `color_codes`, `mode_codes`), `disable_colorization` /
`set_disable_colorization`, `add_color_alias`, and one operation per colour (17), background (17) and
mode (10).

The gem adds a method per colour to String (`"x".red`). A String cannot grow operations in Sake, so they
are module functions with the String first: `Colorize.red(s)`, or in a chain `"x".Colorize.red.Colorize.on_blue`.

## API

| Ruby (colorize) | Sake | |
|---|---|---|
| `"x".red`, `.light_red`, ... (17 colours) | `Colorize.red(s)`, `Colorize.light_red(s)`, ... | same codes; subject first |
| `"x".on_blue`, ... (17 backgrounds) | `Colorize.on_blue(s)`, ... | same |
| `"x".bold`, `.dim`, `.italic`, `.underline`, `.blink`, `.blink_slow`, `.blink_fast`, `.invert`, `.hide`, `.strike` | `Colorize.bold(s)`, ... | same |
| `"x".red.on_blue.bold` | `"x".Colorize.red.Colorize.on_blue.Colorize.bold` | same (re-reads the codes and merges) |
| `"x".colorize(:red)` | `Colorize.colorize(s, :red)` | same |
| `"x".colorize(color: :red, background: :blue, mode: :bold)` | `Colorize.colorize(s, color: :red, background: :blue, mode: :bold)` | same (keywords); also `Colorize.colorize(s, {color: :red})` with a Record |
| `"x".uncolorize`, `"x".colorized?` | `Colorize.uncolorize(s)`, `Colorize.colorized?(s)` | same |
| `String.colors`, `String.modes` | `Colorize.colors`, `Colorize.modes` | same |
| `String.color(:red)`, `String.background_color(:red)`, `String.mode(:bold)` | `Colorize.color(:red)`, ... | same (nil for an unknown name) |
| `String.color_codes`, `String.mode_codes` | `Colorize.color_codes`, `Colorize.mode_codes` | same (Hashes) |
| `String.disable_colorization` / `= true` / `(true)` | `Colorize.disable_colorization` / `Colorize.disable_colorization(true)` / `Colorize.set_disable_colorization(true)` | same effect |
| `String.add_color_alias(:grey, :light_black)` | `Colorize.add_color_alias(:grey, :light_black)` | differs: the alias works in `colorize(s, :grey)` and `color: :grey`; no `Colorize.grey(s)` appears |
| `String.color_samples`, `String.color_matrix` | — | missing (a printed table; not needed to port the API) |
| `ColorizedString` (the opt-in class of `colorized_string`) | — | missing: Sake's `Colorize.red(s)` already is the form that leaves String alone |
| `"x".grey` / `.gray` | — | missing: not in the gem's table either (the README adds them with `add_color_alias`) |
| 256-colour / RGB | — | missing: the gem (1.1.0) has only the 16 colours plus their light variants, as far as I know |

## できたこと / できなかったこと

- Ported: everything the README shows. The codes, the merge of codes on an already coloured String (each
  `\e[m;c;bm...\e[0m` run is re-read and only the asked-for part replaced), plain runs beside coloured
  ones, multi-line text, `disable_colorization`, aliases.
- `"x".red`: a method on String. Sake rule: a built-in type's namespace can get operations
  (`class String ... def red(s)`), but adding 44 of them to String would make them `String.red(s)`,
  which says nothing of the gem; so `module Colorize` with `module_function`, and the chain form
  `"x".Colorize.red` for the fluent look.
- `define_method` loop for the 44 colour/mode methods: not available (no metaprogramming) → 44 one-line
  `def red(s) = colorize(s, color: :red)`. Tedious, but each name is now a checked call target: a typo in
  `Colorize.ligth_red(s)` is a static error with a spelling hint, where Ruby's would be `NoMethodError` at run time.
- `String.disable_colorization` is a class-level mutable flag; Sake has no globals and no constants. The
  flag and the alias table (which `add_color_alias` mutates) are `once { Hash[...] }` values: a Hash made
  once and shared, read and written through a function. It works; it is a trick, not a feature.
- `add_color_alias` cannot create `Colorize.grey(s)`: a new operation would need `define_method`. The
  alias is in the table, so `colorize(s, :grey)` works.
- `color_samples`: left out rather than approximate the gem's layout without the gem to compare.

## 書き心地

- Wrote `h = params in Record ? Record.to_h(params) : Hash[]` → `syntax error: unexpected '?'` with
  `hint: \`x in T\` needs its own parentheses here: \`(x in T)\`` → `(params in Record) ? ...`. The hint
  said exactly what to type. In the final code it became `if params in Symbol ... elsif params in Record`,
  which reads as Ruby.
- Wrote `p(Colorize.light_black("1"), Colorize.on_light_white("2"), ...)` in the test → `wrong number of
  arguments for Kernel.p (given 6, expected 1)` → `p([...])`. Ruby's `p` takes any number.
- The gem's Hash form `"x".colorize(color: :red)` became keyword parameters, and a misspelling is caught
  before running: `Colorize.colorize("x", colour: :red)` → `error: Colorize.colorize has no keyword
  parameter \`colour\`` / `hint: did you mean \`color:\`?`. The gem ignores an unknown key silently (so does
  the Record form here, by design: `Record.to_h` then `h[:color]`). A misspelled colour *value*
  (`color: :redd`) is silent in both, as in the gem.
- The segments of a String as Records, `{mode: m, color: c, background: b, text: ...}` with `nil | String`
  fields, taken apart with `seg => {mode: m, color: c, background: b, text:}`: no friction, reads like Ruby's
  Hash pattern. `String.scan(s, re)` with three groups gave `[g1, g2, g3]` Tuples with nils, as Ruby's.
- Where Sake helped: the first `--strict` run of the library passed; the only errors were the two above,
  both in how I wrote the test. Where it was in the way: nothing beyond the missing `define_method`, which
  cost 44 lines, and the global flag.

## Built-ins requested

- `Kernel.p(*xs)` taking several arguments, as Ruby's: `p(a, b)` is a common test idiom.
