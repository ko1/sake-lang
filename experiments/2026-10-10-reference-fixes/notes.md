# 利用感（2026-10-10: リファレンスの執筆と、その課題の解消で Sake を使って気づいたこと）

出典: リファレンスを書いたエージェント 8 体の報告（10-10 朝）、課題を直してリファレンスを追従させたエージェント 6 体の報告（10-10 午後、`brief-docs.md` の「Usage notes」）、筆者（修正・テスト・probe を書いた側）。約 1,500 本の例と 70 本の library port を `--strict=2` で回した上での観察。

## 良かったこと

- **例が全部走る文書が書けた。** `# => 値` と `# !> 文言` の照合を機械にやらせると、書き手は「出力を見てから書く」しかなくなる。約 1,500 本の例のうち、処理系を直したあとに食い違ったのは 104 か所で、全部その日のうちに直せた。Ruby の文書で同じことをするのは難しい（`Time.now` のような値は `in:` を渡して固定した）。
- **型の問題は 1 行で出て、行と列が合っている。** エージェントの報告に「hint が先回りしていた」が複数ある: `ARGV[0]` → `Array.fetch`、`x.nil?` → `x == nil`、`def` の位置、`attr_reader` の綴り。
- **`p(a, b, c)` が 1 行ずつ出る**（Ruby と同じ）ので、probe を書くのが速い。`Kernel.inspect(e)` で例外の種類と文が一度に見える。
- **union の呼び出し** `(A|B).f(x)` と、`case x in Integer | Float` の絞り込みは、Ruby の duck typing を置き換える手段として十分だった。今日足した「本体が `param in Pattern` の関数は条件で引数を絞る」で、`if number?(x)` と書く Ruby の癖もそのまま通る。

## つまずいたこと（書き手の側）

- **ラムダが無い。** 失敗する呼び出しを 30 個並べて順に `rescue` する probe を `-> { ... }` の表で書こうとして、全部 `unsupported syntax: lambda` になった。`begin/rescue/end` を 30 回書くか、Ruby 側で生成するしかない。テストの表や callback の表を書くときに毎回ぶつかる（proc 値は D で見送った判断）。
- **endless def の本体に `in` や修飾 `if` を書くと、Ruby の文法上 def 全体に掛かる。** `def number?(l) = l in Integer | Float` は「def を pattern match する」と読まれて `def must be at the top level` になり、`def initialize(c) = @x = 1 if @x == nil` は class 本体の規則の文で弾かれた。どちらも Ruby の仕様だが、Sake では endless def を多用するので踏みやすい。後者には hint（`= (body if cond)` と括る）を足した。前者は括れば通る。
- **`String.dup` が無い**（`Kernel.dup`）。hint が `dup` を持つ名前空間を 3 つ挙げてくれたので 1 回で直ったが、「どの名前空間に置かれているか」を当てる作業は Ruby には無いもの。
- **`"..." % record` が `Arithmetic.%` として報告される。** 演算子はモジュールに属するので `%` は Arithmetic だが、String の format で `Arithmetic` の名が出ると一瞬迷う。
- **`r = 3..` は次の行に続く**（Ruby と同じ）。章には `(3..)` と書けと注記した。
- **検査器が同じ一時ディレクトリで章の全例を走らせる**ので、例の中のファイル名は節ごとに違えないと前の例の残骸を読む。

## 「操作に型を書く」が効いた場面と、きつかった場面

- **効いた**: 並べ替えの要素型の混在（`Array.sort(Array[1, "a"])`）を静的に弾くようにしたら、ふだんの程度のコードでは何も起きず、ちょうど「混ぜている」コードだけが止まった。`<` と同じ基準に揃っただけとも言える。
- **きつかった**: 同じ検査で library port 70 本のうち 4 本（erb, liquid, redis, concurrent_ruby）が止まった。テンプレートの filter `sort` が受けるのは「何でも入っている」Array で、Ruby なら実行時に揃っていれば通る。Sake では「全部 String なら String で、全部数なら数で並べ、それ以外は ArgumentError」と 5 行書くことになった（`sakelib/erb.sake` の `sort_values`）。動的なデータを扱うコードは、型を操作に書く以上、この種の関門を自分で書くことになる。それが「正直」なのか「手間」なのかは用途による。
- **型を保つために Ruby と違える判断**: `Arithmetic.round(1234.5, -2)` を Ruby の `1200`（Integer）ではなく `1200.0` にした（桁指定の結果は主語の型）。検査器が値を見ずに型を決めるには、こうするか `Integer | Float` を返すかしかない。matrix の移植がこれで 1 行変わった。同じ理由で `rand(0)` はエラー、負の底の `**` は Math::DomainError（Ruby は Complex）。
- **Ruby の例外が処理系の境界で漏れていた**のは、「組み込みは Ruby をそのまま呼ぶ」実装の宿命で、網羅的に直すには境界で 1 回写すのが正解だった（`Interpreter#ruby_run_error`）。個別の `ruby_error(kind)` の網は 4 か月で 2 か所に分かれ、片方が片方を影にしていた。

## 文書を書いて見えた API の歪み（直したもの）

- 関数形 `Integer.==(1, "a")` が TypeError で演算子形 `1 == "a"` が false。
- `!` 形と素の形で署名が違う（`chomp` / `delete` / `squeeze` / `slice` / `byteslice`）。
- 「外れの nil」のレベルが操作ごとに違う（`a[i]` は 3、`Array.slice(a, i)` は 2、`Set.first` は 2）。
- `Hash.dig` / `Array.dig` が鍵を 1 つしか取らない（名前が Ruby の多段を約束している）。
- `Hash.flat_map` の block が `[k, v]`（Tuple）を返せない。
- `format("%<a>d", {a: 1})` に Record を渡せない（Hash が要った）。
- `Set[...]` だけが Set を作り、他の `T[...]` は T の Array を作る（これは直さず、章の冒頭に書いた）。

## 残っている違和感（直していない）

- `Set.select` が Array を返す（Ruby は Set）。`Set.merge` / `union` が Set しか取らない。
- `Regexp.timeout` は常に nil なのに `Float | nil`。`Range.first(r)` は `T | nil` だが nil になるのは beginless のときだけ。
- Zlib / Socket の結果が ASCII-8BIT で、`== "日本"` が false になる（`force_encoding` が要る）。
- スレッドで後から走る block の引数がループ変数の最後の値を読む（Ruby は呼び出しごとに新しい）。
- `gsub` / `scan` の block から MatchData（`$1`）に触れない。

## 章を追従させたエージェント 6 体の utilization notes（10-10 午後、要約）

良かった:
- 並べ替えの静的検査の文言が「どの組が比べられないか」を名指しする（`elements compared in order may be (Integer, String)`）ので、7 つの節に同じ `ruby error` の型で書けた。`Thread.value` の結果（`nil | String`）を `Array.sort` に渡した例が `[nil]` で止まり、`Array.compact` 1 つで直った。「ちょうど正しい捕まえ方」。
- 例外は `begin ... rescue X => e; puts(Exception.message(e)); end` で種類を問わず同じ形。`rescue` の検査（`the begin body never raises RuntimeError`）が、例を走らせる前に文書の誤りを 1 件見つけた。
- hint が先回りする: `String.equal?` → `Kernel.equal?`、`p(d in Integer[])` → 「`(x in T)` と括る」、`argument 1 must be Rational, but can be Float` → `case x in Rational ... in Float`。
- `IO.winsize` が Tuple なので `rows, cols = IO.winsize(io)` が nil 検査なしに型が付く。`Socket` の `==` が同一性になって `Kernel.equal?` の回り道が消えた。
- 「桁を指定したら主語の型」の規則が `half:` と組んでも崩れない（`Float.round(2.5, half: :even)` は 2、`Float.round(2.5, 0, half: :even)` は 2.0）。
- `ENV.replace(ENV.to_h)` の save / restore で ENV の例が自己完結した。

つまずいた:
- **`rescue RuntimeError` の静的検査**が、組み込みの中で Ruby が投げる RuntimeError（`String.undump`）を知らず、「この rescue を消せ」と間違った助言をした（→ Ruby 自身の RuntimeError は ArgumentError に写すことにして解消）。`Thread.raise` を helper に移すと同じ検査に当たる（hint に Thread.raise を足した）。
- **nil のレベル（2 か 3 か）はソースを見ても分からない**。`MatchData.begin` と `bytebegin` で違っていた（→ 揃えた）が、知るには `--strict=2` と `3` で 2 回走らせるしかない。「この結果の nil はどの種類か」を聞く手段が欲しい。
- 演算子形のエラーが `Arithmetic.*` / `Arithmetic.%` / `Arithmetic.**` の名で出る（`"ab" * -1`、`"%d" % 1`、`(-8.0) ** 0.5`）。関数形は `String.*` / `Float.**`。演算子がモジュールに属する設計の見え方で、読み手は `String.*` を期待する。
- `Process.clock_gettime(c, unit)` の単位が変数だと `Integer | Float` になり、`def elapsed(unit) = ...` のような helper の結果を `Integer.to_s` に渡せない。リテラルだけ読む「継ぎ目」が驚かせる。
- `Time.to_a(t)[9]` の `String | nil` は正しいが、zone 1 つのために 10 要素の分解は重い（実際は `Time.zone(t)` を書く）。
- `Hash.dig` の index-nil の hint が `Array.fetch / Hash.fetch` を勧めるが、多段 dig に fetch 相当は無い。
- 検査器は `--strict=2` で例を走らせるので、level 3 の nil（`Set.first`、`Range.minmax` など）は失敗する例として見せられず、文で述べるしかない。`ruby error` の block は 1 行しか失敗させられないので、例外ごとに block が要る（1 block に複数の `# !>` を別々に走らせる機能があれば短くなる）。終了コード 0 で stderr だけ出るもの（読まれなかったスレッドの報告）は、どちらの block にも入らない。
- 端末の操作（`IO.winsize` など）は検査器では走らない（stdin が pipe）。`printf 'x\n' | script -qc "bin/sake x.sake" /dev/null` で確認した（`ref-brief.md` に追記）。
- `lib/` が動いている最中に章を書くと、同じ probe が時刻で違う答えを返す（`format("%<n>d", {n: 1})` が最初は `one hash required`、後で `"1"`）。最後に全章を再実行することが必須。
- 検査を静的にすると、実行時の形は `--strict=0` でしか見せられず、例の実行器はそれを検証できない（`ruby error --strict=0` のような fence があれば検証に乗る）。
- `Hash.dig` が容器の和（Hash と Tuple が同じ値の位置に来る）を掘るとき、Tuple の枝に String の鍵が流れて偽の `type` になった（→ 鍵が Integer になりえない枝は追わないようにした）。
- 例の中で値の型を示す簡単な手段が無く、`p(Integer.to_s(ms) == "#{ms}")` のような回り道をした（`Kernel.class` に相当する操作があれば例が短い）。

残った違和感（直していない）:
- `Regexp.union("a", Array["b"])` や `Regexp.union(Array[1, 2])` は署名が `*String|Regexp|Array` なので静的に通り、実行時 TypeError。`Regexp[]` の型付き Array が無い。
- `String.slice("hello", "ll", 1)` のように、第 1 引数が String / Range のとき第 2 引数は意味が無いのに静的に通る（Ruby も実行時 TypeError）。
- `Integer.pow(2, -1, 7)` の文が Ruby の引数番号（「1st argument」）で、Sake の見え方（2 つ目）とずれる。`Integer.sqrt(-1)` の文に Ruby の `"isqrt"` の引用符が残る。
- `Range.first(1..5, -1)` は RangeError、`Range.take(1..5, -1)` は ArgumentError（Ruby のまま）。
- `half:` を `Arithmetic.floor` に付けると、ユーザー関数向けの文（`keyword arguments go only to functions with keyword parameters`）で弾かれる。
- `Math.log(8, 0)` は `-0.0`、`Math.log(8, 1)` は NaN（Ruby のまま）。
