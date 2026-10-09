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
