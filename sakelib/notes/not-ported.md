# Ruby の標準添付ライブラリのうち、Sake に移さないもの（2026-10-09）

`sakelib/` に無いライブラリと、その理由。「言語」は Sake の規則（反射・動的な呼び出し・第一級のブロック・Enumerator が無い、
名前空間は型ごとに 1 つ）で表せないもの、「組み込み」は Ruby の C 実装や OS の機能が要るもの、「不要」は Sake の組み込みが既に同じものを持つもの。

| ライブラリ | 判定 | 理由 |
|---|---|---|
| delegate, forwardable | 言語 | `method_missing` と `define_method` で委譲を作る。Sake では委譲先の操作を 1 つずつ書く（それが Sake の書き方） |
| singleton | 言語 | クラスの唯一のインスタンス。`once { T.new(...) }` が同じ役を果たす（`docs/spec.md` の once） |
| ostruct | 言語 | 任意の名前のフィールドを実行時に増やす。Record（`{a: 1}`）か Hash を使う |
| weakref | 組み込み | GC と結びついた参照。Sake に GC の操作は無い |
| English | 言語 | `$INPUT_RECORD_SEPARATOR` などの特殊変数の別名。Sake に特殊変数は無い |
| did_you_mean, error_highlight, syntax_suggest | 不要 | 処理系の機能。Sake の検査器が `did you mean` の hint を出す |
| un | 不要 | `ruby -run -e cp` のコマンド群。Sake の `fileutils.sake` と `bin/sake` のスクリプトで足りる |
| set | 不要 | Sake の `Set` は組み込み（`Set[...]`、`Set.add` ...） |
| tmpdir | 不要 | `Dir.mktmpdir` が組み込み |
| socket | 不要 | `TCPServer` / `Socket` が組み込み（TCP のみ。UDP、UNIX ドメインは無い） |
| open3 | 不要 | `Open3.capture2 / capture2e / capture3` と `Kernel.system` が組み込み（2026-10-09）。`popen3` のストリーム版は無い |
| pp | 一部 | `pp` は組み込み（1 行）。幅で折り返す PP は `sakelib/pp.sake`（2026-10-09 に移植） |
| prettyprint | 移植 | `sakelib/prettyprint.sake`（2026-10-09） |
| monitor, mutex_m, observer, timeout, stringio, tempfile, getoptlong, bigdecimal, net/http (`net_http`), open-uri (`open_uri`) | 移植 | 2026-10-09 に移植（それぞれの notes を参照）。timeout はブロックを止められない（`Thread.raise` が無い）、net_http は http のみ（TLS が無い） |
| resolv, resolv-replace | 組み込み | DNS は UDP ソケットが要る。Sake に UDP は無い |
| openssl, net/https, digest の OpenSSL 版 | 組み込み | TLS と暗号。`digest.sake` は MD5/SHA を Sake で計算する（遅い）。TLS は組み込みで提供するしかない |
| net/ftp, net/imap, net/pop, net/smtp | 組み込みの不足 | TCP の上に書けるが、試験に使える相手（サーバ）が無い。net/http は試験の中でサーバを立てた |
| drb, rinda | 言語 | 分散オブジェクト。`Marshal` と `method_missing` に乗る |
| io-console, io-wait, io-nonblock, readline, reline | 組み込み | 端末と非同期 I/O。Sake の IO は同期の read/gets/puts のみ |
| fiddle | 組み込み | C の関数呼び出し |
| ripper, prism, rbs, typeprof, debug, coverage, objspace, racc, rake, minitest（Ruby の）, test-unit, power_assert | 不要 / 言語 | Ruby のコードを扱う道具。Sake のテストは `sakelib/minitest.sake`（Sake 製） |
| rexml, rss | 一部 | XML は `sakelib/xml.sake`。RSS は XML の上に書けるが、需要が見えるまで保留 |
| nkf | 組み込み | 文字コード変換の C 実装。`String.encode` が組み込みにある（Ruby の Encoding） |
| syslog, etc, win32ole, fcntl, pty | 組み込み | OS の機能 |
| pstore, yaml/store | 保留 | `Marshal` 相当が無い。`yaml.sake` / `json.sake` でファイルに保存する形なら書ける |
| matrix, prime, abbrev, base64, csv, bigdecimal, getoptlong, mutex_m, observer, drb, rinda, nkf, syslog（bundled gems） | 上の各行 | |

## 気づいた点

- 移せないものの大半は「言語」側で、`method_missing`・`define_method`・特殊変数・Enumerator・第一級のブロックの 4 つに集約される。
  これは Sake が静的解析のために意図して捨てたもの（DESIGN.md「禁止するもの」）で、代わりの書き方（操作を 1 つずつ書く、once、Record）はある。
- 「組み込み」側は TLS・UDP・端末の 3 つで、ライブラリを Sake で書いても届かない。使いたいなら処理系に足す。

## gem のうち移さなかった部分（2026-10-09、24 本の移植から）

移した gem の中で落とした機能と理由。各 gem の全文は `sakelib/notes/<gem>.md`。

| 機能 | gem | 判定 | 理由 |
|---|---|---|---|
| 保持するブロック（`then(rescuer) {}`、Map の default block、pub/sub の購読、`rate_scale` の lambda、Liquid の drop/custom tag、Thor の `Thor::Group`/Actions） | concurrent-ruby, redis, ruby-progressbar, liquid, thor | 言語 | ブロックは第二級。走らせる側がブロックを持つ型（Future の Thread）か、キーワード・型で表す |
| 反射（`constantize`、`send`/`method_missing` の登録、`Faker::Config.random` の `Random`、`define_method`） | active_support, liquid, faker, colorize | 言語 / 組み込み | 名前からの呼び出しは無い。`Random` 型は組み込みに無い（`srand` は全体） |
| クラスを値で渡す API（`ask(q, Integer)`、`raise_error(Class)`、`expect(x).to be_a(T)`） | highline, rspec | 言語 | 型は値でない。型ごとの関数（`ask_integer`）か `x in T` |
| `2 * money`、Money を Hash のキーに | money | 設計 | 左のオペランドが決める（`coerce` を Money に書けば通る。D4）。Hash のキーは組み込みの値 |
| 端末（幅、raw mode、`echo = false`、`tty?` 以外） | ruby-progressbar, highline | 組み込みの不足 | `IO.winsize` 等は無い（TODO） |
| RSA/EC の署名、TLS 以外の暗号 | jwt | 組み込み | OpenSSL の公開鍵。HMAC は digest.sake の上に書けた |
| BigDecimal の算術、`Liquid error:` の埋め込み | liquid | 設計 | Float で代用。エラーは raise（埋め込みは gem の挙動） |
| 生の HTML、表、脚注、IAL、smart quotes | kramdown | 予算 | 規則の数。GFM の fence は入れた |
| keep-alive、chunked、CGI/FileHandler/認証/HTTPS | webrick | 予算 / 組み込み | 1 接続 1 スレッドで `Connection: close`。TLS のサーバ側は組み込みに無い |
| Builder DSL、Lint、Session、Multipart、Static | rack | 予算 | app は `RackApp` を include する型、middleware は次の app を持つ型 |
| ロケール、I18n の単位、`delimiter_pattern:` | active_support | 予算 | i18n.sake はあるが接続していない |
| `endian_precedence`、数詞、範囲 | chronic | 予算 | |
| ストリーム API（`Zip::InputStream`）、暗号化、permission | rubyzip | 予算 | 全体を読む/書く API のみ |
| `let`/`before`/`subject`、合成 matcher、`change {}` | rspec | 言語 / 予算 | `let` は遅延評価のブロックを保持する |
