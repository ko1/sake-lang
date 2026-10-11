# mini_mime

`require "mini_mime"` → `sakelib/mini_mime.sake`, after the mini_mime gem 1.1.5. Test:
`test/sakelib/mini_mime.{sake,rb}`, 37 identical lines.

It reads **the gem's own data files at run time**, as Ruby does: `lib/db/ext_mime.db` and
`lib/db/content_type_mime.db` are fixed-length rows sorted by extension / content type; a lookup is a
binary search that seeks to a row and reads it (Ruby: `File#pread`), with a hit cache and a miss cache
of 100 entries. The directory is found with `gem which mini_mime` (Open3) the first time it is needed,
or set with `Configuration.set_ext_db_path` / `set_content_type_db_path` before the first lookup.

## API

| Ruby | Sake | |
|---|---|---|
| `MiniMime.lookup_by_filename(name)` | same | same (the extension decides; nil without one) |
| `MiniMime.lookup_by_extension(ext)` | same | same (exact, then downcased) |
| `MiniMime.lookup_by_content_type(type)` | same | same (exact only, as Ruby) |
| `info.extension` / `content_type` / `encoding` (and `=`) | `MiniMime::Info.extension(info)` / ... / `set_extension` | same |
| `info[0]`, `info[1]`, `info[2]` | `info[0]` (Indexable) | same |
| `info.binary?` | `MiniMime::Info.binary?(info)` | same |
| `MiniMime::Info.new(row)` | same | same (the row is split at whitespace) |
| `Configuration.ext_db_path` (and `=`) | `MiniMime::Configuration.ext_db_path` / `set_ext_db_path(p)` | differs: setter name |
| `Db.lookup_by_*` (class methods) | same | same |
| `Db#lookup_by_extension` (instance) | `Db::RandomAccessDb.lookup(Db.ext_db(db), ext)` | differs: one name is one function |
| `Db::Cache`, `Db::RandomAccessDb` | same classes | same |
| `PReadFile` (Windows fallback) | — | not needed: seek + read is the only path |

15 operations.

## What differs and why

- **Module state.** Ruby keeps the paths in `class << self; attr_accessor` and the Db in `@db ||= new`.
  Sake has no globals; both are tables made by `once` (`once { Hash[] }`, `once { Db.new }`).
- **pread.** `IO.seek` + `IO.read` on a File opened once (`File.open(path, "rb")`); Sake has no `pread`.
- **Info equality.** `==` compares fields in Sake, identity in Ruby; the test's cached-lookup comparison is
  true in both.
- **The gem directory** comes from a subprocess (`gem which`), since Sake has no `__FILE__` of another
  library's gem; Ruby uses `File.expand_path("../db/...", __FILE__)`.

## Built-ins Sake lacks (requests)

- `File.pread(io, len, offset)` (one call, no shared position).
- A way to find an installed gem's directory without spawning `gem` (e.g. `Gem.dir`-like data).
- `Hash.fetch(h, k) { }` with a block: `Cache#fetch(key, &blk)` is written with `Hash.key?` + `yield`.

## Friction

- None at the checker: the port ran under `--strict` at the first try, and the test matched Ruby at the
  first run. `@extension, @content_type, @encoding = String.split(@buffer, /\s+/)` (a multiple assignment
  to fields from an Array) worked as in Ruby.
- Small: `Info.new(buffer)` keeps Ruby's constructor because the first field is the (private) buffer and
  `initialize` derives the rest; a class whose constructor argument is not a field needs this pattern.

## Size

Ruby: 186 lines (lib/mini_mime.rb; 148 without comments and blank lines).
Sake: 164 lines (123 without comments and blank lines).
