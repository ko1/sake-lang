# Notes for 17-encodings (revision round)

Remaining workarounds with today's Sake:

- No `Integer.to_s(n, base)` / `String.to_i(s, base)`: binary and hex still go through `format("%b"/"%x")` and `String.hex`.
- No `Hash.new { |h, k| h[k] = [] }` (blocks are not values): rolling_sync and percent_encoding still look up, create and store the list by hand.
- No `Array.new(n, x)`: transposition and vigenere build placeholder Arrays with `Array.map(Range.to_a(0...n)) { "" }`.
- No value constants: alphabets and tables (Morse, Base64, letter frequencies, CRC catalogue) remain zero-argument functions.
- A line-1 comment containing "coding:" is still read by Prism as a magic encoding comment (huffman, percent_encoding comments stay reworded).
- `(x in T) ? a : b` still needs the parentheses (protobuf_wire), as in Ruby.

No interpreter bugs found. Every revised program was checked with `bin/sake --strict=0`: exit 0 and byte-identical output.
