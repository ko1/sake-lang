# liquid

`sakelib/liquid.sake`: Shopify's Liquid template language after the liquid gem (5.x, lax mode). The
gem is not installed, so `test/sakelib/ref/liquid.rb` is a plain-Ruby reference with the gem's API
(`Liquid::Template.parse(src).render(assigns)`, `Liquid::SyntaxError`), and `test/sakelib/liquid.rb`
requires it; both print the same 59 lines as `test/sakelib/liquid.sake`. 719 lines, 43 functions,
8 types (`LExpr`, `LFilter`, `LCond`, `LNode`, `LTok`, `Template`, `LParser`, `LContext`) and the
modules `Liquid`, `LRender`. `liquid.sake` requires `time` (`Time.parse` for the `date` filter).

## API

| liquid gem | Sake | |
|---|---|---|
| `Liquid::Template.parse(src)` | `Template.parse(src)` | same (nested name flattened; `Template` is a generic name, see below) |
| `template.render(hash)` | `Template.render(t, hash)` | same; a template renders any number of times |
| — | `Liquid.render(src, hash)` | added: parse and render in one call (the brief's shape) |
| `Liquid::SyntaxError` | `LiquidSyntaxError` | differs: messages are this port's (`Unknown tag 'x'`, `'if' tag was never closed`, `Unexpected outer 'endif' tag`, `Variable '{{' was not properly terminated`) |
| `{{ x }}`, `x.k`, `x["k"]`, `x[0]`, `x[-1]`, `.size`/`.first`/`.last`, `'s'`, `1`, `1.5`, `true`, `nil`, `empty`, `blank`, `(1..n)` | same | same; `{{ (1..3) }}` renders `123` (gem: `1..3`) |
| `{{ x \| upcase \| truncate: 10, "…" }}` | same | same; an unknown filter leaves its input (lax mode) |
| filters `upcase downcase capitalize size join first last plus minus times divided_by modulo abs floor ceil date default replace replace_first remove remove_first append prepend truncate truncatewords escape strip lstrip rstrip split reverse sort uniq compact concat sum newline_to_br strip_newlines` | same | same, except: arithmetic is Float where the gem goes through BigDecimal (`0.1 \| plus: 0.2` → `0.30000000000000004`, gem `0.3`); `default: x, allow_false: true` not supported; `date` without `"now"`/`"today"` |
| `{% if a == b and c or d %}`, `elsif`, `else`, `unless`, `==` `!=` `<>` `<` `>` `<=` `>=` `contains` | same | same, including the gem's right-to-left `and`/`or` chain; comparing nil with a number is `false` (gem: raises, rendered as `Liquid error: comparison of ...`) |
| `{% for x in xs limit: n offset: n reversed %}`, `forloop.index/index0/rindex/rindex0/first/last/length/name`, `{% else %}`, `{% break %}`, `{% continue %}` | same | same; `forloop.parentloop`, `offset: continue` missing |
| `{% assign x = e \| f %}`, `{% capture x %}`, `{% case %}/{% when a or b, c %}/{% else %}`, `{% comment %}`, `{% raw %}`, `{% echo %}`, `{{- -}}` `{%- -%}` | same | same (every matching `when` renders, as the gem) |
| `{% cycle %}`, `{% increment %}`, `{% decrement %}`, `{% tablerow %}`, `{% include %}`, `{% render %}`, `{% liquid %}`, `{% # %}` | — | missing |
| `Liquid::Template.error_mode = :strict`, `strict_variables`, `strict_filters`, `render!`, inline `Liquid error: ...` text, drops, `Liquid::Template.register_filter` | — | missing (see below) |

## できたこと / できなかったこと

- できた: the brief's whole list (18 filters plus 20 more, 11 tags, whitespace control, parse once /
  render twice) with the gem's semantics where they are surprising: `a and b or c` is `a and (b or c)`,
  `assign` inside a `for` writes the outermost scope and the loop variable disappears after `endfor`
  (`{{ last }} {{ x }}` → `2 `), `{{ 3 | size }}` is `8` (Ruby's `Integer#size`, which Sake has as
  `Integer.size`), `case` renders every matching `when`, `{{ h }}` prints Ruby's inspect of a Hash.
- できなかった (by rule): `Template.register_filter(Module)` and custom tags are `send`-based
  (`@filters.send(name, input, *args)`), so filters are one `case name in "upcase" ...` in
  `LRender.apply_filter` and tags one `case name` in `LParser.parse_tag`; a user cannot add one
  without editing the library. Drops (`to_liquid`, `liquid_method_missing`) need `respond_to?` and
  `method_missing`; the assigns are plain Hashes. Rendering errors as inline text needs `rescue` of
  any StandardError around each node (`Liquid::Error#to_s`); the port lets `ZeroDivisionError` out
  (and the twin does the same).
- できなかった (by budget): BigDecimal arithmetic (`sakelib/bigdecimal.sake` exists; not wired),
  `cycle`/`increment`/`tablerow`/`include`, `forloop.parentloop`, named filter arguments.
- `Template` is a flat name: the gem's `Liquid::Template`. In a program that also uses another
  template library it would collide; `LiquidTemplate` was the alternative, `Template` follows the
  brief's flattening rule.

## 書き心地

- **`def initialize(c) = @rel = :none if @rel == nil`** → `error: only def, include, and (in a class)
  attr_reader/attr_accessor/attr_writer are allowed in a class/module body` at the `def` line, and then
  three `wrong number of arguments for LCond.new (given 3, expected 5)`. Prism attaches the modifier
  `if` to the whole endless `def`, so the class body held an `if` statement and no `initialize`, and
  without `initialize` every field of `new` is required. Wrote the three-line `def ... end`. The first
  message names the rule, not the cause; a hint "a modifier `if` after `def f = ...` applies to the
  def" would have saved a minute.
- **`parse_expr(val)` with `|key, val|` from `String.scan(rest, /(\w+)\s*:\s*(...)/)`** →
  `String.strip: argument 1 may be nil (nil | String) [nil]` with a seven-step `reached by` chain
  from the test line through `Template.parse` → `LParser.parse` → `parse_block` → `parse_tag`. A scan
  group is `nil | String` to the checker (a `?` group would be), so `parse_expr(val || "")`. True but
  noisy for mandatory groups; see the request below.
- **`if number?(l) && number?(r) then Comparable.<=>(l, r)`** → `Comparable.<=>: the operands may be
  (true|false, true|false), (true|false, Float), (true|false, nil), ... Array@L575#3[Integer | String |
  Hash@L13[String => String]] ...` — a message of ~1,000 characters listing every pair the assigns
  Hash can hold, cut with `…`, plus a second report with every element pair. The predicate function
  `number?` does not narrow `l`; writing the pattern inline does:
  `case l in Integer | Float then (r in Integer | Float) ? ordered?((l <=> r) || 0, op) : false`.
  Good: the fix is one idiom. Bad: the report should say "`number?(l)` does not narrow `l`; test the
  type where it is used" instead of printing the union.
- **A branch missing from `case LTok.kind(t)`** (removed `in :tag` to see) → `case/in: no in branch
  matches :tag [mixed]` with `hint: LExpr.value holds Symbol (written at line 310, 311) besides String,
  Boolean, Integer, Float`. The label is `mixed` and the hint blames `LExpr.value` (which holds the
  `:empty`/`:blank` markers), an unrelated type: the `mixed` heuristic saw "a Symbol among other types
  in some field" and took over. At the default level this is only a warning, so the program runs into
  `NoMatchingPatternError`. Repro: `liquid_bug_mixed_blames_other_field.sake`. Compare kramdown, where
  no field holds a Symbol among other types and the same omission is a clean `[type]` report.
- **Values of the assigns Hash.** Liquid values are "anything": the test's Hash holds String, Integer,
  Float, true, nil, Array and nested Hash. In Sake this is one union flowing through `eval_expr`,
  `index`, `compare`, `apply_filter`, and every operation on it is a `case v in String ... in Array ...
  else`. It reads like Liquid's own `case input when String ... when Array`, and the checker verified
  that each `case` has an `else` or covers the union. `LRender.out_s(v)` (the gem's `Array#join` for
  Arrays, `""` for nil) is the one place the union meets output; `Kernel.to_s` would have printed
  `[3, 1, 2]`.
- **The parser.** `parse_block(p, opener, closers)` returning the body and leaving the closing tag in
  `@tag`/`@markup` is the gem's `BlockBody.parse` with `parse_context` — a struct with `@pos`, `@trim`,
  `@tag` instead of instance variables plus a yield. `case name in "if" | "unless" ... in "for" ...
  else raise LiquidSyntaxError, "Unknown tag"` is the gem's `Template.tags[name]` registry, static.
  Writing it felt like Ruby with the receiver moved left; the Ruby reference was transliterated from
  the Sake file in 15 minutes by deleting the type names, which says how close the two are. The
  reverse direction is where the `|| ""` and `Array.fetch` appear.
- **What helped.** `LTok.new(:text, s, s, false, false)` positional for a plain record and
  `LNode.new(:for, text:, expr:, reversed:)` by keyword for a node with 10 fields; `Hash.new(-1)` with
  `@ids[id] += 1` (kramdown); `Comparable.<=>(l, r)` parsing as a call; `once { Hash[...] }` for the
  escape table; `return nodes` from inside `case` inside `while` behaving as Ruby.

## Built-ins requested

- `String.scan` group types: a group that cannot fail (no quantifier, not in an alternative) should
  type as `String`, not `nil | String` (the `val || ""` above).
- `BigDecimal` as a built-in numeric (or `Float.to_d`): Liquid's arithmetic (`plus`, `times`, `round`)
  is exact decimal; `sakelib/bigdecimal.sake` exists but a built-in would make `x + y` dispatch to it.
- `Kernel.rescue_any` is not a built-in; the request is for the language: `rescue => e` already catches
  every rescuable exception, which is what inline `Liquid error:` rendering needs — nothing missing,
  only budget.
- `Time.parse` is in `sakelib/time.sake`; `require "time"` from a library file worked. No request.
