# Ruby のライブラリを Sake に移す（2026-10-09 開始）

ko1 の依頼: Ruby のライブラリをほぼ全部 Sake 用に移植し、使って気づいた点を報告する。あわせて、Sake で書いた Sake のテストスイートを整える。
気づいた点は `notes.md`（随時追記）。

## 範囲

1. **コア API の穴埋め**（`lib/sake/stdlib_table.rb` の行、`lib/sake/stdlib_core.rb`、typer の結果種）。Ruby 4.0.2 の各クラスの public instance
   methods と Sake の registry の差（`coverage.rb`）を埋める。残したもの: `coerce`、`to_proc`、`deconstruct`/`deconstruct_keys`、`to_ary`/`to_str`/`to_hash`
   （Ruby の変換プロトコル）、`compare_by_identity`、`default_proc`、`rehash`、`dedup`（frozen 関係）、`chain`/`lazy`/`chunk`（Enumerator を返す）、
   `grep`/`grep_v`（`===` が要る）、`Set#divide`（ブロックの引数の数で意味が変わる）、`Set#to_h`/`Range#to_h`。
2. **Sake 製の minitest**（`sakelib/minitest.sake`）と **Sake で書いたテストスイート**（`test/sake/*_test.sake`、`test/test_sake_suite.rb` が回す）。
3. **標準添付ライブラリの移植**（`sakelib/`）。既に 40 本（`sakelib/README.md`）。残りはこの実験で足す。

## 進み

| 日 | 内容 |
|---|---|
| 10-09 | コア API: Integer/Float/Rational/Complex/String/Symbol/Array/Hash/Set/Range/Regexp/MatchData/Time/Math/Process に約 250 操作。`test/sake/core_test.sake`（16 テスト・213 アサーション）で Ruby の値と照合。minitest.sake。 |

## 方法

- 網羅の確認: `ruby coverage.rb` が、クラスごとに Ruby にあって Sake に無い名前を出す。
- 新しい操作の確認: `test/sake/core_test.sake` の期待値は Ruby で同じ式を評価した値（迷ったものは `ruby -e` で確かめた）。
- 既存のテスト（`test/test_samples.rb`、`test/test_sakelib.rb`）は全部通したまま。
