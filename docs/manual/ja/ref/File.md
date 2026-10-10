# File

File はファイルをパス（String）で扱う操作の集まりです。File という型の値はありません: `File.open` が返すのは `IO`（[IO](IO.md)）で、他の操作はパスを受け取ってその場で読み書き・問い合わせをします。Ruby の `File.read(path)` などのクラスメソッドと同じ名前で、インスタンスメソッド（`file.read`）に当たるものは `IO` の操作です（[値と型](../03-values.md)、[組み込み](../09-builtins.md)）。

システムコールの失敗（無いパス、権限、ディレクトリを読む、など。Ruby では `Errno::ENOENT` などの例外）はすべて `IOError` で、メッセージは Ruby のものです（[例外](../08-exceptions.md)）。パスの文字列処理（`basename`、`join`、`expand_path` など）はファイルを見ません。`exist?` などの問い合わせは失敗せず false を返します。

File に演算子はありません。例は空のディレクトリで実行され、そこにファイルを作ります。

## open

`File.open(String, [String], [Integer]) [{ }]`

ファイルを開いて `IO` を返します。第 2 引数はモードで省略すると `"r"`（Ruby と同じ: `"r"` 読む、`"w"` 書く（空にする）、`"a"` 追記、`"r+"` 読み書き、`"w+"`、`"a+"`、`"b"` を付けるとバイナリ）。第 3 引数は新しく作るファイルの許可ビット（`0o600` など。既にあるファイルには影響しません）。ブロックを付けると `IO` をブロックに渡し、ブロックの後にファイルを閉じて**ブロックの値**を返します（Ruby と同じ）。ブロック無しなら `IO.close` で自分で閉じます。無いファイルや権限の無いファイルは `IOError`、知らないモードは `ArgumentError`。

```ruby
f = File.open("a.txt", "w")
IO.puts(f, "one")
IO.close(f)
n = File.open("a.txt", "a") { |io| IO.write(io, "two\n") }
p(n)                                # => 4
p(File.open("a.txt") { |io| IO.readlines(io) })   # => ["one\n", "two\n"]
File.open("p.txt", "w", 0o600) { |io| nil }
p(File.exist?("p.txt"))             # => true
```

```ruby error
File.open("nope.txt")               # !> IOError: File.open: No such file or directory
```

## read

`File.read(String)`

ファイル全体を String で返します。無いファイルやディレクトリは `IOError`。

```ruby
File.write("a.txt", "hello\n")
p(File.read("a.txt"))               # => "hello\n"
```

```ruby error
File.read("nope.txt")               # !> IOError: File.read: No such file or directory
```

## readlines

`File.readlines(String)`

ファイル全体を行に分けた String の Array（各行は改行を含みます）。空のファイルは空の Array。

```ruby
File.write("a.txt", "a\nb\n")
p(File.readlines("a.txt"))          # => ["a\n", "b\n"]
```

## write

`File.write(String, String)`

ファイルを作る（あれば中身を置き換える）か書き、書いたバイト数（Integer）を返します。追記はしません（追記は `File.open(path, "a")`）。第 2 引数は String だけで、他の型は静的に `type` の問題です。

```ruby
p(File.write("a.txt", "日本"))      # => 6
p(File.write("a.txt", "x"))         # => 1
p(File.read("a.txt"))               # => "x"
```

```ruby error
File.write("a.txt", 1)              # !> File.write: argument 2 must be String, but is Integer
```

## exist?

`File.exist?(String)`

パスにファイルかディレクトリがあれば true。失敗しません。

```ruby
File.write("a.txt", "")
p(File.exist?("a.txt"))             # => true
p(File.exist?("."))                 # => true
p(File.exist?("nope"))              # => false
```

## file?, directory?, symlink?

`File.file?(String)`

`File.directory?(String)`

`File.symlink?(String)`

通常のファイル・ディレクトリ・シンボリックリンクなら true。`file?` と `directory?` はリンクをたどって先を見ます。無いパスは false。

```ruby
File.write("a.txt", "")
File.symlink("a.txt", "l1.txt")
p(File.file?("a.txt"))              # => true
p(File.file?("."))                  # => false
p(File.directory?("."))             # => true
p(File.symlink?("l1.txt"))           # => true
p(File.symlink?("a.txt"))           # => false
p(File.file?("nope"))               # => false
```

## zero?, empty?

`File.zero?(String)`

`File.empty?(String)`

ファイルがあって大きさが 0 なら true（2 つは同じ。Ruby と同じ）。無いパスは false。

```ruby
File.write("e.txt", "")
File.write("a.txt", "x")
p(File.zero?("e.txt"))              # => true
p(File.empty?("a.txt"))             # => false
p(File.zero?("nope"))               # => false
```

## readable?, writable?, executable?

`File.readable?(String)`

`File.writable?(String)`

`File.executable?(String)`

このプロセスがそのパスを読める・書ける・実行できるなら true。無いパスは false。

```ruby
File.write("a.txt", "")
p(File.readable?("a.txt"))          # => true
p(File.writable?("a.txt"))          # => true
p(File.executable?("a.txt"))        # => false
File.chmod(0o755, "a.txt")
p(File.executable?("a.txt"))        # => true
```

## size

`File.size(String)`

ファイルの大きさ（バイト数、Integer）。無いパスは `IOError`。

```ruby
File.write("a.txt", "日本")
p(File.size("a.txt"))               # => 6
```

```ruby error
File.size("nope")                   # !> IOError: File.size: No such file or directory
```

## mtime, atime

`File.mtime(String)`

`File.atime(String)`

最後に変更された・読まれた時刻を Time で返します。無いパスは `IOError`。

```ruby
File.write("a.txt", "")
File.utime(Time.at(0), Time.at(60), "a.txt")
p(Time.to_i(File.atime("a.txt")))   # => 0
p(Time.to_i(File.mtime("a.txt")))   # => 60
p(File.mtime("a.txt") <= Time.now)  # => true
```

## ftype

`File.ftype(String)`

種類を String で返します: `"file"`、`"directory"`、`"link"`（リンクそのもの。たどりません）、`"characterSpecial"` など Ruby と同じ。無いパスは `IOError`。

```ruby
File.write("a.txt", "")
File.symlink("a.txt", "l2.txt")
p(File.ftype("a.txt"))              # => "file"
p(File.ftype("."))                  # => "directory"
p(File.ftype("l2.txt"))              # => "link"
```

## identical?

`File.identical?(String, String)`

2 つのパスが同じファイルを指すなら true（リンクをたどります。ハードリンクも同じ）。どちらかが無ければ false。

```ruby
File.write("a.txt", "")
File.write("b.txt", "")
File.symlink("a.txt", "l3.txt")
p(File.identical?("a.txt", "l3.txt"))   # => true
p(File.identical?("a.txt", "b.txt"))   # => false
p(File.identical?("a.txt", "nope"))    # => false
```

## rename

`File.rename(String, String)`

ファイルを移す（名前を変える）。0 を返します。移す先にファイルがあれば置き換えます。元が無ければ `IOError`。

```ruby
File.write("a.txt", "x")
p(File.rename("a.txt", "b.txt"))    # => 0
p(File.exist?("a.txt"))             # => false
p(File.read("b.txt"))               # => "x"
```

```ruby error
File.rename("nope", "b.txt")        # !> IOError: File.rename: No such file or directory
```

## delete, unlink

`File.delete(String)`

`File.unlink(String, *String)`

ファイルを消します。`delete` は 1 つのパスを取り 1 を返します。`unlink` は 1 つ以上のパスを取り、消した数（Integer）を返します。ディレクトリは消せません（`Dir.rmdir`）。無いパスは `IOError`（Ruby の `Errno::ENOENT`）。

```ruby
File.write("a.txt", "")
File.write("b.txt", "")
File.write("c.txt", "")
p(File.delete("a.txt"))             # => 1
p(File.unlink("b.txt", "c.txt"))    # => 2
p(File.exist?("c.txt"))             # => false
```

```ruby error
File.delete("nope")                 # !> IOError: File.delete: No such file or directory
```

## symlink, link

`File.symlink(String, String)`

`File.link(String, String)`

`symlink(target, link)` はシンボリックリンク、`link(target, link)` はハードリンクを作り、0 を返します。`link` 側が既にあれば `IOError`。

```ruby
File.write("a.txt", "x")
p(File.symlink("a.txt", "s.txt"))   # => 0
p(File.link("a.txt", "h.txt"))      # => 0
p(File.read("s.txt"))               # => "x"
p(File.symlink?("h.txt"))           # => false
p(File.identical?("a.txt", "h.txt"))   # => true
```

```ruby error
File.write("a.txt", "")
File.symlink("a.txt", "a.txt")      # !> IOError: File.symlink: File exists
```

## readlink

`File.readlink(String)`

シンボリックリンクが指すパスを String で返します（書かれたままで、解決はしません）。リンクでないパスは `IOError`。

```ruby
File.write("a.txt", "")
File.symlink("a.txt", "l4.txt")
p(File.readlink("l4.txt"))           # => "a.txt"
```

```ruby error
File.write("a.txt", "")
File.readlink("a.txt")              # !> IOError: File.readlink: Invalid argument
```

## chmod

`File.chmod(Integer, *String)`

許可ビットを `mode`（`0o644` など）に変え、変えたファイルの数を返します。パスが無ければ 0。無いパスは `IOError`。

```ruby
File.write("a.txt", "")
File.write("b.sh", "")
p(File.chmod(0o755, "a.txt", "b.sh"))   # => 2
p(File.executable?("b.sh"))         # => true
p(File.chmod(0o644))                # => 0
```

## utime

`File.utime(Time|Nil, Time|Nil, *String)`

`utime(atime, mtime, *paths)`: 読まれた時刻と変更された時刻を設定し、変えたファイルの数を返します。nil は現在時刻です。無いパスは `IOError`。

```ruby
File.write("a.txt", "")
p(File.utime(Time.at(10), Time.at(20), "a.txt"))   # => 1
p(Time.to_i(File.atime("a.txt")))   # => 10
p(Time.to_i(File.mtime("a.txt")))   # => 20
File.utime(nil, nil, "a.txt")
p(File.mtime("a.txt") > Time.at(20))   # => true
```

## basename

`File.basename(String, [String])`

パスの最後の要素。第 2 引数に拡張子（`".rb"`）を与えるとそれを取り、`".*"` ならどんな拡張子でも取ります。ファイルは見ません。

```ruby
p(File.basename("/a/b/c.rb"))       # => "c.rb"
p(File.basename("/a/b/c.rb", ".rb"))   # => "c"
p(File.basename("c.tar.gz", ".*"))  # => "c.tar"
p(File.basename("/a/b/"))           # => "b"
```

## dirname

`File.dirname(String, [Integer])`

最後の要素を取ったディレクトリ部分。第 2 引数 `n` で `n` 段上がります（省略時 1、0 なら元のまま）。ディレクトリ部分が無ければ `"."`。

```ruby
p(File.dirname("/a/b/c.rb"))        # => "/a/b"
p(File.dirname("/a/b/c.rb", 2))     # => "/a"
p(File.dirname("c.rb"))             # => "."
```

## extname

`File.extname(String)`

最後の要素の拡張子（ドットを含む）。無ければ `""`。ドットで始まる名前（`.bashrc`）は拡張子無しです。

```ruby
p(File.extname("c.tar.gz"))         # => ".gz"
p(File.extname("c"))                # => ""
p(File.extname(".bashrc"))          # => ""
```

## split

`File.split(String)`

`[dirname, basename]` の 2 要素の Tuple（String, String）。Ruby では Array ですが Sake では Tuple で、`dir, base = File.split(p)` で分解します。

```ruby
dir, base = File.split("/a/b/c.rb")
p(dir)                              # => "/a/b"
p(base)                             # => "c.rb"
p(File.split("c.rb"))               # => [".", "c.rb"]
```

## join

`File.join(*String|Array)`

部分を `/` で繋いだパス。重なる `/` は 1 つにします。引数は String か String の Array（入れ子も平らにします）で、引数が無ければ `""`。他の型は静的に `type` の問題です。

```ruby
p(File.join("a", "b", "c.rb"))      # => "a/b/c.rb"
p(File.join("a/", "/b"))            # => "a/b"
p(File.join(Array["a", "b"], "c"))  # => "a/b/c"
p(File.join())                      # => ""
```

```ruby error
File.join(1)                        # !> File.join: argument 1 must be String|Array, but is Integer
```

## expand_path, absolute_path

`File.expand_path(String, [String])`

`File.absolute_path(String, [String])`

相対パスを絶対パスにします。第 2 引数は基準のディレクトリで、省略すると現在のディレクトリ（`Dir.pwd`）。`.` と `..` は解決しますが、ファイルは見ずリンクもたどりません。違いは `~`: `expand_path` は `~` をホームディレクトリに展開し（知らないユーザーの `~user` は `ArgumentError`）、`absolute_path` は展開しません（Ruby と同じ）。

```ruby
p(File.expand_path("/x/../y"))      # => "/y"
p(File.expand_path("b", "/a"))      # => "/a/b"
p(File.absolute_path("b", "/a"))    # => "/a/b"
p(File.expand_path("a") == File.join(Dir.pwd, "a"))   # => true
p(File.expand_path("~") == Dir.home)                  # => true
p(File.absolute_path("~") == File.join(Dir.pwd, "~")) # => true
```

## absolute_path?

`File.absolute_path?(String)`

パスが絶対（`/` で始まる）なら true。ファイルは見ません。

```ruby
p(File.absolute_path?("/a/b"))      # => true
p(File.absolute_path?("a/b"))       # => false
```

## realpath

`File.realpath(String, [String])`

シンボリックリンクをすべてたどった実際の絶対パス。第 2 引数は相対パスの基準ディレクトリです。パスは実在しなければならず、無ければ `IOError`（`expand_path` との違い）。

```ruby
File.write("a.txt", "")
File.symlink("a.txt", "l5.txt")
p(File.realpath("l5.txt") == File.join(Dir.pwd, "a.txt"))   # => true
p(File.realpath("l5.txt", Dir.pwd) == File.realpath("./a.txt"))   # => true
```

```ruby error
File.realpath("nope")               # !> IOError: File.realpath: No such file or directory
```
