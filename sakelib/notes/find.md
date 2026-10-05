# find (Ruby's `require "find"`)

`sakelib/find.sake`: `Find.find(*paths, ignore_error: true) {}`, `Find.prune`, and Ruby's
`Pathname#find` as `Pathname.find(pn, ignore_error: true) {}` (requires `pathname`). Test:
`test/sakelib/find.{sake,rb}`, identical output with `--strict`.

**Sake cannot list a directory**, so Find.find yields each given path and raises IOError (`listing a
directory is not available in Sake - d`) when it would descend into a directory. A directory the block
prunes is never listed, so `Find.find(".") { |f| ...; Find.prune }` works. This is honest but makes the
library mostly a placeholder until Sake has `Dir.children` (or `Dir.entries`) and a directory test.
**Deviation from the brief:** no temporary directory (Sake cannot create one); the test uses files
`_find_*` in its own directory and the existing directories `.` and `..`, and removes its files.

## API

| Ruby | Sake | |
|---|---|---|
| `Find.find(*paths) { |f| }` | same | same for files and pruned directories; recursion missing (IOError) |
| `Find.find(*paths)` (no block, Enumerator) | same | an Array of the paths (directories raise) |
| `Find.find(..., ignore_error: false)` | same | accepted; Sake never ignores an error |
| missing path | IOError before anything is yielded | same order as Ruby (Ruby: `Errno::ENOENT`) |
| `Find.prune` | same | same effect; an exception (`FindPrune`) that Find.find rescues, where Ruby uses `throw :prune`. Outside Find.find, `FindPrune` reaches the top (Ruby: `UncaughtThrowError`) |
| `Pathname#find` | `Pathname.find(pn) {}` | same, "./" dropped for ".", as Ruby |

## Frictions

- Ruby's `catch(:prune)` / `throw` do not exist; an exception type does the same job (`def prune = raise
  FindPrune`). It is visible to the user (`rescue => e` inside the block would catch it).
- No checker findings: `--strict=1 -c` and `--strict=2 -c` were OK on the first run.

## Language features used

- **`*rest` + keyword**: `def find(*paths, ignore_error: true)`, called `Find.find("a", "b")` and
  `Find.find(@path, ignore_error:)`.
- **`block_given?`**: the Array result without a block (Ruby's Enumerator).
- **Adding to another library's class**: `class Pathname ... def find` in find.sake, as Ruby's
  pathname.rb reopens Pathname.

## `--types`

No fields of its own (`Pathname.path: String`); no unions or unknowns.
