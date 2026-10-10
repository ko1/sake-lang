# 制御構造とパターン

Sake の制御構造は Ruby のものです。`if` と `while`、修飾子の形、早期 `return`、そして `case` を Ruby と同じ字面で書きます。違いは 3 つあります。反復は `for` ではなく `Array.each` のようなブロックを取る操作で書きます。`case` は `when` ではなく `in` のパターンで分岐します。そして、条件は値を調べるだけでなく、検査器が追う変数の**型を絞り**ます。nil かもしれない値や `Integer | String` のような和を使うには、この絞り込みを使います。

この章の例の `# => 値` は `bin/sake --strict=2` の実際の出力です。

## 条件分岐

`if` / `elsif` / `else`、`unless` / `else`、三項演算子 `c ? a : b` は Ruby と同じです。どれも式で、取った分岐の値を返します。取る分岐が無ければ値は `nil` です。

```ruby
n = 5
r = if n > 10 then "big" elsif n > 3 then "mid" else "small" end
p(r)                                 # => "mid"
p(if n > 10 then "big" end)          # => nil
p(unless n > 10 then "not big" end)  # => "not big"
p(n > 3 ? "yes" : "no")              # => "yes"
```

### 真偽

偽は `nil` と `false` だけです。`0`、`""`、空の Array を含む他のすべての値は真です。`&&`、`||`、`!` は Ruby と同じで、`&&` と `||` は最後に評価したオペランドを返します。

```ruby
p(0 ? "truthy" : "falsy")            # => "truthy"
p("" ? "truthy" : "falsy")           # => "truthy"
p(nil ? "truthy" : "falsy")          # => "falsy"
p(nil || "default")                  # => "default"
p(0 && "zero is truthy")             # => "zero is truthy"
```

### 修飾子の形

文の後ろに条件を置く `stmt if c`、`stmt unless c`、`stmt while c`、`stmt until c` が書けます。

```ruby
n = 5
puts("positive") if n > 0            # => positive
i = 0
i += 1 while i < 3
p(i)                                 # => 3
i -= 1 until i == 0
p(i)                                 # => 0
```

## ループ

`while` と `until` は Ruby と同じです。ループの中で `break` はループを抜け、`next` は次の反復に進みます。ループの値は `nil` で、`break v` で抜けたときだけ `v` です。

```ruby
i = 0
out = Array[]
r = while i < 10
  i += 1
  next if i % 2 == 0
  break if i > 7
  Array.push(out, i)
end
p(out)                               # => [1, 3, 5, 7]
p(r)                                 # => nil
```

### 反復はブロックを取る操作で書く

`for` は未対応です。列を回すときは、`Array.each`、`Integer.times`、`Range.each` のようなブロックを取る操作に書きます（[関数とブロック](04-functions.md)）。ブロックの中の `break v` は、そのブロックを渡した呼び出しを値 `v` で終えます。`next v` はそのブロックの 1 回分を `v` で終えます。

```ruby
xs = Array[3, 8, 12, 5]
big = Array.each(xs) { |x| break x if x > 10 }
p(big)                               # => 12
squares = Array[]
Integer.times(4) { |i| next if i == 0; Array.push(squares, i * i) }
p(squares)                           # => [1, 4, 9]
```

`loop { ... }` は `break` まで繰り返し、`break` の値がその値です。

```ruby
i = 0
r = loop do
  i += 1
  break i * 10 if i == 3
end
p(r)                                 # => 30
```

### 未対応の形

`for` と `begin ... end while` は静的エラーです。

```ruby error
for i in 1..3                        # !> `for` is not supported; iterate with an operation
  p(i)
end
```

## 関数からの早期脱出

`return` は関数をその場で終えます。`return v` の値 `v` が関数の値で、`return a, b` は Tuple `[a, b]` を返します。修飾子の形 `return v if c` が、場合分けの先頭で前提を片付ける書き方です。ブロックの中の `return` も、ブロックではなく外側の**関数**から戻ります（[関数とブロック](04-functions.md)）。

```ruby
def sign(n)
  return "negative" if n < 0
  return "zero" if n == 0
  "positive"
end
p(sign(-2))                          # => "negative"
p(sign(0))                           # => "zero"
p(sign(7))                           # => "positive"
```

## case / in

`case x` に `in P then ...` の分岐を続けると、最初に一致した分岐が走ります。分岐の本体は `then` の後に書いても、次の行に書いてもかまいません。どの分岐も一致せず `else` が無ければ、実行時エラー `NoMatchingPatternError` です。

```ruby
def kind(v)
  case v
  in nil then "nothing"
  in true | false then "bool"
  in Integer | Float then "number"
  in String
    "text"
  end
end
p(kind(nil))                         # => "nothing"
p(kind(true))                        # => "bool"
p(kind(2.5))                         # => "number"
p(kind("s"))                         # => "text"
```

`case`/`when` は未対応です。Ruby の `when` はレシーバの `===` でディスパッチしますが、Sake に `===` は無く、一致は型タグと値の比較です。パターンに書けるものは、この章の最後の節「パターンマッチ」の表のとおりです。

```ruby error
x = 1
case x                               # !> `case`/`when` is not supported (Ruby's `===` dispatches on the receiver); match with `case x` / `in Type`
when 1 then puts("one")
end
```

## 条件による絞り込み

検査器はローカル変数の型をプログラム全体で推論します。条件は、取った分岐の中でその変数の型を**絞り**ます。`if x` の中で `x` は nil ではなく、`if x in Integer` の中で `x` は Integer です。nil かもしれない値（`nil | String`）や和（`Integer | String`）を、`type` や `nil` の報告なしに使う方法がこれです。

### nil を外す

ローカル変数 `x` は次の場所で絞られます（[値と型](03-values.md)の nil の節と同じ表です）。

| 形 | `x` が絞られる場所 |
|---|---|
| `if x` / `while x` / `x && …` | `x` が真のときに取る分岐で非 nil |
| `x != nil` / `x == nil` | 対応する分岐で nil または非 nil |
| `!x` / `unless x` | 同じで、分岐が入れ替わる（`if !x … else` の else で非 nil） |
| `return unless x`、`next unless x`、`break unless x`、その他の早期脱出 | その文の後で非 nil |
| `String.size(x)` など、`x` を引数に取る組み込み操作 | 呼び出しの後で、その操作が受け付ける型（操作は走るときに引数を検査する） |

```ruby
def greet(name = nil)
  if name
    "Hello, " + String.upcase(name)
  else
    "Hello"
  end
end
p(greet("ko1"))                      # => "Hello, KO1"
p(greet())                           # => "Hello"
```

`if name` を外すと、`greet()` の呼び出しについて検査器が報告します。検査器は関数を呼び出しごとに解析するので、報告には至った呼び出しの行が付きます。

```ruby error
def greet(name = nil)
  String.upcase(name)                # !> String.upcase: argument 1 must be String, but is nil [type]
end
p(greet("ko1"))
p(greet())
```

早期脱出で外す形もよく使います。`while x` も同じ絞り込みです。

```ruby
def size_or_zero(xs)
  x = Array.first(xs)
  return 0 unless x
  String.size(x)
end
p(size_or_zero(Array["abc"]))        # => 3
p(size_or_zero(Array[]))             # => 0
```

### フィールドは絞られない

絞られるのは**ローカル変数**だけです。フィールドの読み出し `Node.next(n)` は可変なので、`if Node.next(n)` の中でもう一度読んだ値は nil かもしれないままです。フィールドはいったんローカル変数に写し、そのローカルを調べます。

```ruby
class Node
  attr_accessor value, :next
end
def next_value(n)
  nx = Node.next(n)
  if nx
    Node.value(nx)
  else
    0
  end
end
a = Node.new(1, nil)
b = Node.new(2, a)
p(next_value(b))                     # => 1
p(next_value(a))                     # => 0
```

```ruby error
class Node
  attr_accessor value, :next
end
def next_value(n)
  if Node.next(n)
    Node.value(Node.next(n))         # !> Node.value: argument 1 must be Node, but is nil [type]
  else
    0
  end
end
p(next_value(Node.new(1, nil)))
```

### 型で絞る

`x in Integer` は `x` が Integer のとき真で、その分岐の中で `x` は Integer に絞られます。`elsif` と `else` は残りの型を見ます。`case x` の `in` 分岐も同じです。

```ruby
def pick(flag) = flag ? 1 : "one"
def describe(x)
  if x in Integer
    x + 1
  elsif x in String
    String.size(x)
  else
    x
  end
end
p(describe(pick(true)))              # => 2
p(describe(pick(false)))             # => 3
```

### どのレベルで報告されるか

nil かもしれない値を検査せずに操作に渡すと、レベル 2（`--strict`）で `nil` 項目として報告されます。ただし、要素が無いときの nil（`x[k]`、`Array.first`、`Hash.dig` など）はレベル 3 の `index-nil` 項目です。レベルと項目は[概要と実行](01-overview.md)にあります。報告されなかった nil も、受け取った操作が実行時に `TypeError` で止めます。

## パターンマッチ

`x in P` は `x` がパターン `P` に一致するとき真です。`x => P` はそれを主張します。一致しなければ `NoMatchingPatternError` を投げ、Record パターンのフィールドを束縛します。`case x` の `in P` 分岐も同じパターンを取ります。

| パターン | 一致するもの |
|---|---|
| 型名: `Integer`, `String`, `Tuple`, `Hash`, `Point`, `Record`, `IO`, ... | その型（型タグ）の値 |
| `nil`, `true`, `false`, `1`, `"s"`, `:ok` | 同じ型の等しい値 |
| `P \| Q` | どちらか |
| `{x:, y: name}` | そのフィールドを持つ Record。ローカル `x` と `name` を束縛 |
| `[P, Q]` | その長さの Tuple で、各位置が `P`、`Q` に一致するもの（入れ子可） |
| `x`（`[...]` の中、または単独の裸の名前） | 何でも。ローカル `x` を束縛 |

この表に無いパターン（`*rest`、find パターン、ピン `^x`、ガード、`Integer => n` の形）は未対応で、静的エラーです（[Ruby との違い](a1-ruby.md)）。

### ディスパッチではない

一致は型タグと値の比較です。`===` は無く、`case`/`when` は使えません。型名のパターンは値の型タグを見るだけで、`class B < A` の B が `A` に一致することもありません（[クラス](07-classes.md)）。

### 束縛

Record パターンと Tuple パターンは、要素をローカル変数に取り出します。`{x:}` はフィールド `x` を同名のローカルに、`{y: name}` はフィールド `y` をローカル `name` に束縛します。

```ruby
pt = {x: 3, y: 4}
pt => {x:, y: why}
p(x)                                 # => 3
p(why)                               # => 4
pair = [1, "one"]
case pair
in [n, s] then p([s, n])             # => ["one", 1]
end
p((pair in [Integer, String]))       # => true
p((pair in [String, Integer]))       # => false
```

### 絞り込み

`if x in Integer` の中と、`case x` の各 `in` 分岐で、ローカル `x` は一致する型に絞られます。`else` と後続の分岐は残りの型を見ます。`Integer | String` のような和を `type` の報告なしに使うのはこの方法です（前の節の「型で絞る」）。

```ruby
def pick(flag) = flag ? 1 : "one"
def f(x)
  case x
  in Integer then x + 1
  else String.size(x)
  end
end
p(f(pick(true)))                     # => 2
p(f(pick(false)))                    # => 3
```

### 網羅性

`else` の無い `case` が、来うる**型**を取り残すときは `type` として報告されます。型の集合は閉じているので、検査器はこれを検査できます。

```ruby error
def show(x)
  case x                             # !> case/in: no `in` branch matches String [type]
  in Integer then "int"
  end
end
p(show(41))
p(show("abc"))
```

Symbol リテラルは値として追跡されます。`op` がそのリテラルしか持たないなら、`case op in :add ... in :sub` は完全です。

```ruby
def name(op)
  case op
  in :add then "plus"
  in :sub then "minus"
  end
end
p(name(:add))                        # => "plus"
p(name(:sub))                        # => "minus"
```

リテラルの分岐が開いた型（ある String、Integer、実行時に作った Symbol）の**値**を取り残しうるときは、`exhaustive` 項目（レベル 3）です。プログラムは正しいかもしれず、そうでなければ `NoMatchingPatternError` が止めます。次の例はレベル 2 では走り、`--strict=3` で報告されます。

```ruby error
def name(op)
  case op                            # !> case/in: no `in` branch matches some values of String [exhaustive]
  in "add" then "plus"
  in "sub" then "minus"
  end
end
p(name("add"))
p(name(String.downcase("SUB")))
```

### 主張: x => P

`x => P` の後、ローカル `x` は `in` 分岐と同じく一致する型に絞られます。`initialize` の中では、新しいインスタンスのフィールド `@x` も同じです。「port は Integer だ」のような事実を、値を格納する場所に書く方法です: `p => Integer` の後 `@port = p`。

- 確実に一致しない値は `type`（レベル 1）として報告されます。
- 一致しないかもしれない値（別の型も来うる）は実行時に検査され、`exhaustive`（レベル 3）としてだけ報告されます。失敗は `NoMatchingPatternError` で、Ruby と同じく rescue できます。
- `x => P` は nil の検査でもあるので、nil かもしれない値は報告されません。`Array.fetch` が添字の外れを検査するのと同じ扱いです。

```ruby error
x = "abc"
x => Integer                         # !> `=> Integer`: the value is String, which does not match [type]
```

```ruby
def pick(flag) = flag ? 1 : nil
x = pick(true)
x => Integer
p(x + 1)                             # => 2
```

### 括弧

Ruby と同じく、引数の位置の `x in P` は括弧で囲みます: `p((x in Integer))`。`x in T ? a : b` や `cond && x in T` も意図と違う解析になるので、`(x in T)` と括ります。

```ruby
x = 1
p((x in Integer))                    # => true
r = (x in Integer) ? "int" : "other"
p(r)                                 # => "int"
p(x > 0 && (x in Integer))           # => true
```

```ruby error
x = 1
p(x in Integer)                      # !> syntax error: unexpected 'in'; expected a `)` to close the arguments
```
