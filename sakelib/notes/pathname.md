# pathname (Ruby's `require "pathname"`)

`sakelib/pathname.sake`: `class Pathname` (one field, `path`) with about 65 operations. Test:
`test/sakelib/pathname.{sake,rb}`, identical output with `--strict` (also clean at `--strict=1 -c`,
`--strict=2 -c`; `--strict=3` reports one `index-nil`, `a, b = r` in `relative_path_from`). The file
system part of the test works in a `Dir.mktmpdir` directory and shows paths relative to it.

2026-10-05: the eight functions this library used to add to `File` (`basename`, `dirname`, `extname`,
`split`, `join`, `absolute_path?`, `directory?`, `file?`) are built-ins now and were removed from it (a
built-in cannot be redefined); the 16 edge cases of the test give the same results with them. With the
new `Dir` / `File` built-ins, Pathname gained `children`, `each_child`, `entries`, `glob`, `Pathname.glob`,
`Pathname.pwd`/`getwd`, `realpath`, `expand_path`, `mkdir`, `rmdir`, `mkpath`, `rmtree`, `rename`,
`size`, `mtime`, `ftype`, `symlink?`, `zero?`, `empty?`; `delete` removes a directory too, as Ruby's.

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
| `exist? file? directory? symlink? zero? empty? size mtime ftype read readlines write rename mkdir rmdir delete unlink` | same | same, through the built-in File and Dir; errors are `IOError` (Ruby: `Errno::*`) |
| `expand_path(dir = nil)`, `realpath(dir = nil)` | same | same |
| `children(with_directory = true)`, `each_child`, `entries` | same | same (the directory's own order, as Ruby); `each_child` without a block gives the Array |
| `pn.glob(pattern)` · `Pathname.glob(pattern, base: nil)` | `Pathname.glob(pn, pattern)` · `Pathname.glob(pattern, base:)` | same; one function for both, told apart by the first argument's type (as `Time.xmlschema` in time.sake) |
| `Pathname.pwd`, `getwd` · `mkpath` · `rmtree` | same | same (`mkpath` and `rmtree` give pn, as Ruby 3.1+; written here rather than through FileUtils) |
| `find {}` | `Pathname.find(pn) {}` | in `find.sake` (as Ruby's pathname.rb defines it in the find part) |
| `opendir`, `stat`, `lstat`, `atime`/`ctime`, `chmod`, `make_link`, `make_symlink`, `readlink`, `realdirpath`, `truncate`, `open`, `each_line`, `binread`, `+@`... | — | missing (no stat or Dir value; not needed yet) |
| `File.basename`, `dirname`, `extname`, `split`, `join`, `absolute_path?`, `directory?`, `file?` | built-ins | formerly defined here; now Sake's own (the test's 16 edge cases are unchanged) |

## Differences and why

- **No `Comparable`.** Including it with `<=>` would make Pathname values unusable as Hash keys (spec
  §12.1: a type with its own equality is rejected as a key), and paths as keys are common (`h[path]`).
  Sorting paths is common too; the test sorts with `Array.sort_by { |x| String.tr(Pathname.to_s(x), "/",
  "\0") }`, which is Ruby's order. Ruby has both because `eql?`/`hash` are separate from `<=>`.
- **`Pathname.new` takes a String only.** Accepting a Pathname would make the field `String | Pathname`
  (a field's type is what is written to it, and `new` writes the argument before `initialize` runs);
  `Pathname(x)` and the internal `Pathname.path_of(x)` convert instead.
- **Without a block, `each_filename`/`ascend`/`descend` give an Array** (no Enumerators).
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
