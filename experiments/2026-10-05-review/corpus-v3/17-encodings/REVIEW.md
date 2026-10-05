# Review of 17-encodings (2026-10-05)

All 25 programs run with `bin/sake --strict=0` with exit status 0, and their stdout is byte-identical to `NAME.out`.
The `.rb` files here are dangling symlinks (`../../corpus/...`), so the Ruby versions were read from
`experiments/2026-10-01-inference-500/corpus/17-encodings/`.

- ascii85: exception type `A85Error = Exception.new(:index)` -> `class A85Error < StandardError` + `attr_reader index`; the error loop's `begin/rescue/end` -> `rescue` in the `do` block body, as Ruby writes it
- base32_ids: the error loop's `begin` -> `rescue` in the `do` block body
- base64_codec: `DecodeError` -> `class ... < StandardError` + `attr_reader position`; `rescue` in the `do` block body
- bitset: unchanged
- bloom_filter: `Struct.new` -> `class Bloom` + `attr_reader size, hashes, words, count` (`count` is written only through `@count` inside the class); `create`'s times+push loop -> `Array.new(n, 0)`, as in Ruby
- caesar_cracker: `english_freq` (the Ruby `ENGLISH_FREQ` constant, built again on every one of 104 `chi_squared` calls) -> `once`
- check_digits: unchanged
- crc_catalog: `Struct.new` -> `class CrcModel` + `attr_reader` (8 fields); `catalogue` (Ruby `CATALOGUE`, called twice) -> `once`
- frame_parser: `Temperature`, `Position`, `Note` -> `class` + `attr_reader`; `Stats` stays `Struct.new` (Ruby uses `attr_accessor` there, which is what `Struct.new` declares)
- hamming_secded: `Decoded` -> `class` + `attr_reader`
- hex_dump: `rescue` in the `do` block body
- huffman: `HNode` -> `class` + `attr_reader`
- lzw: unchanged
- morse: unchanged
- murmur_ring: `Ring` -> `class` + `attr_reader`
- percent_encoding: in `parse_query`, the five-line look-up/create/store of the value list -> `Array.push(params[key] ||= String[], ...)`, Ruby's `(params[k] ||= []) << v`; `rescue` in the `do` block body
- playfair: `Square` -> `class` + `attr_reader`
- protobuf_wire: `Field` -> `class` + `attr_reader`; `WireError` -> `class ... < StandardError`; `rescue` in the `do` block body
- raid5_parity: Ruby's `zero_block = Array.new(BLOCK_SIZE, 0)` helper, which the Sake version had inlined four times as `Array.map(Range.to_a(1..block_size)) { 0 }`, is back; `Disk` stays `Struct.new` (Ruby uses `attr_accessor`, and `rebuild` writes the fields from outside)
- rolling_sync: `BlockSig` -> `class` + `attr_reader`; the look-up/create/store of the signature list -> `Array.push(sigs[weak] ||= BlockSig[], ...)`
- run_length: `RleError` -> `class ... < StandardError`; `rescue` in the `do` block body
- transposition: placeholder Arrays `Array.map(Range.to_a(0...n)) { "" }` -> `Array.new(n, "")` (twice, as Ruby); `common_words` (Ruby `COMMON_WORDS`, rebuilt on every `score` call) -> `once`
- utf8_codec: `Utf8Error` -> `class ... < StandardError`; `rescue` in two `do` block bodies
- vigenere: `columns` -> `Array.new(period) { "" }` (Ruby's form); `english` (Ruby `ENGLISH`, rebuilt for each of 26 shifts per column) -> `once`
- xor_breaker: `transpose` -> `Array.new(size) { Integer[] }`, Ruby's `Array.new(size) { [] }`

21 programs changed and 4 unchanged (bitset, check_digits, lzw, morse). base32_ids and hex_dump changed only in the `rescue` form.
Features used: `class` + `attr_reader` (9 programs), `class E < StandardError` (5), `rescue` in a block body (8),
`once` (4), `Array.new(n, v)` / `Array.new(n) { }` (5), `h[k] ||= v` (2). These programs had no place for
optional or keyword parameters, `x => T`, `initialize`, `class B < A`, or `&b`: none of the Ruby versions use them.

`once` was used only where the Sake function rebuilt a Ruby constant on many calls. Where it ran once anyway
(`morse_table` at morse.sake:66, `sample_texts` at lzw.sake:75, `bitmap` in run_length), the function was left as it was.

## Friction

- **Writing a counter field from outside.** I wanted Ruby's `stats.skipped += 1`. Sake has no field-assignment syntax
  outside the class, so the code stays `Stats.set_skipped(stats, Stats.get_skipped(stats) + 1)` (frame_parser.sake:56,
  and three more lines like it). The same applies to `Disk.set_blocks(lost, blocks)` (raid5_parity.sake:71) for
  Ruby's `lost.blocks = ...`.
- **Reading the second operand's fields.** `@x` reads only the first parameter. In Ruby, `def <=>(other)` reads
  `other.weight` directly; here it is `[@weight, @order] <=> [HNode.get_weight(b), HNode.get_order(b)]`
  (huffman.sake:8) and `@bits & BitSet.get_bits(b)` (bitset.sake:19-21). This asymmetry makes the operator code
  noticeably lopsided.
- **Reading a Record field in a block.** I wanted Ruby's `c[:score]`. A Record field can only be read with a
  pattern, so a one-line block becomes two statements: `{ |c| c => {score:}; score }` (caesar_cracker.sake:56,
  vigenere.sake:51 twice).
- **No `loop do`.** I wanted Ruby's `loop do ... break if ... end`. It is written `while true` (base32_ids.sake:61,
  protobuf_wire.sake:47).
- **Padding an Array.** I wanted Ruby's `chunk + [0] * (4 - n)`. The `[0]` literal is a fixed-length Tuple, so
  padding is a `push ... while` loop on a `dup` (ascii85.sake:13, raid5_parity.sake:23).
  `c + Array.new(4 - n, 0)` would now work, but it was left alone because the loop is not wrong.
- **`each_slice` / `each_with_index` without a block.** Ruby chains `bytes.each_slice(3)`, `each_with_index.map`,
  `each_with_index.sum`, `each_slice(w).with_index.map`. Sake needs a block on each of these, so the programs build
  the result with a mutable accumulator, an index counter, or a `while` loop (base64_codec.sake:14, hex_dump
  `dump_lines`, check_digits `luhn_sum`, xor_breaker `hamming`, rolling_sync `signatures`).
- **No `Hash.new { |h, k| h[k] = [] }`.** `h[k] ||= T[]` now covers it in one line (percent_encoding, rolling_sync),
  so this is minor.

## Ruby comparison

What a Ruby programmer notices first, beyond `Type.op(x, ...)` on every call:

- **Exception classes have no body.** Ruby's `initialize(message, index); super(message); @index = index` disappears:
  `class A85Error < StandardError` with `attr_reader index` takes `message` as its first field (ascii85.sake:4-6).
  Reading the extra field is `A85Error.get_index(e)`, not `e.index`.
- **Factories are plain functions of the class.** Ruby's `def self.build` + `new(...)` becomes `def build(nodes, replicas)`
  inside `class Ring` returning `Ring.new(...)` (murmur_ring.sake:47, playfair.sake:7, bloom_filter.sake:22). Calls look
  the same (`Ring.build(...)`), but instance functions take the instance as a first parameter that is visible
  (`def lookup(ring, key)`).
- **Tables are functions.** `ENGLISH_FREQ` is `english_freq` with `once`. Small scalar constants (`MASK32`, `SYNC`,
  `MAX_CODE`, `BLOCK_SIZE`) are zero-argument functions (`mask32`, `sync`, ...).
- **Typed Arrays.** Accumulators are `Integer[]`, `String[]`, `BlockSig[]`, where Ruby writes `[]`. A literal
  `[a, b]` is a Tuple (the `[result, pos]` returns in protobuf_wire and utf8_codec), so a growable list must be
  spelled `Array[...]`.
- **`p.nil?` and `x.is_a?(T)`** are `p == nil` and `(x in T)` (protobuf_wire.sake:115 needs the parentheses).
