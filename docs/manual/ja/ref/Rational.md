# Rational

Rational は分子と分母が Integer の有理数で、常に既約で表されます。リテラルは Ruby と同じ `2r`、`1/3r`（`1 / 3r` の割り算）、`0.5r`（`1/2`）で、`Rational(1, 3)`・`Rational("1/3")`・`Rational(0.5)`（Ruby と同じく `(1/2)`）は Kernel の操作です（Float からは `Float.to_r`・`Float.rationalize` でも変換できます。[値と型](../03-values.md)）。Rational の値を `p` で表示すると `(1/3)` の形になります。

Rational に使える演算子は `+`、`-`、`*`、`/`、`%`、`**` と `==`、`!=`、`<`、`<=`、`>`、`>=`、`<=>` です。右側は Integer、Float、Rational、Complex のどれでもよく、結果の型は閉じた表で決まります: Integer との演算は Rational、Float との演算は Float、Complex との演算は Complex（[演算子と添字](../05-operators.md)）。`1 + 1r/2` のように Integer が左でも Rational になります。Integer の負の冪 `2 ** -1` は Ruby なら Rational ですが Sake では `ArgumentError` で、`2r ** -1` と書きます。ここに挙げた `Rational.+(x, y)` などはその演算子を関数の形で呼ぶものです。

Ruby と同じく、Rational を 0 で割ると `ZeroDivisionError` です（Float と違い、無限大にはなりません）。Ruby との違いは、`round`・`floor`・`ceil`・`truncate` に桁数引数が無いこと（`Arithmetic.round(r, n)` を使います。[Arithmetic](Arithmetic.md)）、`quo` と `rationalize` の引数が Float を取らないことです。

## Rational[]

`Rational[*Any]`

**Rational の Array** を作ります（Rational そのものではありません）。要素はすべて Rational でなければならず、`Array.push` などの書き込みも毎回検査されます。Integer は Rational に変換されず、静的に `type` の問題、実行時は `TypeError` です。空の Rational の Array は `Rational[]`。

```ruby
rs = Rational[1r/2, 2r]
Array.push(rs, Rational(1, 3))
p(rs)                            # => [(1/2), (2/1), (1/3)]
p(Array.size(Rational[]))        # => 0
```

```ruby error
Array.push(Rational[], 1)        # !> Array.push: an element must be Rational, but is Integer
```

## +, -, *, /, %, **

`Rational.+(x, Any)`

`Rational.-(x, Any)`

`Rational.*(x, Any)`

`Rational./(x, Any)`

`Rational.%(x, Any)`

`Rational.**(x, Any)`

`x + y` などの関数形で、左側が Rational のものです。右側 `y` は Integer、Float、Rational、Complex のどれか。Integer・Rational との結果は Rational、Float との結果は Float、Complex との結果は Complex です。それ以外の型は静的に `type` の問題、実行時は `TypeError`。`/` と `%` の右側が 0（`0`・`0r`）なら `ZeroDivisionError`（`0.0` なら Float の規則で `Infinity`）。`%` は Ruby の `Rational#%` で、結果の符号は右側に従います。`**` は Integer の指数なら Rational（負でもよく、`2r ** -1` は `(1/2)`）、Float の指数なら Float です。**Rational の指数**では、整数値なら Rational（`4r ** 2r` は `(16/1)`）、そうでなければ Float（`4r ** (1r/2)` は `2.0`）になるので、検査器はその結果を `Rational | Float` とします。どちらかとして使う前に `case`/`in` で絞ってください（`Rational.numerator(4r ** 2r)` は `type` の問題）。負の底に分数の指数は `Math::DomainError` です（Ruby は Complex を返す）。

```ruby
p(1r/3 + 1r/6)                   # => (1/2)
p(Rational.+(1r/3, 1))           # => (4/3)
p(Rational.+(1r/3, 0.5))         # => 0.8333333333333333
p(Rational.+(1r/3, Complex(1, 1)))  # => ((4/3)+1i)
p(Rational.-(1r, 1r/3))          # => (2/3)
p(Rational.*(2r/3, 3r/4))        # => (1/2)
p(Rational./(1r/3, 2))           # => (1/6)
p(Rational.%(7r/3, 1r/2))        # => (1/3)
p(Rational.**(2r, -1))           # => (1/2)
p(Rational.**(1r/2, 3))          # => (1/8)
p(Rational.**(4r, 2r))           # => (16/1)
p(Rational.**(2r, 1r/2))         # => 1.4142135623730951
x = 4r ** (1r/2)
case x
in Rational then p(Rational.numerator(x))
in Float then p(x)               # => 2.0
end
```

```ruby error
p(Rational./(1r, 0))             # !> ZeroDivisionError: Rational./: divided by 0
```

```ruby error
p(Rational.numerator(4r ** 2r))  # !> Rational.numerator: argument 1 must be Rational, but can be Float
```

```ruby error
p((-8r) ** (1r/2))               # !> Math::DomainError: Arithmetic.**: -8/1 ** 1/2 is not a real number (a negative base with a fractional exponent)
```

## ==, !=

`Rational.==(x, Any)`

`Rational.!=(x, Any)`

`x == y` の関数形。Rational は Integer・Float・Complex と値で比べられ、`1r/2 == 0.5` も `2r == 2` も true です。別の型の値とは決して等しくなく、関数形の `Rational.==(x, y)` も演算子と同じく、右側が他のどんな型でも false（`!=` は true）を返し、エラーにはなりません。

```ruby
p(Rational.==(1r/2, 0.5))        # => true
p(Rational.==(2r, 2))            # => true
p(Rational.!=(1r/2, 1r/3))       # => true
p(1r == nil)                     # => false
p(Rational.==(1r/2, "x"))        # => false
p(Rational.!=(1r/2, "x"))        # => true
```

## <, <=, >, >=

`Rational.<(x, Any)`

`Rational.<=(x, Any)`

`Rational.>(x, Any)`

`Rational.>=(x, Any)`

`x < y` などの関数形。右側は Integer、Float、Rational のどれか（Complex に順序は無く、静的に `type` の問題）。Rational 同士・Integer との比較は正確で、Float とは Float の値で比べます。

```ruby
p(1r/3 < 1r/2)                   # => true
p(Rational.<(1r/3, 0.5))         # => true
p(Rational.<=(1r/2, 0.5))        # => true
p(Rational.>(1r/3, 0.3))         # => true
p(Rational.>=(1r, 1))            # => true
```

```ruby error
p(Rational.<(1r, Complex(1, 0))) # !> the operands are (Rational, Complex), which the left operand's type does not support
```

## <=>

`Rational.<=>(x, Any)`

`x <=> y` の関数形で、-1、0、1 を返します。右側が Integer か Rational なら結果は常に Integer です。右側が Float のときは NaN なら **nil** になるので型は `Integer | nil` で、`--strict`（レベル 2 の `nil`）は結果をそのまま算術に使うことを報告します。

```ruby
p(Rational.<=>(1r/3, 1r/2))      # => -1
p(Rational.<=>(1r/2, 1r/2))      # => 0
p(Rational.<=>(1r, 1r/2))        # => 1
p(Rational.<=>(1r/2, Float.NAN)) # => nil
c = Rational.<=>(1r/3, 1r/2)
p(c + 1)                         # => 0
```

```ruby error
c = Rational.<=>(1r/3, 0.5)
p(c + 1)                         # !> the operands may be nil
```

## abs, magnitude

`Rational.abs(x)`

`Rational.magnitude(x)`

絶対値（Rational）。2 つは同じ働きです。

```ruby
p(Rational.abs(-1r/3))           # => (1/3)
p(Rational.magnitude(-1r/3))     # => (1/3)
p(Rational.abs(-5r/2))           # => (5/2)
```

## negative?, positive?, zero?

`Rational.negative?(x)`

`Rational.positive?(x)`

`Rational.zero?(x)`

`x < 0`、`x > 0`、`x == 0` を true/false で返します。

```ruby
p(Rational.positive?(1r/3))      # => true
p(Rational.positive?(0r))        # => false
p(Rational.negative?(-1r/3))     # => true
p(Rational.zero?(0r))            # => true
p(Rational.zero?(1r/3))          # => false
```

## numerator, denominator

`Rational.numerator(x)`

`Rational.denominator(x)`

既約分数にしたときの分子・分母（Integer）。符号は分子が持ち、分母は常に正です。整数値の分母は 1。

```ruby
p(Rational.numerator(-6r/4))     # => -3
p(Rational.denominator(-6r/4))   # => 2
p(Rational.numerator(1r/2 + 1r/2))    # => 1
p(Rational.denominator(1r/2 + 1r/2))  # => 1
```

## to_i, truncate, floor, ceil, round

`Rational.to_i(x)`

`Rational.truncate(x)`

`Rational.floor(x)`

`Rational.ceil(x)`

`Rational.round(x)`

Integer にします。`to_i` と `truncate` は 0 に近い方へ、`floor` は下へ、`ceil` は上へ、`round` は最も近い Integer へ（ちょうど .5 は 0 から遠い方へ: `Rational.round(5r/2)` は 3、`-5r/2` は -3）。Ruby の `round(digits)` などの桁数引数はこれらには無く、桁を指定するには `Arithmetic.round(x, n)` を使います（結果は Rational）。

```ruby
p(Rational.to_i(-7r/2))          # => -3
p(Rational.truncate(7r/3))       # => 2
p(Rational.floor(-7r/2))         # => -4
p(Rational.ceil(7r/2))           # => 4
p(Rational.round(7r/2))          # => 4
p(Rational.round(5r/2))          # => 3
p(Rational.round(-1r/2))         # => -1
```

```ruby error
p(Rational.round(7r/3, 1))       # !> wrong number of arguments for Rational.round (given 2, expected 1)
```

## fdiv

`Rational.fdiv(x, Integer|Float|Rational)`

浮動小数点の割り算 `x / y` の結果を **Float** で返します。0 で割ると `Infinity`（例外は出ません）。

```ruby
p(Rational.fdiv(1r/3, 2))        # => 0.16666666666666666
p(Rational.fdiv(2r/3, 1r/3))     # => 2.0
p(Rational.fdiv(1r, 0))          # => Infinity
```

## quo

`Rational.quo(x, Integer|Rational)`

正確な割り算 `x / y`（Rational）。`y` は Integer か Rational で、Float は静的に `type` の問題です（Float で割るには `/` を使います）。0 で割ると `ZeroDivisionError`。

```ruby
p(Rational.quo(1r/3, 2))         # => (1/6)
p(Rational.quo(1r/3, 2r/3))      # => (1/2)
```

```ruby error
p(Rational.quo(1r/3, 0))         # !> ZeroDivisionError: Rational.quo: divided by 0
```

## rationalize

`Rational.rationalize(x, [Rational])`

許容誤差 `eps`（Rational）の範囲 `x - eps .. x + eps` で最も簡単な分数を返します（Ruby の `Rational#rationalize`）。`eps` を省くと x 自身を返します。`eps` は Rational でなければならず、Float は静的に `type` の問題です。

```ruby
pi = 3141592653589793r/1000000000000000
p(Rational.rationalize(pi, 1r/100))   # => (22/7)
p(Rational.rationalize(pi, 1r/1000000))  # => (355/113)
p(Rational.rationalize(1r/3))         # => (1/3)
```

```ruby error
p(Rational.rationalize(1r/3, 0.1))    # !> Rational.rationalize: argument 2 must be Rational, but is Float
```

## to_f

`Rational.to_f(x)`

最も近い Float にします。

```ruby
p(Rational.to_f(1r/4))           # => 0.25
p(Rational.to_f(2r/3))           # => 0.6666666666666666
```

## to_r

`Rational.to_r(x)`

x 自身を返します（型が `Integer | Rational` の値をまとめて扱うときの形合わせ用）。

```ruby
p(Rational.to_r(1r/3))           # => (1/3)
```

## to_s

`Rational.to_s(x)`

`"分子/分母"` の形の String（Ruby と同じ）。整数値でも `"2/1"` と分母が付きます。`p` の表示 `(1/3)` とは括弧の分だけ違います。

```ruby
p(Rational.to_s(1r/3))           # => "1/3"
p(Rational.to_s(2r))             # => "2/1"
p(Rational.to_s(-6r/4))          # => "-3/2"
```
