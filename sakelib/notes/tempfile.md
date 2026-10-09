# tempfile (Tempfile, Dir.tmpdir)

`require "tempfile"` → `sakelib/tempfile.sake` (requires `stringio`). Test: `test/sakelib/tempfile.{sake,rb}`
(identical output; the names are random, so the tests print the basename with the stamp replaced, never a
name).

`Tempfile` is a Struct type: `basename`, `tmpdir` (the arguments of `new`), and private `fpath`, `pos`,
`lineno`, `closed`, `unlinked`. `Dir.tmpdir` is added to the built-in `Dir` (Ruby's `tmpdir.rb`, which
tempfile requires). It includes `Bitwise` for `tf << x`.

## API

| Ruby | Sake | |
|---|---|---|
| `Tempfile.new(basename = "", tmpdir = nil)` | `Tempfile.new(basename = "", tmpdir = nil)` | same: `"pre"` or `["pre", ".suf"]`; name `<prefix><yyyymmdd>-<pid>-<base36>[-n]<suffix>`, mode 0600, unusable characters dropped |
| `Tempfile.new(..., mode: m, **opts)` | — | missing: `T.new` takes fields only; the file is always read/write |
| `Tempfile.create(basename = "", tmpdir = nil)` | `Tempfile.create(basename, tmpdir)` | differs: gives a Tempfile (Ruby: a File) |
| `Tempfile.create(...) { \|f\| }` | `Tempfile.create(...) { \|f\| }` | same: closed and removed after the block, the block's value |
| `Tempfile.open(...)` | — | missing (same as `new` / `create { }`) |
| `Dir.tmpdir` | `Dir.tmpdir` | same (`$TMPDIR` or `/tmp`, found once from where `Dir.mktmpdir` creates) |
| `tf.path` / `tf.to_path` | `Tempfile.path(tf)` / `to_path` | same (nil once unlinked) |
| `tf.open` | `Tempfile.open(tf)` | differs: gives the Tempfile (Ruby: the File); pos 0; `IOError` if unlinked (Ruby: Errno::ENOENT, same message) |
| `tf.close(unlink_now = false)` / `tf.close!` | `Tempfile.close(tf, unlink_now)` / `close!` | same (`close(tf, true)` gives unlink's result) |
| `tf.unlink` / `tf.delete` | `Tempfile.unlink(tf)` / `delete` | same (true, then nil) |
| `tf.closed?` | `Tempfile.closed?(tf)` | same |
| `tf.size` / `tf.length` | `Tempfile.size(tf)` / `length` | same while the file exists; differs: 0 once unlinked (Ruby: the open file's size) |
| `tf.write(*objs)`, `print`, `puts`, `printf`, `putc`, `tf << x` | `Tempfile.write(tf, *objs)`, ... , `tf << x` | same results; differs: written to the file at once (Ruby buffers until `flush`/`close`); `<<` gives the Tempfile (Ruby: the File) |
| `tf.read([n])`, `gets(sep, limit, chomp:)`, `readline`, `readlines`, `getc`, `getbyte`, `readchar`, `eof?`/`eof` | `Tempfile.read(tf, n)`, ... | same (StringIO's rules, see stringio.md) |
| `tf.each_line(sep, chomp:) { }` / `tf.each` | `Tempfile.each_line(tf, sep, chomp:) { }` / `each` | same; gives the Tempfile (Ruby: the File) |
| `tf.pos` / `tf.tell` / `tf.pos = n` | `Tempfile.pos(tf)` / `tell` / `Tempfile.set_pos(tf, n)` | same / differs: name (negative: IOError with Ruby's Errno::EINVAL message) |
| `tf.seek(off, whence)` | `Tempfile.seek(tf, off, whence = 0)` | differs: whence `0`/`1`/`2` or `:SET`/`:CUR`/`:END` |
| `tf.rewind` | `Tempfile.rewind(tf)` | same |
| `tf.truncate(n)` | `Tempfile.truncate(tf, n)` | same (gives 0) |
| `tf.flush`, `fsync`, `binmode` | `Tempfile.flush(tf)`, ... | same results (tf, 0, tf); `flush` gives the Tempfile (Ruby: the File) |
| `tf.sync` | `Tempfile.sync(tf)` | differs: true (every write is in the file); Ruby: false |
| `tf.inspect` | `p(tf)` | same: `#<Tempfile:/tmp/foo20261009-1-abc>`, `#<Tempfile:>` once unlinked |
| finalizer: the file is removed when the Tempfile is garbage collected | — | missing: no finalizers; close with `close!`/`unlink`, or use `Tempfile.create { }` |
| `tf.mtime`, `atime`, `stat`, `chmod`, `fileno`, `sysread`, `syswrite`, `set_encoding`, ... | — | missing (use the `File` built-ins on `Tempfile.path(tf)`) |

40 operations ported (including `Dir.tmpdir` and `create`).

## How it works, and what differs

- **No seek in Sake's IO.** `IO` has `read` (whole), `gets`, `write`, `puts`, `print`, `eof?`, `close`,
  and nothing for the position, so an open IO cannot give Ruby's write → `rewind` → `read`, nor
  `read(n)`. Every read or write therefore goes through a `StringIO` over `File.read(path)` at the saved
  position (`with_io`), and a write puts `StringIO.string` back with `File.write`. This is O(file) per
  operation and fine for a temporary file of the usual size; it is also why `sync` is true and `flush`
  does nothing. The name of each operation and its result are Ruby's.
  - *Differs*: Ruby's writes sit in the File's buffer until `flush`/`close`/`size`, so Ruby's
    `File.read(tf.path)` after `tf.write` gives `""`; here it gives the data. The test flushes first.
- **Naming** follows Ruby's `Dir::Tmpname.create`: `"#{prefix}#{Time.strftime(Time.now, "%Y%m%d")}-
  #{Process.pid}-#{base36(Kernel.rand(0x100000000))}#{"-n" on a collision}#{suffix}"`; characters
  outside `, - . 0-9 A-Z _ a-z ~` are deleted from the prefix and suffix (`"a/b c"` → `ab`), as Ruby does
  (an earlier draft raised ArgumentError, which Ruby does not). The file is made with `File.write(path, "")`
  after `File.exist?` (Ruby: `O_EXCL`), then `File.chmod(0o600, path)`.
- **`Dir.tmpdir`** is `once { d = Dir.mktmpdir("sake"); Dir.rmdir(d); File.dirname(d) }`: the directory
  `Dir.mktmpdir` chooses is Ruby's `Dir.tmpdir`, and Sake has no `ENV` to read `$TMPDIR` directly.
- **Ruby's delegation shows through.** Ruby's `tf << x`, `tf.open`, `tf.flush`, `tf.each_line { }` return
  the underlying File, not the Tempfile (`(tf << "x") == tf` is false in Ruby), and `Tempfile.create`
  gives a File. Here they all give the Tempfile. The test compares paths instead of the objects.
- **Removal.** Ruby removes a forgotten Tempfile at garbage collection; Sake has no finalizers, so a
  Tempfile that is not unlinked stays in `/tmp`. Use `Tempfile.create(name) { |f| ... }` or `close!`.

## Built-ins Sake lacks (requests)

- `IO.seek`, `IO.pos`, `IO.rewind`, `IO.read(io, n)`, `IO.getc`, `IO.truncate`, `IO.size`: with these,
  Tempfile (and any File-backed port) would hold one open IO as Ruby does, instead of a StringIO shadow
  with a full read and write per operation.
- `Dir.tmpdir` as a built-in (or `ENV`): the `mktmpdir`+`rmdir` detour creates and removes a directory
  to learn a path.
- `File.open(path, "w", 0o600)`: the permission argument, so a file is never world-readable between
  `File.write` and `File.chmod`.
- `Integer.to_s(n, 36)`: Ruby's random part is base 36; written by hand here (`base36`).
- A finalizer or `at_exit` hook: Ruby's Tempfile relies on one to remove the file.

## Friction

- Wrote `raise ArgumentError, "unexpected prefix: ..." if String.include?(prefix, "/")` from memory of
  Ruby's message → the Ruby twin printed `ab<stamp>`: Ruby *deletes* the unusable characters
  (`prefix.delete(UNUSABLE_CHARS)`) and raises only for a non-String → `String.delete(prefix,
  "^,-.0-9A-Z_a-z~")`, which took Ruby's `^`-negated character set unchanged. Not Sake's doing, but the
  identical-output test caught it at once.
- Wrote `p Tempfile.open(t) == t`, `p Tempfile.flush(t) == t`, `p (t << "z") == t` in the test → the Ruby
  twin printed `false` three times (Ruby returns the inner File) → compared `Tempfile.path(...)` with the
  path. A port that keeps one type where Ruby has a delegator pair cannot reproduce such identities.
- `Tempfile.new(name, mode: ...)`: Ruby's keyword options cannot be given to `T.new` (fields only); a
  `Tempfile.open_with(opts)` would be needed. Not written (mode is always read/write).
- A function in `class Tempfile` named `tmpdir` would replace the field reader `tmpdir`, so Ruby's
  `Dir.tmpdir` went to `class Dir`, which turned out to be the right place and worked at the first try
  (adding an operation to a built-in namespace).
- The polymorphic `with_io(tf, writing) { |io| ... }` returning `yield`'s value (String, nil, Integer,
  Boolean, depending on the caller) typed each caller's result correctly under `--strict`: no union
  leaked into `read`'s or `eof?`'s callers.
- What felt good: the Tempfile port is 40 operations in about 200 lines because StringIO carries the
  IO semantics; `Tempfile.create` with and without a block is one function with `block_given?` and
  `begin/ensure`, exactly Ruby's shape.

## Later the same day (2026-10-09)

Dir.tmpdir, File.open(path, mode, perm), IO.seek/pos/rewind/read(io, n)/truncate/size and Integer.to_s(n, base) are built in (the Dir.tmpdir written here was removed). The StringIO shadow could now be replaced by one open IO.
