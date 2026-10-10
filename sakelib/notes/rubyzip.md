# rubyzip (Zip::File, Zip::Entry)

`require "rubyzip"` → `sakelib/rubyzip.sake` (requires `zlib` for `Zlib.crc32`). Test: `test/sakelib/rubyzip.{sake,rb}`,
identical output; the `.rb` twin uses the real gem (rubyzip 3.4.1), and both read the same archive written by
rubyzip (embedded as base64: zip64 extra fields, a UTF-8 name, an archive comment). A Sake-written archive was
also checked with `unzip -t` and read back by rubyzip (dev check, not in the test).

Shape: a `Zip::File` is an **Array of `Zip::Entry`** here. `Zip.read(path)` / `Zip.parse(bytes)` give the entries,
`Zip.write(path, entries)` / `Zip.generate(entries)` make an archive, the rest of `Zip::File`'s API are module
functions over that Array (`Zip.find_entry(entries, name)`, `Zip.glob(...)`). `Zip::Entry` and `Zip::Error` are
the gem's names (nested since 2026-10-10; before that `Zip::Entry` and `Zip::Error`).

## API

| Ruby (rubyzip 3) | Sake | |
|---|---|---|
| `Zip::File.open(path)` / `zf.entries` | `Zip.read(path)` → `Zip::Entry[]` | differs: an Array, no block form, no lazy reading |
| `Zip::File.open_buffer(bytes)` | `Zip.parse(bytes)` | differs: name |
| `Zip::File.open(path, create: true) { ... }` + commit | `Zip.write(path, entries, comment: "")` | differs: entries are built first, written once |
| `Zip::OutputStream.write_buffer` | `Zip.generate(entries, comment: "")` → bytes | differs: name |
| `zf.get_output_stream(name, time:, compression_method:) { \|f\| f.write s }` | `Zip.add(entries, name, data, compression_method: 8, time: nil)` | differs: data as a String, no stream |
| `zf.add(name, path)` | `Zip.add_file(entries, path, name = basename, compression_method: 8)` | same (keeps mtime) |
| `zf.mkdir(name)` | `Zip.mkdir(entries, name, time: nil)` | same (raises `Zip::Error` if it exists) |
| `zf.remove(name)` | `Zip.remove(entries, name)` | same |
| `zf.find_entry(name)` | `Zip.find_entry(entries, name)` | same |
| `zf.read(name)` | `Zip.entry_data(entries, name)` | differs: name; `Zip::Error` (Ruby: `Errno::ENOENT`), same message |
| `zf.glob(pattern)` | `Zip.glob(entries, pattern)` | same for `*`, `?`, `**` (a directory entry matches as `dir`, as the gem) |
| `zf.entries.map(&:name)` | `Zip.names(entries)` | added |
| `zf.size` | `Array.size(entries)` | same |
| `zf.comment` / `zf.comment = s` | `comment:` of `write`/`generate` | differs: the archive comment is not kept when reading |
| `entry.extract(destination_directory: dir)` | `Zip.extract(entries, dir)` | differs: all entries; refuses paths escaping `dir` |
| `Zip::Entry.new(nil, name, ...)` | `Zip::Entry.new(name, data = "", compression_method: 8, time: Time.now, comment: "")` | differs: holds its data |
| `entry.name`, `size`, `compressed_size`, `compression_method`, `crc`, `time`, `comment` | `Zip::Entry.name(e)` … | same (`time` is a `Time`, Ruby: `Zip::DOSTime`) |
| `entry.directory?`, `file?`, `ftype`, `to_s` | `Zip::Entry.directory?(e)` … | same |
| `entry.get_input_stream.read` | `Zip::Entry.data(e)` | differs: the data is inflated when the archive is read |
| `entry.name = s`, `time = t`, `comment = s` | `Zip::Entry.set_name(e, s)`, `set_time`, `set_comment` | differs: setter names |
| (a new output stream) | `Zip::Entry.set_data(e, s)` | added: replaces the data, recomputes the CRC |
| `Zip::Entry::STORED`, `DEFLATED` | `0`, `8` | differs: no constants in Sake; the method is the Integer |
| `Zip.crc32(s)` | `Zip.crc32(s)` (= `Zlib.crc32`) | same |
| `Zip::InputStream`, `Zip::OutputStream` (streaming) | — | missing: everything is in memory |
| encryption (`Zip::TraditionalDecrypter`), `Zip::FileSystem`, `unix_perms`, `extra` fields of entries, `zf.commit` / `close` | — | missing |
| `Zip.on_exists_proc`, `Zip.continue_on_exists_proc`, `Zip.default_compression`, `Zip.unicode_names` ... | — | missing (settings) |

18 module functions of `Zip` and 17 operations of `Zip::Entry` ported.

## できたこと / できなかったこと

- **Reading**: the end record (`PK\x05\x06`, searched from the end), the zip64 end record and locator when the
  counts are `0xffff`/`0xffffffff`, the central directory (its sizes and CRC are reliable even when a local
  header deferred them to a data descriptor), the `0x0001` zip64 extra field (rubyzip 3 writes it for every
  streamed entry: the local header says `0xffffffff`), the local header (only to find the data). Method 0
  (stored; CRC checked) and 8 (deflated). DOS date/time → `Time` (local, 2-second resolution). Names and
  comments are tagged UTF-8 (rubyzip leaves them binary, so its `p e.name` shows bytes; the test prints names with
  `puts`). Encrypted entries and other methods raise `Zip::Error`.
- **Writing**: local headers with known sizes (no data descriptor), central directory (version made by 0x0314 =
  Unix 2.0, external attributes `0100644`/`040755|0x10`), end record, the UTF-8 flag (bit 11) for non-ASCII
  names, the archive comment. `unzip -t` and rubyzip accept the result.
- **Inflating a raw deflate stream through `Zlib.gunzip`.** The built-in `Zlib.inflate` takes a zlib stream and
  insists on its Adler-32 trailer (`Zlib::BufError` without it; checked in Ruby), and the trailer cannot be
  computed before inflating. A ZIP entry is raw deflate, but its headers carry exactly what a *gzip* trailer
  holds: the CRC-32 and the size. So `inflate_raw(raw, crc, size)` = `Zlib.gunzip(gzip header + raw + [crc,
  size].pack("VV"))`, and gunzip also verifies the CRC for free (a wrong CRC is Ruby's
  `invalid compressed data -- crc error`, re-raised as `Zip::Error`). Deflating is `Zlib.deflate` minus its 2-byte
  header and 4-byte trailer. Compressed sizes match rubyzip's byte for byte (same zlib, same default level).
- **Not ported**: streaming (`Zip::InputStream`/`OutputStream`): there is no IO-like value a user block could
  write into; `Zip.add` takes the data as a String instead. Encryption, `Zip::FileSystem`, permissions, extra
  fields other than zip64 (they are skipped, not kept), the archive comment on reading, the gem's global
  settings (no mutable module state in Sake other than `once`).
- **CRC on reading** is verified (stored and deflated); rubyzip does not verify it on `get_input_stream.read`,
  so a corrupt-entry test could not be shared with the twin.

## 書き心地

- **Field order is the `attr_*` line order, not the order I meant.** Wrote
  `attr_accessor name, compression_method, time, comment` / `attr_reader data, crc`, then
  `Zip::Entry.new(name, data, compression_method: m, ...)` → `error: field `compression_method` is already given
  as argument 2`. The positional order of `new` is the order the fields are declared, across all `attr_*` lines.
  Rewrote the declarations in the intended order (`attr_accessor name` / `attr_reader data` /
  `attr_accessor compression_method, time, comment` / ...), with a comment, since the grouping by access that
  Ruby invites (`attr_reader :a, :b` then `attr_accessor :c`) silently decides the constructor's shape.
- **`"..." \ "..."` with interpolation is rejected**: `puts "#{a} " \ "#{b}"` → `unsupported part of an interpolated
  literal` (4 times, one per line). Ruby's adjacent-literal concatenation is not in Sake; joined the line into one
  long String.
- **`String.unpack1` is `T | nil`**, so `usize = String.unpack1(bytes_at(extra, j, 8), "Q<")` made `usize`, and then
  `size % 4294967296` four functions away, `[nil]` reports under `--strict`. True (unpack1 of a bad `"m"` is
  nil), but not for `"Q<"` on 8 bytes. Wrote one checked `u64(b, i)` that raises `Zip::Error` on nil. By contrast
  multiple assignment from `String.unpack(s, "vvvvvvVVVvvvvvVV")` (16 fields) passed at level 2: its nil is the
  `index-nil` item (level 3), and the typed element (Integer) came from the literal format. Good: a binary
  header read as `a, b, c, ... = String.unpack(...)` reads like the C struct it mirrors.
- **The hint chain named the wrong call.** The `[nil]` report inside `bytes_at(b, i, len)` said
  `reached by the call at line 16 → rubyzip.sake:88`, where the argument at line 88 was `z64`, a value from a
  destructuring (nil only in the level-3 sense); the nil that caused the report came from another call site
  (`loff + 26`, unpack1). The hint picks a call site whose argument *type* contains nil, even when that nil is
  one the level does not report. Took a few minutes to find the real source.
- **Binary Strings just work.** `String.b(File.read(path))`, `String.rindex(b, "PK\x05\x06")` on a binary
  haystack with a UTF-8 literal needle, `String.byteslice`, `Array.pack(..., "vvvvvVVVvv")`, `String.concat(out,
  "PK\x03\x04", packed, name, body)` in place: all Ruby's. The checker's `String.byteslice → String | nil`
  forced the `bytes_at` helper, which turned out to be the right place for the "truncated archive" check.
- **`case method in 0 ... in 8 ... else raise`** reads better than Ruby's `case/when` here: the method is an
  Integer from the header, and the else is the unsupported-method error.
- **`ARGV[0]`** in a throwaway writer → `undefined type or module `ARGV``: `T[...]` is the typed-Array
  constructor, so `ARGV[...]` is parsed as "an Array of ARGV". The message is misleading; repro
  `rubyzip_bug_argv_index_hint.sake`. `Array.first(ARGV)` works.
- The `.rb` twin hit rubyzip's own rough edges: `Zip::File.open_buffer("")` raises a `TypeError` inside the gem
  (dropped that case), directory entries have a `NullInputStream` without `read` (guarded with `directory?`),
  `zf.mkdir` takes no time (set `entry.time` after). The Sake API has none of these because an entry is plain
  data.

## Built-ins requested

- `Zlib.inflate_raw(s)` / `Zlib.inflate(s, window_bits)` (Ruby's `Zlib::Inflate.new(-15)`): raw deflate without
  the gunzip detour, which only works when the CRC and size are known (true for ZIP, not for other raw streams).
- `Zlib.deflate(s, level)`: rubyzip's `compression_level:`; only the default level is available.
- `File.binread(path)` / `File.binwrite(path, s)`: `String.b(File.read(path))` works but re-tags after reading
  the whole file as UTF-8.
- `File.fnmatch(pattern, path, flags)`: `Zip.glob` translates the pattern to a Regexp by hand.
- `Dir.mkdir_p` (or `FileUtils.mkdir_p` as a built-in): written as a 5-line loop for `Zip.extract`.
