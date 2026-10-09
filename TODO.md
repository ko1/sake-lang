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
- [x] (10-09) `IO.tty?`、`Kernel.p(x, y)`、`Array.shift(a, n)`、`String.squeeze(s, chars)`、`Float.divmod(x, Integer)`、`Regexp.new(src, "imx")`（gem の移植が求めたもの）。
- [ ] `IO.winsize` / raw mode / noecho（端末。ruby-progressbar, highline）。
- [ ] `gsub` / `scan` のブロックに MatchData（Ruby の `$1`。active_support, redis）。
- [ ] `Arithmetic.round` に `half: :even`（money）。`Range.sum`。
- [ ] `Random` 型（faker の `Config.random`。今は `srand` が全体）。`ENV.replace`（dotenv の save/restore）。
- [ ] スレッドが例外で死んだとき stderr に報告する（redis: 5 秒のタイムアウトで気づいた）。

## 実装課題（gem の移植で見つかったもの、2026-10-09）

- [x] (10-09) `(IO|StringIO).print(o, s)`: 型のリストに IO を書けなかった。union 呼び出しで `*rest` を取る関数に引数が packed されなかった。キーワードを取る関数はリストに置けない（エラー）。
- [x] (10-09) `elsif cond && block_given?` がブロック無しの呼び出しで yield を落とさない: `&&` / `||` / `!` の中の `block_given?` を畳む。
- [x] (10-09) `/[\x7f-\xff]/n`: /n が落ちて RegexpError で処理系が死んでいた。
- [x] (10-09) `case/in` の Symbol の抜けが、Symbol を持つ無関係なフィールドを `[mixed]` で責める: Symbol の値を持つフィールドがあるときだけ mixed。
- [x] (10-09) `def initialize(x) = @x = x`（Ruby の癖）: x は新しいインスタンスなので循環する値ができた → 静的エラー。
- [x] (10-09) hint: `ARGV[0]`（`Array.fetch(ARGV, 0)` を示す）、`ss.pos = 1`（`Type.set_pos(ss, v)` も示す）。
- [ ] **ブロックの引数が関数のローカル**: ブロックをスレッドで後から走らせると、その時点の値（ループ変数の最後の値）を読む（`sakelib/notes/concurrent_ruby_bug_yield_in_thread_loop_var.sake`）。Ruby はブロック引数が呼び出しごとに新しい。直すにはブロックごとのフレーム（親リンク）が要る: lower / interpreter / typer にまたがる。スレッド無しでは観測できない。
- [ ] predicate のヘルパ（`def number?(l)`）が絞らないとき、union 全体（1,000 字）を印字する: 「`number?` は絞らない。`case l in Integer | Float` を」と言う（kramdown）。
- [ ] nil の hint がフィールドを責めるが、nil は `return nil` から来ている（`sakelib/notes/strscan_bug_nil_hint_blames_field.sake`）。`[mixed]` が Hash の値の union を Struct のフィールドのせいにする（thor の `Integer.times(options[:times])`）。
- [ ] `def initialize(c) = @x = 1 if @x == nil`: 修飾 if が endless def を飲み込み、class 本体の規則の文で報告される（liquid）。
- [ ] `"..." \ "..."`（補間を含む隣接リテラル）が拒否される（rubyzip）。

## 設計判断が要るもの（変えるなら仕様）

- [x] D1. (10-09, 変えない) Tuple と Array の `==`（`[1, 2] == Array[1, 2]` が false。テストの期待値で毎回踏む）。
- [x] D2. (10-09) Tuple のパターン `in [P, Q]`（位置ごとの部分パターン、束縛、入れ子、`=>`）。`*rest` は無し。
- [x] D3. (10-09, 設計どおり。spec §5.6 に「1 つの名前は 1 つの関数」を明記) 型ごとに名前空間が 1 つ: Ruby のクラスメソッドとインスタンスメソッドの同名（`Net::HTTP.get` / `http.get`、`PP.pp`、`Time.xmlschema`）。
- [x] D4. (10-09) 型が `coerce(b, a)` を定義したときだけ `1 + x` を Ruby の protocol で解く（検査器も追う）。
- [x] D5. (10-09, 変えない。spec §6 に Tuple を渡す書き方を明記) `*args` が位置ごとの型を持たない（observer の `notify_observers`）。
- [x] D6. (10-09) `to_s(x, fmt = ...)`: 2 つ目以降に既定値があれば許す（補間は 1 引数で呼ぶ）。
- [x] D7. (10-09, 変えない) `def` をブロックの中に書けない。
- [x] D8. (10-09, 変えない) `def NAN` を型の中から裸で呼べない（大文字は型）。
- [x] D9. (10-09, キーワードの `new` は既にある。spec §10.1 で勧める) 位置の `new` でフィールド順の誤りが静かに通る（キーワードの `new` はある）。
- [x] D10. (10-09) `Kernel.at_exit { }`: 組み込みがブロックを持つ（Thread.new と同じ）。finalizer は無し（GC と結びつく）。
- [?] D11. `**opts` を次の関数に渡す `f(**opts)`（csv, i18n, thor。`sakelib/notes/csv_bug_double_splat_pass_on.sake`）。Hash を位置で渡すと値が 1 つの union になって型が落ちる。案: `f(**opts)` を「opts の各キーを f のキーワードに静的に展開」として、f のキーワード集合 ⊆ opts の集合（`**` で集めた関数のキーワード）のときだけ許す。
- [x] D13. (10-09) Struct 値の型を構築場所ごとに分ける（`Expectation@L4#1`）: `expect(42)` と `expect("abc")` が別の型になり、rspec / Promise / Heap の `[mixed]` が消える。鍵は `new` のノード × 引数の平らな形 × ブロック。費用は SQL エンジンで 1.4〜2.6 倍（`experiments/2026-10-09-struct-sites/`）。typer2 は未対応（型ごとの表のまま）。
- [?] D12. フィールドの既定値が前のフィールドを読めない（`attr_reader src, len = String.bytesize(src)`。`sakelib/notes/json_bug_field_default_reads_earlier_field.sake`）。spec §10.1 は「引数の既定値のよう」と言うが、引数の既定値は前の引数を読める（§6）。案: 読めるようにする（initialize に写すのと同じ）か、spec に「読めない」と書く。
