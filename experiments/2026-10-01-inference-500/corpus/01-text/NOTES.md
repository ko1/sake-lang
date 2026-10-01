# Notes: 01-text

## word_wrap
- No unary `!`: `!para.bullet` is written `Paragraph.get_bullet(para) == false`.
- No `String#<<`: the ruler is built with `marks += ...`.
- `s[0, n]` (two-argument index) is not available (`[]` takes one index); used `s[0...n]` in both versions.

## justify_text
- `case mode when :left` becomes `case mode in :left` (no `case/when`).

## template_render
- No `gsub` with a block (`String.gsub does not take a block`) and no `$1`: the Sake version loops with
  `String.match` + `MatchData.pre_match/post_match`.
- `name, arg = filter.split(":")` fails: multiple assignment needs a Tuple, and `split` returns an Array;
  index the Array instead (`pieces[0]`, `pieces[1]`). Likewise `path, *filters = ...` became `Array.shift`.
- `value.is_a?(Hash)` / `is_a?(Array)` become `case value in Hash`.
- A `"#{{...}}"` in a template string would be interpolation in both languages; changed the text.

## ascii_table
- `cells + [footer]` (Array + Array) has no row in the `+` table; written `Array.push(Array.dup(cells), footer)`.
- `v.is_a?(Numeric)` becomes `(v in Integer | Float)`; inside `||` it must be parenthesized.
- `r[5] = ...` on a row created by `Array[...]` works; the row literal had to be `Array[...]`, not `[...]`
  (a Tuple would fix the position type to nil).

## markdown_table
- `-x` (unary minus) in the `sort_by` key is written `0.0 - x`.
- `each_with_index.map` (enumerator chaining) has no Sake form; built the Array with `each_with_index` + `push`.

## text_stats
- `sort_by { |w, c| [-c, w] }` fails: `Array.sort_by: cannot compare elements of types String` (a Tuple
  key is not comparable; `Array.sort` of Tuples fails the same way). Sake version uses a `WordCount`
  Struct with `include Comparable` and `<=>` (count descending, then word).
- `x.to_f` on a value becomes `Integer.to_f(x)`.

## line_diff
- No `Array.new(n) { ... }`: the 2-D LCS table is `Range.map(0..n) { |_| Range.map(0..m) { |_| 0 } }`.
- A growable `[lo, hi]` pair that is updated in place (`last[1] = hi`) is written `Array[lo, hi]`;
  Ruby's `groups.map { |lo, hi| ... }` (Array destructuring in a block) becomes `g[0]`, `g[1]`.

## number_words
- `%w[...]` is not available; written `String[...]`.
- `Range.sum` takes no block; `(1..100).sum { ... }` became `Array.sum(Range.map(1..100) { ... })`.
- `-n` becomes `0 - n`; `if (x = h[k])` assignment-in-condition was split into two statements.

## csv_report
- `header, *body = rows` (splat assignment) became `Array.shift`; `each_with_index.to_h { ... }` became a loop
  filling `Hash[]`.
- `String#<<` is not available (`Bitwise.<<: no implementation for (String, String)`); fields are built with `+=`.

## slugify
- `break` inside `Array.each` is rejected ("`break` is only supported directly inside `while`/`until`");
  the Sake version iterates with an index and `while`.
- `each_char.map { table.fetch(c, c) }.join` became `String.each_char` accumulating into a String.

## text_box
- Border styles are Records in Sake (`{h: "-", ...}`) and Hashes in Ruby; both destructure with
  `border(style) => {h:, v:, ...}`.
- `left[i].to_s` on a possibly-nil element became an explicit `l == nil ? "" : l`.

## columnize
- Ruby's `item&.ljust(...)` inside `filter_map` became an explicit nil check with `next` in an `Integer.times` block.

## json_pretty
- Ruby's `Parser` class keeps `@src`/`@pos` as instance state; in Sake it is a Struct and every method
  takes the parser as its first argument (`Parser.peek(ps)`), using `@pos` shorthand inside.
- `case c when /[-0-9]/` (regex `===`) became an `if/elsif` chain with `String.match?`.
- `loop do ... break ... end` became `while true`.
- `@src[@pos, 4]` became `@src[@pos...(@pos + 4)]`.
- Parsed values are a union (Hash | Array | String | Integer | Float | true | false | nil); `compact`
  and `pretty` narrow with `case v in ...`.

## ini_config
- `gsub` with a block (and `$1`) for `${...}` interpolation became a `String.match` / `post_match` loop.
- `case s when /regex/` became an `if/elsif` chain of `String.match?`.
- `start_with?("#", ";")` (several prefixes) takes one argument in Sake; written as two calls.
- `entries.to_h { ... rescue ... }` became a loop with `begin/rescue` filling `Hash[]`.

## spell_suggest
- Ruby's `[distance, -frequency, word] <=> [...]` (Array comparison) is written as a chained `<=>` in
  `Suggestion`'s Comparable.
- `Array.join` of Suggestions uses the type's own `to_s`, as in Ruby.
- Slow: about 1.5-3.5 s user for ~600 distance computations (on a loaded machine); the dictionary and
  sentences were shrunk to stay under 5 s.

## classic_ciphers
- `case c when "a".."z"` (Range `===`) became `if c >= "a" && c <= "z"`.
- `text.chars.map do ... end.join` (a call on a block result) becomes `Array.join(Array.map(...) do ... end, "")`.
- `scored.min_by { |_, s| s }` over `[k, score]` Tuples: Sake blocks destructure the Tuple the same way,
  but the Sake version used `pair[1]`.

## human_format
- `10**-decimals` (unary minus) became `10 ** (0 - decimals)`.

## markdown_html
- Ruby's constant `LIST_KINDS = {...}.freeze` has no Sake form (no value constants, `{}` is a Record);
  the Sake version uses a nested ternary on the kind Symbol.
- `case line when /re/` became an `if/elsif` chain of `String.match?`; `line[/re/, 1]` became `String.match(...)[1]`.
- `while (m = ...)` assignment in a condition became `while true` + `break`.

## date_format
- `if (m = s.match(...)) ... elsif (m = s.match(...))` became nested `if` with separately named
  MatchData locals (`m`, `m2`, `m3`).
- Ruby's `def self.ordinal` (a class method) is a plain function in `class Date` in Sake (`ordinal(n)`),
  which is called unqualified from `Date.strftime`.

## outline_number
- Recursive `walk(..., &block)` forwarding the block: Sake has no `&block`; the recursive call passes a
  new block `{ |n, p, d| yield(n, p, d) }`.
- `path + [i + 1]` (Array + Tuple) became `Array.push(Array.dup(path), i + 1)`.

## doc_pretty
- Doc concatenation is a user `+` (`include Arithmetic` + `def +(a, b)` in Sake, `def +(other)` in Ruby).
- `docs.reduce { |acc, d| ... } || text("")` (reduce without an initial value) is not available
  (`init` is required); the Sake version folds with `Array.each` from a nil accumulator.
- `[[indent, true, inner]] + stack.reverse` became `Array.unshift(Array.reverse(stack), [...])`.
