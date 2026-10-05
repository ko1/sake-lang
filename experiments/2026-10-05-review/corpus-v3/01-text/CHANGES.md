# Changes: 01-text (corpus -> corpus-v2)

- word_wrap: `Paragraph.get_bullet(para) == false` -> unary `!`.
- justify_text: `Array.empty?(current) == false` -> unary `!`.
- template_render: the `count` filter's `case value in Array ... in String` (same-named `size`) -> `in Array | String then (Array|String).size(value)`.
- case_convert: `String.empty?(current) == false` -> unary `!`.
- ascii_table: unchanged (`cells + [footer]` still needs `Array.push(Array.dup(...))`; Array + Array has no `+` row).
- markdown_table: sort key `0.0 - x` -> unary `-x`.
- text_stats: removed the `WordCount` Struct with its hand-written Comparable `<=>`; `Hash.sort_by(counts) { |w, c| [-c, w] }` (Tuple key, unary minus), top words destructured `|w, c|`; `Array.sum(Array.map(...))` -> `Array.sum(ws) { ... }`; `Array.map(Hash.to_a(h))` -> `Hash.map(h)`.
- line_diff: `groups.map { |g| edits[g[0]..g[1]] }` -> block destructuring of the Array pair `{ |lo, hi| edits[lo..hi] }`.
- number_words: `0 - n` -> `-n`; `== false` -> `!`; `x = h[k]; if x != nil` -> `if (replacement = irregular[last])` as in Ruby.
- csv_report: `String.empty?(field) == false || Array.empty?(row) == false` -> `unless ... && ...` (as in Ruby); `Array.sum(Array.map(...))` -> `Array.sum(list) { ... }`.
- slugify: `return base if Set.include?(...) == false` -> `return base unless ...`.
- text_box: unchanged.
- columnize: unchanged.
- whitespace_tidy: packed key `count * 100 - step` -> Tuple key `[count, -step]`, result destructured `unit, _ = Hash.max_by(...)` instead of `best[0]`; two `== false` -> `!`.
- json_pretty: `(v in Array | Hash) == false` -> `!(v in Array | Hash)`.
- ini_config: unchanged.
- spell_suggest: the chained three-step `<=>` -> one Tuple comparison `[@distance, -@frequency, @word] <=> [...]` (as in Ruby; Comparable kept for `Array.sort`).
- classic_ciphers: `pair[0]`/`pair[1]` in `min_by`/`sort_by`/`map` blocks -> block destructuring `|_, s|`, `|shift, score|`; packed key `0 - counts[i] * 100 + i` -> `[-counts[i], i]`.
- inflector: unchanged.
- human_format: `10 ** (0 - decimals)` -> `10 ** -decimals`; `== false` -> `!`.
- markdown_html: `while true` + `String.match` + `break` -> `while (m = String.match(...))` as in Ruby; `after_blank == false` -> `!after_blank`.
- bwt_rle: unchanged.
- date_format: nested `if` with separate `m`/`m2`/`m3` locals -> `if (m = ...) elsif (m = ...) elsif (m = ...) else raise` as in Ruby.
- outline_number: `Array.sum(Array.map(@children) { ... })` -> `Array.sum(@children) { ... }`.
- doc_pretty: `return true if flat == false` -> `return true unless flat`; `while Array.empty?(stack) == false` -> `until Array.empty?(stack)`.

Summary: 19 of 25 programs changed (6 unchanged). Features used most: removing `x == false` (11 programs:
unary `!` in 8, `unless`/`until` in 3), unary `-` (7), Tuple comparison keys/`<=>` (4), block and
multiple-assignment destructuring (4). `(A|B).f` once. Chains and `_` were not needed: the existing nesting was
already short, and rewriting it would have reshaped the programs.
