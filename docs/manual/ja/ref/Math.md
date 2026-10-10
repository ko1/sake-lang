# Math

Math は Ruby の `Math` モジュールにあたる初等関数の集まりです。型ではなく名前空間で、Math の値はありません。どの関数も実数（Integer、Float、Rational）を取り、結果は常に **Float** です（`Math.sqrt(4)` は `2.0`。Complex は渡せません）。`atan2` と `hypot` の 2 引数の関数と `ldexp` の指数だけは Rational を取らず、Integer か Float です。

Ruby の `Math::PI`・`Math::E` は Sake では引数なしの操作 `Math.PI`・`Math.E` です（Sake に値の定数はありません）。Ruby の `Math.log(x, base)` の底を指定する形はありません（`Math.log(x) / Math.log(base)` と書きます）。

定義域の外の引数（`sqrt(-1)`、`log(-1)`、`acos(2)` など）は Ruby と同じく `Math::DomainError` を投げ、`rescue Math::DomainError => e` で受けられます（[例外とエラー](../08-exceptions.md)）。NaN を渡せば NaN が返り、無限大は IEEE の規則に従います（`log(0)` は `-Infinity`、`exp(1000)` は `Infinity`。例外は出ません）。

## PI, E

`Math.PI()`

`Math.E()`

円周率 π と自然対数の底 e（Float）。`Math.PI` または `Math.PI()` と書きます。

```ruby
p(Math.PI)                         # => 3.141592653589793
p(Math.E)                          # => 2.718281828459045
p(Math.cos(Math.PI))               # => -1.0
p(Math.exp(1) == Math.E)           # => true
```

## sqrt, cbrt

`Math.sqrt(Integer|Float|Rational)`

`Math.cbrt(Integer|Float|Rational)`

平方根・立方根（Float）。`sqrt` の負の引数は `Math::DomainError`。`cbrt` は負の数も取れます（`cbrt(-8)` は `-2.0`）。Integer の正確な平方根が欲しいときは `Integer.sqrt(n)` です。

```ruby
p(Math.sqrt(4))                    # => 2.0
p(Math.sqrt(2.0))                  # => 1.4142135623730951
p(Math.sqrt(9r/4))                 # => 1.5
p(Math.cbrt(-8))                   # => -2.0
p(Math.sqrt(Float.INFINITY))       # => Infinity
begin
  Math.sqrt(-1)
rescue Math::DomainError => e
  p(Exception.message(e))          # => "Numerical argument is out of domain - sqrt"
end
```

```ruby error
p(Math.sqrt(-1))                   # !> Math::DomainError: Math.sqrt: Numerical argument is out of domain - sqrt
```

## sin, cos, tan

`Math.sin(Integer|Float|Rational)`

`Math.cos(Integer|Float|Rational)`

`Math.tan(Integer|Float|Rational)`

三角関数。引数はラジアンです。結果は Float で、`sin(π)` のような値は正確な 0 にはならず、丸め誤差を含みます。

```ruby
p(Math.sin(0))                     # => 0.0
p(Math.cos(0))                     # => 1.0
p(Math.sin(Math.PI / 2))           # => 1.0
p(Math.cos(Math.PI / 3))           # => 0.5000000000000001
p(Math.tan(Math.PI / 4))           # => 0.9999999999999999
```

## asin, acos, atan

`Math.asin(Integer|Float|Rational)`

`Math.acos(Integer|Float|Rational)`

`Math.atan(Integer|Float|Rational)`

逆三角関数（ラジアンの Float）。`asin`・`acos` の引数は -1 から 1 の間でなければならず、外れると `Math::DomainError`。`atan` はどの実数も取り、`-π/2` から `π/2` を返します。

```ruby
p(Math.asin(1))                    # => 1.5707963267948966
p(Math.acos(1))                    # => 0.0
p(Math.asin(0.5))                  # => 0.5235987755982989
p(Math.atan(1) * 4 == Math.PI)     # => true
p(Math.atan(Float.INFINITY))       # => 1.5707963267948966
```

```ruby error
p(Math.acos(2))                    # !> Math::DomainError: Math.acos: Numerical argument is out of domain - acos
```

## atan2

`Math.atan2(Integer|Float, Integer|Float)`

`atan2(y, x)`: 点 `(x, y)` の偏角を `-π` から `π` のラジアン（Float）で返します。`atan(y / x)` と違い、象限を区別し、`x` が 0 でも使えます。引数は Integer か Float で、Rational は静的に `type` の問題です。

```ruby
p(Math.atan2(1, 1))                # => 0.7853981633974483
p(Math.atan2(1.0, -1.0))           # => 2.356194490192345
p(Math.atan2(1, 0))                # => 1.5707963267948966
p(Math.atan2(0, -1))               # => 3.141592653589793
p(Math.atan2(-1, -1))              # => -2.356194490192345
```

```ruby error
p(Math.atan2(1r, 1))               # !> Math.atan2: argument 1 must be Integer|Float, but is Rational
```

## hypot

`Math.hypot(Integer|Float, Integer|Float)`

`sqrt(x² + y²)`（Float）。中間の 2 乗で溢れないように計算します。引数は Integer か Float で、Rational は静的に `type` の問題です。

```ruby
p(Math.hypot(3, 4))                # => 5.0
p(Math.hypot(5, 12))               # => 13.0
p(Math.hypot(1.0, 1.0))            # => 1.4142135623730951
```

```ruby error
p(Math.hypot(1r, 1))               # !> Math.hypot: argument 1 must be Integer|Float, but is Rational
```

## sinh, cosh, tanh

`Math.sinh(Integer|Float|Rational)`

`Math.cosh(Integer|Float|Rational)`

`Math.tanh(Integer|Float|Rational)`

双曲線関数（Float）。

```ruby
p(Math.sinh(0))                    # => 0.0
p(Math.cosh(0))                    # => 1.0
p(Math.sinh(1))                    # => 1.1752011936438014
p(Math.cosh(1))                    # => 1.5430806348152437
p(Math.tanh(Float.INFINITY))       # => 1.0
```

## asinh, acosh, atanh

`Math.asinh(Integer|Float|Rational)`

`Math.acosh(Integer|Float|Rational)`

`Math.atanh(Integer|Float|Rational)`

逆双曲線関数（Float）。`acosh` の引数は 1 以上、`atanh` の引数は -1 から 1 の間でなければならず、外れると `Math::DomainError`。`atanh(1)` は `Infinity`、`atanh(-1)` は `-Infinity` です。

```ruby
p(Math.asinh(1))                   # => 0.881373587019543
p(Math.acosh(2))                   # => 1.3169578969248168
p(Math.atanh(0.5))                 # => 0.5493061443340549
p(Math.atanh(1))                   # => Infinity
```

```ruby error
p(Math.acosh(0))                   # !> Math::DomainError: Math.acosh: Numerical argument is out of domain - acosh
```

## exp

`Math.exp(Integer|Float|Rational)`

`e` の x 乗（Float）。大きな引数は `Infinity` になります（例外は出ません）。

```ruby
p(Math.exp(0))                     # => 1.0
p(Math.exp(2))                     # => 7.38905609893065
p(Math.exp(0.5r))                  # => 1.6487212707001282
p(Math.exp(1000))                  # => Infinity
p(Math.exp(-Float.INFINITY))       # => 0.0
```

## log, log2, log10

`Math.log(Integer|Float|Rational)`

`Math.log2(Integer|Float|Rational)`

`Math.log10(Integer|Float|Rational)`

自然対数・2 を底とする対数・10 を底とする対数（Float）。`log(0)` は `-Infinity`、負の引数は `Math::DomainError`。Ruby の `Math.log(x, base)` の 2 引数の形はありません（引数の個数が静的に `wrong number of arguments`）。他の底は `Math.log(x) / Math.log(base)` で求めます。大きな Integer も、Float に直せない大きさでも対数を取れます（Ruby と同じ）。

```ruby
p(Math.log(Math.E))                # => 1.0
p(Math.log(1))                     # => 0.0
p(Math.log(0))                     # => -Infinity
p(Math.log2(8))                    # => 3.0
p(Math.log10(0.001))               # => -3.0
p(Math.log(8r))                    # => 2.0794415416798357
p(Math.log(8) / Math.log(2))       # => 3.0
p(Math.log(10 ** 400))             # => 921.0340371976183
```

```ruby error
p(Math.log(8, 2))                  # !> wrong number of arguments for Math.log (given 2, expected 1)
```

## erf, erfc

`Math.erf(Integer|Float|Rational)`

`Math.erfc(Integer|Float|Rational)`

誤差関数と補誤差関数 `1 - erf(x)`（Float）。

```ruby
p(Math.erf(0))                     # => 0.0
p(Math.erf(1))                     # => 0.8427007929497149
p(Math.erfc(1))                    # => 0.15729920705028513
p(Math.erf(Float.INFINITY))        # => 1.0
```

## gamma, lgamma

`Math.gamma(Integer|Float|Rational)`

`Math.lgamma(Integer|Float|Rational)`

`gamma` はガンマ関数 Γ(x)（Float。正の整数 n では `(n-1)!`）。`gamma(0)` は `Infinity`、負の整数と `-Infinity` は `Math::DomainError`、172 以上は `Infinity`。`lgamma` は Tuple `[log|Γ(x)|, sign]` を返します: 第 1 要素は絶対値の自然対数（Float）、第 2 要素は Γ(x) の符号（Integer の `1` か `-1`）です。`gamma` が溢れる大きな x でも使えます。

```ruby
p(Math.gamma(5))                   # => 24.0
p(Math.gamma(0.5))                 # => 1.772453850905516
p(Math.gamma(0))                   # => Infinity
p(Math.gamma(172))                 # => Infinity
p(Math.lgamma(6))                  # => [4.787491742782046, 1]
p(Math.lgamma(-0.5))               # => [1.2655121234846454, -1]
v, sign = Math.lgamma(-0.5)
p(sign)                            # => -1
```

```ruby error
p(Math.gamma(-1))                  # !> Math::DomainError: Math.gamma: Numerical argument is out of domain - gamma
```

## frexp, ldexp

`Math.frexp(Integer|Float|Rational)`

`Math.ldexp(Integer|Float|Rational, Integer)`

`frexp(x)` は x を仮数と指数に分けた Tuple `[fraction, exponent]`（`[Float, Integer]`）を返します。`fraction` の絶対値は 0.5 以上 1 未満で、`x == fraction * 2 ** exponent`。0 では `[0.0, 0]`。`ldexp(fraction, exponent)` はその逆で、`fraction * 2 ** exponent` を Float で返します。指数は Integer でなければならず、Float は静的に `type` の問題です。

```ruby
p(Math.frexp(8.0))                 # => [0.5, 4]
p(Math.frexp(0.75))                # => [0.75, 0]
p(Math.frexp(10))                  # => [0.625, 4]
p(Math.frexp(0))                   # => [0.0, 0]
f, e = Math.frexp(8.0)
p(Math.ldexp(f, e))                # => 8.0
p(Math.ldexp(1.0, -2))             # => 0.25
p(Math.ldexp(3, 2))                # => 12.0
```

```ruby error
p(Math.ldexp(0.5, 4.0))            # !> Math.ldexp: argument 2 must be Integer, but is Float
```
