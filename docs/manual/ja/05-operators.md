# 演算子と添字

## 二項演算子

各演算子は module に属し、`a OP b` はその module の関数を呼ぶ略記です: `a + b` は `Arithmetic.+(a, b)` です。module の関数は第 1 引数の型で解決されるので（[module の関数の呼び方](02-program.md)）、この呼び出しは `a` の型 `T` の `T.+(a, b)` を走らせます。つまり演算子は**左のオペランド**でディスパッチします。エラーの文は module の関数の名で出ます（`Arithmetic.*: ...`）。

| module | 演算子 | include する組み込み型 |
|---|---|---|
| `Arithmetic` | `+ - * / % **`、単項 `-x` `+x`（`-@` `+@`） | Integer, Float, Rational, Complex, String, Time, Set |
| `Comparable` | `<=> < <= > >=` | Integer, Float, Rational, String, Time, Tuple, Array |
| `Bitwise` | `& \| ^ << >>`、単項 `~x` | Integer, Set |
| `Indexable` | `[]`, `[]=`（下記「添字」） | Array, Hash, String, Tuple, MatchData |
| `Kernel` | `== != =~ !~` | すべての型 |

- **自分の型。** クラスは module を include して本体に演算子を定義すると演算子に参加します。`include Arithmetic` と `def +(a, b)` など。`include Comparable` では `<=>` を定義すれば十分で、`<`、`<=`、`>`、`>=` はそこから来ます。`Array.sort`、`min`、`max` もそれを使います。
- **左が組み込み型のとき。** `2 + money` は Integer でディスパッチしますが、Integer に Money の行はありません。クラスが Ruby のプロトコルと同じく Tuple `[left, right]` を返す `coerce(b, a)` を定義していれば、組を先に変換してから演算子を走らせます: `def coerce(m, other) = [Money.new(other * 100), m]` で `2 + money` は `Money.new(200) + money` になります。検査器も変換を追います。
- **等価。** Struct 値の `==` は、型が自分の `==` を定義していなければ、Ruby の Struct と同じく型とフィールドを比べます。`Comparable` を include して `<=>` を定義した（`==` は定義しない）型は、Ruby の `Comparable#==` と同じく、同じ型の値と `<=>` が 0 のとき等しく、別の型の値（nil など）とは決して等しくなく、`<=>` は呼ばれません。`Array.include?`、`index` などは同じ等価を使います。
- **明示の形。** `Arithmetic.+(a, b)` は同じようにディスパッチします。`Integer.+(a, b)` は Integer の `+` を直接呼び、`a` は Integer でなければならず、`b` は Integer の `+` が受けるどの型でもよい。
- **エラー。** 左のオペランドの型が include しない、または定義しない module の演算子を使うのは、実行前に `type` の問題、実行時は `TypeError` です。

組み込み型では、結果の型は両オペランドの型から**閉じた表**で決まります。

| 演算子 | 行 |
|---|---|
| `+` | (Integer, Integer) → Integer。Float を含めば Float。Rational を含み Float を含まなければ Rational。Complex を含めば Complex。(String, String) → String |
| `-` `*` `/` `%` `**` | 数値の組は `+` と同じ |
| `*` | (String, Integer) → String も |
| `<` `<=` `>` `>=` `<=>` | 数値の組、(String, String)、(Tuple, Tuple)、(Array, Array) → true/false（`<=>` は -1, 0, 1, nil） |
| `==` `!=` | **任意の 2 値**: 同じ型の等しい値（数は Integer・Float・Rational をまたいで比べる）。Ruby と同じく、別の型の値は等しくない |
| `+` `-` | (Array, Array) → Array（連結。差） |
| `*` | (Array, Integer) → Array（繰り返し） |
| `<` `<=` `>` `>=` `<=>` | (Symbol, Symbol) も |
| 単項 `-` `+` | Integer, Float, Rational, Complex → 同じ型 |
| 単項 `~` | Integer → Integer |
| `&` `\|` `^` `<<` `>>` | (Integer, Integer) → Integer |
| `\|` `&` `-` | (Set, Set) → Set（和、積、差） |
| `=~` | (String, Regexp), (Regexp, String) → Integer か nil。`!~` (String, Regexp) → true/false |
| `%` | (String, Integer / Float / String / Symbol / Tuple / nil / true / false) → String、Ruby の format（`"%d items" % 3`、`"%s-%s" % [a, b]`） |

- **合う行が無いとき。** オペランドの型に合う行が無ければ `TypeError` です。メッセージは存在する行を列挙します。暗黙の変換はありません。
- **整数の除算。** Integer の `/` と `%` は Ruby に従います: `7 / 2 == 3`、`-7 / 2 == -4`。Integer のゼロ除算は `ZeroDivisionError`、Float のゼロ除算は IEEE に従います。
- **負の指数。** `Integer ** 負の Integer` は `ArgumentError` です。`a ** b` の型が `b` の値に依らないためです。Rational が欲しければ `2r ** -1` と書きます。
- **Complex。** 順序が無いので `<` などは定義されません。
- **Time。** `Time ± 数` は Time、`Time - Time` は秒の Float、2 つの Time は比較できます。
- **別の型の値**は決して等しくありません: `1 == :a` と `struct == "x"` は Ruby と同じく false です（クラス自身の `==` があればそれが決める）。
- **コレクション。** Tuple、Array、Set、Hash、Record は中身が等しいとき等しい（2 つの Record は同じフィールドも要る）。Tuple と Array は Ruby の Array と同じく要素ごとに順序付けられ、比べられない要素があれば `<` などは `ArgumentError`、`<=>` は nil です。実行前に、比べられない要素型が報告されます。
- **`!x`** は `x ? false : true` です。どの値にも使え、型の操作ではありません。
- **複合代入。** `x OP= e` は `x = x OP e` です。
- **演算子ではないもの。** `&&` と `||` は Ruby と同じく短絡し、オペランドの一方を返します。

## 添字

`x[k]` は `Indexable.[](x, k)`、`x[k] = v` は `Indexable.[]=(x, k, v)` で、`x` の型の `[]` と `[]=` を走らせます。クラスは `include Indexable` と `def [](x, k)` / `def []=(x, k, v)` で参加します。添字が 2 つなら `m[r, c]` は `def [](m, r, c)`、`m[r, c] = v` は `def []=(m, r, c, v)` を呼びます。組み込み型は次のとおりです。

| レシーバ, 添字 | `x[k]` | `x[k] = v` |
|---|---|---|
| Array, Integer | 要素。Array の外なら nil | `v` を格納（T の Array は `v` を検査） |
| String, Integer | 1 文字の String。外なら nil | 不可 |
| Tuple, Integer | 要素。Tuple の外は `IndexError` | その位置の型なら `v` を格納 |
| Array, Range / String, Range | スライス、または nil | 不可 |
| Array, Integer, Integer / String, Integer, Integer（`s[start, length]`） | スライス、または nil | 不可 |
| Hash, 任意のキー | 値、または既定値（`Hash.new(default)` で作っていなければ nil） | `v` を格納 |
| MatchData, Integer / String | グループ、または nil | 不可 |

- **負の添字**は Ruby と同じく末尾から数えます。
- **外れは `nil`**（Ruby と同じ）なので、`a[i]` の静的な型は `T | nil` です。`--strict` では結果を検査してから使います。`Array.fetch(a, i)` は代わりに `IndexError` を投げます。
- **Tuple。** 長さが型の一部なので、外の添字は `IndexError` です。
- **末尾の先への書き込み。** 型無しの Array では Ruby と同じく隙間が nil で埋まります。T の Array は nil が T でないので `IndexError` です。
- **複合代入。** `x[k] OP= v` と `x[k] ||= v` は `x` と `k` を 1 度だけ評価します。
- **ローカルの `||=`。** `y ||= v` はローカルが nil か false のときだけ代入します。
