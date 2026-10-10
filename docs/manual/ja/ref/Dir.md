# Dir

Dir はディレクトリをパス（String）で扱う操作の集まりです。Dir という型の値はなく（Ruby の `Dir.open` や `Dir` オブジェクトはありません）、すべて Ruby の `Dir` のクラスメソッドと同じ名前・同じ結果です（[組み込み](../09-builtins.md)）。中身の一覧は String の Array で返ります。

システムコールの失敗（無いディレクトリ、空でないディレクトリの削除、など。Ruby の `Errno::ENOENT` 等）はすべて `IOError` で、メッセージは Ruby のものです（[例外](../08-exceptions.md)）。`exist?` は失敗せず false、`glob` は何にも合わなければ空の Array です。

Dir に演算子はありません。例は空のディレクトリで実行され、そこにディレクトリを作ります。

## children, entries

`Dir.children(String)`

`Dir.entries(String)`

ディレクトリの中の名前（パスではなく名前だけ）の Array。`children` は `.` と `..` を含まず、`entries` は含みます。順序は OS が返す順で決まっていないので、並べて使うなら `Array.sort`。無いディレクトリは `IOError`。

```ruby
Dir.mkdir("d1")
File.write("d1/a.txt", "")
File.write("d1/b.rb", "")
p(Array.sort(Dir.children("d1")))   # => ["a.txt", "b.rb"]
p(Array.sort(Dir.entries("d1")))    # => [".", "..", "a.txt", "b.rb"]
```

```ruby error
Dir.children("nope")                # !> IOError: Dir.children: No such file or directory
```

## each_child

`Dir.each_child(String) { }`

`children` の各名前を順にブロックに渡し、nil を返します（Ruby は Dir を返しますが、Sake では nil）。ブロックの値は使いません。順序は `children` と同じく決まっていません。無いディレクトリは `IOError`。

```ruby
Dir.mkdir("d2")
File.write("d2/x", "")
File.write("d2/y", "")
names = Array[]
r = Dir.each_child("d2") { |n| Array.push(names, n) }
p(Array.sort(names))                # => ["x", "y"]
p(r)                                # => nil
```

## glob

`Dir.glob(String|Array, [base: String])`

パターンに合うパスの Array（Ruby の `Dir.glob`。`*`、`?`、`[...]`、`{a,b}`、`**/` が使えます）。パターンは String か String の Array（どれかに合えばよい）。結果は Ruby と同じく並べ替え済みで、ドットで始まる名前は `*` に合いません。キーワード `base:` を与えると、そのディレクトリから探して**相対の名前**を返します。合うものが無いときや `base:` のディレクトリが無いときは空の Array で、失敗しません。

```ruby
Dir.mkdir("d3")
File.write("d3/a.txt", "")
File.write("d3/b.rb", "")
Dir.mkdir("d3/sub")
File.write("d3/sub/c.txt", "")
p(Dir.glob("d3/*.rb"))              # => ["d3/b.rb"]
p(Dir.glob("d3/**/*.txt"))          # => ["d3/a.txt", "d3/sub/c.txt"]
p(Dir.glob(Array["d3/*.txt", "d3/*.rb"]))   # => ["d3/a.txt", "d3/b.rb"]
p(Dir.glob("*", base: "d3"))        # => ["a.txt", "b.rb", "sub"]
p(Dir.glob("nope/*"))               # => []
```

## exist?

`Dir.exist?(String)`

パスにディレクトリがあれば true。ファイルや無いパスは false で、失敗しません。

```ruby
Dir.mkdir("d4")
File.write("f4", "")
p(Dir.exist?("d4"))                 # => true
p(Dir.exist?("f4"))                 # => false
p(Dir.exist?("nope"))               # => false
```

## empty?

`Dir.empty?(String)`

ディレクトリが空（`.` と `..` 以外に何も無い）なら true。無いディレクトリは `IOError`。

```ruby
Dir.mkdir("d5")
p(Dir.empty?("d5"))                 # => true
File.write("d5/a", "")
p(Dir.empty?("d5"))                 # => false
```

## mkdir

`Dir.mkdir(String, [Integer])`

ディレクトリを 1 つ作り、0 を返します。第 2 引数は許可ビット（`0o700` など。省略時は `0o777` を umask で削ったもの）。親が無いときや、同じ名前が既にあるときは `IOError`（Ruby の `mkdir -p` に当たるものはありません）。

```ruby
p(Dir.mkdir("d6"))                  # => 0
p(Dir.mkdir("d6/sub", 0o700))       # => 0
p(Dir.exist?("d6/sub"))             # => true
```

```ruby error
Dir.mkdir("d6b")
Dir.mkdir("d6b")                    # !> IOError: Dir.mkdir: File exists
```

## rmdir, unlink

`Dir.rmdir(String)`

`Dir.unlink(String)`

空のディレクトリを消し、0 を返します（2 つは同じ。Ruby と同じ）。空でないディレクトリや無いパスは `IOError`。ファイルを消すのは `File.delete`。

```ruby
Dir.mkdir("d7")
p(Dir.rmdir("d7"))                  # => 0
p(Dir.exist?("d7"))                 # => false
Dir.mkdir("d7")
p(Dir.unlink("d7"))                 # => 0
```

```ruby error
Dir.mkdir("d7b")
File.write("d7b/a", "")
Dir.rmdir("d7b")                    # !> IOError: Dir.rmdir: Directory not empty
```

## pwd

`Dir.pwd()`

現在のディレクトリの絶対パス。Sake に `Dir.chdir` は無いので、プログラムの間変わりません。

```ruby
p(File.absolute_path?(Dir.pwd))     # => true
p(Dir.pwd == File.expand_path("."))   # => true
```

## home

`Dir.home([String])`

ホームディレクトリの絶対パス。引数にユーザー名を与えるとそのユーザーのホームです。知らないユーザーは `ArgumentError`。

```ruby
p(Dir.home == ENV.fetch("HOME"))    # => true
p(File.expand_path("~") == Dir.home)   # => true
```

```ruby error
Dir.home("no_such_user_xyz")        # !> ArgumentError: Dir.home: user no_such_user_xyz doesn't exist
```

## tmpdir

`Dir.tmpdir()`

一時ファイル用のディレクトリ（`$TMPDIR` か `/tmp`）の絶対パス。

```ruby
p(Dir.exist?(Dir.tmpdir))           # => true
p(File.absolute_path?(Dir.tmpdir))  # => true
```

## mktmpdir

`Dir.mktmpdir([String], [String]) [{ }]`

新しい一時ディレクトリを作ります。第 1 引数は名前の接頭辞（省略時 `"d"`）、第 2 引数は作る場所（省略時 `Dir.tmpdir`）。ブロック無しならそのパス（String）を返し、消すのは呼ぶ側の仕事です（`Dir.rmdir` は空のときだけ）。ブロックを付けるとパスをブロックに渡し、ブロックの後にディレクトリを**中身ごと**消して、ブロックの値を返します（Ruby の `tmpdir` と同じ）。場所が無ければ `IOError`。

```ruby
t = Dir.mktmpdir("pfx", ".")
p(String.start_with?(File.basename(t), "pfx"))   # => true
p(Dir.exist?(t))                    # => true
Dir.rmdir(t)
kept = ""
v = Dir.mktmpdir { |dir| File.write(File.join(dir, "f"), "1"); kept = dir; 42 }
p(v)                                # => 42
p(Dir.exist?(kept))                 # => false
```
