# 利用感: ベンチマーク 3 本を Sake で書いて、Rust バックエンドを通した

書いたのは loops / fib / levenshtein の 3 本（各 15〜55 行）と、バックエンドの対象範囲を確かめる test/rust/basics.sake・more.sake の 2 本。書き手は Claude Fable 5.1（2026-10-10）。

## 書いていて踏んだもの

- **`ARGV[0]` は書けない。** `undefined type or module ARGV` と出て、hint が `Array.fetch(ARGV, 0)` を示した。hint どおりに直して通った。Ruby 使いの癖で一番最初に踏む。
- **level 4 では `a[i] += v` が通らない**（`index-nil`: `a[i]` が nil かもしれない）。`a[i] = Array.fetch(a, i) + v` に書き直した。ベンチマークの内側のループなので、「外れの nil」を毎回 fetch で言い直すのは冗長に感じる。一方、コンパイラの側ではこの書き方のおかげで要素型が `Integer`（`nil | Integer` ではない）と決まり、Option の箱を作らずに済んだ。level 4 の要求と AOT の都合が一致している。
- **`args[i]` も同じ**で、`levenshtein(Array.fetch(args, i), Array.fetch(args, j))` になった。
- 3 本とも `--strict=4` で通り、インタプリタの出力は Ruby 版と一致した。

## バックエンドを書く側から見た Sake

- **呼び出し先が全部決まっている**（resolver の SakeAST は `call_builtin Array.fetch` / `call_user fn:fib` の形）ので、生成器は名前の解決をしない。組み込みの名前ごとに Rust の式を 1 行書くだけで済んだ。
- **操作に型があるので、値の型が決まらない場所でも呼ぶ先と検査する型が決まる。** `String.to_i(x)` の x が何であれ、ここは String を要求する。この性質のおかげで、型推論は「スロットの型を単相に決める」だけの小さなもの（約 250 行）で済んだ。
- **ブロックが第二級**なのが Rust に向いている。`yield` だけのブロックは `&mut impl FnMut` にそのまま写せ、`Array.each` / `Integer.times` / `Range.each` のブロックはループ本体にインライン展開できる（`break` / `next` / `return` もそのまま Rust の `break` / `continue` / `return` になる）。
- **値が参照**なのは Rust に向いていない。`Rc<UnsafeCell<Vec<T>>>` で写し、「スレッドが無く、要素への参照が 1 操作を越えて生きない」ことを根拠に unsafe で済ませた。最初の版は変数を参照するたびに Rc を clone していて、levenshtein で手書きの 4 倍遅かった（受け手位置では借用するよう直した）。
- **`nil | T` は `Option<T>`** に写り、`if x != nil` の中の絞り込みは生成器側でも要った。typer と同じ規則を別の実装でもう一度書くことになる（typer の結果を流用するほうが筋がいい。今回は typer の出力が式ごとの型を保持していないので自前にした）。

## mixin を足したとき（shapes）

- **mixin の要件は `def area(s) = raise NotImplementedError` で宣言する**ことを、`undefined function Shape.area` のエラーで思い出した。hint は `area` を定義している型（Circle, Rect, Tri）を列挙してくれたが、「module に抽象の def を書け」とは言わない。prelude の `Enum.each` と同じ書き方なので、hint にその形を足すとよい。
- 生成器側では、合併型 `Circle | Rect | Tri` を enum にし、`Shape.area(s)` を `match` にし、`case/in` の `in Circle` で変数を絞り込む、の 3 つで 1 時間弱。resolver のディスパッチ表（型名 → その型の関数）がそのまま `match` の腕になるので、型ごとの関数を実体化して並べるだけだった。
- `case i % 3 in 0 then ... in 1 then ... else ...` のような値のパターンは、既存のプログラムでそのまま出てきたので、PValue / PType / PAlt だけ対応した。Tuple や Record のパターンは未対応。
