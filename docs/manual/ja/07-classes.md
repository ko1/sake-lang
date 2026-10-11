# クラス

プログラムが定義する型はクラスです。`class` に `attr_*` の行で宣言しても `Struct.new(:x, :y)` で作っても同じもので、値はフィールドを持ち（Ruby の Struct の値として `#<struct Point x=3, y=4>` と表示されます）、操作は `Point.norm2(pt)` と型を付けて呼びます。クラスは継承せず、値へのメソッド呼び出しも無いので、Ruby の class と重なるのは「型を宣言し、その操作をまとめる」ところです。

この章の例の `# => 値` は `bin/sake --strict=2` の実際の出力です。

## 型の宣言: class と attr_*

`class C ... end` は型 `C` を宣言します。本体の `attr_*` の行がフィールドを、`def` が操作を定めます。`C.new` が値を作り、フィールドはリーダ `C.x(c)` とライタ `C.set_x(c, v)` で読み書きします。

```ruby
class Account
  attr_reader owner
  attr_accessor balance
  def initialize(a)
    @balance = 0 if @balance == nil
  end
end
acct = Account.new("ko1")
p(acct)                              # => #<struct Account owner="ko1", balance=0>
p(Account.owner(acct))               # => "ko1"
Account.set_balance(acct, 100)
p(Account.balance(acct))             # => 100
rich = Account.new("you", 500)
p(Account.balance(rich))             # => 500
```

すべての `class` は型です。フィールドは最初の `class` の本体で宣言します。後の `class Account` は関数を足すだけです。フィールド名は裸で書きます。

| 行 | 意味 |
|---|---|
| `attr_accessor x, ...` | リーダ `C.x(c)` とライタ `C.set_x(c, v)` を持つフィールド |
| `attr_reader x, ...` | リーダだけ。型の関数の中では `@x = v` で書ける |
| `attr_writer x, ...` | ライタだけ。型の関数の中では `@x` で読める |
| `private attr_... x` | リーダとライタはそのクラス自身の関数専用。`new` は受け取る |

`private` のフィールドは、そのクラスの関数からならどの値のものでも読み書きできます（`@x`、または `T.x(other)`）。外からの `T.x(c)` は静的エラーです。

```ruby
class Counter
  attr_reader label
  private attr_accessor n
  def bump(c) = @n += 1
  def same?(c, other) = n(c) == n(other)
end
c = Counter.new("hits", 0)
Counter.bump(c)
p(Counter.bump(c))                   # => 2
p(Counter.same?(c, Counter.new("x", 2)))   # => true
```

```ruby error
class Counter
  attr_reader label
  private attr_accessor n
end
c = Counter.new("hits", 0)
p(Counter.n(c))                      # !> field `n` of Counter is private (private attr_*)
```

### フィールドの順序と new

フィールドは書いた順に並び、行をまたいでも同じです。これが `C.new` の引数の順です。`C.new` はアクセスの種類に関わらずフィールドを位置で取り、名前でも取れます。`Logger.new("app", level: :warn)` は最初のフィールドを位置で、`level` をキーワードで与えます。

- フィールドが複数ある型では名前を勧めます。位置の `new` はフィールド順と照合されません。
- 未知の名前と、1 つのフィールドの二重指定は静的エラーです。
- `initialize` が無ければ、全フィールドを与えます。
- `initialize` があれば、後ろのフィールドを省略できます。後のキーワードのために飛ばすこともできます。省略したフィールドは initialize が始まるとき nil で、initialize が設定します。

```ruby
class Logger
  attr_reader name, level
  def initialize(l)
    @level = :info if @level == nil
  end
end
a = Logger.new("app")
p(Logger.level(a))                   # => :info
b = Logger.new("app", level: :warn)
p(Logger.level(b))                   # => :warn
c = Logger.new(level: :debug, name: "db")
p(c)                                 # => #<struct Logger name="db", level=:debug>
```

```ruby error
class Logger
  attr_reader name, level
  def initialize(l)
    @level = :info if @level == nil
  end
end
Logger.new("app", lvl: :warn)        # !> Logger has no field `lvl`
```

### initialize

class の `def initialize(c)` は、`C.new` がフィールドを格納した**後**に、新しいインスタンスを受けて走ります。Ruby と同じく、最初の値（`@items = Array[]`）、検査（`@port => Integer`）、変換（`@celsius = Float(@celsius)`）を書く場所です。`@level = :info if @level == nil` は `new` が与えた値を保ちます。

- 引数はその 1 つ（新しいインスタンス）だけです。2 つ以上は静的エラーです。
- `C.initialize` を直接呼ぶのは静的エラーです。`C.new` が呼びます。
- 検査器は initialize を `C.new` の呼び出しごとに解析します。そこで `@x` はその呼び出しが与えた値を読むので、誤った引数はその呼び出しについて報告されます。フィールドは initialize が残したものを持ちます。

```ruby
class Temp
  attr_reader celsius, label
  def initialize(t)
    @celsius = Float(@celsius)
    @label = "C" if @label == nil
  end
end
t = Temp.new(21)
p(Temp.celsius(t))                   # => 21.0
p(Temp.label(t))                     # => "C"
p(Temp.new(1, "K"))                  # => #<struct Temp celsius=1.0, label="K">
```

```ruby error
class Box
  attr_reader value
  def initialize(b)
    @value => Integer                # !> `=> Integer`: the value is String, which does not match [type]
  end
end
p(Box.new(1))
p(Box.new("s"))
```

> [!WARNING]
> Ruby の `def initialize(x) = @x = x` は Sake では静的エラーです。`x` は新しいインスタンスであって値ではなく、自分を自分のフィールドに入れることになります。`C.new(...)` が既にフィールドを格納しているので、initialize は検査と変換だけを書きます。

```ruby error
class Box
  attr_reader value
  def initialize(x) = @value = x     # !> `@value = x` stores the new Box in its own field: `x` is the instance, not a value
end
```

### 既定値は無い

`attr_reader items = Array[]` は静的エラーです。フィールドの最初の値は `initialize` で設定します。新しいインスタンスごとに走る唯一の場所がそこで、他のフィールドも読めます（`@len = String.bytesize(@src)`）。検査器は initialize を通してフィールドを追うので、initialize が常に設定するフィールドはその後 nil ではありません。

```ruby error
class Bag
  attr_reader items = Array[]        # !> a field has no default value; set it in initialize, which runs after Bag.new
end
```

```ruby
class Bag
  attr_reader items
  def initialize(b)
    @items = Array[] if @items == nil
  end
  def add(b, x) = Array.push(@items, x)
end
b = Bag.new
Bag.add(b, 1)
p(Bag.items(b))                      # => [1]
```

### 予約語と同じ名前のフィールド

予約語と同じ名前のフィールドは Symbol で宣言します: `attr_accessor :next`。裸では解析できません。リーダは `Node.next(n)`、関数の中の `@next` はいつもどおりです。

```ruby
class Node
  attr_accessor value, :next
  def last_value(n)
    nx = @next
    nx ? last_value(nx) : @value
  end
end
list = Node.new(1, Node.new(2, nil))
p(Node.next(Node.next(list)))        # => nil
p(Node.last_value(list))             # => 2
```

### 構築ごとに 1 つの型

検査器にとって、各 `C.new` はそれ自身の型です。別の場所で作ったインスタンスはそれぞれのフィールド型を保つので、Integer の `Heap` と String の `Heap` は混ざりません。1 つの `C.new` が別の引数型で呼ばれた関数の中にあるとき（`expect(42)` と `expect("x")`）も、呼び出しごとに型が分かれます。汎用の包み（`Result.map` の `Ok.new(yield(@value))`）は呼び出し元ごとに 1 つの型です。

- メッセージは、型に複数の場所があるときだけ場所付きで名乗ります（`Heap@L7`）。
- 値から値を作る関数（Value を取る関数の中の `Value.new(a + b)`）は、場所ごとに 1 つの型にとどまります。

```ruby
class Heap
  attr_reader items
  def push(h, x) = Array.push(@items, x)
  def top(h) = Array.first(@items)
end
ints = Heap.new(Array[])
Heap.push(ints, 3)
words = Heap.new(Array[])
Heap.push(words, "job")
p(Heap.top(ints) + 1)                # => 4
p(String.upcase(Heap.top(words)))    # => "JOB"
```

### class B < A

`class B < A` は A の定義を B に書き写す略記で、継承ではありません。

- A のフィールドが先、次に B のフィールドが並びます。
- A の関数は B の関数でもあります。その中の型無しの名前と `@x` は B のものです。
- A の `include` は B のものです。
- B 自身の定義が A のものに勝ちます。
- その後 A と B は無関係です。B は A ではなく、`A.f(b)` は型エラーで、`b in A` は偽です。
- `<` はプログラムのどの class でも取り、その場に書いた `Struct.new(...)` も取ります（`class P < Struct.new(:x)`）。module は `include` します。

```ruby
class Shape
  attr_reader name
  def describe(s) = "a shape called " + @name
end
class Circle < Shape
  attr_reader r
  def area(c) = 3.0 * @r * @r
end
class Square < Shape
  attr_reader side
  def describe(s) = "a square called " + @name
end
c = Circle.new("c1", 2.0)
p(c)                                 # => #<struct Circle name="c1", r=2.0>
p(Circle.describe(c))                # => "a shape called c1"
p(Circle.area(c))                    # => 12.0
p(Square.describe(Square.new("s1", 3.0)))   # => "a square called s1"
```

```ruby error
class Shape
  attr_reader name
  def describe(s) = @name            # !> Shape.name: argument 1 must be Shape, but is Circle [type]
end
class Circle < Shape
  attr_reader r
end
p(Shape.describe(Circle.new("c", 2.0)))
```

### 例外型

`class E < Exception`（または `< StandardError`）は例外型を宣言します。`message` が最初のフィールドで、その後に `attr_*` の行のフィールドが続きます。`message` より後のフィールドは常に省略でき、`E.new("msg")` はメッセージだけ与えます。`raise E, "msg"` の形は、`message` 以外のフィールドを持たない例外型に限ります（[例外とエラー](08-exceptions.md)）。

```ruby
class ParseError < StandardError
  attr_reader line
end
begin
  raise ParseError.new("bad token", 7)
rescue ParseError => e
  p(ParseError.message(e))           # => "bad token"
  p(ParseError.line(e))              # => 7
end
begin
  raise ParseError.new("no line")
rescue ParseError => e
  p(ParseError.line(e))              # => nil
end
```

### 略記: Struct.new と Exception.new

`Struct.new(:x, :y)` は `attr_accessor x, y` を持つ `class C` の略記です。Ruby の形 `class C < Struct.new(:x, :y)` も書け、そのフィールドが先、本体の `attr_*` 行と関数が後に来ます。`Exception.new(:line)` は `attr_accessor line` を持つ `class C < Exception` の略記です。

```ruby
class Point < Struct.new(:x, :y)
  attr_reader label
  def to_s(pt) = @label + "(" + Integer.to_s(@x) + ", " + Integer.to_s(@y) + ")"
end
p(Point.to_s(Point.new(1, 2, "P")))  # => "P(1, 2)"
Oops = Exception.new(:line)
begin
  raise Oops.new("oops", 3)
rescue Oops => e
  p(Oops.line(e))                    # => 3
end
```

### 宣言の静的エラー

次はどれも静的エラーで、検査器が hint で直し方を示します。

- `attr_reader :x`: 予約語でないフィールドを Symbol で書いた（裸で書く）。
- 最初の `class C` より後の `class C` でフィールドを宣言した。
- 既定値 `attr_reader x = v`。
- 読み出し専用（`attr_reader`）のフィールドへの、クラスの外からの書き込み。
- 古い形 `class C < {reader: [...]}`。hint が `attr_*` の行を示します。

## Struct.new の操作

```ruby
Point = Struct.new(:x, :y)
```

名前空間 `Point` に次の操作が定義されます。

| 操作 | 意味 |
|---|---|
| `Point.new(x, y)` | 作成。位置引数、フィールドごとに 1 つ |
| `Point.x(p)`, `p.Point.x` | フィールド `x` を読む（リーダはフィールドの名前） |
| `Point.set_x(p, v)`, `p.Point.x = v` | フィールド `x` をその場で書く。`v` を返す |
| `p.Point.x += v`, `\|\|=`, `&&=` | `p.Point.x = p.Point.x + v`。`p` は 1 度だけ評価 |
| `Point[p1, ...]` | Point の Array |
| `p == nil`, `p != nil` | nil との比較 |

```ruby
Point = Struct.new(:x, :y)
pt = Point.new(3, 4)
p(pt)                                # => #<struct Point x=3, y=4>
p(Point.x(pt))                       # => 3
p(Point.set_x(pt, 10))               # => 10
pt.Point.y += 1
p(pt)                                # => #<struct Point x=10, y=5>
pts = Point[Point.new(1, 2), Point.new(3, 4)]
p(pts)                               # => [#<struct Point x=1, y=2>, #<struct Point x=3, y=4>]
p(pt == nil)                         # => false
```

### 可変性

値は可変で、参照で共有されます。ある変数を通した変更は、同じ値を持つ他のすべての変数から見えます。

```ruby
Point = Struct.new(:x, :y)
pt = Point.new(3, 4)
q = pt
Point.set_y(q, 0)
p(pt)                                # => #<struct Point x=3, y=0>
```

### 操作を足す

`class Point ... end` か `def Point.f` で自分の操作を足します。その中ではリーダとライタを型無しで呼べます（`x(p)`、`set_x(p, v)`）。フィールドと同名の関数（`def x(p) = ...`）は、Ruby で attr_reader の後にメソッドを定義したのと同じくリーダを置き換えます。`@x` は常にフィールドを読みます。

```ruby
Point = Struct.new(:x, :y)
def Point.shift(pt, dx)
  @x += dx
  pt
end
class Point
  def norm2(pt) = @x * @x + @y * @y
  def x(pt) = 100
end
pt = Point.new(3, 4)
p(Point.shift(pt, 1))                # => #<struct Point x=4, y=4>
p(Point.norm2(pt))                   # => 32
p(Point.x(pt))                       # => 100
```

### フィールドの略記 @x

クラスの関数（`class Point` の中、または `def Point.f`）の中で、`@x` は関数の**第 1 引数**のフィールド `x` です。第 1 引数は慣習として主語です。

| 書いたもの | 意味 |
|---|---|
| `@x` | `Point.x(p)` |
| `@x = v` | `Point.set_x(p, v)` |
| `@x OP= v` | `Point.set_x(p, Point.x(p) OP v)` |
| `@x \|\|= v` | `Point.x(p) \|\| Point.set_x(p, v)` |

- `p` は第 1 引数の今の値で、同名の引数を持つブロックの中でも変わりません。
- 通常の実行時検査がかかります。第 1 引数は Point でなければなりません。
- `@x` は次の場合に静的エラーです: クラスの関数の外、引数の無い関数、フィールドが存在しないとき。

```ruby error
Point = Struct.new(:x, :y)
def far(pt) = @x > 100               # !> `@x` means a field of the first argument, so it is only available in a function of a class
```

### 印字

`p` は クラスのインスタンスを `#<struct Point x=1, y=2>` と印字します。`puts` も同じです。

### Struct.new の制限

`Struct.new` は定数に代入しなければなりません。定数はトップレベルか、class / module の本体の直下に置きます（`module Geo` の中の `Point = Struct.new(:x, :y)` は `Geo::Point`）。Symbol だけを取り、ブロックは取りません。関数は `class Point` の中で定義します。

`Data.define` は無く、`Struct.new` を使う hint 付きで拒否されます。Ruby の `Data` は不変ですが、Sake の名前付き型は可変で、それは Ruby の `Struct` が提供するものです。

```ruby error
Point = Data.define(:x, :y)          # !> Sake's named types are mutable, so they are made with Struct.new, not Data.define
```

### 複製: Kernel.dup

`Kernel.dup(x)` は浅い複製です。新しい容器と クラスのインスタンスを作り、要素は同じものを共有します。型が `dup` を定義していればそれが呼ばれます。

```ruby
Point = Struct.new(:x, :y)
a = Point.new(1, Array[2])
b = Kernel.dup(a)
Point.set_x(b, 9)
Array.push(Point.y(b), 3)
p(a)                                 # => #<struct Point x=1, y=[2, 3]>
p(b)                                 # => #<struct Point x=9, y=[2, 3]>
```
