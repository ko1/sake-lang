# Ruby との違いと未対応のもの

## Ruby から Sake へ

| Ruby | Sake | 理由 |
|---|---|---|
| `s.upcase` | `String.upcase(s)`、`s.String.upcase` | 操作に型を書く。値へのメソッド呼び出しは静的エラーで、hint がこの形を示す |
| `p.x`, `p.x = v` | `Point.x(p)`, `p.Point.x = v`（関数の中では `@x`, `@x = v`） | フィールドの読み書きも型を名乗る |
| `def self.f` | `def f`（値が先に来る形は同じ関数）、module では `module_function` | 型の名前空間に 1 つの名前は 1 つの関数 |
| `class B < A`（継承） | `class B < A` は A の定義の書き写し。部分型ではない | 呼び出し先は静的に決まる |
| `attr_reader :x` | `attr_reader x` | フィールド名は裸 |
| `def initialize(x) = @x = x` | `C.new(x)` が格納する。`initialize(c)` は検査と変換だけ | 引数は新しいインスタンス |
| `@items = []`（既定値） | `initialize` の中で `@items = Array[]` | フィールドの既定値は無い |
| `[1, 2]`（伸びる配列） | `Array[1, 2]`。`[1, 2]` は Tuple（長さ固定） | リテラルは形で型が決まる |
| `{a: 1}`（Hash） | `{a: 1}` は Record。Hash は `Hash[a: 1]` | 同上 |
| `PI = 3.14` | `def pi = 3.14`、表は `once { ... }` | 値の定数は無い |
| `Math::PI`, `ARGV`, `$stdout` | `Math.PI`, `ARGV`, `IO.stdout`（操作） | 同上 |
| `case x when Integer` | `case x in Integer` | `===` は無い |
| `x.nil?` | `x == nil` | |
| `$1`, `$~` | `m = String.match(s, re)` の後 `m[1]` | グローバル変数は無い |
| `proc`, `lambda`, `->`, `&:sym`, `method(:f)` | 無し。ブロックは `yield` か `&b` で渡すだけ | ブロックは第二級 |
| `obj.send(:f)`, `define_method`, `method_missing`, `eval` | 無し | 呼び出し先は静的 |
| `f(**opts)` | 無し（Hash を位置で渡す） | 設計判断中（D11） |
| `rescue A` と階層 | `rescue A, B`（階層は無い）。`rescue => e` は全部 | 例外型はクラス |
| `1 + money` | Money に `coerce(m, other)` を定義 | 左のオペランドが決める |
| `Data.define` | `Struct.new` | 名前付き型は可変 |
| `for x in xs` | `Array.each(xs) { \|x\| }` | |
| `%w[a b]`, `%i[a b]` | `String["a", "b"]`, `Symbol[:a, :b]` | |

## 未対応のもの

次はいずれも静的に拒否されます。多くは設計判断を待っています。

- **Record のフィールドへの書き込み。**
- **型スコープ `Integer.(a + b)`。**
- **`case`/`when`**（`case`/`in` を使う）、**`%w[]`、`%i[]`。**
- **`for`**: 今のところ予定なし。`Range.each(1..3) { |i| ... }` のような操作で反復する。
- **パターンの他の形**: Tuple パターンの `*rest`、find パターン、ピン、ガード。
- **入れ子の名前**（`URI::HTTP`。組み込みの定数 `Math::PI` などだけ読める）。
- **第一級のブロック**（ブロックの格納、`proc`、`lambda`）。
- **`f(**opts)`** で集めたキーワードを次に渡すこと。
- **`begin ... end while`。**

## 設計の資料

- `DESIGN.md`（日本語）: 設計の経緯と各決定の理由。
- `TODO.md`: 開いている課題と設計判断（D1〜D13）。
- `experiments/`: 各実験の方法・結果・限界（README 付き）。
