# fileutils (Ruby's `require "fileutils"`, common subset)

`sakelib/fileutils.sake`: `module FileUtils` (module functions), 22 public operations, on regular files.
Requires `pathname` (for `File.basename`/`join`/`directory?` and Pathname arguments). Test:
`test/sakelib/fileutils.{sake,rb}`, identical output with `--strict` (also clean at `--strict=3 -c`).

**Sake has no directory primitives** (no `Dir.mkdir`, `rmdir`, `rename`, `stat`, `utime`, listing). So:
an existing directory can be a destination and `mkdir_p` of it is a no-op, but creating or removing a
directory raises `IOError`. **Deviation from the brief:** the tests cannot create a temporary directory
(the Sake side has no way to), so both work on files named `_fu_*` in the test's directory (and one in
`..`, an existing directory used as a `cp` destination), and remove each one at the end.

## API

| Ruby | Sake | |
|---|---|---|
| `cp(src, dest, preserve:, noop:, verbose:)`, `copy` | same | same for files: src a path or a list, dest a file or an existing directory; `same file` ArgumentError; `preserve:` accepted and ignored (no stat). Copying a directory raises IOError *before* creating dest (Ruby leaves an empty dest file) |
| `copy_file(src, dest)` | same | same (bytes preserved; tested with `\x00\xFF\r\n\x80`); Ruby's `preserve`/`dereference` args missing |
| `mv(src, dest, force:, noop:, verbose:, secure:)`, `move` | same | same for files (result 0, as Ruby); a copy then a delete, since there is no rename: not atomic, slower; a directory raises IOError |
| `rm(list, force:, noop:, verbose:)`, `remove` | same | same |
| `rm_f(list)`, `safe_unlink` | same | same |
| `rm_r`, `rm_rf`, `rmtree` | same | same for files; a directory raises IOError even with force (rather than being silently kept) |
| `touch(list, noop:, verbose:, nocreate:)` | same | creates missing files; an existing file is unchanged (Ruby updates its mtime; no utime). `mtime:` missing |
| `mkdir_p(list, mode:, noop:, verbose:)`, `makedirs`, `mkpath` | same | same when every path is an existing directory or `noop:`; an existing file raises (Ruby `EEXIST`); a new directory raises IOError |
| `mkdir(list, ...)` | same | an existing path raises, as Ruby; a new one raises IOError (cannot create) |
| `rmdir(list, parents:, ...)` | same | a missing path or a file raises, as Ruby; an existing directory raises IOError (cannot remove) |
| `compare_file`, `identical?`, `cmp` | same | same |
| `verbose: true` | same | same message (`cp a b`, `rm -f x`, `mkdir -p d`) on `IO.stderr` |
| return values | same | same: lists for rm/touch/mkdir_p, nil for cp and for `noop:` (except mkdir_p, which gives the list, as Ruby) |
| `cp_r`, `ln`, `ln_s`, `install`, `chmod`, `chown`, `pwd`, `cd`, `uptodate?`, `remove_dir`, `copy_entry`, `FileUtils::Verbose`/`NoWrite`/`DryRun` | — | missing (directories, links, modes, cwd: no primitives; nested modules: no nested names) |

## Differences and why

- Errors are `IOError` with messages like `No such file or directory - x` (Sake's File raises
  IOError); Ruby raises `Errno::ENOENT` etc. (`SystemCallError`). The Ruby test rescues
  `SystemCallError` and both print `error`.
- Lists are `String`, `Pathname`, or an Array of them (Ruby flattens nested Arrays; Sake takes one level).

## Frictions

- None from the checker: the module passed `--strict=1/2 -c` on the first run. The cost was in
  the missing primitives, which leave half of FileUtils unimplementable.
- Ruby's `def rm_f(list, noop: nil, verbose: nil) = rm(list, force: true, noop: noop, verbose: verbose)`
  is written with the `k:` shorthand (`noop:, verbose:`) — the keyword forwarding reads as in Ruby.
- First test run differed from Ruby in return values under `noop:` (Ruby `return if noop` → nil) and in
  the empty file Ruby's `cp(dir, file)` leaves behind (test then removes it on both sides).

## Language features used

- **Keyword arguments with defaults** everywhere (`noop: false, verbose: false, force: false`), and the
  `k:` shorthand to forward them: `def rm_f(list, noop: false, verbose: false) = rm(list, force: true, noop:, verbose:)`.
  Misspelled keywords are reported before running, which Ruby only finds when the line runs.
- **`case x in Array ... in String | Pathname`** for Ruby's "a path or a list" (`fu_list`).
- **Blocks passed through a module function with `yield`**: `fu_each_src_dest(src, dest) { |s, d| ... }`.
- **`raise` re-raise in `rescue`** for `force:`.

## Checker findings before the test passed

`--strict=1 -c`, `--strict=2 -c`: OK on the first run; `--strict=3 -c`: OK.

## `--types`

Fields: only `Pathname.path: String` (from pathname). No unions or unknowns in FileUtils' functions;
the test's `show` gives `[String, true|false]` Tuples.
