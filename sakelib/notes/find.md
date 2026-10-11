# find (Ruby's `require "find"`)

`sakelib/find.sake`: `Find.find(*paths, ignore_error: true) {}`, `Find.prune`, and Ruby's
`Pathname#find` as `Pathname.find(pn, ignore_error: true) {}` (requires `pathname`). Test:
`test/sakelib/find.{sake,rb}`, identical output with `--strict` (also clean at `--strict=3 -c`). The
test builds a tree in a `Dir.mktmpdir` directory and shows each path relative to it.

2026-10-05: rewritten on `Dir.children` and `File.symlink?`. The walk is Ruby's find.rb: depth first,
each directory's children sorted, symbolic links to directories not followed, and a directory that
cannot be listed skipped when `ignore_error` (the default). The earlier version, written when Sake could
not list a directory, raised IOError when it would descend.

## API

| Ruby | Sake | |
|---|---|---|
| `Find.find(*paths) { \|f\| }` | same | same order and paths (`File.join(dir, name)`) |
| `Find.find(*paths)` (no block, Enumerator) | same | an Array of the paths |
| `Find.find(..., ignore_error: false)` | same | same: an unlistable directory raises IOError |
| missing path | IOError before anything is yielded | same order as Ruby (Ruby: `Errno::ENOENT`) |
| `Find.prune` | same | same effect; an exception (`Find::Prune`) that Find.find rescues, where Ruby uses `throw :prune`. Outside Find.find, `Find::Prune` reaches the top (Ruby: `UncaughtThrowError`) |
| `Pathname#find` | `Pathname.find(pn) {}` | same, "./" dropped for ".", as Ruby |

## Frictions

- Ruby's `catch(:prune)` / `throw` do not exist; an exception type does the same job (`def prune = raise
  FindPrune`). It is visible to the user (`rescue => e` inside the block would catch it).
- Ruby's walk uses `File.lstat` once per path; Sake asks `File.directory?` and `File.symlink?` (two
  stats), with no stat value.

## Language features used

- **`*rest` + keyword**: `def find(*paths, ignore_error: true)`, called `Find.find("a", "b")` and
  `Find.find(@path, ignore_error:)`.
- **`yield` inside a `while` loop and a `begin/rescue`**, and `next` out of the loop body.
- **`block_given?`**: the Array result without a block (Ruby's Enumerator).
- **Adding to another library's class**: `class Pathname ... def find` in find.sake, as Ruby's
  pathname.rb reopens Pathname.

## `--types`

No fields of its own (`Pathname.path: String`); no unions or unknowns.
