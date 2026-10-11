# Rust バックエンド: 3 本のマイクロベンチマークで Ruby / Sake(interp) / Sake(Rust) を比べる（2026-10-10）

## 問い

Sake のプログラムを Rust に変換してネイティブにすると、どのくらい速くなるか。比較は Ruby（YJIT あり・なし）、Sake のインタプリタ、Sake → Rust の 3 本に、天井の参考として手書きの Rust を添える。

## 方法

- **バックエンド**: `lib/sake/rust.rb`（`bin/sabic` が呼ぶ）。検査済みの SakeAST を入力に、関数を引数の型ごとに単相化して Rust を出し、`rustc --edition 2021 -O -C overflow-checks=on` で実行ファイルにする。対象は型を一つに固定できる部分集合: Integer（i64。溢れたらエラー）、Float、true/false、nil（`Option<T>`）、String、Array（`Rc<UnsafeCell<Vec<T>>>`。Sake の値は参照なので共有する）、Tuple、クラス（`Rc<UnsafeCell<struct>>`）、ブロック（`yield` だけのものは `&mut impl FnMut`、`Array.each` / `Integer.times` / `Range.each` のものはループにインライン展開）。対象外のものは行番号付きで断り、exit 3。
- **プログラム**: `bench/loops.sake`（10,000 × 100,000 回の `j % u` と配列更新）、`bench/fib.sake`（素朴な再帰。`fib(1)` から `fib(u-1)` の和）、`bench/levenshtein.sake`（引数の全組の編集距離）。Ruby 版（`bench/*.rb`）は同じアルゴリズムを同じ形で書いたもの。手書き Rust（`bench/hand/*.rs`）は同じアルゴリズムを Rust らしく書いたもの（`%` は Rust の切り捨て、配列は `Vec` を直接）。3 本とも `bin/sake --strict=4 -c` を通り、出力は Ruby 版と一致する。
- **入力**: loops は `7`、fib は `32`（インタプリタも走る）と `38`（インタプリタ以外）、levenshtein は `srand(1)` で作った 40 文字 × 100 語（9,900 組）。loops はインタプリタでは 10^9 回が長すぎるので、内側を 1/100 にした `loops_small`（10^7 回）を全実装で別に測った。
- **計測**: `bench/run.sh`。各 3 回（インタプリタは 1 回）、bash の `time` で壁時計。出力は `build/*.out` に取り、fib と levenshtein では 4 実装の出力が一致することを確かめる。JIT なしの Ruby（`--disable-yjit`）、loops をメソッドに包んだ `loops_fn.rb`、`--yjit-call-threshold=1` は run.sh の後に手で足した（`results-run2.txt` 末尾）。
- **環境**: sp4（16 コア、専用。`bench-lease` で占有、governor performance）。Ruby 4.0.6 +YJIT +PRISM（`~/ruby/install/bench-40`）、rustc 1.93.1、Sake は c93f5fd2 の作業木（このバックエンドを足した状態）。

## 結果

`results-run1.txt` は最初の生成器（変数を参照するたびに Rc を clone していた）、`results-run2.txt` は受け手位置で借用するよう直した生成器。下の表は run 2 の中央値（秒）。

| ベンチ | 入力 | Ruby 4.0.6 JIT なし | Ruby `--yjit` | Sake interp | Sake → Rust | 手書き Rust | Ruby(YJIT) / Sake→Rust | Sake→Rust / 手書き |
|---|---|---|---|---|---|---|---|---|
| loops_small | 7（10^7 回） | 0.294 | 0.294 | 44.2 | 0.014 | 0.014 | 21x | 1.0 |
| loops | 7（10^9 回） | 26.4 | 27.4（書いたまま） / **7.6**（閾値 1） | （測らず） | 1.27 | 1.16 | 21.6x / **6.0x** | 1.09 |
| fib | 32 | 0.26 | 0.057 | 43.5 | 0.012 | 0.013 | （起動時間） | （起動時間） |
| fib_big | 38 | 4.19 | 0.496 | （測らず） | 0.185 | 0.205 | 2.7x | 0.90 |
| levenshtein | 100 語 | 1.81 | 0.318 | 229 | 0.034 | 0.021 | 9.4x | 1.6 |

run 1（clone していた生成器）との差: levenshtein の Sake→Rust は 0.095 → 0.034 で、手書きとの差が 4.5 倍から 1.6 倍に縮んだ。loops は 1.65 → 1.27。

### 読み方

- **インタプリタは Ruby(YJIT) の 150〜760 倍遅い**（loops_small 150x、fib 760x、levenshtein 720x）。AST を歩く Ruby のインタプリタで、1 操作ごとに型タグを検査しているので当然の桁。
- **Sake → Rust は Ruby(YJIT) の 2.7〜21 倍速い。** fib は Ruby 4.0 の YJIT が非常に速く（fib(37) までの和、約 1.3 億回の再帰呼び出しを 0.5 秒）、差が 2.7 倍にとどまる。JIT なしの Ruby と比べると 8〜53 倍。
- **loops の Ruby の数字は書き方で 3.6 倍変わる。** `loops.rb` のループはトップレベルにあり、メソッドに包んでも（`loops_fn.rb`）1 回しか呼ばれないので、YJIT の既定（30 回呼ばれたら compile）では一度も compile されず、JIT なしと同じ 27 秒になる。`--yjit-call-threshold=1` で 7.6 秒。SNS の比較で Ruby の loops が遅く見えるのはこれが原因で、Ruby の実力は 7.6 秒の方。表には両方を載せ、比は 7.6 秒の方で言う。
- **手書き Rust との差は 0.9〜1.6 倍。** fib では生成コードの方がわずかに速い（LLVM の揺れの範囲）。loops の 9% と levenshtein の 1.6 倍は、Ruby の意味論を保つ検査の分: `Array.fetch` の負の添字の正規化と範囲検査、`a[i] = v` の「末尾なら push」の分岐。levenshtein は内側のループに fetch が 5 回、set が 1 回ある。
- **床除算は原因ではない**（切り分け）。手書き Rust の `%`（切り捨て）を Sake と同じ床除算にした `bench/hand/loops_floor.rs` は 1.161 秒で、切り捨ての 1.162 秒と同じ。LLVM が分岐を安く済ませている。

## mixin ディスパッチの費用（shapes）

`Shape.area(s)` が s の型で振り分ける費用を測った。`bench/shapes.sake` は Circle・Rect・Tri を 1,000 個混ぜた Array を round 回なめて面積を足す（round = 1,000,000 で 10^9 回のディスパッチ）。対照の `shapes_mono.sake` は全部 Circle で、呼び出し先が静的に決まる。Ruby 版は `s.area` の多相呼び出し（YJIT のインラインキャッシュ）、手書き Rust は enum + `match`（閉じた型集合。sabic が生成するのと同じ構造）、`Box<dyn Shape>`（vtable）、単相の 3 本。インタプリタは 10,000 round（10^7 回）で測り、他は 1,000,000 round。生成器側の対応: 合併型 `Circle | Rect | Tri` は Rust の enum、`Shape.area(s)` は `match &s { U::Circle(x) => Circle_area(x.clone()), ... }`、`case/in` は if 連鎖。

| | Ruby `--yjit` | Sake interp（10^7 回） | Sake → Rust（最初の生成器） | Sake → Rust（借用渡し） | 手書き Rust |
|---|---|---|---|---|---|
| shapes_mono（静的） | 18.0 | 46.0 | 1.65 | **0.477** | 0.41 |
| shapes（3 型） | 20.0 | 44.2 | 1.90 | **0.596** | enum 0.60 / `dyn` 1.44 |
| ディスパッチの増分 | +2.0（10%） | （起動と同程度） | +0.25 | **+0.12（25%）** | enum +0.19 / `dyn` +1.03 |

単位は秒、中央値。10^9 回なので「増分の秒数 = 1 回あたりの ns」。`results-shapes.txt`（最初の生成器）、`results-run3.txt`（借用渡し）。

- **Sake の mixin ディスパッチは 1 回 0.12〜0.25 ns**。include している型の集合が静的に閉じているので enum の `match` になり、本体（`3 * r * r`）が呼び出し側に展開される。手書きの enum（+0.19 ns）と同じ桁で、Rust の `dyn Trait`（+1.03 ns。vtable 経由で展開できない）より速い。Ruby の多相呼び出しは +2.0 ns。
- **最初の生成器が手書きより 1.2 秒遅かったのは、ディスパッチではなく `Rc` の参照カウント。** 単相の shapes_mono でも 1.65 対 0.41 だった。切り分け: 生成コードを手で直して、ディスパッチの引数の clone を借用にすると 1.18、`Array.each` の要素取り出しの clone も借用にすると 0.477（`results-shapes.txt` 末尾の `sake-rust-v0/v1/v2`）。1 反復に 2 組あった参照カウントの増減で 1.15 秒、残り 0.07 秒が `Rc` 経由の間接参照。
- **生成器を直した**: 本体で再代入されない非 Copy の引数（オブジェクト・配列・文字列）は `&T` で渡し、`Array.each` の要素も再代入されないブロック引数なら借用で取り出す。これで shapes は手書き enum と同じ 0.60、shapes_mono は手書きの 1.16 倍。loops / fib / levenshtein は変わらない（引数は整数か、既に 1 回しか渡さない）。
- インタプリタは shapes と shapes_mono でほぼ同じ（44 対 46 秒）。ディスパッチ表の参照 1 回は、AST を歩く費用の中では見えない。

## Spinel（matz の Ruby AOT コンパイラ）との比較

[Spinel](https://github.com/matz/spinel) は Ruby の大きな部分集合（クラス・継承・ブロック・lambda・例外・パターンマッチ・Fiber・Thread・正規表現）を全プログラム型推論で C に落とし、世代別 GC を持つ。推論が揃わない場所は tagged union（`poly`）に落として `--warn-widen` で知らせる。同じ Ruby 版のプログラム（`bench/*.rb`。Spinel には Ruby がそのまま入力になる）を sp4 で Spinel dd29ea35（2026-10-10 取得、gcc 15.2、既定の `-O2`）でコンパイルして測った。`--warn-widen` の警告は 5 本とも利用者のコードには出ていない（levenshtein の 75 行は Spinel 自身の builtins/enumerator.rb に対するもの）。生の結果は `results-spinel.txt`。

| ベンチ（秒、中央値） | Ruby `--yjit` | Spinel → C | Sake → Rust | 手書き Rust |
|---|---|---|---|---|
| loops（10^9 回） | 7.6 | 1.43 | 1.27 | 1.16 |
| fib 38 | 0.496 | 0.006（C コンパイラが畳む。比較不能） | 0.185 | 0.205 |
| levenshtein 100 語 | 0.318 | 0.038 | 0.034 | 0.021 |
| shapes_mono（10^9 回） | 18.0 | 4.45 | 0.477（最初の生成器 1.65） | 0.41 |
| shapes（10^9 回、3 型） | 20.0 | 4.58 | 0.596（最初の生成器 1.90） | 0.60 |

- **loops と levenshtein は同じ速さ**（Spinel 1.43 / 0.038、Sake→Rust 1.27 / 0.034）。整数と配列だけのコードでは、どちらも型を全部決めてネイティブの整数演算に落としていて、残る差は配列の添字検査の書き方。
- **fib は Spinel が 0.006 秒**で、Spinel の README 自身が「C コンパイラがビルド時に大半を畳む」と注意している通り、再帰が定数畳み込みされている。gcc が再帰関数を部分的に評価したもので、Rust（LLVM）は畳まなかった。比較には使えない。
- **shapes は Spinel が 7.7〜9.3 倍遅い**（4.45 / 4.58 対 0.477 / 0.596。最初の生成器に対しても 2.4〜2.7 倍）。ディスパッチの増分は Spinel も +0.13 秒（0.13 ns/回）と小さく、差は 1 反復あたり約 4 ns の定数部分。Spinel のオブジェクトは GC 管理のヒープ上にあり、`shapes.each { |s| total += s.area }` のブロックと外側の `total` への書き込みがどう落ちているかで決まる。Sake→Rust は `Array.each` のブロックをループ本体に展開し、`total` はローカル変数のままで、オブジェクトは `Rc` 経由の読み出し。Spinel の生成 C を読んで切り分けるのは今後の課題。
- **解析器の大きさは桁が違う。** Spinel は `src/analyze*.c` が 107,000 行、`src/codegen*.c` が 141,000 行、ランタイム `lib/*.c` が 41,000 行。Sake は resolver 1,600 行 + `rust.rb` 1,100 行（うち型推論は約 250 行、Rust 側ランタイム約 350 行）。Spinel が Ruby の意味論（メソッドの動的解決、open class、`poly` への退避、GC）をコンパイラ側で引き受けているのに対し、Sake は言語の側で削っている（呼び出し先は resolver が決める、値へのメソッド呼び出しが無い、ブロックは第二級、継承なし）。性能が同じなら、この差は「どちらが書きやすいか」の問題に戻る。

## C バックエンド（ceec）

`bin/ceec`（`lib/sake/c.rb`）は Rust 版と同じ型推論の上で C を出し、`cc -std=gnu11 -O2` でネイティブにする。Array・String・オブジェクトは C のポインタを共有し（何も解放しない。GC なし）、`nil | T` は `{bool some; T v;}`、クラスの合併は `{int tag; void *p;}` と `switch`、整数演算は `__builtin_*_overflow` で溢れを検査する。`yield` で渡すブロックは呼び出し側の変数を構造体（フレーム）にまとめ、そのポインタを受け取る C 関数にした。式の中の文は GNU C の文式 `({ ... })`、`next`/`break` は `goto`。比較のため手書き C（`bench/hand/*.c`。整数の溢れ検査なし）も書いた。sp4、gcc 15.2、2026-10-10 23:33 UTC（JST 10-11 08:33）。生の結果は `results-c.txt`（`sake-interp OUTPUT DIFFERS` はインタプリタを走らせていないので出力ファイルが無いだけ）。

| ベンチ（秒、中央値） | Sake → C | Sake → C（溢れ検査を外す） | 手書き C | Sake → Rust | 手書き Rust |
|---|---|---|---|---|---|
| loops（10^9 回） | 1.387 | 1.356 | 1.355 | 1.269 | 1.162 |
| fib 38 | 0.186 | 0.065 | 0.064 | 0.186 | 0.206 |
| levenshtein 100 語 | 0.032 | 0.030 | 0.015 | 0.034 | 0.021 |
| shapes（10^9 回、3 型） | 0.674 | 0.607 | 0.471 | 0.596 | 0.606 |
| shapes_mono（10^9 回） | 0.481 | 0.406 | 0.354 | 0.479 | 0.408 |

- **Sake → C と Sake → Rust はほぼ同じ速さ。** loops は C が 9% 遅く（gcc と LLVM の差で、手書き同士でも C 1.355 対 Rust 1.162）、shapes は C が 13% 遅い。fib・levenshtein・shapes_mono は同じ。
- **fib の手書き C との 3 倍の差は、すべて整数の溢れ検査。** 生成コードから検査を外すと 0.065 で手書き C（0.064）と同じ。手書き Rust（検査あり）も 0.206 で、検査ありの fib はどちらの言語でも 3 倍かかる。gcc は検査が無いと再帰を部分的に展開できるが、検査の分岐があると展開しない。Sake の Integer は溢れないのが意味論なので、検査は外せない（外すなら多倍長への昇格か、64 ビットで回る意味論への変更）。
- **levenshtein の 2 倍は、Ruby の配列の意味論を保つ検査。** `Array.fetch` の負の添字の正規化と範囲検査、`a[i] = v` の「末尾なら push」の分岐。溢れ検査を外しても 0.030 で、手書き（0.015）との差はほぼ残る。Rust 版の 1.6 倍と同じ理由。
- **shapes の残り 0.14 秒（1 反復 0.14 ns）は切り分けていない。** 溢れ検査を外して 0.607、手書きは 0.471。候補は合併値の構造体コピーと、ループのたびに `arr->len` と `arr->p` を読み直すこと（生成コードは `Array.each` 中の push を許すため読み直す）。
- **書きやすさ**: Rust 版で手間だった所有権・`Rc`・借用渡しが C では存在しない。その代わりメモリを解放しない。ブロックの閉包はフレーム構造体で足り、型推論は 1 行も書き足していない。生成器は約 1,150 行（半分は C 側ランタイム）。

## 範囲解析で検査を外す（2026-10-11）

`lib/sake/ranges.rb` は各関数を抽象解釈し、整数の変数に上下界（定数か「別の変数 + 定数」）、配列の変数に長さの下界を持たせる。`while j <= n` の本体では j ≤ n、`return n if n < 2` の後では n ≥ 2 とし、代入はその変数に触れる界を消し、ループは拡大（widening）つきで不動点まで回す。証明できた溢れ検査と添字検査を、C 版は素の演算と `p[i]` に、Rust 版は `wrapping_*` と `get_unchecked` に落とす（`--keep-checks` で全部残す）。Rust 版は、絞り込み後の `nil | T` の読み出しも `unwrap()` から検査なしの取り出しにした。型の検査は生成コードにもともと無い。生成された関数本体の検査付き演算の数は、fib 6 → 3、levenshtein 26 → 4、loops 11 → 4、shapes 12 → 7。残るのは値の範囲が分からない所（配列要素やフィールドへの演算、関数の戻り値の和、入力値での割り算）。消してはいけない検査（1 つ多く回るループ、実際の溢れ、負の添字、ブロックの中で書き換わる変数）が残ることは `test/test_c.rb` と `test/test_rust.rb` で確かめている。

sp4、2026-10-11 02:10 UTC（JST 11:10）、`bench/run_elide.sh`、中央値（秒）。生の結果は `results-elide.txt`（loops の OUTPUT DIFFERS は `rand` の値が実行ごとに違うため）。

| ベンチ | C 検査あり | C 範囲解析 | Rust 検査あり | Rust 範囲解析 | 手書き C | 手書き Rust |
|---|---|---|---|---|---|---|
| loops（10^9 回） | 1.362 | 1.356 | 1.268 | **1.175** | 1.355 | 1.162 |
| fib 38 | 0.185 | 0.009* | 0.185 | 0.185 | 0.064 | 0.206 |
| levenshtein | 0.031 | **0.026** | 0.033 | **0.025** | 0.015 | 0.021 |
| shapes（10^9 回） | 0.673 | 0.674 | 0.572 | 0.582 | 0.471 | 0.606 |
| shapes_mono（10^9 回） | 0.482 | 0.483 | 0.479 | 0.479 | 0.354 | 0.408 |

- **levenshtein は 16〜24% 速くなった。** 添字検査 11 個が全部消えた分。残る差（手書き C の 1.7 倍）は、配列要素への `+ 1` の溢れ検査 4 個と、`Array.fetch` の負の添字の扱いを除いた後も残る配列の間接参照（`a->p[i]` は毎回 `a` から `p` を読む）。
- **Rust の loops は手書き Rust と同じになった**（1.175 対 1.162）。C は変わらない（gcc は検査付きでも同じ速さだった）。
- **shapes は変わらない。** 内側のループの検査（面積の掛け算と合計の加算）は値の範囲が分からず残る。
- **\* fib の C 0.009 秒は比べられない数字。** 計測を疑って確かめた: 出力は正しく、n を 4 増やすと 0.01 → 0.06 → 0.33 秒と指数的に伸びる（検査あり 0.31 → 1.96 → 12.8 秒）。`n - 1` と `n - 2` の検査が消えると gcc が再帰を何段も展開し（`fib_0` の中に `call` が 21 個）、副作用の無い関数として重複する部分呼び出しをまとめるので、伸び方の底まで下がる。Spinel の README が注意している「C コンパイラが fib を畳む」と同じ現象で、Rust（LLVM）では起きず、手書き C（0.064）でもこの形では起きなかった。言語や変換器の速さではなく、gcc がこの形の再帰に何をするかを測っている。

## 限界

- 対象は部分集合で、Hash・Set・Regexp・例外の rescue・mixin ディスパッチ・`(A|B).f`・Thread は未対応（exit 3 で断る）。sakelib の移植 73 本のような普通のプログラムはまだ通らない。
- 型推論は typer とは別に生成器の中に書いた小さなもの（スロットごとに 1 つの型、`nil | T` だけ Option、`if x != nil` の絞り込み）。typer の結果を使うほうが筋がよく、typer が式ごとの型を保持するようになれば置き換える。
- Integer は 64 ビット。溢れたら `attempt to add with overflow` で exit 1（Sake の意味論では多倍長になるところ）。
- Array の共有は `Rc<UnsafeCell>` で、unsafe の根拠は「スレッドが無く、要素への参照が 1 操作を越えて生きない」こと。`Array.each` の最中の push は添字ループなので壊れない。
- 3 本のマイクロベンチマークだけ。文字列処理や Hash の多いプログラムでは別の結果になる。
- fib(32) の Rust の 12 ms は起動時間で、比較には使えない（fib_big を見る）。

## 利用感

`notes.md`。

## まとめの頁

`report.html`（artifact: <https://claude.ai/artifact/KkyJRUA32P5nsSkMQyfbx6>。リンクを知っている人が閲覧できる設定）。

## ファイル

- `bench/*.sake`, `bench/*.rb`, `bench/loops_fn.rb`, `bench/hand/*.rs`: プログラム（shapes の手書きは `shapes_enum.rs`、`shapes_dyn.rs`、`shapes_mono.rs`）
- `bench/run.sh`: 計測スクリプト（sp4 で `RUBY=... SAKE=... ./run.sh > results.txt 2> results.log`。`BENCHES="shapes shapes_mono"` で対象を絞れる）
- `results-run1.txt` / `.log`, `results-run2.txt` / `.log`: 生の結果（loops / fib / levenshtein）
- `results-shapes-small.txt`（10,000 round、インタプリタを含む）、`results-shapes.txt`（末尾が 1,000,000 round）、`results-shapes.log`: shapes の生の結果
- `results-elide.txt` / `.log`、`bench/run_elide.sh`: 範囲解析で検査を外した版と外さない版（C と Rust）
- `results-c.txt` / `.log`: C バックエンドと手書き C（末尾に溢れ検査を外した版）
- `results-spinel.txt`: Spinel で同じ Ruby 版を測った結果（末尾に Spinel のソース行数）
- `results-run3.txt` / `.log`: 借用渡しにした生成器での再計測（loops / fib_big / levenshtein、shapes の 1,000,000 round。インタプリタは走らせていないので log の「sake-interp OUTPUT DIFFERS」は出力ファイルが無いだけ）
