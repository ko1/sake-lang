# 値と型

| 型 | リテラル / 構築 | 備考 |
|---|---|---|
| Integer | `42`, `-7` | 多倍長 |
| Float | `1.5`, `2.0` | |
| String | `"abc"`, `'abc'`, `"a#{x}"` | 補間は `to_s` を使う（下記「値の表示」） |
| true / false | `true`, `false` | 内部では 1 つの型 `Boolean`。ソースには書けない |
| nil | `nil` | 「nil」の節を参照 |
| Tuple | `[a, b, ...]` | 長さと位置ごとの型が作成時に固定 |
| Record | `{x: a, y: b}` | (フィールド, 型) の集合が作成時に固定 |
| Array | `Array[a, ...]` | 要素型の宣言なし |
| T の Array | `T[a, ...]`、例 `Float[]`, `Point[p]` | 要素型 T。書き込みごとに検査 |
| Hash | `Hash["a" => 1, b: 2]`, `Hash.new(0)` | キーは値と型で比較（Ruby の `eql?`） |
| Set | `Set[1, 2]` | 要素は値と型で比較（Ruby の `eql?`） |
| Symbol | `:name` | |
| Range | `1..5`, `1...5`, `1..` | 端は Integer, Float, String, nil |
| Regexp, MatchData | `/(\d+)-(\d+)/`, `/#{x}/`, `String.match(s, re)` | |
| Rational, Complex | `2r`, `1/3r`, `Rational(1, 3)`, `2i`, `Complex(1, 2)` | Ruby の数値の塔 |
| Time | `Time.now`, `Time.at(0)`, `Time.new(2026, 10, 1)` | |
| IO | `IO.stdout`, `File.open(path)` | ファイルとストリームの 1 つの型 |
| Thread, Mutex, Queue, TCPServer, Socket | `Thread.new { }`, `Mutex.new`, ... | 並行とネットワーク |
| Struct 型 | `Point.new(x, y)` | 可変なフィールドを持つレコード |

- **真偽。** 偽は `nil` と `false` だけです。`0` や `""` を含む他のすべての値は真です。
- **エラーメッセージ。** `nil`、`true`、`false` は値として示され（`got nil`）、他の値は型名で示されます（`got Integer`）。

## 値の表示

どの値も 2 つの形で表示できます。

| 形 | 使う場所 | 組み込みの形 |
|---|---|---|
| `to_s` | `puts`, `print`, `"#{x}"`, `Array.join`, `format` の `%s`, `:"#{x}"`, `/#{x}/` | Ruby の `to_s` と同じ。`nil` は空、Array と Tuple は `inspect` |
| `inspect` | `p`、`Kernel.inspect`、`format` の `%p`、および Array・Tuple・Hash・Record の中の要素 | Ruby の `inspect` と同じ。`#<struct Point x=1, y=2>` |

- **自分の形。** Struct 型は class の中に自分の `to_s` と `inspect` を定義できます: `def to_s(p) = "(#{@x}, #{@y})"`。必須の引数は値 1 つで（既定値付きの引数は続けられる: `to_s(n, base = 10)`）、String を返さなければなりません。String でない結果は実行前に `type` の問題、実行時は `TypeError` です。
- **どれが走るか。** 型の集合は閉じているので、値の型が分かればどの `to_s` が走るかも分かります。

## Tuple、Record、Array

**リテラルと構築。** リテラル（`[...]`、`{...}`）には型を付けた操作が無いので、その形が作成時に型を決めます。伸びる容器は、型を付けた操作（`Array[...]`、`T[...]`）で作ります。

- **中身は可変。** リテラルの中身は同じ型の値で置き換えられ、各書き込みが検査されます。Tuple は `t[i] = v` で書きます。Record に書く構文はまだありません。
- **長さは固定。** 長さは型の一部なので、空の `[]` は伸びません。
- **nil。** `nil` で作った位置の型は nil です。後で値を入れる場所には、`0` や `""` のような意図した型の仮の値を置きます。

**Tuple。** リテラル `[a, b, ...]` は Tuple です。

- 要素は多重代入 `x, y = t` で読みます。多重代入は Array も分解します（`key, value = String.split(s, "=")`）。Ruby と同じく、足りない要素は nil、余った要素は捨てられます。足りないかもしれない要素を受ける変数は `x[k]` と同じ `nil | T` の型です（`index-nil` 項目、レベル 3）。代入先には要素とフィールドも書けます: `a[i], a[j] = a[j], a[i]` は交換、`@done, @rest = Array.partition(xs) { ... }`。レシーバと添字を先に、右辺をその後に評価します。
- `first, *rest = xs` は残りを新しい Array に入れます（`a, *mid, z = xs` も。`x, * = xs` は捨てる）。rest を受けられるのはローカル変数だけです。`[...]` の中のスプラットは拒否されます（Tuple の長さは既知でなければならない）。`Array[*xs, 1]` は Array を作ります。
- `t[0]` は位置を読み、`t[0] = v` は同じ型の値で置き換えます。
- `Tuple.size` と `Tuple.length` が要素数です。`Tuple.max([a, b])` は Ruby の `[a, b].max`（長さが分かるので nil にならない）。

**Record。** リテラル `{x: a, y: b}` は Record です。

- **型。** Record の型は (フィールド, 型) の集合、例えば `{x: Integer, y: Integer}` です。同じ集合の Record は同じ型です。
- **順序。** 順序は関係ありません。`{y: 2, x: 1}` は `{x: 1, y: 2}` と印字されます。
- **Struct ではない。** フィールドが一致しても Record は Struct の値ではありません。Struct 型は名前で、Record 型は構造で決まります。
- **フィールドの読み出し。** パターンで分解します: `r => {x:, y: name}`。ローカル `x` にフィールド `x`、ローカル `name` にフィールド `y` が束縛されます。一部のフィールドだけ書いてもよい。無いフィールドは `KeyError`、Record でない値は `TypeError`。`Record.to_h(r)`、`Record.keys(r)`、`Record.values(r)` もあります。
- **制限。** フィールド名はラベル（`x:`）で書きます。空の `{}` と `{key => value}` は静的エラーです（Hash は `Hash[...]`）。

**Array。** `Array[a, ...]` は要素型を宣言しない Array を作ります。どの値も入ります。

**T の Array。** `T[a, ...]` は要素型 T の Array を作ります。T は組み込み型（`Integer`, `Float`, `Rational`, `Complex`, `String`, `Symbol`, `Tuple`）か Struct 型です。

- **書き込みの検査。** 作成、`Array.push`、`Array.append`、`Array.concat` のすべての書き込みが検査され、合わなければ `TypeError`。暗黙の変換は無く、Integer は `Float[]` に入りません。
- **静的検査。** `T[...]` のリテラル引数が別の型なら実行前に報告されます。Ruby 流に書いた `Point[1, 2]`（`Point.new(1, 2)` のつもり）がここで捕まります。
- **型無しの結果。** `map`、`select`、`sort` などが返す Array は要素型を宣言しません。

Array は可変で、参照で共有されます。

**Ruby の癖。** Array が要るところに Tuple や Record を渡す（`result = []` の後の `Array.push(result, x)`）と、`Array[]` と書く hint 付きで失敗します。

- **要素型を変える in-place 操作。** 検査器は容器にプログラム全体で 1 つの要素型を与えるので、`Array.map!(xs) { |x| Integer.to_s(x) }` や `Hash.transform_keys!(h) { ... }` の後は、容器が古い型と新しい型の両方を持つとみなし、片方にしか合わない操作を `type`（部分的）として報告します。in-place の形は 1 つの型の中の写像に使い、型を変えるときは `Array.map` / `Hash.transform_keys`（新しい容器）を使ってください。

## Hash と Set

- **構築。** `Hash[k => v, ...]`（`Hash[name: v]` も。キーは Symbol）、`Hash[]`、`Hash.new(default)` が Hash を、`Set[x, ...]` が Set を作ります。リテラル `{...}` は Record で、Hash ではありません。
- **キーと要素。** Hash のキーと Set の要素は Ruby の `eql?` と同じく値と型で比較します。`1` と `1.0` は別のキーです（`Hash[1 => "a"][1.0]` は nil、`Set[1, 1.0]` は 2 要素）が、`1 == 1.0` は true です。使えるもの: Integer, Float, String, Symbol, true, false, nil, Time、およびそれらからなる Tuple, Record, Array, Hash, Set, Struct 値。使えないもの（`TypeError`）: Regexp, Range、自分の等価（`==`、または `Comparable` の `<=>`）を定義した Struct 型の値（キーの比較がその等価と食い違いうる）。Ruby と同じく、キーに使った Array・Hash・Set・Struct 値を後で変えると見つからなくなります。
- **キーは複製される。** Tuple や Record のキーは格納時に複製されるので、元を後で書いてもキーは変わりません。
- **既定値。** `Hash.new(default)` は無いキーに `default` を返し、Ruby と同じく同じオブジェクトを共有します。ブロックの形 `Hash.new { ... }` はありません（ブロックは値ではない）。
- **ブロック。** Hash のブロックは `[key, value]` を 1 つの Tuple として受けるので、`|k, v|` で分解します。
- **順序。** 反復は挿入順です。

## nil

`nil` は普通の値です。無いかもしれない値の型は `nil | T` で、Option のような包みはありません。

- **実行時。** T が要る操作が `nil` を受けると `TypeError ... got nil` を投げます。インタプリタはそのエラーの経路でだけ静的解析を走らせ、nil を持ちうるフィールドと nil を格納する行を hint に加えます。
- **絞り込み。** 静的解析は**ローカル変数**を次の場所で絞ります。

  | 形 | `x` が絞られる場所 |
  |---|---|
  | `if x` / `while x` / `x && …` | `x` が真のときに取る分岐で非 nil |
  | `x != nil` / `x == nil` | 対応する分岐で nil または非 nil |
  | `!x` / `unless x` | 同じ、分岐を入れ替えて（`if !x … else` の else で非 nil） |
  | `return unless x`、`next unless x`、`break unless x` などの早期脱出 | 文の後で非 nil |
  | `String.size(x)` など、`x` を引数に取る組み込みの操作 | 呼び出しの後、その操作が受け付ける型（実行時に引数を検査するから） |
  | `x in T` / `x => T` / `case x in T` | 一致する型（[制御構造とパターン](06-control.md)） |

  フィールドの読み出し（`Node.next(n)`）は絞られ**ません**。フィールドは可変だからです。フィールドをローカル変数に写してから検査してください。
- **`--strict`。** レベル 2 は、検査されていない `nil` を受けうるすべての操作を実行前に報告します。レベル 3 は `x[k]` の結果も対象にします。

## Ruby の他の型

- **Range。** 反復する操作には Integer か String で始まる Range が要ります（`"A".."Z"` は Ruby と同じく `String#succ` で進む）。`step`、`sum`、`size` は Integer が要ります。別の型の Range（`1.0..2.0`）は `type` で報告されます。2 つの Range は端と `exclude_end?` が同じなら `==`、2 つの Regexp はソースとオプションが同じなら `==` です。有限の Range が要る操作は、終端の無い Range に `RangeError` を投げます。
- **Regexp と MatchData。** `$1` や `$~` のようなグローバルはありません。MatchData を変数に置いて添字で読みます（`m[1]`）。`String.sub`、`gsub`、`index`、`split` は Regexp も取ります。`/.../n` は Ruby と同じくバイト列の正規表現です。
- **Time。** ゾーンは Ruby と同じ固定の UTC オフセットです: `"+09:00"`、`"-0500"`、`"Z"`、`"UTC"`、軍用の 1 文字、秒数（`3600`）。`Time.new`、`Time.at`、`Time.now` はキーワード `in:` でも取ります。`Time.utc(t)` と `Time.localtime(t, zone)` は変換した複製を返します（Ruby の `utc` と `localtime` はレシーバを変える）。
- **IO。** `IO.stdin`、`IO.stdout`、`IO.stderr` がプログラムのストリームを型 `IO` の値として与えます（Sake に `$stdout` や `STDOUT` は無く、`ARGV` と同じく値は操作から来ます）。`File.open(path, mode = "r")` も `IO` を返し、ブロック付きならブロックの値を返してファイルを閉じます。ファイルとストリームの型は 1 つなので、1 つの関数がどちらにも書けます。`IO` はパターンに書け（`in IO`）、同じストリームやファイルの 2 つの IO 値は `==` です。
- **エンコーディング。** 互換でないエンコーディングの文字列が出会うと（`Integer.chr(227)` のバイトと UTF-8 の文章）、rescue できる `EncodingError` が上がります。
