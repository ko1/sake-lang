# Sake の新規性: 言語観の比較（2026-10-10）

問い: Sake の設計のうち、何が新しく、何が既存の言語にあるものの組み合わせか。軸ごとに先行例と並べて判定する。判定は 3 段階: **新**（同じ規則を持つ言語を知らない）、**組**（個々の要素は既存で、組み合わせ方か徹底の度合いが Sake 固有）、**既**（先行例がそのままある）。出典は末尾。知識の範囲での比較なので、見落としがあれば追記する。

## 結論

- **個々の機構のほとんどには先行例がある。** module 関数だけで操作を呼ぶのは Elixir・Erlang・Elm・Roc・Gleam・OCaml・Odin の形、「操作は型に属さず、呼び出しは関数で、引数の型が実装を選ぶ」のは CLOS・Dylan・Julia の generic function、注釈なしの全プログラム型推論は Crystal・RPython・DRuby・TypeProf と Elixir 1.17 以降の型システム、`M.f(x)` のディスパッチは CLOS の generic function、Rust の `Trait::f(&x)`、Clojure の protocol、`Enum` は Elixir と Ruby の Enumerable、厳格レベルと「外れの nil」は TypeScript の strict フラグ（`noUncheckedIndexedAccess`）、構築場所ごとの型は points-to 解析の allocation-site abstraction。
- **新しいのは型を書く場所と、組み合わせである。** (1) 束縛（変数・引数・返り値・フィールド）への型注釈を**禁じ**、操作の修飾 `T.op(x)` を**唯一の**型情報にすること。最も近いのは Elixir で、束縛に型を書く構文が無く、呼び出しは慣習として常に module 関数で、新しい型システムは関数呼び出しから推論する。Sake はその慣習を規則にした: module 名は省けず、`T` は第 1 引数の型そのもので、検査器がその一致を使う。Elm 系は呼び出しの**形**が同じだけで、型は束縛に書く側の言語であり（module 名も `exposing` で省ける）、Crystal は推論するがメソッド呼び出しを持つ（§A の表）。(2) その修飾を推論の錨にして、構築場所ごとの型・段階的な厳格さ・「外れの nil」の分離・`mixed` の区別を 1 つの検査器にまとめたこと。(3) 「AI が書きやすいか」を目的にし、同じ課題を 6 言語で書かせて隠しテストとトークン費用で比べる評価を行ったこと（結果は否定的で、未知の言語の費用の下に埋もれた）。
- 一文で言えば、**「Elixir の呼び方（module 関数、束縛に型を書かない）を規則にし、Ruby の構文、Crystal の推論、TypeScript の strict フラグ、CLOS 風の静的な generic function を与え、メソッド呼び出しと型注釈を禁じた言語」**である。Elm から借りているのは呼び出しの形だけで、型を書く場所については Elm の逆を選んでいる。設計文書が「Elixir の意味論を目指しているわけではない」と断っているのは、値の可変性・クラス・nil・例外について正しい。しかし型を書く場所と呼び方については Elixir が最も近く、重なりは `Enum` だけではない。

## 比較の軸

| 軸 | Sake の規則 | 最も近い先行例 | 判定 |
|---|---|---|---|
| A. 型を書く場所 | 操作に書き、束縛には書けない | Elixir / Erlang（注釈の構文が無く、呼び出しは慣習として module 関数。module は型でなく名前空間、`import` で省ける）。Elm / Gleam は呼び方の形だけが同じで、型は束縛に書く側 | **新**（小） |
| B. 値へのメソッド呼び出しが無い | `x.f` は静的エラー、`T.f(x)` と書く | Elm, Roc, Gleam, OCaml, Erlang, Odin, Hare, C | **既** |
| C. 連鎖 `x.T.f` と `_` | 連鎖の段が型を名乗る。`_` は直前の文の値 | パイプ `\|>`（Elixir, F#, Elm）、UFCS（D, Nim）、REPL の `_` | **新**（小） |
| D. 注釈なしの全プログラム推論 + 実行時検査 | 推論は全体、値は型タグ、検査は常に走る | Crystal, RPython, DRuby, TypeProf, Dialyzer | **組** |
| E. 構築場所ごとの型と `mixed` | `Point.new` の場所ごとに別の型、出会いを `mixed` と呼ぶ | allocation-site abstraction（Andersen, Milanova）、Starkiller | **組**（利用者に見せる点は新） |
| F. 厳格レベルと「外れの nil」 | 0〜4 の項目選択。`a[i]` の nil は level 3 | TypeScript の `strict*` / `noUncheckedIndexedAccess`、mypy `--strict`、Sorbet の sigil | **組** |
| G. mixin ディスパッチ・写し・継承なし | `M.f(x)` は第 1 引数の型へ。`include` と `<` は写し | CLOS / Dylan / Julia の generic function（静的・単一にしたもの）、Rust の `Trait::f(&x)` と default method、Clojure protocol、Go の埋め込み | **既** |
| H. `(A\|B).f(x)` | 呼び出しの場で型を列挙してディスパッチ | C++ `std::visit`、TypeScript の union、Typed Racket | **新**（小） |
| I. Tuple / Record / Array / Hash、`T[...]` | リテラルは Tuple と Record、`Array[...]`、`Integer[1, 2]` | Elixir（`{}` と `[]`）、Elm/TS の構造的レコード、Julia の `Int[1, 2]` | **既** |
| J. 演算子は module の関数 | `a + b` は `Arithmetic.+(a, b)`、左の型に解決 | Rust `Add::add`、Haskell `Num`、Elixir `Kernel.+` | **既** |
| K. 漏れる例外の推論 | `unrescued` を注釈なしに推論 | Nim の例外追跡、Koka の効果推論、Java の検査例外（宣言） | **既** |
| L. 名前空間の入れ子、prelude の `Enum` | `A::B`、`Enum.map(x)` は型へディスパッチ | Ruby の Enumerable（each の上に書く）、Elixir の Enum/Enumerable protocol | **既** |
| M. AI 向けという目的と評価 | 書きやすさを仮説にし、6 言語で同じ課題を測る | NanoLang（2026-01）、AIDL（2025-02）、MultiPL-E/MultiPL-T の低資源言語研究 | **新**（問いと方法） |

以下、軸ごとに述べる。

## A. 型を書く場所

Sake: 操作は `String.upcase(s)` と型を名乗って呼び、変数・引数・返り値・フィールドには型を書けない（書くと静的エラー）。型の情報源は操作の修飾だけで、束縛の型はそこから推論する（DESIGN.md「思想: 型を書く場所を逆にする」）。

| 言語 | 操作の書き方 | 束縛の注釈 | Sake との差 |
|---|---|---|---|
| Elm | `String.toUpper s`、`List.map f xs` | 任意（慣習的に関数には書く） | 核ライブラリは主語の型で module を分ける点が同じ。ただし module 名は `import String exposing (toUpper)` で**省ける**し、注釈は束縛に書く。型を書く場所は Sake の逆 |
| Roc | `Str.toUpper s`、`List.map xs f` | 任意 | 同上。主語を先に置く引数順は Sake と同じ。2024 年末に `xs.map(f)` と書いて型で静的に解決する方式（static dispatch）への転換を決めた。module 名の繰り返しを冗長と見た、Sake と逆向きの判断 |
| Gleam | `string.uppercase(s)`、`list.map(xs, f)` | 任意（公開関数には必要） | 同上。`import gleam/list.{map}` で module 名を省ける。パイプ `\|>` で連鎖 |
| OCaml / F# | `String.uppercase_ascii s`、`List.map f xs` | 任意、.mli で明示 | module は型と一致するとは限らない。オブジェクトと `#` のメソッドもある |
| Elixir | `String.upcase(s)`、`Enum.map(xs, f)`、`Map.get(m, k)` | **束縛には書けない**（構文が無い）。`@spec` は関数に任意、Dialyzer が読む | **最も近い**。メソッドは無く、呼び出しはほぼ常に module 関数で、束縛に型を書く構文が無い。1.17 以降の型システムはパターン・ガード・既知の関数呼び出しから注釈なしに推論する（Sake の typer と同じ情報源）。差は 3 つ: `import String` で module 名を省ける（スタイルガイドは勧めない）、module は型ではなく名前空間（`Enum`、`Kernel` の `length(x)`、`elem(t, 0)` は裸）、`Enum.map` は実行時に protocol で振り分ける |
| Erlang | `string:uppercase(S)`、`lists:map(F, L)` | 無し。`-spec` は任意 | 同上。module は型ではなく機能の単位（`lists`、`maps`、`string`）。`-import` は非推奨 |
| Common Lisp / CLOS | `(string-upcase s)`、`(vector-push x v)`、generic function `(area shape)` | `(declare (type fixnum x))` は任意。SBCL が推論と警告 | メソッドは無く、呼び出しは常に関数。組み込み関数は名前に型を含める慣習（`string-`、`char-`、`hash-table-`）だが規則ではなく、CLOS の generic function は引数の class で実行時に振り分ける。注釈は束縛に書く側 |
| Julia | `uppercase(s)`、`push!(xs, 1)`、`length(xs)` | `x::Int` は任意。主に多重ディスパッチのため | メソッドは無く、関数名に型は無い。型は注釈（引数）と実行時のディスパッチに属する |
| Lua / Python | `string.upper(s)`、`str.upper(s)` | 無し / 任意（3.6 以降） | 同じ形で書**ける**が、`s:upper()` / `s.upper()` が普通。型の修飾は検査されない（Python の `str.upper(3)` は実行時エラー） |
| Odin / Hare / Zig / C | 手続きのみ（Odin, Hare, C）、`T.f(&x)` も可（Zig） | 必須 | メソッドが無い点は同じだが、型注釈は必須 |
| Rust | `Vec::push(&mut v, 1)` と `v.push(1)` の両方 | 推論あり、関数の署名は必須 | 完全修飾の形（UFCS）が存在するが、普段はメソッド呼び出し |
| Crystal | `s.upcase` | 任意（ほぼ推論） | 注釈なしで書けるが、操作は**メソッド**。型は宣言側に属する |
| Austral | 明示的な宣言、推論を意図的に持たない | 必須 | 「暗黙を排する」思想は近いが、束縛に書く側 |

判定: **新（小）**。先行例と見えるものを 2 つの問いで分けると、Sake の席は空いているが、隣に Elixir と Erlang がいる。

| | 操作の修飾 `T.f(x)` が**必須**で T は第 1 引数の型 | 修飾は任意、または module は名前空間 | 修飾は無い（メソッド、または裸の関数） |
|---|---|---|---|
| 束縛の注釈が**無い・禁止** | **Sake** | **Elixir, Erlang**（慣習として常に書く） | Ruby, Lua |
| 束縛の注釈は任意 | （無し） | Elm, Roc, Gleam, OCaml, Common Lisp（関数名の慣習） | Crystal, Python, Julia, TypeScript, Kotlin |
| 束縛の注釈が必須 | Odin, Hare, C（手続き名に型を含める慣習） | Zig | Java, C# |

Elm 系が Sake に見えるのは、オブジェクトが無いので関数が型ごとの module に置かれ、呼び出しが `String.toUpper s` の**形**になるからである。しかしその module 名は `exposing` で省けるし、型の情報は束縛の注釈と推論に属する。Elm の文書に「`String.toUpper` と書くことが型を書くことだ」という見方は無い。Elm は型を**束縛に**書く言語で、Sake の原理の逆側にいる。Crystal は注釈を書かない方向で近いが、操作はメソッドで、呼び出しの場に型は現れない。Common Lisp は `string-upcase` のように関数名に型を含めるが、それは慣習で、CLOS の generic function `(area shape)` には型が現れない。

**最も近いのは Elixir**である。束縛に型を書く構文が無く、メソッドが無く、呼び出しはほぼ常に `String.upcase(s)` の形で、1.17 以降の型システムはパターン・ガード・既知の関数呼び出しから注釈なしに推論する。DESIGN.md も「モジュール名で関数を呼ぶので操作の型が先に決まる状況は OCaml と Elixir がもともとそう」と認めている。Sake と Elixir の差は、Sake が慣習を**規則**にした点に尽きる: (1) module 名は省けない（Elixir は `import`）、(2) `T.f(x)` の T は第 1 引数の型そのものであって名前空間ではない（Elixir の `Enum`、`Kernel` の `length(x)` は型を名乗らない）、(3) 検査器はその一致を使い、違えば静的エラーにする（Elixir の `Enum.map` は実行時に protocol で振り分ける）。「使うたびに型を書く冗長さが整合性の検査になる」（DESIGN.md）という位置づけは、この (2) と (3) があって初めて成り立つ。

この**新**は「隣の席の慣習を規則に格上げした」程度の新である。良い席かは別の問い（§総合の末尾）で、Elixir がその規則を持たないまま成功していることは、規則の価値を疑う材料にもなる。

## B. 値へのメソッド呼び出しが無い

Sake: `x.op(...)` は静的エラーで、hint が `T.op(x)` と `x.T.op` を示す。

先行: 関数型言語の多くと C 系の一部にメソッドは無い（上表）。Elixir と Erlang は module 関数だけ。Common Lisp（CLOS）・Dylan・Julia は generic function で、`(area shape)`、`area(shape)` と関数の形で呼び、引数の class で実行時に振り分ける。「オブジェクトにメッセージを送る」Smalltalk 系に対し「関数が引数で振り分ける」系譜がもともとあり、Sake の `T.f(x)` と mixin ディスパッチ（§G）はこちらに属する。Smalltalk・Ruby・Python はその逆。Roc は module 関数の形で始めて、2024 年末に `xs.map(f)` の形（型で静的に解決）へ移る決定をした。メソッドの形が好まれる証拠として重い。判定: **既**。Sake 固有なのは、Ruby の構文のままメソッド呼び出しを**禁ずる**こと（構文は通るが意味として拒む）と、拒むときに書き換え先を機械的に示すことである。

## C. 連鎖 `x.T.f(...)` と `_`

Sake: `x.T.f(a)` は `T.f(x, a)`。連鎖の各段が型を名乗る。`_` は同じ本体の直前の**文**の値。

| 言語 | 形 | 差 |
|---|---|---|
| Elixir, F#, Elm, OCaml, Gleam, R | パイプ `x \|> f(a)` | 段に型が現れない。Sake の `.T.` は「この段は T の操作」を読み手に言う |
| D, Nim | UFCS: `f(x, a)` を `x.f(a)` と書ける | 逆方向（関数をメソッドに見せる）。型は現れない |
| Kotlin, C#, Swift | 拡張メソッド | 宣言側で型に結び付ける |
| Python / IPython の REPL、Clojure の `*1` | `_` は直前の結果 | REPL だけ。ソースに書く言語は知らない |
| Perl / Raku の `$_` | 話題変数 | ループやブロックの暗黙の引数。「直前の文」ではない |

判定: **新**（小）。パイプの変種だが、「型を段として書く」ことで 1 行の自立性（宣言を見ずに何が走るか分かる）を連鎖でも保つ。`_` を文の値としてソースに置くのも珍しい。いずれも小さな構文の工夫で、言語観を変えるものではない。

## D. 注釈なしの全プログラム推論と、残る実行時検査

Sake: 検査器はプログラム全体の型を推論し、`--strict` で選んだ項目を実行前に報告する。値は型タグを持ち、すべての操作が実行時に引数を検査する（level 0 でも）。

| 言語・系統 | 推論 | 実行時 | 差 |
|---|---|---|---|
| Crystal | 注釈なしの全プログラム推論（インスタンス変数は class ごと）。union と flow typing で nil を扱う | 静的に通ったものは検査しない | 最も近い。Ruby 風の構文、union、nil の絞り込み。違いは、メソッド呼び出しを持つこと、注釈が書けること、健全性を目指すこと（Sake は偽陽性を認め、実行時検査を残す） |
| RPython | 制限した Python の全プログラム推論（annotator）。注釈なし | 推論できないものは拒否 | 推論の方式は近い。目的はコンパイル。対話的な言語ではない |
| DRuby（Furr ら 2009） | Ruby に静的推論。注釈は任意、動的機能は test suite のプロファイルで補う | 注釈は実行時に検査（契約） | 「静的推論 + 残る実行時検査」の先例。言語を変えず、注釈を**足す**方向 |
| TypeProf（Ruby） | 注釈なしの全体推論、RBS を生成 | 無し（解析器） | クラスごとの型。Sake の検査器は TypeProf に近い系統で、構築場所ごとに分ける |
| Dialyzer（Erlang） | success typing（偽陽性を出さない） | 常に動的 | 「到達しない分岐も報告する」点を Sake は Dialyzer に倣った。Sake は偽陽性を出し、レベルで量を選ぶ |
| 漸進的型付け（Siek & Taha）、TypeScript、Sorbet、mypy | 注釈を**足す**ことで静的部分を広げる | TS/mypy は無し、Sorbet は `T.let` を実行時検査 | 方向が逆: Sake は注釈を足せない。静的な部分の広さは操作の修飾の密度で決まる |
| Starkiller / Shed Skin（Python） | 全体推論、割り当て場所ごとの型 | コンパイル | E の先例でもある |
| Spinel（matz、2026-09） | Ruby の大きな部分集合（クラス・継承・ブロック・例外・Fiber・Thread・Regexp。`eval` と実行時に名前が決まる `send`/`method_missing` は無し）を注釈なしで全プログラム推論し、C に落とす。RBS は任意で推論の種になる | 推論が揃わない場所は tagged union（`poly`）に退避して動的に。世代別 GC | 言語を変えずに Ruby をコンパイルする道。Ruby の意味論（動的なメソッド解決、`poly`、GC）をコンパイラ側で引き受けるので解析器は 10 万行の C。Sake は同じ仕事を言語の規則で削り、resolver 1,600 行 + Rust 生成器 1,100 行。整数と配列のベンチでは同じ速さ（`experiments/2026-10-10-rust-backend`） |

判定: **組**。Crystal・RPython・DRuby・TypeProf にそれぞれ半分ずつある。Sake 固有なのは「注釈を禁じた上で推論し、しかも偽陽性をレベルで選ぶ」という割り切りである。健全性を目標にしない代わりに、実行時検査が最後の網として常に残る（これは Ruby と同じ）。

## E. 構築場所ごとの型と `mixed`

Sake: クラスの値の型は構築場所（`Point.new` のノード × 引数の形）ごとに分かれ、`Heap@L7` と表示される。合わない型が 1 つのフィールドに合う型と一緒に現れたら `mixed` と呼び、level 2 から止める。

先行: points-to 解析の allocation-site abstraction（Andersen 1994）と object sensitivity（Milanova ら 2002）は、まさに「割り当て場所ごとに別のオブジェクト」として扱う。Starkiller（Salib 2004）は Python の型推論でこれを使った。Crystal と TypeProf はクラスごと。判定: **組**。解析としては古典だが、(1) 言語の文書で「1 つの構築は 1 つの型」と利用者に約束し、メッセージに場所を出すこと、(2) `mixed` という「出会いか誤りか分からない」報告の種類を切り出してレベルで扱うことは、他で見ない。代償（本当の誤りも `mixed` になる）も文書に書いてある。

## F. 厳格レベルと「外れの nil」

Sake: level 0〜4 と項目名（`type`, `rescue`, `nil`, `mixed`, `index-nil`, `exhaustive`, `unrescued`）。`a[i]`、`Array.first`、`Hash.dig` などの「外れの nil」は level 3 で初めて報告する。

| 言語 | 対応物 | 差 |
|---|---|---|
| TypeScript | `strictNullChecks`、`noUncheckedIndexedAccess`（`a[i]` を `T \| undefined` に）、`exactOptionalPropertyTypes` … | **ほぼ同じ区別**。TS は注釈のある言語で、フラグはコンパイラ設定。Sake は項目を言語の規則として段に並べ、hint が `Array.fetch` を示す |
| mypy `--strict`、Pyright の strict | 段階的な厳しさ | 項目の中身は違う（Python の Optional は宣言） |
| Sorbet | `# typed: false/true/strict/strong` | ファイル単位の段。nil は宣言（`T.nilable`） |
| Kotlin / Swift / Rust | nullable / Optional を型で強制、`!`/`unwrap` で明示 | 常に強制。「外れ」と「nil かもしれない値」を区別しない |
| Dialyzer | 偽陽性なしの 1 段 | 段が無い |

判定: **組**。TypeScript のフラグ群と同じ発想だが、「外れの nil」を他の nil から分けて別の段に置くこと、`rescue`（決して投げない例外の rescue）や `mixed` を項目にすることは Sake 固有である。

## G. mixin ディスパッチ、写し、継承なし

Sake: module の関数 `M.f(x)` は第 1 引数の型の `f` にディスパッチする（M を include する型の中から）。`include M` と `class B < A` は定義を**写す**。部分型関係は作らない。

| 言語 | 対応物 | 差 |
|---|---|---|
| Rust | `Trait::method(&x)` の完全修飾呼び出し。default method は型に写される。継承なし | **ほぼ同じ**。Rust は `x.method()` も書ける。impl は trait ごとに明示、Sake は `include` 1 行 |
| Clojure | protocol 関数は名前空間の関数で、第 1 引数の型でディスパッチ | 同じ振り分け。動的 |
| Haskell | 型クラスのメソッド。default method | 型で解決（返り値でも）。Sake は第 1 引数だけ |
| Elixir | protocol（`Enumerable`）と `Enum.map(x)`。`defimpl` で型ごとに実装 | 同じ振り分け。Sake の `Enum` はこの設計の写し。Elixir は実行時、Sake は静的 |
| Common Lisp (CLOS) | generic function `(defgeneric area (shape))` を class の外に置き、`(defmethod area ((c circle)) ...)` を class ごとに足す。多重ディスパッチ、`call-next-method` | **形が最も近い**: 操作は class に属さず、呼び出しは関数で、引数の class が実装を選ぶ。Sake の `Shape.area(x)` は「Shape を include する型に限った、第 1 引数だけの、静的な generic function」。CLOS には継承（多重）があり、Sake には無い |
| Dylan / Julia | 同じ generic function と多重ディスパッチ。Julia は型注釈で method を特化 | Sake は単一（第 1 引数）、注釈なし、候補集合は `include` が決める |
| Go | 埋め込み: フィールドとメソッドが昇格し、部分型にはならない | 「B は A ではない」が同じ。interface は構造的 |
| Ruby | `include` は祖先鎖に module を差す（写しではない）。継承あり | Sake は Ruby の構文で Go/Rust の意味を与えた |

判定: **既**（CLOS の generic function を静的・単一にしたもの。Rust の trait + Go の埋め込みとも読める）。Sake 固有なのは、module の関数の要件（本体が呼ぶ名前と `@x`）を**宣言なしに本体から集め**、include 先に無ければ静的エラーにすること（Rust は trait に署名を書く）。

## H. `(A|B).f(x)`

Sake: 呼び出しの場で型を列挙し、実行時は `x` の型で `A.f` か `B.f` を選ぶ。列挙にない型は実行前に報告。宣言は要らない。

先行: TypeScript の union 型は**束縛**に書き、絞り込みで振り分ける。Typed Racket の occurrence typing も同じ。C++ の `std::visit` は variant の候補を visitor が全部受ける。Erlang/Elixir はパターンで振り分ける。「呼び出しの場で候補集合を述べ、同名の操作を型ごとに探す」構文は知らない。判定: **新**（小）。mixin ディスパッチを「include の宣言」ではなく「呼び出しの場の列挙」で与える双対と見るのが筋で、2.8 節にそう書いた。

## I. データの区別と `T[...]`

Sake: `[a, b]` は Tuple（長さと位置ごとの型が固定）、`{x: 1}` は Record（構造的）、`Array[...]`、`Hash[...]`、`Integer[1, 2]` は Integer の Array。

先行: Elixir（`{a, b}` と `[a, b]`）、Python（tuple と list）、Rust（tuple と array）。構造的 Record と名前的クラスの対置は Elm・OCaml・TypeScript。`Integer[1, 2]` は Julia の `Int[1, 2]` と同じ字面と意味。判定: **既**。Sake 固有なのは Ruby の `[]` と `{}` に Tuple と Record を**割り当て直した**ことで、これは Ruby 使いの癖に逆らう判断（利用感レポートで毎回踏まれる）。

## J. 演算子

Sake: `a + b` は `Arithmetic.+(a, b)` で、左の型に解決する。自分の型は `include Arithmetic` と `def +(a, b)`。`coerce` は Ruby の protocol。

先行: Rust の `Add::add`、Haskell の `Num`、Python の `operator.add` と `__add__`/`__radd__`、Elixir の `Kernel.+`。判定: **既**。

## K. 漏れる例外の推論

Sake: 関数から漏れる例外を推論し、`rescue` 項目（決して投げない例外の rescue）と `unrescued` 項目（トップレベルまで届く raise）で報告する。

先行: Nim の例外追跡（`{.raises.}` を推論・検査）、Koka の効果推論、Java の検査例外（宣言が必要）、Swift の `throws`（宣言）。判定: **既**。注釈なしで推論する点は Nim・Koka と同じ系統。

## L. 名前空間の入れ子と `Enum`

Sake: `module A` の中の `class B` は `A::B`（2026-10-10）。prelude の `Enum` は `each` の上に Sake で書かれ、Array・Hash・Set・Range は自分の操作で答える。

先行: 入れ子は Ruby・Rust・C++ そのまま。`Enum` は Ruby の `Enumerable`（`each` を定義して include）と Elixir の `Enum` + `Enumerable` protocol（`Enum.map(x)` が protocol でディスパッチ）の合成。判定: **既**。

## M. AI 向けという目的と評価

Sake の動機は「AI が書きやすい言語」（DESIGN.md）。仮説は「型を操作に書くほうが、変数に書くより AI にとって書きやすく、読みやすい」。評価（`experiments/2026-10-05-ai-writability/`）は、同じ課題を Ruby・Java・Haskell・Scheme・Steep 付き Ruby・Sake で Claude に書かせ、隠しテストの通過数と出力トークンを比べた。結果: Sonnet 級は未知の言語を資料だけで 1.1〜2.4 倍の費用で Ruby と同じ正しさに書けたが、型を書く場所の差は、言語がどれだけ知られているかの効果の下に埋もれて見えなかった（P10b: Java 1.06、Haskell 1.18、Scheme 1.22、Steep 1.48、Sake 1.71）。

| 先行 | 内容 | Sake との関係 |
|---|---|---|
| NanoLang（Jordan Hubbard、2026-01） | LLM が生成することを前提にした小さな言語。曖昧さの無い構文、テストを必須にし、C に変換 | 目的が同じ。「資料を 1 つ渡せば LLM が書ける」という見方（Simon Willison）も Sake の実験の前提と同じ。Sake は型の置き場所という 1 つの仮説に絞った |
| AIDL（2025-02、arXiv） | LLM が CAD を操作するための solver 付き言語。「LLM が扱いやすい言語機能は何か」を問う | 領域特化。事前・事後条件で LLM の誤りを捕まえる方針は、Sake の「実行時検査が残る」と似る |
| MultiPL-E / MultiPL-T（Cassano ら） | 低資源言語で LLM の正答率が落ちること、高資源言語からの転移 | Sake の結果（未知の言語の費用が支配する）はこの知見と一致する |
| Crystal・TypeProf・Sorbet の動機 | 人間のための静的検査 | AI を読み手・書き手に想定した設計判断（1 行の自立性、hint の機械的な書き換え先）は Sake 固有 |

判定: **新**（問いと方法）。言語機能を LLM のために選ぶ試みは 2025〜2026 年に複数現れたが、1 つの仮説を立てて多言語で同じ課題を測り、否定的な結果を含めて公開したものは Sake のほかに知らない。残る問い（人間が読みやすいか、Sake を**学習した**モデルなら差が出るか）も実験の README に書いてある。

## 総合

| 新規性の層 | 中身 |
|---|---|
| 言語観（**新**、小） | 型注釈を束縛から完全に排し、操作の修飾だけを型情報の源にする。1 行の自立性を設計基準にする（「操作に型を書く発想でどこまでいけるか」が判断基準）。Elixir の慣習（module 関数、束縛に型を書かない）を規則に格上げしたものと見るのが正確 |
| 検査器（**組**） | 注釈なしの全体推論 + 実行時検査 + 構築場所ごとの型 + 段階的厳格さ + 「外れの nil」の分離 + `mixed`。要素は Crystal・TypeProf・TypeScript・points-to 解析にあり、束ね方が固有 |
| 構文の工夫（**新**、小） | `x.T.f` の連鎖、`_`、`(A\|B).f(x)`、`@x` を「第 1 引数のフィールド」とする略記、Ruby の `[]`/`{}` を Tuple/Record に |
| 意味論（**既**） | module 関数、mixin ディスパッチ、写しによる `include` と `<`、継承なし、演算子の module、例外の推論、`Enum` |
| 目的と評価（**新**） | AI の書きやすさを仮説にした言語設計と、6 言語比較による検証（否定的な結果を含む） |

Sake を新しい言語として主張できるのは第 1 層と第 5 層で（第 1 層は Elixir との差が小さい）、第 2〜4 層は「Ruby の構文の上にそれらを置いたらどうなるか」の実装報告に当たる。逆に言えば、第 1 層の主張（型は操作に書けば十分で、束縛に書く必要は無い）は、70 本のライブラリ移植と 1,000 本のコーパス（`examples/`、`experiments/`）で「書ける」ことまでは示したが、「人や AI にとって良い」ことは示していない。

## 出典

- 言語: [Elm](https://elm-lang.org/)、[Roc](https://www.roc-lang.org/)、[Gleam](https://gleam.run/)、[Crystal](https://crystal-lang.org/)、[RPython](https://rpython.readthedocs.io/)、[Rust の完全修飾構文](https://doc.rust-lang.org/reference/expressions/call-expr.html#disambiguating-function-calls)、[Clojure protocols](https://clojure.org/reference/protocols)、[Elixir Enum / Enumerable](https://hexdocs.pm/elixir/Enumerable.html)、[Elixir の型システム（gradual set-theoretic types。1.17 で導入、1.18〜1.19 で関数呼び出しと関数本体からの推論）](https://hexdocs.pm/elixir/gradual-set-theoretic-types.html)、[Common Lisp の generic function（CLHS 7.6）](https://www.lispworks.com/documentation/HyperSpec/Body/07_f.htm)、[Julia の methods](https://docs.julialang.org/en/v1/manual/methods/)、[TypeScript `noUncheckedIndexedAccess`](https://www.typescriptlang.org/tsconfig/#noUncheckedIndexedAccess)、[Nim の例外追跡](https://nim-lang.org/docs/manual.html#effect-system-exception-tracking)、[Koka](https://koka-lang.github.io/)、[Austral](https://austral-lang.org/)、[Odin](https://odin-lang.org/)、[Hare](https://harelang.org/)、[Julia の型付き配列リテラル](https://docs.julialang.org/en/v1/manual/arrays/#man-array-literals)、[TypeProf](https://github.com/ruby/typeprof)、[Spinel](https://github.com/matz/spinel)、[Sorbet](https://sorbet.org/)、[Dialyzer](https://www.erlang.org/doc/apps/dialyzer/dialyzer.html)。
- 研究: Furr, An, Foster, Hicks, [Static Type Inference for Ruby (DRuby)](https://www.cs.umd.edu/~mwh/papers/druby.pdf), SAC 2009; Salib, Starkiller: A Static Type Inferencer and Compiler for Python, MIT 2004; Andersen, Program Analysis and Specialization for the C Programming Language, 1994; Milanova, Rountev, Ryder, Parameterized Object Sensitivity for Points-to Analysis, 2002; Siek & Taha, Gradual Typing for Functional Languages, 2006; Cassano ら, [MultiPL-E](https://github.com/nuprl/MultiPL-E), 2022 と [Knowledge Transfer from High-Resource to Low-Resource Programming Languages for Code LLMs](https://arxiv.org/pdf/2308.09895), 2023。
- LLM 向け言語: [NanoLang](https://feeds.simonwillison.net/2026/Jan/19/nanolang/)（Simon Willison の紹介、2026-01）、[llms for new programming languages](https://simonwillison.net/2025/Nov/7/llms-for-new-programming-languages)（2025-11）、[A Solver-Aided Hierarchical Language for LLM-Driven CAD Design (AIDL)](https://arxiv.org/pdf/2502.09819)（2025-02）。
- Sake 自身: `DESIGN.md`（思想、判断の基準、決定の経緯）、`docs/spec.md`、`experiments/2026-10-05-ai-writability/`（評価）、`experiments/2026-10-01-inference-500/`（推論の到達度）。
