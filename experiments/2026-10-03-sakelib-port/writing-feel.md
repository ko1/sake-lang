# Sake の書き味: sakelib 移植 18 本から

材料: `sakelib/notes/*.md`（18 本、8 人で分担。brief は `brief.md`）と、それぞれの `sakelib/*.sake`。
ライブラリと人の対応は notes に書かれていない（zlib の notes が digest と同じ検証方法を参照しているので、この 2 本は同じ人だと推測できる程度）。

表記:
- **[報告]** は notes に書かれていること。数字は「その現象を notes で書いた本数」で、カッコ内に名前を挙げる。
- **[推論]** はこのまとめを書いた側の解釈。notes には書かれていない。
- 評価: **良** / **悪** / **中立**（言語にとってどうか）と、理由を 1 行。

bug repro は 6 本とも、2026-10-03 時点で `bin/sake --strict` で再現することを確かめた（`builtin-requests.md` を参照）。

---

## 1. Ruby API を Sake の呼び出し形にしたとき

### 1.1 モジュール関数はそのまま読める

[報告] Ruby でもともとモジュール関数だった API は、名前も呼び出し形も変わらない: abbrev, base64, cgi, json, prime, shellwords, zlib, digest の `Digest.hexencode`（8 本）。base64 と shellwords と abbrev は「表の行がほぼすべて same」で、base64・shellwords は最初の実行で `--strict=3` を通り、abbrev は `--strict` を通った。

```ruby
Base64.strict_encode64(s)      # Ruby も Sake も同じ
Shellwords.split("a 'b c'")    # 同じ
```

評価: **良**。理由: もともと「型.操作(値)」の形をしている API では、Sake の規則が見えない。

### 1.2 インスタンスメソッドは「型を名乗り、主体を第 1 引数に」

[報告] 全 18 本。`ss.scan(re)` → `StringScanner.scan(ss, re)`、`log.warn(m)` → `Logger.warn(log, m)`、`tms.real` → `BenchmarkTms.get_real(t)`。

```ruby
# Ruby
log.level = :warn; log.warn("disk")
# Sake
Logger.set_level(log, :warn); Logger.warn(log, "disk")
```

[報告] 組み込み型への追加（`class Integer; def prime?(n)`）は Ruby と同じ構造のまま書ける: prime（`Integer.prime?`）, shellwords（`String.shellsplit`, `Array.shelljoin`）, abbrev（`Array.abbrev`）, json（`Hash.to_json` など）, csv（`String.parse_csv`, `Array.to_csv`）, tsort（`class Hash; include TSort`）の 6 本。prime の作者によれば、`97.prime?` と書くと hint がライブラリで追加した `Integer.prime?(97)` を出し、「よく効く」。

[推論] 呼び出し側は長くなる（`Logger.` が毎回つく）。ただし、どの notes もこれを friction に挙げていない。呼び出し側が冗長になるのを許容したのか、ライブラリを書く側からは見えなかったのかは、notes からは区別できない。利用側のコードを書かせて見る必要がある。

評価: **中立**。理由: 構造は保たれ、文句も出ていない。冗長さは利用側でまだ測っていない。

### 1.3 演算子は include で Ruby の見た目に戻る

[報告] `include Indexable` / `Bitwise` / `Arithmetic` を入れると、`m[i, j]`、`csv << row`、`ss[1]`、`md << s`、`d >> 1` が Ruby どおりに読める: csv, strscan, matrix, digest, date（5 本）。strscan と csv の作者はこれを「よかった点」に挙げている。digest は `md << "ab"` で `Bitwise.<<: SHA256 does not include Bitwise` と言われてから気づいた。メッセージが直し方をそのまま示している。

評価: **良**。理由: 型の名前を書かなくてよい唯一の経路が、型を決める規則（include）と一致している。

### 1.4 `A::B` を平らにする・例外の継承がない

[報告] ネストした名前を 1 段の名前に平らにしたのは 11 本: benchmark（`BenchmarkTms`）, csv（`CSVRow`, `MalformedCSVError`）, date（`DateError`）, digest（`MD5`）, erb（`ERB.h`）, json（`JSONParserError`）, matrix（`ErrDimensionMismatch`）, optparse（`OptionParserError`）, strscan（`ScanError`）, tsort（`TSortCyclic`）, uri（`InvalidURIError`）。
継承がないことで意味まで変わったのは 3 本:
- date: `DateError` が `rescue ArgumentError` で捕まらない。
- json: `NestingError` を `JSONParserError` に畳んだ。
- optparse: 6 種の例外を 1 型にまとめ、`get_kind(e)` が `"InvalidOption"` などを返す。

```ruby
rescue OptionParser::InvalidOption => e       # Ruby
rescue OptionParserError => e                 # Sake
  ... if OptionParserError.get_kind(e) == "InvalidOption"
```

評価: 名前の平坦化は **中立**（機械的に読み替えられる）。継承がないことは **悪**。理由: Ruby で `rescue ArgumentError` と書いて Date のエラーも捕まえていたコードが、移植すると黙って捕まえなくなる。

### 1.5 クラスメソッドとインスタンスメソッドが同じ名前

[報告] date（`Date.jd(n)` と `d.jd`）, digest（`MD5.hexdigest(s)` と `md.hexdigest`）の 2 本。1 つの関数の中で `case x in Integer ... in Date ...` と分岐する。checker は呼び出しごとに結果型を出し（`Date.jd(2460341)` は Date）、`Date.jd(1.5)` は実行前に報告される。digest の作者は「アルゴリズム 1 つにつき case 関数が 3 つ重複する」ことをコストとして挙げている。

評価: **中立〜良**。理由: 書く手間は増えるが、型付けは Ruby より精密になる。

### 1.6 `T[...]` は型付き Array の構文

[報告] matrix（`Matrix[[1, 2]]` → `Matrix[]: an element must be Matrix`）, json（`JSON[s]` は書けない）, erb（`String[e, i, n]` と部分文字列のつもりで書いて、型付き Array の構築と解釈された）の 3 本。`Matrix.rows(Array[Array[1, 2], ...])` という呼び出し側は、Ruby より明らかに重い。

評価: **悪（軽度）**。理由: 構文の静的な意味は一貫しているが、Ruby のよく使う慣用句と衝突し、Ruby の意味を期待して書く手が繰り返し止まる。

### 1.7 演算子は左辺で dispatch する

[報告] matrix のみ。`2 * m` は書けず、`m * 2` と書く（`coerce` がない）。評価: **悪（局所的）**。理由: 数値型ライブラリでしか起きないが、そこでは必ず起きる。

---

## 2. 欠けている機能の代用

### 2.1 キーワード引数 → options Record と `_with`

[報告] Record を使ったのは csv, json, base64 の 3 本（base64 は「csv の慣習に合わせた」と書いている）。キーワード引数をあきらめて別の形にしたのは logger（setter で後から設定する）, matrix（`Vector.basis(3, 1)` と位置引数にした）, erb（`ERB.new(str, "-")`。Struct のフィールド既定値のおかげで第 2 引数は省略できる）, strscan / uri（その形は欠落）。

```ruby
CSV.parse(s, col_sep: ";", headers: true)          # Ruby
CSV.parse_with(s, {col_sep: ";", headers: true})   # Sake → CSVTable
```

良かった点 [報告 csv]: checker が Record の形ごとに特殊化するので、`{headers: true}` を渡せば結果が CSVTable、`{converters: :numeric}` を渡せば `Integer | Float` が加わる。しかも union は呼び出し側に出ない。csv の作者は「予想以上にうまくいった」と書いている。
悪かった点:
- [報告 csv] 綴りを間違えた option（`{colsep: ";"}`）が黙って無視される。Ruby なら `unknown keyword` で落ちる。
- [報告 csv] `headers: false` は例外にするしかない（フィールドがあるかどうかで型を選んでいるので、false でも表を返すことになる）。
- [報告 json, csv] `in {symbolize_names: true}` のようにリテラル値を書く Record パターンが使えない。`(o in {symbolize_names: x}) ? x == true : d` と書く。
- [報告 json] `symbolize_names` の値で型を選べないので、`JSON.parse(s)` も `Hash[String | Symbol => ...]` と推論される。Symbol キーの可能性がすべての呼び出しに漏れる。
- [報告 strscan] 同じ現象が flag 引数でも起きた。`do_scan(..., getstr)` の結果型が flag で分かれないので、結果の型ごとに関数を分けた。

[推論] 「フィールドがあるかどうか」は型を分けるが、「値」は型を分けない。この区別を知っていれば Record option はかなり使える。ただし、この区別は spec ではなく使った経験から学ぶしかない。

評価: **良（条件付き）**。理由: 型が精密になるのは Ruby より上。綴りの誤りが静かに通るのは Ruby より下。

### 2.2 省略可能引数 → 別名・nil・欠落

[報告] 省略可能引数がないことで、どこかの形を失ったか名前を変えたのは 13 本:
- 名前を変えた: abbrev（`abbrev_matching`）, zlib（`crc32_with`）, benchmark（`measure_label`）
- nil を渡す: prime（`Prime.each(nil) { ... break }`）
- 必須にした: date（`Date.step(d, limit, by)`、`strptime(s, fmt)`）, matrix（`Matrix.round(m, n)`）
- 形を落とした: cgi（第 2 引数）, csv, digest, strscan, tsort, uri（`URI.join` は 2 引数のみ）, optparse（`into` を必須にした）

このうち「欲しい」とはっきり書いたのは date, digest, zlib, strscan, tsort の 5 本。

```ruby
Zlib.crc32(s, crc)       # Ruby
Zlib.crc32_with(s, crc)  # Sake
d.next_day(3)            # Ruby
d + 3                    # Sake: next_day は引数を取らない
```

可変長引数もない [報告]: matrix（`diagonal(Array[...])`, `vstack(a, b)`）, csv / strscan（`values_at`）, optparse（`getopts` の long options を Array で渡す）, uri（`join`）, benchmark（`bm(w, *labels)`）。

評価: **悪**。理由: 18 本中 13 本で表の行が変わり、最も広く書き味に効いている。名前を変える代用（`_with`）は読めるが、名前が増える。

### 2.3 setter は `set_x`

[報告] strscan（`set_pos`）, uri（`set_host`）, logger（`set_level`）, optparse（`set_banner`）の 4 本。getter 側も benchmark（`get_utime`）, csv（`get_line_number`）が Struct の慣習どおり `get_` になっている。strscan では `ss.pos = 1` に対する hint が `Type.pos=(ss, ...)` を出すが、これは構文として書けない（bug repro あり）。

評価: **中立**。理由: 慣習は一貫していて読める。ただ、hint が一度間違った方向へ誘導する。

### 2.4 定数 → 関数

[報告] benchmark（`Benchmark.CAPTION`）, logger（`Logger.INFO`）, date（`Date.monthnames`）, digest（`MD5.k`）, zlib（`crc_table`）の 5 本が定数を関数にした。prime はキャッシュを持てず、毎回 sieve し直す。json は `Float::NAN` を `0.0 / 0.0` で、matrix は `Math::PI` を `Math.atan(1) * 4` で代用した。

```ruby
Logger::INFO       # Ruby
Logger.INFO        # Sake: 大文字名の関数として受け付けられる
```

呼び出し側の見た目はほぼ変わらない。ただし digest と zlib では、表が呼び出しのたびに作り直される（digest は 1 ブロックごとに 64〜80 要素の表を再構築する）。

評価: 見た目は **良**。性能は **悪**。理由: 書き味は保たれるが、表を引くアルゴリズムで実行のたびにコストを払う。

### 2.5 保存するブロック → データとして宣言した option

[報告] 7 本:
- optparse: `on` にブロックを渡さず、`parse(op, argv, opts)` で Hash を埋める。Ruby の `into:` の形。
- logger: formatter を proc の代わりに format 文字列にした。
- benchmark: `bmbm` が外側のブロックを 3 回走らせる。
- csv: 独自 converter は使えず、parse 後に `Array.map` する。
- tsort: callable 2 つの代わりに Hash でグラフを渡す（`tsort_hash`）。
- erb: 2.6 節。
- prime: generator オブジェクトは移植しなかった。

```ruby
op.on("-c", "--count N", Integer) { |v| opts[:count] = v }      # Ruby
OptionParser.on_type(op, "-c", "--count N", :Integer, "How many")  # Sake
rest = OptionParser.parse(op, argv, opts)
```

[推論] 評価は事例ごとに分かれる。
- optparse と tsort はうまくいった。Ruby 側にもともとブロックなしの形（`into:`、Hash）があったため。
- logger は「計算する formatter」（JSON エスケープなど）が書けない。
- benchmark の `bmbm` は意味が変わった: 外側のブロック内で report の外にあるコードが 3 回走る。
- csv の converter は「後で map する」で困らない。

評価: **中立**。理由: Ruby 側に宣言的な形があれば、ほぼ損をしない。なければ意味が変わる（bmbm）か、機能が欠ける（formatter）。

### 2.6 ERB は「Ruby 構文のサブセットを解釈するインタプリタ」

[報告 erb] eval も binding もないので、ERB を、Ruby 構文の部分集合で書かれたテンプレートの解釈器として作った。部分集合で書いたテンプレートは、Ruby の `result_with_hash` でも同じ出力になる。メソッドは閉じた集合（`size`, `join`, `upcase` など）で、値の型による dispatch はライブラリ内の `case v in String ... in Array ... in Hash` で行う。Struct のフィールドはテンプレートから読めない。テンプレートの中身は `--strict` の対象外。

```erb
<% items.each do |it| %>- <%= h(it[:name]) %>
<% end %>
```

評価: **中立**。理由: 「テンプレートはデータ」と割り切れば一貫しているが、Ruby の ERB 利用の大半（任意のコード、自作ヘルパー）は書き直しになる。作者自身が「データとしてのテンプレートの代償」と書いている。

### 2.7 コンストラクタを置き換えられない・既定値はリテラルだけ

[報告] 3 本:
- date: `Date.new(y, m, d)` が Struct の生のコンストラクタなので、検証用に `Date.civil` を用意した。`Date.new(2024, 1, 31)` は arity エラーになるので、黙って間違うことはない。
- optparse: `def new` が拒否され、`Array[]` は既定値にできないので nil にして遅延生成した。
- digest: `Integer[]` を既定値にできないので、状態をフィールド `h0`..`h7` に展開した。

評価: **悪**。理由: 3 本とも「初期化時に 1 回だけ何かする」ことができないための回り道で、digest ではデータの表現まで歪んだ。

### 2.8 private がない → `_` 接頭辞

[報告] cgi, uri, date（`module DateCore`）, digest, zlib の 5 本。要望としては誰も挙げていない。評価: **中立**。理由: 慣習で足りているが、内部関数が `--types` や補完に出る。

### 2.9 自前の `==` を持つ型は Hash キーにできない

[報告] date（Comparable なので Hash キーにできない。`h[date] += 1` は Ruby でよく書くのに、TypeError になる）, uri（`==` を定義するとキーにできなくなるので、正規化した比較をあきらめた）, matrix・digest（Struct の等価をそのまま使う）。

評価: **悪（date では重い）**。理由: 値型（日付・URI）は自然なキーなのに、正しい等価とキーとしての利用のどちらかを選ばされる。

---

## 3. 型検査器: ライブラリを書いていて助けになったところ・邪魔になったところ

### 3.1 助けになった [報告]

- json: generator の nesting error を `JSONParserError` に変えたら、テスト側の `rescue JSONGeneratorError` に対して `the begin body never raises JSONGeneratorError [rescue]` が実行前に出た。作者は「実行前に出た本物の検出」と書いている。
- date: `Date.jd(1.5)` が `case/in: no in branch matches Float` で報告される。`Date.new(2024, 1, 31)` は arity エラー。
- strscan: Integer のパターンを渡すと、`no in branch matches Integer` が利用者の行を含む hint 連鎖つきで出る。
- csv: `t[0]` は CSVRow、`t["age"]` は Array と、ユーザ定義の `[]` が呼び出しごとに型付けされる。CSV を使う側にとっては、空のフィールドが nil であることと、converter が数値でない値を String のまま残すことが型として見えるようになった（Ruby でも事実だが隠れている）。
- matrix: `angle_with` が平行なベクトルに対して Integer 0 を返すことを指摘された（Ruby でも同じ）。`m * v` は Vector、`m * m` は Matrix と型付けされる。
- uri: フィールドの順序を間違えたのを検出した（ただし原因から遠い所で。3.3 節）。
- 初回からほぼ報告が出なかった: abbrev, base64, shellwords, tsort, prime（`--strict=3` も通る）, csv（level 2 では修正不要）。

評価: **良**。理由: 型の推論で実際のバグと Ruby の隠れた事実を拾っており、注釈は 1 つも書いていない。

### 3.2 narrowing の穴 [報告]

| 書いたもの | 何が起きたか | lib |
|---|---|---|
| `if x in Integer ... else ...` | `case/in` なら絞り込まれるのに、`if` では絞り込まれない（bug） | date |
| `while jd == nil ... end; jd(jd)` | ループ後に nil が外れない | date |
| `unless (a in Integer) \|\| (a in Float)` | `\|\|` を越えて絞り込まれない | erb |
| `@pos >= @len` で守った後の `@src[@pos]` | フィールドで守っても添字の結果が絞り込まれない | json |
| `rel = parse(other) if other in String` | 再代入した局所変数が union のまま残る | uri |
| `while !Array.empty?(tmp)` + `Array.shift` | shift の結果が nil のまま | uri |
| `Array.[](cs, 1, 2)` | Array ではなく要素型と型付けされる（bug） | benchmark |

```ruby
# Ruby の書き方
rel = other
rel = parse(other) if other in String
# Sake で通る形 (uri)
def _as_uri(x) = case x in String then parse(x) in URI then x end
```

[推論] どれも書き換えれば回避でき、書き換えた後の形（`case/in`、`while (c = ...)`）は Ruby として読んでも悪くない。ただ「Ruby で自然な制御構造は、どれを使えば絞り込まれるのか」を覚える必要がある。上の 7 件はすべて別々の作者が別々に踏んでいる。

評価: **悪**。理由: 書き換え先はあるが、書き味の上では「書いた後に checker の流儀に合わせる」作業になっている。

### 3.3 原因から遠い所で報告される [報告]

- matrix: テストで 1 か所 `Matrix.collect(a) { |e| Integer.to_s(e) }` と書いただけで、matrix.sake の中に数十件の `[type]` 報告が出た。
- csv: `--strict=3` で出る 16 件のうち 14 件は、呼び出し側の `t[0]`（nil かもしれない）が原因なのに、ライブラリ内を指す。
- uri: フィールドの順序を間違えると、`to_s` の中で `Array.push: an element must be String` と報告される。
- hint が無関係のフィールドを名指しする: strscan（`StringScanner.mstr may be nil`、bug repro あり）, erb（`ERB.trim_mode may be nil`）, uri（「URI のフィールド 8 つすべてが nil かもしれない」）の 3 本。

評価: **悪**。理由: 報告そのものは正しいのに、場所と hint が原因を指さないので、ライブラリの作者が自分の側のバグだと思って追いかけてしまう。

### 3.4 `--strict=3` の index-nil の雑音 [報告]

cgi, date（`String.[](s, i, n) || ""` を毎回書く）, digest（161 件）, json, erb, csv（2 件）の 6 本。level 2 では消える。matrix はもっと細かい話を報告している: ライブラリが literal の `nil` を返すと、利用者側で level 2 の `[nil]` 報告になる。`(@rows[i] || Array[])[j]` と書いて nil を添字由来に変えれば、`a[k]` と同じ level 3 扱いになる。

評価: **中立**。理由: level の設計どおり（level 2 では静か）だが、「どこで nil を作るかで利用者に出る level が変わる」のは、ライブラリ作者だけが知っておくべき暗黙知になっている。

---

## 4. 繰り返し出た Ruby の癖と、メッセージで直ったか

| 癖 | 本数 | メッセージ | 直ったか |
|---|---|---|---|
| `x in T ? a : b`（優先順位） | 6: benchmark, csv, json, logger, optparse, date | Prism の `syntax error: unexpected '?'`。date の `def f(n) = n in Integer` は `only def and include are allowed in a class/module body` | 直ったが、メッセージからではなく既知の罠として知っていたから。date の作者は「メッセージが parse を示唆しない」と書いている。csv の作者は最初から括弧をつけていた |
| `require "x"` がテスト自身を読む | 7: csv, cgi, date, matrix, prime, optparse, strscan | `undefined type or module X` が全行に出る | メッセージでは直らない。ローダを修正した（ea484f6） |
| キーワード引数 | 2: csv, json（ほかは最初から避けた） | `keyword arguments are not supported` | 直った（明快） |
| ブロックなしで Enumerator を受け取る | 2: base64, prime | base64: `String.each_char requires a block` は明快。prime: hint が `Prime.to_a(Prime.each(10))` で、間違い | base64 は直った。prime は hint に誤誘導された |
| `module M` 内で `def M.f` | 2: digest, tsort | `write def f` と出るが、それに従うと mixin 関数になってしまう | hint は不正確。module_function を使うか、本体の外で定義して回避した |
| `def new` で再定義 | 2: date, optparse | `is a built-in operation and cannot be redefined` | 明快。ただし代わりの方法は示されない |
| `ss.pos = n` | 1: strscan | `Type.pos=(ss, ...)`（書けない形） | 誤誘導（bug repro あり） |
| `String[e, i, n]` を部分文字列のつもりで書く | 1: erb | `element 3 must be String` | 直った |
| 隣接する文字列リテラルに式展開 | 1: uri | `unsupported part of an interpolated literal` | `+` で連結した |
| `case/when` | 1: abbrev | （書く前に避けた） | `if/elsif` |
| break の値を使う慣用句 | 1: prime | — | flag 変数を使って明示的に書いた |
| 組み込みのエラーメッセージに接頭辞 `Hash.fetch: ` がつく | 2: strscan, tsort | — | テストで接尾部分だけを比べた |

評価: **中立〜悪**。理由:
- 明快なメッセージ（キーワード引数、ブロック必須、`new`、Bitwise の include）は 1 回で直っている。
- 6 本が踏んだ `in ? :` には専用のメッセージがない。
- hint が間違った方向を示す例が 4 件ある（setter、`def M.f`、`Prime.to_a`、無関係のフィールド名）。

---

## 5. 汎用コンテナの型が大まかになる

[報告] 4 本:
- matrix: プログラムのどこか 1 か所に String の Matrix があるだけで、`rows` フィールドの型が全関数で `Array of (Integer | ... | String)` になる。Complex のベクトルが 1 つあると、`inner_product` の結果がどこでも Complex かもしれないと扱われる。作者の結論は「汎用コンテナは、プログラム全体で要素の種類が 1 つのときだけ機能する」で、experiments/2026-10-03-libraries/linalg と同じ所見になった。
- tsort: `TSortHashGraph.h` が全呼び出し元の Hash 型の union になる（今回は無害）。
- json: 結果は再帰的な union 全体になり、利用者は `if v in Hash` で絞り込む。メッセージには 300 文字の union が出る。
- csv: `(String | nil)[]` が書けないので、行は型のない Array になる。

```ruby
# 1 行足すだけで matrix.sake 内に数十件の報告
Matrix.collect(a) { |e| Integer.to_s(e) }
```

[推論] 1.5 節と 2.1 節で関数の引数が呼び出しごとに特殊化されるのとは対照的に、Struct のフィールドは「プログラムで 1 つの型」になる。関数ではうまくいく型の流れが、フィールドを経由した瞬間に途切れる。ここが書き味の境目になっている。直前の `state-survey` 実験（commit c64f7ac, 84aecec）が扱った問題そのもの。

評価: **悪**。理由: Ruby の主な汎用ライブラリ（行列、表、グラフ）の使い方を 1 か所で壊し、しかも報告がライブラリの中に出る（3.3 節）。

---

## 6. 性能の体感

[報告] 計測はすべて共有機（load 16〜40）で行われており、作者自身が目安だと断っている。sp4 は他の session が lease 中で使えなかった（digest）。

| lib | 観測 |
|---|---|
| digest | MD5 で約 13 KB/s、SHA256 で約 5 KB/s。Ruby の C 実装より 4〜5 桁遅い。1 MB のファイルに数分かかる |
| zlib | crc32 / adler32 で数十 KB/s |
| base64 | テスト（256 バイトと短い文字列約 60 個）に約 3 秒 |
| json | テスト（parse 約 60 回、generate 約 30 回）に約 6 秒、大半は検査 |
| csv | 引用符つきの 2000 行で約 1.2 秒（split の経路なら約 0.2 秒） |
| strscan | 1 呼び出しあたり約 0.8 ms。残りの文字列を毎回コピーするコストは、この大きさでは見えない |
| logger | 1 行書くごとにファイル全体を読み直して書き戻すので O(n²) |
| prime | キャッシュがないので、呼び出しのたびに sieve し直す |

[推論] 遅さの原因は 3 層ある:
1. Ruby で書いたインタプリタそのもの（全般）。
2. 位置を指定する文字列操作がない（`String.index` に開始位置がない、位置を指定する match がない、byteslice がない）ので、残りをコピーするか 1 文字ずつ歩く: cgi, csv, json, erb, shellwords, strscan, digest。
3. 定数がないので表を作り直す: digest, zlib。

2 と 3 は言語やライブラリの欠落によるもので、インタプリタを速くしても残る。

評価: **悪**。理由: 書き味としては「Ruby の書き方では遅い」ではなく「Ruby の書き方が書けないので遅い書き方を強いられる」形で表に出ている。

---

## 言語設計者向けの要点 5 つ

1. **省略可能引数（または名前ごとの arity overload）が、最も広く書き味を削っている**（13 本で表の行が変わり、5 本がはっきり要望した）。キーワード引数の代用としての Record は形で特殊化されてうまく動くので、残りは次の 2 つ。
   - リテラル値の Record パターン（`in {headers: true}`）
   - 未知フィールドの検出（綴りの誤りが黙って通る）
2. **位置を指定する文字列プリミティブを足す**: `String.index(s, t, pos)`、位置で anchor した `Regexp.match`、`byteslice`、ブロックを取る `gsub`。6 本以上が自前の走査器を書き、O(n) のコピーを払っている。どれも組み込みの範囲で済み、ブロックを値にしなくてよい。
3. **Struct フィールドの型がプログラム全体で 1 つになることが、汎用コンテナを壊す**（matrix, tsort, json, csv）。しかも報告がライブラリの内側に出る。フィールドの型を呼び出し側から追えるようにするか、少なくとも報告を原因の位置（混ぜた側の `new` / 代入）に出す。
4. **メッセージを安く直せる所が多い**: `x in T ? :` の優先順位（6 本）、setter の hint は `set_x` を出す、`def M.f` の hint、`Prime.to_a` の誤った hint、nil の hint が無関係のフィールドを指す（3 本）、組み込みエラーの `Op: ` 接頭辞。正しい checker が誤った hint のせいで信用を失っている。
5. **「1 回だけ評価する」手段がない**: 値定数、非リテラルの既定値、`new` の置き換え。この不在が性能（digest, zlib, prime）とデータ表現（digest の `h0..h7`、optparse の遅延 nil、date の `civil`）の両方に効いている。あわせて CLI 用ライブラリには `ARGV` / `exit` / `$stderr` / ファイル追記が足りない（optparse, logger）。

[推論] 逆に、変えなくてよいと示されたもの:
- ブロックを値にしないこと（Ruby 側に宣言的な形があればほぼ損をしない。optparse, tsort）
- 型名を書く呼び出し形（誰も friction に挙げていない）
- include による演算子
