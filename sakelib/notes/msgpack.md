# msgpack (MessagePack)

`require "msgpack"` → `sakelib/msgpack.sake` (after the msgpack gem 1.8.3). The gem's packer and unpacker are C
(`ext/msgpack/packer.h`, `unpacker.c`, `*_class.c`); they are written here in Sake over binary Strings
(`Array.pack`, `String.unpack1`, `String.append_as_bytes`, `String.byteslice`). Test:
`test/sakelib/msgpack.{sake,rb}` (every integer width, str/bin, containers, Packer, streaming Unpacker,
ext, Timestamp, errors; identical output).

## API

| Ruby | Sake | |
|---|---|---|
| `MessagePack.pack(v)` / `dump` | `MessagePack.pack(v)` / `dump` | same |
| `MessagePack.unpack(s)` / `load` | `MessagePack.unpack(s)` / `load` | same |
| `MessagePack.unpack(s, symbolize_keys: true)` (also `freeze:`, `allow_unknown_ext:`) | `MessagePack.unpack(s, Hash[symbolize_keys: true])` | differs: options Hash (`freeze` is accepted and ignored) |
| `MessagePack.pack(v, io)` / `unpack(io)` | — | missing: no IO sources and sinks (ArgumentError) |
| `obj.to_msgpack` / `obj.to_msgpack(packer)` | `Hash.to_msgpack(h)` (Array, String, Integer, Float, Symbol too) | same; nil/true/false have no namespace to hang it on |
| `MessagePack::Packer.new` / `.new(nil, compatibility_mode: true)` | `MessagePack::Packer.new` / `.new(nil, Hash[compatibility_mode: true])` | same shape |
| `pk.write(v)`, `write_nil/true/false/int/float/float32/string/bin/symbol/array/hash/extension` | `MessagePack::Packer.write(pk, v)`, ... | same (return the packer, so chains work: `pk.MessagePack::Packer.write(1).MessagePack::Packer.write_nil`) |
| `pk.write_array_header(n)`, `write_map_header(n)`, `write_bin_header(n)`, `write_ext(type, payload)` | same | same |
| `pk.to_s` / `to_str` / `to_a` / `full_pack` / `size` / `empty?` / `reset` / `clear` / `flush` | same | same |
| `pk.register_type(...)`, `registered_types`, `type_registered?` | `registered_types` only (always `[]`) | missing (below) |
| `MessagePack::Unpacker.new` / `.new(nil, symbolize_keys: true)` | `MessagePack::Unpacker.new` / `.new(nil, Hash[...])` | same shape |
| `u.feed(s)` / `feed_reference` / `each { }` / `feed_each(s) { }` / `read` / `skip` / `skip_nil` / `read_array_header` / `read_map_header` / `full_unpack` / `reset` | same | same |
| `u.buffer` | `MessagePack::Unpacker.buffer(u)` | differs: a String of the unread bytes, not a `MessagePack::Buffer`; and see "partial objects" |
| `MessagePack::ExtensionValue.new(type, payload)` | same (`Struct.new(:type, :payload)`) | same; `p` prints a Sake struct, not `#<struct ...>` |
| `MessagePack::Timestamp.new(sec, nsec)`, `.from_msgpack_ext(data)`, `.to_msgpack_ext(sec, nsec)`, `#to_msgpack_ext`, `==` | same; the instance form is `Timestamp.to_msgpack_ext(ts)` | same (one name: the class and instance methods share it) |
| `MessagePack::Factory`, `register_type`, `MessagePack::Time`, Bigint, `MessagePack::Buffer` | — | missing |
| `UnpackError`, `MalformedFormatError`, `StackError`, `UnexpectedTypeError`, `UnknownExtTypeError` | same names | same, without the hierarchy |

About 50 operations.

## What differs and why

- **Ext type registration** is not ported: Ruby's `register_type(type, klass, :to_msgpack_ext)` and the
  unpacker's `register_type(type) { |data| ... }` take a Class and a Proc (or a method name), and Sake has
  neither as values (no stored blocks, no reflection). What works: `ExtensionValue` packs as ext, and an
  ext unpacks to an `ExtensionValue` with `allow_unknown_ext`; `Timestamp.to/from_msgpack_ext` give the
  payload for type -1, so a program can pack a Timestamp by hand (`write_ext(-1, Timestamp.to_msgpack_ext(t))`).
- **Partial objects.** Ruby's C unpacker keeps a half-read object's state and drops its bytes from the
  buffer; this one rewinds and keeps the bytes until the object is whole (`u.buffer.size` is 0 in Ruby,
  2 here after feeding `"\x93\x01"`). The objects yielded are the same.
- **Unpackable values.** Ruby raises NoMethodError (`undefined method 'to_msgpack'`) for a Time or a
  Range; Sake has no NoMethodError, so it raises TypeError with that text.
- **Encodings.** Strings whose encoding is ASCII-8BIT are bin, others str (converted to UTF-8 first);
  `compatibility_mode` writes all as str without str8, as Ruby. Unpacked str is UTF-8, bin ASCII-8BIT.
- **Integers** use the shortest form, as `msgpack_packer_write_long`; out of range raises RangeError with
  Ruby's message. Floats are always float 64 (`write_float32` for float 32).
- **Stack depth**: 128 nested containers, then `StackError`, as the C unpacker's stack capacity.

## Built-ins Sake lacks

- A result type for `String.unpack1(s, "N")` that follows the directive: it is `Integer | Float | String |
  nil`, so every read needs `v => Integer` (the `uint`, `sint`, `float` helpers).
- `String.dup` (there is `dup(x)` and `Array.dup`, `Hash.dup`).
- NoMethodError (to match Ruby's error for unpackable values).
- Procs or Class values (for `register_type`).

## Friction

- `String.dup(@buffer)` → `undefined function String.dup` (hint: `dup` is in `Kernel.dup`) → `dup(@buffer)`.
- `Integer.times(String.unpack1(take(u, 2), "n"))` → `Integer.times: argument 1 must be Integer, but can be
  Float | nil | String`, and the same at `String.byteslice` and `+`; the hint blamed
  `ExtensionValue.type holds ... Float, String`, the field the value later flowed into, which sent me
  looking at the wrong place → `uint/sint/float` helpers that assert the type once.
- `Packer.new(nil, Hash[compatibility_mode: true])`, Ruby's `(io, options)`: `new` takes the fields in
  order, so the class starts with `attr_reader io, options` (io must be nil) and keeps the buffer in a
  later private field.
- Adding `to_msgpack` to the core types: `module MsgpackCoreExt` + `class Hash; include MsgpackCoreExt;
  end` (and Array, String, Integer, Float, Symbol) worked as in Ruby.
- What went well: the byte-level code (shifts, `pack`/`unpack1` directives, `append_as_bytes` on a
  binary String) ran as Ruby's would; the test matched on the first run except for the partial-object
  buffer size above.

## Size

Ruby: 267 lines of the gem's lib (packer.rb, unpacker.rb, timestamp.rb, core_ext.rb, msgpack.rb) and
~2030 lines of C in the five files this replaces (without comments and blank lines; much of the C is
buffer management and the ext registry). Sake: 471 lines (579 with comments).
