# 言語

この部は、v0 処理系（`bin/sake`）が実装している Sake という言語そのものを、10 章と付録 1 つで述べます。読み手として、Ruby を知っている人と、Ruby を知っている言語モデルを想定しています。構文は Ruby のものなので、この部が説明するのは「Ruby と同じ字面に Sake が与える意味」と「Ruby には無い規則」です。

## 一つの考え

Sake のプログラムは Ruby の構文で書きますが、`name.upcase` とは書かず、`String.upcase(name)` と書きます。型を名乗るのは**操作**だけで、変数・引数・返り値・フィールドには何も書きません。

```ruby
words = String.split("the cat and the hat", " ")
counts = Hash.new(0)
Array.each(words) { |w| counts[w] += 1 }
p(Hash.to_a(counts).Array.sort_by { |w, n| -n }.Array.first(2))   # [["the", 2], ["cat", 1]]
```

この一つの決まりから、言語の性質がほぼすべて出てきます。

- **1 行で呼び出し先が分かる。** `Array.each(words)` はどの `each` か、宣言を探さなくても読めます。連鎖 `x.Array.sort_by { }` も、各段が型を名乗ります。
- **呼び出し先は実行前に決まる。** `String.upcase(s)` は 1 つの関数を名指しします。module の mixin 関数 `M.f(x)`、型の列挙 `(A|B).f(x)`、演算子 `a + b` は第 1 引数の型で 1 つを選びますが、候補の集合（`M` を include する型、列挙した型、演算子の表）は実行前に確定していて、集合の外の型は実行前に報告されます。レシーバで動的に探す仕組み（`method_missing`、リフレクション）は無いので、名前の誤り（`String.upcse`）や引数の数の誤りも、プログラム全体について実行前に報告されます。
- **型は書かずに推論する。** 検査器はプログラム全体の型を推論し、操作に合わない値（`"" + 1`、検査していない nil）を実行前に報告します。どこまで止めるかは `--strict` のレベル 0〜4 で選びます。
- **実行時の検査は残る。** 値は型タグを持ち、すべての操作が引数を検査するので、実行前の検査が見逃したものもその操作の行で止まります。

Ruby と字面が同じでも意味が違うものがいくつかあります。`[a, b]` は Tuple、`{x: 1}` は Record で、Array と Hash は `Array[...]`、`Hash[...]` と書きます。`class` の中の `@x` は「第 1 引数のフィールド x」で、インスタンスの状態ではありません。`class B < A` は A の定義を B に写す略記で、継承ではありません。この部の各章が、そうした違いを一つずつ述べます。

## 章の案内

| 章 | 内容 |
|---|---|
| [概要と実行](01-overview.md) | 4 つの原則、コマンドと終了コード、`--strict` のレベル 0〜4 と各項目（`type`、`nil`、`mixed`、`index-nil`、`exhaustive`、`rescue`、`unrescued`）、静的・実行時エラーの形式。 |
| [プログラムの構造と名前解決](02-program.md) | ファイルと `require`、型付きの呼び出し `T.f(x)`、連鎖 `x.T.f` と `_`、値へのメソッド呼び出しが無いこと、型を付けない呼び出し（自分の関数、`puts`、`p`）、`include`、`module_function` とディスパッチ、型の列挙 `(A\|B).f(x)`、引数の数とブロック。 |
| [値と型](03-values.md) | 値の表示、Tuple・Record・Array の区別、Hash と Set、nil と `nil \| T` の絞り込み、Ruby の他の型（Symbol、Range、Regexp、Time、Rational、Complex）。 |
| [関数とブロック](04-functions.md) | 注釈の無い多相な関数、省略できる引数とキーワード、`yield` で渡すブロック、`once`。 |
| [演算子と添字](05-operators.md) | `a + b` は `Arithmetic.+(a, b)` の略記で、左のオペランドの型に解決されること、`Arithmetic`・`Comparable`・`Bitwise`・`Indexable` を include して自分の型に演算子を与えること、`a[i]` と `a[i] = v`。 |
| [制御構造とパターン](06-control.md) | `if`・`while`・`case`/`in`、`x in T` による絞り込み、`case` の網羅性の検査。 |
| [クラス](07-classes.md) | `class` と `attr_*` による型の宣言（`Struct.new` はその略記）、`@x` の意味、`initialize`、`class B < A`、構築場所ごとに 1 つの型。 |
| [例外とエラー](08-exceptions.md) | `raise`・`rescue`・`ensure`・`retry`、例外型の宣言、関数から漏れる例外の推論、静的エラーと実行時エラーの種類。 |
| [組み込み操作](09-builtins.md) | 約 550 の組み込み操作の概観（名前は Ruby の core と同じ）と型付き Array `T[...]`。各操作の正確な署名と例は[組み込みリファレンス](part-reference.md)に。 |
| [ライブラリ（sakelib）](10-library.md) | 標準添付ライブラリと gem の移植、minitest、テストの書き方。 |
| 付録 [Ruby との違いと未対応のもの](a1-ruby.md) | Ruby の書き方から Sake の書き方への対応表、未対応の構文と機能、設計の資料。 |

## 読み方

- **Ruby を知っていて書き始めるなら**、[概要と実行](01-overview.md)、[プログラムの構造と名前解決](02-program.md)、[値と型](03-values.md)、[演算子と添字](05-operators.md)の順に読み、付録の対応表を手元に置くと、ほとんどの静的エラーの意味が分かります。クラスを宣言するときに[クラス](07-classes.md)を読んでください。
- **言語モデルに書かせるなら**、この部の規則を 4 ページに圧縮した [cheatsheet.md](https://github.com/ko1/sake-lang/blob/main/docs/cheatsheet.md)（約 1 万トークン）を渡します。順を追った入門は [tutorial.md](https://github.com/ko1/sake-lang/blob/main/docs/tutorial.md) です。
- **試すなら**、[playground](https://ko1.github.io/sake-lang/playground/)がブラウザで動きます。補完、入力中の診断、ホバーで推論された型が見られます。
- **約束。** 例の中の `# 値` は `bin/sake` の実際の出力です。「静的エラー」は実行前に報告され何も走らないもの、「実行時エラー」はその操作で止まるものを指します。「レベル n」は `--strict=n` のことです。
