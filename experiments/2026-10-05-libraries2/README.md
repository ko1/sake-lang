# 2026-10-05 ライブラリをたくさん書いてみる（第 2 弾）

目的: 2026-10-05 時点の言語（new のキーワード、`*rest`/`**opts`、`private attr_*`、式のデフォルト、
`initialize`、`class B < A`、`x => T`、フィールド読み書き `v.T.x` / `v.T.x += 1` など）で、
既存 18 ライブラリを書き直し、新しく 21 ライブラリを書いて、書き味と処理系の穴を見る。

## 方法

- 処理系: 4cd0da6（書き直し・新規作成時）。修正後は 832e624。
- エージェント 4 体を並列に（既存の書き直し 1 体（内部で 9 分割）、新規 3 グループ）。指示は `brief.md`。
  lib/・docs/ の変更と git は禁止。バグは `sakelib/notes/<lib>_bug_*.sake` に最小再現を置く。
- 判定: `ruby -Ilib test/test_sakelib.rb`。各テストは `.sake` を `--strict`（レベル 2）で走らせ、
  同じ内容の Ruby 版（Ruby 標準ライブラリ、または `test/sakelib/ref/` の参照実装）と出力が一致すること。

## 結果

39 ライブラリすべて Ruby と出力一致（39 runs, 0 failures）。

新規 21 本（行数 / 関数数）:

| グループ | ライブラリ |
|---|---|
| 標準ライブラリ移植 | pathname 359/50, fileutils 162/25, find 58/3, securerandom 107/16, time 411/36, ipaddr 454/70 |
| データ形式 | yaml 626/45（Psych と比較）, xml 442/70（REXML と比較）, toml 421/39, ini 151/19, diff 257/24, mustache 179/13 |
| gem 風 | semver 163/18, text 118/6, pqueue 114/19, trie 121/16, lru_cache 103/18, state_machine 122/17, event_emitter 92/14, units 169/24, terminal_table 142/18 |

既存 18 本のうち 14 本に新機能を適用（`Logger.new(dev, level:, progname:, ...)`、`ERB.new(src, trim_mode:)`、
`URI.join(base, *refs)`、`OptionParser.on(op, *args)`、`Benchmark.bm(width, *labels)`、内部状態の `private attr_*` など）。

## 見つかった処理系の問題と処置（832e624 で修正）

| 問題 | 処置 |
|---|---|
| `f(*xs)` がユーザ関数の `*rest` に入らない（4 ライブラリで遭遇） | 書き出した位置引数の後なら `*rest` に入るようにした |
| `class B < A` で A の関数が作る配列を B と共有し、要素型が混ざる（pqueue） | 貼り付けた関数は自分の容器を持つ |
| `initialize` 内の `@x => T` がフィールドを絞らない（lru_cache） | `=>` / `case/in` で新インスタンスのフィールドを絞る |
| `if !x ... else` の else で x が非 nil にならない（semver） | `!x` を条件の否定として絞る |
| `Regexp == Regexp` が常に false（ipaddr）。Range も同様（修正中に発見） | 値で比較 |
| `Range.to_a("A".."Z")` が検査を通って実行時 TypeError（securerandom） | String 始まりの Range は列挙可（Ruby と同じ）。それ以外（Float など）は検査で `type` |

## 設計判断が必要なもの（未対応）

- `f(**opts)` で受け取ったキーワードを渡せない（csv, json）。Hash の値は 1 つの型なので、渡すと各キーの型が混ざる。
- フィールドのデフォルト式が前のフィールドを読めない（json: `attr_reader src, len = String.bytesize(src)`）。
- `private attr_*` のフィールドを、クラス内の関数でも第 2 引数（`other`）からは読めない（units）。Ruby の `protected` 相当がない。
- フィールドは全インスタンスで 1 つの型なので、要素型の違うコンテナは型ごとに `class IntQueue < PQueue` が要る（pqueue）。
- ディレクトリ操作（`Dir.children`, `mkdir`, `rmdir`）がなく、fileutils/find は不完全。Time に固定オフセットがない（time）。

## 書き味（各 notes/<lib>.md より）

- 効いたもの: new のキーワード（`TerminalTable.new(title:, headings:, rows:)`）、`initialize` での正規化
  （units の `"km/h"`、`REXMLDocument.new(str)` のパース）、式のデフォルト（trie の `root = TrieNode.new`）、`once` の定数表、
  `x => T`（diff の `@action => String` がテストのわざと間違えた呼び出しを実行前に検出）。
- 保存ブロックなしの設計: event_emitter はリスナーを「`Listener` を include した型の値」にして `Listener.call` で分岐
  （コマンドオブジェクト）。state_machine は guard/callback を Symbol にしてモデル側の `case` で処理。
- 型の絞り込みが効かない書き方: `Array.select { c in T }` は要素型を絞らない（xml で `[mixed]` 9 件 → `filter_map { (c in T) ? c : nil }`）。
  述語ヘルパー（`table_array?(v)`）も絞らない。

## 回帰確認（832e624、corpus-v3 500 本）

`REUSE=results-head ./run.sh ../2026-10-05-review/corpus-v3 ../2026-10-05-review/results-v3-c1`:
500 本すべて Ruby と出力一致。健全性違反 0（負の対照は 1874 件検出、前回と同じ）。
レベル 1 の報告 38 本 / 84 件（A2 で mixed を警告にした後の値と同じ）、レベル 2 は 293 本 / 1258 件で変化なし。
今回の修正による報告の増減はなかった。

## デフォルト値の廃止と組み込み追加の後（corpus-v3、2 回）

- `results-v3-d1`（a12be1d、デフォルト値の廃止直後）: 健全性違反 511 件 / 115 本。すべて「initialize 内のフィールド書き込み（`T.set_x`）が実行時に観測されたのに静的検査の記録がない」。書き込みを env だけに入れる変更で、setter の引数検査の記録まで飛ばしていた。記録を戻して該当 2 本で 0 件を確認。
- `results-v3-d2`（a08178e のマージ後）: 違反 0（負の対照は 1873 件検出）。出力一致 499 本。1 本（07-trees/filesystem_du）は自前の `class Dir` が新しい組み込みの Dir とぶつかった。.sake と .rb で DirNode に改名し、出力一致を確認。エラーメッセージも「組み込みの型なので別名を」に直した。
- レベル 1 は 38 本 84 件 → 40 本 95 件。増分は filesystem_du の 10 件（上の衝突）と keypad_lock の 1 件。後者は `attr_reader state = :locked` のリテラルのデフォルトでフィールドの型が Symbol 全体に広がっていたのが、`@state = :locked` になって書かれた Symbol の集合に絞られた結果。そのため `case @state` に `:lockout` の枝がないことが level 1 で報告される（フィールドの読み取りは絞り込まないので、直前の `if @state == :lockout … @state = :locked` は効かない）。言語の規則どおりの報告で、ローカルに写してから `case` すれば消える。
