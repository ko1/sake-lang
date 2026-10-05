# Review: 01-text (corpus-v3, against the language at 2026-10-05)

All 25 programs give `NAME.out` exactly with `bin/sake --strict=0` (exit 0).

- ascii_table: `Column = Struct.new` -> `class Column` with `attr_reader title, align, max_width` / `attr_accessor width` (as Ruby); `Array.push(Array.dup(cells), footer)` -> `cells + Array[footer]` (Array + Array).
- bwt_rle: `DecodeError = Exception.new(:offset)` -> `class DecodeError < StandardError` + `attr_reader offset`.
- case_convert: `Ident` Struct -> `class Ident` + `attr_reader`.
- classic_ciphers: `Array.map(Range.to_a(0...26)) { |_| 0 }` -> `Array.new(26, 0)` (as Ruby).
- columnize: `Layout` Struct + reopened class -> one `class Layout` with `attr_reader rows, cols, widths, order`.
- csv_report: `CsvError` -> exception class; `Sale` -> `class Sale` + `attr_reader`; `header = Array.shift(rows)` -> `header, *body = rows` (rest in multiple assignment).
- date_format: `Date`, `DateError` -> classes with `attr_reader`; `day_of_year` loop with `Integer.upto` -> `@day + Range.sum(1...@month) { ... }` (as Ruby).
- doc_pretty: `Doc` -> `class Doc` + `attr_reader`; `Array.unshift(Array.reverse(stack), item)` -> `Array[item] + Array.reverse(stack)` (Array + Array, as Ruby).
- human_format: unchanged.
- inflector: `Rule`, `Inflections` Structs -> classes with `attr_reader` (the Inflections fields moved into its existing `class` body).
- ini_config: `ConfigError` -> exception class; `Entry` -> `class Entry` with `attr_reader section, key, line_no` / `attr_accessor raw` (as Ruby, raw is appended from outside); `m = ...; if m != nil` -> `if (m = ...)`; `interpolate`'s `String.match`/`pre_match`/`post_match` loop -> `String.gsub(value, re) do |m| ... end` (gsub with a block).
- json_pretty: `JsonError`, `Parser` -> classes with `attr_reader`.
- justify_text: unchanged.
- line_diff: `Edit` -> class + `attr_reader`; `Range.map(0..n) { Range.map(0..m) { 0 } }` -> `Array.new(n + 1) { Array.new(m + 1, 0) }` (as Ruby).
- markdown_html: `Block` -> class + `attr_reader`; the nested ternary standing for Ruby's `LIST_KINDS` constant -> `def list_kinds = once { Hash[bullet: :ul, ...] }` and `list_kinds[kind]`.
- markdown_table: `Table`, `TableError` -> classes with `attr_reader`.
- number_words: `Array.sum(Range.map(1..100) { ... })` -> `Range.sum(1..100) { ... }` (as Ruby).
- outline_number: `Node`, `OutlineError` -> classes with `attr_reader`; `walk` re-yielding through a wrapper block -> `def walk(node, path, depth, &block)` passing `&block` on; `Array.push(Array.dup(path), i + 1)` -> `path + Array[i + 1]`.
- slugify: `Post` -> class + `attr_reader`; the index `while` in `shorten` (needed only for `break`) -> `Array.each(words) do |w| ... break if ... end` (as Ruby).
- spell_suggest: `Suggestion` -> class with `include Comparable` + `attr_reader`.
- template_render: `TemplateError` -> exception class; `pieces = String.split(...); pieces[0]; pieces[1]` -> `name, arg = String.split(filter, ":")` (missing elements are nil now); `Array.shift(parts)` -> `path, *filters = ...`; the `match`/`pre_match`/`post_match` loop in `render` -> one `String.gsub(template, re) { |m| ... }`.
- text_box: `BoxOptions` -> class + `attr_reader`.
- text_stats: unchanged.
- whitespace_tidy: `Change` -> class + `attr_reader`.
- word_wrap: `Paragraph` -> class + `attr_reader`.

Summary: 22 changed, 3 unchanged. Most used: `class` + `attr_reader` (20 programs, 7 of them also an
exception class), Array + Array (3), gsub with a block (2), rest/short multiple assignment (2),
`Array.new` with a size (2), `Range.sum` with a block (2), `&block` (1), `once` (1), `break` in a block (1).
No program needed `x => T`, keyword/optional parameters, `initialize` or `class B < A`: the Ruby
versions of this domain use none of them.

## Friction

- **gsub block without the groups.** ini_config.sake:50-55 and template_render.sake:55. Wanted Ruby's
  `gsub(re) { ... $1 ... }` → the block gets only the matched String (no `$1`, no MatchData) → wrote
  `m[2...-1]` / `m[2...-2]`, slicing the delimiters off by hand. This ties the slice to the pattern's
  literal prefix/suffix lengths; a block parameter that is the MatchData (or a second one) would let
  the code say `m[1]`.
- **No private fields.** json_pretty.sake:6. Ruby's Parser has `attr_reader :pos` and a plain `@src`
  → every Sake field is declared by an `attr_*` line, and there is no form without an accessor →
  `attr_reader src, pos` (exposes `Parser.get_src`).
- **`@x` only reaches the first argument.** spell_suggest.sake:6. Ruby's `<=>(other)` reads
  `other.distance` → the second operand has no shorthand → `Suggestion.get_distance(b)` etc. next
  to `@distance` on the same line.
- **Exception check vs. assertion.** template_render.sake:22-26. Ruby: `raise TemplateError ... unless
  value.is_a?(Integer)`. `value => Integer` would raise `NoMatchingPatternError` (not rescuable),
  but the program expects a TemplateError it can report → kept `case value in Integer ... else raise`.
  `=>` fits invariants, not input validation that should be rescued.
- Unchanged: `str << x` / `+""` has no counterpart (String `+=` reassigns), so bwt_rle, case_convert,
  date_format etc. build Strings with `out += ...`; harmless here.

## Ruby comparison

- Every field read is `Type.get_f(x)` where Ruby writes `x.f` (e.g. text_box.sake:43-46,
  csv_report.sake:88-94). With `attr_reader` declared in the class, the declaration now looks like
  Ruby's, but the uses do not; this is still the first thing a Ruby reader sees.
- Methods take their receiver as the first parameter (`def amount(s) = @units * @price`,
  `Inflections.pluralize(inf, w)`); a Ruby `self.ordinal` class method and an instance method are
  written alike (date_format.sake `ordinal(n)` takes a non-Date first argument and does not use `@`).
- Ruby's `initialize(...)` with `super(message)` for exception classes disappears entirely:
  `class E < StandardError` + `attr_reader f` and `E.new("msg", f)` gives the same shape with
  `message` implicit as the first field.
- `case/when` with Ranges or Regexps (classic_ciphers `when "a".."z"`, markdown_html `classify`,
  ini_config `coerce`) stays an `if/elsif` chain of comparisons or `String.match?`.
- `each_with_index.map` (no enumerator chaining), `reduce` without an initial value, and `&:sym` are
  absent, so several Ruby one-liners are an explicit `Array[]` + `push` loop (markdown_table.sake
  `render_row`, text_box.sake shadow, tidy's `expanded`) or a block spelled out (`{ |w| String.size(w) }`).
