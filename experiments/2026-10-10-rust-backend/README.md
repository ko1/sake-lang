# Rust バックエンド: 3 本のマイクロベンチマークで Ruby / Sake(interp) / Sake(Rust) を比べる（2026-10-10）

## 問い

Sake のプログラムを Rust に変換してネイティブにすると、どのくらい速くなるか。比較は Ruby（YJIT あり・なし）、Sake のインタプリタ、Sake → Rust の 3 本に、天井の参考として手書きの Rust を添える。

## 方法

- **バックエンド**: `lib/sake/rust.rb`（`tools/sakec.rb` が呼ぶ）。検査済みの SakeAST を入力に、関数を引数の型ごとに単相化して Rust を出し、`rustc --edition 2021 -O -C overflow-checks=on` で実行ファイルにする。対象は型を一つに固定できる部分集合: Integer（i64。溢れたらエラー）、Float、true/false、nil（`Option<T>`）、String、Array（`Rc<UnsafeCell<Vec<T>>>`。Sake の値は参照なので共有する）、Tuple、クラス（`Rc<UnsafeCell<struct>>`）、ブロック（`yield` だけのものは `&mut impl FnMut`、`Array.each` / `Integer.times` / `Range.each` のものはループにインライン展開）。対象外のものは行番号付きで断り、exit 3。
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

## 限界

- 対象は部分集合で、Hash・Set・Regexp・例外の rescue・mixin ディスパッチ・`(A|B).f`・Thread は未対応（exit 3 で断る）。sakelib の移植 73 本のような普通のプログラムはまだ通らない。
- 型推論は typer とは別に生成器の中に書いた小さなもの（スロットごとに 1 つの型、`nil | T` だけ Option、`if x != nil` の絞り込み）。typer の結果を使うほうが筋がよく、typer が式ごとの型を保持するようになれば置き換える。
- Integer は 64 ビット。溢れたら `attempt to add with overflow` で exit 1（Sake の意味論では多倍長になるところ）。
- Array の共有は `Rc<UnsafeCell>` で、unsafe の根拠は「スレッドが無く、要素への参照が 1 操作を越えて生きない」こと。`Array.each` の最中の push は添字ループなので壊れない。
- 3 本のマイクロベンチマークだけ。文字列処理や Hash の多いプログラムでは別の結果になる。
- fib(32) の Rust の 12 ms は起動時間で、比較には使えない（fib_big を見る）。

## 利用感

`notes.md`。

## ファイル

- `bench/*.sake`, `bench/*.rb`, `bench/loops_fn.rb`, `bench/hand/*.rs`: プログラム
- `bench/run.sh`: 計測スクリプト（sp4 で `RUBY=... SAKE=... ./run.sh > results.txt 2> results.log`）
- `results-run1.txt` / `.log`, `results-run2.txt` / `.log`: 生の結果
