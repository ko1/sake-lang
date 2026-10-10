# Zlib

Zlib is the group of operations that compress and decompress a String in the zlib and gzip formats (Ruby's `Zlib.deflate`, `inflate`, `gzip`, and `gunzip`; built in for speed, see [Built-ins](../09-builtins.md)). There is no compression level and no stream form (no `Zlib::Deflate` class).

Both the compressed and the decompressed result are binary Strings (encoding `ASCII-8BIT`). Decompressing a UTF-8 string gives the same bytes in a different encoding, so the result is not `==` to the original: pass it through `String.force_encoding(s, "UTF-8")` to use it as text. Corrupt input, or input of the other format (gzip data given to `inflate`), is an `ArgumentError` with zlib's message (`incorrect header check`, ...); there is no exception type for Ruby's `Zlib::DataError` and the like.

Zlib has no operators.

## deflate, inflate

`Zlib.deflate(String)`

`Zlib.inflate(String)`

`deflate` returns the String compressed in the zlib format (RFC 1950); `inflate` returns the original String. The empty string can be compressed and decompressed, but `inflate("")` is an `ArgumentError` (`buffer error`).

```ruby
s = String.*("hello ", 100)
z = Zlib.deflate(s)
p(String.bytesize(z) < String.bytesize(s))   # => true
p(Zlib.inflate(z) == s)                      # => true
p(String.encoding(Zlib.inflate(z)))          # => "ASCII-8BIT"
j = Zlib.inflate(Zlib.deflate("日本"))
p(j == "日本")                               # => false
p(String.force_encoding(j, "UTF-8") == "日本")   # => true
```

```ruby error
Zlib.inflate("not compressed")      # !> ArgumentError: Zlib.inflate: incorrect header check
```

## gzip, gunzip

`Zlib.gzip(String)`

`Zlib.gunzip(String)`

`gzip` returns the String compressed in the gzip format (RFC 1952, the format of the `gzip` command and of `.gz` files; the first two bytes are `0x1f 0x8b`); `gunzip` returns the original String. The result of `deflate` cannot be given to `gunzip`, nor that of `gzip` to `inflate` (`ArgumentError`).

```ruby
g = Zlib.gzip("hello")
p(String.getbyte(g, 0))             # => 31
p(String.getbyte(g, 1))             # => 139
p(Zlib.gunzip(g))                   # => "hello"
File.write("a.gz", g)
out, status = Open3.capture2("sh", "-c", "gunzip -c a.gz")
p(out)                              # => "hello"
```

```ruby error
Zlib.gunzip(Zlib.deflate("x"))      # !> ArgumentError: Zlib.gunzip:
```
