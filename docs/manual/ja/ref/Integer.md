# Integer

Integer は Ruby と同じく大きさに上限の無い整数です: `42`、`-7`、`1_000_000`、`0x1f`、`0b101`、`0o17`、`2 ** 100`（[値と型](../03-values.md)）。変換 `Integer("42")`、`Integer(3.9)` はこの名前空間ではなく Kernel の操作です（`Kernel.Integer`。不正な入力は `ArgumentError`）。Integer は値であり、主語を変更する操作はここにはありません。すべての結果は新しい値です。

Integer に使える演算子は Integer が include するモジュールから来ます（[演算子と添字](../05-operators.md)）: `Arithmetic` が `+ - * / % **` と単項の `-x`、`Comparable` が `<=> < <= > >=`、`Bitwise` が `& | ^ << >>` と単項の `~x` を与え、`==` と `!=` は Kernel のものです。`a + b` は `a` の型で振り分けられるので、左が Integer なら `Integer.+(a, b)` が走ります。以下の `Integer.+(x, y)` などはその関数形です。右側の型は**閉じた表**で決まります: Integer と Integer は Integer、Float とは Float、Rational とは Rational（`**` だけは Rational の指数で `Rational | Float`）、Complex とは Complex。`<` などは Integer、Float、Rational と比べられ、ビット演算子は Integer だけを取ります。それ以外の型の右側（String、nil、Symbol）は静的に `type` の問題（`the operands are (Integer, String), which the left operand's type does not support`）、実行時は `TypeError` です。関数形は第 1 引数も Integer でなければなりません（`Integer.+(1.0, 2)` は `type` の問題。`Float.+` か演算子を使います）。

Ruby と違う点は 2 つ: `Integer ** 負の Integer` は Rational を返さず `ArgumentError` を投げます（`a ** b` の型が `b` の値に依存しないように）。また値に対するメソッド呼び出しはありません（`1.+(2)` は拒否され、`Integer.+(1, 2)` か `1 + 2` と書きます）。`/` と `%` は Ruby と同じく床へ丸め（`-7 / 2` は -4）、0 で割ると `ZeroDivisionError` です。

丸めの一族 `round`、`floor`、`ceil`、`truncate` と `abs`、`to_f`、`to_i`、`zero?` はモジュール `Arithmetic`（[Arithmetic](Arithmetic.md)）にもあり、そちらはどの実数も取ります（Integer、Float、Rational の `x` に `Arithmetic.round(x)`。Ruby の `x.round`）。以下の項目は Integer 専用の形で、Float の主語は `Arithmetic` を使うようヒント付きで拒否されます。結果が nil になりうる操作はこの名前空間にはありません: どの結果も確定した Integer、Float、Rational、String、Boolean、Tuple、Array です。

## Integer[]

`Integer[*Any]`

**Integer の Array** を作ります: 要素がすべて Integer でなければならない型付き Array で、構築時と書き込み（`Array.push`、`a[i] = v` など）のたびに検査されます。別の型のリテラル要素は実行前に拒否され（`element 2 must be Integer, got String`）、別の型の書き込みは静的に `type` の問題、実行時は `TypeError` です。空の Integer の Array は `Integer[]` です。`Array[1, 2]` は要素の型が推論され、書き込まれたものに応じて広がる点が違います。

```ruby
a = Integer[1, 2, 3]
Array.push(a, 4)
p(a)                         # => [1, 2, 3, 4]
p(Array.size(Integer[]))     # => 0
```

```ruby error
Array.push(Integer[], 1.5)   # !> Array.push: an element must be Integer, but is Float
```

## +, -, *

`Integer.+(x, Any)`

`Integer.-(x, Any)`

`Integer.*(x, Any)`

加算・減算・乗算。どんな大きさでも正確です。結果の型は右側に従います: Integer なら Integer、Float なら Float、Rational なら Rational、Complex なら Complex。それ以外の右側は `type` の問題です。単項マイナス `-x` は `Integer.-@` で、演算子としてだけ書けます。

```ruby
p(Integer.+(1, 2))           # => 3
p(Integer.-(1, 2))           # => -1
p(3 * 4)                     # => 12
p(2 + 1.5)                   # => 3.5
p(1 + 1r)                    # => (2/1)
p(2 ** 64 + 1)               # => 18446744073709551617
```

```ruby error
p(1 + "a")                   # !> the operands are (Integer, String), which the left operand's type does not support
```

## /, %

`Integer./(x, Any)`

`Integer.%(x, Any)`

除算と剰余。Integer 同士では Ruby と同じくどちらも**床**へ丸めます: 商は負の無限大の方向へ丸め、余りは除数の符号を取ります（`-7 / 2` は -4、`-7 % 3` は 2、`7 % -3` は -2）。Integer の除数 0 は `ZeroDivisionError`。右側が Float なら結果は Float で、`0.0` で割ると `Infinity`（IEEE）、Rational なら Rational です。`div`、`modulo`、`remainder`、`divmod`、`fdiv`、`ceildiv` も参照。

```ruby
p(7 / 2)                     # => 3
p(-7 / 2)                    # => -4
p(7 % 3)                     # => 1
p(-7 % 3)                    # => 2
p(Integer./(7, 2.0))         # => 3.5
p(1 / 0.0)                   # => Infinity
```

```ruby error
p(Integer./(1, 0))           # !> ZeroDivisionError: Integer./: divided by 0
```

## **

`Integer.**(x, Any)`

べき乗。Integer に非負の Integer の指数なら正確な Integer。Float の指数は Float を与えます。**Rational の指数**は、整数値なら Rational（`2 ** 2r` は `(4/1)`）、そうでなければ Float（`2 ** (1r/2)` は `1.4142135623730951`）になるので、検査器はその結果を `Rational | Float` とします。どちらかとして使う前に `case`/`in` で絞ってください。Ruby と違い、**負の Integer の指数は `ArgumentError`** です（Ruby は Rational を返す）。メッセージが Rational を得る書き方（`2r ** -1`）を教えます。負の底に分数の指数（`(-8) ** 0.5`）は `Math::DomainError` です（Ruby は Complex を返す）。`**` は単項マイナスより強く結合するので Ruby と同じく `-2 ** 2` は -4、右結合です（`2 ** 3 ** 2` は 512）。`pow` も参照。

```ruby
p(2 ** 10)                   # => 1024
p(Integer.**(2, 0))          # => 1
p(2 ** 0.5)                  # => 1.4142135623730951
p(2 ** 2r)                   # => (4/1)
p(2 ** (1r/2))               # => 1.4142135623730951
p(-2 ** 2)                   # => -4
x = 2 ** 2r
case x
in Rational then p(Rational.numerator(x))   # => 4
in Float then p(x)
end
```

```ruby error
p(2 ** -1)                   # !> ArgumentError: Arithmetic.**: Integer ** negative Integer (2 ** -1) is an error; for a Rational, write 2r ** -1
```

```ruby error
p((-8) ** 0.5)               # !> Math::DomainError: Arithmetic.**: -8 ** 0.5 is not a real number (a negative base with a fractional exponent)
```

```ruby error
p(Rational.numerator(2 ** 2r))   # !> Rational.numerator: argument 1 must be Rational, but can be Float
```

## ==, !=

`Integer.==(x, Any)`

`Integer.!=(x, Any)`

等価（`!=` はその否定）。数は型をまたいで比べられます: `1 == 1.0`、`1 == 1r`、`1 == Complex(1, 0)` は true。Ruby と同じく、別の型の値とは決して等しくありません（`1 == "1"` は false、`1 == nil` は false）。関数形 `Integer.==(x, y)` も、右側が他のどんな型でも同じく false（`!=` は true）を返し、エラーにはなりません。

```ruby
p(1 == 1)                    # => true
p(1 == 1.0)                  # => true
p(1 != 1)                    # => false
p(1 == "1")                  # => false
p(1 == nil)                  # => false
p(Integer.==(1, nil))        # => false
p(Integer.==(1, "a"))        # => false
p(Integer.!=(1, "a"))        # => true
```

## <, <=, >, >=

`Integer.<(x, Any)`

`Integer.<=(x, Any)`

`Integer.>(x, Any)`

`Integer.>=(x, Any)`

順序。右側は Integer、Float、Rational です。Complex に順序は無く、String や nil は `type` の問題（`Comparable.<: the operands are (Integer, String) ...`）。結果は true か false。

```ruby
p(1 < 2)                     # => true
p(1 <= 1)                    # => true
p(2 >= 3)                    # => false
p(1 < 1.5)                   # => true
p(Integer.<(1, 2r))          # => true
```

```ruby error
p(1 < "a")                   # !> Comparable.<: the operands are (Integer, String), which the left operand's type does not support
```

## <=>

`Integer.<=>(x, Any)`

左が右（Integer、Float、Rational）より小さければ -1、等しければ 0、大きければ 1。数同士では nil にならないので、検査器は結果を Integer とします。それ以外の右側は `type` の問題です。

```ruby
p(1 <=> 2)                   # => -1
p(2 <=> 1)                   # => 1
p(1 <=> 1)                   # => 0
p(Integer.<=>(1, 1.5))       # => -1
```

## &, |, ^

`Integer.&(x, Any)`

`Integer.|(x, Any)`

`Integer.^(x, Any)`

2 の補数のビットに対するビット積・ビット和・排他的論理和（Ruby と同じ）。負の数は上位に無限に 1 が並んでいるものとして振る舞います。両側とも Integer でなければならず、右側の Float は `type` の問題（`Bitwise.&: the operands are (Integer, Float) ...`）。単項の補数 `~x` は `Integer.~` で、演算子としてだけ書けます。

```ruby
p(6 & 3)                     # => 2
p(6 | 3)                     # => 7
p(6 ^ 3)                     # => 5
p(~5)                        # => -6
p(Integer.&(6, 3))           # => 2
```

```ruby error
p(6 & 1.5)                   # !> Bitwise.&: the operands are (Integer, Float), which the left operand's type does not support
```

## <<, >>

`Integer.<<(x, Any)`

`Integer.>>(x, Any)`

Integer のビット数だけ左・右へシフトします（Ruby と同じ）: `x << n` は `x * 2**n`（正確で、必要なだけ伸びる）、`x >> n` は床へ丸めます（`-1 >> 1` は -1）。負のビット数は逆方向へシフトします（`1 << -1` は 0）。右側は Integer でなければなりません。

```ruby
p(1 << 4)                    # => 16
p(256 >> 4)                  # => 16
p(-1 >> 1)                   # => -1
p(1 << 100 == 2 ** 100)      # => true
```

## bit_length

`Integer.bit_length(x)`

2 の補数で数を表すのに要るビット数（符号ビットを除く。Ruby と同じ）: 255 は 8、256 は 9、0 と -1 は 0、-256 は 8。

```ruby
p(Integer.bit_length(255))   # => 8
p(Integer.bit_length(256))   # => 9
p(Integer.bit_length(0))     # => 0
p(Integer.bit_length(-1))    # => 0
```

## allbits?, anybits?, nobits?

`Integer.allbits?(x, Integer)`

`Integer.anybits?(x, Integer)`

`Integer.nobits?(x, Integer)`

マスクで立っているビットが数の中ですべて立っているか、どれかが立っているか、どれも立っていないか: `x & mask == mask`、`x & mask != 0`、`x & mask == 0`。

```ruby
p(Integer.allbits?(6, 2))    # => true
p(Integer.allbits?(6, 3))    # => false
p(Integer.anybits?(6, 3))    # => true
p(Integer.nobits?(6, 1))     # => true
```

## div, modulo, remainder

`Integer.div(x, Integer|Float|Rational)`

`Integer.modulo(x, Integer)`

`Integer.remainder(x, Integer)`

`div` は床へ丸めた商で、除数が Float や Rational でも **Integer** です（`Integer.div(7, 2.0)` は 3。`7 / 2.0` は 3.5）。`modulo` は `%` と同じで、除数の符号を取る余り。`remainder` は Ruby と同じく**被除数**の符号を取る余りです（`Integer.remainder(-7, 3)` は -1。`-7 % 3` は 2）。除数 0（`0.0` も）は `ZeroDivisionError`。

```ruby
p(Integer.div(-7, 2))        # => -4
p(Integer.div(7, 2.0))       # => 3
p(Integer.modulo(-7, 3))     # => 2
p(Integer.remainder(-7, 3))  # => -1
p(Integer.remainder(7, -3))  # => 1
```

```ruby error
p(Integer.modulo(7, 0))      # !> ZeroDivisionError: Integer.modulo: divided by 0
```

## divmod

`Integer.divmod(x, Integer)`

床へ丸めた除算の Tuple `[商, 余り]`。`q * b + r == a` が成り立ち、`r` は除数の符号を取ります。除数 0 は `ZeroDivisionError`。Ruby と違い除数は Integer でなければなりません（`Float.divmod` は Float の主語を取ります）。

```ruby
p(Integer.divmod(7, 2))      # => [3, 1]
p(Integer.divmod(-7, 2))     # => [-4, 1]
q, r = Integer.divmod(17, 5)
p([q, r])                    # => [3, 2]
```

```ruby error
p(Integer.divmod(7, 0))      # !> ZeroDivisionError: Integer.divmod: divided by 0
```

## ceildiv

`Integer.ceildiv(x, Integer)`

正の無限大の方向へ丸めた商（Ruby の `ceildiv`）: `Integer.ceildiv(7, 2)` は 4、`Integer.ceildiv(-7, 2)` は -3。除数 0 は `ZeroDivisionError`。

```ruby
p(Integer.ceildiv(7, 2))     # => 4
p(Integer.ceildiv(-7, 2))    # => -3
p(Integer.ceildiv(6, 2))     # => 3
```

## fdiv

`Integer.fdiv(x, Integer)`

Float としての商、`Integer.to_f(a) / b`。除数 0 は例外にならず、Ruby と同じく `Infinity`、`-Infinity`、`NaN`（`0 / 0`）になります。Ruby と違い除数は Integer でなければなりません。

```ruby
p(Integer.fdiv(7, 2))        # => 3.5
p(Integer.fdiv(1, 3))        # => 0.3333333333333333
p(Integer.fdiv(1, 0))        # => Infinity
```

## pow

`Integer.pow(x, Integer, [Integer])`

`Integer.pow(a, b)` は Integer の指数の `a ** b` で、負の指数は同じ `ArgumentError`。`Integer.pow(a, b, m)` は `a ** b` を `m` で割った余りで、Ruby と同じく巨大なべきを作らずに計算します。結果は `m` の符号を取ります。法付きのとき、負の指数は `RangeError`（メッセージは Ruby のもので、指数を 1 番目の引数と数えます）、法 0 は `ZeroDivisionError` で、どちらも `rescue` できます。

```ruby
p(Integer.pow(2, 10))        # => 1024
p(Integer.pow(2, 10, 1000))  # => 24
p(Integer.pow(3, 100, 7))    # => 4
p(Integer.pow(2, 10, -7))    # => -5
begin
  Integer.pow(2, 3, 0)
rescue ZeroDivisionError => e
  p(Exception.message(e))    # => "divided by 0"
end
```

```ruby error
p(Integer.pow(2, -1))        # !> ArgumentError: Integer.pow: Integer ** negative Integer (2 ** -1) is an error; for a Rational, write 2r ** -1
```

```ruby error
p(Integer.pow(2, -1, 7))     # !> RangeError: Integer.pow: Integer#pow() 1st argument cannot be negative when 2nd argument specified
```

## gcd, lcm

`Integer.gcd(x, Integer)`

`Integer.lcm(x, Integer)`

最大公約数と最小公倍数。Ruby と同じく常に非負です。`gcd(0, n)` は `|n|`、`gcd(0, 0)` は 0、`lcm(0, n)` は 0。

```ruby
p(Integer.gcd(12, 18))       # => 6
p(Integer.gcd(-12, 18))      # => 6
p(Integer.gcd(0, 0))         # => 0
p(Integer.lcm(4, 6))         # => 12
p(Integer.lcm(0, 6))         # => 0
```

## gcdlcm

`Integer.gcdlcm(x, Integer)`

Tuple `[gcd, lcm]`。

```ruby
g, l = Integer.gcdlcm(4, 6)
p([g, l])                    # => [2, 12]
```

## sqrt

`Integer.sqrt(x)`

整数平方根: 2 乗が数を超えない最大の Integer（Ruby の `Integer.sqrt`）。どんな大きさでも正確で、`Math.sqrt` は Float を返すところです。負の数は `Math::DomainError`（メッセージは Ruby のもの）を投げ、`rescue` できます。

```ruby
p(Integer.sqrt(16))          # => 4
p(Integer.sqrt(17))          # => 4
p(Integer.sqrt(10 ** 20))    # => 10000000000
```

```ruby error
p(Integer.sqrt(-1))          # !> Math::DomainError: Integer.sqrt: Numerical argument is out of domain - "isqrt"
```

## abs, magnitude

`Integer.abs(x)`

`Integer.magnitude(x)`

絶対値（Integer）。`Arithmetic.abs(x)` はどの実数にも同じことをします。

```ruby
p(Integer.abs(-5))           # => 5
p(Integer.magnitude(5))      # => 5
```

## even?, odd?

`Integer.even?(x)`

`Integer.odd?(x)`

偶数か奇数か。0 は偶数、-3 は奇数です。

```ruby
p(Integer.even?(4))          # => true
p(Integer.even?(-3))         # => false
p(Integer.odd?(-3))          # => true
```

## zero?, positive?, negative?

`Integer.zero?(x)`

`Integer.positive?(x)`

`Integer.negative?(x)`

数が 0 か、0 より大きいか、0 より小さいか。0 は正でも負でもありません。`Arithmetic.zero?(x)` はどの実数も取ります。

```ruby
p(Integer.zero?(0))          # => true
p(Integer.positive?(0))      # => false
p(Integer.negative?(-1))     # => true
```

## succ, next

`Integer.succ(x)`

`Integer.next(x)`

数に 1 を足したもの。

```ruby
p(Integer.succ(5))           # => 6
p(Integer.next(-1))          # => 0
```

## pred

`Integer.pred(x)`

数から 1 を引いたもの。

```ruby
p(Integer.pred(5))           # => 4
p(Integer.pred(0))           # => -1
```

## times

`Integer.times(x) { }`

0, 1, ..., n-1 をブロックへ渡し、n（主語）を返します（Ruby と同じ）。n が 0 以下ならブロックは呼ばれません。ブロックは**必須**です（ブロック無しの Ruby の `times` は Enumerator を返す）。ブロックの引数は 1 つ。`break v` はループを終えて `v` を結果にし、`next` は次の回へ進み、関数の中の `return` は関数から戻ります。

```ruby
n = Integer.times(3) { |i| puts(i) }   # => 0
                                       # => 1
                                       # => 2
p(n)                                   # => 3
sum = 0
Integer.times(4) { |i| sum += i }
p(sum)                                 # => 6
p(Integer.times(0) { |i| puts(i) })    # => 0
p(Integer.times(3) { |i| break i * 10 if i == 1 })   # => 10
```

```ruby error
Integer.times(3)                       # !> Integer.times requires a block
```

## upto

`Integer.upto(x, Integer) { }`

a, a+1, ..., b をブロックへ渡し、a（主語）を返します（Ruby の `a.upto(b)`）。a が b より大きければブロックは呼ばれません。ブロックは必須です。

```ruby
p(Integer.upto(1, 3) { |i| puts(i) })  # => 1
                                       # => 2
                                       # => 3
                                       # => 1
p(Integer.upto(3, 1) { |i| puts(i) })  # => 3
```

## downto

`Integer.downto(x, Integer) { }`

a, a-1, ..., b をブロックへ渡し、a を返します（Ruby の `a.downto(b)`）。a が b より小さければブロックは呼ばれません。ブロックは必須です。

```ruby
p(Integer.downto(3, 1) { |i| puts(i) })  # => 3
                                         # => 2
                                         # => 1
                                         # => 3
```

## step

`Integer.step(x, Integer, Integer) { }`

`Integer.step(a, limit, step)` は a, a+step, a+2·step, ... を、値が（step の向きで）limit を越えない間ブロックへ渡し、a を返します（Ruby の `a.step(limit, step)`）。limit と step はどちらも必須の Integer です（Ruby の Float の刻みやキーワード形はありません）。刻み 0 は `ArgumentError`。負の刻みは下ります。

```ruby
p(Integer.step(1, 10, 3) { |i| puts(i) })   # => 1
                                            # => 4
                                            # => 7
                                            # => 10
                                            # => 1
p(Integer.step(10, 1, -3) { |i| print(i, " ") })   # => 10 7 4 1 10
```

```ruby error
Integer.step(1, 10, 0) { |i| puts(i) }      # !> ArgumentError: Integer.step: step can't be 0
```

## clamp

`Integer.clamp(x, Integer, Integer)`

数を区間に収めたもの: `lo` より下なら `lo`、`hi` より上なら `hi`、それ以外はそのまま。Ruby と違い Range の形（`clamp(1..10)`）はありません。`lo` が `hi` より大きいと `ArgumentError`（`min argument must be less than or equal to max argument`）です。

```ruby
p(Integer.clamp(5, 1, 10))   # => 5
p(Integer.clamp(-5, 1, 10))  # => 1
p(Integer.clamp(50, 1, 10))  # => 10
```

```ruby error
p(Integer.clamp(5, 10, 1))   # !> ArgumentError: Integer.clamp: min argument must be less than or equal to max argument
```

## between?

`Integer.between?(x, Integer, Integer)`

`lo <= x <= hi` なら true。両端を含みます。`lo` が `hi` より大きければ false です。

```ruby
p(Integer.between?(5, 1, 10))   # => true
p(Integer.between?(1, 1, 10))   # => true
p(Integer.between?(0, 1, 10))   # => false
```

## round

`Integer.round(x, [Integer])`

桁数無しなら数そのもの。負の桁数 -d なら 10^d の倍数へ丸め、半分はゼロから遠い側へ寄せます（Ruby と同じ。`Integer.round(1250, -2)` は 1300、`Integer.round(-1250, -2)` は -1300）。正の桁数は数を変えません。結果は常に Integer。主語は Integer だけで、Float は `type` の問題になり、どの実数も丸める `Arithmetic.round(x)` をヒントが示します。

```ruby
p(Integer.round(1234))       # => 1234
p(Integer.round(1234, -2))   # => 1200
p(Integer.round(1250, -2))   # => 1300
p(Integer.round(-1250, -2))  # => -1300
p(Integer.round(1234, 2))    # => 1234
```

```ruby error
p(Integer.round(2.5))        # !> Integer.round: argument 1 must be Integer, but is Float
```

## floor, ceil

`Integer.floor(x, [Integer])`

`Integer.ceil(x, [Integer])`

桁数無しなら数そのもの。負の桁数 -d なら 10^d の倍数へ、`floor` は下（負の無限大の方向）へ、`ceil` は上（正の無限大の方向）へ丸めます（Ruby と同じ）。常に Integer。Float には `Arithmetic.floor` か `Float.floor` を使います。

```ruby
p(Integer.floor(1234, -2))   # => 1200
p(Integer.floor(-1234, -2))  # => -1300
p(Integer.ceil(1234, -2))    # => 1300
p(Integer.ceil(-1234, -2))   # => -1200
p(Integer.floor(5))          # => 5
```

## truncate

`Integer.truncate(x, [Integer])`

桁数無しなら数そのもの。負の桁数 -d なら 10^d の倍数へゼロの方向へ丸めます。常に Integer。

```ruby
p(Integer.truncate(1234, -2))    # => 1200
p(Integer.truncate(-1234, -2))   # => -1200
```

## digits

`Integer.digits(x)`

10 進の各桁を下の桁から並べた新しい Array（基数無しの Ruby の `digits`。`Integer.digits(1234)` は `[4, 3, 2, 1]`、0 は `[0]`）。型付きの `Integer[]` で、別の型の値を push すると `type` の問題です。負の数は `Math::DomainError`（`out of domain`）を投げます。Ruby と違い基数の引数は無く、`to_s(n, base)` と `String.chars` を使います。

```ruby
p(Integer.digits(1234))      # => [4, 3, 2, 1]
p(Integer.digits(0))         # => [0]
p(Array.sum(Integer.digits(999)))   # => 27
d = Integer.digits(12)
Array.push(d, 9)
p(d)                         # => [2, 1, 9]
```

```ruby error
Array.push(Integer.digits(12), "x")   # !> Array.push: an element must be Integer, but is String
```

```ruby error
p(Integer.digits(-1))        # !> Math::DomainError: Integer.digits: out of domain
```

## to_s

`Integer.to_s(x, [Integer])`

数を指定の基数（2 から 36。省略時 10）で書いた String。9 を超える桁は小文字で、負の数には先頭に `-` が付きます。2..36 の外の基数は `ArgumentError`（`invalid radix 1`）。`String.to_i(s, base)` が読み戻します。

```ruby
p(Integer.to_s(255))         # => "255"
p(Integer.to_s(255, 2))      # => "11111111"
p(Integer.to_s(-255, 16))    # => "-ff"
p(Integer.to_s(35, 36))      # => "z"
```

```ruby error
p(Integer.to_s(255, 37))     # !> ArgumentError: Integer.to_s: invalid radix 37
```

## to_f

`Integer.to_f(x)`

数を Float にしたもの（正確に表せない大きな数は最も近いもの）。`Arithmetic.to_f(x)` はどの実数も取ります。

```ruby
p(Integer.to_f(3))           # => 3.0
```

## to_i, to_int

`Integer.to_i(x)`

`Integer.to_int(x)`

数そのもの。どの実数向けにも書かれたコードのためにあり、`Arithmetic.to_i(x)` は Float や Rational を Integer へ切り捨てます。String の変換 `Integer(s)` は Kernel のもので、この操作ではありません。

```ruby
p(Integer.to_i(3))           # => 3
p(Integer.to_int(-3))        # => -3
```

## to_r

`Integer.to_r(x)`

数を分母 1 の Rational にしたもの。

```ruby
p(Integer.to_r(3))           # => (3/1)
```

## rationalize

`Integer.rationalize(x, [Integer|Float|Rational])`

数を Rational にしたもの（`to_r` と同じ）。省略可能な許容誤差は `Float.rationalize` との対称のために受け取るだけで、Integer では結果を変えません。

```ruby
p(Integer.rationalize(3))        # => (3/1)
p(Integer.rationalize(3, 0.5))   # => (3/1)
```

## numerator, denominator

`Integer.numerator(x)`

`Integer.denominator(x)`

分数と見たとき、数は自分自身を分子、1 を分母に持ちます。

```ruby
p(Integer.numerator(6))      # => 6
p(Integer.denominator(6))    # => 1
```

## integer?

`Integer.integer?(x)`

Integer では常に true（Ruby の `Numeric#integer?`）。別の型かもしれない値の型を調べるには `x in Integer` を使います。

```ruby
p(Integer.integer?(6))       # => true
```

## size

`Integer.size(x)`

機械表現のバイト数（Ruby と同じ）: 機械語 1 語に収まる数は 8、それより大きい数はもっと多く。有効なビット数には `bit_length` を使います。

```ruby
p(Integer.size(1))           # => 8
p(Integer.size(2 ** 100))    # => 13
```

## chr

`Integer.chr(x)`

そのバイト値を持つ 1 文字の String。数は 0 から 255 でなければならず、外れると `RangeError`（`256 out of char range`）を投げます（`rescue` できます）。エンコーディング無しの Ruby の `chr` と同じく、0 から 127 は ASCII の String、128 から 255 は 1 バイトのバイナリ String で、UTF-8 の文字列とつなぐと `EncodingError` を投げます。`String.ord` が逆の操作です。255 を超えるコードポイントの String は別の方法で作ります（`format("%c", n)`）。

```ruby
p(Integer.chr(65))           # => "A"
puts(Integer.chr(97))        # => a
p(Integer.chr(10))           # => "\n"
p(String.ord(Integer.chr(200)))   # => 200
begin
  Integer.chr(200) + "é"
rescue EncodingError => e
  p(Exception.message(e))    # => "incompatible character encodings: BINARY (ASCII-8BIT) and UTF-8"
end
```

```ruby error
p(Integer.chr(256))          # !> RangeError: Integer.chr: 256 out of char range
```

## ord

`Integer.ord(x)`

数そのもの（Ruby の `Integer#ord`）。String の先頭文字のコードポイントを返す `String.ord` の対になるものです。

```ruby
p(Integer.ord(65))           # => 65
p(String.ord("A"))           # => 65
```
