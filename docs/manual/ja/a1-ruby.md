# Ruby との違いと未対応のもの

Sake の構文は Ruby のものですが、Ruby の書き方のいくつかは静的エラーになり、別の書き方に置き換えます。この付録は、その置き換えを 1 枚の表にまとめ、表の下で理由を述べます。Ruby で書いて静的エラーが出たら、まずこの表を引いてください。各エラーの hint も、表の Sake 側の形を示します。

## Ruby から Sake へ

表の各行は、Ruby の書き方（左）、Sake での書き方（中）、その一言の理由（右）です。理由の詳しい説明と例は表の下の各節にあります。

| Ruby | Sake | 理由 |
|---|---|---|
| `s.upcase` | `String.upcase(s)`、`s.String.upcase` | 操作に型を書く |
| `p.x`, `p.x = v` | `Point.x(p)`, `p.Point.x = v`。関数の中では `@x`, `@x = v` | フィールドの読み書きも型を名乗る |
| `x.nil?` | `x == nil` | 値へのメソッド呼び出しは無い |
| `def self.f` | `def f`。module では `module_function` | 名前空間に 1 つの名前は 1 つの関数 |
| `class B < A`（継承） | `class B < A`（A の定義の書き写し。部分型ではない） | 呼び出し先は静的 |
| `attr_reader :x` | `attr_reader x` | フィールド名は裸 |
| `def initialize(x) = @x = x` | `C.new(x)` が格納する。`initialize(c)` は検査と変換だけ | 引数は新しいインスタンス |
| `@items = []`（既定値） | `initialize` の中で `@items = Array[]` | フィールドの既定値は無い |
| `Data.define` | `Struct.new` | クラスは可変 |
| `[1, 2]`（伸びる配列） | `Array[1, 2]`。`[1, 2]` は Tuple（長さ固定） | リテラルの形が型を決める |
| `{a: 1}`（Hash） | `Hash[a: 1]`。`{a: 1}` は Record | 同上 |
| `%w[a b]`, `%i[a b]` | `String["a", "b"]`, `Symbol[:a, :b]` | 未決（Tuple か Array か） |
| `PI = 3.14` | `def pi = 3.14`。表は `once { ... }` | 値の定数は無い |
| `Math::PI`, `ARGV`, `$stdout` | `Math.PI`（`Math::PI` も可）、`ARGV`、`IO.stdout` | 操作として読む |
| `case x when Integer` | `case x in Integer` | `===` は無い |
| `for x in xs` | `Array.each(xs) { \|x\| }` | 反復は操作 |
| `$1`, `$~` | `m = String.match(s, re)` の後 `m[1]` | グローバル変数は無い |
| `proc`, `lambda`, `->`, `&:sym`, `method(:f)` | 無し。ブロックは `yield` か `&b` で渡すだけ | ブロックは第二級 |
| `obj.send(:f)`, `define_method`, `method_missing`, `eval` | 無し | 呼び出し先は静的 |
| `g(**opts)` | 無し。Hash を位置で渡す | 設計判断中（D11） |
| `rescue A`（階層で捕まえる） | `rescue A, B`（列挙した型だけ） | 例外型に階層は無い |
| `1 + money` | Money に `coerce(m, other)` を定義 | 左のオペランドが決める |

### 操作に型を書く

Sake では型を名乗るのは操作だけです。`s.upcase` のような値へのメソッド呼び出しは静的エラーで、検査器は `String.upcase(s)` と連鎖の形 `s.String.upcase` を hint で示します（[プログラムの構造と名前解決](02-program.md)）。フィールドの読み書きも同じで、`p.x` は `Point.x(p)`、`p.x = v` は `p.Point.x = v` です。クラスの関数の中では `@x` が第 1 引数のフィールド `x` を指します（[クラス](07-classes.md)）。

```ruby
Point = Struct.new(:x, :y)
class Point
  def shift(pt, d)
    @x = @x + d          # Point.set_x(pt, Point.x(pt) + d)
    @x
  end
end
pt = Point.new(1, 2)
p(Point.x(pt))           # => 1
pt.Point.x = 5
p(Point.shift(pt, 1))    # => 6
p(pt)                    # => #<struct Point x=6, y=2>
```

`x.nil?` も値へのメソッド呼び出しなので同じエラーになり、hint は `x == nil` を示します。

### クラス

プログラムが定義する型はクラスです。`class C` に `attr_*` の行で宣言しても、略記の `Struct.new(:x, :y)` で作っても同じものです。Ruby の class と違う点は次のとおりです（[クラス](07-classes.md)）。

- **`def self.f` は書かない。** Sake に `self` は無く、`class C` の中の `def f` がそのまま `C.f` です。Ruby のクラスメソッドもインスタンスメソッドも、Sake では同じ `def f` になります。module では `module_function` を書きます。
- **継承は無い。** `class B < A` は A の定義（フィールド、関数、include）を B に書き写す略記です。その後 A と B は無関係な型で、B の値を `A.f(b)` に渡すのは型エラーです。
- **フィールド名は裸。** `attr_reader :x` は「`:` を付けずに `x` と書く」というエラーになります。
- **`initialize` は値を受け取らない。** `C.new(x)` がフィールドを格納した後、`def initialize(c)` が新しいインスタンスを受けて走ります。Ruby の `def initialize(x) = @x = x` は、インスタンス自身を自分のフィールドに入れることになるので静的エラーです。
- **既定値は `initialize` で。** `attr_reader items = Array[]` はエラーで、最初の値は `initialize` の中で `@items = Array[]` と設定します。`C.new` はそのフィールドを省略できます。
- **`Data.define` は無い。** Sake のクラスは可変なので、Ruby の `Struct` に当たる `Struct.new` を使います。

```ruby
class A
  attr_reader x
  def double(a) = @x * 2
end
class B < A              # A の x と double を B に書き写す
  attr_reader y
end
b = B.new(1, 2)
p(B.double(b))           # => 2
p(b)                     # => #<struct B x=1, y=2>
```

```ruby error
class Bag
  attr_reader name, items
  def initialize(x) = @items = x    # !> `@items = x` stores the new Bag in its own field: `x` is the instance, not a value
end
```

### リテラルと定数

リテラルは形で型が決まります（[値と型](03-values.md)）。

- **`[1, 2]` は Tuple** で、長さが固定です。伸びる配列は `Array[1, 2]`、空なら `Array[]` と書きます。Tuple を `Array.push` に渡すと、`Array[...]` と書く hint 付きの型エラーです。
- **`{a: 1}` は Record** で、`Hash[a: 1]` が Hash です。Record のフィールドはパターン `r => {a:}` で読みます。
- **`%w[a b]` と `%i[a b]` は未対応** です。Tuple にするか Array にするかが決まっていません。`String["a", "b"]`、`Symbol[:a, :b]` と書くと、要素型付きの Array になります。
- **値の定数は無い。** `PI = 3.14` は静的エラーで、hint は `def pi = 3.14` を示します。計算して保持したい表は `def table = once { ... }` です（[関数とブロック](04-functions.md)）。定数に代入できるのは `Struct.new` と `Exception.new` だけです。
- **組み込みの定数は操作。** `Math.PI`、`ARGV`、`IO.stdout` のように呼びます。`Math::PI` など組み込みの数個は Ruby の形でも読めます。`$stdout` のようなグローバル変数はありません。

```ruby
t = [1, 2]
xs = Array[1, 2]
Array.push(xs, 3)
p(t, xs)                 # => [1, 2]
                         # => [1, 2, 3]
h = Hash[a: 1]
h[:b] = 2
p(h)                     # => {a: 1, b: 2}
def pi = 3.14
p(pi, Math.PI)           # => 3.14
                         # => 3.141592653589793
```

```ruby error
xs = [1, 2]
Array.push(xs, 3)        # !> Array.push: argument 1 must be Array, but is [Integer, Integer] [type]
```

### 制御と反復

- **`case`/`when` は無く、`case`/`in`** を使います。Ruby の `when` はレシーバで `===` をディスパッチしますが、Sake には `===` がありません。`case x in Integer` は型で分岐し、検査器が網羅性を見ます（[制御構造とパターン](06-control.md)）。
- **`for` は無く、操作で反復します。** `Array.each(xs) { |x| ... }`、`Range.each(1..3) { |i| ... }` のように、要素を渡すのは Array や Range の操作です（[関数とブロック](04-functions.md)）。
- **`$1`、`$~` は無い。** 一致を変数に保って読みます: `m = String.match(s, re)` の後、`m` が nil でなければ `m[1]`。

### ブロックと動的な機能

- **ブロックは第二級です。** 関数に渡して `yield` で呼ぶか、`&b` で次の関数に渡すだけで、変数に格納できません。`proc`、`lambda`、`->`、`method(:f)` は無く、`&:sym` も渡せません（[関数とブロック](04-functions.md)）。
- **呼び出し先は静的です。** `send`、`define_method`、`method_missing`、`eval` はありません。`eval` は「静的解析を無効にする」というエラーになります。
- **キーワードの受け渡し。** `def f(**opts)` で集めることはできますが、`g(**opts)` と次の関数に渡すことはできません（`**` is not supported）。Hash を位置引数で渡します。設計判断 D11 として開いています。

### 例外

例外型に階層は無いので、`rescue A, B => e` は列挙した型だけを捕まえます（[例外とエラー](08-exceptions.md)）。`class MyErr < StandardError` と書いても MyErr は StandardError の部分型ではなく、`<` は書き写しです。ただし `rescue => e`、`rescue StandardError => e`、`rescue Exception => e` の 3 つは、Ruby の「どの例外も」という意味を保って、rescue できるすべての例外を捕まえます。

```ruby
class MyErr < StandardError
end
begin
  raise MyErr, "boom"
rescue KeyError, IndexError => e
  p(1)
rescue MyErr => e
  p(Exception.message(e))    # => "boom"
end
```

### 演算子

`a + b` は `Arithmetic.+(a, b)` の略記で、左のオペランドの型で解決されます（[演算子と添字](05-operators.md)）。`1 + money` は Integer でディスパッチするので、Money の `+` には届きません。Ruby と同じプロトコルで、Money に `coerce(m, other)` を定義して `[left, right]` の Tuple を返すと、組を変換してから演算子が走ります。

```ruby
class Money
  include Arithmetic
  attr_reader cents
  def +(a, b) = Money.new(@cents + Money.cents(b))
  def coerce(m, other) = [Money.new(other * 100), m]
end
m = Money.new(50)
p(2 + m)                 # => #<struct Money cents=250>
```

## 未対応のもの

次はいずれも静的に拒否され、「not supported」のエラーになります。多くは設計判断を待っています。

- **Record のフィールドへの書き込み。** `r[:a] = 2` は Record を添字できないというエラーです。読むのはパターン `r => {a:}` です。
- **型スコープ `Integer.(a + b)`。**
- **`case`/`when`。** `case`/`in` を使います。
- **`%w[]`、`%i[]`。** Tuple か Array か未決です。
- **`for`。** 今のところ予定なし。`Range.each(1..3) { |i| ... }` のような操作で反復します。
- **パターンの他の形。** Tuple パターンの `*rest`、find パターン、ピン `^x`、ガード `in Integer if c`。使えるパターンは[制御構造とパターン](06-control.md)にあります。
- **第一級のブロック。** ブロックの格納、`proc`、`lambda`。
- **`g(**opts)`。** 集めたキーワードを次に渡すこと。
- **`begin ... end while`。** `while` を先に書きます。

## 設計の資料

- `DESIGN.md`（日本語）: 設計の経緯と各決定の理由。
- `docs/comparison.md`（日本語）: Sake の新規性。軸ごとに Elm・Crystal・Rust・Elixir・TypeScript・Clojure や型推論の研究と比べ、何が新しく何が既存かを判定する。
- `TODO.md`: 開いている課題と設計判断（D1〜D13）。
- `experiments/`: 各実験の方法・結果・限界（README 付き）。
