# Complex

A Complex is a complex number with a real and an imaginary part, each an Integer, a Float or a Rational. The literals are Ruby's imaginary units `2i`, `3.5i` and expressions with them such as `1 + 2i`; `Complex(1, 2)` (and `Complex(1.5)` without an imaginary part) is a Kernel operation whose arguments are real numbers only ([Values and types](../03-values.md)). `p` shows a Complex as `(1+2i)`.

The operators on Complexes are `+`, `-`, `*`, `/`, `**` and `==`, `!=`. A Complex has no order, so there is no `<` and the like, and no `%` (both are `type` problems statically). The right operand may be an Integer, a Float, a Rational or a Complex, and the result is always a Complex; with an Integer, a Float or a Rational on the left and a Complex on the right the result is a Complex as well ([Operators and indexing](../05-operators.md)). The entries `Complex.+(x, y)` and so on below are the function forms of those operators.

The parts keep their types inside the value: `Complex(1, 2) / 2` is `((1/2)+1i)`, with a Rational real part (as in Ruby). That is why `real` and `imag` have the result type `Integer | Float | Rational`; to use a part as an Integer, narrow it with `case`/`in`. The differences from Ruby: a part cannot be a Complex, and the function form `Complex.==(x, y)` accepts only numbers.

## Complex[]

`Complex[*Any]`

Makes an **Array of Complexes** (not a Complex). Every element must be a Complex, and every write (`Array.push`, ...) is checked. A real number is not converted: it is a `type` problem statically and a `TypeError` at run time. The empty Array of Complexes is `Complex[]`.

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

The function forms of `x + y` and the others with a Complex on the left. The right operand `y` is an Integer, a Float, a Rational or a Complex, and the result is a Complex. Any other type is a `type` problem statically and a `TypeError` at run time. `/` computes exactly according to the parts' types, so Integer parts become Rationals. Dividing a Complex whose parts are all exact (Integer, Rational) by 0 or by `Complex(0, 0)` is a `ZeroDivisionError`; so is dividing one with Float parts by the Integer 0, while dividing by `0.0` follows the Float rules and gives `Infinity` parts (as in Ruby). `**` is exact for an integral power and gives Float parts otherwise. There is no `%` on Complex.

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

The function form of `x == y`. True when the real parts and the imaginary parts are each `==`; `Complex(1, 0) == 1` and `Complex(1.0, 0) == 1` are true. The operator `==` accepts any two values and is false when the types differ (`Complex(1, 2) == "x"` is false), but the function form `Complex.==(x, y)` raises a `TypeError` at run time unless the right operand is a number (nil included); the checker does not catch this statically.

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

The real and the imaginary part. The type is that of the part as constructed (`Integer | Float | Rational`). `imag` and `imaginary` are the same operation.

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

The Tuple `[re, im]` of the two parts (each position `Integer | Float | Rational`). Multiple assignment takes both. The two are the same operation.

```ruby
p(Complex.rect(Complex(1, 2)))             # => [1, 2]
p(Complex.rectangular(Complex(1.5, 2r)))   # => [1.5, (2/1)]
re, im = Complex.rectangular(Complex(1, 2))
p(re + im)                                 # => 3
```

## polar

`Complex.polar(x)`

The polar form as the Tuple `[r, θ]`: `r` is the absolute value (as `abs`, `Integer | Float`) and `θ` the argument (as `arg`, a Float; `0.0` or `π` on the real axis).

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

The absolute value `sqrt(re² + im²)`. Usually a Float, but as in Ruby, when one part is an exact 0 the absolute value of the other part is returned as it is, so `Complex(3, 0)` gives the Integer `3`. The type is `Integer | Float` (a Rational part gives a Rational, which the checker does not see). The two are the same operation.

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

The square of the absolute value, `re² + im²`. No square root is taken, so it is exact, and the type follows the parts: `Integer | Float | Rational`.

```ruby
p(Complex.abs2(Complex(3, 4)))         # => 25
p(Complex.abs2(Complex(1.5, 0)))       # => 2.25
p(Complex.abs2(Complex(1r/2, 1r/2)))   # => (1/2)
```

## arg, angle, phase

`Complex.arg(x)`

`Complex.angle(x)`

`Complex.phase(x)`

The argument (a Float from `-π` to `π`), that is, `Math.atan2(im, re)`: `0.0` for `Complex(0, 0)`, `π` on the negative real axis. The three are the same operation.

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

The complex conjugate (the Complex with the sign of the imaginary part flipped). The two are the same operation.

```ruby
p(Complex.conj(Complex(1, 2)))         # => (1-2i)
p(Complex.conjugate(Complex(1.5, -2))) # => (1.5+2i)
p(Complex.conjugate(Complex(3, 0)))    # => (3+0i)
```

## real?

`Complex.real?(x)`

Always **false** (as Ruby's `Complex#real?`: a value of type Complex is not a real number even when its imaginary part is 0). To ask whether the value is real, use `Complex.imag(x) == 0`.

```ruby
p(Complex.real?(Complex(1, 2)))    # => false
p(Complex.real?(Complex(1, 0)))    # => false
p(Complex.imag(Complex(1, 0)) == 0)  # => true
```

## finite?, infinite?

`Complex.finite?(x)`

`Complex.infinite?(x)`

`finite?` is true when both parts are finite (neither a NaN nor infinite). `infinite?` returns, as Ruby's does, `1` when either part is infinite and **nil** otherwise (a NaN included), so its type is `Integer | nil`. It is usually used as a condition; to use the value in arithmetic, check it for nil first (`--strict`'s `nil` item reports the unchecked use).

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

Divides by the real number `y` after turning the parts into Floats: a Complex with Float parts. `y` cannot be a Complex (a `type` problem statically; to divide by a Complex use `/` or `quo`). Dividing by zero gives `Infinity` parts, without an exception.

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

The division `x / y` (a Complex), the same as `/`: Integer parts become Rationals. Dividing by an exact zero is a `ZeroDivisionError`.

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

`denominator` is the least common multiple of the parts' denominators (an Integer); `numerator` is `x * denominator`, a Complex with integral parts. An Integer part has denominator 1.

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

Convert the real part to an Integer, a Float or a Rational (`rationalize` is the real part's `rationalize`, with a Rational tolerance `eps`), but only when the imaginary part is an exact 0 (the Integer `0` or `0r`). When it is not 0, or is `0.0` (the Float zero), the result is Ruby's `RangeError` (`can't convert 1+2i into Float`).

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

Returns x itself (a real number becomes a Complex through Kernel's `Complex(x)`).

```ruby
p(Complex.to_c(Complex(3, 4)))     # => (3+4i)
```

## to_s

`Complex.to_s(x)`

The String `"re+imi"` (as Ruby's): `p`'s `(3+4i)` without the parentheses, and a Rational part is written without its parentheses too, `1/2+3i`.

```ruby
p(Complex.to_s(Complex(3, 4)))         # => "3+4i"
p(Complex.to_s(Complex(-1, -1)))       # => "-1-1i"
p(Complex.to_s(Complex(0.5, 2)))       # => "0.5+2i"
p(Complex.to_s(Complex(1r/2, 3)))      # => "1/2+3i"
```
