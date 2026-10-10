# Arithmetic

Arithmetic は算術演算子 `+`、`-`、`*`、`/`、`%`、`**` と単項の `-x`、`+x` が属するモジュールです。`a + b` は `Arithmetic.+(a, b)` の略記で、左側の値の型（Integer、Float、Rational、Complex、String、Time、Set、または `include Arithmetic` したクラス）の `+` に振り分けられます（[演算子と添字](../05-operators.md)、[プログラムの構造](../02-program.md)）。

この章に挙げる 8 つの操作は、演算子ではなく、**どの実数（Integer、Float、Rational）にも使える丸めと変換**です。Sake の操作は普通 `Float.round(f)` のように型を名乗りますが、値の型が `Integer | Float` のように定まらないとき（`Array.sum` の結果、JSON から読んだ数など）に、Ruby の `x.round` と同じく値の型を見て振り分けるのがこれらです。結果の型は引数の型に従います: 桁数なしの `round`・`floor`・`ceil`・`truncate` と `to_i` は Integer、桁数付きの丸めと `abs` は引数と同じ型（引数の型が和なら結果も和）、`to_f` は Float、`zero?` は true/false。検査器は引数の各型についてこの規則を当てます。

引数が Complex や String なら静的に `type` の問題です（`argument 1 must be Integer|Float|Rational, but is Complex`）。NaN・Infinity を Integer にしようとすると `FloatDomainError` を投げ、`rescue FloatDomainError => e` で受けられます。

## round, floor, ceil, truncate

`Arithmetic.round(Integer|Float|Rational, [Integer], [half: Symbol])`

`Arithmetic.floor(Integer|Float|Rational, [Integer])`

`Arithmetic.ceil(Integer|Float|Rational, [Integer])`

`Arithmetic.truncate(Integer|Float|Rational, [Integer])`

Ruby の `x.round(n)`・`x.floor(n)`・`x.ceil(n)`・`x.truncate(n)` です（結果の型に 1 つ違いがあります）。`round` は最も近い値へ（.5 は既定では 0 から遠い方へ）、`floor` は下へ、`ceil` は上へ、`truncate` は 0 に近い方へ丸めます。

- 桁数 `n` を省くと結果は **Integer** です（引数が Integer でもそのまま Integer）。
- 桁数を付けると結果は **引数と同じ型**: Float には Float、Rational には Rational、Integer には Integer（正の桁数では値はそのまま）。負の桁数は 10 の冪に丸めます。Ruby と違い、0 以下の桁数でもこの規則どおりです: `Arithmetic.round(1234.5, -2)` は `1200.0`（Ruby の `1234.5.round(-2)` は Integer の 1200）、`Arithmetic.round(5r/2, -1)` は `(0/1)`。つまり結果の型は引数の型と桁数の有無だけで決まります。
- `round` は `Float.round` と同じキーワード `half:` を、どの型の引数にも取ります: `:up`（既定。0 から遠い方へ）、`:even`（偶数側へ）、`:down`（0 に近い方へ）。他の Symbol は `ArgumentError`（`invalid rounding mode: foo`）です。`floor`・`ceil`・`truncate` は `half:` を取りません（静的なエラー）。
- NaN・Infinity は桁数なしなら `FloatDomainError`（`rescue` できます）、桁数付きならそのまま返します。

```ruby
p(Arithmetic.round(1.5))           # => 2
p(Arithmetic.round(7r/2))          # => 4
p(Arithmetic.round(3))             # => 3
p(Arithmetic.round(1.2345, 2))     # => 1.23
p(Arithmetic.round(7r/3, 2))       # => (233/100)
p(Arithmetic.round(1234, -2))      # => 1200
p(Arithmetic.round(1234.5, -2))    # => 1200.0
p(Arithmetic.round(5r/2, -1))      # => (0/1)
p(Arithmetic.round(2.5, half: :even))      # => 2
p(Arithmetic.round(5r/2, half: :even))     # => 2
p(Arithmetic.round(25, -1, half: :even))   # => 20
p(Arithmetic.round(1.25, 1, half: :even))  # => 1.2
p(Arithmetic.floor(-1.5))          # => -2
p(Arithmetic.floor(1.567, 1))      # => 1.5
p(Arithmetic.floor(1234.5, -2))    # => 1200.0
p(Arithmetic.ceil(7r/2))           # => 4
p(Arithmetic.ceil(1234, -2))       # => 1300
p(Arithmetic.truncate(-7r/2))      # => -3
p(Arithmetic.truncate(1.999, 2))   # => 1.99
p(Arithmetic.round(Float.NAN, 2))  # => NaN
begin
  Arithmetic.round(Float.NAN)
rescue FloatDomainError => e
  p(Exception.message(e))          # => "NaN"
end
```

型が定まらない値にも一つの操作で使えます:

```ruby
def tenth(x)
  Arithmetic.round(x, 1)
end
p(tenth(1.25))                     # => 1.3
p(tenth(3))                        # => 3
p(tenth(1r/3))                     # => (3/10)
```

```ruby error
p(Arithmetic.round("1.5"))         # !> Arithmetic.round: argument 1 must be Integer|Float|Rational, but is String
```

```ruby error
p(Arithmetic.round(2.5, half: :foo))   # !> ArgumentError: Arithmetic.round: invalid rounding mode: foo
```

```ruby error
p(Arithmetic.round(Float.INFINITY))    # !> FloatDomainError: Arithmetic.round: Infinity
```

## abs

`Arithmetic.abs(Integer|Float|Rational)`

絶対値。結果は引数と同じ型です（Ruby の `x.abs`）。

```ruby
p(Arithmetic.abs(-3))              # => 3
p(Arithmetic.abs(-1.5))            # => 1.5
p(Arithmetic.abs(-1r/3))           # => (1/3)
```

```ruby error
p(Arithmetic.abs(Complex(3, 4)))   # !> Arithmetic.abs: argument 1 must be Integer|Float|Rational, but is Complex
```

## to_i, to_f

`Arithmetic.to_i(Integer|Float|Rational)`

`Arithmetic.to_f(Integer|Float|Rational)`

`to_i` は 0 に近い方へ切り捨てた Integer、`to_f` は最も近い Float を返します。`Integer | Float` の値を Float に揃えるときの `to_f` が代表的な使い方です（検査器は `Float.floor(x)` に `Integer | Float` を渡すと、`Arithmetic.floor(x)` を使うよう助言します）。`to_i` の NaN・Infinity は `FloatDomainError` で、`rescue` できます。

```ruby
p(Arithmetic.to_i(1.9))            # => 1
p(Arithmetic.to_i(7r/2))           # => 3
p(Arithmetic.to_i(7))              # => 7
p(Arithmetic.to_f(3))              # => 3.0
p(Arithmetic.to_f(1r/4))           # => 0.25
p(Arithmetic.to_f(1.5))            # => 1.5
```

```ruby error
p(Arithmetic.to_i(Float.NAN))      # !> FloatDomainError: Arithmetic.to_i: NaN
```

## zero?

`Arithmetic.zero?(Integer|Float|Rational)`

`x == 0` のとき true（`0.0` と `-0.0` も true）。

```ruby
p(Arithmetic.zero?(0))             # => true
p(Arithmetic.zero?(0.0))           # => true
p(Arithmetic.zero?(0r))            # => true
p(Arithmetic.zero?(1))             # => false
```
