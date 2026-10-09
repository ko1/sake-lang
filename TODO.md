# TODO（2026-10-09、ライブラリ移植と Sake 製テストで出た課題）

出典: `experiments/2026-10-09-stdlib-port/notes.md`（集計）、`sakelib/notes/*.md`、`experiments/2026-10-03-sakelib-port/builtin-requests.md`。
状態: `[ ]` 未着手、`[x]` 済み（日付）、`[?]` 設計判断が要る（ko1 に聞く）。簡単なものから。

## 検査器

- [x] (10-09) `while (x = f()) != nil` / `while (x = f())` / `if (m = String.match(...))`: 条件の中の代入で x を絞る（stringio が 4 ループを書き直した）。
- [x] (10-09, already worked; test added) `return unless x in T` / `raise ... unless x in T` の後で x を絞る（observer）。
- [x] (10-09) `Integer <=> Integer`（同種のスカラー同士）を `Integer` に（nil は比較できない組だけ。bigdecimal）。
- [x] (10-09) `String.byteslice` の nil を `IndexNil`（`s[i, n]` と同じ扱い。stringio で `|| ""` が 12 回）。
- [x] (10-09) `raise X if a in T && cond`: `&&` が `raise ... if` 全体に掛かる構文解析を警告する（net_http）。
- [x] (10-09) `x in T ? a : b` / `f(t, x in T)` の構文エラーに「`(x in T)` と括る」hint（延べ 9 本が踏んだ）。
- [x] (10-09) `empty?` の直後の `Array.shift` / `Array.max` / `Array.last` は nil 型（3 本）: 空の配列の nil を `x[k]` と同じ index-nil（level 3）にした。空でないことを追うのは難しい。
- [x] (10-09, 文書化: spec §12) 要素の型を変える破壊的操作（`transform_keys!`）で容器の型が前後の合併になる（検査器が時間を持たない）。
- [x] (10-09, 文書化: spec §2.1) ライブラリ 1 本を `--strict=4` で検査すると `unrescued` が全部出る（レベル 4 はプログラム向け）。

## 実行時・メッセージ

- [x] (10-09) `rescue StandardError => e` / `rescue Exception` を裸の rescue として受ける。

- [x] (10-09) 組み込みの例外の文から `Op: ` を外し、操作名は報告の行に出す（Ruby と同じ `Exception.message`。4 本）。
- [x] (10-09) `test/sakelib/foo.sake`（プログラム）が兄弟の `require "foo"` を影にする: トップレベルに定義以外の文がある file はライブラリ候補にしない。

## 組み込み

- [x] (10-09) `Record.to_h(r)` / `Record.values(r)` / `Record.keys(r)`（pp の汎用 walk、以前の csv/json も）。
- [x] (10-09) ソケットのタイムアウト: `Socket.connect(host, port, timeout)`、`Socket.set_timeout(s, secs)`（net_http）。
- [x] (10-09) `Thread.kill(t)`、`Thread.raise(t, msg)`。timeout.sake は `Thread.raise` でブロックを本当に止めるようになった。
- [x] (10-09, `Array.sum` のみ) `Array.sum` / `Range.sum` が `Arithmetic` を include する型の要素を受ける（bigdecimal, matrix）。
- [x] (10-09) TLS: `Socket.connect_ssl(host, port[, timeout])`（OpenSSL、peer を検証）。net_http が https で使う。
- [x] (10-09, 不要と判断) Float → 10 進の桁指定変換: `Float.to_r` が正確な値を与えるので、有効桁への丸めは bigdecimal.sake 側で書ける。

## 設計判断が要るもの（変えるなら仕様）

- [?] Tuple と Array の `==`（`[1, 2] == Array[1, 2]` が false。テストの期待値で毎回踏む）。
- [?] 配列パターン `in [a, b]`（spec §16 で保留中）。
- [?] 型ごとに名前空間が 1 つ: Ruby のクラスメソッドとインスタンスメソッドの同名（`Net::HTTP.get` / `http.get`、`PP.pp`、`Time.xmlschema`）。
- [?] 右オペランドの dispatch（`coerce`。`1 + bigdecimal`）。
- [?] `*args` が位置ごとの型を持たない（observer の `notify_observers`）。
- [?] `to_s(x, fmt)`（`to_s` は 1 引数固定）。
- [?] `def` をブロックの中に書けない。
- [?] `def NAN` を型の中から裸で呼べない（大文字は型）。
- [?] 位置の `new` でフィールド順の誤りが静かに通る（キーワードの `new` はある）。
- [?] `at_exit` / finalizer（第一級のブロックが無い）。
