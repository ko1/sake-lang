# pstore (PStore)

`require "pstore"` → `sakelib/pstore.sake` (ported from the pstore gem 0.2.1). Test: `test/sakelib/pstore.{sake,rb}` (write
and read transactions, a second store on the same file, delete, abort, commit, an exception in the
block, ultra_safe, and every PStore::Error; identical output).

## The file format differs: JSON, not Marshal

Ruby's PStore writes the table with `Marshal.dump`, which keeps any Ruby object. Sake has no Marshal
(no reflection over arbitrary objects), so the table is written with `sakelib/json.sake` as a JSON
array of `[key, value]` pairs (pairs rather than an object so that keys need not be Strings).

- Keys: Strings, Integers, Floats, true/false, nil come back as they were. Symbols come back as Strings.
- Values: JSON values (Hash, Array, String, Integer, Float, true/false, nil). Hash keys inside values
  come back as Strings; Symbols as Strings; instances of your classes cannot be stored
  (`JSON::GeneratorError` at the end of the transaction).
- The files are not compatible with Ruby's PStore files (Ruby's YAML::Store is the closer relative:
  PStore with `dump`/`load` replaced).

## API

| Ruby | Sake | |
|---|---|---|
| `PStore.new(path)` / `PStore.new(path, true)` | `PStore.new(path)` / `PStore.new(path, true)` | same (thread_safe) |
| `store.transaction { \|s\| ... }` / `transaction(true)` | `PStore.transaction(store) { \|s\| ... }` / `(store, true)` | same; the block's value is returned |
| `s[key]`, `s[key] = v` | `s[key]`, `s[key] = v` | same (`include Indexable`) |
| `s.fetch(key)` / `s.fetch(key, default)` | `PStore.fetch(s, key)` / `(s, key, default)` | same |
| `s.delete(key)`, `s.keys` / `roots`, `s.key?(k)` / `root?(k)` | `PStore.delete(s, k)`, ... | same |
| `s.commit` / `s.abort` | `PStore.commit(s)` / `PStore.abort(s)` | same effect (see below) |
| `store.path` | `PStore.path(store)` | same |
| `store.ultra_safe = true` | `store.PStore.ultra_safe = true` | same |
| `PStore::Error` | `PStore::Error` | same messages |
| `PStore::VERSION` | `PStore.version` | differs: no value constants |

12 operations.

## What differs and why

- **commit / abort.** Ruby throws `:pstore_abort_transaction` and catches it at the end of the
  transaction. Sake has no catch/throw, so they raise `PStore::TransactionEnd`, which the transaction
  rescues. A bare `rescue` (or `rescue PStore::TransactionEnd`) inside the block would catch it, which
  Ruby's throw passes through.
- **No file locking.** Ruby takes `flock(LOCK_SH)` / `flock(LOCK_EX)`; Sake has no flock, so two
  processes writing one store can lose updates. The in-process Mutex (nested transaction check, thread
  safety) is ported.
- **No checksum.** Ruby keeps the SHA-512 of the data read and writes only if the new data differ; here
  the data read are kept and compared (same effect; Digest::SHA512 in Sake would cost more than it saves).
- **Writes.** The fast strategy writes the whole file with `File.write` (Ruby: rewind, write, truncate
  on the open file); ultra_safe writes a temp file and renames it, as Ruby.
- A read-write transaction creates an empty file, as Ruby's `File::CREAT` does, and an empty file reads as
  an empty table.

## Built-ins Sake lacks

- Marshal (or another serializer for any value): the reason for the JSON format.
- `File#flock` (or `File.open` with a lock).
- catch/throw (to end a transaction without an exception a `rescue` can catch).

## Friction

- Ruby's ivar `@abort` and its method `abort` share a name; in Sake a field gets a reader, so
  `attr_accessor abort` would collide with `def abort` → the field is `aborted` (renamed before running).
- In the test, `s["list"] = s["list"] + ["more"]` → `s["list"]` is a value of the table's union type, so
  `+` needs it narrowed: `list = s["list"]; list => Array; s["list"] = list + Array["more"]`.
- In the test, `s["hash"] = {"a" => {"b" => [1]}}` → `{"a" => ...} is not a Hash in Sake` →
  `Hash["a" => Hash["b" => Array[1]]]`.
- `s[key]` / `s[key] = v` need `include Indexable` in PStore (added from the cheat sheet before running).

## Size

The gem's Ruby: 220 lines (without comments and blank lines). Sake: 150 lines (196 with comments);
shorter because the open/lock/checksum code is gone.
