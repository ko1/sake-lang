# active_support_inflector (ActiveSupport::Inflector)

`require "active_support_inflector"` → `sakelib/active_support_inflector.sake`. Test:
`test/sakelib/active_support_inflector.{sake,rb}` (identical output; the `.rb` uses activesupport 8.1.3).

`ActiveSupport::Inflector` is `module Inflector` inside `module ActiveSupport`, Ruby's name (nested since 2026-10-10; it was the top-level `Inflector` while names could not nest). The inflection rules of
`active_support/inflections.rb` are **data**: a Record `{plurals:, singulars:, uncountables:, humans:, acronyms:}`
built by `once` (`ActiveSupport::Inflector.inflections`), filled in ActiveSupport's order so that the irregulars come first and
`/$/ → "s"` last. Ruby's `inflections { |inflect| inflect.plural ... }` block is the module functions
`ActiveSupport::Inflector.plural/singular/irregular/uncountable/human/acronym`, which add to that table.

## API

| Ruby | Sake | |
|---|---|---|
| `ActiveSupport::Inflector.pluralize(w)` / `singularize(w)` | `ActiveSupport::Inflector.pluralize(w)` / `singularize(w)` | same (all default rules; "person" → "people", "sheep", "octopus" → "octopi", "CamelOctopus" → "CamelOctopi", "cactus" → "cactu" as Ruby) |
| `pluralize(w, :es)` (locale) | — | missing: one language; the table has no locale key |
| `camelize(s, uppercase_first_letter = true)` | `ActiveSupport::Inflector.camelize(s, true \| false \| :lower)` | same |
| `underscore(s)` | `ActiveSupport::Inflector.underscore(s)` | same (acronyms: Ruby's one regexp with an optional look-behind group is two passes) |
| `humanize(s, capitalize:, keep_id_suffix:)` | same keywords | same |
| `titleize(s, keep_id_suffix:)` | same | same |
| `upcase_first` / `downcase_first` | same | same |
| `tableize` / `classify` / `dasherize` / `demodulize` / `deconstantize` / `foreign_key(s, sep = true)` | same | same |
| `ordinal(n)` / `ordinalize(n)` | same | same (Integer or Float, as the en locale lambda: 1.5 → "1.5st") |
| `transliterate(s, replacement = "?", locale:)` | `ActiveSupport::Inflector.transliterate(s, replacement = "?")` | same output for UTF-8 input (the i18n gem's default approximations as a `once` Hash; `:none` keeps the character); missing: `locale:`, non-UTF-8 encodings, `tidy_bytes` of invalid bytes |
| `parameterize(s, separator:, preserve_case:, locale:)` | without `locale:` | same |
| `inflections { \|i\| i.plural(re, rep) }` etc. | `ActiveSupport::Inflector.plural(re, rep)`, `singular`, `irregular(s, p)`, `uncountable(*words)`, `human(rule, rep)`, `acronym(w)` | differs: no block, the table is global (it is in Ruby too) |
| `inflections.clear(:all)` | — | missing (`Array.clear(ActiveSupport::Inflector.plurals)` works) |
| `constantize` / `safe_constantize` | — | missing: no reflection; a String cannot name a type |

24 operations ported (18 transformations + 6 table editors); 3 missing (`constantize`, `safe_constantize`, `clear`).

## できたこと / できなかったこと

- できた: every string transformation, bit for bit on 140 inputs including the acronym cases (`acronym "HTML"`,
  `"RESTful"`): `camelize("my_html_parser")` → "MyHTMLParser", `underscore("HTMLS")` → "html_s". Since there are no
  value constants, each rule list is a `once` block and the regexps are literals inside it; the irregulars are
  generated with `Regexp.new("(?i)(#{s0})#{srest}$")` as Ruby's `irregular` does.
- できなかった: `constantize` (there is no `Object.const_get`; Sake's rule: every call target is known before
  running). Locales: ActiveSupport keeps one table per locale through I18n; Sake has no I18n and one table is
  enough for the gem's own rules, so `locale` arguments were dropped rather than carried as a dead parameter.
- Ruby's `$1`/`$2` inside a `gsub` block (`camelize`, `underscore`): a Sake block gets only the matched text.
  For `/(?:_|(\/))([a-z\d]*)/` the match itself says which alternative matched (`String.start_with?(m, "/")`), so
  the groups were not needed. For the acronym regexp `(?:(?<=([A-Za-z\d]))|\b)(ACR)(?=…)` the group is a
  zero-width look-behind that the match text does not contain, so it became two `gsub` passes.

## 書き心地

- Wrote the rule table as `Array.each(rules) { |rule, replacement| break if String.sub!(result, rule, replacement) }`,
  Ruby's `apply_inflections` line for line; `String.sub!` keeps Ruby's nil-on-no-change, so `break if` reads the
  same. The first run of the test under `--strict` was identical to ActiveSupport's output, with no checker report.
- Wrote `return found ? found.dup : ...` → `error: undefined function String.dup / hint: dup is defined in Kernel.dup` →
  `dup(found)`. Every `.dup` in the gem became `dup(x)`; a copy is a Kernel operation, not a String one.
- Wrote `p a, b, c` to print several results → `wrong number of arguments for Kernel.p (given 4, expected 1)` →
  `Array.each(Array[a, b, c]) { |x| p x }`, which the tests use through `show`. `p` with one argument is the rule;
  the message said so at once.
- Wrote `def inflections = once { t = {...}; plural(...); t }` so the defaults would go through the public
  `plural`. That would re-enter `once` while computing it (a `SystemStackError` by the spec), so the defaults are
  added by `default_inflections(t)` / `irregular_into(t, s, p)` taking the table, and the public editors call
  `inflections`. The language made the dependency explicit; in Ruby the same shape is an `||=` that silently
  recurses once.
- `inflections => {plurals:}` to read one field of the Record: one line per accessor (`def plurals`). A Record is
  read by pattern, never by `t.plurals`; it is the one place the Ruby would have been shorter (`@plurals`).
- A caller's mistake is caught at the caller: `ActiveSupport::Inflector.pluralize(nil)` → `active_support_inflector.sake:165:5:
  error: Regexp.match?: argument 2 must be String, but is nil [type] / hint: reached by the call at line 3 →
  ...:178 → ...:171`. Ruby raises `NoMethodError` inside `apply_inflections` at run time; here it is reported
  before running, with the chain from the user's line (3) into the library (178 → 171). Ruby would blame
  `apply_inflections`; the hint blames the call.
- What helped: `once` for the tables (no constant, no `@@`), `Regexp.new("(?i)...")` for Ruby's `/.../i`
  interpolation, `String.sub!` returning nil, keyword parameters (`humanize(s, capitalize: false)`) with a
  misspelling caught statically (`did you mean capitalize:?`).

## Built-ins requested

- `Regexp.new(src, "i")` or `Regexp.new(src, Regexp::IGNORECASE)`: flags are now spelled inside the source as
  `(?i)`, which is fine for `i` but not for `x` with comments; a second argument would read as Ruby.
- The groups of the current match inside a `gsub` block (a MatchData parameter, `{ |m, md| }`), for Ruby's `$1`,
  `$2`; the two-pass rewrite of `underscore`'s acronym regexp is because of this.
- `String.sub(s, re, hash)` already exists; a `String.sub(s, re) { |m| }` form where `m` is the MatchData would
  serve the same.
