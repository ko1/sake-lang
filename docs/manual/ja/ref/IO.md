# IO

IO は開いたファイルとプログラムの標準ストリームの型です。値は操作から来ます: `IO.stdin`、`IO.stdout`、`IO.stderr` が標準ストリームを、`File.open(path, mode)` がファイルを与えます（Sake に `$stdout` や `STDOUT` はありません。[値と型](../03-values.md)）。ファイルとストリームの型は 1 つなので、IO を受け取る関数はどちらにも書けます。IO のリテラルはありません。

Ruby の `io.puts(x)` は `IO.puts(io, x)` と書きます。Ruby の `IO` のメソッドのうち、ここに挙げたものだけがあります。読み書きの失敗（閉じた IO、その向きに開いていない IO、OS のエラー）は `IOError` です（Ruby の `Errno::ENOENT` などもまとめて `IOError`。[例外](../08-exceptions.md)）。

IO に使える演算子は `==`、`!=` だけです（同じストリームか同じ `File.open` の結果のとき等しい）。引数の無い操作 `IO.stdout()` は `IO.stdout` とも書けます。

## stdin, stdout, stderr

`IO.stdin()`

`IO.stdout()`

`IO.stderr()`

プログラムの標準入力・標準出力・標準エラー出力を IO として返します。何度呼んでも同じ値で、`IO.stdout == IO.stdout` は true です。`Kernel.puts` と `Kernel.p` は `IO.stdout` に書き、`Kernel.gets` は `IO.stdin` から読みます。`IO.stderr` への書き込みは先に stdout を flush するので、2 つのストリームの行の順序が保たれます。標準ストリームを `IO.close` で閉じてはいけません: 閉じると以後の `p` などの出力が Ruby の `IOError` でプログラムを止めます。

```ruby
out = IO.stdout
IO.puts(out, "hello")            # => hello
p(IO.stdout == out)              # => true
p(IO.stdout == IO.stderr)        # => false
p(IO.stdin)                      # => #<IO:<STDIN>>
```

## puts

`IO.puts(x, *Any)`

各引数を `Kernel.puts` と同じ形で `x` に書き、nil を返します。引数ごとに 1 行（末尾に改行が無ければ加える）。Array と Tuple は平らにして要素ごとに 1 行、空の Array は空行、引数が無ければ空行 1 つ。文字列以外は `Kernel.to_s` の形です（nil は空行、Symbol は名前）。閉じた IO や読み出し専用の IO には `IOError`。

```ruby
out = IO.stdout
IO.puts(out, "a", 1)             # => a
                                 # => 1
IO.puts(out, [1, Array[2, 3]])   # => 1
                                 # => 2
                                 # => 3
IO.puts(out, "x\n")              # => x
p(IO.puts(out, :s))              # => s
                                 # => nil
```

## print

`IO.print(x, *Any)`

各引数の `to_s` を改行を挟まずに `x` に書き、nil を返します（Ruby の `io.print`）。Array は `[1, 2]` の形、nil は空文字列です。

```ruby
out = IO.stdout
IO.print(out, "a", 1, :s, "\n")  # => a1s
IO.print(out, Array[1, 2], "\n") # => [1, 2]
```

## write

`IO.write(x, String)`

文字列をそのまま `x` に書き、書いたバイト数（Integer）を返します。改行は加えません。引数は String でなければならず、他の型は静的に `type` の問題です（`puts` や `print` と違い、変換しません）。

```ruby
p(IO.write(IO.stdout, "ab\n"))   # => ab
                                 # => 3
p(IO.write(IO.stdout, "日本\n")) # => 日本
                                 # => 7
```

```ruby error
IO.write(IO.stdout, 1)           # !> IO.write: argument 2 must be String, but is Integer
```

## flush

`IO.flush(x)`

バッファに溜まった出力を書き出し、`x` を返します。`File.open` で開いたファイルへの `IO.write` や `IO.puts` はバッファされ、`flush` か `close` でファイルに届きます。

```ruby
f = File.open("log.txt", "w")
IO.puts(f, "a")
p(File.read("log.txt"))          # => ""
IO.flush(f)
p(File.read("log.txt"))          # => "a\n"
IO.close(f)
```

## gets

`IO.gets(x)`

次の 1 行を改行を含めて返し（Ruby の `io.gets`）、終端では nil です。結果は `String | nil` なので、`--strict`（レベル 2）はそのまま使うことを `nil` の問題として報告します: `if line`、`while (line = IO.gets(io))` のように確かめてから使います。書き込み専用の IO では `IOError`。

```ruby
io = IO.stdin
line = IO.gets(io)
if line
  p(String.to_i(line))           # => 3
end
while (l = IO.gets(io))
  p(l)                           # => "1 2\n"
end
p(IO.gets(io))                   # => nil
```

```ruby error
line = IO.gets(IO.stdin)
p(String.upcase(line))           # !> argument 1 may be nil
```

## read

`IO.read(x, [Integer])`

`IO.read(io)` は現在位置から終端までをすべて読んで String を返します（終端ではすでに空文字列 `""`。nil にはなりません）。`IO.read(io, n)` は最大 `n` バイト（文字ではなくバイト）を読み、終端に達していれば nil を返します（`n` が 0 のときは常に `""`）。この 2 引数の形だけが `String | nil` で、レベル 2 で検査されます。読み出しに開いていない IO は `IOError`。

```ruby
io = IO.stdin
p(IO.read(io, 2))                # => "3\n"
p(IO.read(io))                   # => "1 2\n"
p(IO.read(io))                   # => ""
p(IO.read(io, 1))                # => nil
```

## getc

`IO.getc(x)`

次の 1 文字を String で返し、終端では nil です（`String | nil`、レベル 2）。

```ruby
io = IO.stdin
p(IO.getc(io))                   # => "3"
p(IO.getc(io))                   # => "\n"
IO.read(io)
p(IO.getc(io))                   # => nil
```

## readlines

`IO.readlines(x)`

現在位置から終端までを行に分けて、String の Array で返します（各行は改行を含みます）。終端では空の Array です。

```ruby
p(IO.readlines(IO.stdin))        # => ["3\n", "1 2\n"]
p(IO.readlines(IO.stdin))        # => []
```

## each_line

`IO.each_line(x) { }`

現在位置から終端まで、1 行ずつ（改行を含む String）ブロックに渡し、`x` を返します。ブロックの値は使いません。Ruby の `io.each_line` と同じで、ブロックは必須です。

```ruby
r = IO.each_line(IO.stdin) { |l| p(String.chomp(l)) }   # => "3"
                                                         # => "1 2"
p(r == IO.stdin)                 # => true
```

## eof?

`IO.eof?(x)`

読み出し位置が終端にあれば true。書き込み専用の IO や閉じた IO では `IOError`。

```ruby
io = IO.stdin
p(IO.eof?(io))                   # => false
IO.read(io)
p(IO.eof?(io))                   # => true
```

## seek

`IO.seek(x, Integer, [Integer|Symbol])`

読み書きの位置を動かし、0 を返します（Ruby の `io.seek`）。第 2 引数はオフセット、第 3 引数は基準で、省略すると先頭（`0`）。`0`/`:SET` は先頭から、`1`/`:CUR` は現在位置から、`2`/`:END` は末尾から（オフセットは負）。Symbol はこの 3 つだけで、他の Symbol は Ruby の `NameError` でプログラムが止まります。seek できないストリーム（パイプの `IO.stdin` など）は `IOError`。

```ruby
File.write("a.txt", "hello\n")
f = File.open("a.txt")
IO.seek(f, 2)
p(IO.read(f, 2))                 # => "ll"
IO.seek(f, -2, :END)
p(IO.read(f))                    # => "o\n"
p(IO.seek(f, 1, :SET))           # => 0
p(IO.getc(f))                    # => "e"
IO.close(f)
```

## pos

`IO.pos(x)`

現在の位置（先頭からのバイト数、Integer）。seek できないストリームでは `IOError`。

```ruby
File.write("a.txt", "日本\n")
f = File.open("a.txt")
p(IO.pos(f))                     # => 0
IO.getc(f)
p(IO.pos(f))                     # => 3
IO.close(f)
```

## rewind

`IO.rewind(x)`

位置を先頭に戻し、0 を返します。もう一度読み直すときに使います。

```ruby
File.write("a.txt", "one\n")
f = File.open("a.txt")
p(IO.gets(f))                    # => "one\n"
p(IO.rewind(f))                  # => 0
p(IO.gets(f))                    # => "one\n"
IO.close(f)
```

## size

`IO.size(x)`

開いたファイルの大きさ（バイト数、Integer）。まだ flush していない書き込みも含みます。ファイルでない IO（`IO.stdin` などのストリーム）には使えず、Ruby の `NoMethodError` でプログラムが止まります（`IOError` ではありません）。

```ruby
f = File.open("a.txt", "w")
IO.write(f, "abc")
p(IO.size(f))                    # => 3
IO.close(f)
```

## truncate

`IO.truncate(x, Integer)`

ファイルを `n` バイトに切り詰め、0 を返します。書き込みに開いていないファイルは `IOError`。

```ruby
File.write("a.txt", "hello")
r = File.open("a.txt", "r+") { |f| IO.truncate(f, 3) }
p(r)                             # => 0
p(File.read("a.txt"))            # => "hel"
```

```ruby error
File.write("a.txt", "hello")
f = File.open("a.txt")
IO.truncate(f, 1)                # !> IOError: IO.truncate: not opened for writing
```

## close

`IO.close(x)`

IO を閉じて nil を返します。バッファの出力は書き出されます。閉じた IO をもう一度閉じても何も起きません（Ruby と同じ）。閉じた IO への読み書きは `IOError`。`File.open` のブロック形はブロックの後に自動で閉じるので、`close` は手で開いたときだけ必要です。

```ruby
f = File.open("a.txt", "w")
IO.write(f, "x")
p(IO.close(f))                   # => nil
p(IO.close(f))                   # => nil
p(File.read("a.txt"))            # => "x"
```

```ruby error
f = File.open("a.txt", "w")
IO.close(f)
IO.write(f, "x")                 # !> IOError: IO.write: closed stream
```

## closed?

`IO.closed?(x)`

閉じていれば true。`File.open` のブロックに渡された IO は、ブロックの後では閉じています。

```ruby
kept = IO.stdout
File.open("a.txt", "w") { |f| kept = f }
p(IO.closed?(kept))              # => true
p(IO.closed?(IO.stdout))         # => false
```

## tty?

`IO.tty?(x)`

端末に繋がっていれば true（Ruby の `io.tty?`）。ファイルやパイプでは false。検査器の中では標準入出力もパイプなので false です。

```ruby
f = File.open("a.txt", "w")
p(IO.tty?(f))                    # => false
IO.close(f)
```

## ==, !=

`IO.==(x, Any)`

`IO.!=(x, Any)`

2 つの IO 値が同じストリーム、または同じ `File.open` の結果なら等しい（`!=` はその否定）。同じパスを 2 回開いた IO は別の値です。IO 以外の値とは等しくありません。

```ruby
f = File.open("a.txt", "w")
g = File.open("a.txt", "w")
p(f == f)                        # => true
p(f == g)                        # => false
p(IO.stdout != IO.stdin)         # => true
IO.close(f)
IO.close(g)
```
