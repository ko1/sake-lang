# shellwords

`sakelib/shellwords.sake` ports all of Ruby's `Shellwords` module, including the methods it adds to
String and Array. Splitting uses Ruby's own regular expression and its rules for unescaping, quoting,
and error messages. `test/sakelib/shellwords.sake` covers empty input, every quoting form, backslash
and newline, unbalanced quotes and NUL, non-ASCII words, escaping of special characters, and
join-then-split round trips. Its output is identical to `shellwords.rb`.

## API

| Ruby | Sake | |
|---|---|---|
| `Shellwords.split(s)`, `.shellsplit`, `.shellwords` | the same names | same |
| `Shellwords.escape(x)`, `.shellescape` | the same names | same (any value, via `to_s`) |
| `Shellwords.join(a)`, `.shelljoin` | the same names | same |
| `s.shellsplit`, `s.shellescape` | `String.shellsplit(s)`, `String.shellescape(s)` | differs (subject first) |
| `a.shelljoin` | `Array.shelljoin(a)` | differs (subject first) |
| `include Shellwords` then `shellwords(s)` | | missing (module functions only) |

## What differs from Ruby, and why

- **Scanning.** Ruby uses `line.scan(re)` with `\G` and `$~.begin(0)`. Sake has no `\G` position and
  no `$~`, and `String.scan` returns only the groups. Each step matches the same pattern, anchored with
  `\A`, against `line[pos, n - pos]` and advances by the length of the match. The result is the same,
  but each step copies the rest of the line.
- `Shellwords.split` returns a `String[]` (an Array of String), so callers get Strings with no checks.

## Built-ins needed but missing

- `String.match(s, re, pos)` or `Regexp.match(re, s, pos)` with a start position (Ruby's optional
  `pos`), or `String.scan` with a block that receives the MatchData. Either would avoid copying the
  rest of the line at every word, and the first would keep Ruby's `\G` pattern unchanged.

## Friction

1. My own porting mistake, not a Sake problem: I added `/m` to `esc.gsub(/\\(.)/, '\\1')`, and
   `"foo\\\nbar"` split to `["foo\nbar"]` instead of Ruby's `["foo\\\nbar"]`. Comparing the outputs
   caught it.
2. No static reports. The library passed `--strict=3` on the first run.
