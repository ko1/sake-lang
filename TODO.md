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
- [x] (10-10) `IO.winsize` / `IO.raw { }` / `IO.noecho { }` / `IO.getch`（端末。ruby-progressbar, highline）。端末でなければ IOError。
- [ ] `gsub` / `scan` のブロックに MatchData（Ruby の `$1`。active_support, redis）。
- [x] (10-10, `Arithmetic.round` / `Float.round` に `half:`。`Range.sum` は既にある) `Arithmetic.round` に `half: :even`（money）。`Range.sum`。
- [ ] `Random` 型（faker の `Config.random`。今は `srand` が全体）。[x] (10-10) `ENV.replace`（dotenv の save/restore）。
- [x] (10-10, 誰も value / join で読まなかった例外をプログラムの終了時に stderr へ) スレッドが例外で死んだとき stderr に報告する（redis: 5 秒のタイムアウトで気づいた）。

## 実装課題（gem の移植で見つかったもの、2026-10-09）

- [x] (10-09) `(IO|StringIO).print(o, s)`: 型のリストに IO を書けなかった。union 呼び出しで `*rest` を取る関数に引数が packed されなかった。キーワードを取る関数はリストに置けない（エラー）。
- [x] (10-09) `elsif cond && block_given?` がブロック無しの呼び出しで yield を落とさない: `&&` / `||` / `!` の中の `block_given?` を畳む。
- [x] (10-09) `/[\x7f-\xff]/n`: /n が落ちて RegexpError で処理系が死んでいた。
- [x] (10-09) `case/in` の Symbol の抜けが、Symbol を持つ無関係なフィールドを `[mixed]` で責める: Symbol の値を持つフィールドがあるときだけ mixed。
- [x] (10-09) `def initialize(x) = @x = x`（Ruby の癖）: x は新しいインスタンスなので循環する値ができた → 静的エラー。
- [x] (10-09) hint: `ARGV[0]`（`Array.fetch(ARGV, 0)` を示す）、`ss.pos = 1`（`Type.set_pos(ss, v)` も示す）。
- [ ] **ブロックの引数が関数のローカル**: ブロックをスレッドで後から走らせると、その時点の値（ループ変数の最後の値）を読む（`sakelib/notes/concurrent_ruby_bug_yield_in_thread_loop_var.sake`）。Ruby はブロック引数が呼び出しごとに新しい。直すにはブロックごとのフレーム（親リンク）が要る: lower / interpreter / typer にまたがる。スレッド無しでは観測できない。
- [x] (10-10, 本体が `param in Pattern` だけの関数は条件で引数を絞る) predicate のヘルパ（`def number?(l)`）が絞らないとき、union 全体（1,000 字）を印字する: 「`number?` は絞らない。`case l in Integer | Float` を」と言う（kramdown）。
- [x] (10-10 に確認: 既に責めない) nil の hint がフィールドを責めるが、nil は `return nil` から来ている（`sakelib/notes/strscan_bug_nil_hint_blames_field.sake`）。[ ] `[mixed]` が Hash の値の union を Struct のフィールドのせいにする（thor の `Integer.times(options[:times])`）。
- [x] (10-10, hint で「`= (body if cond)` と括る」と言う) `def initialize(c) = @x = 1 if @x == nil`: 修飾 if が endless def を飲み込み、class 本体の規則の文で報告される（liquid）。
- [x] (10-10) `"..." \ "..."`（補間を含む隣接リテラル）が拒否される（rubyzip）。

## 実装課題（組み込みリファレンスの執筆で見つかったもの、2026-10-10）

全部 10-10 に処理した（`experiments/2026-10-10-reference-fixes/`）。リファレンスの該当の節も同日に直した（`ruby tools/check_reference.rb` が例で捕まえる）。

- [x] (10-10) **`Stdlib.ruby_error` が二重定義**（`stdlib_ext.rb:50` と `stdlib_net.rb:79`。後者が勝ち、ThreadError と ArgumentError しか包まない）。そのため `Integer.chr(256)`、`Integer.sqrt(-1)`、`Integer.digits(-1)`、`Integer.pow(2, -1, 7)`、`Regexp.new("(")`、`String.match?("a+c", "+")`、`String.byteindex("héllo", "l", 2)`、`Arithmetic.round/to_i(Float.NAN)`、`Integer(Float.NAN)` などが Ruby の生の backtrace で死に、`rescue RegexpError` 等で捕まえられない。1 か所にまとめれば直る。
- [x] (10-10, 組み込みの境界で Ruby の例外をクラスごとに Sake の例外に写す: `Interpreter#ruby_run_error`) 包まれていない Ruby 例外（生の backtrace）: `"ab" * -1`（演算子形。`String.*` は包む）、`ljust/rjust/center` の空の詰め文字、`tr/delete/squeeze/count` の逆順範囲 `"z-a"`、`String.undump`、`Array.each_slice/each_cons(a, 0)`、`Array.pack` の TypeError、`Array.transpose` に Tuple（`Sake::Tuple` の名が出る）、`Set.subtract(s, 1)`（NoMethodError）、`MatchData.begin/end` の範囲外、`Range.first/last(1.0..2.0, 2)`、`Range.max(1.0...2.5)`、`Range.first(..5)`、`Range.step(r, 0)`、`Range.sum(r, Complex)`、`7.5 % 0`、`Float.divmod(x, 0.0)`、`Float.clamp` の lo > hi、`IO.close(IO.stdout)` 後の `puts`、`IO.size(IO.stdin)`、`IO.seek(f, n, :FOO)`、`ENV.set("", v)`、`Process.clock_gettime(999)`、`Mutex.synchronize` の再入、`Thread.value/join(Thread.current)`、`Socket.connect` の名前解決失敗（`Socket::ResolutionError`）、閉じた `TCPServer.port`。
- [x] (10-10, 関数形も false / true を返す) **`==` / `!=` の関数形が演算子形と食い違う**: `1 == "a"` は false だが `Integer.==(1, "a")`、`String.==("a", 1)`、`Symbol.==(:a, "a")`、`Hash.==(h, nil)`、`Float.==(1.0, "1")`、`Range.==(1..5, 5)`、`Time.==(t, 100)` は実行時 TypeError。署名が `(x, Any)` なので静的に通る。関数形も false を返すか、署名を狭めるか。
- [x] (10-10: begin/end は `Integer | nil`、casecmp? は false、zone は `String | nil`、clock_gettime は単位のリテラルで Integer/Float、rand(0) は ArgumentError、負の底の `**` は Math::DomainError、`** Rational` は `Rational | Float`、round の桁指定は主語の型を保つ、numerator(NaN) は FloatDomainError、Complex.abs の Rational は Float) 検査器の型と実行時の値がずれるもの: `MatchData.begin/end` が Integer（参加しなかったグループで nil）、`String.casecmp?`/`Symbol.casecmp?` が Boolean（エンコーディング不一致で nil）、`Time.to_a` の zone が String（固定オフセットで nil）、`Process.clock_gettime(c, :millisecond)` が Float（Integer）、`rand(0)` が Integer（Float）、`Float.**(負, 0.5)` が Float（Complex）、`Rational.**(4r, 1r/2)` が Rational（Float）、`Arithmetic.round(1234.5, -2)` が Float（Integer）、`Float.numerator(NaN)` が Integer（NaN）、`Complex.abs(Complex(3r, 0))` が Integer|Float（Rational）。
- [x] (10-10, 全部 level 3 に。dig は鍵を複数取る) 「外れの nil」の分類が揃っていない: `Array.slice/slice!/dig/minmax`、`Set.first/min/max/min_by/max_by`、`Hash.dig` は level 2、`a[i]`/`Array.first/min/max` は level 3。`Array.dig`/`Hash.dig` は鍵 1 つしか取らない（Ruby は複数）。
- [x] (10-10: insert は末尾より先で IndexError、fill は静的にも、replace は実行時にも、digits は `Integer[]`) 型付き Array の穴: `Array.insert` が末尾より先に nil を詰める（`is[3] = 2` は IndexError）、`Array.fill` は実行時だけ、`Array.replace` は静的だけで検査、`Integer.digits` は型無しの Array。
- [x] (10-10, 静的に `type`。erb / liquid / redis / concurrent_ruby の移植がこれで止まり、絞り込みを足した) `Array.sort/min/max/sort_by` の要素型の混在（`Array[1, "a"]`）が静的に出ない（`<`/`<=>` は出る）。`Tuple.max([1, "a"])` も同じ。
- [x] (10-10, 全部) `Hash.flat_map` が Tuple のブロック結果を拒む（`[k, v]` と書くのが自然）。`Regexp.new` が `n` フラグを拒む（リテラル `/a/n` は通る）。`Regexp.union` が Array 1 つを取らない。`Range.include?/member?` が `cover?` の実装（`"a".."z"` が `"mm"` を含む）。`Range.minmax` が Float の Range を拒む（`min`/`max` は通す）。`Math.log(x, base)` が無い。`Kernel.Rational(0.5)` が拒まれる。`String.force_encoding` が新しい String を返す。`Thread.raise` 後の `Thread.value` を `rescue RuntimeError` で受けると `rescue` 項目が拒む（`rescue => e` だけ通る。未捕捉の報告が行 0）。`Socket`/`TCPServer` の `==` が黙って false（`==` の操作が無いのに弾かれない）。
- [x] (10-10) メッセージ: `MatchData.[]=` の「defined for」が INDEX_ROWS（INDEX_SET_ROWS であるべき）、`Symbol.name` の凍結した String を変えたときの TypeError が Symbol の名を挙げない、`stdlib_core.rb` のコメントが Symbol 名を凍結と言うが `Symbol.to_s` は可変。
- [x] (10-10, spec と 03-values を `eql?` に) 仕様の文: spec §12.1「鍵は `==` で比べる」は `eql?`/hash（`Hash[1 => "a"][1.0]` は nil、`Set[1, 1.0]` は 2 要素）。`Hash.==(h, nil)` と同様。
- [x] (10-10) `Array.rfind` が Ruby 4.0 の `Array#rfind` に依存している。

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
- [ ] D14. (10-10) 表示の protocol（`to_s` / `inspect`）を `Comparable` のようなモジュールに分けるか。分けない: 表示には常に既定の形があり、opt-in にしても検査が増えない。`to_str` 相当の暗黙変換（String を要る場所に Struct 値を渡す）は、引数の型が protocol の有無で決まることになるので足さない（操作に型を書く原則）。代わりに「自分の `to_s` を持たない Struct 値を補間・`puts` している」を厳格レベルで報告する案を残す。
- [?] D12. フィールドの既定値が前のフィールドを読めない（`attr_reader src, len = String.bytesize(src)`。`sakelib/notes/json_bug_field_default_reads_earlier_field.sake`）。spec §10.1 は「引数の既定値のよう」と言うが、引数の既定値は前の引数を読める（§6）。案: 読めるようにする（initialize に写すのと同じ）か、spec に「読めない」と書く。

## 実装課題（マニュアルの書き直しで見つかったもの、2026-10-10）

言語の章を読みやすく書き直したエージェント 7 体の報告から（`experiments/2026-10-10-manual-readability/`）。

- [ ] **`Thread.new { break }` / ブロック内の `return` で処理系が落ちる**: `t = Thread.new { break }; Thread.join(t)` が `--strict=0` で Ruby の生の `NoMethodError: undefined method 'origin' for an instance of Prism::CallNode`（`interpreter.rb:90`、`thread_body`）。spec は LocalJumpError と言う。`--strict=2` では検査器が `break v` を `Thread.new` の結果型に加えてしまい、`Thread.join(t)` に `[nil]` が出る。静的に「スレッドのブロックから `break`/`return` はできない」と弾くのが筋。
- [ ] `rescue` の検査が `Thread.new { raise "x" }` の raise を見ない: `begin Thread.value(t) rescue RuntimeError` が level 1 で「never raises」。hint は Thread.raise だけを挙げる。ブロック内の raise も Thread.value/join に流すか、hint に書く。
- [ ] `@y ||= 0` がフィールドを絞らない: 直後の `@y * @y` が `[nil]` のまま（`Point.new(3, nil)` があるとき）。
- [ ] hint: 関数の中で読んだトップレベルのローカル（`def bump = count + 1`）に `String.count()`… の 5 候補が出る。「トップレベルのローカルは関数の中から見えない」と言うべき。`f = proc { }` は「undefined function `proc`」だけで、ブロックが値でないことを言わない（`->` は「unsupported syntax: lambda」と言う）。
- [ ] `sakelib/notes/not-ported.md` と `notes/timeout.md` が「Sake に `Thread.raise` が無い」「net_http に TLS が無い」と言うが、どちらも今はある（`Thread.raise`、`Socket.connect_ssl`）。notes を直す。
- [ ] リファレンスの検査器（`tools/check_reference.rb`）: 1 つの fence で実行時エラーは 1 つしか見せられず、静的エラーがあると実行時の行は走らない。`ruby error --strict=0` のような fence があれば、level 2 で静的に止まるものの実行時の形も検証に乗る（08 章は文で引用した）。
- [ ] `Enum` module（ko1、10-10）: `Enum.each(x) { }` / `Enum.map` … を Array・Hash・Set・Range・Tuple（と `each` を定義して include した自分の型）に第 1 引数の型でディスパッチする、Enumerable の短い名前の module。mixin のディスパッチの仕組みで書けるか、組み込み型の include 表（`Operators::BUILTIN` 相当）と typer の結果型の扱いを設計する。
- [ ] `module_function` の後の `def area(s) = raise NotImplementedError`（必須の関数）を include したクラスが定義していても、「Sq includes Shape but does not define area」と誤って報告する（`module_function` 無しなら正しく動く）。02 章の書き直しで発見。
