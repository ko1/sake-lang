# rainbow

`require "rainbow"` → `sakelib/rainbow.sake`. Test: `test/sakelib/rainbow.{sake,rb}` (identical output).
Ported from rainbow 3.1.1.

## The form chosen for `Rainbow("text").red.bright`

Ruby's `Rainbow(s)` returns a `Rainbow::Presenter`, a String subclass whose methods return new
Presenters, so calls chain on the value. Sake has no String subclasses and no calls on values. The
closest form is the chain form of module functions over a String:

```ruby
Rainbow("text").Rainbow.red.Rainbow.bright      # Ruby: Rainbow("text").red.bright
Rainbow.bright(Rainbow.red("text"))             # the same, nested
```

`Rainbow(s)` is a top-level function that returns `Kernel.to_s(s)`; every result is a plain String
(Ruby's Presenter is a String too, so `puts`, `+`, `length` behave the same). The same shape as
`colorize.sake` (`"x".Colorize.red`). The other candidate, a `Rainbow::Presenter` class holding the
String, would read `Rainbow("text").Rainbow::Presenter.red.Rainbow::Presenter.bright` and need a
conversion back to String at every use.

## API

| Ruby | Sake | |
|---|---|---|
| `Rainbow(s)` | `Rainbow(s)` | differs: returns the String (Ruby: Presenter / NullPresenter) |
| `.red .green .yellow .blue .magenta .cyan .white .black` | `.Rainbow.red` … or `Rainbow.red(s)` | same |
| `.bright/.bold .faint/.dark .italic .underline .blink .inverse .hide .cross_out/.strike .reset` | same, `Rainbow.bright(s)` … | same |
| `.color(x)` / `.foreground` / `.fg` with an index, a name, `r, g, b`, `"#rrggbb"` | `Rainbow.color(s, x)` … | same codes and errors |
| `.background(x)` / `.bg` | `Rainbow.background(s, x)` / `bg` | same |
| `.aqua`, `.ghostwhite`, … (X11 names by `method_missing`) | `Rainbow.color(s, :aqua)` | differs: no `method_missing`; the 145 names work through `color`/`background` |
| `.color([r, g, b])` (one Array argument) | — | missing (the rest parameter holds Integer, Symbol or String) |
| `Rainbow.enabled` / `Rainbow.enabled = v` | `Rainbow.enabled` / `Rainbow.set_enabled(v)` | same defaults (off unless stdout and stderr are terminals; TERM=dumb; CLICOLOR_FORCE=1) |
| `Rainbow.uncolor(s)` | same | same |
| `Rainbow.global`, `Rainbow::Wrapper.new(enabled).wrap(s)`, `Rainbow.new` | — | missing: a per-wrapper switch needs the switch to travel with the value; here the global one is read at each call |
| `require "rainbow/refinement"` / `"rainbow/ext/string"` (`"x".bright`) | `"x".Rainbow.bright` | the chain form is the Sake way to put the String first |
| `Rainbow::Color::*` classes, `StringUtils` | `Rainbow.codes`, `Rainbow.wrap_with_sgr`, `parse_hex_color` | module functions (internal in the gem) |

31 operations.

## What differs and why

- **Enabled at each call.** Ruby decides Presenter or NullPresenter when `Rainbow(s)` wraps the
  String; a NullPresenter stays plain even if colouring is enabled afterwards. Here the global switch
  is read by each operation. A disabled `color`/`background` does not check its arguments, as the
  NullPresenter ignores them.
- **Tables** (`TERM_EFFECTS`, `Named::NAMES`, `X11ColorNames::NAMES`) are `once { Hash[...] }`
  functions (no value constants); the X11 table was copied mechanically (145 entries).
- `Color.build`'s class hierarchy (Indexed < Color, Named < Indexed, RGB < Indexed, X11Named < RGB)
  only computes the SGR codes, so it is one function `codes(ground, values)` with a `case`.

## Built-ins Sake lacks (requests)

- None needed.

## Friction

- `Array.min(x)` on an X11 entry (`aqua: [0, 255, 255]` in the table) → `Array.min: argument 1 must be
  Array, but is [Integer, Integer, Integer]` → `Tuple.to_a(x)`: the table literal makes Tuples, as Ruby
  code would make Arrays.
- `def Rainbow(s)` at the top level next to `module Rainbow` worked at once; `Rainbow("x")` and
  `Rainbow.red(...)` do not clash.
- The test reads close to Ruby's: `Rainbow("text").red.bright` vs `Rainbow("text").Rainbow.red.Rainbow.bright`.
  The repeated `Rainbow.` is the cost of naming the type on every operation.

## Size

Ruby (non-blank, non-comment lines): 559 (color 116, presenter 95, null_presenter 77, x11 names 151,
ext/string 48, the rest 72). Sake: 129 lines (166 with comments). Tests: 67 lines each.
