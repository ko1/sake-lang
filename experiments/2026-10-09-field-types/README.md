# フィールドの型はどこで決まっているか（2026-10-09）

設計の問い（DESIGN.md「双方向の推論」）: v0 の typer はフィールドの型を全プログラムの書き込みの union にするので全体解析になる。
「`T.new(x, y)` の引数の型だけで決め、あとの書き込み（`T.set_x`、関数の中の `@x = v`）は照合する」規則にしたら、
全体解析はどれだけ減り、既存のコードの書き方とどれだけ衝突するか。

## 方法

対象は P10 の SQL エンジン 2 本の段階 6（`experiments/2026-10-05-ai-writability/runs/p10-sake-{1,2}/stage-6/code`、
Sonnet 5.5 が書いたもの。sake-1 は `class` + `attr_reader`、sake-2 は `Struct.new`）。検査器は commit `463a6174`（YJIT 込み）。

- `bin/sake --types main.sake > types-sake-N.txt`: v0 の推論結果（フィールドの型の一覧を含む）。
- `classify_fields.rb types-sake-N.txt`: フィールドの型を「1 つ / nil|T / union（nil 以外が 2 つ以上）/ union+nil」に分ける。
- `count_writes.rb CODE_DIR`: Prism で歩いて、`initialize` の外の `@x = v`、`T.set_x(...)` の呼び出し、`T.new` の地点数と実引数の種類を数える。
- `nil_fields.rb CODE_DIR`: 全 `new` 地点で nil リテラルしか渡されないフィールドと、そのうちあとで書かれるもの（規則の衝突点）。

## 結果

| | sake-1 | sake-2 |
|---|---|---|
| フィールド | 271 | 216 |
| 型が 1 つ | 156 | 120 |
| nil \| T | 24 | 19 |
| union（nil 以外が 2 つ以上） | 64 | 65 |
| union + nil | 27 | 12 |
| 相異なる union | 34 | 59 |
| `new` の地点 | 260 | 189 |
| `new` の実引数: literal / local / `T.op(...)` / 他の呼び出し | 189 / 244 / 160 / 58 | 344 / 211 / 172 / 24 |
| `initialize` の外の `@x = v` | 8（6 フィールド） | 0 |
| `T.set_x(...)` の呼び出し | 5（1 フィールド） | 20（12 フィールド） |
| 全 `new` 地点で nil、あとで書かれる（衝突） | 1: `Database.saved` | 2: `SelectStmt.limit`, `.offset` |

union の正体は AST のノード型の合併（Struct 型は値にタグがあるので実質は直和）。sake-1 では式の union（Struct 型 14〜18 個）が 28 フィールド、文の union が 9 フィールドに現れる。

## 結論

- **外からの書き込みは問題ではない。** `set_x` と `initialize` 外の `@x =` は合わせて 13 と 20 回で、生成時の型に合わないのは 3 フィールド
  （nil で作って後から入れる `Database.saved`、`SelectStmt.limit/offset`）。規則にすればこの 3 つが型エラーになり、生成時に型を言う必要がある。
- **全体解析はほとんど減らない。** 全体性の源は `new` の地点そのもの（260 と 189、プログラム中に散在）で、実引数の大半はローカル変数と
  関数呼び出しの結果。その型を知るには囲む関数の推論が要り、それは他の関数の返り値（フィールドの読み出しを含む）に依存するので、不動点は残る。
  規則が変えるのは「広げる書き込み」が「照合する書き込み」になる 13 と 20 回分だけ。
- **union は本物。** フィールドの 3 分の 1 は 2 つ以上の Struct 型を持ち、`ResultColumn.new(col)` と `ResultColumn.new(binary)` が別の場所にある
  だけで生じる。単一化で局所にするには合併を名前で宣言する（OCaml の variant）しかなく、それは union か nil を持つフィールド（3 分の 1）に
  型を書くことになる。
