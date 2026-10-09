# 制御構造とパターン

- `if` / `elsif` / `else`、`unless` / `else`、三項演算子 `c ? a : b`。無い分岐は `nil` です。
- `while` と `until`（値は `nil`）。ループの中で `break` はループを抜け、`next` は次の反復に進みます。`begin ... end while` は未対応です。
- 修飾子の形 `stmt if c`、`stmt unless c`、`stmt while c`、`stmt until c`。
- `for` は未対応です。`Range.each(1..3) { |i| ... }` のような操作で反復します。
- `case`/`when` は未対応です（`===` は無い）。`case`/`in` を使います。

## パターンマッチ

`x in P` は `x` がパターン `P` に一致するとき真です。`x => P` はそれを主張します: 一致しなければ `NoMatchingPatternError` を投げ、Record パターンのフィールドを束縛します。`case x` に `in P then ...` の分岐を続けると、最初に一致した分岐が走ります。どの分岐も一致せず `else` が無ければ `NoMatchingPatternError` です。

| パターン | 一致するもの |
|---|---|
| 型名: `Integer`, `String`, `Tuple`, `Hash`, `Point`, `Record`, `IO`, ... | その型（型タグ）の値 |
| `nil`, `true`, `false`, `1`, `"s"`, `:ok` | 同じ型の等しい値 |
| `P \| Q` | どちらか |
| `{x:, y: name}` | そのフィールドを持つ Record。ローカル `x` と `name` を束縛 |
| `[P, Q]` | その長さの Tuple で、各位置が `P`、`Q` に一致するもの（入れ子可） |
| `x`（`[...]` の中、または単独の裸の名前） | 何でも。ローカル `x` を束縛 |

- **ディスパッチではない。** 一致は型タグと値の比較です。`===` は無く、`case`/`when` は使えません。
- **絞り込み。** `if x in Integer` の中と、`case x` の各 `in` 分岐で、ローカル `x` は一致する型に絞られます。`else` と後続の分岐は残りの型を見ます。`Integer | String` のような和を `type` の報告なしに使うのはこの方法です。
- **網羅性。** `else` の無い `case` が**型**を取り残しうるときは `type` として報告されます。型の集合は閉じているので検査できます。Symbol リテラルは値として追跡されるので、`op` がそのリテラルしか持たないなら `case op in :add ... in :sub` は完全です。リテラルの分岐が開いた型（ある String、Integer、実行時に作った Symbol）の**値**を取り残しうるときは `exhaustive` 項目（レベル 3）です。プログラムは正しいかもしれず、そうでなければ `NoMatchingPatternError` が止めます。
- **主張。** `x => P` の後、ローカル `x`（`initialize` の中では新しいインスタンスのフィールド `@x` も）は `in` 分岐と同じく一致する型に絞られます。確実に一致しない値は `type`（レベル 1）、一致しないかもしれない（別の型が来うる）値は実行時に検査され、`exhaustive`（レベル 3）としてだけ報告されます。失敗は Ruby と同じく rescue できる `NoMatchingPatternError` です。`x => P` は `Array.fetch` が添字の外れを検査するのと同じく nil の検査でもあるので、nil かもしれない値は報告されません。「port は Integer だ」のような事実を、値を格納する場所に書く方法です: `p => Integer` の後 `@port = p`。
- **括弧。** Ruby と同じく、引数の位置の `x in P` は括弧で囲みます: `p((x in Integer))`。`x in T ? a : b` や `cond && x in T` も意図と違う解析になるので `(x in T)` と括ります。
