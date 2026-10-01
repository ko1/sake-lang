# 2026-10-01 型推論の通り具合（type coverage）

## 問い

型を一切書かない Sake のプログラム（ブロック・`it`・`yield`・Data・配列を含む）に、静的な型推論は素直に通るか。通らないなら、どこで詰まるか。

## 方法

### 推論器（`lib/sake/typer.rb`、`bin/sake --types`）

- 前向きの抽象解釈。
  - 型は atom の union で表す。atom は Integer / Float / String / Boolean / Nil / Data 型 / Tuple / Array@site / unknown。
- ユーザ関数は引数の型ごとに具体化する（Crystal 方式）。
  - `yield` する関数は、呼び出し側ごとに本体を解析する（ブロックは second-class）。
- 配列は、作った箇所（allocation site）ごとに要素の型を持つ。
  - その型は、その site に書き込まれた全ての型の union とする（flow-insensitive）。
- Data のフィールドは、型ごとに、書き込まれた全ての型の union とする。
- ブロックの中から外側の変数への書き込みは、weak update にする（0 回以上回るため）。
  - while とブロックは、環境が変わらなくなるまで繰り返す。
- プログラム全体を、上の表（site・フィールド・返り値）が変わらなくなるまで繰り返し解析する。数えるのは最後の 1 周だけ。
- 解析するのは、到達できるコードだけ。一度も呼ばれない関数は dead として報告する。
- 組み込みの操作の返り値の型は、`builtin_result` に手で書いた。

### 指標

実行時に型タグを検査する箇所（「検査箇所」）ごとに、静的な判定を次の 4 つに分ける。

| 判定 | 意味 |
|---|---|
| proven | 推論した型がすべて期待する型に入る → 実行時の検査を省ける |
| partial | union の一部だけが期待に合う → 検査が残る |
| error | どの型も合わない → 到達すれば必ず失敗する（success typing の報告対象） |
| unknown | 推論が型を決められなかった |

検査箇所は次のとおり。

- 組み込みの操作の引数（`"Any"` の引数を除く）。
- `BinaryOp` の被演算子の組。
- `T[...]` / `Array.push` で型付き配列に書き込む要素。
- 多重代入の右辺。

多相関数では、検査箇所ごとに全ての具体化の判定のうち最も悪いものを採る（ある具体化で必ず失敗するなら error）。

### 健全性の確認（`crosscheck.rb`）

- 各プログラムを実際に実行し、検査箇所ごとに実行時に観測した型を記録する。
- 観測した型が、静的に推論した型に含まれることを確かめる。含まれなければ violation として数える。

**負の対照（`--sabotage`）**
- 推論器をわざと壊し、算術の結果を常に Integer と答えさせる。
- Float を使うプログラムで violation が出ることを確かめる。

### コーパス

- `corpus/*.sake`: 10 本。サブエージェント（Claude）に `brief.md` だけを渡し、10 個の課題を書かせた。
  - 処理系のソースや DESIGN.md は読ませていない。
  - 最初の試行は `corpus/first/` に、手を入れずに残してある。
  - 経緯は `corpus/notes.md` にある。
- `../../test/samples/*.sake`: 13 本。静的エラーで止まるもの（`static_errors` / `typed_array_static` / `ruby_times`）は除いた。
  - うち 8 本は、実行時エラーを意図的に起こすサンプル。

### 環境と再現

- ローカルマシン。性能の計測ではないので、ベンチマシンは使っていない。
- Ruby 4.0.2 (d3da9fec82) +PRISM、Prism 1.9.0。
- 推論器・crosscheck・実験ファイルは、すべて sake リポジトリのコミット「Add experimental type inference and type-coverage experiment」で追加した（親コミットは 1b8c321）。
- 再現は `./run.sh` で行う。`results-*.md` と `types-report.txt` が生成される。
- 解析は決定的で、2 回流して同じ数字になることを確認した。

## 結果

| 構成 | プログラム | proven | partial | error | unknown | violations |
|---|---|---|---|---|---|---|
| narrowing あり（既定） | 23 | 431 | 0 | 8 | 0 | 0 |
| narrowing なし | 23 | 426 | 5 | 8 | 0 | 0 |
| 負の対照（sabotage） | 23 | 424 | 1 | 14 | 0 | **14** |

- コーパスの 10 本だけを見ると、narrowing ありで proven 316 / partial 0 / error 0 / unknown 0 だった。narrowing なしでは proven 311 / partial 5 だった。
- **error の 8 件は、すべて実行時に失敗するサンプル 8 本に 1 件ずつ対応していた。** 正常に動くプログラムでの誤検出（false error）は 0 件だった。
- 健全性の確認での violation は 0 件だった。負の対照では 14 件（`shapes.sake` 7 件、`stats.sake` 7 件）出たので、この確認は壊れた推論を検出できる。
- 解析が止まるまでの周回数は、どのプログラムも 2 周以下だった。
- 表は `results-narrow.md` / `results-no-narrow.md` / `results-sabotage.md`、検査箇所ごとの型は `types-report.txt` にある。

### 型が union になった箇所（narrowing なしで 5 件、すべて `linked_list.sake`）

- `Node.next` に nil が入る（最後のノード）ので、フィールドの型は `nil | Node` になる。
- `while node` の中で `Node.get_value(node)` を呼ぶ箇所が partial になる。
- 真偽で判定した局所変数から nil を除く（narrowing。`if x` / `while x` の、then 側・ループ本体側だけ）と、5 件ともすべて proven になった。

### 最初の試行（`corpus/first/`）について

- 10 本中 8 本が、1 回目の実行で通った。
- 失敗した 2 本は次のとおり。
  - `shapes`: `PI = 3.14...`。値の定数が使えないという静的エラーで、修正案は出ていなかった。
  - `linked_list`: `while node != nil` で実行時エラー。`BinaryOp.!=` の表に `(Node, nil)` の行が無いため。修正案は出ていなかった。
- `first/linked_list.sake` を推論器にかけると、`node != nil` の 3 箇所は **partial** で、error ではなかった。
  - 推論した型は `[nil | Node, nil]` で、`(nil, nil)` の行には当たる。
  - 実際にはループの 1 周目で必ず失敗するが、flow-insensitive な field union ではこれを区別できない。

## 結論

1. **ブロック・`it`・`yield` は、型推論の障害にならなかった。** unknown は 0 件。ブロックが second-class で、呼び出し側ごとに具体化できることが効いている。
2. **型を書かない状態で、小規模なプログラムなら型はほぼ完全に決まった。** 残る穴は nil だけだった。
   - nil を union（`nil | T`）にして、真偽による narrowing を入れれば、このコーパスでは穴が無くなる。これは DESIGN の未決 5（nil）の判断材料になる。
3. **空の `Array[]` も、作った箇所ごとの union で型が決まった。**
   - `bank.sake` では、`Array[]` で作った history をフィールドに入れ、別の関数から push している。それでも要素の型は `[String, Integer]` に決まった。
   - DESIGN §7 は「別名や多相関数を通した push を追う必要があり、実装できない」としていた。これに対し、プログラム全体を allocation site 単位の union で解析すれば、数十行で扱えた。
   - **§7 のこの判断は、少なくとも小規模では撤回の候補。** ただし、下の限界にあるとおり、規模が大きいときの精度は確認していない。
4. **`x != nil` の行が表に無いことは、AI が実際に踏む罠だった。** Ruby の書き方として最も自然な nil の検査が、実行時エラーになる。nil の設計を決めるときに、`(T, nil)` の `==` / `!=` の行を足すかどうかも一緒に決める必要がある。

## 限界（この結果を一般化できない理由）

- **コーパスが小さく、書き手が偏っている。** 10 本・各 20〜60 行で、書いたのは同じ系列のモデル（Claude）が 1 体。
- **書き手は、使える機能が制限された brief を読んで書いている。** nil を返す操作（`first` / `find` / `pop` / 添字）が無いので、union の主な発生源が最初から除かれている。これらを入れたら、partial は増えるはず。
- **フィールドや site 単位の union は、文脈を区別しない。**
  - 多相関数の中で作った配列を、異なる要素の型で使い回すと、型が混ざる。
  - 1 つの Data 型を、場面によって違う型のフィールドで使うと、やはり混ざる。
  - このコーパスにはどちらも無かった。
- **到達できるコードしか見ていない。** 一度も呼ばれない関数の中の誤りは報告されない。
- **組み込みの操作の返り値の型は、手で書いた表による。** 表の誤りは、健全性の確認（観測した型との突き合わせ）でしか捕まらない。また、実行されなかった操作の誤りは捕まらない。

## 訂正の記録

- 最初に crosscheck を流したとき、violation が 47 件出た。
  - 原因は crosscheck 側にあった。`T[...]` / `Array[...]` の要素の検査を、推論器は `"elem"` というキーで記録していたのに、crosscheck は引数の番号で突き合わせていた。
  - 修正後は 0 件になった。推論器の不健全さではなかった。
- 最初の `run.sh` は、除外条件の誤りで `typed_array_static.sake`（静的エラーで止まるサンプル）を含めてしまい、途中で落ちた。除外条件を直して再実行した。

## 追記: nil の設計を入れた後（同日）

この実験を受けて、nil の扱いを次のように決めた（DESIGN.md「実装 v0」）。

- nil は `nil | T` の union にする。
- 絞り込みの形を広げた（`x != nil`、`&&`、早期脱出など）。
- `(T, nil)` の `==` / `!=` を表に足した。

上の「結果」の数字は、コミット 8da5bfc での値である。この後のコミットで `run.sh` を流すと、数字は変わる。

nil の設計を入れた後、`crosscheck.rb` を流し直した結果は次のとおり。

- 対象は 26 本（上の 23 本、`corpus/first/linked_list.sake`、nil のサンプル 2 本）。
- proven 476 / partial 7 / error 8 / unknown 0 / violation 0。sabotage では violation 14 件。

結果の要点:

- **`corpus/first/linked_list.sake`（`while node != nil`）は、そのまま動くようになった。** partial は 0 件で、`x != nil` による絞り込みが効いている。
- **partial の 7 件はすべて、新しく足した nil のサンプルにある。** 内訳は次のとおり。
  - 意図して書いた「確かめずに使う」箇所が 2 件。
  - 実際に nil に当たる箇所が 2 件。
  - `while Node.get_next(n) != nil` の形が 3 件。フィールドの読み出しは絞り込まない規則なので、取りこぼしになる。`--strict` では誤検出として報告される。
