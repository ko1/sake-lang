# 2026-10-01 型推論は、いろいろなプログラムでどこまで決まるか（500 本）

結論の解説ページ（artifact）: <https://claude.ai/artifact/BeRhEirMeBWWwuGLSng3BG>（`report.html`）

## 問い

型を一切書かない Sake のプログラムに対して、操作に書いた型だけから、推論器はどこまで型を決められるか。
同じ課題を Ruby で書いたものに対する TypeProf（注釈なしの Ruby の型推論器）と比べてどうか。

前回（`../2026-10-01-type-coverage/`、10 本）の弱点：本数が少なく、brief で添字・nil を返す操作・Hash を禁じていた。今回はそれを外した。

## 方法

### コーパス（`corpus/`、500 本 × Sake と Ruby）

- 20 の分野（`domains.md`）× 25 課題。1 分野を 1 体の書き手エージェント（Claude）が担当し、課題も自分で考えた。指示は `brief.md` と `writer-prompt.md`。
  - 書き手が読めるのは `docs/`（tutorial・spec・builtins）だけ。処理系のソース・DESIGN.md・他の分野は読ませていない。
  - **書き手は `--strict=0`（実行前の型検査なし）で実行させた。** 推論器の出力を見て書き直すと、計測対象に合わせたコーパスになるため。
  - 各課題は Sake 版 `.sake` と Ruby 版 `.rb`（慣用的な Ruby。レコードは `attr_accessor` の class）を書き、出力が完全に一致することを確かめた（`.out`）。
  - 書き手が詰まった点は各分野の `NOTES.md`、集計は `notes-tally.md`。
- 規模：Sake 56,376 行、Ruby 60,493 行。1 本あたり Sake で 41〜262 行（多くは 70〜200 行）。
- 試行の前に、2 分野 × 4 本の試作（`pilot/`）で brief と計測の流れを確かめた。

### 指標

推論した型を「構造的な型」（配列の allocation site を落とし、`Array@L3[Integer]` も `Array@L5[Integer]` も `Array[Integer]`）に直し、悪い順に分類する（`classify.rb`）。

| 分類 | 意味 |
|---|---|
| unknown | 推論器が型を諦めた |
| partial | 中に unknown がある（`Array[?]`） |
| union | どこかに nil 以外の型が 2 つ以上（`Integer \| Float`） |
| nilable | どこかに `nil \| T`、それ以外は 1 つ |
| mono | 全体が 1 つの型 |

「決まった（determined）」= mono + nilable + union（unknown をどこにも含まない）。

計測の単位（`measure.rb`、`typeprof_measure.rb`）：

| 単位 | Sake | TypeProf |
|---|---|---|
| expr.var | ローカル変数・`@x` の読み（全具体化の union） | なし |
| expr.call | 呼び出し・演算子・添字・`yield` の結果 | なし |
| sig.param | 到達した関数の引数（具体化の union。Struct の関数の第 1 引数（自分）は除く） | メソッドの引数（`initialize` と attr の writer を除く） |
| sig.ret | 関数の返り値 | メソッドの返り値 |
| sig.field | Struct のフィールド | `attr_reader` / `attr_accessor` の型 |

Sake と TypeProf は単位が 1 対 1 に対応しない（呼び出されない Ruby のメソッドも TypeProf は報告する、など）。割合で比べる。

ほかに測ったもの：
- **実行前の検査の誤報**：全プログラムが正しく動くので、strict の各レベル（1〜4）で止められたプログラムはすべて誤報。TypeProf の `--show-errors` も同様に全部誤報。
- **健全性**（`crosscheck.rb`）：実行して、検査箇所ごとに観測した型と組み込みの操作の結果の型が、推論した型に含まれるかを確かめる。負の対照（`--sabotage`：算術の結果を常に Integer と答える壊れた推論器）で違反が出ることも確かめる。
- **振り分けの需要**：Ruby 版を TracePoint 付きで実行し（`polysites.rb`、`tools/receiver_trace.rb`）、受け手のクラスが 2 つ以上になった呼び出し（行・メソッド）を数える。Sake 版では、`case x in T` / `if x in T` の枝で同じ名前の操作を別の型で呼んでいる箇所を数える（`sake_dispatch.rb`）。

### 計測した版

| 版 | commit | 内容 |
|---|---|---|
| baseline | tag `inference-500-baseline`（aa45ff0） | 試作の前の推論器（表示の無限再帰だけ直した） |
| HEAD | 2fd8886 | 試作で見つけた弱点を直した版：user の `<=>`/`==` の解析、`Exception.message`、`String.scan` のグループ、組み込みの操作の引数による絞り込み、添字の型の検査の分離 |
| fixed | branch `sakeast` の d2469d0 | 推論器を SakeAST に移し（出力は 568 本すべてで移植前と一致）、健全性の穴 7 つを直した版 |

TypeProf 0.31.1、Ruby 4.0.2 (d3da9fec82)。TypeProf は 1 本 120 秒・アドレス空間 3 GB で打ち切った（無制限だと 15 分以上・9 GB 超になるものがあった）。
ローカルマシン（16 コア、他の作業と共有、load average 10〜45）。性能の計測ではない。再現は `./run.sh corpus OUT`（`J=` 並列数、`REUSE=DIR` で TypeProf と Ruby 側の結果を流用）。

## 結果

### 1. 型推論の決まり具合（fixed、500 本）

| 単位 | n | mono | nilable | union | partial + unknown | determined |
|---|---|---|---|---|---|---|
| expr.var | 57,645 | 80.6% | 13.2% | 5.5% | 0.6% | 99.4% |
| expr.call | 61,718 | 80.8% | 13.7% | 3.9% | 0.4% | 99.6% |
| sig.param | 5,183 | 79.4% | 11.7% | 8.4% | 0.5% | 99.5% |
| sig.ret | 4,317 | 77.2% | 15.0% | 6.7% | 1.0% | 99.0% |
| sig.field | 2,859 | 82.5% | 13.3% | 4.1% | 0.1% | 99.9% |

（mono 等の割合は none（到達しないコード）を含む全体に対するもの、determined は到達した単位に対するもの）

- 実行時に型を検査する箇所 55,632 のうち、proven（検査を省ける）51,351（92.3%）、partial 3,775、error 431、unknown 75。
- 推論が止まらなかった（30 周で収束しなかった）プログラムは 0。到達しない関数は 87。

### 2. TypeProf との比較（TypeProf が完走した 451 本）

| 単位 | Sake mono | Sake determined | TypeProf mono | TypeProf determined |
|---|---|---|---|---|
| 引数 | 79.1% | 99.9% | 72.2% | 90.5% |
| 返り値 | 77.1% | 99.4% | 71.8% | 91.5% |
| フィールド | 82.1% | 99.9% | 76.7% | 92.0% |

- **TypeProf は 49 本で結果を出せなかった**（120 秒の打ち切り 38、メモリ 3 GB 超 9、内部エラー `unknown type variable: Return` 2）。上の表はこれらを除いた 451 本なので、TypeProf に有利な選び方になっている。
- TypeProf の `untyped` がどこから来るかの内訳は、まだ分析していない（`results-head/typeprof.jsonl` の detail にある）。Sake は呼ばれない関数を数えない（87 個）が、TypeProf は呼ばれないメソッドも引数 `untyped` で報告する。単位は 1 対 1 ではない。
- **誤報**：TypeProf は 391 本で 3,331 件のエラーを報告した（全部誤報。`wrong type of arguments` 403、`failed to resolve overloads` 386、`undefined method: nil#[]` 181 など、主に nil の可能性）。

### 3. 版ごとの変化

| | baseline | HEAD | fixed |
|---|---|---|---|
| expr（mono / determined / partial+unknown の数） | 80.8% / 98.3% / 1,987 | 82.0% / 99.8% / 295 | 81.2% / 99.5% / 621 |
| sig（同） | 79.4% / 98.5% / 188 | 79.9% / 99.6% / 51 | 79.4% / 99.4% / 71 |
| 検査箇所 proven / partial / error / unknown | 47,762 / 3,883 / 594 / 331 | 51,239 / 3,743 / 446 / 40 | 51,351 / 3,775 / 431 / 75 |
| **健全性の違反** | **585** | **173（17 本）** | **0** |
| 負の対照の違反 | 2,306 | 1,975 | 1,734 |
| level 1 で止められた正しいプログラム | 192 | 178 | 180 |

- **baseline と HEAD の推論器は健全ではなかった。** 違反の原因は 7 つ（すべて試作より前からあった）：Set の演算子の結果に要素が無い、空の集まりの `sum` が Integer 0 になることを見ていない、`Array[...]` の要素の型が最初の解析の分しか残らない、引数 2 つのブロックで Tuple 以外を含む要素を分解しない、`Tuple[...]` の要素の中身を持たない、`while` の `break`/`next` の直前の変数がループの後に伝わらない、unknown の値に対する `case/in` が全部の枝を飛ばす。どれも「型が空（bottom）になり、その先を解析しない」形で、決まり具合の数字を良く見せていた。
- fixed で unknown が増えた（295 → 621）のは、それまで解析されていなかったコードが解析されるようになったため。

### 4. 実行前の検査の誤報（fixed）

| level | 止められたプログラム | 診断 |
|---|---|---|
| 1 | 180 / 500 | 453 |
| 2 | 357 / 500 | 1,643 |
| 3 | 469 / 500 | 3,991 |
| 4 | 477 / 500 | 4,206 |

level 1 の 453 件の内訳：
- `case/in` の網羅性 159 件。うち **112 件は Symbol の値に対する `case op in :add ... in :sub` で `else` が無いもの**。値の集合が閉じていないので網羅を証明できないが、プログラムは正しい。
- Struct の getter / setter 66 件（`argument 1 must be Cons, but is nil` など、nil やほかの型の具体化）。
- 添字 33、比較 `<` 26、`==` 24、算術 41 など（union の値への演算）。

→ level 1 を既定にするなら、リテラルの `case/in` の網羅性は別の項目（もっと高い level）に分けるべき、という判断材料になる。

### 5. 振り分けの需要（`(A|B).op(x)` の材料）

Ruby 版で、受け手のクラスが 2 つ以上だった呼び出し（nil を除く）：

| 分類 | 箇所 | プログラム | Sake では |
|---|---|---|---|
| 演算子・`[]` | 398 | 212 | すでに左の値の型で振り分け |
| `to_s` / `inspect` など | 112 | 46 | Kernel の関数 |
| 例外 | 6 | 4 | `Exception.message` |
| ユーザ定義のクラスだけ | 119 | 23 | module の振り分け（`Shape.area(s)`） |
| 組み込みのクラスだけ | 74 | 66 | **`(Array\|String).size` の形が要る** |
| 混在 | 9 | 8 | 同上 |

組み込みのクラスの内訳：`(Array|String).size` 19、`(Array|Hash).size` 16、`(Array|Range).map` 14、`(Array|Set).size` 6、…

Sake 版では、手で型を分けて同じ名前の操作を呼んでいる箇所が 24（16 本）、module の振り分けを通る呼び出しが 223（30 本）。Ruby で組み込みのクラスが混ざる 74 箇所を、Sake の書き手がどう書いたか（手で分けた・値の流れを変えた）の対応付けは、まだしていない。

### 6. 書き手が詰まった点（`notes-tally.md`）

上位：Tuple の順序（50 本）、値の定数が無い（≥37）、Array からの多重代入（≥34）、Tuple/Array/Set の `==`（≥30）、単項マイナス（≥29）、ブロック内の `break`（≥27）、Enumerator の連鎖（≥25）、`Array.new`（≥24）、遅さのために入力を縮めた（22）。

### 7. 結果を受けた言語の変更の後（v2、2026-10-01 夜）

報告の 8 節の提案（ko1 が採用）を入れた版で測り直した（`results-v2/`。TypeProf と Ruby 側の結果は `results-head/` と同じなので流用）。
入れたもの：Tuple・Array・Set・Hash・Record の中身での `==` と Tuple・Array の順序、単項演算子、Array からの多重代入、`(A|B).f(x)`、Symbol のリテラルの値としての追跡、`case/in` の網羅性の検査の分割（値の集合が開いた型は新しい項目 `exhaustive`、level 3）。

| | fixed | v2 |
|---|---|---|
| level 1 で止められた正しいプログラム | 180 / 500（診断 453） | **108 / 500（診断 311）** |
| うち `case/in` の診断 | 159 | 16 |
| level 2 / 3 / 4 | 357 / 469 / 477 | 321 / 456 / 464 |
| 健全性の違反 / 負の対照 | 0 / 1,734 | 0 / 1,734 |
| 型が決まった割合 | （変化なし） | （変化なし） |

- Symbol の `case` の多くは、Symbol のリテラルを値として追跡したことで網羅を証明できた（level 1 の `case/in` は 159 → 16、`exhaustive` に移ったのは 39 件・33 本）。level 1 に残る `case/in` は主に Boolean や nil を含む union。
- コーパスはこれらの機能を使わずに書かれているので、決まり具合の数字は変わらない。新しい機能がどれだけ書き手を楽にするかは、書き手に書き直させないと測れない（未実施）。
- 測り直しの途中で、ブロックの引数の分解の変更のバグ（Tuple の最初の要素が Array だと、もう一度分解していた）を、出力の変わった 5 本から見つけて直した。

### 8. 新しい機能で書き直させた後（corpus-v2、2026-10-02）

各分野の書き手に、自分の分野の Sake 版を「今の Sake で自然に書く形」に書き直させた（指示は `brief-v2.md`。アルゴリズムと出力は同じ、Ruby 版は変えない、`--strict=0` で実行）。各分野の `CHANGES.md` に変更点、`NOTES.md` に残った難点がある。比較は `corpus_diff.rb`（結果 `corpus-v2-diff.md`）、計測は `results-v3/`（v2 と同じ処理系）。

- 500 本のうち 337 本が変わった。コードの行数は 50,181 → 49,885（-0.6%）。
- 新しい機能の使用（構文で数えた）：単項演算子 167 箇所（130 本）、`!x` 102、Tuple のソートキー 83（74 本）、多重代入（右辺が呼び出し）376 → 423、`(A|B).f` 29（15 本）、連鎖 `x.T.f` 18（7 本）、`_` 1。
- 回避策：`0 - x` 115 → 1、`x == false` 130 → 0、`format("%0..")` のソートキー 173 → 136、split の直後の `x[0]` 21 → 17。
- 書き手は連鎖と `_` をほとんど使わなかった（「元の入れ子が短い」「書き換えると形が変わる」）。`(A|B).f` は、mixin の module と転送用の関数、型で分ける `case` を置き換えた。

| | v2（書き直す前） | v3（書き直した後） |
|---|---|---|
| 変数の読み mono / nilable | 80.6% / 13.2% | 81.2% / 12.6% |
| 引数 mono | 79.4% | 80.4% |
| level 1 で止められた正しいプログラム | 108 | 106 |
| 健全性の違反 / 負の対照 | 0 / 1,734 | 0 / 1,701 |

- 新しい機能は主に書きやすさに効き、型の決まり具合はわずかに上がっただけ（nilable が減ったのは、split の結果を添字（nil になりうる）でなく多重代入（要素の型）で取り出すようになったため）。
- 書き手が残った難点として多く挙げたもの：要素の入れ替え `a[i], a[j] = a[j], a[i]`、入れ子の分解の引数 `|(a, b), i|`、Array の `+`、`Array.new(n, v)`、ブロックの中の `break`、splat、長さの変わる `split` の結果の多重代入（Ruby は nil で埋める）、2 引数の添字、型の違う組み込みの値の `==`。

### 9. 残りの機能を入れた後（results-v4、2026-10-02）

8 節で書き手が挙げた難点を入れた処理系（commit b5156d3）で、corpus-v2 をそのまま測り直した（`REUSE=results-head ./run.sh corpus-v2 results-v4`）。入れたもの：多重代入とブロックの分解を Ruby に合わせる（足りない要素は nil）、要素の入れ替え、`|(a, b), i|`、Array の `+ - *`、`Array.new(n, v)`、ブロックの中の `break`、splat、2 引数の添字、型の違う値の `==` は false、Struct・Array・Hash・Set を Hash のキーに、Comparable の `==`、`raise NotImplementedError` で示す必須の関数。コーパスはまだこれらを使って書き直していない。

| | v3 | v4 |
|---|---|---|
| 変数の読み mono / nilable | 81.2% / 12.6% | 80.0% / 13.8% |
| 引数 mono | 80.4% | 78.9% |
| determined（変数の読み） | 99.4% | 99.4% |
| level 1 で止められた正しいプログラム（診断） | 106（307） | 106（280） |
| level 3 | 451（3,702） | 457（3,910） |
| 健全性の違反 / 負の対照 | 0 / 1,701 | 0 / 1,701 |
| 実行（Ruby 版・`.out` と一致） | 500 / 500 | 500 / 500 |

- mono の低下は、多重代入の変更による。Array から取り出した変数は、要素が足りなければ nil になるので `nil | T`（index-nil）になった。v3 で mono・v4 で nilable になった変数の読み 668 箇所のうち、517 箇所は多重代入かブロックの分解の変数そのもので、残り 151 箇所もその値を入れた Hash のキーなどへの伝播だった（`tools/nilable_attr.rb`）。level 3 の増加（+6 本）も同じ理由。`x[k]` と同じ扱いにするという決定どおりの結果で、推論が弱くなったのではない。
- level 1 の診断は 307 → 280 に減った（止められた本数は変わらず）。どの変更が効いたかの内訳は取っていない。
- 書き直させれば（`Array.new`、`break`、入れ替えなどを使えば）回避策が減るはずだが、その計測はしていない。

### 10. level 1 の誤報の解析と、推論器の修正（results-v5 / v6、2026-10-02）

v4 の level 1 の診断 280 件（106 本。どれも正しいプログラムなので全部誤報）を、1 件ずつコードを読んで、実行時には来ない型がどこから来たかで分類した（`level1-analysis/`）。

**分類の定義**（実行時に来ない型の出どころ）
- typer-bug：推論器の誤りか不要な不精密（下記の 6 件）。
- shared-site-merge：無関係な 2 つの使い方が、1 つの生成箇所（site）・フィールド・関数の具体化を共有して型が混ざる（関数は呼び出しの型ごとに解析するが、関数の中で作る Array / Hash は 1 つの site）。
- heterogeneous-container：Array / Hash に複数の型の値が入り、どの位置に何があるかはプログラムの構造だけが知っている（JSON・Lisp の値、`[:copy, Integer]` と `[:literal, Array]` のようなタグ付きの Tuple）。
- path-correlation：別の変数（フラグ・長さ・`i > 0`）で除かれている型を、推論器が結び付けられない。
- numeric-mix：Float の Array の `sum` が Integer にもなる（空なら Integer の 0。Ruby でも同じなので推論は正しい）。

| 分類 | 件数（v4） | 修正後（v6） |
|---|---|---|
| typer-bug | 94 | 5 |
| shared-site-merge | 68 | 68 |
| heterogeneous-container | 68 | 67 |
| path-correlation | 27 | 19 |
| numeric-mix | 23 | 23 |
| 計 | 280 | 182 |

**直した推論器の誤り**（どれも小さな再現で確かめてから直した。コミットごとの数は `level1-analysis/by_commit.log`）

| コミット | 内容 | level 1 の診断 / 本数 |
|---|---|---|
| （v4） | | 280 / 106 |
| f0b6a02 | Struct の自前の `<=>` / `==` を、到達しうる全 Struct 型を相手に解析していた（`p(L.new(1, Money.new(1)))` だけで `Money#<=>(Money, L)`）。比べられうる値の組（同じ容器の要素、同じフィールド、Tuple の同じ位置）ごとに解析する | 266 / 97 |
| 1c119be | `in true \| false` が Boolean の網羅に数えられなかった | 261 / 97 |
| 8be53ea | ブロックの中で、外側の変数を狭めていなかった（`best == nil \|\| x < best` を `Array.each` の中に書くと nil の報告）。ブロックの実行ごとに外側の変数の狭めた型を持ち、代入で途中の階層の分を消す | 204 / 64 |
| 3cb0f11 | 同じチェックの評価のうち最悪の判定を残していたので、ループの初回（変数がちょうど nil）の「必ず失敗」が収束後も残った。同じ呼び出し経路の評価は合わせて「失敗しうる」、別の経路は悪い方を残す | 197 / 64 |
| d3b73ba | rescue の「送出されない」を、yield する関数の呼び出し（渡すブロック）ごとに判定していた。どれかで送出されれば報告しない | 194 / 62 |
| 206394c | f0b6a02 の続き：`Array.reduce` の初期値や `format` の引数どうしも比べる組にしていた。比べる組み込み（`include?`、`index`、Hash の `[]` など）だけ引数をまとめる | 182 / 58 |

| | v4 | v6 |
|---|---|---|
| level 1 で止められた正しいプログラム（診断） | 106（280） | 58（182） |
| level 2 / 3 / 4 | 321 / 457 / 464 | 300 / 450 / 458 |
| 変数の読み mono | 80.0% | 80.3% |
| 健全性の違反 / 負の対照 | 0 / 1,701 | 0 / 1,733 |

- 修正で新しく出た診断は 0 件（v6 の 182 件はすべて v4 の 280 件に含まれる）。8be53ea の健全性は、狭めた後に内側のブロックで nil を代入する例と、2 周目で nil になる例が、修正後も報告されることで確かめた。
- 3cb0f11 は、level 1 の「必ず失敗」の一部を level 2 の「nil かもしれない」に移す（level 2 の本数が一時 305 → 307 に増えたのはこのため）。
- 307 → 280（v3 → v4）の 27 件減は、ほぼ 38ca44c（型の違う値の `==` は false）で、消えた `Kernel.==` / `!=` の報告 28 件による。

**その後に入れた 2 つ**（ko1「2、3 は簡単そう」）
- 77b8ac9（推論器）：Symbol のタグで区別できる Tuple（`[:copy, n]` / `[:literal, xs]`）を位置ごとに混ぜずに保つ。`|kind, arg|`（多重代入も）で取り出した変数どうしの対応を覚え、`case kind in :copy` や `kind == :copy` で kind を絞ると arg も絞る（どちらかが代入し直されたら対応を捨てる）。`case op[0]` / `op[0] == :copy` は op 自体を絞る。書き手はほぼ全員、分解してからタグで振り分けていたので、Tuple を分けて保つだけでは効かなかった。
- cbdb600（言語）：`Array.sum(xs, 0.0)` など、Ruby と同じ `sum` の初期値。Float を期待する操作に Integer が来うるときのメッセージで勧める。コーパスはまだ使っていないので、下の数字には効いていない。

| | v6 | v7（77b8ac9） |
|---|---|---|
| level 1 で止められた正しいプログラム（診断） | 58（182） | 52（162） |
| うち型の混ざった容器 / 別の変数との相関 | 67 / 19 | 49 / 17 |
| level 2 / 3 / 4 | 300 / 450 / 458 | 299 / 450 / 458 |
| 健全性の違反 / 負の対照 | 0 / 1,733 | 0 / 1,841 |

新しく出た診断は 0 件。残り 162 件は、生成箇所の共有 68、型の混ざった容器 49（JSON・Lisp の値、値の型が列で決まる Hash の行など）、数値の混在 23（`sum` の初期値で書き換えれば消える）、相関 17、推論器の誤り 5。

**残りへの手**（未着手。提案）
- shared-site-merge（68）：関数の中で作る Array / Hash の site を、関数の具体化（引数の型）ごとに分ける。関数を型ごとに解析しているのと揃える。推論器の変更で、site の数が増える。
- heterogeneous-container（49）：JSON・Lisp の値の多くは本当に動的なので、書き方（Struct 型の union）の問題。
- path-correlation（19）：推論器では扱わない。書き方の問題として残す。
- typer-bug の残り（5）：`while x in T` の後で x を狭めない、要素ごとの比較で nil だけの組を level 2 に回していない、など。

### 11. ライブラリ試作で見つかった不具合を直した後（results-v8、2026-10-03）

`experiments/2026-10-03-libraries/` で見つかった推論器の不具合 9 件を直した処理系（926afa2）で測り直した。

| | v7 | v8 |
|---|---|---|
| level 1 で止められた正しいプログラム（診断） | 52（162） | 52（162） |
| level 2 / 3 / 4 | 299 / 450 / 458 | 286 / 448 / 456 |
| 変数の読み mono | 80.5% | 80.7% |
| 健全性の違反 / 負の対照 | 0 / 1,841 | 0 / 1,841 |

- level 2 の減少は、主に `while (x = f)` / `if (x = f)` の狭めと、常に raise する関数の呼び出しを出口と見なすようにしたことによる（どちらが何件かは分けて数えていない）。
- level 1 は変わらない: 試作で見つかった不具合は、このコーパスの level 1 の報告には現れていなかった。
- 計測全体が約 10 分から約 3 分になった。型の表示を 1 回の表示につき各 site 1 度に改めた（adc105c）ためとみられる（共有マシンでの観察、未検証）。
- 検査の集計から raise と rescue を外した（12a62fa）ので、`results.md` の run-time check sites の数は v7 以前と少し違う。

## 制限

- 書き手は 1 種類の AI（Claude）。人が書いたプログラムではない。課題も書き手が選んだ。
- Sake の書き手は Sake の制約に合わせて書き換えている（`notes-tally.md`）。Ruby 版と Sake 版は同じ出力だが、同じ構造とは限らない。
- 推論器の数字は、書き手が型推論を見ずに書いたコードに対するもの。ただし実行時の型検査（`--strict=0` でも残る）には合わせて書いている。
- Sake の推論器は具体化ごとに解析し、その union を数える。TypeProf はシグネチャを 1 つにまとめる。単位は 1 対 1 ではない。
- 遅さのために入力を縮めたプログラムがある（22 本以上）。型には影響しないはず。
- 計測ツールの誤りを途中で 5 つ直した（下記）。数字はすべて直した後のもの。

## 訂正の記録

- `measure.rb` を並列に流したとき、長い JSON の行が 1 つのパイプで混ざり、500 行のうち 34 行が壊れた。各バッチが別のファイルに書くようにした（`run.sh` の `par`）。
- 最初の計測は、TypeProf が 1 本で 9 GB を超え、マシンのメモリ不足で止められた。TypeProf に 120 秒・3 GB の上限を付けた。
- `crosscheck.rb`（前回の実験から流用）が、添字の検査と unknown の検査で落ちた。修正した版をこのディレクトリに置いた。
- 受け手のクラスの計測（`receiver_trace.rb`）が 2 度間違っていた。(1) C のメソッドの呼び出しを、1 段外側の行に数えていた（`(Array|Heap).pop` などの「混在」が 57 箇所と出ていたが、実際は 9 箇所）。(2) C のメソッドが内部で呼ぶ C のメソッドを数えていた（`(Regexp|String).match` が 107 箇所と出ていたが、0 箇所）。どちらも小さな例で正解が分かる形で確かめてから流し直した。
- 健全性の確認で HEAD に 173 件の違反が見つかり、推論器の 7 つの穴を直した（3 節）。

## ファイル

- `brief.md`, `writer-prompt.md`, `domains.md`：書き手への指示
- `corpus/NN-domain/`：プログラム（`.sake` / `.rb` / `.out`）、`TASKS.md`、`NOTES.md`
- `pilot/`, `pilot-results/`：試作
- `measure.rb`, `classify.rb`, `typeprof_measure.rb`, `crosscheck.rb`, `polysites.rb`, `sake_dispatch.rb`, `tools/`, `run.sh`, `summarize.rb`：計測
- `results-baseline/`, `results-head/`, `results-fixed/`：各版の結果（`results.md` が要約。大きい `sake.jsonl` は gzip）
- `notes-tally.md`：書き手の NOTES の集計
- `union-receiver-prior-art.md`：`(A|B).op(x)` の先行例の調査
- `report.html`：結論の解説ページ（上の artifact の元）
- `typeprof-analysis/`：TypeProf の結果の詳しい解析（完走できなかった原因、誤報の原因、untyped の原因。最小の再現例と診断用パッチ）。開発者向けの解説ページ <https://claude.ai/artifact/UUxaeKVUa9HAC95CS7hpzN>（`typeprof-analysis/report.html`）

## 2026-10-04: class declarations converted

The corpus `.sake` files were rewritten from `class C < {reader: [...]}` to the body form (`attr_reader ...`)
by `tools/convert_class_settings.rb` when the old form was removed. The crosscheck table over corpus-v2
is identical before and after the conversion (0 lines differ).

## 2026-10-05: measure.rb and optional parameters

measure.rb recorded a parameter's type from the arguments of each call, one entry per argument; a call that
leaves out an optional or keyword parameter (possible since 2026-10-03) crashed it (`truth_table` of
`../2026-10-05-review/corpus-v3`). It now keeps one entry per parameter and skips arguments the call did not
give, so an omitted parameter adds no type (its default's type is not counted). Programs without optional
parameters measure the same as before.
