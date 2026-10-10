# 組み込みリファレンスの執筆で見つかった課題の解消（2026-10-10）

ko1 の依頼: 「どんどん解決してって。利用感レポート忘れずに」。前日までにリファレンス（`docs/manual/*/ref/`、31 章 × 日英）を書いたエージェント 8 体と筆者が見つけた処理系・検査器の課題（`TODO.md` の「組み込みリファレンスの執筆で見つかったもの」約 40 件と、移植で残っていた課題のうち設計判断の要らないもの）を全部直し、リファレンスの該当の節を追従させ、使って気づいた点を `notes.md` に残す。

## 直したもの（`lib/`）

| 件 | 内容 |
|---|---|
| Ruby の例外の漏れ | `Stdlib.ruby_error` の二重定義（`stdlib_net.rb` が `stdlib_ext.rb` を影にしていた）を 1 つにし、さらに組み込み呼び出しの境界（`Interpreter#call_builtin` / `binary_op` / `unary_op`）で Ruby の例外をクラスごとに Sake の例外に写す `ruby_run_error` を置いた。RangeError / RegexpError / FloatDomainError / Math::DomainError / ZeroDivisionError / TypeError / ArgumentError / IndexError / KeyError / IOError（Errno, EOFError, ClosedQueueError も）/ ThreadError / EncodingError / RuntimeError / FrozenError→TypeError。`Sake::Tuple` などの内部名は文から消す。処理系自身のバグ（引数の数、`BUG:`）は生のまま出す。約 30 の呼び出しが rescue できるようになった（`test/samples/ruby_errors.sake`）。 |
| `==` / `!=` の関数形 | 演算子形と同じく、型が違えば false / true（TypeError だった）。 |
| 検査器の型と実行時の値のずれ 10 件 | `MatchData.begin/end` は `Integer \| nil`、`casecmp?` は false、`Time.to_a` の zone は `String \| nil`、`clock_gettime` は単位のリテラルで Integer / Float、`rand(0)` は ArgumentError（`rand(Float)` は Float）、負の底の `**` は Math::DomainError、`** Rational` は `Rational \| Float`、`round(x, 桁)` は主語の型を保つ、`Float.numerator(NaN)` は FloatDomainError、`Complex.abs` の Rational は Float。 |
| 「外れの nil」の分類 | `Array.slice/slice!/dig/minmax`、`Set.first/min/max/min_by/max_by/minmax`、`Hash.dig`、`MatchData.begin/end` を `x[k]` と同じ level 3 に。`Array.dig` / `Hash.dig` は鍵を複数取る。 |
| 型付き Array の穴 | `Array.insert` は末尾より先で IndexError（Ruby は nil を詰める）、`Array.fill` は静的にも、`Array.replace` は実行時にも検査、`Integer.digits` は `Integer[]`。 |
| 並べ替えの静的検査 | `Array.sort/min/max/minmax/sort_by/min_by/max_by`、`Set` の同名、`Tuple.max/min/minmax` で、要素（または block の結果）の型が互いに比べられないと `type`（nil を含めば `nil`）。混在がフィールド由来なら `mixed`。 |
| 細かいもの | `flat_map` の block が Tuple を返せる、`Regexp.new` の `n`、`Regexp.union(Array)`、`Range.include?/member?` が String の Range を歩く、`Range.minmax` が Float を取る、`Math.log(x, base)`、`Kernel.Rational(Float)`、`String.force_encoding` が in place、`Thread.raise` 後の `Thread.value` を `rescue RuntimeError` で受けられる、`Socket` / `TCPServer` の `==`、`Set.subtract` の TypeError、`Array.transpose` が Tuple の行を取る、`IO.size` / `IO.seek` のエラー、`Array.rfind` の Ruby 4.0 依存を外す、メッセージ 3 件。 |
| 章の追従で見つかって直したもの | `Array.dig` / `Hash.dig` が Tuple に入れる、`Hash.dig` の結果に既定値の型が入る、`Hash.sort_by/min_by/max_by` にも並べ替えの静的検査、`MatchData.bytebegin/byteend/offset/byteoffset/match/match_length` の nil も level 3、`Complex.polar` の Rational も Float、Ruby 自身の RuntimeError（`String.undump`）は ArgumentError（Sake の RuntimeError は `raise "msg"` と `Thread.raise` だけ。`rescue RuntimeError` の検査が生きる）、`ENV.replace` の鍵と値を静的に検査し変更前に確認、`IO.close(IO.stdout)` 後の CLI の flush の落ち、`r[:x]` の報告での CLI の落ち、`Array.insert` の負の添字の文、`Tuple.max([])` が静的エラーにならない、`rescue RuntimeError` の hint に Thread.raise。 |
| 移植で残っていた課題 | `IO.winsize` / `IO.raw { }` / `IO.noecho { }` / `IO.getch`、`Arithmetic.round` / `Float.round` の `half:`、`ENV.replace`、誰も value / join で読まなかったスレッドの例外を終了時に stderr へ、predicate ヘルパ（本体が `param in Pattern` の関数）が条件で引数を絞る、`def f(x) = body if cond` への hint、補間を含む隣接リテラル `"a#{x}" "b"`、`format` / `%` が Record を取る（`%<name>s`）、String の `chomp/delete/squeeze/slice/byteslice` の署名を `!` 形と揃える。 |

残したもの（設計判断が要る、または大きい）: `gsub` / `scan` の block への MatchData、`Random` 型、スレッドで後から走る block の引数がループ変数の最後の値を読む件、`[mixed]` が Hash の値の union をフィールドのせいにする件、D11（`**opts` の受け渡し）、D12（フィールドの既定値が前のフィールドを読む）。

## 確認

- `ruby test/test_samples.rb`（golden 159 本。新規: `ruby_errors`、`thread_unread`、`predicate_helper.strict`、`sort_union.strict`、`endless_def_modifier`。期待値を変えたもの: `mixed_warning`（`Array.max` の混在が `mixed` の警告として増えた）、`sort_tuple_key`（実行時の ArgumentError が静的な `type` に））。
- `ruby test/test_sake_suite.rb`、`ruby test/test_sakelib.rb`（並べ替えの静的検査で erb / liquid / redis / concurrent_ruby の 4 本が止まり、絞り込みを足した。`notes.md`）、`ruby test/test_cli.rb`（生成物の鮮度）。
- `ruby tools/check_reference.rb`: 変更後に 104 problems → 章を直して 0（エージェント 6 体、`brief-docs.md`）。約 1,500 の例を実行して照合する。
- `docs/cheatsheet.md`、`docs/builtins.md` を再生成。spec §2（厳格レベルの表）と §12.1（鍵は `eql?`）、manual 01 / 03 を更新。

## 利用感

`notes.md`。同じ内容の HTML 版 `notes.html` を artifact として publish した: https://claude.ai/artifact/WoWrzLyGPDQbTw7VjGdQRp
