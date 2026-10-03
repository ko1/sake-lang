# Sake でライブラリを書いてみる（2026-10-03）

ko1 の依頼「いろんなライブラリとか作って、使用感試してくれる？」「ウェブアプリどうなるかな」に応えて、性格の違うライブラリを 8 つ、Sake で書かせて使用感を記録した。

- 書き手: Claude（Opus）のサブエージェント 8 体、各 90 分程度。指示は `brief.md`（共通）と各依頼文（下表の「主題」）。
- 処理系: commit 07245b0 の `lib/`（書き手の作業中に `lib/` は変えていない。ソケットとスレッドは別ブランチ `io`）。
- 書き方の指定: 型は `class C < {reader: [...]}` を基本、後から詰める Array は要素型付き（`Integer[]` など）、`--strict`（level 2）できれいに動くまで直す。
- 各ディレクトリ: `lib.sake`、`client_*.sake`、`build.sh`（Sake には `require` が無いので連結して 1 ファイルにする）、`NOTES.md`（つまずきの記録と報告）、`bug_*.sake`（推論器・処理系の不具合の再現）。webapp は `serve.rb`（Ruby の小さな HTTP サーバ。リクエストごとに `bin/sake` を CGI として起動）と `curl_session.txt`。

| ライブラリ | 主題 | lib / クライアントの行数 | 結果 |
|---|---|---|---|
| json | 型の混ざった値 | 293 / 211 | 4 本とも level 2 で通る |
| collections | 汎用コンテナ（ヒープ、LRU、両端キュー） | 217 / 248 | 4/5 本が level 2。1 本は限界を示すため level 0 |
| events | イベントと状態機械（コールバックの代わり） | 92 / 315 | 4 本とも level 2 |
| csvtable | CSV と表の整形 | 272 / 207 | 5 本とも level 2 |
| linalg | ベクトルと行列（Integer/Float/Rational） | 222 / 129 | 5 本とも level 2 |
| validate | Result 型と入力検証 | 184 / 253 | 5 本とも level 2（level 3 で正しい報告 2 件） |
| graph | 頂点の型が変わるグラフ | 241 / 227 | 4 本とも level 2 |
| webapp | CGI 方式のウェブアプリ（ToDo、短縮 URL） | 311 / 251 | 3 本とも level 3。curl で一通り動作 |

合計（空行とコメントを除く）: ライブラリ 1,832 行、クライアント 1,841 行。不具合・限界の再現 19 ファイル。

## つまずきの記録（98 件）

| カテゴリ | 件数 |
|---|---|
| type-check-false-report（正しいのに拒否） | 18 |
| language-limit（書けない） | 15 |
| tooling（行番号、連結など） | 14 |
| ruby-habit | 14 |
| type-check-caught-bug（本物の誤りを実行前に発見） | 10 |
| message | 10 |
| missing-builtin | 9 |
| bug（処理系・推論器の不具合） | 7 |
| type-check-gap | 1 |

カテゴリは書き手の自己申告（`NOTES.md` の `- [category]` の行を数えた。json は番号付きの書式だったので別に数えた）。

## 共通して出た話題

1. **汎用コンテナが union にぼやける**（collections、graph、validate、linalg、csvtable）。フィールドの型がプログラム全体で型ごとに 1 つなので、同じ `Heap` を Integer と String で使うと、どちらの Heap も `Integer | String` になる。誤報の最大の原因。回避は、Record（形ごとに型が分かれる）、要素型ごとの小さな型＋`include` でコードを共有、など。
2. **コールバックの代わり**（events、webapp）: 処理する側を型にして mixin のモジュールで振り分ける（Java のリスナーに近い）、または Symbol と `case/in`。どちらも書けたが、推論器はどの購読者がどのイベントを受けるかを知らないので、全購読者が全イベントを受けるとして検査する。表と `case` がずれても気づけない。
3. **1 ファイルのプログラム**（ほぼ全員）: 連結すると行番号がずれる。呼ばれないライブラリ関数は検査されない（クライアントがライブラリのテスト代わり）。使われない mixin で「no type includes M」になる。
4. **推論器の不具合**（再現あり）: 型の表示が爆発する（35MB の出力）。`case` の `in` で網羅しても `else` の型が残る。`in true` / `in false` を網羅と見なさない。`while (x = …)` で x を狭めない。常に raise する関数の呼び出しを出口と見なさない。`--types` が rescue されない `raise` を error と数える。必須の関数を修飾なしで呼ぶと検査されない。必須関数の仮置きがブロックを取れない。
5. **処理系の不具合**: `Integer.chr(227)` が BINARY の文字列を返し、UTF-8 と連結すると Ruby の例外で落ちる（webapp、json）。
6. **足りない組み込み**: `Math::PI`（値の定数）、`<<`、ブロック付きの `gsub`、`pack`、失敗時に nil を返す数値変換、UTF-8 の `Integer.chr`、`Rational.to_r`。
7. **速さ**: 228KB の JSON の解析に 12〜15 秒。webapp では 1 リクエスト約 440ms のうち 40% が実行前の検査（共有マシンでの目安）。

## うまくいったこと

- 実行前に見つかった本物の誤り: ガード名のつづり誤り `:payd`、表の列の取り違え（events）。`String[]` の行に数値を書き込む（csvtable）。Struct を `generate` に渡す（json）。エスケープしていない String をページとして返す（webapp。`SafeHtml` 型で XSS を防いだ）。
- 300 行の JSON パーサ、Gram–Schmidt、LRU の連結リスト、スキーマ検証が、`--strict` を最初の実行で通った。
- 演算子の多重定義と数値の汎用性: 同じ `det` / `solve` が Rational では厳密に、Float では近似で動いた（Hilbert 行列の逆行列、det = 1/6048000）。
- `--types` が注釈なしで、JSON の再帰的な型やグラフの頂点の型を正しく出した。
- `reader:` を基本にする書き方は「邪魔にならなかった」「最初は癖で accessor にしたが、全部 reader にしても全プログラムが動いた」（linalg、validate、json、events）。

## その後（2026-10-03）

- 不具合 9 件を修正した（再現ファイルはそのまま残した）: 型の表示の爆発（adc105c）、網羅された `else` と `in true` / `in false`（8b0c327）、`while (x = f)` と常に raise する関数（68f9594）、必須の関数と使われない mixin（0008d81）、`--types` の `raise`（12a62fa）、文字コードの混在と `Symbol[]` など（926afa2）。
- ソケットとスレッドを入れた（2eee894、main には 7d8b842 で取り込み）。`webapp-native/` は同じフレームワークを Sake 自身がサーバになる形にしたもの。1 リクエスト約 3ms（CGI 版は約 280ms）。

## 次の手（提案）

- 不具合の修正（4、5）。
- 設計判断（ko1）: 汎用コンテナのためのフィールドの型の持ち方（型ごと → 生成箇所 `C.new` ごと、など）。複数ファイル（`require` か行番号の対応）と、呼ばれない関数の検査。Hash/Set の要素型の書き方。値の定数（`Math::PI`）。

結論の解説ページ（artifact）: <https://claude.ai/artifact/FKP8ZBSJ89wHUdVrSSsEGb>（`report.html`）
