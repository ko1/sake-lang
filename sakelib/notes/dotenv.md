# dotenv

`sakelib/dotenv.sake`: the dotenv gem (3.2.0, installed; the Ruby twin `test/sakelib/dotenv.rb` runs the real
gem). `.env` files into ENV: `Dotenv.load`, `overload`, `parse`, `update`, `modify`, `require_keys`, and the
parser `Dotenv::Parser.call(text)` with the gem's whole syntax (comments, `export`, `KEY: value`, single and
double quotes, `\"` / `\\` unescaping, `$VAR` / `${VAR}` substitution, `$(cmd)` command substitution,
`DOTENV_LINEBREAK_MODE`). 11 operations, 2 exception types; the test prints 51 lines, identical to the gem's.

## API

| Ruby (dotenv) | Sake | |
|---|---|---|
| `Dotenv.load(*files, overwrite:, ignore:)` → Hash of changed keys | `Dotenv.load(*files, overwrite:, ignore:)` | same |
| `Dotenv.load!(*files)` (Errno::ENOENT) | `Dotenv.load!(*files)` (IOError) | differs: exception type |
| `Dotenv.overwrite` / `overload` / `overwrite!` / `overload!` | same names | same |
| `Dotenv.parse(*files, overwrite:, ignore:)` → Hash | `Dotenv.parse(*files, ...)` | same (no block per file) |
| `Dotenv::Parser.call(text, overwrite:)` → Hash | `Dotenv::Parser.call(text, overwrite:)` | same (nested, as Ruby; was `DotenvParser` before 2026-10-10) |
| `Dotenv.update(env, overwrite:)` → Hash of changed keys | `Dotenv.update(env, overwrite:)` | same (`overwrite: :warn` missing) |
| `Dotenv.modify(env) { }` | `Dotenv.modify(env) { }` | same |
| `Dotenv.require_keys(*keys)` (Dotenv::MissingKeys) | `Dotenv.require_keys(*keys)` (Dotenv::MissingKeys) | same message |
| `Dotenv::FormatError` (a SyntaxError) | `Dotenv::FormatError` | same name and message (was `DotenvFormatError` before 2026-10-10) |
| `Dotenv.save` / `Dotenv.restore` | — | missing (`modify` restores by itself; no `ENV.replace`) |
| `Dotenv.instrumenter`, Rails railtie, `dotenv/autorestore`, `dotenv/tasks`, `Dotenv::Template`, the `dotenv` CLI | — | missing: Rails / Minitest hooks and ActiveSupport::Notifications |

## できたこと / できなかったこと

- Done: the parser is the gem's regular expressions unchanged (`LINE` with its named groups, `VARIABLE`,
  the recursive `INTERPOLATED_SHELL_COMMAND` with `\g<cmd>`), the same substitution order (unescape,
  commands, variables), the same `existing?` rule (an ENV value wins unless `overwrite:`, except
  `DOTENV_LINEBREAK_MODE`), and the gem's 3.x line-break rule: `"a\nb"` stays `a\nb` unless
  `DOTENV_LINEBREAK_MODE=legacy` (verified against the gem first; the brief's "`\n` expands" is dotenv 2.x).
  `$(cmd)` runs through `Open3.capture2("sh", "-c", cmd)`, the gem's backticks.
- `Dotenv.update` returns the gem's `Diff.env`: the keys whose ENV value changed, **in ENV's order**, not the
  file's. The first version collected changed keys while walking the file and the outputs differed in one
  line; porting the gem's design (snapshot `ENV.to_h` before and after, `Hash.select`) fixed it.
- Not done, Sake rule: `Dotenv.save`/`restore` need `ENV.replace`; `restore`'s `Thread.current == Thread.main`
  safety check has no equivalent (`Thread.current` exists, `Thread.main` does not). `Dotenv.instrumenter`
  stores an object with a `instrument` method (duck typing). The Rails/Minitest integrations patch other
  libraries' classes.
- `Dotenv::FormatError < SyntaxError`: not a StandardError in Ruby, so `rescue => e` misses it (I hit that
  probing the gem). Sake has no exception hierarchy; `rescue Dotenv::FormatError` is the only form, and the
  trap does not exist.
- Names (2026-10-10): `Dotenv::Parser`, `Dotenv::FormatError`, `Dotenv::MissingKeys` are declared inside
  `module Dotenv` and match Ruby; they were `DotenvParser` / `DotenvFormatError` / `DotenvMissingKeys`.

## 書き心地

- Ran under `--strict` on the first try, with no report. The one wrong output (the Hash order above) was a
  design difference the checker could not see.
- Wrote `String.gsub(value, variable_re) { |var| ... match[3] ... }` as the gem's `gsub(VARIABLE) { $LAST_MATCH_INFO }`
  → the block gets the matched String, and Sake has no `$~` → `m = String.match(var, variable_re)` inside the
  block, matching the piece again. Works, reads as a repetition.
- Wrote `String.scan(text, line_re)` for the gem's `@string.scan(LINE) { match = $LAST_MATCH_INFO }` → `scan`
  with groups gives only the captures, and the error message needs the whole line (`Line "export Z" has an
  unset variable`) → a loop of `Regexp.match(line_re, text, pos)` with `pos = MatchData.end(m, 0)`. Clear once
  written, three lines longer than Ruby.
- `m["key"] || ""`: a named group is `String | nil` and `--strict` asks for the `|| ""` even where the regexp
  guarantees the group; the gem's `match[:key]` has the same nil in principle, unchecked.
- `def line_re = once { /.../ }` for the gem's `LINE = /.../x` constant: the `x` flag's comments were dropped
  into one line. No value constants is the one Sake rule that hurt the reading of this file.
- `Dotenv.parse(*filenames, overwrite: false, ignore: true)`: a rest parameter with keyword defaults works
  as Ruby's; `Array.empty?(filenames) ? String[".env"] : filenames` for the gem's `filenames << ".env"`.
- Helped: `Dotenv.modify(env) { ... }` with `begin / ensure` restoring from a `before = ENV.to_h` snapshot
  reads as the gem's; `Dotenv.update`'s `Hash.select(ENV.to_h) { |k, v| before[k] != v }` is the Diff in one line.
- `Open3.capture2("sh", "-c", cmd)` returning `[out, status]` as a Tuple: `out, _status = ...`, like Ruby.

## Built-ins requested

- `String.gsub` block receiving the MatchData (or `MatchData` of the last match, `Regexp.last_match`): the
  gem's substitution callbacks all read groups of the current match; today the piece is matched twice.
- `String.scan` with a block that gets the MatchData (Ruby's `scan(re) { $~ }`): a loop of
  `Regexp.match(re, s, pos)` + `MatchData.end` is the workaround.
- `ENV.replace(hash)` (and `ENV.clear`): `Dotenv.restore` and `Dotenv.save` want to replace ENV wholesale.
- A `Thread.main` or `Thread.main?` : `restore`'s "not thread safe" guard.
