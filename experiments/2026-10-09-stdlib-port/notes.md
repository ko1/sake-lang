# 気づいた点（移植と、Sake でテストを書いていて）

書式: 何が起きたか → なぜ → どうしたか / 提案。日付は JST。

## 10-09: コア API の穴埋めと minitest

1. **`[1, 2]` は Tuple で、Array の結果と `==` で等しくならない。** `assert_equal(t, [1, 2], Array.sort!(a))` が失敗する。
   Ruby では両方 Array。Sake では「中身が同じなら等しい」のは同じ種類の中だけ。テストは `Array[1, 2]` と書くことで通したが、
   Ruby の感覚で書くと最初に必ず踏む。Tuple と Array の `==` を中身で比べる（長さと各要素）案は、型の区別を弱める代わりに
   この落とし穴を消す。
2. **組み込みの例外メッセージに `Op: ` が付く**（`Rational.quo: divided by 0`）。Ruby と同じ文で比べる assert は書けず、
   `assert_match` にした。以前の移植（strscan, tsort）も同じ要求を出している。
3. **`module` の関数は既定で mixin。`Minitest.assert_equal(...)` と呼ぶには `module_function` が要る。** エラーの hint がそのまま答えなので
   詰まらないが、Ruby の `module Foo; def self.bar` に当たる書き方が無いことは毎回思い出す。
4. **`rescue StandardError => e` は書けない**（`StandardError` is not an exception type）。全部を受けるのは裸の `rescue => e`。Ruby の癖で
   書くと止まる。これも hint で済むが、`StandardError` を裸の rescue の別名として受けてもよさそう。
5. **要素の型を変える破壊的操作は、容器の型を「前後の合併」にする。** `Hash.transform_keys!(h) { |k| Symbol.to_s(k) }` の後、`h` の鍵は
   `Symbol | String` になり、ブロック引数 `k` も同じ型なので `Symbol.to_s(k)` が partial になる（型が変わらない変換なら問題ない）。
   検査器が時間を持たない（1 つのサイトに 1 つの型）ことの帰結で、`map!` 系は同じ型への写像にしか安全に使えない。
   テストは `Kernel.to_s(k)` で逃げた。Ruby の破壊的 API を移すとここが構造的に合わない。
6. **Ruby の変換プロトコルに乗らない Sake の値。** `Array#assoc` は要素が `to_ary` に応える Array であることを要求するので、Tuple の要素を
   飛ばして nil を返した。Sake 側で Tuple/Array を見て書き直した。Ruby の実装に委ねる組み込みは、Tuple・Record・Struct 値が
   Ruby の Array/Hash でないことで静かに違う結果になりうる（`flatten` が Tuple を開かないのは意図どおりだが、同じ理由）。
7. **コアとライブラリで同じ名前**: Ruby 3.4 で `Time#xmlschema` がコアに入ったが、`sakelib/time.sake` は `Time.xmlschema(x)` を
   「String なら parse、Time なら format」の 1 関数にしている（クラスメソッドとインスタンスメソッドが同名で、Sake には名前空間が 1 つ）。
   組み込みに足すと再定義エラーになるので、組み込み側を見送った。名前空間が型ごとに 1 つなのは、Ruby の「クラスメソッドとインスタンスメソッド」の
   対を潰す（digest の移植も同じ要求）。
8. **`did you mean` が破壊的な形も挙げる**（`upcace` → `upcase` と `upcase!`）。穴埋めで `!` 付きが増えた副作用。害は無いが、
   候補を 1 つに絞るなら「`!` を除いた名前が一致する方」を優先する。
9. **`String.encoding` 系は Encoding オブジェクトを返せない**ので名前の String にした（`Symbol.encoding(:a)` は `"US-ASCII"`）。
   Ruby の値のうち Sake に型が無いもの（Encoding, Proc, Method, Enumerator, Class）はこうして String か Tuple に落とすしかない。
10. **ブロック無しで Enumerator を返す操作は全部落とした**（`chain`, `lazy`, `chunk`, `each_slice` のブロック無し形は Array）。
    Sake のブロックは第二級で Enumerator が無いので、Ruby の「ブロックを省くと Enumerator」は表せない。
11. **`Hash#default=`** は `Hash.set_default(h, v)`。setter の名前規則（`set_x`）に揃えた。
12. **`Process::CLOCK_MONOTONIC`** のような定数は `Process.CLOCK_MONOTONIC` という操作（`Math.PI` と同じ）。値の定数が無いことの帰結。

## 10-09: Sake でテストを書いていて（string_test, collections_test）

13. **実行時の型エラーを期待するテストは書けない。** `assert_raises { Array.push(Integer[1], "a") }`、`pair[5]`（Tuple の範囲外）、
    `Range.to_a(1.0..2.0)` は、検査器がプログラム全体を実行前に拒否する（それが仕様: 「到達しない枝も検査する」）。
    テストでそれを確かめるには `--strict=0` で別のファイルにするか、検査器の報告をテストするしかない。Ruby の感覚で
    「例外が出ることを確かめる」テストを書くと、テストファイルごと落ちる。これは言語の設計どおりだが、テストスイートの作りに効く。
14. **同じ理由で、1 つの Hash に別の型の鍵を入れる試験も書けない。** `Hash.store(h, /re/, 1)` を試すと、`h` の鍵の型が
    `Symbol | Regexp` になり、他の行の `Symbol.to_s(k)` が partial になる。新しい Hash で試すしかない。
15. **`a + b` と `a - b` は新しい配列**（Ruby と同じ）。期待値を自分で間違えたが、Sake では `Array.concat` が破壊的で `+` が非破壊という
    Ruby の区別がそのまま残っているのは良い。
16. **Ruby 4.0 の `Set#select` は Array を返す**（Sake もそれに合わせている）。Ruby 側の挙動で、移植のとき Ruby の版を確かめる必要がある。
17. **`String.b(s) == "\xE3\x81\x82"` は false**（Ruby と同じ: バイト列が同じでもエンコーディングが違う）。`String.encoding` で確かめる。

## 10-09: Sake で言語のテストを書いていて（language_test）

18. **`def` はブロックの中に書けない**（Ruby は許す）。テストごとに補助関数をブロック内に置く Ruby の癖は使えず、全部トップレベルに出した。
    メッセージは明快（`def` must be at the top level or directly in a class/module body）。
19. **`x in T` を引数の中に裸で書くと構文エラー**（`assert(t, v in Point)`）。`(v in Point)` と括る。Prism の規則で、以前の移植 6 本も踏んだ。
    「`in` の優先順位」専用のメッセージが欲しいという要求はそのまま。
20. **配列パターン `in [a, b]` は未対応**（spec §16）。Tuple は `in Tuple` で受けて `t[0]` で取る。Record パターン `{name:}` は使える。
21. **`x rescue y` の型は `x | y` の合併になる**ので、`assert_match(re, (1 / 0 rescue "..."))` は「Integer かもしれない」で止まる。
    正しい指摘（Ruby でも 1/0 が例外を出さなければ Integer が渡る）。`assert_raises` のブロックに書き直した。
22. **型の値の等価と比較**は書いた `<=>`/`==` が `Array.sort`・`Array.max`・`assert_equal` にそのまま効く。ここは Ruby と同じ感触。

## 10-09: 12 本の移植（5 体のエージェント）の friction の集計

元は `sakelib/notes/{observer,monitor,mutex_m,timeout,prettyprint,pp,stringio,tempfile,net_http,open_uri,getoptlong,bigdecimal}.md` の
「Friction」と「Built-ins Sake lacks」。同じ趣旨をまとめ、何本が挙げたかを付けた。

### 言語の規則に由来するもの（設計の帰結。変えるなら仕様）

- **型ごとに名前空間が 1 つ**: Ruby のクラスメソッドとインスタンスメソッドが同名だと片方しか置けない（`Net::HTTP.get` と `http.get`、
  `PP.pp` と `PP#pp`、`Time.xmlschema`、`Net::HTTP.start` の 2 形）。4 本。回避は別名か `case` で引数の型を見る 1 関数。
- **右側のオペランドで dispatch できない**（`coerce` が無い）: `1 + bigdecimal` は書けない。数値型を作ると必ず当たる。1 本（matrix も以前に）。
- **ジェネリックなプロトコルが無い**: `obj.pretty_print(q)` のように「v の型の関数を呼ぶ」ことは、その型が module を include していないと
  できない。pp のユーザー型は汎用の walk に参加できない。1 本。Record を走査する手段（`Record.to_h`）も無い。1 本。
- **Tuple と Array**: `divmod` の Tuple に `Array.map` は使えず `Tuple.to_a`、Tuple に `join` は無い。2 本。
- **Struct 値の `==` は構造的**: Ruby の `Array#delete` で同じ見かけの別物まで消える（prettyprint は id を持たせた）。Tempfile のように
  Ruby が委譲で「同じオブジェクトを返す」API は再現できない。2 本。
- **`*args` は Array で、位置ごとの型を持たない**: `name, price = args` の各変数が全呼び出しの union になる。observer のように
  可変長で通知する API は、受け手が毎回パターンで取り出す。1 本。
- **`def` の中の `to_s` は 1 引数**（`to_s(fmt)` は別名に）、**型名の定数は関数にしても型の中から裸では呼べない**（`NAN` →
  `BigDecimal.NAN`）。1 本。
- **フィールド順 = `new` の引数順**で、位置の `new` は間違えても静かに通る（型の検査は `new` にかからない）。キーワードの `new` はあるのに
  Ruby の癖で位置で書く。1 本。

### 検査器（直せるもの）

- **`while (x = f()) != nil`** が `x` を絞らない: ストリームを読む Ruby の定型で、4 つのループを `loop do ... break unless x` に
  書き直した。1 本（stringio）。`return unless x in T` も絞らない。1 本。
- **`Array.shift`/`Array.max`/`Array.last` は空を見た直後でも nil 型**: `Array.fetch` に逃げる。3 本。正しいが、`empty?` の後の
  `shift` は Ruby の定型。
- **`Integer <=> Integer` が nil を含む型**: `(x <=> y) * s` が nil 報告。両方 Integer なら nil にならない。1 本。
- **`String.byteslice` は常に nil 混じり**: 範囲内と分かっていても `|| ""` が 12 回。1 本。
- **型エラーの後の偽の報告**（while の本体で型エラー → 後の代入が落ちて「nil」）: 同日に直した（`typer_eval.rb`）。1 本。
- **ライブラリ 1 本を `--strict=4` で検査すると `unrescued` が全部出る**: ライブラリは例外を投げる側。レベル 4 はプログラム向け。2 本。
- **報告がライブラリの行に出る**: ユーザーの誤りがライブラリの `case` で見つかると、ユーザーの行は hint の連鎖の中。1 本。
- 検査器が **本物の誤りを先に見つけた**例: getoptlong の Ruby 本体にある到達しない `raise RuntimeError`（`set_error` が常に投げる）、
  `[].max` の nil、テストの中の引数なし通知。3 本。

### 構文（Prism = Ruby の規則だが、Sake の書き方で頻度が上がるもの）

- **`x in T ? a : b`、`f(t, x in T)`、`raise X if a in T && cond`** は意図と違う構文解析になる（`in` の結合が弱い）。3 本（以前の移植で 6 本）。
  `(x in T)` と括る。専用の hint か、`&&` の右が死ぬ警告が欲しい。
- **組み込みの例外の文に `Op: ` が付く**（`Kernel.Integer: invalid value ...`）: Ruby と同じ文で比べる試験が書けない。2 本（以前にも 2 本）。
- **`test/sakelib/foo.sake` が兄弟の `require "foo"` を影にする**（loader は自分自身の require だけ特別扱い）。1 本。

### 組み込みの不足（同日に足したもの）

`Thread.current`、`Thread.join(t, limit)`、`Mutex.lock/unlock/try_lock/locked?/owned?`、`Queue.pop(q, timeout)`、`ThreadError`、
`EOFError`、`IO.seek/pos/rewind/read(io, n)/getc/truncate/size`、`File.open(path, mode, perm)`、`Dir.tmpdir`、`Zlib.inflate/deflate/gzip/gunzip`、
`ENV`、`Kernel.PROGRAM_NAME`、`Kernel.equal?`、`Integer.to_s(n, base)`。デッドロックは Sake の `ThreadError` に。

### 組み込みの不足（残り）

`Thread.raise`/`Thread.kill`（timeout の本体を止められない）、ソケットのタイムアウトと TLS（net_http は http のみ）、`Time.httpdate`、
`Array.sum` が `Arithmetic` を include する型を受けること、Float → 10 進の桁指定変換、`Record.to_h`/`Record.each`、`at_exit`/finalizer。

### 良かったと書かれたもの

- 入れ子の `yield`・`ensure`・2 段のブロックからの `return`・`until` を含む Oppen のアルゴリズムが、`--strict` で最初の実行から Ruby と同じ出力（prettyprint）。
- StringIO 54 操作の初稿が `--strict` を通り、Ruby の双子との差は Ruby 4.0 の挙動変更 1 つ（stringio）。
- `include` した module の関数が including 型の `@field` をそのまま読める（observer）。`attr_accessor` の setter、`include Indexable` の `req["X"] = v`、
  `(Text|Breakable).width(data)` の union 呼び出し（net_http, prettyprint）。
- 同一出力の試験（.rb の双子）が、移植者の Ruby の記憶違いを毎回すぐ捕まえた（tempfile 2 件、stringio 1 件、monitor のメッセージ）。

## 10-09: 有名 gem 24 本の移植（8 体のエージェント、`brief-gems.md`）の書き心地と friction の集計

元は `sakelib/notes/<gem>.md` の「Writing feel」「Friction」と各エージェントの報告。gem: colorize, ruby-progressbar, highline /
ActiveSupport（inflector, core_ext, number_helper）/ kramdown, liquid / rack, rackup, webrick, httparty / redis, dotenv, money /
rubyzip, chronic, i18n / faker, thor, awesome_print / concurrent-ruby, jwt, rspec。全部 Ruby の双子（gem が入っていれば本物、
無ければ gem の API を持つ素の Ruby）と同一出力。

### できた・できなかった（gem の API のうち）

- **そのまま移ったもの**: 文字列処理（inflector 140 入力、kramdown GFM 223 行、liquid の 38 filter、colorize 57 操作）、プロトコル
  （redis RESP2、jwt HS256/384/512、rubyzip の central directory と zip64、webrick/rack の HTTP）、数値（money の half-even、
  number_helper の 9 つの丸め、BigDecimal の丸めを Rational で再現）、並行（concurrent-ruby の Future/Promise/Atom/Map/Semaphore を
  Thread + Mutex + Queue で、thor の `Options#parse` 全文）。
- **型やキーワードで書き直したもの**: Ruby の「クラスを値で渡す」API（`ask(q, Integer)` → `ask_integer`、`raise_error(Class)` →
  無し）、ブロックで設定する DSL（HighLine の Question/Menu、Thor の `method_option`）→ キーワード引数、`define_method` のループ →
  1 行の def を 44 本（colorize）、`format` 文字列の eval（faker）→ `case rand(n)`、Rack の env Hash のキャッシュ → `RackRequest` の
  フィールド、RSpec の `expect(x).to eq(y)` → `RSpec.expect(ex, x).To.eq(y)`（module `To`/`NotTo` の chain 形）。
- **移せなかったもの**（理由は言語の規則）: 保持するブロック（Promise の `then(rescuer){}`、Map の default block、pub/sub、
  `rate_scale` の lambda、Liquid の drop、Thor の subcommand の `Thor::Group`）、反射（`constantize`、`send`/`method_missing`
  による filter/tag の登録、`Faker::Config.random` の `Random` 型）、`2 * money`（左のオペランドが決める。`coerce` は money 側に
  書けば通る。同日に D4 で入れた）、Money を Hash のキーに、組み込みの端末制御（`IO.winsize`、raw mode、`echo = false`）。

### 言語の規則に由来するもの（設計の帰結）

- **フィールドの型はプログラム全体で 1 つ**: `Expectation.actual`（rspec）、`Promise.result`（concurrent）、`Thor` の options Hash の値が、
  全部の使用箇所の union になり `[mixed]` で落ちる。rspec は期待を Tuple `[ex, actual]` にして（リテラルごとの型）解決。Promise は
  `then` の中で `v => Integer`。Hash も同じ（thor は `Thor.integer(options, :k)` ヘルパ）。4 本。これは **Sake の設計の中心（型は操作に、
  変数には書かない）の代償**で、ジェネリクスの無い型付きコレクションそのもの。→ 同日に D13 で、構築場所ごとに別の型にした
  （`expect(42)` と `expect("abc")` は別の `Expectation`）。Hash の値の union（thor）は残る。
- **`**opts` を次に渡せない**（`f(**opts)` は「`**` は未対応」）: i18n の 3 つの入口を Hash を位置で受ける内部関数に集約、thor の DSL
  関数 6 本が 9 キーワードを繰り返す。csv（以前）と合わせて 3 本。→ **D11**。
- **`new` の位置引数の順 = `attr_*` の行の順**（行をまたいでも）: アクセスでまとめて書く Ruby の癖で構築子が変わる（rubyzip。
  `field compression_method is already given as argument 2` が出て気づく）。rack も `RackResponse` の順を間違え、`new` の呼び出しで検出。2 本。
- **フィールドのリーダが同名の mixin の操作を影にする**（`value` と `Obligation.value`）、**クラスメソッドとインスタンスメソッドの同名**
  （`Promise.fulfill` → `fulfilled`）。D3 のとおり。2 本。
- **関数のローカルがスレッドに共有される**: Thread ごとに別のローカルを持たせるには関数（`_spawn`）に切り出す。警告は出ない。1 本（rack）。
  さらに **ブロックの引数も関数のローカル**なので、ブロックをスレッドで後から走らせると、その時点の値（ループ変数の最後の値）を読む
  （concurrent-ruby、repro あり）。Ruby はブロック引数が呼び出しごとに新しい。→ **実装課題**（スレッドで走る場合だけ観測できる）。
- **`case` の網羅性は Symbol の集合でしか検査できない**: thor の `run` の `case name` は登録リスト（String）と照合できない。Ruby の `def`
  が 1 つにしていた「登録」と「分岐」の 2 つのリストになる。1 本。
- **パターンの型を値で渡せない**: `ask(q, Integer)`、`raise_error(Class)`。1 行の関数を型ごとに書く。2 本。

### 検査器（直せるもの・直したもの）

- 同日に直した: **`(IO|StringIO).print` の IO**（型のリストに IO を書けなかった）、**union 呼び出しで `*rest` の関数に引数が
  packed されない**、**`elsif cond && block_given?`** が block 無しの呼び出しで yield を落とさない（`&&`/`||`/`!` の中の `block_given?`
  を畳む）、**`/[\x7f-\xff]/n`**（/n が落ちて RegexpError で処理系が死ぬ）、**`case/in` の Symbol の抜けが無関係なフィールドを
  `[mixed]` で責める**（Symbol の *値* を持つフィールドがあるときだけ mixed に）、**`def initialize(x) = @x = x`**（x は新しい
  インスタンスなので自分を自分のフィールドに入れて循環する。Ruby の反射的な書き方なので静的エラーに）、`ARGV[0]` と `ss.pos = 1` の hint。
- 残り: **predicate のヘルパ（`number?(l)`）が絞らない**とき、union 全体（1,000 字）を印字する → 「絞らない」と言うべき（kramdown）。
  **nil の hint がフィールドを責める**が nil は `return nil` から来ている（strscan）。**`[mixed]` が Hash の値の union を Struct の
  フィールドのせいにする**（thor）。**`def initialize(c) = @x = 1 if @x == nil`** は修飾 if が endless def を飲み込み、class 本体の規則
  の文で報告される（liquid）。**スレッドが例外で死んだとき stderr に何も出ない**（redis。5 秒のタイムアウトで気づく）。
- 検査器が本物の誤りを見つけた例: `in_groups_of` の nil の padding（`Array.concat: element must be String, but can be nil`、
  active_support）、`RackResponse` のフィールド順（rack）、`Range.begin` の nil（faker）、`Array.flatten(Hash.to_a(h))` が Tuple を
  ほどかない（redis）、nil の循環（2 つのフィールドが互いの nil を保持。highline）、Ruby の参照実装側の誤り（colorize の
  `case x when Integer`）。最初の `--strict` で何も出ず双子の diff で見つかった誤りも多い（kramdown 3 件）。
- **`|| ""` と `Array.fetch`**: 静かな検査は `m[1]`/`s[i]` の後の `|| ""` で買っている（kramdown, redis）。レベル 2 では
  `String.[](s, 1..)` の後の `|| ""` は不要だった（thor。strscan からの癖）。

### 組み込みの不足（同日に足したもの）

`IO.tty?`、`Kernel.p(x, y, ...)`、`Array.shift(a, n)`、`String.squeeze(s, chars)`、`Float.divmod(x, Integer)`、`Regexp.new(src, "imx")`。

### 組み込みの不足（残り）

`IO.winsize` / raw / noecho（端末。ruby-progressbar, highline）、`gsub`/`scan` のブロックに MatchData（`$1`。active_support, redis）、
`Arithmetic.round` の `half: :even`（money）、`Random` 型（faker の `Config.random`）、`ENV.replace`（dotenv の save/restore）、
`Array.sum` の後に `Range.sum`。

### 良かったと書かれたもの

- 24 本中、kramdown（690 行）・thor・awesome_print・chronic（300 行）・redis・dotenv・money は **最初の `--strict` で何も出ないか 1 件**
  （その 1 件は本物）。
- mixin `RedisCommands` に includer ごとの `call` を持たせて、直接でも pipelined でも **返り値に型が付く**（`Redis.get` は `String|nil`、
  `incr` は Integer）。gem の Future より読みやすいと書かれた。
- 17 種の node の `case` を `else` 無しで網羅検査できるのは、パーサでは Ruby より良い（liquid）。
- Sake → Ruby の書き直しは機械的（15 分）。Ruby → Sake のほうに nil ガードが現れる（kramdown）。
- 間違えた option 名が `did you mean` 付きの静的エラーになる（gem は黙って無視する）。`include ThorCLI` の契約違反が関数名と行で出る。
- Ruby の双子が gem の事実を暴いた: WEBrick の `mount_proc` は PATCH/DELETE に 405、Rack 3 の `rack.input` は 1 回しか読めない、
  dotenv 3.x は二重引用符の `\n` をそのまま残す。
