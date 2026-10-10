# Zlib

Zlib は String を zlib 形式・gzip 形式で圧縮・展開する操作の集まりです（Ruby の `Zlib.deflate`、`inflate`、`gzip`、`gunzip`。速度のために組み込みです。[組み込み](../09-builtins.md)）。圧縮レベルやストリームの形（`Zlib::Deflate` クラスなど）はありません。

圧縮した結果と展開した結果はどちらもバイナリの String（エンコーディング `ASCII-8BIT`）です。UTF-8 の文字列を展開した結果と元の文字列は、バイトは同じでもエンコーディングが違うので `==` になりません: 文字列として使うなら `String.force_encoding(s, "UTF-8")` を通します。壊れた入力や形式の違う入力（`inflate` に gzip を渡す、など）は `ArgumentError` で、メッセージは zlib のもの（`incorrect header check` など。Ruby の `Zlib::DataError` 等に当たる例外型はありません）。

Zlib に演算子はありません。

## deflate, inflate

`Zlib.deflate(String)`

`Zlib.inflate(String)`

`deflate` は zlib 形式（RFC 1950）に圧縮した String、`inflate` はそれを元に戻した String を返します。空の文字列も圧縮・展開できますが、`inflate("")` は `ArgumentError`（`buffer error`）です。

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

`gzip` は gzip 形式（RFC 1952。`gzip` コマンドや `.gz` ファイルと同じで、先頭 2 バイトは `0x1f 0x8b`）に圧縮した String、`gunzip` はそれを元に戻した String を返します。`deflate` の結果を `gunzip` に、`gzip` の結果を `inflate` に渡すことはできません（`ArgumentError`）。

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
