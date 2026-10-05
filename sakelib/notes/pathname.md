# pathname (Ruby's `require "pathname"`, plus File's path-string functions)

`sakelib/pathname.sake`: `class Pathname` (one field, `path`) with about 40 operations, and seven
functions added to `File` that Sake lacks and Pathname is built on (`File.basename`, `dirname`, `extname`,
`split`, `join`, `absolute_path?`, `directory?`, `file?`). Test: `test/sakelib/pathname.{sake,rb}`, identical
output with `--strict` (also clean at `--strict=1 -c`, `--strict=2 -c`; `--strict=3` reports one
`index-nil`, `a, b = r` in `relative_path_from`).

The path algorithms are Ruby's pathname.rb (3.x; in Ruby 4.0 Pathname is in C, same behaviour):
`chop_basename`, `plus`, `cleanpath_aggressive` / `cleanpath_conservative`, `relative_path_from`,
`ascend`. Separators are "/" only (no `File::ALT_SEPARATOR`).

## API

| Ruby | Sake | |
|---|---|---|
| `Pathname.new(s)` | same | same for a String: `initialize` checks `@path => String` and NUL (`ArgumentError: path name contains null byte`). Ruby also takes a Pathname or any `to_path`; Sake: use `Pathname(x)` |
| `Pathname(x)` (Kernel) | `Pathname(x)` | same (a top-level `def Pathname(x)`; String or Pathname) |
| `to_s`, `to_path`, `inspect` | `Pathname.to_s(pn)` ... | same (`#<Pathname:a/b>`); `puts pn` and `"#{pn}"` use `to_s` |
| `pn + x`, `pn / x` | same operators | same (x a String or a Pathname) |
| `join(*args)` | `Pathname.join(pn, *args)` | same |
| `parent`, `absolute?`, `relative?`, `root?` | same | same |
| `cleanpath(consider_symlink = false)` | same | same |
| `basename(suffix = "")`, `dirname`, `extname`, `split` | same | same (`".*"` suffix) |
| `each_filename {}`, `ascend {}`, `descend {}` | same | same with a block; without one, an Array (Ruby: an Enumerator) |
| `relative_path_from(base)` | same | same, including both ArgumentErrors and their messages |
| `sub_ext(repl)`, `sub(pat, repl)` | same | same (sub: String or Regexp, String replacement) |
| `==` | same | same (Struct equality on the path) |
| `<=>` | `Pathname.<=>(a, b)` | differs: not an operator, Pathname does not include `Comparable`; see below |
| Pathname as a Hash key | same | same |
| `exist? file? directory? read readlines write delete unlink` | same | same, through File; errors are `IOError` (Ruby: `Errno::*`) |
| `find {}` | `Pathname.find(pn) {}` | in `find.sake` (as Ruby's pathname.rb defines it in the find part) |
| `children entries glob opendir mkpath rmtree realpath expand_path stat mtime size symlink? ...`, `Pathname.pwd`, `Pathname.glob` | — | missing: Sake has no directory, stat, or cwd primitives |
| `File.basename(p, suffix = "")`, `dirname`, `extname`, `split`, `join(*parts)`, `absolute_path?` | same | same (tested on 16 edge cases: `""`, `"//"`, `"a."`, `".a.b"`, `"a..b"`, ...); `File.dirname(p, level)` missing |
| `File.directory?`, `File.file?` | same | same results; implemented as "exists, and reading it fails with EISDIR" (no stat) |

## Differences and why

- **No `Comparable`.** Including it with `<=>` would make Pathname values unusable as Hash keys (spec
  §12.1: a type with its own equality is rejected as a key), and paths as keys are common (`h[path]`).
  Sorting paths is common too; the test sorts with `Array.sort_by { |x| String.tr(Pathname.to_s(x), "/",
  "\0") }`, which is Ruby's order. Ruby has both because `eql?`/`hash` are separate from `<=>`.
- **`Pathname.new` takes a String only.** Accepting a Pathname would make the field `String | Pathname`
  (a field's type is what is written to it, and `new` writes the argument before `initialize` runs);
  `Pathname(x)` and the internal `Pathname.path_of(x)` convert instead.
- **Without a block, `each_filename`/`ascend`/`descend` give an Array** (no Enumerators).
- **File's path functions live in `pathname.sake`**, as operations added to `File`; a second library
  defining `File.basename` would collide when both are required.
- **Missing-file errors are `IOError`** (Sake's File raises it), not `Errno::ENOENT`; the Ruby test rescues
  `IOError, SystemCallError`.

## Frictions (wrote first → message → wrote instead)

- `def path_of(x) = case x in Pathname then ... in String then x end` → `syntax error: expected a when or
  in clause after case` → a multi-line `case`. (Ruby's grammar: `case x in` on one line is `x in P`.)
- `File.join(*names)` with `def join(*parts)` → `` `*names`: splat arguments go only to built-ins ...
  hint: File.join takes a fixed number of arguments `` → `File.join(names)` (join flattens, like Ruby's).
  The hint is wrong for a `*rest` function; repro: `notes/pathname_bug_splat_to_rest.sake`.
- `Pathname.new(path_of(Array.pop(args)))` → `case/in: no in branch matches nil [type]` (pop may be nil
  though `args` was checked non-empty) → `last = Array.pop(args); last => Pathname | String`.
- `String.[](File.dirname(path), /\/*\z/)` (Ruby's `str[/re/]`) → `Indexable.[]: the index must be
  Integer, but is Regexp` → `String.match` + `MatchData.to_s`.
- `Array.sort(paths) { |a, b| Pathname.<=>(a, b) }` → `Array.sort does not take a block` → `sort_by`.
- Ruby's `path[0, path.rindex(base)]` and similar: every `String.[](s, i, n)` needs `|| ""`.

## Language features used

- **`initialize` + `x => T`**: `@path => String` and the NUL check, where Ruby's `Pathname.new` checks.
- **Optional arguments**: `basename(pn, suffix = "")`, `cleanpath(pn, consider_symlink = false)`,
  `File.basename(path, suffix = "")`.
- **`*rest`**: `Pathname.join(pn, *args)`, `File.join(*parts)` — but a caller cannot splat into them.
- **`block_given?`**: `each_filename`, `ascend`, `descend` give an Array without a block.
- **`x => A | B`** to narrow `Array.pop`'s result.
- `include Arithmetic` for `+` and `/`; a top-level `def Pathname(x)`.

## Checker findings before the test passed

`--strict` (level 2) run: the two `[type]` reports above (`case/in` on nil from `Array.pop`; a Regexp
index on a String). After the fixes, `--strict=1 -c` and `--strict=2 -c`: OK.

## `--types`

Fields: `Pathname.path: String`. No unknowns. The only union is the test's own nested literal
`File.join("a", Array["b", Array["c"]])` (`String | Array[String]`), which `File.join` flattens.
