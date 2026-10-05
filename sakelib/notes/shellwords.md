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

- **Scanning.** Ruby uses `line.scan(re)` with `\G` and `$~.begin(0)`. Sake's `String.scan` returns
  only the groups and there is no `$~`, so the loop calls `String.match(line, re, pos)` with Ruby's
  `\G` pattern unchanged and moves to `MatchData.end(m, 0)`.
- `Shellwords.split` returns a `String[]` (an Array of String), so callers get Strings with no checks.

## Built-ins needed but missing

- None (`String.match(s, re, pos)`, requested in phase 1, now exists). `String.scan` with a block
  receiving the MatchData would make the loop Ruby's exactly.

## Friction

1. My own porting mistake, not a Sake problem: I added `/m` to `esc.gsub(/\\(.)/, '\\1')`, and
   `"foo\\\nbar"` split to `["foo\nbar"]` instead of Ruby's `["foo\\\nbar"]`. Comparing the outputs
   caught it.
2. No static reports. The library passed `--strict=3` on the first run.

## Phase 2

- No names to restore (Ruby's Shellwords has no optional arguments).
- `shellsplit` matches Ruby's `\G` pattern at a position (`String.match(line, re, pos)`) instead of
  an `\A` pattern on a copy of the rest of the line; the five-way `if` for the piece became Ruby's
  `word || sq || (dq && ...) || esc.gsub(...)`.
- Speed (`phase2/bench_shellwords.sake`: split a 2000-word line, join, split again; CPU s of the
  whole `bin/sake --strict` run, 3 runs, load about 37 on 16 cores): before 2.76 / 2.74 / 2.86,
  after 2.35 / 2.29 / 2.33. The copies were cheap next to the interpreter's cost per word.

## Review 2026-10-05

No change: module functions only, as Ruby's. `shellescape(x)` takes any value (Ruby's `str.to_s`), so its parameter is a union of whatever callers pass (Integer | String | Symbol in the test). `--strict=1`/`2`: 0 reports before and after.

## 2026-10-05

Checked against the new features; nothing applies (module functions only, no keywords or rest arguments in Ruby's API). No change to the library or the test.
