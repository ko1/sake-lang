# protocol_hpack (Protocol::HPACK, RFC 7541)

`require "protocol_hpack"` → `sakelib/protocol_hpack.sake`. Port of the protocol-hpack gem 1.5.1.
Test: `test/sakelib/protocol_hpack.{sake,rb}` (identical output): RFC 7541 C.1 integers, C.4.1 Huffman, the C.3/C.4
request sequences, C.5 responses with a 256-byte table (eviction), index modes, table size updates and limits,
malformed buffers and Huffman input.

## API

| Ruby | Sake | |
|---|---|---|
| `Compressor.new(buffer, context = Context.new, table_size_limit: nil)` | `Protocol::HPACK::Compressor.new(buffer, ctx, table_size_limit: n)` | same (keyword = field name) |
| `c.encode(headers, table_size = limit)` | `Compressor.encode(c, headers)` | same (returns the buffer, appended in place) |
| `c.write_integer(v, bits)` / `write_string(s, huffman)` / `write_header(cmd)` / `write_bytes` | `Compressor.write_integer(c, v, bits)` / … | same |
| `c.buffer` / `context` / `table_size_limit` / `huffman` | `Compressor.buffer(c)` / … | same |
| `Decompressor.new(buffer, context, table_size_limit:)` | `Protocol::HPACK::Decompressor.new(...)` | same |
| `d.decode(list = [])` | `Decompressor.decode(d)` | same |
| `d.read_integer(bits)` / `read_string` / `read_header` / `read_byte` / `peek_byte` / `read_bytes(n)` / `end?` / `offset` | `Decompressor.read_integer(d, bits)` / … | same; `read_header` returns a `Command` (below) |
| `Context.new(table = nil, huffman: :shorter, index: :all, table_size: 4096)` | `Protocol::HPACK::Context.new(nil, huffman: :never)` | same |
| `ctx.encode(headers)` / `decode(cmd)` / `add_command(n, v)` / `dereference(i)` | `Context.encode(ctx, headers)` / … | same, commands are `Command`s |
| `ctx.change_table_size(n)` / `table_size = n` | `Context.change_table_size(ctx, n)` / `Context.set_table_size(ctx, n)` | differs: setter name |
| `ctx.table` / `huffman` / `index` / `table_size` / `compute_current_table_size` / `dup` | `Context.table(ctx)` / … / `Context.dup(ctx)` | same |
| `Huffman.encode(s)` / `Huffman.decode(s)` | `Protocol::HPACK::Huffman.encode(s)` / `decode(s)` | same output and error messages |
| command Hash `{name:, value:, type:}` | `Protocol::HPACK::Command` with `type`, `name`, `value` | differs (see below) |
| `CompressionError`, `DecompressionError`, `Error` | same names | differs: no hierarchy (`rescue Error` does not catch `CompressionError`) |
| `NAIVE`, `LINEAR`, … `MODES`, `HEADER_REPRESENTATION`, `*_TYPE` constants | `Representation.prefix(type)` / `pattern(type)` | missing (constants hold no values); the presets are just option sets for Context |
| `STATIC_TABLE`, `STATIC_EXACT_LOOKUP`, `STATIC_NAME_LOOKUP`, `Huffman::CODES` | `Context.static_table` / `static_exact_lookup` / `static_name_lookup`, `Huffman.codes` | differs: functions made `once` |

27 operations ported (everything public in the gem except the constants).

## What differs, and why

- **Commands are a class, not a Hash.** Ruby's `{name: 3, type: :indexed}` mixes Integer and String names and
  Integer/String values in one Hash; in Sake that Hash would have a union value type and every read would need a
  pattern. `Command` keeps the three fields (`name: Integer | String`, `value: String | Integer | nil`), and the
  code narrows with `value => String` where Ruby trusted the type.
- **Huffman decoding** walks the code bit by bit through a Hash keyed by `(length << 32) | code` instead of the
  gem's machine-generated 4-bit state machine (`huffman/machine.rb`, 256 rows of data). Same results, and the same
  two errors ("EOS found", "EOS invalid": leftover bits must be fewer than 8 and all 1s, which is what the
  machine's `state <= MAX_FINAL_STATE` checks). Huffman encoding packs bits into an Integer instead of building a
  "0101..." String and `pack("B*")`.
- **A truncated buffer.** Ruby calls `nil & limit` and raises NoMethodError; Sake raises
  `CompressionError("Unexpected end of buffer!")` (strict mode makes the nil visible; there is no NoMethodError).
- **Buffers** are binary Strings appended in place with `String.append_as_bytes` (Ruby's `buffer << byte`);
  the caller's String is the same object, as in Ruby.
- `Context#initialize_copy` is `Context.dup(ctx)`.

## Built-ins Sake lacks

- `Integer.downto` exists, but `7.downto(0)` must be written `Integer.downto(7, 0)` (rule, not a gap).
- None needed beyond what is there; `String.append_as_bytes`, `setbyte`, `getbyte`, `byteslice`, `unpack1("H*")` all worked.

## Friction

- `7.downto(0) do |shift|` → "method call on a value `7.downto` is not allowed" → `Integer.downto(7, 0)`.
- `String.getbyte(buf, first) | 0x80` → "Bitwise.|: the operands may be nil" → `(String.getbyte(buf, first) || 0) | 0x80`.
  getbyte's nil is not one of the "misses" level 2 lets through, unlike `x[i]`.
- Module-level constants (`INDEXED_TYPE = {prefix: 7, pattern: 0x80}`, the static table) → not allowed →
  `module Representation` with `prefix(type)` / `pattern(type)`, and tables as `def static_table = once { Array[...] }`.
- The command Hash (see above) → a `Command` class plus `x => String` / `x => Integer` narrowing in five places.
- Nothing else: the test passed on the first run once it checked.

## Size

Ruby: 1391 lines in 7 files (1001 without comments/blank lines, of which 575 are data rows: the static table, the
Huffman codes and the decoding machine) → about 426 lines of code. Sake: 524 lines (439 without comments/blank,
52 of them data rows) → about 387 lines of code.
