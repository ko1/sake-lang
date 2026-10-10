# Complex

Complex は実部と虚部を持つ複素数で、各部は Integer、Float、Rational のどれかです。リテラルは Ruby と同じ虚数単位の `2i`、`3.5i` と、それを使った `1 + 2i` で、`Complex(1, 2)`（虚部省略で `Complex(1.5)`）は Kernel の操作です（引数は実数のみ。[値と型](../03-values.md)）。`p` で表示すると `(1+2i)` の形になります。

Complex に使える演算子は `+`、`-`、`*`、`/`、`**` と `==`、`!=` です。Complex には順序が無いので `<` などの比較は無く、`%` もありません（静的に `type` の問題）。右側は Integer、Float、Rational、Complex のどれでもよく、結果は常に Complex です。Integer・Float・Rational が左側でも、右側が Complex なら結果は Complex です（[演算子と添字](../05-operators.md)）。ここに挙げた `Complex.+(x, y)` などはその演算子を関数の形で呼ぶものです。

各部の型は値の中に残り、`Complex(1, 2) / 2` は `((1/2)+1i)` と Rational の実部になります（Ruby と同じ）。実部・虚部を取り出す `real`・`imag` の結果の型が `Integer | Float | Rational` なのはそのためで、Integer として使うには `case`/`in` などで型を確かめます。Ruby との違いは、各部に Complex を渡せないこと、`Complex.==(x, y)` の関数形が数以外を受け付けないことです。

## Complex[]

`Complex[*Any]`

**Complex の Array** を作ります（Complex そのものではありません）。要素はすべて Complex でなければならず、`Array.push` などの書き込みも毎回検査されます。実数は Complex に変換されず、静的に `type` の問題、実行時は `TypeError` です。空の Complex の Array は `Complex[]`。

```ruby
cs = Complex[Complex(1, 2), 3i]
Array.push(cs, Complex(0, 0))
p(cs)                              # => [(1+2i), (0+3i), (0+0i)]
p(Array.size(Complex[]))           # => 0
```

```ruby error
Array.push(Complex[], 1)           # !> Array.push: an element must be Complex, but is Integer
```

## +, -, *, /, **

`Complex.+(x, Any)`

`Complex.-(x, Any)`

`Complex.*(x, Any)`

`Complex./(x, Any)`

`Complex.**(x, Any)`

`x + y` などの関数形で、左側が Complex のものです。右側 `y` は Integer、Float、Rational、Complex のどれかで、結果は Complex。他の型は静的に `type` の問題、実行時は `TypeError` です。`/` は各部の型に従って正確に計算し、Integer 同士の部は Rational になります。各部がすべて正確（Integer・Rational）な Complex を 0 や `Complex(0, 0)` で割ると `ZeroDivisionError`、Float の部を含んでいても Integer の 0 で割れば同じく `ZeroDivisionError` ですが、`0.0` で割ると Float の規則で `Infinity` の部になります（Ruby と同じ）。`**` は整数乗なら正確、それ以外は Float の部になります。`%` は Complex にありません。

```ruby
c = Complex(1, 2)
p(c + Complex(3, 4))               # => (4+6i)
p(Complex.+(c, 1.5))               # => (2.5+2i)
p(Complex.-(Complex(5, 3), 2))     # => (3+3i)
p(Complex.*(c, c))                 # => (-3+4i)
p(Complex.*(Complex(1, 1), Complex(1, -1)))  # => (2+0i)
p(Complex./(c, 2))                 # => ((1/2)+1i)
p(Complex./(Complex(1.0, 2), 2))   # => (0.5+1i)
p(Complex./(Complex(1, 2), 0.0))   # => (Infinity+Infinity*i)
p(Complex.**(Complex(0, 1), 2))    # => (-1+0i)
p(Complex.**(c, -1))               # => ((1/5)-(2/5)*i)
p(1.5 * c)                         # => (1.5+3.0i)
```

```ruby error
p(Complex./(Complex(1, 2), 0))     # !> ZeroDivisionError: Complex./: divided by 0
```

## ==, !=

`Complex.==(x, Any)`

`Complex.!=(x, Any)`

`x == y` の関数形。実部と虚部がそれぞれ `==` なら true で、`Complex(1, 0) == 1` や `Complex(1.0, 0) == 1` も true です。演算子の `==` はどんな 2 値にも使えて型が違えば false ですが（`Complex(1, 2) == "x"` は false）、関数形の `Complex.==(x, y)` は右側が数でなければ（nil でも）実行時に `TypeError` です（検査器はこれを静的には見つけません）。

```ruby
p(Complex.==(Complex(1, 2), Complex(1, 2)))    # => true
p(Complex.==(Complex(1, 0), 1))                # => true
p(Complex.==(Complex(2, 0), 2.0))              # => true
p(Complex.!=(Complex(1, 2), Complex(2, 1)))    # => true
p(Complex(1, 2) == "x")                        # => false
```

```ruby error
p(Complex.==(Complex(1, 2), "x"))  # !> TypeError: Complex.==: no implementation for (Complex, String)
```

## real, imag, imaginary

`Complex.real(x)`

`Complex.imag(x)`

`Complex.imaginary(x)`

実部・虚部を返します。型は作ったときの部の型（`Integer | Float | Rational`）です。`imag` と `imaginary` は同じ働きです。

```ruby
c = Complex(1, 2.5)
p(Complex.real(c))                 # => 1
p(Complex.imag(c))                 # => 2.5
p(Complex.imaginary(Complex(3, 4))) # => 4
p(Complex.real(Complex(1r/2, 1)))  # => (1/2)
r = Complex.real(Complex(1, 2))
p(r + 1)                           # => 2
```

## rect, rectangular

`Complex.rect(x)`

`Complex.rectangular(x)`

実部と虚部の Tuple `[re, im]`（各位置の型は `Integer | Float | Rational`）。多重代入で両方を受け取れます。2 つは同じ働きです。

```ruby
p(Complex.rect(Complex(1, 2)))             # => [1, 2]
p(Complex.rectangular(Complex(1.5, 2r)))   # => [1.5, (2/1)]
re, im = Complex.rectangular(Complex(1, 2))
p(re + im)                                 # => 3
```

## polar

`Complex.polar(x)`

極形式の Tuple `[r, θ]`。`r` は絶対値（`abs` と同じ、`Integer | Float`）、`θ` は偏角（`arg` と同じ Float。実軸上の値では `0.0`・`π`）です。

```ruby
p(Complex.polar(Complex(3, 4)))    # => [5.0, 0.9272952180016122]
p(Complex.polar(Complex(0, 2)))    # => [2, 1.5707963267948966]
p(Complex.polar(Complex(-2, 0)))   # => [2, 3.141592653589793]
r, th = Complex.polar(Complex(3, 4))
p(r)                               # => 5.0
```

## abs, magnitude

`Complex.abs(x)`

`Complex.magnitude(x)`

絶対値 `sqrt(re² + im²)`。普通は Float ですが、Ruby と同じく片方の部が正確な 0 ならもう一方の部の絶対値をそのまま返すので、`Complex(3, 0)` では Integer の `3` です。型は `Integer | Float`（Rational の部なら Rational が返りますが、検査器はそれを見ません）。2 つは同じ働きです。

```ruby
p(Complex.abs(Complex(3, 4)))      # => 5.0
p(Complex.abs(Complex(3, 0)))      # => 3
p(Complex.abs(Complex(0, -2)))     # => 2
p(Complex.magnitude(Complex(1, 1))) # => 1.4142135623730951
a = Complex.abs(Complex(3, 4))
p(a + 1)                           # => 6.0
```

## abs2

`Complex.abs2(x)`

絶対値の 2 乗 `re² + im²`。平方根を取らないので正確で、型は各部に従う `Integer | Float | Rational` です。

```ruby
p(Complex.abs2(Complex(3, 4)))         # => 25
p(Complex.abs2(Complex(1.5, 0)))       # => 2.25
p(Complex.abs2(Complex(1r/2, 1r/2)))   # => (1/2)
```

## arg, angle, phase

`Complex.arg(x)`

`Complex.angle(x)`

`Complex.phase(x)`

偏角（Float、`-π` から `π`）。`Math.atan2(im, re)` と同じで、`Complex(0, 0)` では `0.0`、負の実軸上では `π` です。3 つは同じ働きです。

```ruby
p(Complex.arg(Complex(1, 1)))      # => 0.7853981633974483
p(Complex.angle(Complex(0, 1)))    # => 1.5707963267948966
p(Complex.phase(Complex(-1, 0)))   # => 3.141592653589793
p(Complex.arg(Complex(0, -1)))     # => -1.5707963267948966
p(Complex.arg(Complex(0, 0)))      # => 0.0
```

## conj, conjugate

`Complex.conj(x)`

`Complex.conjugate(x)`

共役複素数（虚部の符号を反転した Complex）。2 つは同じ働きです。

```ruby
p(Complex.conj(Complex(1, 2)))         # => (1-2i)
p(Complex.conjugate(Complex(1.5, -2))) # => (1.5+2i)
p(Complex.conjugate(Complex(3, 0)))    # => (3+0i)
```

## real?

`Complex.real?(x)`

常に **false** を返します（Ruby の `Complex#real?` と同じく、Complex という型は虚部が 0 でも実数ではないとみなします）。実数かどうかを値で知るには `Complex.imag(x) == 0` を使います。

```ruby
p(Complex.real?(Complex(1, 2)))    # => false
p(Complex.real?(Complex(1, 0)))    # => false
p(Complex.imag(Complex(1, 0)) == 0)  # => true
```

## finite?, infinite?

`Complex.finite?(x)`

`Complex.infinite?(x)`

`finite?` は実部と虚部がともに有限（NaN でも無限大でもない）のとき true。`infinite?` は Ruby と同じく、どちらかの部が無限大なら `1`、そうでなければ **nil**（NaN を含む）を返すので型は `Integer | nil` です。真偽として使うのが普通で、値を算術に使うには先に nil を確かめます（`--strict` の `nil` が報告します）。

```ruby
p(Complex.finite?(Complex(1, 2)))                 # => true
p(Complex.finite?(Complex(Float.INFINITY, 2)))    # => false
p(Complex.finite?(Complex(Float.NAN, 2)))         # => false
p(Complex.infinite?(Complex(1, 2)))               # => nil
p(Complex.infinite?(Complex(1, -Float.INFINITY))) # => 1
p(Complex.infinite?(Complex(Float.NAN, 2)))       # => nil
```

```ruby error
x = Complex.infinite?(Complex(1, 2))
p(x + 1)                           # !> the operands may be nil
```

## fdiv

`Complex.fdiv(x, Integer|Float|Rational)`

各部を Float にしてから実数 `y` で割った Complex（各部は Float）。`y` に Complex は渡せません（静的に `type` の問題。Complex で割るには `/` か `quo`）。0 で割ると `Infinity` の部になり、例外は出ません。

```ruby
p(Complex.fdiv(Complex(3, 4), 2))    # => (1.5+2.0i)
p(Complex.fdiv(Complex(1, 2), 2r))   # => (0.5+1.0i)
p(Complex.fdiv(Complex(1, 2), 0))    # => (Infinity+Infinity*i)
```

```ruby error
p(Complex.fdiv(Complex(1, 2), Complex(1, 1)))  # !> Complex.fdiv: argument 2 must be Integer|Float|Rational, but is Complex
```

## quo

`Complex.quo(x, Integer|Float|Rational|Complex)`

割り算 `x / y`（Complex）。`/` と同じで、Integer 同士の部は Rational になります。正確な 0 で割ると `ZeroDivisionError`。

```ruby
p(Complex.quo(Complex(3, 4), 2))              # => ((3/2)+2i)
p(Complex.quo(Complex(3, 4), 2.0))            # => (1.5+2.0i)
p(Complex.quo(Complex(3, 4), Complex(1, 1)))  # => ((7/2)+(1/2)*i)
```

```ruby error
p(Complex.quo(Complex(1, 2), 0))   # !> ZeroDivisionError: Complex.quo: divided by 0
```

## numerator, denominator

`Complex.numerator(x)`

`Complex.denominator(x)`

`denominator` は実部と虚部の分母の最小公倍数（Integer）、`numerator` は `x * denominator`（各部が整数になった Complex）です。Integer の部の分母は 1。

```ruby
c = Complex(1r/2, 1r/4)
p(Complex.denominator(c))          # => 4
p(Complex.numerator(c))            # => (2+1i)
p(Complex.denominator(Complex(3, 4)))  # => 1
p(Complex.numerator(Complex(3, 4)))    # => (3+4i)
```

## to_i, to_f, to_r, rationalize

`Complex.to_i(x)`

`Complex.to_f(x)`

`Complex.to_r(x)`

`Complex.rationalize(x, [Rational])`

虚部が正確な 0（Integer の `0` か `0r`）のときだけ、実部を Integer・Float・Rational にします（`rationalize` は実部の `rationalize`。許容誤差 `eps` は Rational）。虚部が 0 でないとき、または `0.0`（Float の 0）のときは Ruby と同じく `RangeError`（`can't convert 1+2i into Float`）です。

```ruby
p(Complex.to_i(Complex(1.9, 0)))           # => 1
p(Complex.to_f(Complex(3, 0)))             # => 3.0
p(Complex.to_r(Complex(1.5, 0)))           # => (3/2)
p(Complex.rationalize(Complex(0.333, 0)))  # => (333/1000)
p(Complex.rationalize(Complex(0.333, 0), 1r/100))  # => (1/3)
begin
  Complex.to_f(Complex(1, 2))
rescue RangeError => e
  p(Exception.message(e))                  # => "can't convert 1+2i into Float"
end
```

```ruby error
p(Complex.to_f(Complex(1, 0.0)))   # !> RangeError: Complex.to_f: can't convert 1+0.0i into Float
```

## to_c

`Complex.to_c(x)`

x 自身を返します（実数を Complex にするのは Kernel の `Complex(x)`）。

```ruby
p(Complex.to_c(Complex(3, 4)))     # => (3+4i)
```

## to_s

`Complex.to_s(x)`

`"re+imi"` の形の String（Ruby と同じ）。`p` の表示 `(3+4i)` から括弧を外したもので、Rational の部は `1/2+3i` のように括弧なしです。

```ruby
p(Complex.to_s(Complex(3, 4)))         # => "3+4i"
p(Complex.to_s(Complex(-1, -1)))       # => "-1-1i"
p(Complex.to_s(Complex(0.5, 2)))       # => "0.5+2i"
p(Complex.to_s(Complex(1r/2, 3)))      # => "1/2+3i"
```
