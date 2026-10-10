# 演算子と添字

この章は `a + b` のような二項演算子と、`x[k]` の添字を述べます。どちらも module の関数の略記で、左のオペランド（レシーバ）の型で解決されます。自分のクラスに演算子や添字を与えるには、その module を include して関数を定義します。

## 二項演算子

各演算子は module に属し、`a OP b` はその module の関数を呼ぶ略記です: `a + b` は `Arithmetic.+(a, b)` です。module の関数は第 1 引数の型で解決されるので（[module の関数の呼び方](02-program.md)）、この呼び出しは `a` の型 `T` の `T.+(a, b)` を走らせます。つまり演算子は**左のオペランド**でディスパッチします。エラーの文は module の関数の名で出ます（`Arithmetic.*: ...`）。

```ruby
p(1 + 2)                  # => 3
p(Arithmetic.+(1, 2))     # => 3
p(Integer.+(1, 2))        # => 3
p("a" + "b")              # => "ab"
```

| module | 演算子 | include する組み込み型 |
|---|---|---|
| `Arithmetic` | `+ - * / % **`、単項 `-x` `+x`（`-@` `+@`） | Integer, Float, Rational, Complex, String, Time, Set |
| `Comparable` | `<=> < <= > >=` | Integer, Float, Rational, String, Time, Tuple, Array |
| `Bitwise` | `& \| ^ << >>`、単項 `~x` | Integer, Set |
| `Indexable` | `[]`, `[]=`（下記「添字」） | Array, Hash, String, Tuple, MatchData |
| `Kernel` | `== != =~ !~` | すべての型 |

### 明示の形

`Arithmetic.+(a, b)` は `a + b` と同じようにディスパッチします。`Integer.+(a, b)` は Integer の `+` を直接呼びます。`a` は Integer でなければならず、`b` は Integer の `+` が受けるどの型でもよい。

```ruby error
p(Integer.+("a", "b"))    # !> Integer.+: argument 1 must be Integer, but is String
```

### 自分の型に演算子を与える

クラスは module を include し、本体に演算子を定義すると演算子に参加します。`include Arithmetic` と `def +(a, b)` などです。`include Comparable` では `<=>` を定義すれば十分で、`<`、`<=`、`>`、`>=` はそこから来ます。`Array.sort`、`min`、`max` もその `<=>` を使います。

```ruby
class Money
  include Arithmetic
  include Comparable
  attr_reader cents
  def +(a, b) = Money.new(@cents + Money.cents(b))
  def <=>(a, b) = @cents <=> Money.cents(b)
  def to_s(m) = format("$%d.%02d", @cents / 100, @cents % 100)
end
a = Money.new(150)
b = Money.new(250)
puts(a + b)                                        # => $4.00
p(a < b)                                           # => true
puts(Array.join(Array.sort(Array[b, a]), " "))     # => $1.50 $2.50
```

左のオペランドの型が、その演算子の module を include していない、または演算子を定義していないときは、実行前に `type` の問題、実行時は `TypeError` です。

```ruby error
Point = Struct.new(:x, :y)
p(Point.new(1, 2) + Point.new(1, 2))   # !> Arithmetic.+: Point does not include Arithmetic
```

### 左が組み込み型のとき: coerce

`2 + money` は Integer でディスパッチしますが、Integer の表に Money の行はありません。クラスが Ruby のプロトコルと同じく Tuple `[left, right]` を返す `coerce(b, a)` を定義していれば、組を先に変換してから演算子を走らせます。下の `coerce` で `2 + money` は `Money.new(200) + money` になります。検査器も変換を追います。

```ruby
class Money
  include Arithmetic
  attr_reader cents
  def +(a, b) = Money.new(@cents + Money.cents(b))
  def coerce(m, other) = [Money.new(other * 100), m]
end
m = Money.new(50)
p(2 + m)                  # => #<struct Money cents=250>
```

### 等価

クラスの値の `==` は、型が自分の `==` を定義していなければ、Ruby の Struct と同じく型とフィールドを比べます。`Array.include?`、`index` などは同じ等価を使います。

```ruby
Point = Struct.new(:x, :y)
p(Point.new(1, 2) == Point.new(1, 2))   # => true
p(Point.new(1, 2) == Point.new(2, 1))   # => false
p(Point.new(1, 2) == "x")               # => false
p(Array.include?(Array[Point.new(1, 2)], Point.new(1, 2)))   # => true
```

`Comparable` を include して `<=>` を定義した（`==` は定義しない）型は、Ruby の `Comparable#==` と同じく、同じ型の値と `<=>` が 0 のとき等しい。別の型の値（nil など）とは決して等しくなく、そのとき `<=>` は呼ばれません。上の Money では `a == Money.new(150)` が true、`a == nil` が false です。

### 組み込み型の表

組み込み型では、結果の型は両オペランドの型から**閉じた表**で決まります。

| 演算子 | 行 |
|---|---|
| `+` | (Integer, Integer) → Integer。Float を含めば Float。Rational を含み Float を含まなければ Rational。Complex を含めば Complex。(String, String) → String |
| `-` `*` `/` `%` `**` | 数値の組は `+` と同じ |
| `*` | (String, Integer) → String も |
| `<` `<=` `>` `>=` `<=>` | 数値の組、(String, String)、(Tuple, Tuple)、(Array, Array) → true/false（`<=>` は -1, 0, 1, nil） |
| `==` `!=` | **任意の 2 値**: 同じ型の等しい値（数は Integer・Float・Rational をまたいで比べる）。Ruby と同じく、別の型の値は等しくない |
| `+` `-` | (Array, Array) → Array（連結。差） |
| `*` | (Array, Integer) → Array（繰り返し） |
| `<` `<=` `>` `>=` `<=>` | (Symbol, Symbol) も |
| 単項 `-` `+` | Integer, Float, Rational, Complex → 同じ型 |
| 単項 `~` | Integer → Integer |
| `&` `\|` `^` `<<` `>>` | (Integer, Integer) → Integer |
| `\|` `&` `-` | (Set, Set) → Set（和、積、差） |
| `=~` | (String, Regexp), (Regexp, String) → Integer か nil。`!~` (String, Regexp) → true/false |
| `%` | (String, Integer / Float / String / Symbol / Tuple / nil / true / false) → String、Ruby の format（`"%d items" % 3`、`"%s-%s" % [a, b]`） |

```ruby
p("ab" * 3)                    # => "ababab"
p(Array[1, 2] + Array[3])      # => [1, 2, 3]
p(Array[1, 2, 3] - Array[2])   # => [1, 3]
p(Set[1, 2] | Set[2, 3])       # => Set[1, 2, 3]
p(5 & 3)                       # => 1
p(1 << 4)                      # => 16
p("abc" =~ /b/)                # => 1
p("abc" !~ /z/)                # => true
p("%s-%s" % ["a", "b"])        # => "a-b"
```

### 合う行が無いとき

オペランドの型に合う行が無ければ、実行前は `type` の問題、実行時は `TypeError` です。実行時のメッセージは存在する行を列挙します。暗黙の変換はありません。

```ruby error
p("a" - "b")   # !> Arithmetic.-: the operands are (String, String), which the left operand's type does not support
```

### 数値

Integer の `/` と `%` は Ruby に従い、負の数では床に向かって丸めます。Integer のゼロ除算は `ZeroDivisionError`、Float のゼロ除算は IEEE に従います。

```ruby
p(7 / 2)        # => 3
p(-7 / 2)       # => -4
p(-7 % 2)       # => 1
p(7.0 / 2)      # => 3.5
p(1 / 2r)       # => (1/2)
p(1.0 / 0)      # => Infinity
```

- **負の指数。** `Integer ** 負の Integer` は `ArgumentError` です。`a ** b` の型が `b` の値に依らないためです。Rational が欲しければ `2r ** -1` と書きます（`(1/2)`）。
- **Complex。** 順序が無いので `<` などは定義されません。

```ruby error
p(1 / 0)        # !> ZeroDivisionError: Arithmetic./: divided by 0
```

```ruby error
p(2 ** -1)      # !> ArgumentError: Arithmetic.**: Integer ** negative Integer (2 ** -1) is an error; for a Rational, write 2r ** -1
```

### Time

`Time ± 数` は Time、`Time - Time` は秒の Float です。2 つの Time は比較できます。

```ruby
t = Time.at(0, in: "+00:00")
p(t + 60)                 # => 1970-01-01 00:01:00 +0000
p(Time.at(60) - t)        # => 60.0
p(t < Time.at(1))         # => true
```

### 等しさと順序の規則

別の型の値は決して等しくありません。`1 == :a` と `struct == "x"` は Ruby と同じく false です。クラス自身の `==` があればそれが決めます。数だけは Integer・Float・Rational をまたいで比べます。

```ruby
p(1 == 1.0)     # => true
p(1 == 1r)      # => true
p(1 == :a)      # => false
p("1" == 1)     # => false
```

Tuple、Array、Set、Hash、Record は中身が等しいとき等しい。2 つの Record は同じフィールドも要ります。Tuple と Array は Ruby の Array と同じく要素ごとに順序付けられます。

```ruby
p([1, 2] == [1, 2])                 # => true
p([1, 2] == Array[1, 2])            # => false
p({x: 1} == {x: 1, y: 2})           # => false
p(Set[1, 2] == Set[2, 1])           # => true
p([1, 2] < [1, 3])                  # => true
p(Array[1, 2] <=> Array[1, 2, 0])   # => -1
```

比べられない要素があれば、`<` などは `ArgumentError`、`<=>` は nil です。検査器は、比べられない要素型を実行前に報告します。

```ruby error
p(Array["a", 1] < Array["a", "b"])   # !> Comparable.<: elements compared in order may be (Integer, String), which cannot be compared
```

### 演算子ではないもの

- **`!x`** は `x ? false : true` です。どの値にも使え、型の操作ではありません。
- **複合代入。** `x OP= e` は `x = x OP e` です。
- **`&&` と `||`** は Ruby と同じく短絡し、オペランドの一方を返します。

```ruby
p(!0)                  # => false
p(!nil)                # => true
x = 5
x += 2
p(x)                   # => 7
p(nil || "default")    # => "default"
p(1 && "second")       # => "second"
```

## 添字

`x[k]` は `Indexable.[](x, k)`、`x[k] = v` は `Indexable.[]=(x, k, v)` で、`x` の型の `[]` と `[]=` を走らせます。

```ruby
xs = Array[10, 20, 30]
p(xs[0])                  # => 10
p(xs[-1])                 # => 30
p(xs[1..])                # => [20, 30]
p(xs[0, 2])               # => [10, 20]
p(Indexable.[](xs, 1))    # => 20
xs[1] = 25
p(xs)                     # => [10, 25, 30]
```

組み込み型は次のとおりです。

| レシーバ, 添字 | `x[k]` | `x[k] = v` |
|---|---|---|
| Array, Integer | 要素。Array の外なら nil | `v` を格納（T の Array は `v` を検査） |
| String, Integer | 1 文字の String。外なら nil | 不可 |
| Tuple, Integer | 要素。Tuple の外は `IndexError` | その位置の型なら `v` を格納 |
| Array, Range / String, Range | スライス、または nil | 不可 |
| Array, Integer, Integer / String, Integer, Integer（`s[start, length]`） | スライス、または nil | 不可 |
| Hash, 任意のキー | 値、または既定値（`Hash.new(default)` で作っていなければ nil） | `v` を格納 |
| MatchData, Integer / String | グループ、または nil | 不可 |

```ruby
s = "hello"
p(s[0])                   # => "h"
p(s[1..2])                # => "el"
p(s[1, 3])                # => "ell"
h = Hash["a" => 1]
p(h["a"])                 # => 1
p(h["z"])                 # => nil
p(Hash.new(0)["z"])       # => 0
m = String.match("2026-10", /(\d+)-(\d+)/)
if m
  p(m[0])                 # => "2026-10"
  p(m[2])                 # => "10"
end
```

### 外れた添字

負の添字は Ruby と同じく末尾から数えます。外れた添字の値は Ruby と同じく `nil` なので、`a[i]` の静的な型は `T | nil` です。結果を検査せずに使うと、レベル 3 の `index-nil` が報告します。レベル 2 は通し、実行時にその操作で止まります。`Array.fetch(a, i)` は代わりに `IndexError` を投げます。

```ruby error
xs = Array[10, 20, 30]
p(xs[5] + 1)              # !> TypeError: Arithmetic.+: no implementation for (nil, Integer)
```

```ruby error
xs = Array[10, 20, 30]
p(Array.fetch(xs, 5))     # !> IndexError: Array.fetch: index 5 outside of array bounds: -3...3
```

Tuple は長さが型の一部なので、外の添字は `IndexError` です。添字が定数なら実行前に報告されます。

```ruby error
t = [1, "a"]
p(t[2])                   # !> Indexable.[]: the index is outside the Tuple [Integer, String]
```

### 書き込み

型無しの Array の末尾の先に書くと、Ruby と同じく隙間が nil で埋まります。T の Array は nil が T でないので `IndexError` です。T でない値の書き込みは実行前に `type` の問題です。Tuple への書き込みは、その位置の型の値だけです。String には書けません。

```ruby
xs = Array[1]
xs[3] = 4
p(xs)                     # => [1, nil, nil, 4]
```

```ruby error
ys = Integer[1]
ys[3] = 4                 # !> IndexError: Array.[]=: index 3 is past the end of Integer[] (length 1); the gap would be nil
```

```ruby error
ys = Integer[1]
ys[0] = "a"               # !> Indexable.[]=: an element must be Integer, but is String
```

### 複合代入

`x[k] OP= v` と `x[k] ||= v` は `x` と `k` を 1 度だけ評価します。ローカル変数の `y ||= v` は、`y` が nil か false のときだけ代入します。

```ruby
h = Hash[]
h[:a] ||= Array[]
Array.push(h[:a], 1)
h[:a] ||= Array[]
p(h)                      # => {a: [1]}
y = nil
y ||= 5
y ||= 6
p(y)                      # => 5
```

### 自分の型に添字を与える

クラスは `include Indexable` と `def [](x, k)` / `def []=(x, k, v)` で参加します。添字が 2 つなら `m[r, c]` は `def [](m, r, c)`、`m[r, c] = v` は `def []=(m, r, c, v)` を呼びます。

```ruby
class Grid
  include Indexable
  attr_reader w, cells
  def [](g, r, c) = @cells[r * @w + c]
  def []=(g, r, c, v)
    @cells[r * @w + c] = v
  end
end
g = Grid.new(2, Array[0, 0, 0, 0])
g[1, 0] = 7
p(g[1, 0])                # => 7
p(Grid.cells(g))          # => [0, 0, 7, 0]
```
