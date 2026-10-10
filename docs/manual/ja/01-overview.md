# 概要と実行

Sake（/seɪk/）は、型を書く場所を変えてみるための実験的な言語です。構文は Ruby のまま、型は**操作**に書き、変数・引数・返り値・フィールドには書きません。

```ruby
name = "sake"
puts(String.upcase(name))      # => SAKE
```

Ruby の書き方 `name.upcase` は静的エラーです。hint が上の形を示します。

```ruby error
name = "sake"
puts(name.upcase)              # !> method call on a value `name.upcase` is not allowed
```

この本は、v0 インタプリタ（`bin/sake`）が実装している言語の参照マニュアルです。入門には [tutorial.md](https://github.com/ko1/sake-lang/blob/main/docs/tutorial.md) を、短い要約には [cheatsheet.md](https://github.com/ko1/sake-lang/blob/main/docs/cheatsheet.md) を参照してください。cheatsheet は約 1 万トークンで、AI に渡す用です。設計の経緯は `DESIGN.md` にあります。

## 原則

Sake の性質は、次の 4 つの原則からほぼすべて出てきます。この部の各章は、どれもこの 4 つの帰結です。

1. **Ruby の構文。** Sake のプログラムは Prism が構文解析できる Ruby のプログラムです。Ruby の構文の部分集合を受け付け、いくつかの構文には別の意味を与えます。
2. **型は操作に書き、束縛には書かない。** 操作は `Type.op(subject, args...)` と、型を付けて呼びます。変数・引数・返り値・フィールドに型注釈はありません。
3. **呼び出し先は実行前に決まる。** `String.upcase(s)` は 1 つの関数を名指しします。module の mixin 関数 `M.f(x)`、型の列挙 `(A|B).f(x)`、演算子 `a + b` は第 1 引数の型で 1 つを選びますが、候補の集合は実行前に確定しています。候補とは、`M` を include する型、列挙した型、演算子の表のことです。集合の外の型は実行前に報告されます。レシーバで動的に探す仕組み（`method_missing`、リフレクション）は無いので、名前の誤り（`String.upcse`）や引数の数の誤りも、プログラム全体について実行前に報告されます。
4. **値は型タグを持ち、すべての操作がそれを検査する。** 型の誤りは、その値を受け取った操作の行で報告されます。この検査は常に有効です。

原則 4 の検査は、実行前の検査が見逃したものを捕まえます。次の例では、無いキーの `h["b"]` が nil を返し、`String.upcase` がその行で止まります。

```ruby error
h = Hash["a" => "x"]
puts(String.upcase(h["b"]))    # !> TypeError: String.upcase: argument 1 must be String, got nil
```

## 実行

`bin/sake` はプログラムをまず検査し、問題が無ければ実行します。オプションで、検査だけにするか、どこまで厳しく検査するかを選びます。

```
bin/sake FILE.sake              # 検査してから実行
bin/sake -c FILE.sake           # 検査のみ
bin/sake --strict FILE.sake     # より厳しく検査（レベル 2）してから実行
bin/sake --strict=3 FILE.sake   # レベル 0〜4、または項目名: --strict=type,nil
bin/sake --types FILE.sake      # 実験的: 推論した型を表示する
bin/sake --dump=ast FILE.sake   # 解決済みのプログラム（SakeAST）を表示する
```

| 終了コード | 意味 |
|---|---|
| 0 | 成功 |
| 1 | 実行時エラー |
| 2 | 実行前に問題が見つかった（何も実行していない） |

インタプリタは Ruby で書かれ、Ruby 4.0 を必要とします（4.0.2 と Prism 1.9.0 で試験）。他の依存はありません。

## 厳格さ（`--strict`）

`--strict` は、実行前にプログラムを止める問題の種類を選びます。検査器はプログラム全体の型を推論し、見つけた問題を**項目**（`type`、`nil` など）に分けて報告します。レベルは、どの項目でプログラムを止めるかの組み合わせです。報告されなかったものは、実行時に各操作が検査します。

| レベル | オプション | 加わる項目 | 止めるもの |
|---|---|---|---|
| 0 | `--strict=0` | （無し） | 常に検査されるもの |
| 1 | 既定 | `type`, `rescue` | 型の不一致、無駄な `rescue` |
| 2 | `--strict` | `nil`, `mixed` | 検査していない nil、フィールドに出会った型 |
| 3 | `--strict=3` | `index-nil`, `exhaustive` | 添字の「外れ」の nil、網羅していない `case` |
| 4 | `--strict=4` | `unrescued` | トップレベルまで届く `raise` |

各レベルは、下のレベルの項目をすべて含みます。

### 常に検査されるもの（レベル 0）

次の問題はレベルに関係なく、実行前にプログラムを止めます: 構文、名前、引数の数、ブロック、値へのメソッド呼び出し、禁止構文、`T[...]` のリテラルの型。

### `type`（レベル 1）

nil 以外の、操作に合わない型の値です。`"" + 1` のように型が確定している場合も、1 か `""` を返す `pick()` の `pick() + 1` のように、合わない型を取りうる場合も報告します。

```ruby error
def half(n) = n / 2
puts(half("ten"))              # !> the operands are (String, Integer), which the left operand's type does not support [type]
```

報告は `half` の中の `n / 2` の行に出ます。hint の `reached by the call at line 2` が、そこに至った呼び出しを示します。

### `rescue`（レベル 1）

begin 本体が決して投げない例外の `rescue` です。対象は、プログラムが宣言した例外型と `RuntimeError` です。`KeyError` や `ZeroDivisionError` のような組み込みの種類は、普通の操作からも上がりうるので、常に起こりうるものとして扱われ、報告されません。

```ruby error
class ParseError < StandardError
end
begin
  p(10 / 2)
rescue ParseError              # !> the begin body never raises ParseError [rescue]
  p(0)
end
```

### `nil`（レベル 2）

nil かもしれない値を、検査なしに使うことです。レベル 1 では実行時の `TypeError` になるものが、レベル 2 では実行前に報告されます。

```ruby error
words = String.split("a b", " ")
w = Array.find(words) { |x| x == "c" }
puts(String.upcase(w))         # !> argument 1 may be nil (nil | String) [nil]
```

ただし、「外れ」の nil は除きます。外れとは、添字 `x[k]`、`Array.dig`、`Hash.dig`、`MatchData.begin`/`end`、および空の容器への次の操作が返す nil です: `Array.first`, `last`, `pop`, `shift`, `min`, `max`, `minmax`, `at`, `slice`, `sample`, `delete_at`, `Set.first`, `min`, `max`, `min_by`, `max_by`。これらはレベル 3 の `index-nil` が対象にします。nil の絞り込み方は[値と型](03-values.md)にあります。

### `mixed`（レベル 2。レベル 1 では警告）

`mixed` は `type` の報告の一種です。合わない型のすべてが、合う型と一緒に、あるクラスの 1 つのフィールドに現れるときに付きます。フィールドに入った容器の要素も同じです。

検査器はフィールドに構築場所ごとの型を与えます（[クラス](07-classes.md)）。1 つの場所で作ったインスタンスを別々の値に使うと、型がそのフィールドで出会います。次の例では、`make()` が作る Heap を Integer 用と String 用に使っています。

```ruby error
class Heap
  attr_accessor items
  def initialize(h)
    @items = Array[]
  end
  def push(h, x) = Array.push(@items, x)
  def top(h) = Array.first(@items)
end
def make() = Heap.new(nil)
ints = make()
Heap.push(ints, 1)
strs = make()
Heap.push(strs, "a")
p(Heap.top(ints) + 1)          # !> the operands may be (nil, Integer), (String, Integer), which the left operand's type does not support [mixed]
```

このような報告は、誤りではなく出会いである可能性が高いので、レベル 2 からプログラムを止め、レベル 1 では警告として印字します。上の例はレベル 1 では警告を出した後に走り、`2` を印字します。

この見分けの代償として、同じ場所で本当に誤った型がフィールドに入った場合も `mixed` になります。例えば `Config.new("h", port)` の `port` が 80 のことも `"eighty"` のこともあるときです。そのような値は格納する場所、`initialize` で検査してください（`@port => Integer`）。

### `index-nil`（レベル 3）

「外れ」の nil（上記）を検査なしに使うことです。次のプログラムはレベル 2 までは走り、`2` を印字します。

```ruby
xs = Array[1, 2, 3]
x = xs[0]
p(x + 1)                       # => 2
```

レベル 3 では実行前に止まります。

```
$ bin/sake --strict=3 index.sake
index.sake:3:3: error: Arithmetic.+: the operands may be nil, because x[k] (or `a, b = array`) gives nil when the element is missing [index-nil]
  hint: check the value first: `if x`, `while x`, `return unless x`, or `x != nil`
  hint: or use Array.fetch / Hash.fetch, which raise instead
```

### `exhaustive`（レベル 3）

開いた型の値が、どのリテラルの分岐にも取られないかもしれない `case`/`in` です。開いた型とは、String、Integer、リテラルで書かれていない Symbol など、値を列挙しきれない型のことです。次のプログラムはレベル 2 までは走ります。

```ruby
def kind(s)
  case s
  in "a" then 1
  in "b" then 2
  end
end
p(kind(String.downcase("A")))  # => 1
```

```
$ bin/sake --strict=3 kind.sake
kind.sake:2:3: error: case/in: no `in` branch matches some values of String [exhaustive]
  hint: add an `else`, or `in` branches for the other values
  hint: reached by the call at line 7
```

### `unrescued`（レベル 4）

rescue されずにトップレベルまで届くかもしれない `raise` です。プログラム向けの項目で、ライブラリの raise は呼び出し側のためのものなので、ライブラリには向きません。

```ruby
def check(n)
  raise ArgumentError, "negative" if n < 0
  n
end
p(check(1))                    # => 1
```

```
$ bin/sake --strict=4 check.sake
check.sake:2:3: error: raise: ArgumentError may reach the top level without being rescued [unrescued]
  hint: rescue it, or check with a level below 4
```

### 項目で選ぶ

レベルの代わりに、項目名で選べます。

- `--strict=type,nil` はその項目だけを選びます。
- `--strict=2,index-nil` はレベルに項目を足します。
- `--strict=3,-index-nil` はレベルから項目を引きます。

各報告は `[type]` のように項目名で終わるので、どの項目を足す・引くかはそこで分かります。

### 報告の性質

- **関数の中のエラー。** 多相な関数の中の報告には、そこに至った呼び出しを示す hint が付きます（上の `half` の例）。
- **到達しない分岐。** 分岐は評価されないので、決して走らない分岐の問題も報告されます（Erlang の Dialyzer と同じ）。
- **内部エラー。** 型推論自体が失敗したときは、警告を出して型検査を飛ばし、プログラムを実行します。
- **要素の組が多すぎるとき。** Array や Tuple の比較（`<`、`<=>`、ソート）は要素型の各組が比較できるか検査します。1 つの比較の要素型の組が 50,000 を超えると、その比較の要素は検査せず、比較の行に警告を出します。他の検査には影響しません。

## 静的エラーの形式

静的エラーは位置順にまとめて報告され、何も実行されません。各行は、ファイル名・行・桁・メッセージの順で、続く `hint:` 行が直し方を示します。

```
FILE:LINE:COLUMN: error: MESSAGE
  hint: SUGGESTION
```

冒頭の `name.upcase` の例では、次のように印字されます。

```
greet.sake:2:11: error: method call on a value `name.upcase` is not allowed
  hint: String.upcase(name)
  hint: Symbol.upcase(name)
  hint: name.String.upcase
```

## 実行時エラーの形式

実行時エラーは、止まった操作の行と、そこに至った呼び出しの列（`from` 行）を印字します。

```
FILE:LINE: in FUNCTION: KIND: MESSAGE
  from FILE:LINE: in CALLER
  hint: SUGGESTION
```

```ruby error
def third(xs) = Array.fetch(xs, 2)
p(third(Array[1, 2]))          # !> IndexError: Array.fetch: index 2 outside of array bounds: -2...2
```

```
third.sake:1: in third: IndexError: Array.fetch: index 2 outside of array bounds: -2...2
  from third.sake:2: in <main>
```

種類の一覧は [例外とエラー](08-exceptions.md) にあります。
