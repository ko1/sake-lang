# kramdown

`sakelib/kramdown.sake`: Markdown → HTML after the kramdown gem (2.5.2, installed), for the common
subset. 690 lines, 52 functions, the module `Kramdown` with 4 types nested in it (`Element`, `Blocks`,
`Spans`, `Html`; since 2026-10-11, were the flat `KNode`, `KBlocks`, `KSpans`, `KHtml`). Test:
`test/sakelib/kramdown.{sake,rb}` print the same 223 lines; the `.rb` uses the real gem
with `Kramdown::Document.new(md, input: "GFM", hard_wrap: false, gfm_quirks: [:paragraph_end,
:no_auto_typographic], smart_quotes: %w[apos apos quot quot]).to_html`, which is the dialect the port
follows (see "Where it follows GFM/CommonMark").

## API

| kramdown gem | Sake | |
|---|---|---|
| `Kramdown::Document.new(text, input: "GFM", ...).to_html` | `Kramdown.to_html(text)` | same output for the subset (options fixed as above) |
| `Kramdown::Document.new(text).root` (the element tree) | `Kramdown.parse(text)` → `Kramdown::Element[]` | differs: an Array of `Kramdown::Element` (kind, text, level, href, title, lang, children), not the gem's `Kramdown::Element` (type, value, attr, options, children) |
| `Kramdown::Converter::Html.convert(root)` | `Kramdown.render(nodes)` | same HTML |
| ATX / setext headings, GFM auto ids (`id="a-b"`, `-1` for repeats) | same | same |
| paragraphs, `*em*` `_em_` `**strong**` `__strong__`, `` `code` `` | same | same, including kramdown's closing rules (`**a* and *b**`) |
| indented and fenced code (``` and ~~~, `class="language-x"`) | same | same |
| `[t](u "title")`, `[t](<u>)`, `[t][id]`, `[t][]`, `[t]`, `![alt](src)`, `<http://autolink>`, `<mail@x>` | same | same; a link definition must be on one line |
| ordered / unordered lists, nested, tight / loose (transparent first paragraph) | same | same (kramdown's `parse_list` and `convert_li` rules) |
| blockquotes (lazy lines, nested), `<hr />`, `<br />` (two spaces, `\\`, GFM `\`) | same | same |
| escapes `\*`, entities `&amp;` `&#169;` `&#xA9;`, `<`/`>`/`&` escaping | same | named entities: 18 common names (`&copy;` → ©); kramdown knows them all |
| `--`, `---`, `...`, `"smart quotes"` typographic rewrites | — | missing by choice (disabled in the twin) |
| raw HTML (block and span), tables, footnotes, definition lists, `{:.class}` IALs, `{#id}`, math, abbreviations, `^` EOB marker | — | missing |
| `Document#warnings`, `to_kramdown`, `to_latex`, options (`auto_ids: false`, `header_offset`, ...) | — | missing |

### Where it follows GFM/CommonMark instead of kramdown's own dialect

kramdown's default parser has no ``` fences (they render as a paragraph) and lets no list or heading
interrupt a paragraph. The brief asks for fenced code, so the port is kramdown's **GFM** parser with
`hard_wrap: false`: ``` fences, a list / ATX heading / blockquote / fence ends a paragraph
(`paragraph_end` quirk), `\` before a newline is a hard break, header ids are GFM's (`[^\p{Word}\- \t]`
dropped, `-1` `-2` suffixes). Everything else (output indentation, blank-line placement, list
transparency, emphasis closing rules, lazy lines in code blocks and quotes) is kramdown's, taken from
its parser sources. Compared with CommonMark: `2*3*4` is `2<em>3</em>4`, `- item\n---` is a list whose
item holds a setext `<h2>`, four-space lines after a paragraph line continue the paragraph, lists of
`*`, `+`, `-` mix into one list, all as kramdown does.

## できたこと / できなかったこと

- できた: the brief's whole subset, with kramdown's exact HTML (indentation by 2, one `\n` per run of
  source blank lines, `<li>` without `<p>` for tight items, `<li>two\n    <ul>` with the newline that
  kramdown appends to a transparent paragraph followed by a nested list). The twin diff caught three
  behavioral bugs; the checker caught none on the first run (below).
- できなかった (by rule): kramdown's parser is a table of `define_parser(name, start_re)` entries
  dispatched with `send(@parsers[name].method)` and `parse_spans` takes a block as the stop
  condition (`parse_spans(el, stop_re) { count == 0 }`). Sake has no `send` and no stored blocks, so
  the dispatch is a `case` in `KBlocks.parse` / `KSpans.parse_one` in kramdown's order, and the stop
  condition is `KSpans.close_ok?(sc, node, stop, elem)` with the element kind selecting the rule.
  `@src[1]` / `$1` do not exist: every regexp result is `m = String.match(...)` then `m[1] || ""`.
- できなかった (by budget): raw HTML (kramdown parses it with REXML and keeps it as elements), tables,
  footnotes, IALs, the full entity table, typographic symbols.

## 書き心地

- **One Struct type for all nodes.** Wrote `KNode` with `kind` plus every field any kind needs
  (`text`, `level`, `href`, `title`, `lang`, `transparent`, `count`, `children`), as kramdown's
  `Element` (type, value, attr, options). The alternative, a type per kind with `(Header|P|Li).f`, would
  have cost a dispatch list at each use. Fields unused by a kind are `""`/`0`/`false` from
  `initialize`; only `title` is `nil | String`, and the checker made me write `t == nil ? "" : ...`
  in `title_attr` exactly once. The `mixed` heuristic never fired. A field reused for another meaning
  (`count` = open brackets while reading a link's text; in liquid `LNode.text` = the variable name of
  `assign`/`for`/`capture`) is the price; a comment names it.
- **First run under `--strict` passed with no report**, 690 lines. Three bugs then came from the twin
  diff, none of them a type: `parse_codespan` read `char_before(sc)` after advancing `@pos`, so it
  saw the backtick itself (wrote `@str[start - 1] || ""`); GFM's `\`-newline break; `""` renders as
  `"\n"`. The habit that made the checker quiet: `s[i]`, `m[1]`, `Array.first` always followed by
  `|| ""` or `|| raise(...)`, and `Array.fetch(@lines, i)` instead of `@lines[i]` for indexes the
  loop guards (`def line(b, i) = Array.fetch(@lines, i)`). `--strict=3` passes too.
- **Exhaustive `case` over node kinds.** `KHtml.convert` is a 17-branch `case KNode.kind(node)` with
  no `else`. Removing `in :br` gives `case/in: no `in` branch matches :br [type]` with the call chain
  to the test line: the checker knows the set of kinds because every `KNode.new(:x)` is a literal.
  This is the one place where Sake beat Ruby for a parser: kramdown's converter would raise
  `NoMethodError: convert_br` at run time on the first document with a break.
- **Returning two values.** `split_tag` / `parse_spans` return Tuples (`[found, pos]` was planned;
  ended with `found` and `@pos` in the scanner struct). `name, markup = split_tag(s)` reads as Ruby.
  `(String|Array|Hash).size(v)` for Ruby's duck-typed `x.size` also read well.
- **Where Sake was in the way.** (1) No `$~`: kramdown's `@src[2].nil? ? "mailto:#{@src[1]}" : @src[1]`
  becomes four lines with `m[1] || ""`. (2) `String.scan` with groups gives Tuples of `nil | String`,
  so `|key, val|` then `parse_expr(val)` is a `[nil]` report (in liquid; here I wrote `|| ""` first).
  (3) A predicate function does not narrow: `if number?(l) && number?(r) then l <=> r` reports every
  operand pair the Hash values may hold (a 10-line message, truncated with `…`); `case l in Integer |
  Float` does narrow. (4) Regexp interpolation `/\A {0,#{w}}[+*-]/` works, which saved the port of
  kramdown's `fetch_pattern(type, indentation)` table.
- **Writing a parser vs Ruby.** The shape is Ruby's: a struct with `@pos`, `while @pos < n`,
  `String.match(@str, /\G.../, @pos)` as `StringScanner#scan` (kramdown uses StringScanner; Sake's
  `strscan.sake` exists but the built-in `\G` form was enough). What is longer: every `scan` is two
  lines (`m = ...; @pos = MatchData.end(m, 0)`), every group read has `|| ""`. What is shorter:
  nothing, but nothing broke later either; the twin run was the only debugging.

## Built-ins requested

- `String.scan(s, re)` whose group Tuples are `String` when the group cannot be nil (no `?`/`|`): every
  `|k, v|` from scan currently needs `|| ""`.
- A `StringScanner`-like `String.scan_at(s, re, pos)` returning the MatchData only when it matches at
  `pos` (today: `String.match(s, /\G.../, pos)`, which needs `\G` written into every pattern and a
  separate `MatchData.end(m, 0)` to advance).
- `Hash` of HTML entity names (or `String.decode_entities`): kramdown resolves every named entity;
  the port carries 18 names.
- A way to say "this field is only for kind :x" is not a built-in but a wish: a per-kind field type
  would turn the `count`/`text` reuse above into a report.
