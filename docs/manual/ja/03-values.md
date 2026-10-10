# 値と型

Sake の値は Ruby の値とほぼ同じ顔をしていますが、どの値も 1 つの型タグを持ち、すべての操作がそれを検査します。この章は、どんな型があり、それぞれをどう書くかを述べます。Ruby と字面が同じで意味が違うのは `[a, b]`（Tuple）、`{x: 1}`（Record）、`{}` と `{k => v}`（静的エラー）です。

| 型 | 書き方（リテラル、または値を作る操作） | 備考 |
|---|---|---|
| Integer | `42`, `-7` | 多倍長 |
| Float | `1.5`, `2.0` | |
| String | `"abc"`, `'abc'`, `"a#{x}"` | 補間は `to_s` を使う（下記「値の表示」） |
| true / false | `true`, `false` | 内部では 1 つの型 `Boolean`。ソースには書けない |
| nil | `nil` | 「nil」の節を参照 |
| Tuple | `[a, b, ...]` | 長さと位置ごとの型が作成時に固定 |
| Record | `{x: a, y: b}` | (フィールド, 型) の集合が作成時に固定 |
| Array | `Array[a, ...]` | 要素型の宣言なし |
| T の Array | `T[a, ...]`、例 `Float[]`, `Point[p]` | 要素型 T。書き込みごとに検査 |
| Hash | `Hash["a" => 1, b: 2]`, `Hash.new(0)` | キーは値と型で比較（Ruby の `eql?`） |
| Set | `Set[1, 2]` | 要素は値と型で比較（Ruby の `eql?`） |
| Symbol | `:name` | |
| Range | `1..5`, `1...5`, `1..` | 端は Integer, Float, String, nil |
| Regexp, MatchData | `/(\d+)-(\d+)/`, `/#{x}/`, `String.match(s, re)` | |
| Rational, Complex | `2r`, `1/3r`, `Rational(1, 3)`, `2i`, `Complex(1, 2)` | Ruby の数値の塔 |
| Time | `Time.now`, `Time.at(0)`, `Time.new(2026, 10, 1)` | |
| IO | `IO.stdout`, `File.open(path)` | ファイルとストリームの 1 つの型 |
| Thread, Mutex, Queue, TCPServer, Socket | `Thread.new { }`, `Mutex.new`, ... | 並行とネットワーク |
| クラス | `Point.new(x, y)` | 可変なフィールドを持つレコード（[クラス](07-classes.md)） |

- **真偽。** 偽は `nil` と `false` だけです。`0` や `""` を含む他のすべての値は真です。
- **エラーメッセージ。** `nil`、`true`、`false` は値として示され（`got nil`）、他の値は型名で示されます（`got Integer`）。

```ruby
p(0 ? "yes" : "no")            # => "yes"
p("" ? "yes" : "no")           # => "yes"
p(nil ? "yes" : "no")          # => "no"
p(false ? "yes" : "no")        # => "no"
```

## 値の表示

どの値も 2 つの形で表示できます。`to_s` は人に読ませる形、`inspect` はプログラマに値の種類まで見せる形で、使い分けは Ruby と同じです。

| 形 | 使う場所 | 組み込みの形 |
|---|---|---|
| `to_s` | `puts`, `print`, `"#{x}"`, `Array.join`, `format` の `%s`, `:"#{x}"`, `/#{x}/` | Ruby の `to_s` と同じ。`nil` は空、Array と Tuple は `inspect` |
| `inspect` | `p`、`Kernel.inspect`、`format` の `%p`、および Array・Tuple・Hash・Record の中の要素 | Ruby の `inspect` と同じ。`#<struct Point x=1, y=2>` |

```ruby
Point = Struct.new(:x, :y)
puts("a")                      # => a
p("a")                         # => "a"
puts("#{nil}|")                # => |
puts("#{[1, "a"]}")            # => [1, "a"]
puts(format("%s %p", "a", "a"))  # => a "a"
p(Point.new(1, 2))             # => #<struct Point x=1, y=2>
```

### 自分の形

クラスはその本体に自分の `to_s` と `inspect` を定義できます。必須の引数は値 1 つで、String を返さなければなりません。既定値付きの引数は続けられます（`to_s(n, base = 10)`）。

```ruby
class Point
  attr_accessor x, y
  def to_s(p) = "(#{@x}, #{@y})"
  def inspect(p) = "Point(#{@x}, #{@y})"
end
pt = Point.new(1, 2)
puts(pt)                       # => (1, 2)
puts("at #{pt}")               # => at (1, 2)
p(pt)                          # => Point(1, 2)
p([pt])                        # => [Point(1, 2)]
```

String でない結果は、実行前に `type` の問題として報告されます。実行時に届けば `TypeError` です。

```ruby error
class Point
  attr_accessor x, y
  def to_s(p) = @x
end
puts(Point.new(1, 2))          # !> Point.to_s must return a String, but returns Integer [type]
```

- **どれが走るか。** 型の集合は閉じているので、値の型が分かればどの `to_s` が走るかも分かります。

## Tuple、Record、Array

リテラル `[...]` と `{...}` には型を付けた操作が無いので、その**形**が作成時に型を決めます。`[a, b]` は Tuple、`{x: a, y: b}` は Record です。伸びる容器は、型を付けた操作（`Array[...]`、`T[...]`、`Hash[...]`）で作ります。

### リテラルの性質

- **中身は可変。** リテラルの中身は同じ型の値で置き換えられ、各書き込みが検査されます。Tuple は `t[i] = v` で書きます。Record に書く構文はまだありません。
- **長さは固定。** 長さは型の一部なので、空の `[]` は伸びません。
- **nil。** `nil` で作った位置の型は nil で、後から他の値を入れられません。後で値を入れる場所には、`0` や `""` のような意図した型の仮の値を置きます。

```ruby error
xs = []
Array.push(xs, 1)              # !> `[...]` is a Tuple with a fixed length; for a growable Array, write `Array[...]`
```

```ruby error
t = [1, nil]
t[1] = 2                       # !> Indexable.[]=: the value must be Nil, but is Integer [type]
```

### Tuple

リテラル `[a, b, ...]` は Tuple です。要素は多重代入 `x, y = t` か添字 `t[0]` で読みます。

```ruby
t = [1, "a"]
x, y = t
p(x)                           # => 1
p(y)                           # => "a"
t[0] = 2
p(t)                           # => [2, "a"]
p(Tuple.size(t))               # => 2
p(Tuple.max([3, 9, 4]))        # => 9
```

- **多重代入。** `x, y = t` は Tuple を分解します。Array も分解します（`key, value = String.split(s, "=")`）。Ruby と同じく、足りない要素は nil、余った要素は捨てられます。
- **足りないかもしれない要素。** それを受ける変数は `x[k]` と同じ `nil | T` の型です（`index-nil` 項目、レベル 3）。
- **代入先。** 要素とフィールドも書けます。`a[i], a[j] = a[j], a[i]` は交換、`@done, @rest = Array.partition(xs) { ... }` はフィールドへの代入です。レシーバと添字を先に、右辺をその後に評価します。
- **残りを受ける。** `first, *rest = xs` は残りを新しい Array に入れます。`a, *mid, z = xs` も同じで、`x, * = xs` は残りを捨てます。rest を受けられるのはローカル変数だけです。
- **`[...]` の中のスプラット。** Tuple の長さは既知でなければならないので、`[*xs, 1]` は拒否されます。`Array[*xs, 1]` は Array を作ります。
- **添字。** `t[0]` は位置を読み、`t[0] = v` は同じ型の値で置き換えます。
- **操作。** `Tuple.size` と `Tuple.length` が要素数です。`Tuple.max([a, b])` は Ruby の `[a, b].max` です。長さが分かるので nil にはなりません。

```ruby
first, *rest = Array[1, 2, 3]
p(first)                       # => 1
p(rest)                        # => [2, 3]
key, value = String.split("a=1", "=")
p(value)                       # => "1"
a = Array[1, 2]
a[0], a[1] = a[1], a[0]
p(a)                           # => [2, 1]
```

### Record

リテラル `{x: a, y: b}` は Record です。フィールド名で読む、小さな固定の値の組です。

- **型。** Record の型は (フィールド, 型) の集合、例えば `{x: Integer, y: Integer}` です。同じ集合の Record は同じ型です。
- **順序。** 順序は関係ありません。`{y: 2, x: 1}` は `{x: 1, y: 2}` と印字され、両者は `==` です。
- **クラスの値ではない。** フィールドが一致しても Record はクラスの値ではありません。クラスは名前で、Record 型は構造で決まります。
- **フィールドの読み出し。** パターンで分解します: `r => {x:, y: name}`。ローカル `x` にフィールド `x`、ローカル `name` にフィールド `y` が束縛されます。一部のフィールドだけ書いてもよい。`Record.to_h(r)`、`Record.keys(r)`、`Record.values(r)` もあります。
- **無いフィールド。** 実行前に `type` で報告されます。実行時に届けば、無いフィールドは `KeyError`、Record でない値は `TypeError` です。
- **制限。** フィールド名はラベル（`x:`）で書きます。空の `{}` と `{key => value}` は静的エラーです（Hash は `Hash[...]`）。

```ruby
Point = Struct.new(:x, :y)
r = {y: 2, x: 1}
p(r)                           # => {x: 1, y: 2}
p(r == {x: 1, y: 2})           # => true
p(r == Point.new(1, 2))        # => false
r => {x:, y: name}
p(x)                           # => 1
p(name)                        # => 2
p(Record.keys(r))              # => [:x, :y]
```

```ruby error
r = {x: 1}
r => {z:}                      # !> the pattern needs field `z`, but the value is {x: Integer} [type]
```

```ruby error
h = {"a" => 1}                 # !> `{"a" => ...}` is not a Hash in Sake: `{name: value}` makes a Record
```

### Array

`Array[a, ...]` は要素型を宣言しない Array を作ります。どの値も入ります。Array は可変で、参照で共有されます。

### T の Array

`T[a, ...]` は要素型 T の Array を作ります。T は組み込み型（`Integer`, `Float`, `Rational`, `Complex`, `String`, `Symbol`, `Tuple`）かクラスです。

- **書き込みの検査。** 作成、`Array.push`、`Array.append`、`Array.concat` のすべての書き込みが検査され、合わなければ `TypeError`。暗黙の変換は無く、Integer は `Float[]` に入りません。
- **静的検査。** `T[...]` のリテラル引数が別の型なら実行前に報告されます。Ruby 流に書いた `Point[1, 2]`（`Point.new(1, 2)` のつもり）がここで捕まります。
- **型無しの結果。** `map`、`select`、`sort` などが返す Array は要素型を宣言しません。

```ruby error
fs = Float[1.5]
Array.push(fs, 2.5)
Array.push(fs, 3)              # !> Array.push: an element must be Float, but is Integer [type]
```

```ruby error
Point = Struct.new(:x, :y)
pt = Point[1, 2]               # !> Point.new(1, 2) creates one Point; Point[...] is an Array of Point
```

```ruby
Point = Struct.new(:x, :y)
pts = Point[Point.new(1, 2), Point.new(3, 4)]
xs = Array.map(pts) { |pt| Point.x(pt) }
Array.push(xs, "s")
p(xs)                          # => [1, 3, "s"]
```

### Ruby の癖

- **Array が要るところの `[]`。** Array が要るところに Tuple や Record を渡す（`result = []` の後の `Array.push(result, x)`）と、`Array[]` と書く hint 付きで失敗します（上の例）。
- **要素型を変える in-place 操作。** 検査器は容器にプログラム全体で 1 つの要素型を与えます。そのため `Array.map!(xs) { |x| Integer.to_s(x) }` や `Hash.transform_keys!(h) { ... }` の後は、容器が古い型と新しい型の両方を持つとみなし、片方にしか合わない操作を `type`（部分的）として報告します。in-place の形は 1 つの型の中の写像に使い、型を変えるときは `Array.map` / `Hash.transform_keys`（新しい容器）を使ってください。

```ruby error
xs = Array[1, 2]
Array.map!(xs) { |x| Integer.to_s(x) }
p(Array.sum(xs))               # !> Array.sum: an element must be Integer|Float|Rational|Complex, but can be String [type]
```

## Hash と Set

Hash と Set は、キーや要素を値で探す伸びる容器です。リテラル `{...}` は Record なので、どちらも型を付けた操作で作ります。

### 構築

`Hash[k => v, ...]`、`Hash[]`、`Hash.new(default)` が Hash を、`Set[x, ...]` が Set を作ります。`Hash[name: v]` と書くとキーは Symbol です。

```ruby
h = Hash["a" => 1, b: 2]
p(h)                           # => {"a" => 1, b: 2}
counts = Hash.new(0)
Array.each(String.split("the cat the", " ")) { |w| counts[w] += 1 }
p(counts)                      # => {"the" => 2, "cat" => 1}
Hash.each(counts) { |k, v| puts("#{k}: #{v}") }   # => the: 2
                                                  # => cat: 1
```

### キーと要素の比較

Hash のキーと Set の要素は Ruby の `eql?` と同じく、値と型で比較します。`1` と `1.0` は別のキーですが、`1 == 1.0` は true です。

```ruby
p(Hash[1 => "a"][1.0])         # => nil
p(Set[1, 1.0])                 # => Set[1, 1.0]
p(1 == 1.0)                    # => true
```

- **使えるもの。** Integer, Float, String, Symbol, true, false, nil, Time、およびそれらからなる Tuple, Record, Array, Hash, Set、クラスの値。
- **使えないもの（`TypeError`）。** Regexp、Range、自分の等価（`==`、または `Comparable` の `<=>`）を定義したクラスの値。キーの比較がその等価と食い違いうるからです。
- **キーの変更。** Ruby と同じく、キーに使った Array・Hash・Set・クラスの値を後で変えると見つからなくなります。
- **キーは複製される。** Tuple や Record のキーは格納時に複製されるので、元を後で書いてもキーは変わりません。

```ruby error
h = Hash[/a/ => 1]             # !> Regexp cannot be a Hash key or Set element
```

```ruby
k = [1, 2]
h = Hash[k => "a"]
k[0] = 9
p(Hash.keys(h))                # => [[1, 2]]
```

### 既定値

`Hash.new(default)` は無いキーに `default` を返し、Ruby と同じく同じオブジェクトを共有します。ブロックの形 `Hash.new { ... }` はありません（ブロックは値ではない）。

```ruby
h = Hash.new(Array[])
Array.push(h[:a], 1)
p(h[:b])                       # => [1]
```

```ruby error
h = Hash.new { |hh, k| 0 }     # !> Hash.new does not take a block
```

### ブロックと順序

- **ブロック。** Hash のブロックは `[key, value]` を 1 つの Tuple として受けるので、`|k, v|` で分解します（上の `Hash.each` の例）。
- **順序。** 反復は挿入順です。

## nil

`nil` は普通の値です。無いかもしれない値の型は `nil | T` で、Option のような包みはありません。nil を受け取れない操作に渡す前に、検査で型から nil を取り除きます。

### 実行時

T が要る操作が `nil` を受けると `TypeError ... got nil` を投げます。インタプリタはそのエラーの経路でだけ静的解析を走らせ、nil を持ちうるフィールドと nil を格納する行を hint に加えます。

```ruby error
h = Hash["a" => "x"]
puts(String.upcase(h["b"]))    # !> TypeError: String.upcase: argument 1 must be String, got nil
```

### 絞り込み

静的解析は**ローカル変数**を次の場所で絞ります。

| 形 | `x` が絞られる場所 |
|---|---|
| `if x` / `while x` / `x && …` | `x` が真のときに取る分岐で非 nil |
| `x != nil` / `x == nil` | 対応する分岐で nil または非 nil |
| `!x` / `unless x` | 同じ、分岐を入れ替えて（`if !x … else` の else で非 nil） |
| `return unless x`、`next unless x`、`break unless x` などの早期脱出 | 文の後で非 nil |
| `String.size(x)` など、`x` を引数に取る組み込みの操作 | 呼び出しの後、その操作が受け付ける型（実行時に引数を検査するから） |
| `x in T` / `x => T` / `case x in T` | 一致する型（[制御構造とパターン](06-control.md)） |

```ruby
def find_even(xs) = Array.find(xs) { |x| x % 2 == 0 }
x = find_even(Array[1, 4])
if x
  p(x + 1)                     # => 5
end
p(x + 1) if x != nil           # => 5
def twice(xs)
  x = find_even(xs)
  return 0 unless x
  x * 2
end
p(twice(Array[1, 4]))          # => 8
p(twice(Array[1, 3]))          # => 0
```

フィールドの読み出し（`Node.next(n)`）は絞られ**ません**。フィールドは可変だからです。

```ruby error
class Node
  attr_accessor value, :next
end
def mk(v) = Node.new(v, nil)
a = mk(1)
Node.set_next(a, mk(2))
if Node.next(a)
  p(Node.value(Node.next(a)))  # !> Node.value: argument 1 may be nil (nil | Node) [nil]
end
```

フィールドをローカル変数に写してから検査してください。

```ruby
class Node
  attr_accessor value, :next
end
def mk(v) = Node.new(v, nil)
a = mk(1)
Node.set_next(a, mk(2))
nx = Node.next(a)
if nx
  p(Node.value(nx))            # => 2
end
```

### `--strict`

レベル 2 は、検査されていない `nil` を受けうるすべての操作を実行前に報告します。レベル 3 は `x[k]` の結果も対象にします（[概要と実行](01-overview.md)）。

## Ruby の他の型

Ruby の他の型は、Ruby と同じ値を同じ字面で作ります。違いは、操作を型付きで呼ぶことと、グローバル変数（`$1`、`$stdout`）が無いことです。

### Range

反復する操作には Integer か String で始まる Range が要ります。`"A".."Z"` は Ruby と同じく `String#succ` で進みます。`step`、`sum`、`size` は Integer が要ります。別の型の Range（`1.0..2.0`）は `type` で報告されます。

```ruby
p(Range.to_a("a".."e"))        # => ["a", "b", "c", "d", "e"]
p(Range.sum(1..4))             # => 10
p((1..3) == (1..3))            # => true
p(/a/i == /a/i)                # => true
```

```ruby error
Range.each(1.0..2.0) { |x| p(x) }   # !> Range.each: the Range's first value must be Integer|String, but is Float [type]
```

- **等価。** 2 つの Range は端と `exclude_end?` が同じなら `==`、2 つの Regexp はソースとオプションが同じなら `==` です。
- **終端の無い Range。** 有限の Range が要る操作は、終端の無い Range に `RangeError` を投げます。

```ruby error
p(Range.to_a(1..))             # !> RangeError: Range.to_a: cannot do this on an endless Range 1..
```

### Regexp と MatchData

`$1` や `$~` のようなグローバルはありません。MatchData を変数に置いて添字で読みます（`m[1]`）。`String.match` は一致しないと nil を返すので、先に検査します。`String.sub`、`gsub`、`index`、`split` は Regexp も取ります。`/.../n` は Ruby と同じくバイト列の正規表現です。

```ruby
m = String.match("2026-10", /(\d+)-(\d+)/)
if m
  p(m[1])                      # => "2026"
  p(m[2])                      # => "10"
end
p(String.sub("a-b", /-/, "+")) # => "a+b"
p(String.scan("a1b22", /\d+/)) # => ["1", "22"]
```

```ruby error
m = String.match("a1", /(\d)/)
puts($1)                       # !> Sake has no global variables (`$1`)
```

### Time

ゾーンは Ruby と同じ固定の UTC オフセットです: `"+09:00"`、`"-0500"`、`"Z"`、`"UTC"`、軍用の 1 文字、秒数（`3600`）。`Time.new`、`Time.at`、`Time.now` はキーワード `in:` でも取ります。`Time.utc(t)` と `Time.localtime(t, zone)` は変換した複製を返します（Ruby の `utc` と `localtime` はレシーバを変える）。

```ruby
t = Time.new(2026, 10, 1, 9, 0, 0, in: "+09:00")
p(t)                           # => 2026-10-01 09:00:00 +0900
p(Time.utc(t))                 # => 2026-10-01 00:00:00 UTC
p(t)                           # => 2026-10-01 09:00:00 +0900
p(Time.at(0, in: 3600))        # => 1970-01-01 01:00:00 +0100
```

### IO

`IO.stdin`、`IO.stdout`、`IO.stderr` がプログラムのストリームを型 `IO` の値として与えます。Sake に `$stdout` や `STDOUT` は無く、`ARGV` と同じく値は操作から来ます。`File.open(path, mode = "r")` も `IO` を返し、ブロック付きならブロックの値を返してファイルを閉じます。

- **1 つの型。** ファイルとストリームの型は 1 つなので、1 つの関数がどちらにも書けます。
- **パターンと等価。** `IO` はパターンに書け（`in IO`）、同じストリームやファイルの 2 つの IO 値は `==` です。

```ruby
def say(io, s) = IO.puts(io, s)
say(IO.stdout, "to stdout")    # => to stdout
File.open("out.txt", "w") { |f| say(f, "to a file") }
p(File.read("out.txt"))        # => "to a file\n"
p(IO.stdout == IO.stdout)      # => true
```

### エンコーディング

互換でないエンコーディングの文字列が出会うと（`Integer.chr(227)` のバイトと UTF-8 の文章）、rescue できる `EncodingError` が上がります。

```ruby
begin
  s = Integer.chr(227) + "あ"
rescue EncodingError => e
  puts("rescued")              # => rescued
end
```
