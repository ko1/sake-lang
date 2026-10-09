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
| 10-09 | 組み込み: `ENV`、`Kernel.system`、`Open3.capture2/2e/3`（`process_test.sake`）。`Integer.to_s(n, base)`、`String.to_i(s, base)`。 |
| 10-09 | Sake で書いたテスト: string / collections / numbers / language / io_thread（合計 7 本、約 520 アサーション）。 |
| 10-09 | 12 本の移植（エージェント 5 体、`brief.md`）: observer, monitor, mutex_m, timeout, prettyprint, pp, stringio, tempfile, net_http, open_uri, getoptlong, bigdecimal。全部 Ruby の双子と同一出力。 |
| 10-09 | 移植が求めた組み込み 15 種（`Thread.current`、`Mutex.lock`…、`IO.seek`…、`Dir.tmpdir`、`Zlib`、`EOFError`/`ThreadError` など）。検査器 2 件（確実に失敗する呼び出しの後は到達不能、`while` 終了後の絞り込み）、デッドロックを Sake のエラーに。 |
| 10-09 | 移さないライブラリとその理由: `sakelib/notes/not-ported.md`。friction の集計: `notes.md`。 |
| 10-09 | TODO.md の課題を全部処理（D1–D10 は ko1 の判断）: Tuple パターン `in [P, Q]`、`coerce`、`to_s(x, fmt = ...)`、`at_exit`、rescue StandardError、`Op: ` を文から外す、など。 |
| 10-09 | 有名 gem 24 本の移植（エージェント 8 体、`brief-gems.md`）: colorize, ruby-progressbar, highline, ActiveSupport（inflector, core_ext, number_helper）, kramdown, liquid, rack, rackup, webrick, httparty, redis, dotenv, money, rubyzip, chronic, i18n, faker, thor, awesome_print, concurrent-ruby, jwt, rspec。全部 Ruby の双子と同一出力。 |
| 10-09 | 移植が見つけたもの: 検査器・処理系 7 件を同日に修正（IO を型リストに、union 呼び出しの `*rest`、`&&` の中の `block_given?`、`/n`、Symbol の `[mixed]` の誤認、`def initialize(x) = @x = x`、hint 2 つ）、組み込み 6 種。書き心地の集計: `notes.md`。残りは `TODO.md`（D11、スレッドで走るブロックの引数）。 |

## 方法

- 網羅の確認: `ruby coverage.rb` が、クラスごとに Ruby にあって Sake に無い名前を出す。
- 新しい操作の確認: `test/sake/core_test.sake` の期待値は Ruby で同じ式を評価した値（迷ったものは `ruby -e` で確かめた）。
- 既存のテスト（`test/test_samples.rb`、`test/test_sakelib.rb`）は全部通したまま。
