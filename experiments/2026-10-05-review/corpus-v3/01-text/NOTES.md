# Notes: 01-text (corpus-v2, remaining difficulties)

- **Array + Array has no `+` row.** `cells + [footer]` (ascii_table) and `path + [i + 1]` (outline_number)
  are still `Array.push(Array.dup(xs), x)`.
- **Multiple assignment from a variable-length Array.** `name, arg = String.split(filter, ":")` (template_render)
  raises `ArgumentError: multiple assignment of 2 variables from Array of size 1` when there is no `:`;
  Ruby fills `arg` with nil. Indexing (`pieces[0]`, `pieces[1]`) stays. No splat (`path, *filters = ...`), so
  `Array.shift` stays.
- **`Range.sum` takes no block** (`Range.sum does not take a block`) while `Array.sum` does; number_words keeps
  `Array.sum(Range.map(1..100) { ... })`.
- Still no: `gsub` with a block / `$1` (template_render, ini_config: `String.match` + `post_match` loops);
  `case/when` with Regexp or Range (`if/elsif` chains of `String.match?`, `c >= "a" && c <= "z"`); value
  constants (markdown_html keeps a nested ternary for `LIST_KINDS`); `break` inside a block (slugify keeps an
  index `while`); `each_with_index.map`; `reduce` without an initial value (doc_pretty); `Array.new(n) { }`
  (line_diff); `&block` forwarding (outline_number).
- spell_suggest still takes about 2 s (unchanged).
- No interpreter bugs found. Assignment in a condition (`if (m = ...)`, `while (m = ...)`) runs fine at
  `--strict=0`; the original notes treated it as unavailable, so date_format, markdown_html and number_words
  now use it.
