# cgi (Ruby's cgi/escape)

`require "cgi"` loads `sakelib/cgi.sake`: the escaping functions that remain in Ruby 4.0's `cgi/escape`
(the rest of CGI was removed from Ruby 4.0). Test: `test/sakelib/cgi.sake` / `cgi.rb` (identical output).

## API

| Ruby | Sake | |
|---|---|---|
| `CGI.escape(s)` | `CGI.escape(s)` | same (bytes outside `a-zA-Z0-9_.-~` become `%XX`, space becomes `+`) |
| `CGI.unescape(s)` | `CGI.unescape(s)` | same (`+` is a space; a lone `%` stays; result is UTF-8, possibly invalid) |
| `CGI.escapeURIComponent(s)`, `escape_uri_component` | same names | same (space becomes `%20`) |
| `CGI.unescapeURIComponent(s)`, `unescape_uri_component` | same names | same (`+` stays) |
| `CGI.escapeHTML(s)`, `escape_html` | same names | same (`& < > " '` → `&amp; &lt; &gt; &quot; &#39;`) |
| `CGI.unescapeHTML(s)`, `unescape_html` | same names | same: `&amp; &quot; &gt; &lt; &apos;`, `&#NNN;`, `&#xHH;`/`&#XHH;`; a numeric reference decodes only below U+10FFFF, as Ruby's C code does (so `&#x10FFFF;` stays); a surrogate gives its raw (invalid) bytes, as Ruby |
| `CGI.unescape(s, encoding)`, `unescapeURIComponent(s, encoding)` | same | same, with the encoding as a name (`"ASCII-8BIT"`); Ruby also takes an `Encoding` |
| `CGI.escape(s)` of a non-UTF-8 String | — | differs: the result is always UTF-8 (Ruby keeps the argument's encoding) |
| `CGI.escapeElement`, `unescapeElement`, `CGI.rfc1123_date`, `CGI.pretty` | — | missing: removed from Ruby 4.0's cgi (CGI::Util) |
| `CGI.new`, `CGI::Cookie`, ... | — | missing: removed from Ruby 4.0 |

Helpers `CGI._percent_encode`, `CGI._percent_decode`, `CGI._char_ref`, `CGI.html_table` are visible (Sake has no
private functions); the leading `_` marks them internal.

## Differences and why

- Arguments must be Strings (Ruby's accept anything with `to_str`); each operation names its type.
- Ruby's escapers keep the argument's encoding; Sake's return UTF-8 (Sake has no `Encoding`
  objects). The unescapers take an encoding name, default `"UTF-8"`.

## Built-ins Sake lacks (requests)

- None now: `String.gsub` with a Hash or a block and `String.b` (phase 2) made each function one
  `gsub`, as Ruby's pure-Ruby fallback is.

## Friction

- `String.to_i(m[2])` (a group that always participates) → level 3 `index-nil` report →
  `String.to_i("#{m[2]}")`. Fine at `--strict` (level 2).
- `require "cgi"` in `test/sakelib/cgi.sake` used to load the test file itself; the loader was fixed
  during this port (the requiring file is never chosen now).

## Phase 2

- Restored Ruby's optional argument: `unescape(s, encoding = "UTF-8")`,
  `unescapeURIComponent(s, encoding = "UTF-8")` (and `unescape_uri_component`); tested with
  `"ASCII-8BIT"` and `"UTF-8"`.
- Every function is one `gsub`, as Ruby's `cgi/escape` fallback: `escape` replaces each unsafe run with
  `%XX` per byte (block), `unescape` turns each `%XX` run into bytes with `pack("H*")` (block),
  `escapeHTML` uses a Hash built once (`html_table = once { ... }`), `unescapeHTML` a block. The
  split-and-rebuild loops are gone (81 → 55 lines).
- Speed (`phase2/bench_cgi.sake`: escape/unescape, URI component, HTML escape/unescape of 20 KB; CPU s
  of the whole `bin/sake --strict` run, 3 runs, load about 37 on 16 cores): before 3.97 / 4.11 / 4.19,
  after 1.83 / 1.85 / 1.76.
