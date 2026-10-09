# stringio (StringIO)

`require "stringio"` → `sakelib/stringio.sake`. Test: `test/sakelib/stringio.{sake,rb}` (identical output).

`StringIO` is a Struct type (`class StringIO`): the String, the mode, `pos`, `lineno`, and private flags
(readable, writable, append, closed for reading, closed for writing). Every Ruby instance method is an
operation with the StringIO first. It includes `Bitwise` for `io << x`. `EOFError` (Ruby's, which Sake
lacks) is declared here as `class EOFError < Exception`; `tempfile.sake` requires this file and shares it.

## API

| Ruby | Sake | |
|---|---|---|
| `StringIO.new(s = "", mode = "r+")` | `StringIO.new(s, mode)` | same for String modes (`r`, `r+`, `w`, `w+`, `a`, `a+`, with `b`/`t`/`:enc` ignored); Integer modes (`File::RDONLY`) missing |
| `io.string` / `io.string = s` | `StringIO.string(io)` / `StringIO.set_string(io, s)` | same (pos and lineno 0; mode and closed state stay, as Ruby 4.0) / differs: name |
| `io.read` / `io.read(n)` | `StringIO.read(io)` / `StringIO.read(io, n)` | same: `""` at the end / `nil` at the end, binary String |
| `io.readpartial(n)`, `io.read_nonblock(n)` | `StringIO.readpartial(io, n)`, `read_nonblock` | same (EOFError at the end) |
| `io.pread(n, offset)` | `StringIO.pread(io, n, offset)` | same |
| `io.gets(sep = $/, limit, chomp:)` | `StringIO.gets(io, sep = "\n", limit = nil, chomp: false)` | same, also `gets(io, limit)`, `gets(io, nil)`, paragraph mode `gets(io, "")` |
| `io.readline(...)` | `StringIO.readline(io, ...)` | same (EOFError) |
| `io.each_line(sep, chomp:) { }`, `io.each` | `StringIO.each_line(io, sep, chomp:) { }`, `each` | same; without a block (Enumerator) missing |
| `io.readlines(sep, chomp:)` | `StringIO.readlines(io, sep, chomp:)` | same (a `String[]`) |
| `io.getc` / `io.readchar` | `StringIO.getc(io)` / `readchar` | same |
| `io.getbyte` / `io.readbyte` | `StringIO.getbyte(io)` / `readbyte` | same |
| `io.ungetc(c)` / `io.ungetbyte(b)` | `StringIO.ungetc(io, c)` / `ungetbyte` | same (String or Integer; what does not fit before pos goes in front of the String) |
| `io.each_char { }` / `io.each_byte { }` | `StringIO.each_char(io) { }` / `each_byte` | same |
| `io.write(*objs)` | `StringIO.write(io, *objs)` | same (bytes written; NUL padding past the end; `a` mode appends) |
| `io.syswrite(s)`, `io.write_nonblock(s)` | `StringIO.syswrite(io, s)`, `write_nonblock` | same |
| `io << x` | `io << x` | same (`include Bitwise`) |
| `io.print(*objs)` / `io.puts(*objs)` | `StringIO.print(io, *objs)` / `puts` | same (puts flattens Arrays, an empty Array prints nothing, nil an empty line) |
| `io.printf(fmt, *args)` | `StringIO.printf(io, fmt, *args)` | same (Sake's `format`) |
| `io.putc(c)` | `StringIO.putc(io, c)` | same |
| `io.pos` / `io.tell` | `StringIO.pos(io)` / `tell` | same (bytes) |
| `io.pos = n` | `StringIO.set_pos(io, n)` | differs: name; negative → IOError "Invalid argument" (Ruby: Errno::EINVAL) |
| `io.seek(off, whence = IO::SEEK_SET)` | `StringIO.seek(io, off, whence = 0)` | differs: whence is `0`/`1`/`2` or `:SET`/`:CUR`/`:END` (no `IO::SEEK_*` constants) |
| `io.rewind` | `StringIO.rewind(io)` | same (pos and lineno 0, gives 0) |
| `io.eof?` / `io.eof` | `StringIO.eof?(io)` / `eof` | same |
| `io.size` / `io.length` | `StringIO.size(io)` / `length` | same (bytes) |
| `io.truncate(n)` | `StringIO.truncate(io, n)` | same (gives 0; negative → IOError "Invalid argument - negative length") |
| `io.lineno` / `io.lineno = n` | `StringIO.lineno(io)` / `StringIO.set_lineno(io, n)` | same / differs: name (an `attr_accessor` writer) |
| `io.reopen(s = "", mode = "r+")` | `StringIO.reopen(io, s, mode)` | same (opens a closed StringIO again) |
| `io.close` / `io.closed?` | `StringIO.close(io)` / `closed?` | same |
| `io.close_read` / `io.close_write` | `StringIO.close_read(io)` / `close_write` | same (IOError "closing non-duplex IO for ..." on a one-way StringIO) |
| `io.closed_read?` / `io.closed_write?` | `StringIO.closed_read?(io)` / `closed_write?` | same |
| `io.flush`, `fsync`, `sync`, `sync = v`, `fileno`, `isatty`, `tty?`, `pid`, `binmode` | `StringIO.flush(io)`, ..., `StringIO.set_sync(io, v)` | same (Ruby's constant results: io, 0, true, v, nil, false, false, nil, io) |
| `io.external_encoding` / `io.internal_encoding` | `StringIO.external_encoding(io)` / `internal_encoding` | differs: the String's encoding name, as `String.encoding` gives it / nil |
| `io.inspect` | `p(io)` | differs: `#<StringIO>` (Ruby shows the address) |
| `set_encoding`, `set_encoding_by_bom`, `codepoints`, `each_codepoint`, `ungetc` of a frozen String's StringIO, Integer modes, `StringIO.open { }` | — | missing |

54 operations ported (plus `new`).

## How it works, and what differs

- **Bytes.** Ruby's positions are bytes, so `pos`, `seek`, `size`, `read(n)`, `gets(limit)`, `truncate`,
  `pread` are too: the String is cut with `String.byteslice` and written with `String.bytesplice`. A
  limit read extends to the end of the character it would cut (`gets(io, 2)` on `"héllo"` gives `"hé"`),
  as Ruby's does. `read(n)` and `pread` give a binary String (`String.b`), as Ruby's do.
  - *Differs*: a write that lands inside a multibyte character (pos 1 of `"é"`) raises `IndexError` from
    `String.bytesplice`; Ruby overwrites the bytes and leaves a broken String.
- **The String is shared.** `StringIO.new(s)` keeps `s` and changes it in place (`String.concat`,
  `bytesplice`, `replace`, `clear`), so the caller's `s` shows the writes, as in Ruby. A frozen String is
  not a notion Sake has, so `new` never falls back to mode `r`.
- **Modes.** `"w"`/`"w+"` empty the String; `"a"`/`"a+"` write at the end whatever pos is; a String mode
  with another first letter raises `ArgumentError "invalid access mode x"`. Writing to a read-only
  StringIO raises `IOError "not opened for writing"`; reading a write-only one "not opened for reading";
  both after `close` too (Ruby's messages).
- **Errno::EINVAL** (negative pos, bad whence, negative truncate) is `IOError` with Ruby's message text
  (`"Invalid argument - invalid whence"`); Sake has no Errno types. The test's Ruby twin rescues
  `Errno::EINVAL` alongside and prints the same message.
- **`string=` on a closed StringIO** keeps it closed, as Ruby 4.0 does (checked: `io.close; io.string = "y";
  io.read` → `not opened for reading`); `reopen` opens it again. An earlier draft reopened on `string=`.
- **Paragraph mode** (`gets(io, "")`) follows StringIO, not IO: leading newlines are skipped and the
  line ends after the whole run of newlines (`"a\n\n\nb"` → `"a\n\n\n"`), which is what Ruby's StringIO
  prints.
- **Setters.** `io.pos = n`, `io.string = s`, `io.lineno = n`, `io.sync = v` are `set_pos`, `set_string`,
  `set_lineno`, `set_sync` (the Struct writer convention; `lineno`'s is the generated `attr_accessor`
  writer, the others validate, so they are functions beside an `attr_reader`).
- **`each_line` without a block** (an Enumerator) cannot exist: blocks are not values.

## Built-ins Sake lacks (requests)

- `EOFError` as a built-in exception type: every IO-like library raises it; declaring it in one library
  means a second library (`tempfile`) must `require` that one, and two libraries declaring it would
  collide.
- `IO::SEEK_SET`/`SEEK_CUR`/`SEEK_END` (or `IO.SEEK_END()` as `Math.PI` is read): `seek` takes `0`/`1`/`2`
  or Symbols here.
- `String.byteslice` that cannot be nil for an in-range request, or a `String.fetch`-like byte slice:
  every slice is followed by `|| ""` under `--strict` (12 times in this file).
- `Integer.to_s(n, base)` (Ruby's `to_s(36)`): tempfile writes base 36 by hand.

## Friction

- Wrote `s = c in Integer ? Integer.chr(c) : c` → `error: syntax error: unexpected '?', expecting
  end-of-input` → `s = (c in Integer) ? ... : c`. Ruby's grammar too (`in` binds loosely), but the
  Sake habit of writing `x in T` for a type test makes it a common place to trip; the hint could
  suggest the parentheses.
- Wrote Ruby's idiom `while (line = gets(io, sep, nil, chomp:)) != nil; Array.push(lines, line); end` →
  `stringio.sake:191: Array.push: argument elem may be nil (nil | String) [nil]` (and, in a user's
  program, `String.length: argument 1 may be nil` with `reached by the call at line 71 →
  stringio.sake:186` naming the library's line): an assignment inside the `while` condition does not
  narrow the local → `loop do; line = gets(...); break unless line; ...; end`. Four loops rewritten
  (`each_line`, `readlines`, `each_char`, `each_byte`). The `x != nil` narrowing could cover
  `(x = e) != nil`, which is how Ruby reads a stream.
- A user's `p io.each(...)` is not the issue; `each` passing its block on with `&b` to `each_line`
  worked at the first try (`def each(io, sep = "\n", chomp: false, &b) = each_line(io, sep, chomp:, &b)`).
- Ruby's `puts` needs `case x in Array` to flatten: `Kernel.to_s` of an Array gives its inspect, as in
  Ruby, so `puts(io, Array["a"])` would have written `["a"]` without it.
- What felt good: the whole first draft (54 operations) passed `--strict` with only the two problems
  above, and the Ruby twin of the 276-line test printed the same 201 lines after fixing one behaviour
  (`string=` on a closed StringIO) that Ruby 4.0 itself had changed. `attr_accessor lineno` gave
  `set_lineno` for free; `include Bitwise` gave `io << "x" << 1` with Ruby's chaining.
