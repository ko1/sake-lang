# active_support_core_ext (ActiveSupport's core extensions)

`require "active_support_core_ext"` → `sakelib/active_support_core_ext.sake` (requires `active_support_inflector`).
Test: `test/sakelib/active_support_core_ext.{sake,rb}` (identical output; the `.rb` uses activesupport 8.1.3).

ActiveSupport reopens `String`, `Array`, `Hash`, `Integer`, `Numeric`, `Object`. A Sake type's operations are
fixed (a user program may add to `class String`, a library should not take the names), and a value is never a
receiver, so each extension is a function in a module named after the class it extends, with the value first:
`"x".squish` → `StringExt.squish(s)`, `xs.in_groups_of(3)` → `ArrayExt.in_groups_of(xs, 3)`, `h.deep_merge(o)` →
`HashExt.deep_merge(h, o)`, `7.ordinalize` → `IntegerExt.ordinalize(7)`, `x.blank?` on anything → `Blank.blank?(x)`,
`2.hours` → `ActiveSupport::Duration.hours(2)` (Ruby's name, nested since 2026-10-10; was `Duration`). The `Ext` suffix says "this is the extension, not the type"; `Blank` is named for
what it tests, since `Object` is not a Sake namespace.

## API

| Ruby | Sake | |
|---|---|---|
| `x.blank?` / `present?` / `presence` (Object, nil, false, true, String, Array, Hash, Set, Symbol, Numeric, Time) | `Blank.blank?(x)` / `present?` / `presence` (one `case x in ...`) | same (`presence` is typed `x \| nil`) |
| `x.deep_dup` | `Blank.deep_dup(x)` | same (Arrays and Hashes through, the rest `dup`) |
| `s.squish`, `remove(*pats)`, `truncate(n, omission:, separator:)`, `truncate_words(n, omission:, separator:)`, `indent(n, str = nil, empty = false)`, `at`, `from`, `to`, `first(n = 1)`, `last(n = 1)`, `starts_with?`, `ends_with?`, `upcase_first`, `downcase_first` | `StringExt.*(s, ...)` | same (`truncate_bytes`, `squish!`/`remove!`/`indent!` missing: the `!` forms mutate; `String.gsub!` exists, so they could be added) |
| `s.pluralize`, `singularize`, `camelize(:lower)`, `camelcase`, `underscore`, `dasherize`, `demodulize`, `deconstantize`, `tableize`, `classify`, `humanize(...)`, `titleize(...)`, `titlecase`, `foreign_key`, `parameterize(...)` | `StringExt.*(s, ...)` → `Inflector` | same |
| `s.constantize`, `safe_constantize`, `html_safe`, `mb_chars`, `to_time`/`to_date`, `inquiry`, `in_time_zone` | — | missing: reflection, SafeBuffer, Date/TimeZone |
| `xs.in_groups_of(n, fill = nil) [{ }]`, `in_groups(n, fill = nil) [{ }]`, `split(v) / split { }`, `to_sentence(words_connector:, two_words_connector:, last_word_connector:)` | `ArrayExt.*(xs, ...)` | same (the block forms yield and give the groups; Ruby gives the receiver) |
| `second`..`fifth`, `forty_two`, `second_to_last`, `third_to_last`, `from`, `to`, `including`, `excluding`/`without`, `exclude?`, `compact_blank`, `many? [{ }]`, `sole`, `index_by { }`, `index_with(v) / { }`, `pluck(*keys)`, `pick(*keys)`, `deep_dup` | `ArrayExt.*` | same (`pluck`/`pick` on elements that take `[]`: Hashes, Arrays) |
| `minimum(:key)`, `maximum(:key)`, `in_order_of(:key, series, filter:)` | `ArrayExt.minimum(xs) { \|x\| key }` ... | differs: a block computes the key (no method names as values) |
| `xs.sum`, `to_xml`, `to_fs`, `to_param`, `to_query` | — | `Array.sum` is built in; the rest need Builder / Rack |
| `h.deep_merge(o) [{ \|k, a, b\| }]`, `deep_merge!`, `reverse_merge`/`with_defaults`(`!`), `stringify_keys`, `symbolize_keys`/`to_options`, `deep_stringify_keys`, `deep_symbolize_keys`, `deep_transform_keys { }`, `deep_transform_values { }`, `compact_blank`(`!`), `assert_valid_keys(*keys)`, `deep_dup` | `HashExt.*(h, ...)` | same (`stringify_keys!` & co. missing: `Hash.transform_keys!` exists, left out) |
| `h.except`, `slice`, `extract!`, `to_query`, `to_xml`, `with_indifferent_access` | — | `except`/`slice` are built in; the rest need Rack / a new type |
| `n.ordinalize`, `ordinal`, `multiple_of?` | `IntegerExt.*(n, ...)` | same |
| `n.in_milliseconds` | `NumericExt.in_milliseconds(n)` | same (`bytes`/`kilobytes`... missing, trivial) |
| `n.seconds`/`minutes`/`hours`/`days`/`weeks`/`fortnights`/`months`/`years` | `ActiveSupport::Duration.seconds(n)` ... | same |
| `ActiveSupport::Duration.build(s)`, `parse(iso)`, `d.value`, `parts`, `to_i`, `to_f`, `to_s`, `inspect` (`p d`), `iso8601(precision:)`, `in_seconds`..`in_years`, `+`, `-`, `-@`, `*`, `/`, `%`, `<=>`, `==`, `<` ..., `ago`/`until`/`before`, `since`/`from_now`/`after`, `abs`, `zero?`, `positive?`, `negative?` | `ActiveSupport::Duration.*(d, ...)`; the operators as operators | same on the test's 60 cases: `1.month.since(Jan 31)` → Feb 29, `13.months` → Feb 28 2025, `1.5.days` → +1 day 12 h; `parse` raises `ArgumentError` with Ruby's message (Ruby: `ISO8601Parser::ParsingError < ArgumentError`) |
| `Time.current`, `d.since` with no Time (uses `Time.current`) | `ActiveSupport::Duration.since(d, time = Time.now)` | differs: no `Time.zone` |
| `Date` arithmetic, `Duration#to_s` of parts, `Scalar` | — | missing: no Date type; `Scalar` is Ruby's coercion plumbing |

About 135 operations ported across six modules and the `Duration` type (the inflection wrappers and aliases counted); about 20 missing (listed).

## できたこと / できなかったこと

- できた: all of `object/blank`, `object/deep_dup`, `string/{filters,access,indent,inflections,starts_ends_with}`,
  `array/{grouping,conversions(to_sentence),access}`, most of `enumerable`, `hash/{deep_merge,keys,reverse_merge,
  deep_transform_values}`, `integer/{inflections,multiple}`, `numeric/time`, and `Duration` with calendar
  `ago`/`since` (Ruby's `Time#advance` through `Date#>>` is `shift_months` with the day clamped to the month's end).
- できなかった, by Sake rule:
  - **Monkey patches**: `"x".blank?` cannot be written; `Blank.blank?(x)` is a `case` over the closed set of
    types, which is how ActiveSupport's eleven `blank?` definitions read when put in one place.
  - **A method name as a value** (`pluck(:id)` on objects, `minimum(:price)`, `in_order_of(:key, ...)`): no `send`,
    so these take a block for the key. `pluck`/`pick` keep the key argument because they index (`e[k]`).
  - **`Time.current` / `Time.zone`**: no time zones beyond fixed offsets; `since`/`ago` default to `Time.now`.
  - `Enumerable::SoleItemExpectedError` is the top-level `SoleItemExpectedError`: Sake has no `Enumerable` to nest it in (names nest since 2026-10-10).
- Differences kept: `in_groups_of(xs, n) { }` returns the groups (Ruby: the receiver). `ActiveSupport::Duration.parse` raises
  `ArgumentError` (the test prints Ruby's class name by hand).

## 書き心地

- Wrote `in_groups_of` as the gem does: `collection = Array.concat(Array.dup(xs), Array.new(padding, fill_with))` →
  `error: Array.concat: an element must be String, but can be nil | true|false [type] / hint: reached by the call
  at line 13`. The test passes `String["1", "2", ...]`, a typed Array, and the padding is nil. **The checker found
  a real difference from Ruby**: `dup` of a `String[]` keeps the element type, so Ruby's "pad the copy with nil"
  would raise at run time. Now `collection = Array.concat(Array[], xs)`, a fresh untyped Array, and the same for
  each group in `in_groups`. The line reads as a decision ("this result is untyped") where the Ruby was implicit.
- Wrote `deep_merge` with `elsif Hash.key?(result, k) && block_given?` → `error: yield: no block is given on this
  call [type] / hint: check block_given? before yield / reached by the call at line 57 → line 48`. A lone
  `if block_given?` is pruned for a block-less call; joined with `&&` it is not, so the recursion without a block
  reaches the `yield`. Rewritten as a nested `if block_given?`. Repro: `active_support_core_ext_bug_block_given_and.sake`
  (a ternary `block_given? ? yield(x) : x` is fine, so it is the `&&`).
- The caller's side of `deep_merge`: the test's block `{ |k, a, b| a + b }` →
  `Arithmetic.+: the operands may be (nil, Integer), (Integer, Hash@L58), (Hash@L58, Integer)...` because the Hash
  holds `Integer | Hash` values and `r[k]` adds the nil of a miss. True to the types (the block does get a Hash and
  an Integer under the same key in other calls), so the test writes `(a in Integer) && (b in Integer) ? a + b : b`.
  Ruby's version works by never meeting that case; Sake's shows the case exists.
- Wrote `deep_transform_keys(h, &b)` recursing with `yield(k)` inside the block passed to `each_with_object` and
  `&b` to the recursive call — accepted: `yield` and passing `&b` on mix in one function as in Ruby, and the
  checker followed the block through the recursion.
- `Duration`: `include Arithmetic` + `def +(d, other)`, `include Comparable` + `def <=>`, own `==` so that
  `ActiveSupport::Duration.hours(1) == 3600` is true as in Ruby; then `d - 60`, `-d`, `Array.min(Array[d1, d2])`, `d1 > d2` all
  read as Ruby. `p d` prints `2 hours` through the type's own `inspect(d)`. `@value` / `@parts` inside the type's
  functions are the Ruby `@ivar`s; `ActiveSupport::Duration.new(value, parts)` with `initialize` dropping zero parts is Ruby's
  `initialize` line for line. This was the most Ruby-like file of the three.
- `ActiveSupport::Duration.parse`: `Array.each(String.scan(s, /(\d+)([YMWD])/)) do |num, unit|` → `String.match?: argument 1 may
  be nil (nil | String) [nil]`: the Tuples of `scan` have `nil | String` groups. `num || ""` is the honest fix; the
  group cannot be nil for that regexp, but the checker cannot know it.
- `StringExt.presence("")` then `String.upcase(s)` → `argument 1 may be nil (nil | String) [nil]`: the gem's
  `s.presence || "default"` idiom is exactly what the checker asks for, so it reads the same in Sake.
- Two small Ruby habits: `Array.shift(arr, n)` has no count (`Array.slice!(arr, 0, n)`), `String.squeeze(s)` has no
  character argument (`squeeze!` has; `gsub` with `{2,}` was used instead). `Hash.each_key`, `Hash.replace`,
  `Hash.transform_keys`, `Hash.sum { }`, `Array.each_slice` without a block (gives the slices) all existed and
  made the Hash/Array ports one-liners.

## Built-ins requested

- `Array.shift(x, n)` / `Array.pop(x, n)` with a count, as Ruby (`split` uses `slice!` + `shift`).
- `String.squeeze(x, chars)`: the non-bang form takes no argument while `squeeze!` does.
- `Float.divmod(x, Integer)`: `divmod` requires a Float second argument; `Time#advance`'s `n.divmod(1)` became
  `floor` and a subtraction.
- A Date type, or a `Time` operation that moves by months with the day clamped (Ruby's `Date#>>`): `Time.new`
  rejects month 13 as Ruby's does, so the library carries `shift_months`/`days_in_month`.
- (checker) `block_given?` inside `&&` pruning the branch, as it does alone and in a ternary (bug repro above).
