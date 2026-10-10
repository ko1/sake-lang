# Float

Float は IEEE 754 の倍精度浮動小数点数です。リテラルは `1.5`、`2.0`、`1e-3`（[値と型](../03-values.md)）。文字列からの変換 `Float("1.5")` は Kernel の操作で、Integer からは `Integer.to_f(n)` です。Integer を Float の代わりに渡す暗黙の変換はありません: `Float[1]` や `Float.clamp(x, 1, 2)` は静的に `type` の問題です。

Float に使える演算子は `+`、`-`、`*`、`/`、`%`、`**` と `==`、`!=`、`<`、`<=`、`>`、`>=`、`<=>` です。右側は Integer、Float、Rational、Complex のどれでもよく、結果の型は閉じた表で決まります: Integer・Rational との演算は Float、Complex との演算は Complex（[演算子と添字](../05-operators.md)）。ここに挙げた `Float.+(x, y)` などはその演算子を関数の形で呼ぶもので、左側が Float と決まっている分だけ検査が細かくなります。

Ruby と同じく、0 で割ると例外ではなく `Infinity`・`-Infinity`・`NaN` になり（`%`・`modulo`・`divmod` は例外で `ZeroDivisionError`）、NaN・Infinity を Integer に変える操作（`to_i`、`floor`、`ceil`、`round`、`truncate`、`to_r`、`numerator`、`denominator`）は `FloatDomainError` を投げます。Ruby の `Float::INFINITY` などの定数は、Sake では `Float.INFINITY` のように引数なしの操作として読みます（Sake に値の定数はありません）。Ruby との大きな違いは、`round(f, 2)` が桁数を付けると常に Float を返すこと、負の底に分数の指数（`(-8.0) ** 0.5`）が Complex ではなく `Math::DomainError` になること、`divmod` が Tuple を返すこと、`<=>` と `infinite?` の nil を検査器が追うことです。

## Float[]

`Float[*Any]`

**Float の Array** を作ります（Float そのものではありません）。`Integer[]` などと同じ型付き Array で、要素はすべて Float でなければならず、`Array.push` などの書き込みも毎回検査されます。Integer は Float に変換されません: `Float[1.5, 2]` は静的に `type` の問題、実行時は `TypeError` です。空の Float の Array は `Float[]`。

```ruby
fs = Float[1.5, 2.0]
Array.push(fs, 3.5)
p(fs)                          # => [1.5, 2.0, 3.5]
p(Array.size(Float[]))         # => 0
p(Array.sum(fs))               # => 7.0
```

```ruby error
Array.push(Float[], 1)         # !> Array.push: an element must be Float, but is Integer
```

## INFINITY, NAN, EPSILON, MAX, MIN

`Float.INFINITY()`

`Float.NAN()`

`Float.EPSILON()`

`Float.MAX()`

`Float.MIN()`

Ruby の `Float::INFINITY` などに当たる値を返す、引数なしの操作です（Sake には値の定数が無いので、`Float.INFINITY` または `Float.INFINITY()` と書きます）。`INFINITY` は正の無限大（負は `-Float.INFINITY`）、`NAN` は非数、`EPSILON` は 1.0 と「1.0 より大きい最小の Float」との差、`MAX` は最大の有限値、`MIN` は正の最小の正規化数です。型はすべて Float。NaN はどの値とも `==` で等しくならず、自分自身とも等しくありません。

```ruby
p(Float.INFINITY)              # => Infinity
p(-Float.INFINITY)             # => -Infinity
p(Float.NAN == Float.NAN)      # => false
p(Float.EPSILON)               # => 2.220446049250313e-16
p(1.0 + Float.EPSILON > 1.0)   # => true
p(Float.MAX)                   # => 1.7976931348623157e+308
p(Float.MAX * 2)               # => Infinity
p(Float.MIN)                   # => 2.2250738585072014e-308
```

## +, -, *, /, %, **

`Float.+(x, Any)`

`Float.-(x, Any)`

`Float.*(x, Any)`

`Float./(x, Any)`

`Float.%(x, Any)`

`Float.**(x, Any)`

`x + y` などの関数形で、左側が Float のものです。右側 `y` は Integer、Float、Rational、Complex のどれか。Integer・Rational との結果は Float、Complex との結果は Complex です。それ以外の型（String、nil など）は静的に `type` の問題（`the operands are (Float, String), which the left operand's type does not support`）、実行時は `TypeError` です。

割り算は IEEE に従い、`1.0 / 0` は `Infinity`、`0.0 / 0` は `NaN` で、例外は出ません。`%` は Ruby の `Float#%`（結果の符号は右側に従う）ですが、0（Integer の `0` でも Float の `0.0` でも）で割ると `ZeroDivisionError` です（`rescue` できます。Ruby 4 も同じく投げます）。`**` は Integer・Float・Rational の指数で Float を返します。Ruby と違い、負の底に分数の指数（`(-8.0) ** 0.5`）は Complex ではなく `Math::DomainError` なので、結果は常に Float です。

```ruby
p(1.5 + 2)                     # => 3.5
p(Float.+(1.5, 2r))            # => 3.5
p(Float.+(1.5, Complex(1, 2))) # => (2.5+2i)
p(Float.*(1.5, 2))             # => 3.0
p(Float./(1.0, 0))             # => Infinity
p(Float./(0.0, 0))             # => NaN
p(Float.%(7.5, 2))             # => 1.5
p(-7.5 % 2)                    # => 0.5
p(Float.**(2.0, 3))            # => 8.0
p(Float.**(2.0, 0.5))          # => 1.4142135623730951
p(Float.**(2.0, 2r))           # => 4.0
p((-8.0) ** 2)                 # => 64.0
begin
  7.5 % 0.0
rescue ZeroDivisionError => e
  p(Exception.message(e))      # => "divided by 0"
end
```

```ruby error
p(Float.+(1.5, "a"))           # !> the operands are (Float, String), which the left operand's type does not support
```

```ruby error
p(Float.%(7.5, 0))             # !> ZeroDivisionError: Float.%: divided by 0
```

```ruby error
p(Float.**(-8.0, 0.5))         # !> Math::DomainError: Float.**: -8.0 ** 0.5 is not a real number (a negative base with a fractional exponent)
```

## ==, !=

`Float.==(x, Any)`

`Float.!=(x, Any)`

`x == y` の関数形。Float は Integer・Rational・Complex と値で比べられ、`1.0 == 1` は true です。NaN は自分自身を含むどの値とも等しくありません。別の型の値とは決して等しくなく（`1.0 == "1"` は false）、関数形の `Float.==(x, y)` も演算子と同じく、右側が他のどんな型でも false（`!=` は true）を返し、エラーにはなりません。

```ruby
p(Float.==(1.0, 1))            # => true
p(Float.==(1.0, 1r))           # => true
p(1.5 != 1.5)                  # => false
p(Float.!=(1.0, Float.NAN))    # => true
p(1.0 == "1")                  # => false
p(Float.==(1.0, "1"))          # => false
p(Float.!=(1.0, nil))          # => true
```

## <, <=, >, >=

`Float.<(x, Any)`

`Float.<=(x, Any)`

`Float.>(x, Any)`

`Float.>=(x, Any)`

`x < y` などの関数形。右側は Integer、Float、Rational のどれか（Complex に順序は無く、静的に `type` の問題）。NaN との比較はすべて false です。

```ruby
p(1.5 < 2)                     # => true
p(Float.<=(1.5, 2r))           # => true
p(Float.>(1.5, 2))             # => false
p(Float.>=(1.5, 1.5))          # => true
p(Float.NAN < 1.0)             # => false
```

```ruby error
p(Float.<(1.0, Complex(1, 0))) # !> the operands are (Float, Complex), which the left operand's type does not support
```

## <=>

`Float.<=>(x, Any)`

`x <=> y` の関数形で、-1、0、1 を返します。右側は Integer、Float、Rational。どちらかが NaN なら **nil** なので結果の型は `Integer | nil` で、`--strict`（レベル 2 の `nil`）は結果をそのまま算術に使うことを `the operands may be nil` と報告します。先に `if c` などで確かめてください。

```ruby
p(Float.<=>(1.5, 2))           # => -1
p(1.5 <=> 1.5)                 # => 0
p(Float.<=>(Float.NAN, 1.0))   # => nil
c = 2.0 <=> 1
if c
  p(c + 1)                     # => 2
end
```

```ruby error
c = Float.<=>(1.5, 2.0)
p(c + 1)                       # !> the operands may be nil
```

## abs, magnitude

`Float.abs(x)`

`Float.magnitude(x)`

絶対値（Float）。`-0.0` は `0.0`、`-Infinity` は `Infinity` になります。

```ruby
p(Float.abs(-1.5))             # => 1.5
p(Float.magnitude(-1.5))       # => 1.5
p(Float.abs(-0.0))             # => 0.0
p(Float.abs(-Float.INFINITY))  # => Infinity
```

## negative?, positive?, zero?

`Float.negative?(x)`

`Float.positive?(x)`

`Float.zero?(x)`

`x < 0`、`x > 0`、`x == 0` を true/false で返します。`-0.0` は `zero?` が true で、`negative?` も `positive?` も false です。NaN はどれも false。

```ruby
p(Float.negative?(-1.5))       # => true
p(Float.negative?(-0.0))       # => false
p(Float.positive?(0.0))        # => false
p(Float.zero?(-0.0))           # => true
p(Float.zero?(1.5))            # => false
```

## nan?, finite?, infinite?

`Float.nan?(x)`

`Float.finite?(x)`

`Float.infinite?(x)`

`nan?` は NaN のとき true。`finite?` は NaN でも無限大でもないとき true。`infinite?` は Ruby と同じく正の無限大で `1`、負の無限大で `-1`、それ以外（NaN を含む）で **nil** を返すので、型は `Integer | nil` です。真偽として `if Float.infinite?(x)` のように使うのが普通で、値を算術に使うには先に nil を確かめます（`--strict` の `nil` が報告します）。

```ruby
p(Float.nan?(0.0 / 0))               # => true
p(Float.nan?(1.5))                   # => false
p(Float.finite?(1.5))                # => true
p(Float.finite?(Float.INFINITY))     # => false
p(Float.infinite?(1.5))              # => nil
p(Float.infinite?(Float.INFINITY))   # => 1
p(Float.infinite?(-Float.INFINITY))  # => -1
```

## to_i, to_int, truncate

`Float.to_i(x)`

`Float.to_int(x)`

`Float.truncate(x)`

小数部分を切り捨てて 0 に近い方の Integer にします（Ruby の `Float#to_i`）。3 つは同じ結果です。NaN と Infinity は Integer にできないので `FloatDomainError`（メッセージはその値 `NaN` / `Infinity`）。Ruby の `truncate(digits)` の桁数引数は Float には無く、`Arithmetic.truncate(x, n)` を使います（[Arithmetic](Arithmetic.md)）。

```ruby
p(Float.to_i(1.9))             # => 1
p(Float.to_int(-1.9))          # => -1
p(Float.truncate(-1.8))        # => -1
begin
  Float.to_i(Float.NAN)
rescue FloatDomainError => e
  p(Exception.message(e))      # => "NaN"
end
```

```ruby error
p(Float.truncate(Float.INFINITY))  # !> FloatDomainError: Float.truncate: Infinity
```

## floor, ceil

`Float.floor(x)`

`Float.ceil(x)`

`floor` は x 以下の最大の Integer、`ceil` は x 以上の最小の Integer を返します。NaN・Infinity は `FloatDomainError`。桁数引数は無く、`Arithmetic.floor(x, n)`・`Arithmetic.ceil(x, n)` が代わりです。

```ruby
p(Float.floor(1.8))            # => 1
p(Float.floor(-1.2))           # => -2
p(Float.ceil(1.2))             # => 2
p(Float.ceil(-1.2))            # => -1
```

```ruby error
p(Float.floor(Float.INFINITY)) # !> FloatDomainError: Float.floor: Infinity
```

## round

`Float.round(x, [Integer], [half: Symbol])`

四捨五入します。桁数を省くと最も近い Integer を返し、.5 は既定では 0 から遠い方に丸めます（`Float.round(2.5)` は 3、`-2.5` は -3。Ruby の `round` と同じ）。桁数 `n` を付けると小数第 n 位に丸めた **Float** を返します。負の桁数は 10 の冪に丸めますが、結果はやはり Float です（Ruby の `1234.5.round(-2)` は Integer 1200 ですが、Sake では `1200.0`）。結果の型が桁数の有無で決まるのは、検査器が引数の個数を見るからです。キーワード `half:` は Ruby と同じく、ちょうど .5 のときの丸め方を選びます: `:up`（既定。0 から遠い方へ）、`:even`（偶数側へ。銀行家の丸め）、`:down`（0 に近い方へ）。他の Symbol は `ArgumentError`（`invalid rounding mode: foo`）、Symbol 以外は `type` の問題です。桁数なしの NaN・Infinity は `FloatDomainError`、桁数付きならそのまま NaN・Infinity を返します。

```ruby
p(Float.round(1.5))            # => 2
p(Float.round(2.5))            # => 3
p(Float.round(-2.5))           # => -3
p(Float.round(1.2345, 2))      # => 1.23
p(Float.round(3.14159, 3))     # => 3.142
p(Float.round(1234.5, -2))     # => 1200.0
p(Float.round(1.5, 0))         # => 2.0
p(Float.round(Float.NAN, 2))   # => NaN
p(Float.round(2.5, half: :even))      # => 2
p(Float.round(3.5, half: :even))      # => 4
p(Float.round(2.5, half: :down))      # => 2
p(Float.round(2.5, 0, half: :even))   # => 2.0
p(Float.round(1.25, 1, half: :even))  # => 1.2
p(Float.round(1250.0, -2, half: :even))  # => 1200.0
```

```ruby error
p(Float.round(-Float.INFINITY))  # !> FloatDomainError: Float.round: -Infinity
```

```ruby error
p(Float.round(2.5, half: :foo))  # !> ArgumentError: Float.round: invalid rounding mode: foo
```

## divmod

`Float.divmod(x, Any)`

商と余りの Tuple `[q, r]` を返します。`q` は `x / y` を floor した **Integer**、`r` は `x - q * y` の Float で、符号は `y` に従います（Ruby の `7.5.divmod(2)` が `[3, 1.5]` なのと同じ）。`y` は Float か Integer で、他の型（Rational を含む）は静的に `type` の問題です。0（Integer の `0` でも Float の `0.0` でも）で割ると `ZeroDivisionError`、`x` が NaN・Infinity なら `FloatDomainError`（メッセージはその値）です。どちらも `rescue` できます。

```ruby
p(Float.divmod(7.5, 2))        # => [3, 1.5]
p(Float.divmod(-7.5, 2.0))     # => [-4, 0.5]
q, r = Float.divmod(7.5, 2)
p(q + 1)                       # => 4
p(r + 0.5)                     # => 2.0
begin
  Float.divmod(Float.NAN, 2)
rescue FloatDomainError => e
  p(Exception.message(e))      # => "NaN"
end
```

```ruby error
p(Float.divmod(7.5, 0))        # !> ZeroDivisionError: Float.divmod: divided by 0
```

```ruby error
p(Float.divmod(7.5, 0.0))      # !> ZeroDivisionError: Float.divmod: divided by 0
```

## fdiv, quo

`Float.fdiv(x, Integer|Float|Rational)`

`Float.quo(x, Integer|Float|Rational)`

浮動小数点の割り算 `x / y`（Float）。`/` と同じ結果で、0 で割れば `Infinity` か `NaN` です（例外は出ません）。2 つは同じ働きです。

```ruby
p(Float.fdiv(7.5, 2))          # => 3.75
p(Float.quo(1.0, 4r))          # => 0.25
p(Float.fdiv(1.0, 0))          # => Infinity
```

## modulo

`Float.modulo(x, Integer|Float|Rational)`

`x % y` と同じ余り（Float。符号は `y` に従う）で、`%` と同じ働きです。0（Integer の 0 でも `0.0` でも）で割ると `ZeroDivisionError` を投げます。

```ruby
p(Float.modulo(7.5, 2))        # => 1.5
p(Float.modulo(-7.5, 2))       # => 0.5
p(Float.modulo(5.5, 2.5))      # => 0.5
begin
  Float.modulo(7.5, 0)
rescue ZeroDivisionError => e
  p(Exception.message(e))      # => "divided by 0"
end
```

## between?

`Float.between?(x, Float, Float)`

`lo <= x <= hi` のとき true。`lo`、`hi` は Float でなければならず、Integer は静的に `type` の問題です（`argument 2 must be Float, but is Integer`）。

```ruby
p(Float.between?(1.5, 1.0, 2.0))   # => true
p(Float.between?(2.5, 1.0, 2.0))   # => false
```

```ruby error
p(Float.between?(1.5, 1, 2))       # !> Float.between?: argument 2 must be Float, but is Integer
```

## clamp

`Float.clamp(x, Float, Float)`

`x` を `lo..hi` に収めた Float を返します（`lo` 未満なら `lo`、`hi` より大きければ `hi`）。`lo`、`hi` は Float のみ。`lo > hi` は `ArgumentError`（`min argument must be less than or equal to max argument`）で、`rescue` できます。

```ruby
p(Float.clamp(2.5, 1.0, 2.0))  # => 2.0
p(Float.clamp(0.5, 1.0, 2.0))  # => 1.0
p(Float.clamp(1.5, 1.0, 2.0))  # => 1.5
```

```ruby error
p(Float.clamp(1.5, 1, 2))      # !> Float.clamp: argument 2 must be Float, but is Integer
```

```ruby error
p(Float.clamp(1.5, 2.0, 1.0))  # !> ArgumentError: Float.clamp: min argument must be less than or equal to max argument
```

## next_float, prev_float

`Float.next_float(x)`

`Float.prev_float(x)`

x の次に大きい・次に小さい表現可能な Float。`next_float(1.0) - 1.0` が `Float.EPSILON` です。`Float.MAX` の次は `Infinity`、NaN の次は NaN。

```ruby
p(Float.next_float(1.0))                       # => 1.0000000000000002
p(Float.prev_float(1.0))                       # => 0.9999999999999999
p(Float.next_float(0.0))                       # => 5.0e-324
p(Float.next_float(1.0) - 1.0 == Float.EPSILON)  # => true
p(Float.next_float(Float.MAX))                 # => Infinity
```

## to_r, rationalize

`Float.to_r(x)`

`Float.rationalize(x)`

Rational に変えます。`to_r` は 2 進の値をそのまま分数にするので `0.1` は `3602879701896397/36028797018963968` になります。`rationalize` は元の Float に丸め戻せる範囲で最も簡単な分数を選ぶので `0.1` は `1/10` です。NaN・Infinity は `FloatDomainError`。Ruby の `rationalize(eps)` の許容誤差引数は Float には無く、`Rational.rationalize(r, eps)` が代わりです（[Rational](Rational.md)）。

```ruby
p(Float.to_r(0.75))            # => (3/4)
p(Float.to_r(0.1))             # => (3602879701896397/36028797018963968)
p(Float.rationalize(0.1))      # => (1/10)
p(Float.rationalize(0.333))    # => (333/1000)
p(Float.to_r(-1.5))            # => (-3/2)
```

```ruby error
p(Float.to_r(Float.NAN))       # !> FloatDomainError: Float.to_r: NaN
```

## numerator, denominator

`Float.numerator(x)`

`Float.denominator(x)`

`Float.to_r(x)` の分子・分母（Integer）。`0.1` の分母は `36028797018963968` のように 2 進表現の値になります。Ruby では NaN の `numerator` は NaN そのもの、`denominator` は 1 ですが、Sake では NaN・Infinity は `FloatDomainError` で、結果は常に Integer です。

```ruby
p(Float.numerator(0.75))       # => 3
p(Float.denominator(0.75))     # => 4
p(Float.numerator(1.5))        # => 3
p(Float.denominator(0.1))      # => 36028797018963968
```

```ruby error
p(Float.numerator(Float.NAN))  # !> FloatDomainError: Float.numerator: NaN
```

## angle, arg, phase

`Float.angle(x)`

`Float.arg(x)`

`Float.phase(x)`

複素平面での偏角。正の数（と `0.0`）では Integer の `0`、負の数（と `-0.0`）では Float の `π` を返すので、型は `Integer | Float` です。NaN では NaN。3 つは同じ働きです。

```ruby
p(Float.angle(1.5))            # => 0
p(Float.arg(-1.5))             # => 3.141592653589793
p(Float.phase(-0.0))           # => 3.141592653589793
p(Float.angle(Float.NAN))      # => NaN
```

## to_f, to_s

`Float.to_f(x)`

`Float.to_s(x)`

`to_f` は x 自身を返します（型が `Integer | Float` の値をまとめて Float にするには `Arithmetic.to_f(x)`）。`to_s` は Ruby の表記で、整数値でも `.0` が付き、おおよそ 1e16 以上と 1e-4 未満は `1.0e+20` のような指数表記になります。`Infinity`、`-Infinity`、`NaN` もそのまま文字にします。`puts(1.5)` も同じ表記です。

```ruby
p(Float.to_f(1.5))             # => 1.5
p(Float.to_s(1.0))             # => "1.0"
p(Float.to_s(0.1 + 0.2))       # => "0.30000000000000004"
p(Float.to_s(1e20))            # => "1.0e+20"
p(Float.to_s(1e-5))            # => "1.0e-05"
p(Float.to_s(Float.INFINITY))  # => "Infinity"
p(Float.to_s(-0.0))            # => "-0.0"
```
