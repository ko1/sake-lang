# クラス

プログラムが定義する型はクラスです。`class` に `attr_*` の行で宣言しても `Struct.new(:x, :y)` で作っても同じもので、値はフィールドを持ち（Ruby の Struct の値として `#<struct Point x=3, y=4>` と表示されます）、操作は `Point.norm2(pt)` と型を付けて呼びます。クラスは継承せず、値へのメソッド呼び出しも無いので、Ruby の class と重なるのは「型を宣言し、その操作をまとめる」ところです。

## 型の宣言: class と attr_*

```ruby
class Account
  attr_reader owner
  attr_accessor balance
  def initialize(a)
    @balance = 0 if @balance == nil
  end
end
```

すべての `class` は型です。フィールドは最初の `class` の本体で宣言します（後の `class Account` は関数を足すだけ）。フィールド名は裸で書きます。

| 行 | 意味 |
|---|---|
| `attr_accessor x, ...` | リーダ `C.x(c)` とライタ `C.set_x(c, v)` を持つフィールド |
| `attr_reader x, ...` | リーダだけ。型の関数の中では `@x = v` で書ける |
| `attr_writer x, ...` | ライタだけ。型の関数の中では `@x` で読める |
| `private attr_... x` | リーダとライタはそのクラス自身の関数専用（どの値のものでも: `@x`、または `T.x(other)`）。`new` は受け取る |

- **フィールドの順序。** 書いた順で、`C.new` の引数の順です（行をまたいでも）。
- **`new`。** `C.new` はアクセスの種類に関わらずフィールドを位置で、または名前で取ります（フィールドが複数ある型では名前を勧めます。位置の `new` はフィールド順と照合されません）: `Logger.new(io, level: :warn)` は最初のフィールドを位置で、`level` をキーワードで与えます（未知の名前と二重指定はエラー）。`initialize` が無ければ全フィールド必須。あれば後ろのフィールドを省略でき（後のキーワードのために飛ばすこともでき）、省略分は initialize が始まるとき nil で、initialize が設定します。Ruby の `@items = []` と同じです（`@level = :info if @level == nil` は `new` が与えた値を保つ）。例外型の `message` より後のフィールドは常に省略できます（`raise E, "msg"` はメッセージだけ与える）。
- **既定値は無い。** `attr_reader items = Array[]` はエラーです。フィールドの最初の値は、新しいインスタンスごとに走る唯一の場所 `initialize` で設定し、そこで他のフィールドを読めます（`@len = String.bytesize(@src)`）。検査器は initialize を通してフィールドを追うので、常に設定されるフィールドはその後 nil ではありません。
- **予約語。** 予約語と同じ名前のフィールドは Symbol で宣言します: `attr_accessor :next`（裸では解析できない）。リーダは `Node.next(n)`、`@next` はいつもどおりです。
- **`initialize`。** class の `def initialize(c)` は、`C.new` がフィールドを格納した後に新しいインスタンスを受けて走ります。最初の値（`@items = Array[]`）、検査（`@port => Integer`）、変換（`@celsius = Float(@celsius)`）の場所で、Ruby と同じです。引数はその 1 つだけで、`C.initialize` を直接呼ぶのはエラーです。検査器は各 `C.new` の呼び出しごとに解析し、そこで `@x` はその呼び出しが与えた値を読むので、誤った引数はその呼び出しについて報告されます。フィールドは initialize が残したものを持ちます。

> [!WARNING]
> Ruby の `def initialize(x) = @x = x` は Sake では静的エラーです。`x` は新しいインスタンスであって値ではなく、自分を自分のフィールドに入れることになります。`C.new(...)` が既にフィールドを格納しているので、initialize は検査と変換だけを書きます。

- **構築ごとに 1 つの型。** 検査器にとって、各 `C.new` はそれ自身の型です。別の場所で作ったインスタンス（または、`expect(42)` と `expect("x")` のように別の引数型で呼ばれた関数の 1 つの場所）はそれぞれのフィールド型を保つので、Integer の `Heap` と Job の `Heap` は混ざらず、汎用の包み（`Result.map` の `Ok.new(yield(@value))`）は呼び出し元ごとに 1 つの型です。メッセージは、型に複数の場所があるときだけ場所付きで名乗ります（`Heap@L7`）。値から値を作る関数（Value を取る関数の中の `Value.new(a + b)`）は場所ごとに 1 つの型にとどまります。
- **`class B < A`。** A の定義を B に書き写す略記です。A のフィールドが先（次に B の）、A の関数は B の関数でもあり（型無しの名前と中の `@x` は B のもの）、A の `include` は B のものです。B 自身の定義が A のものに勝ちます。その後 A と B は無関係で、B は A ではなく、`A.f(b)` は型エラーです。`<` はプログラムの class（または `Struct.new` の型）を取り、module は `include` します。
- **`class E < Exception`**（または `< StandardError`）は例外型を宣言します。`message` が最初のフィールドで、その後に `attr_*` の行のフィールドが続きます。
- **`Struct.new(:x, :y)`。** `attr_accessor x, y` を持つ `class C` の略記です。Ruby の形 `class C < Struct.new(:x, :y)` も書け、そのフィールドが先、本体の `attr_*` 行と関数が後に来ます。
- **`Exception.new(:line)`。** `attr_accessor line` を持つ `class C < Exception` の略記です。
- **エラー。** `attr_reader :x`（Symbol）、後の `class C` でのフィールド、既定値、読み出し専用フィールドへの外からの書き込みは静的エラーです。古い形 `class C < {reader: [...]}` はエラーで、hint が `attr_*` の行を示します。

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

- **可変性。** 値は可変で、参照で共有されます。ある変数を通した変更は、同じ値を持つ他のすべての変数から見えます。
- **操作を足す。** `class Point ... end` か `def Point.f` で自分の操作を足します。その中ではリーダとライタを型無しで呼べます（`x(p)`、`set_x(p, v)`）。フィールドと同名の関数（`def x(p) = ...`）は、Ruby で attr_reader の後にメソッドを定義したのと同じくリーダを置き換えます。`@x` は常にフィールドを読みます。
- **フィールドの略記 `@x`。** クラスの関数（`class Point` の中、または `def Point.f`）の中で、`@x` は関数の**第 1 引数**（慣習として主語）のフィールド `x` です。

  | 書いたもの | 意味 |
  |---|---|
  | `@x` | `Point.x(p)` |
  | `@x = v` | `Point.set_x(p, v)` |
  | `@x OP= v` | `Point.set_x(p, Point.x(p) OP v)` |
  | `@x \|\|= v` | `Point.x(p) \|\| Point.set_x(p, v)` |

  - `p` は第 1 引数の今の値で、同名の引数を持つブロックの中でも変わりません。
  - 通常の実行時検査がかかります。第 1 引数は Point でなければなりません。
  - `@x` は次の場合に静的エラーです: クラスの関数の外、引数の無い関数、フィールドが存在しないとき。
- **印字。** `p` は Struct 値を `#<struct Point x=1, y=2>` と印字します。`puts` も同じです。
- **`Struct.new` の制限。** トップレベルの定数に代入しなければなりません。Symbol だけを取り、ブロックは取りません。
- **`Data.define` は無い。** `Struct.new` を使う hint 付きで拒否されます。Ruby の `Data` は不変ですが、Sake の名前付き型は可変で、それは Ruby の `Struct` が提供するものです。
- **`Kernel.dup(x)`。** 浅い複製（新しい容器と Struct 値、同じ要素）。型が `dup` を定義していればそれが呼ばれます。
