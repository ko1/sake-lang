# fileutils (Ruby's `require "fileutils"`, common subset)

`sakelib/fileutils.sake`: `module FileUtils` (module functions), about 40 public operations on files and
directories. Requires `pathname` (Pathname arguments, `Pathname.remove_tree`). Test:
`test/sakelib/fileutils.{sake,rb}`, identical output with `--strict` (also clean at `--strict=3 -c`). The
test works in a `Dir.mktmpdir` directory, as Ruby's own tests do, and shows paths relative to it.

2026-10-05: rewritten on the new built-ins `Dir.mkdir`, `rmdir`, `children`, `glob`, `mktmpdir`,
`File.rename`, `utime`, `symlink`, `link`, `chmod`, `mtime`, ... The earlier version, written when Sake had
no directory primitives, raised IOError for every directory operation and copied+deleted for `mv`.

## API

| Ruby | Sake | |
|---|---|---|
| `cp(src, dest, preserve:, noop:, verbose:)`, `copy` | same | same for files: src a path or a list, dest a file or a directory; `same file` ArgumentError; `preserve:` keeps the times. Copying a directory raises IOError *before* creating dest (Ruby leaves an empty dest file). Result nil (Ruby gives the list when src is a list) |
| `copy_file(src, dest, preserve = false)` | same | same (bytes preserved) |
| `cp_r(src, dest, ...)`, `copy_entry(src, dest, preserve = false)` | same | same for files and directories (into dest/basename(src) when dest is a directory); symbolic links are followed, Ruby copies them as links |
| `mv(src, dest, force:, noop:, verbose:, secure:)`, `move` | same | same (`File.rename`; result 0); across file systems Ruby copies then removes, Sake raises IOError |
| `rm(list, force:, noop:, verbose:)`, `remove`, `rm_f`, `safe_unlink` | same | same |
| `rm_r`, `rm_rf`, `rmtree`, `remove_entry`, `remove_dir`, `remove_file` | same | same (a directory with its contents; a symbolic link removed, not followed). `remove_*` give nil (Ruby: internal counts) |
| `touch(list, noop:, verbose:, mtime:, nocreate:)` | same | same (creates missing files, sets times with `File.utime`) |
| `mkdir_p(list, mode:, noop:, verbose:)`, `makedirs`, `mkpath` | same | same; an existing file in the way raises |
| `mkdir(list, mode:, ...)` · `rmdir(list, parents:, ...)` | same | same |
| `ln`, `link`, `ln_s`, `symlink`, `ln_sf` (`force:`) | same | same (result 0) |
| `chmod(mode, list)` | same | an Integer mode only (Ruby also takes `"u+x"`) |
| `uptodate?(new, old_list)` · `pwd` | same | same |
| `compare_file`, `identical?`, `cmp` | same | same |
| `verbose: true` | same | same message (`cp a b`, `rm -f x`, `mkdir -p d`) on `IO.stderr` |
| `cd`/`chdir`, `chown`, `install`, `cp_lr`, `ln_sr`, `remove_entry_secure`, `compare_stream`, `FileUtils::Verbose`/`NoWrite`/`DryRun` | — | missing (no `Dir.chdir`, owners, IO copy streams; nested modules: no nested names) |

## Differences and why

- Errors are `IOError` with Ruby's messages (`No such file or directory @ rb_sysopen - x`); Ruby raises
  `Errno::ENOENT` etc. (`SystemCallError`). The Ruby test rescues `SystemCallError` and both print `error`.
- Lists are `String`, `Pathname`, or an Array of them (Ruby flattens nested Arrays; Sake takes one level).
- The list-returning functions give nil under `noop:` (as Ruby's `return if noop`); the test's `rel`
  helper takes `nil` for the checker, which sees `nil | Array` as the result.

## Frictions

- Ruby's `File.stat(f).mode` has no counterpart (no stat value); the test checks `File.executable?` after
  `chmod` instead.
- Ruby's `mv` / `cp` of a list return the list only by accident of their internals; the test does not
  print those.

## Language features used

- **Keyword arguments with defaults** everywhere (`noop: false, verbose: false, force: false`), and the
  `k:` shorthand to forward them: `def rm_f(list, noop: false, verbose: false) = rm(list, force: true, noop:, verbose:)`.
- **`case x in Array ... in String | Pathname`** for Ruby's "a path or a list" (`fu_list`).
- **Blocks passed through a module function with `yield`**: `fu_each_src_dest(src, dest) { |s, d| ... }`.
- **Recursion** for `copy_entry` and `Pathname.remove_tree`.
- **`raise` re-raise in `rescue`** for `force:`.
- A built-in keyword: `Dir.glob("**/*", base: dir)` in the test.

## Checker findings before the test passed

`--strict` run: `Array.map: argument 1 may be nil` for `rel(FileUtils.touch(...))` (the result is
`nil | Array` because of `noop:`) → the test's helper takes nil. `--strict=3 -c`: OK.

## `--types`

Fields: only `Pathname.path: String` (from pathname). No unknowns.
