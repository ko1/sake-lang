# erubi

`require "erubi"` → `sakelib/erubi.sake`, after the erubi gem 1.13.1. Test: `test/sakelib/erubi.{sake,rb}`,
98 identical lines: generated sources for every option, rendered pages, trimming, literals, `Erubi.h`, an
invalid indicator.

## Source and rendering (no eval)

Ruby's Erubi only compiles: `Erubi::Engine.new(template).src` is Ruby source that the caller `eval`s.
The port keeps the compiler whole: **`Erubi::Engine.src(e)` is byte for byte the source Ruby's Erubi
generates** (the test prints it for every option). Sake has no `eval`, so that source cannot be run.

To render, `Erubi::Engine.render(e, vars)` (Sake only) replays what the compiler emitted — text after
Erubi's trimming, expressions (escaped or not), code — as a template for Sake's ERB (`sakelib/erb.sake`),
with no trim mode, and renders it with `ERB.result_with_hash(erb, vars)`: the Hash's keys are the template's
variables, as the Ruby test's `binding.local_variable_set` + `eval(src)`. So the code inside tags must be in
the subset Sake's ERB interprets (`if`/`elsif`/`else`/`unless`/`each do |x|`/`end`, names, `[]`, a few
methods, comparisons; `notes/erb.md`); anything else raises `ERB::Error` where Ruby would run it.
`Erubi::Engine.erb_template(e)` shows the replayed template.

## API

| Ruby | Sake | |
|---|---|---|
| `Erubi::Engine.new(t, opts = {})` | `Erubi::Engine.new(t, Hash[:escape => true])` | same; options are a Hash |
| options `escape escape_html trim filename bufvar outvar bufval regexp literal_prefix literal_postfix preamble postamble chain_appends freeze_template_literals src freeze ensure escapefunc` | same keys | same (all 18) |
| `engine.src` / `filename` / `bufvar` | `Erubi::Engine.src(e)` / ... | same |
| `eval(engine.src)` | `Erubi::Engine.render(e, vars)` | differs: no eval; the template's code must be in Sake's ERB subset |
| `Erubi.h(v)` | `Erubi.h(v)` | same (`CGI.escapeHTML`: `& < > " '`) |
| `Erubi::VERSION` | `Erubi.version` | differs: no value constants |
| invalid indicator (custom regexp) | `ArgumentError`, Ruby's message | same |
| `Erubi::CaptureBlockEngine`, `Erubi::CaptureEndEngine` | — | missing: capturing needs a block's output as a value inside the evaluated template (`@_buf.capture(&block)`), which needs eval and blocks as values |
| subclass hooks (`add_text`, `handle`, ... overridden by Rails) | — | missing: no subclassing with overrides of the engine's own calls |

6 operations + 18 options.

## What differs and why

- No `eval` (by design) → the renderer above. The replayed template has the trimming already applied, so
  ERB without a trim mode reproduces Erubi's whitespace exactly (checked by the test with `trim` on and off).
- Ruby builds `src` with `<<` on one String; here `@src += ...` (no `<<` on String in Sake).
- `(indicator == "=") ^ @escape` is `!=`: `Bitwise.^` takes only Integers.
- `src.freeze` / `freeze`: Sake has no freezing; the Engine has only readers for its results.
- `FREEZE_TEMPLATE_LITERALS` is true (Ruby ≥ 2.1, as on this machine's Ruby 4.0).

## Built-ins Sake lacks (requests)

- `true ^ false` (Ruby's `TrueClass#^`). And the checker did not catch it: `Bitwise.^: no implementation for
  (true, false)` came at run time.

## Friction (what I wrote → the message → what I wrote instead)

- `if (indicator == "=") ^ @escape` → run-time `TypeError: Bitwise.^: no implementation for (true, false);
  defined for (any two of Integer)` → `!=`. Should be a static error: both operands are known Booleans.
- A Hash of options with mixed values (`true`, Strings, a Regexp) needs a narrowing reader per kind:
  `opt_s(props, k)` (String or nil) and `opt?(props, k)`; Ruby reads `properties[:bufvar]` directly.
- What went well: the compiler is a near line-for-line port (the scan loop became `while (m =
  Regexp.match(re, input, pos))`), the 13 generated sources matched Ruby's at the first run, and reusing
  Sake's ERB as the evaluator kept the renderer to 20 lines.

## Size

Ruby: 299 lines (lib/erubi.rb; 210 without comments and blank lines). The capture engines (149 lines) are
not ported.
Sake: 235 lines (192 without comments and blank lines).
