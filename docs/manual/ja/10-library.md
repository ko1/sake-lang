# ライブラリ（sakelib）

`require "name"` は、require するファイルの隣に `name.sake` が無いとき、処理系に付属する `sakelib/name.sake` を読みます。名前は Ruby のものに従います: `JSON.parse(s)`、`Base64.encode64(s)`。Ruby のインスタンスメソッドは主語を先頭に置く操作になります: `StringScanner.scan(ss, /\w+/)`。

各ライブラリの注記（Ruby との違いとその理由、無いもの）は `sakelib/notes/NAME.md` に、移植しないライブラリとその理由は `sakelib/notes/not-ported.md` にあります。

## 標準添付ライブラリの移植

```ruby
require "json"
h = JSON.parse(File.read("conf.json"))
```

| 分野 | ライブラリ |
|---|---|
| データ形式 | json, csv, yaml（部分）, toml, ini, base64, digest（MD5/SHA を Sake で計算）, zlib（組み込み）, xml（REXML の部分）, erb, mustache |
| 文字列・解析 | strscan（StringScanner）, optparse, getoptlong, shellwords, abbrev, prettyprint, pp, text, diff, terminal_table |
| 数 | bigdecimal, matrix, prime, securerandom, units |
| 時間 | time, date |
| 入出力・OS | fileutils, pathname, find, tempfile, tmpdir（組み込み）, stringio, logger, benchmark, open3（組み込み） |
| ネットワーク | net_http（`Net::HTTP`。https は `Socket.connect_ssl`）, open_uri, uri, cgi, ipaddr, webrick |
| 並行 | monitor, mutex_m, timeout（`Thread.raise` で本当に止める）, observer, event_emitter |
| データ構造 | pqueue, lru_cache, trie, tsort, state_machine, semver |

singleton の代わりは `once`、forwardable/delegate の代わりは委譲する操作を書く、ostruct の代わりは Record か Hash です。

## gem の移植

| 分野 | ライブラリ |
|---|---|
| 端末・CLI | colorize, ruby_progressbar, highline, thor, awesome_print |
| ActiveSupport | active_support_inflector, active_support_core_ext（`Blank`、`StringExt`、`ArrayExt`、`HashExt`、`Duration`）, active_support_number_helper |
| テキスト | kramdown（GFM 方言）, liquid, i18n, faker |
| Web | rack, rackup, webrick, httparty |
| データ | redis（RESP2 クライアント）, dotenv, money, rubyzip, chronic, jwt（HS256/384/512） |
| 並行・テスト | concurrent_ruby（Future, Promise, Atom, Map, Semaphore ...）, rspec（`RSpec.expect(ex, x).To.eq(y)`）, minitest |

落とした機能とその理由（保持するブロック、反射、クラスを値で渡す API など）は `sakelib/notes/not-ported.md` の表にあります。

## minitest

`sakelib/minitest.sake` は Sake で書いたプログラムのテスト枠組みです。Sake 自身のテストスイート（`test/sake/*_test.sake`）もこれで書かれています。Sake に反射は無いので、テストは名前で見つけるメソッドではなく `Minitest.test` に渡すブロックで、各アサーションは属するテスト（ブロックの引数）を名乗ります。Sake のすべての操作が主語を名乗るのと同じです。

```ruby
require "minitest"

suite = Minitest.suite("strings")
Minitest.test(suite, "upcase and split") do |t|
  Minitest.assert_equal(t, "ABC", String.upcase("abc"))
  Minitest.assert_equal(t, Array["a", "b"], String.split("a,b", ","))
  Minitest.assert(t, String.empty?(""))
end
Minitest.run(suite)      # 報告を印字。失敗があれば終了コード 1
```

報告の最終行は `N runs, M assertions, 0 failures, 0 errors` です。失敗したアサーションは `AssertionFailed` を投げ、失敗として記録されます。他の例外はエラーとして記録されます。テストは定義順に走ります。

## テスト

ライブラリの各移植には Ruby の双子があります。`test/sakelib/NAME.sake`（`--strict` で走る）は、同じプログラムを Ruby のライブラリで書いた `test/sakelib/NAME.rb` と同じ出力を印字しなければなりません（`ruby test/test_sakelib.rb`）。
