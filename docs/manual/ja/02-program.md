# プログラムの構造と名前解決

この章は、プログラムが何から成り、プログラムの中の名前がどう解決されるかを述べます。1 つの考えが全体を貫きます。すべての定義は実行前に集められ、すべての呼び出し先は実行前に決まります。だから関数は定義より上の行から呼べ、名前の誤りは実行前に報告されます。

## ファイルと `require`

プログラムは 1 つのファイルと、それが `require` するファイルです。ファイルのトップレベルには定義と文を並べます。定義は実行前にまとめて集められ、文は上から順に実行されます。

```ruby
puts(greet("Sake"))                  # => Hello, Sake
def greet(name) = "Hello, #{name}"   # 定義より上の行から呼べる
def String.shout(s) = String.upcase(s) + "!"
puts(String.shout("hi"))             # => HI!
Point = Struct.new(:x, :y)
class Point
  def to_s(p) = "(#{@x}, #{@y})"
end
module Util
  module_function
  def origin = Point.new(0, 0)
end
puts(Util.origin)                    # => (0, 0)
```

### トップレベルに書けるもの

- **`require "path"`**: 別のファイルを読みます。次の節で述べます。
- **関数定義**: `def name(params) ... end` と `def name(params) = expr`。
- **名前空間付きの関数定義**: `def Type.name(params) ...`。`class Type` の中で `name` を定義するのと同じです。
- **名前空間**: `class Name ... end` と `module Name ... end`。
- **クラス**: `attr_*` の行を持つ `class Name`、または `Name = Struct.new(:field, ...)`。
- **文**: それ以外の式。文は順に実行されます。

### `require`

`require "path"` は `path.sake` を読みます。拡張子は省略でき、パスは require するファイルのディレクトリからの相対です。

```ruby
# lib/units.sake
puts("loading units")
def km_to_m(km) = km * 1000
```

```ruby
# main.sake
require "lib/units"          # => loading units
puts("main")                 # => main
puts(km_to_m(3))             # => 3000
```

- **実行前に決まる。** 引数は文字列リテラル、`require` はファイルのトップレベルの文でなければなりません。プログラムを構成するファイルは実行前に決まります。
- **1 回だけ。** 各ファイルは、誰が require しても 1 回だけ読まれます。循環は既に読んだファイルで止まります。
- **glob。** `require "sql/*"` は、require するファイルの隣で `sql/*.sake` に合うファイルを**名前順**に全部読みます（自分自身は除く）。何にも合わなければエラーです。定義は先に集められるので、順序が効くのはトップレベルの文だけです。
- **順序。** require されたファイルのトップレベルの文は、require したファイルの文より先に走ります。1 つのファイルの `require` はすべて先に読まれます。上の例で `loading units` が `main` より先に出るのはそのためです。
- **定義は 1 つの集まり。** すべてのファイルの定義はまとめて集められるので、ファイルをまたいで名前を任意の順で使えます。同じ名前を 2 つのファイルで定義するのは、1 つのファイルの中と同じくエラーです。
- **メッセージ。** エラーメッセージは各行のファイルを名乗ります（`lib/units.sake:4`、`from lib/broken.sake:3`）。
- **ライブラリ。** `require "json"` のように兄弟に無い名前は、処理系に付属する [ライブラリ](10-library.md)（`sakelib/`）から探します。

### 名前空間: `class` と `module`

`class Name ... end` と `module Name ... end` は名前空間を開きます。`class` は**型**（クラス）を宣言するか、既にある型に操作を足します。`String` のような組み込み型にも足せます。`module` は**型を持たない**名前空間です。

名前空間の本体に書けるのは次だけです。

- `def name(...)`（レシーバ無し）
- `include Module`
- `module_function`（module の中。後述の「module の関数の呼び方」）
- 入れ子の `class` / `module`、`Name = Struct.new(...)`
- class では `attr_reader` / `attr_accessor` / `attr_writer` の行（[クラス](07-classes.md)）

それ以外の文を本体に置くのは静的エラーです。型に `module` を使うのも静的エラーで、hint が `class` を示します。

```ruby error
module String                # !> `module String`: String is a type; add operations to a type with class
  def shout(s) = String.upcase(s)
end
```

### 名前空間は入れ子にできる

`module A` の中の `class B`（`module B`、`B = Struct.new(...)` も）は `A::B` を宣言します。トップレベルの `class A::B` も同じ名前空間を開くので、どちらの書き方でも同じクラスに操作を足せます。

```ruby
module Geo
  Point = Struct.new(:x, :y)
  class Point
    def norm2(p) = @x * @x + @y * @y
  end
  module Util
    module_function
    def origin = Point.new(0, 0)      # ここでの Point は Geo::Point
  end
end
class Geo::Point                       # Ruby の書き方で同じクラスを開く
  def to_s(p) = "(#{@x}, #{@y})"
end
pt = Geo::Point.new(3, 4)
p(Geo::Point.norm2(pt))                # => 25
p(pt.Geo::Point.norm2)                 # => 25
puts(Geo::Util.origin)                 # => (0, 0)
p((pt in Geo::Point))                  # => true
```

- **外からは完全な名前。** `A::B.f(x)`、`x.A::B.f`、`include A::M`、`class C < A::B`、`x in A::B`、`(A::B|C).f(x)`、`rescue A::E` と書きます。
- **中では短い名前。** `A` の中では `B` だけで `A::B` を指せます。Ruby と同じく内側の名前空間から探し、無ければトップレベルの `B` です。
- **`def A::B.f` は書けない。** Ruby の構文に無いからです。入れ子の module の module 関数は、その中で定義します（`module A::B` + `module_function`）。
- **名前空間は値ではない。** `p(A::B)` はエラーで、`A::B` だけを書いても意味がありません。

```ruby error
module Geo
  Point = Struct.new(:x, :y)
end
p(Geo::Point)                # !> type `Geo::Point` cannot be used as a value
```

### クラスは継承しない

どの class についても、`class B < A` は A の定義を B に書き写す略記です。その後 A と B は無関係な型で、`A.f` は A の値だけを取ります（[クラス](07-classes.md)）。

```ruby
class A
  attr_reader x
  def double(a) = @x * 2
end
class B < A
  attr_reader y
end
b = B.new(1, 2)
p(B.double(b))               # => 2
p((b in A))                  # => false
```

```ruby error
class A
  attr_reader x
  def double(a) = @x * 2     # !> A.x: argument 1 must be A, but is B [type]
end
class B < A
  attr_reader y
end
p(A.double(B.new(1, 2)))
```

### `self` は無い

`def self.x` は拒否されます。Sake に `self` は無いからです。class の中の `def x` がそのまま `A.x` を定義します。

```ruby error
class A
  attr_reader x
  def self.make = A.new(1)   # !> `def self.make` inside `A`: write `def make` (it defines A.make)
end
```

### 同じ名前は 1 度だけ

1 つの名前空間で同じ名前を 2 度定義するのはエラーです。組み込みの操作を再定義するのもエラーです。

```ruby error
def f = 1
def f = 2                    # !> `f` is already defined at line 1
```

```ruby error
def String.upcase(s) = s     # !> `String.upcase` is a built-in operation and cannot be redefined
```

### 値の定数は無い

定数に代入できるのは `Struct.new` だけです。名前付きの値は関数にして（`def pi = 3.14159`）呼びます（`pi`）。`PI = 3.14` は静的エラーで、hint がその関数を示します。`PI` を使う各行にも、`pi` と呼ぶ hint が付きます。1 度だけ計算する値には `once { ... }` があります（[組み込み操作](09-builtins.md)）。

```ruby
def pi = 3.14159
p(pi * 2)                    # => 6.28318
```

```ruby error
PI = 3.14                    # !> Sake has no value constants; a constant names a class (`Point = Struct.new(:x, :y)`, `Err = Exception.new(:msg)`), and a value goes in a function
p(PI * 2)                    # !> `PI` is not defined (Sake has no value constants)
```

## 型付きの呼び出し

`Type.op(args...)` は名前空間 `Type` の操作 `op` を呼びます。慣習として、主語（subject）が第 1 引数です。`Type` と `op` の両方が存在しないとプログラムは実行前に拒否されます。エラーは綴りの候補と、`op` を定義している他の名前空間を示します。

```ruby error
puts(String.upcse("a"))      # !> undefined function `String.upcse`
```

```ruby error
puts(Strng.upcase("a"))      # !> undefined type or module `Strng`
```

```ruby error
puts(Integer.upcase("a"))    # !> undefined function `Integer.upcase`
```

最後の例の hint は `` `upcase` is defined in `String.upcase`, `Symbol.upcase` `` です。

## 連鎖と `_`

一連の操作を左から右・上から下に読める形が 2 つあります。どちらも各段が型を名乗ります。

### 連鎖

`x.T.f(args...)` は `T.f(x, args...)` です。段 `.T` が型かモジュールを名乗り、その左の値が第 1 引数になります。段は続けて書け、次の行の先頭にドットを置くこともできます。

```ruby
line = "a, b ,c"
r = String.split(line, ",")
  .Array.map { |s| String.strip(s) }
  .Array.join("|")
p(r)                         # => "a|b|c"
```

操作の無い `x.T` は静的エラーです。

```ruby error
s = "x"
p(s.String)                  # !> `s.String` needs an operation after the type: `s.String.op(...)`
```

### `_`

`_` は、同じ本体（関数、ブロック、分岐、トップレベル）の**直前の文**の値です。

```ruby
line = "a, b ,c"
String.split(line, ",")
Array.map(_) { |s| String.strip(s) }
Array.join(_, "|")
p(_)                         # => "a|b|c"
```

`_` が指すのが式ではなく文なのは、文が曖昧でないからです。式レベルの `_` は、前の行に含まれる部分式のどれかを選ばなければならず、その選び方に自然な答えはありません。「直前の文」なら 1 つに決まります。

- **最初の文では読めない。** 本体の最初の文や、定義の直後で `_` を読むのは静的エラーです。
- **括弧と補間。** 括弧の中と文字列の補間の中では、最初の文は外側の文の `_` を読みます。
- **名前としての `_`。** `_` は無視する名前としては使えます（`|_, v|`、`a, _ = t`）。ただし、ローカル変数を名付けた `_` は読めません。

```ruby
String.upcase("sake")
puts("got #{_}")             # => got SAKE
Array[1, 2]
p((Array.size(_) + 1))       # => 3
```

```ruby error
def f(x)
  p(_)                       # !> `_` is the previous statement's value, and no statement precedes it here
end
f(1)
```

```ruby error
a, _ = [1, 2]
p(_)                         # !> `_` is the previous statement's value, but here it names a local variable
```

## 値へのメソッド呼び出しは無い

小文字のレシーバを持つ呼び出し、`x.op(...)`、`"lit".op`、`3.times` は静的エラーです。エラーは型付きの形を提案し、1 段なら連鎖の形（`x.T.op(...)`）も提案します。

```ruby error
s = " a "
puts(s.strip.upcase)         # !> method call on a value `s.strip.upcase` is not allowed
```

- **連鎖**は全体を書き直します。`s.strip.upcase` には `String.upcase(String.strip(s))` を提案します。連鎖の形で書くなら `s.String.strip.String.upcase` です。
- **フィールドアクセス**にはリーダを提案します。`p.x` には `Point.x(p)`（または `p.Point.x`）、`p.x = v` には `p.Point.x = v` です。関数のセッタなら `Point.set_x(p, v)` と書きます。
- **リテラルのレシーバ**は候補をそのリテラルの型に絞ります。`"lit".upcase` には `String.upcase("lit")` だけです。
- **`x.nil?`** には `x == nil` を提案します。

```ruby error
Point = Struct.new(:x, :y)
pt = Point.new(1, 2)
p(pt.x)                      # !> method call on a value `pt.x` is not allowed
```

```ruby error
3.times { puts("hi") }       # !> method call on a value `3.times` is not allowed
```

## 型を付けない呼び出し

レシーバ無しの `f(args)` は実行前に解決されます。次の順に探し、最初に見つかったものが勝ちます。

1. 囲んでいる class か module。その組み込みの操作、フィールドの reader と writer、include した関数を含みます。一番内側のものだけで、`A::B` の中から `A` の関数は `A.f(...)` と呼びます（型の名前は関数と違って外側へ探します）。
2. トップレベルの関数。
3. `Kernel`（`puts`、`print`、`p`）。

```ruby
def size(x) = "top-level size"
class Box
  attr_reader items
  def size(b) = Array.size(@items)
  def describe(b) = "#{size(b)} items"   # Box.size
end
b = Box.new(Array[1, 2])
puts(Box.describe(b))        # => 2 items
puts(size(b))                # => top-level size
```

- **隠す。** 内側の定義は外側を隠します。同じ名前が複数の段にあるのはエラーではありません。
- **外側は名前空間付きで。** 外側の定義は常に名前空間付きで呼べます（`Kernel.puts`）。
- **トップレベル。** トップレベルのコードには囲む名前空間が無いので、解決は 2 から始まります。

```ruby
class Logger
  attr_reader prefix
  def puts(l, msg) = Kernel.puts("#{@prefix}#{msg}")
  def run(l) = puts(l, "start")          # Logger.puts
end
Logger.run(Logger.new("> "))             # => > start
puts("done")                             # => done
```

## include

class か module の本体の `include M` は、module `M` の関数を include した側に書き写します。Ruby の module を静的に解決したものです。

```ruby
module Summary
  def total(x) = Array.inject(items(x), 0) { |a, v| a + v }
  def report(x) = "total=#{total(x)}"
end
class Basket
  include Summary
  attr_reader items
end
b = Basket.new(Array[1, 2, 3])
puts(Basket.report(b))       # => total=6
puts(Summary.total(b))       # => 6
```

### 写し

`M` の各関数 `f` は、include した名前空間 `X` の `X.f` になります。`X` が既に `f` を持つならそれが勝ちます。`M` が include した module も写します。

```ruby
module A
  def bar(x) = "A"
  def baz(x) = "A"
end
class C
  include A
  attr_reader v
  def bar(x) = "C"
end
p(C.bar(C.new(1)))           # => "C"
p(C.baz(C.new(1)))           # => "A"
```

### 順序

Ruby の祖先順で探します。**最後**に include した module が先です。`include A` の後に `include B` なら、両方にある `bar` は B のものです。

```ruby
module A
  def bar(x) = "A"
end
module B
  def bar(x) = "B"
end
class C
  include A
  include B
  attr_reader v
end
p(C.bar(C.new(1)))           # => "B"
```

### include 側での解決

写した関数の中の型無しの名前は `X` で解決されます。だから `M` は、`X` が提供する関数（`each` など）を使えます。実行時のディスパッチは無く、各 `X.f` は実行前に固定されます。`X` がクラスなら `@x` は `X` のフィールドです。

```ruby
module Named
  def label(x) = "<#{@name}>"
end
class Cat
  include Named
  attr_reader name
end
puts(Cat.label(Cat.new("tama")))   # => <tama>
```

### 要件

`M` の関数の本体で型を付けずに呼ぶ名前（`each(x)` など）と `@x` のうち、`M` 自身もトップレベルも `Kernel` も定義しないものが、`M` の要件です。宣言はなく、本体から集められます。

- **include 側に無い。** 要件を `X` が持たないと（`each` が無い、フィールド `x` が無い）、`include M` は静的エラーです。どの関数が何を必要としたかを名指しします。
- **直接呼ぶ。** 要件を持つ関数を、include した型を通さずに `M.total(x)` と直接呼ぶのも静的エラーです。hint は include した型を通して呼ぶ形を示します。これは `total` が module 関数のときの話で、mixin 関数の `M.total(x)` は次の節のディスパッチです。

```ruby error
module Summary
  def total(x) = Array.inject(items(x), 0) { |a, v| a + v }
end
class Empty
  include Summary            # !> `include Summary` in Empty: Summary.total needs `items`, which Empty does not define (used at line 2)
  attr_reader v
end
```

```ruby error
module Summary
  module_function
  def total(x) = Array.inject(items(x), 0) { |a, v| a + v }
end
class Basket
  include Summary
  attr_reader items
end
puts(Summary.total(Basket.new(Array[1])))   # !> Summary.total needs `items` from a namespace that includes Summary
```

### 制限

- include できるのは module だけです。class を include するのは静的エラーです。
- include の循環はエラーです。
- **継承ではない。** `include` は部分型関係を作りません。`M` を include した値は、`M` の値になるわけではありません。

```ruby error
class A
  attr_reader x
end
class B
  include A                  # !> `include A`: A is not a module
  attr_reader y
end
```

## module の関数の呼び方: module_function とディスパッチ

型や module の 1 つの名前は 1 つの関数です。Sake には `def f` の隣の `def self.f` はありません。「インスタンス」の形は、値が先に来る（`T.f(x, ...)`）という意味しか持たないからです。Ruby でクラスメソッドとインスタンスメソッドが同名のとき（`Net::HTTP.get(uri)` と `http.get(path)`）は、片方に別の名前を付けるか、1 つの関数が第 1 引数の型で形を見分けます。

module の関数は Ruby と同じく 2 種類あります。

| 種類 | 宣言 | `M.f(args)` |
|---|---|---|
| module 関数 | `module_function` の後、`module_function :f`、または `def M.f` | `M` 自身の `f` が走る（静的） |
| mixin 関数 | それ以外の module の関数 | **ディスパッチ**: 第 1 引数の型の `f` が走る。その型は `M` を include していなければならない |

```ruby
module Describe
  def describe(x) = "#{prefix}#{name(x)}"   # mixin 関数
  def prefix = "* "
  module_function :prefix                   # module 関数
end
class Cat
  include Describe
  attr_reader name
end
class Dog
  include Describe
  attr_reader name
end
p(Describe.prefix)                          # => "* "
puts(Describe.describe(Cat.new("tama")))    # => * tama
puts(Describe.describe(Dog.new("pochi")))   # => * pochi
puts(Cat.describe(Cat.new("tama")))         # => * tama
```

### 主語が無い

mixin 関数は引数無しで呼べません（`M.foo`）。ディスパッチするものが無いからです。どの型も `M` を include していないときに呼ぶのも静的エラーで、`module_function` を使う hint が付きます。

```ruby error
module Greeting
  def hello(x) = "hello"
end
puts(Greeting.hello(1))      # !> Greeting.hello is a mixin function, and no type includes Greeting
```

### 型検査

第 1 引数が取りうる型のすべてが `M` を include することを型推論が検査し、していないものを `type` の問題として報告します。実行時は、include していない型は `TypeError` を投げます。

```ruby error
module Describe
  def describe(x) = "#{name(x)}"
end
class Cat
  include Describe
  attr_reader name
end
Dog = Struct.new(:name)
def pick(flag) = flag ? Cat.new("tama") : Dog.new("pochi")
puts(Describe.describe(pick(true)))   # !> Describe.describe dispatches on its first argument, which can be Dog; the types that include Describe are Cat [type]
```

### 静的な呼び出し

型自身の名前空間は常に静的です。上の例の `Cat.describe(c)` は Cat の `describe`（`Describe` から写したもの）を走らせ、`Describe.describe(x)` がディスパッチする形です。

### Kernel

すべての型は `Kernel` を include します。`Kernel.to_s(x)` と `Kernel.inspect(x)` は型自身の `to_s` / `inspect` にディスパッチし、無ければ組み込みの形を使います。`"#{x}"`、`puts`、`p` はその略記です。

```ruby
class Temp
  attr_reader deg
  def to_s(t) = "#{@deg} C"
end
t = Temp.new(20)
puts(t)                      # => 20 C
puts("now #{t}")             # => now 20 C
puts(Kernel.to_s(t))         # => 20 C
p(Kernel.to_s(5))            # => "5"
```

### 必須の関数

本体が `raise NotImplementedError` だけ（メッセージの有無は問わない）の module の関数は必須です。module を include する各型がそれを定義し、`M.f(x)` はその定義にディスパッチします。ブロックを取るかは型側の定義から決まります。

```ruby
module Shape
  def area(s) = raise NotImplementedError
  def describe(s) = "area=#{area(s)}"
end
class Sq
  include Shape
  attr_reader side
  def area(s) = @side * @side
end
puts(Shape.describe(Sq.new(3)))   # => area=9
puts(Shape.area(Sq.new(2)))       # => 4
```

- **定義しない型。** 定義せずに include した型は、呼び出しが届きうる場所で `type` の問題になり、実行時は `NotImplementedError` です。
- **rescue できない。** `NotImplementedError` はプログラムの誤りで rescue できません。
- **メッセージ。** `raise T` と例外型だけ書くと、型名がメッセージになります。

```ruby error
module Shape
  def area(s) = raise NotImplementedError
  def describe(s) = "area=#{area(s)}"   # !> Shape.area: Blob includes Shape but does not define area, which Shape requires (`raise NotImplementedError`) [type]
end
class Blob
  include Shape
  attr_reader v
end
puts(Shape.describe(Blob.new(1)))
```

## 型を列挙する: `(A|B).f(x)`

`(A|B).f(x, args...)` は、`x` が取りうる型を操作自身に列挙します。実行時は `x` の型が `A.f` か `B.f` を選び、それ以外の型は `TypeError` です。結果は結果の和です。

```ruby
Leaf = Struct.new(:weight)
Node = Struct.new(:weight, :kids)
def weight(t) = (Leaf|Node).weight(t)   # 2 つのクラスの同名のフィールド
p(weight(Leaf.new(2)))                  # => 2
p(weight(Node.new(5, Array[])))         # => 5
def size_of(x) = (String|Array|Hash).size(x)
p(size_of("abc"))                       # => 3
p(size_of(Array[1, 2]))                 # => 2
```

実行前には 2 つのことが検査されます。

- **列挙した型は `f` を持つ。** 持たなければ静的エラーです。
- **列挙にない型は来ない。** 列挙にない型の値が届きうると、検査器が `type` の問題として報告します。

```ruby error
def shout(x) = (String|Integer).upcase(x)   # !> Integer has no `upcase`, so `(String|Integer).upcase` cannot dispatch to it
p(shout("abc"))
```

```ruby error
def size_of(x) = (String|Array).size(x)   # !> (String|Array).size: argument 1 must be String or Array, but is Integer [type]
p(size_of(5))
```

- **列挙できるのは型。** 組み込み型（`IO` も）とクラスを、それぞれ 1 度まで。`nil` は列挙できません。先に nil を検査します。
- **形は違ってよい。** 列挙した関数の形は違っていてよく、ユーザ関数の `*rest` はその分岐のために詰められます（`(IO|StringIO).print(io, a, b)`）。キーワードを取る関数は列挙できません。`case` で型を見分けてください。
- **mixin のディスパッチとの関係。** mixin 関数のディスパッチ `M.f(x)` は、`M` を include するクラスをすべて列挙した `(A|B|...).f(x)` と同じ振り分けです。違いは集合の述べ方で、`include` が各クラスの側で宣言するのに対し、`(A|B)` は呼び出しの場が述べます。だから宣言が要らず、module を共有しない型（組み込み型、同名のフィールド）にも使えます。

## 引数の数とブロック

呼び出し先が実行前に決まるので、引数の数とブロックの有無は実行前に検査されます。

- **引数の数。** ユーザ関数も組み込みの操作も検査されます。
- **ユーザ関数へのブロック。** 関数が `yield` を含む（または `&b` を取る）とき**に限り**ブロックを渡します。ただし `block_given?` を検査する関数はブロック無しで呼べます。
- **組み込みへのブロック。** 組み込みの操作はブロックを必須とするか拒否します。

```ruby error
def area(w, h) = w * h
p(area(3))                   # !> wrong number of arguments for area (given 1, expected 2)
```

```ruby error
def twice(x) = x * 2
p(twice(3) { 1 })            # !> twice does not take a block (it has no `yield`)
```

```ruby error
p(Array.map(Array[1]))       # !> Array.map requires a block
```

### スプラット引数

`*xs` は Tuple か Array を展開します。他の値は `TypeError` です。展開先は rest 引数だけです。組み込みのもの（`puts(*lines)`、`format(fmt, *row)`、`Array[*xs, 0]`、`Set[*xs]`、`Array.push(a, *xs)`）か、ユーザ関数の `*rest`（`join(*parts)`、[関数とブロック](04-functions.md)）です。

```ruby
def join(sep, *parts) = Array.join(parts, sep)
xs = Array["a", "b"]
p(join("-", *xs))            # => "a-b"
t = [1, 2]
p(Array[*t, 0])              # => [1, 2, 0]
puts(*xs)                    # => a
                             # => b
```

- **前の引数は書き切る。** スプラットの前の引数は 1 つずつ書くので、その数は検査されます。
- **静的エラー。** `*rest` の無い関数へのスプラットと、必須か省略可能な引数を埋めるスプラットは静的エラーです。`Array.zip` / `Range.zip`（Tuple の長さが引数の数）と `Hash[...]` へのスプラットも同様です。
- **型推論。** Tuple は位置ごとに展開され、Array は要素型の任意個の引数を表します。

```ruby error
def two(a, b) = a + b
t = [1, 2]
p(two(*t))                   # !> `*t`: splat arguments go only to a `*rest` parameter or to built-ins that take any number of arguments (puts, format, Array[...], Set[...], Array.push, ...)
```
