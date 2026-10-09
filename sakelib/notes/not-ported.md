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
