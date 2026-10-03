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
| `CGI.escape(s, encoding)` (2nd arg) | — | missing: Sake functions have no optional arguments; UTF-8 only |
| `CGI.escapeElement`, `unescapeElement`, `CGI.rfc1123_date`, `CGI.pretty` | — | missing: removed from Ruby 4.0's cgi (CGI::Util) |
| `CGI.new`, `CGI::Cookie`, ... | — | missing: removed from Ruby 4.0 |

Helpers `CGI._percent_encode`, `CGI._percent_decode`, `CGI._char_ref` are visible (Sake has no
private functions); the leading `_` marks them internal.

## Differences and why

- Arguments must be Strings (Ruby's accept anything with `to_str`); each operation names its type.
- Ruby's versions keep the argument's encoding; Sake's always return UTF-8 (Sake has no
  `Encoding` objects to pass around).

## Built-ins Sake lacks (requests)

- `String.gsub(s, re) { |m| ... }` or `String.gsub(s, re, Hash)`: Ruby's own pure-Ruby fallback
  for these functions is one `gsub` with a table; without it every escaper is split-and-rebuild.
- `String.index(s, t, pos)` (an offset): scanning a String left to right needs it; I used
  `String.split` with a capturing Regexp instead.

## Friction

- `String.to_i(m[2])` (a group that always participates) → level 3 `index-nil` report →
  `String.to_i("#{m[2]}")`. Fine at `--strict` (level 2).
- `require "cgi"` in `test/sakelib/cgi.sake` used to load the test file itself; the loader was fixed
  during this port (the requiring file is never chosen now).
