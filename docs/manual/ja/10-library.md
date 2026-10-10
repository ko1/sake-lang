# ライブラリ（sakelib）

処理系には、Ruby の標準添付ライブラリと主な gem を Sake で書き直したライブラリ群 `sakelib/` が付属します。この章では、ライブラリの読み込み方、何が移植されているか、テスト枠組み minitest、そして各移植がどう検査されているかを述べます。個々のライブラリの API は `sakelib/notes/NAME.md` にあり、この章はその一覧です。

## 読み込みと名前

ライブラリは `require "json"` のように読みます。ライブラリの名前も、その中の操作の名前も Ruby のものに従うので、Ruby で知っている名前がそのまま使えます。違うのは呼び出しの形だけです。

- **探す場所。** `require "name"` は、まず require するファイルと同じディレクトリの `name.sake` を探します。無ければ処理系に付属する `sakelib/name.sake` を読みます。隣にある `name.sake` が require している自分自身か、ライブラリでないプログラムのときも sakelib のほうを読みます。どのディレクトリから実行しても `require "json"` は同じ `sakelib/json.sake` です。
- **`/` を含む名前。** Ruby の `net/http`、`open-uri` は `net_http`、`open_uri` と書きます。
- **モジュール関数は Ruby のまま。** `JSON.parse(s)`、`Base64.encode64(s)` は Ruby と同じ字面です。
- **インスタンスメソッドは主語が先。** Ruby の `ss.scan(/\w+/)` は `StringScanner.scan(ss, /\w+/)` です。連鎖なら `ss.StringScanner.scan(/\w+/)` と書きます（[プログラムの構造と名前解決](02-program.md)）。
- **入れ子の名前は平らに。** Sake に入れ子の名前は無いので、`Net::HTTP` は `NetHTTP`、`Concurrent::Future` は `ConcurrentFuture` です。対応表は各ライブラリの notes にあります。

```ruby
require "base64"
require "strscan"

e = Base64.encode64("hello")
p(e)                                  # => "aGVsbG8=\n"
p(Base64.decode64(e))                 # => "hello"
ss = StringScanner.new("foo bar")
p(StringScanner.scan(ss, /\w+/))      # => "foo"
p(StringScanner.scan(ss, /\w+/))      # => nil
p(ss.StringScanner.scan(/\s+/))       # => " "
```

各ライブラリの注記は `sakelib/notes/NAME.md` にあります。Ruby との違いとその理由、無いもの、そして Ruby の API と Sake の API の対応表です。移植しないライブラリとその理由は `sakelib/notes/not-ported.md` にあります。

## 標準添付ライブラリの移植

Ruby の標準添付ライブラリのうち、Sake で書けるものを移植しています。移植できないものの大半は、`method_missing`・`define_method`・特殊変数・第一級のブロックに依るもので、Sake がわざと持たない機能です。TLS・UDP・端末のように OS や C 実装が要るものは、ライブラリではなく処理系に組み込みます。

```ruby
require "json"

doc = JSON.parse("{\"name\": \"ann\", \"tags\": [\"a\", \"b\"]}")
p(doc)                                # => {"name" => "ann", "tags" => ["a", "b"]}
if doc in Hash
  p(doc["name"])                      # => "ann"
  puts(JSON.generate(doc))            # => {"name":"ann","tags":["a","b"]}
end
```

`JSON.parse` は Hash・Array・String・Integer・Float・true/false・nil のどれかを返すので、添字で読む前に `if doc in Hash` で絞り込みます（[制御構造とパターン](06-control.md)）。絞り込まずに `doc["name"]` と書くと、検査器は「添字できない型かもしれない」と報告します。

| 分野 | ライブラリ |
|---|---|
| データ形式 | json, csv, yaml, toml, ini, base64, digest, zlib, xml, erb, mustache |
| 文字列・解析 | strscan, optparse, getoptlong, shellwords, abbrev, prettyprint, pp, text, diff, terminal_table |
| 数 | bigdecimal, matrix, prime, securerandom, units |
| 時間 | time, date |
| 入出力・OS | fileutils, pathname, find, tempfile, stringio, logger, benchmark |
| ネットワーク | net_http, open_uri, uri, cgi, ipaddr, webrick |
| 並行 | monitor, mutex_m, timeout, observer, event_emitter |
| データ構造 | pqueue, lru_cache, trie, tsort, state_machine, semver |

### 部分的な移植と補足

- **yaml** は Psych の部分集合、**xml** は REXML の部分集合です。
- **digest** は MD5 と SHA を Sake で計算します（遅い）。**zlib** は CRC-32 と Adler-32 のチェックサムだけで、圧縮はありません。
- **net_http** の `Net::HTTP` は `NetHTTP` です。https は組み込みの `Socket.connect_ssl` を使います。
- **timeout** はブロックを別の Thread で走らせ、時間が来たら組み込みの `Thread.raise` で本当に止めます。
- **pp** は組み込みの `pp`（1 行）とは別に、幅で折り返す PP です。

### 組み込みにあるので require しないもの

Ruby では require するが Sake では組み込みの操作になっているものがあります。`require "tmpdir"` は「読めるファイルが無い」という静的エラーになります。

| Ruby の require | Sake の組み込み |
|---|---|
| `tmpdir` | `Dir.mktmpdir`、`Dir.tmpdir`（`Dir.tmpdir` は tempfile が足す） |
| `open3` | `Open3.capture2`、`capture2e`、`capture3`、`Kernel.system` |
| `set` | `Set[...]`、`Set.add` ...（[値と型](03-values.md)） |
| `socket` | `TCPServer`、`Socket`（TCP のみ） |

### gem に倣った小さなライブラリ

上の表のうち toml（toml-rb）、ini（inifile）、mustache、units（ruby-units）、text、diff（diff-lcs）、terminal_table、event_emitter（Node の EventEmitter）、pqueue、lru_cache（lru_redux）、trie、state_machine（AASM 風）、semver は Ruby の標準添付ではなく、よく使われる gem や他言語のライブラリに倣って書いたものです。どれに倣ったかは各 notes の冒頭にあります。

### 移植しないものの代わり

- **singleton** の代わりは `once { T.new(...) }` です（[関数とブロック](04-functions.md)）。
- **forwardable / delegate** の代わりは、委譲する操作を 1 つずつ書くことです。
- **ostruct** の代わりは Record `{a: 1}` か Hash です。

## gem の移植

よく使われる gem も、Sake で書ける範囲で移植しています。各移植は gem の名前を Sake で書ける限り保ちます（`Inflector.pluralize(s)`、`Redis.get(r, k)`）。

| 分野 | ライブラリ |
|---|---|
| 端末・CLI | colorize, ruby_progressbar, highline, thor, awesome_print |
| ActiveSupport | active_support_inflector, active_support_core_ext, active_support_number_helper |
| テキスト | kramdown, liquid, i18n, faker |
| Web | rack, rackup, webrick, httparty |
| データ | redis, dotenv, money, rubyzip, chronic, jwt |
| 並行・テスト | concurrent_ruby, rspec, minitest |

### 補足

- **active_support_core_ext** は `Blank`、`StringExt`、`ArrayExt`、`HashExt`、`Duration` の各 module です。
- **kramdown** は GFM 方言、**redis** は RESP2 のクライアント、**jwt** は HS256/384/512 です。
- **concurrent_ruby** は `ConcurrentFuture`、`ConcurrentPromise`、`ConcurrentAtom`、`ConcurrentMap`、`Semaphore` などです。
- **rspec** は minitest と同じ形で、例を名乗って書きます: `RSpec.expect(ex, x).To.eq(y)`。

### 落とした機能

落とした機能とその理由は `sakelib/notes/not-ported.md` の表にあります。主なものは次の 3 つです。

- **保持するブロック。** `then(rescuer) {}` やコールバックの登録。ブロックは第二級なので格納できません（[関数とブロック](04-functions.md)）。
- **反射。** `constantize`、`send`、`define_method`。名前からの呼び出しはありません。
- **クラスを値で渡す API。** `expect(x).to be_a(T)`。型は値ではないので、`x in T` か型ごとの関数にします。

## minitest

`sakelib/minitest.sake` は、Sake で書いたプログラムのための Ruby の Minitest 風のテスト枠組みです。Sake 自身のテストスイート（`test/sake/*_test.sake`）もこれで書かれています。

### テストの書き方

Sake には反射が無いので、テストは名前で見つけるメソッドではなく、`Minitest.test` に渡すブロックです。各アサーションは、属するテスト（ブロックの引数 `t`）を第 1 引数で名乗ります。Sake のすべての操作が主語を名乗るのと同じです。

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

```
# Running strings:

.

Finished in 0.026718s

1 runs, 3 assertions, 0 failures, 0 errors
```

- **テストはその場で走ります。** `Minitest.test` はブロックをすぐ走らせて結果を記録します。テストは定義順に走ります。
- **`Minitest.run(suite)`** は報告を印字し、失敗かエラーがあれば終了コード 1 で終わります。`Minitest.report(suite)` は印字だけして、全部通ったかを true / false で返します。

### アサーション

`Minitest` の関数で、どれも第 1 引数がテスト `t`、最後に省略できるメッセージを取ります。

| 関数 | 検査 |
|---|---|
| `assert(t, cond)`, `refute(t, cond)` | 真 / 偽 |
| `assert_equal(t, expected, actual)`, `refute_equal` | `==` |
| `assert_nil(t, x)`, `refute_nil` | nil |
| `assert_in_delta(t, expected, actual, delta = 0.001)` | 差が delta 以内 |
| `assert_includes(t, collection, x)`, `refute_includes` | 要素を含む |
| `assert_empty(t, collection)`, `refute_empty` | 空 |
| `assert_match(t, pattern, s)` | Regexp に一致 |
| `assert_raises(t) { ... }` | ブロックが例外を投げる。例外のメッセージを返す |

`assert_output` はありません。Sake のプログラムは自分の出力を捕まえられないので、値を印字して比べます。

### 失敗とエラー

失敗したアサーションは `AssertionFailed` を投げ、失敗（F）として記録されます。他の例外はエラー（E）として記録されます。Ruby の Minitest と同じです。

```ruby
require "minitest"

suite = Minitest.suite("numbers")
Minitest.test(suite, "integer division floors") do |t|
  Minitest.assert_equal(t, 3, 7 / 2)
end
Minitest.test(suite, "divides by zero") do |t|
  Minitest.assert_equal(t, 0, 1 / 0)
end
Minitest.test(suite, "wrong expectation") do |t|
  Minitest.assert_equal(t, 4, 2 + 3)
end
Minitest.run(suite)      # 終了コード 1
```

```
# Running numbers:

.EF

Finished in 0.035481s

  1) Error:
divides by zero
divided by 0

  2) Failure:
wrong expectation
expected 4, got 5

3 runs, 2 assertions, 1 failures, 1 errors
```

## テスト

ライブラリの各移植には Ruby の双子があります。同じプログラムを Sake のライブラリで書いた `test/sakelib/NAME.sake` と、Ruby のライブラリで書いた `test/sakelib/NAME.rb` で、両方が同じ出力を印字しなければなりません。移植の正しさの定義はこの「同じ出力」です。

```ruby
# test/sakelib/shellwords.sake の形
require "shellwords"
p(Shellwords.split("a 'b c' d"))      # => ["a", "b c", "d"]
p(Shellwords.escape("it's"))          # => "it\\'s"
```

```ruby
# 双子の shellwords.rb。Ruby で同じ 2 行を印字する
require "shellwords"
p(Shellwords.split("a 'b c' d"))
p(Shellwords.escape("it's"))
```

- **走らせ方。** `ruby test/test_sakelib.rb` が、各 `.sake` を `bin/sake --strict`（レベル 2）で、各 `.rb` を Ruby で `test/sakelib/` の中で走らせ、出力を比べます。
- **gem が無いとき。** 手元に無い gem の双子は、gem と同じ名前と出力を持つ素の Ruby の参照実装 `test/sakelib/ref/NAME.rb` で走らせます。
- **notes。** 双子が一致しない箇所、Ruby と違えた箇所は `sakelib/notes/NAME.md` に書きます。
