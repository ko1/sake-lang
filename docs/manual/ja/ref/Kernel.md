# Kernel

Kernel はプログラム全体から名前だけで呼べる操作の集まりです。`puts(x)`、`Integer(s)`、`loop { }` のように書き、`Kernel.puts(x)` と書く必要はありません（書いても動きます。名前の解決は、今の名前空間、トップレベルの関数、Kernel の順です。[関数](../04-functions.md)）。他の名前空間の操作と同じく、引数の型は静的に検査され、合わない型は `type` の問題です。

ここにあるのは入出力（`puts`、`print`、`p`、`pp`、`format`、`gets`、`warn`）、厳密な数値変換（`Integer`、`Float`、`Rational`、`Complex`）、値の表示（`to_s`、`inspect`）と複製（`dup`、`equal?`）、制御（`loop`、`block_given?`、`once`）、乱数と時間（`rand`、`srand`、`sleep`）、プロセス（`exit`、`at_exit`、`system`、`ARGV`、`PROGRAM_NAME`）です。`raise` は操作ではなく構文で、[例外とエラー](../08-exceptions.md)にあります。`Math.PI` や `Float.INFINITY` も操作として読みますが、それぞれの名前空間の章にあります（Sake に値の定数は無く、名前の付いた値は `once` で作ります）。

## puts

`Kernel.puts(*Any)`

各引数を 1 行ずつ出力に書き、nil を返します（Ruby の `puts`）。String はそのまま（末尾に改行が無ければ足す）、nil は空行、他の値は `to_s` の形です。Array と Tuple は要素を 1 行ずつ、入れ子も平らにして書きます（空の Array は空行）。引数が無ければ空行です。クラスのインスタンスは型自身の `to_s(x)` があればそれで、無ければ `p` と同じ `#<struct ...>` の形で書きます（[to_s](#to_s)）。

```ruby
puts("a", 1, :sym)
# => a
# => 1
# => sym
puts(Array[1, [2, 3]])
# => 1
# => 2
# => 3
puts(Hash["k" => 1], 1..3)
# => {"k" => 1}
# => 1..3
```

## print

`Kernel.print(*Any)`

各引数を `to_s` の形で改行を挟まずに書き、nil を返します（Ruby の `print`）。Array と Tuple は `[1, 2]` の形（`puts` のように 1 行ずつにはなりません）、nil は空文字列です。

```ruby
print("a", 1, nil, "\n")        # => a1
print(Array[1, 2], [3, 4], "\n") # => [1, 2][3, 4]
```

## p

`Kernel.p(*Any)`

各引数を `inspect` の形で 1 行ずつ書きます（Ruby の `p`）。String は引用符付き、Symbol は `:sym`、クラスのインスタンスは `#<struct Point x=1, y=2>`、例外値は `#<KeyError: msg>` です。戻り値は Ruby と同じく、引数が 1 つならその値、複数なら引数の Tuple、無ければ nil（検査器もそう見ます）。型自身の `inspect(x)` を持つ クラスのインスタンスはそれで書きます。

```ruby
x = p(1, "a")
# => 1
# => "a"
p(x)                             # => [1, "a"]
p(p())                           # => nil
Point = Struct.new(:x, :y)
p(Point.new(1, 2))               # => #<struct Point x=1, y=2>
p(Hash["a" => 1], Set[1], 2r)
# => {"a" => 1}
# => Set[1]
# => (2/1)
```

## pp

`Kernel.pp(Any)`

1 つの値を `p` と同じ形で書き、その値を返します。Ruby の `pp` は長い値を折り返しますが、Sake では `p(x)` と同じです。

```ruby
a = pp(Array[1, {k: 2}])        # => [1, {k: 2}]
p(a)                             # => [1, {k: 2}]
```

## format, sprintf

`Kernel.format(String, *Any)`

`Kernel.sprintf(String, *Any)`

Ruby の `format` と同じ書式で String を作ります: `%d`、`%f`、`%e`、`%g`、`%x`、`%o`、`%b`、`%c`、`%s`、`%p`、`%%` と、幅・精度・`-`・`+`・`0` のフラグ。`%s` は値の `to_s`（クラス自身の `to_s(x)` も使われます）、`%p` は `inspect` です。`%<name>d` と `%{name}` は、Record（`{a: 1}`）か Symbol をキーに持つ Hash（`Hash[a: 1]`）を唯一の引数として 1 つ渡します。演算子の形 `fmt % x` も同じです（[String](String.md)）。引数が足りない・多すぎる、数値の指示子に数にならない値を渡す、無いキーを名乗る（`key<a> not found`）、はすべて `ArgumentError` です。

```ruby
p(format("%05.2f|%-4s|%p|%x", 3.14159, :ab, "q", 255))   # => "03.14|ab  |\"q\"|ff"
p(sprintf("%+d %s %s", 3, nil, true))                     # => "+3  true"
p(format("%<a>d-%<b>s", {a: 1, b: "x"}))                  # => "1-x"
p("%<a>05d" % {a: 42})                                    # => "00042"
p(format("%<n>d-%{s}", Hash[n: 1, s: "x"]))               # => "1-x"
Point = Struct.new(:x, :y)
p(format("%s", Point.new(1, 2)))                          # => "#<struct Point x=1, y=2>"
```

```ruby error
p(format("%d %d", 1))            # !> ArgumentError: Kernel.format: too few arguments
```

```ruby error
p(format("%<a>d", {b: 1}))       # !> ArgumentError: Kernel.format: key<a> not found
```

## gets

`Kernel.gets()`

標準入力から 1 行を読み、末尾の改行を含めた String を返します。入力の終わりでは nil です。戻り値は `String | nil` なので、検査せずに `String.chomp(gets)` と書くと `--strict`（レベル 2）が `nil` の問題として止めます。`if (line = gets)` のように先に調べます。Ruby の `gets` と違い引数（区切り）は取りません。

```ruby
line = gets
p(line)                          # => "3\n"
if (rest = gets)
  p(String.split(String.chomp(rest), " "))   # => ["1", "2"]
end
p(gets)                          # => nil
```

```ruby error
p(String.chomp(gets))            # !> argument 1 may be nil
```

## warn

`Kernel.warn(*Any)`

各引数を `puts` と同じ形でエラー出力（stderr）に書き、nil を返します。引数が無ければ何も書きません。使い方の誤りを報告して `exit` する、という組み合わせが典型です。

```ruby error
warn("usage: prog FILE")         # !> usage: prog FILE
exit(2)
```

## Integer

`Kernel.Integer(String|Integer|Float)`

Ruby の厳密な `Integer()` です。String は 10 進の整数、または `0x`・`0b`・`0o`・`0` 接頭辞付きの整数で、`_` の区切りと前後の空白は許されます。それ以外（`"12abc"`、`""`、`"1e3"`）は `ArgumentError`。Float は切り捨て、Integer はそのままです。`String.to_i` は読めるところまでを黙って読みますが、こちらは全体が整数でなければ失敗します。NaN や Infinity の Float は `FloatDomainError` で（メッセージは値の名前 `NaN`・`Infinity`）、他の例外と同じく rescue できます。

```ruby
p(Integer("42"))                 # => 42
p(Integer(" 0x1f "))             # => 31
p(Integer("1_000"))              # => 1000
p(Integer(3.9))                  # => 3
p(String.to_i("12abc"))          # => 12
```

```ruby error
p(Integer("12abc"))              # !> ArgumentError: Kernel.Integer: invalid value for Integer(): "12abc"
```

```ruby error
p(Integer(Float.NAN))            # !> FloatDomainError: Kernel.Integer: NaN
```

## Float

`Kernel.Float(String|Integer|Float)`

Ruby の厳密な `Float()` です。String は 10 進の実数（`"1e3"`、`"1_0.5"`、前後の空白可）でなければ `ArgumentError`。Integer は Float に、Float はそのままです。

```ruby
p(Float("1.5"))                  # => 1.5
p(Float("1e3"))                  # => 1000.0
p(Float(2))                      # => 2.0
```

```ruby error
p(Float("abc"))                  # !> ArgumentError: Kernel.Float: invalid value for Float(): "abc"
```

## Rational

`Kernel.Rational(Integer|Float|Rational|String, [Integer|Rational])`

Ruby の `Rational(a, b = 1)` です。`a` は Integer、Float、Rational、または `"1/3"`・`"0.75"`・`"3"` の形の String、`b` は Integer か Rational で、`a / b` を既約の Rational にします。Float は `Float.to_r` と同じく正確な値として読むので、`Rational(0.5)` は `(1/2)` ですが、`Rational(0.1)` は `0.1` が実際に表す長い 2 進の分数です（短い `(1/10)` が欲しければ `Float.rationalize`）。読めない String は `ArgumentError`、`b` が 0 なら `ZeroDivisionError`、NaN や Infinity の Float は `FloatDomainError`。

```ruby
p(Rational(3, 6))                # => (1/2)
p(Rational("0.75"))              # => (3/4)
p(Rational("1/3"))               # => (1/3)
p(Rational(1r/2, 1r/4))          # => (2/1)
p(Rational(0.5))                 # => (1/2)
p(Rational(1.5, 1r/2))           # => (3/1)
p(Rational(0.1) == Float.to_r(0.1))   # => true
p(Float.rationalize(0.1))        # => (1/10)
```

```ruby error
p(Rational(1, 0))                # !> ZeroDivisionError: Kernel.Rational: divided by 0
```

## Complex

`Kernel.Complex(Integer|Float|Rational, [Integer|Float|Rational])`

Ruby の `Complex(re, im = 0)` です。実部と虚部はそれぞれ実数で、String は受け付けません（`String.to_c` を使います）。

```ruby
p(Complex(1, 2))                 # => (1+2i)
p(Complex(1.5))                  # => (1.5+0i)
p(Complex(1r, 2.5))              # => ((1/1)+2.5i)
```

## to_s

`Kernel.to_s(Any)`

値を `puts`・文字列補間 `"#{x}"`・`format` の `%s` が使う形の String にします。String はそのまま、nil は `""`、Symbol は名前、数は Ruby の `to_s`、Array・Tuple・Hash・Set・Record・Range は `inspect` と同じ形です。クラスのインスタンスは、その型が `to_s(x)` を定義していればそれを呼び（`include` したモジュールのものでも）、無ければ `#<struct T ...>` です。Ruby の `x.to_s` に相当しますが、Sake では値へのメソッド呼び出しが無いので、どの型の値もこの 1 つの操作で文字列にします。

```ruby
class Temp
  attr_reader celsius
  def to_s(t) = "#{@celsius}C"
end
t = Temp.new(21)
p(to_s(t))                       # => "21C"
puts("now #{t}")                 # => now 21C
p(to_s(nil))                     # => ""
p(to_s(Array[1, "a"]))           # => "[1, \"a\"]"
p(to_s(:sym))                    # => "sym"
```

## inspect

`Kernel.inspect(Any)`

値を `p` が書く形の String にします（Ruby の `x.inspect`）: String は引用符とエスケープ付き、Symbol は `:sym`、nil は `"nil"`、容器は要素を `inspect` した形です。クラスのインスタンスは、その型が `inspect(x)` を定義していればそれ（`include` したモジュールのものでも）、無ければ `#<struct T f=v, ...>`、例外値は `#<E: message>` です。`p`、`pp`、`format` の `%p`、容器の中の要素の表示がこれを使います。

```ruby
module Pretty
  def inspect(v) = "<pretty>"
end
class Box
  include Pretty
  attr_reader n
end
p(inspect("a\n"))                # => "\"a\\n\""
p(inspect(nil))                  # => "nil"
p(inspect(Box.new(1)))           # => "<pretty>"
p(Array[Box.new(1)])             # => [<pretty>]
```

## dup

`Kernel.dup(Any)`

値の浅い複製（Ruby の `obj.dup`）: Array、Tuple、Hash、Set、Record、クラスのインスタンス、String は新しい容器になり、中の要素は同じ値のままです（要素の容器は共有されます）。Integer、Symbol、nil、true/false、Range はそのままの値が返ります。型は元と同じです。その型が `dup(x)` を定義している クラスのインスタンスには、それを呼びます（戻り値はその関数の型）。型の関数の中で要素を複製するときは `Kernel.dup(@items)` と書きます。裸の `dup` は型自身の `dup` に解決されるからです。

```ruby
a = Array[Array[1], Array[2]]
b = dup(a)
Array.push(b, Array[3])
Array.push(b[0], 9)
p(a)                             # => [[1, 9], [2]]
p(b)                             # => [[1, 9], [2], [3]]
class Box
  attr_accessor items
  def dup(b) = Box.new(Kernel.dup(@items))
end
x = Box.new(Array[1])
y = dup(x)
Array.push(Box.items(y), 2)
p(Box.items(x))                  # => [1]
p(Box.items(y))                  # => [1, 2]
```

## equal?

`Kernel.equal?(Any, Any)`

2 つの引数が同じ値（同一のオブジェクト）なら true（Ruby の `a.equal?(b)`）。`==` は中身を比べますが、こちらは同一性です。`dup` の結果は元と `==` ですが `equal?` ではありません。同じ Integer、Symbol、nil、true/false は常に同一です。別々に書いた String リテラルは同一ではありません。

```ruby
a = Array[1]
b = a
p(equal?(a, b))                  # => true
p(a == dup(a))                   # => true
p(equal?(a, dup(a)))             # => false
p(equal?("a", "a"))              # => false
p(equal?(:a, :a))                # => true
```

## loop

`Kernel.loop() { }`

ブロックを `break` まで繰り返します（Ruby の `loop`）。戻り値は `break v` の `v`（裸の `break` は nil）で、検査器にはブロック内のすべての `break` の値の和が見えます。`next` は次の回へ進みます。`break` の無い `loop` は決して返りません（Ruby の `StopIteration` による終了は Sake にはありません）。

```ruby
i = 0
v = loop do
  i += 1
  next if i < 3
  break i * 10
end
p(v)                             # => 30
p(loop { break })                # => nil
```

## block_given?

`Kernel.block_given?()`

今の関数がブロック付きで呼ばれたなら true。`block_given?` を調べる関数は、ブロック無しでも呼べます（調べない関数で `yield` すれば、ブロックは必須です。[関数](../04-functions.md)）。検査器は条件の中の `block_given?` をその呼び出しごとの値に畳むので、ブロック無しの呼び出しで `yield` に届く枝は走りません。トップレベルでは false です。

```ruby
def each_or(x)
  return yield(x) if block_given?
  x
end
p(each_or(1))                    # => 1
p(each_or(1) { |v| v + 10 })     # => 11
p(block_given?)                  # => false
```

## once

`Kernel.once() { }`

ブロックの値を返します。ブロックはプログラム中のその場所が最初に実行されたとき 1 度だけ走り、値はプログラムの終わりまで保たれて、以後の実行（別の呼び出し、別のスレッド）はその同じ値を受け取ります。Sake には値の定数が無いので、表や名前付きの値を 1 度だけ計算する手段です: `def table = once { ... }`。保たれるのは値そのもので、Array なら後から変えられます（Ruby の定数と同じ）。計算中のブロックが自分の `once` にまた届くと `SystemStackError` でプログラムが止まります（rescue できません）。

```ruby
def table = once { puts("computing"); Array[1, 2, 3] }
p(table)
# => computing
# => [1, 2, 3]
p(table)                         # => [1, 2, 3]
p(equal?(table, table))          # => true
```

```ruby error
def rec(n) = once { rec(n) }
rec(1)                           # !> SystemStackError: once: the block reached its own once again while computing it
```

## rand

`Kernel.rand([Integer|Float])`

Ruby の `rand` ですが、引数は厳密です。引数が無ければ 0.0 以上 1.0 未満の Float。Integer `n` なら 0 以上 `n` 未満の Integer。Float `x` なら 0.0 以上 `x` 未満の Float。上限は正でなければならず、0・0.0・負の数は `ArgumentError`（`invalid argument - 0`）です（Ruby は `|n|` を使い、0 なら Float を返します）。Range は受け付けません（静的に `type` の問題）。

```ruby
f = rand
p(f >= 0.0 && f < 1.0)           # => true
i = rand(6)
p(i >= 0 && i < 6)               # => true
g = rand(2.5)
p(g >= 0.0 && g < 2.5)           # => true
```

```ruby error
p(rand(0))                       # !> ArgumentError: Kernel.rand: invalid argument - 0
```

## srand

`Kernel.srand([Integer])`

乱数の種を設定し、前の種（Integer）を返します（Ruby の `srand`）。引数が無ければ新しい種を無作為に選びます。同じ種からの `rand` の列は同じです。

```ruby
srand(7)
a = Array.map(Array[1, 2, 3]) { rand(1000) }
srand(7)
b = Array.map(Array[1, 2, 3]) { rand(1000) }
p(a == b)                        # => true
p(srand(1))                      # => 7
```

## sleep

`Kernel.sleep([Integer|Float|Rational])`

指定した秒数だけ止まり、眠った秒数（Integer に丸めたもの、Ruby の `sleep`）を返します。引数が無ければ永久に止まります（他のスレッドに起こされるまで）。

```ruby
p(sleep(0))                      # => 0
p(sleep(1r/100))                 # => 0
```

## exit

`Kernel.exit([Integer|Boolean])`

プログラムを終了状態 `status` で終えます。Integer はそのまま、true は 0、false は 1、省略は 0。`rescue` では捕まえられず（`rescue => e` も通り抜けます）、途中の `ensure` 節と `at_exit` のブロックは走ります。検査器は `exit` の後のコードを到達しないものとして扱います（型 `[]`: 値を返しません）。

```ruby
at_exit { puts("at_exit") }
begin
  exit(true)
rescue => e
  puts("not caught")
ensure
  puts("ensure")                 # => ensure
end
puts("not reached")              # => at_exit
```

```ruby error
puts("start")                    # !> start
exit(3)
puts("not reached")
```

## at_exit

`Kernel.at_exit() { }`

ブロックを登録して nil を返します。登録したブロックはプログラムが終わるとき（普通に、`exit` で、または捕まえられなかった例外で）後に登録したものから順に走ります（Ruby の `at_exit`）。

```ruby
at_exit { puts("bye 1") }
at_exit { puts("bye 2") }
puts("main")
# => main
# => bye 2
# => bye 1
```

## system

`Kernel.system(String, *String)`

コマンドを子プロセスとして走らせ、終わるまで待ちます（Ruby の `system`）。引数が 1 つならシェルを通し、複数なら最初がコマンド、残りがその引数です。戻り値は、終了状態 0 なら true、0 以外なら false、起動できなければ nil（`Boolean | nil`）。子プロセスの出力はそのまま出力に出ます。出力を String として受け取るには `Open3.capture2`・`capture3` を使います。

```ruby
p(system("echo", "hi"))
# => hi
# => true
p(system("false"))               # => false
p(system("/no/such/command"))    # => nil
```

## ARGV

`Kernel.ARGV()`

プログラムのコマンドライン引数の Array（String の Array）。Ruby の定数のように `ARGV` と書きますが操作で、毎回同じ Array を返すので `Array.shift(ARGV)` や `OptionParser` の `parse!` で縮めると以後の `ARGV` にも反映されます。要素の String は凍結されていて、その場で変える操作（`String.concat` など）は `TypeError` です。

```ruby
p(ARGV)                          # => []
Array.push(ARGV, "x")
p(ARGV)                          # => ["x"]
p(equal?(ARGV, ARGV))            # => true
```

## PROGRAM_NAME

`Kernel.PROGRAM_NAME()`

実行中のプログラム（最初のファイル）のパス（Ruby の `$0`）。他の Kernel の操作と違い、裸の `PROGRAM_NAME` は型名として読まれて拒まれるので（`type PROGRAM_NAME cannot be used as a value`）、`Kernel.PROGRAM_NAME` と書きます。

```ruby
p(String.end_with?(Kernel.PROGRAM_NAME, ".sake"))   # => true
```
