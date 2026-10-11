# Math

Math is the collection of elementary functions of Ruby's `Math` module. It is a namespace, not a type: there are no Math values. Every function takes a real number (Integer, Float, Rational) and the result is always a **Float** (`Math.sqrt(4)` is `2.0`; a Complex is not accepted). Only the two-argument functions `atan2` and `hypot`, and the exponent of `ldexp`, do not take a Rational: they take an Integer or a Float.

Ruby's `Math::PI` and `Math::E` are the operations without arguments `Math.PI` and `Math.E` in Sake (Sake has no value constants); `Math::PI` is also read in Ruby's form, as the same operation. `Math.log(x, base)` takes a base as Ruby's does (an Integer or a Float).

An argument outside the domain (`sqrt(-1)`, `log(-1)`, `acos(2)`, ...) raises `Math::DomainError`, as in Ruby, which `rescue Math::DomainError => e` catches ([Exceptions and errors](../08-exceptions.md)). A NaN argument gives a NaN, and infinities follow IEEE (`log(0)` is `-Infinity`, `exp(1000)` is `Infinity`; no exception).

## PI, E

`Math.PI()`

`Math.E()`

The circle constant π and the base of natural logarithms e (Floats). Written `Math.PI` or `Math.PI()`.

```ruby
p(Math.PI)                         # => 3.141592653589793
p(Math.E)                          # => 2.718281828459045
p(Math.cos(Math.PI))               # => -1.0
p(Math.exp(1) == Math.E)           # => true
```

## sqrt, cbrt

`Math.sqrt(Integer|Float|Rational)`

`Math.cbrt(Integer|Float|Rational)`

The square root and the cube root (Floats). A negative argument to `sqrt` is a `Math::DomainError`. `cbrt` accepts negative numbers (`cbrt(-8)` is `-2.0`). For the exact integer square root use `Integer.sqrt(n)`.

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

The trigonometric functions; the argument is in radians. The result is a Float, so a value such as `sin(π)` is not an exact 0 but carries rounding error.

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

The inverse trigonometric functions (Floats in radians). The argument of `asin` and `acos` must lie between -1 and 1; outside it is a `Math::DomainError`. `atan` takes any real number and returns a value from `-π/2` to `π/2`.

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

`atan2(y, x)`: the angle of the point `(x, y)` in radians from `-π` to `π` (a Float). Unlike `atan(y / x)` it tells the quadrants apart and works when `x` is 0. The arguments are Integers or Floats; a Rational is a `type` problem statically.

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

`sqrt(x² + y²)` (a Float), computed without overflowing in the intermediate squares. The arguments are Integers or Floats; a Rational is a `type` problem statically.

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

The hyperbolic functions (Floats).

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

The inverse hyperbolic functions (Floats). The argument of `acosh` must be at least 1 and that of `atanh` between -1 and 1; outside it is a `Math::DomainError`. `atanh(1)` is `Infinity` and `atanh(-1)` is `-Infinity`.

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

`e` to the power x (a Float). A large argument gives `Infinity`, without an exception.

```ruby
p(Math.exp(0))                     # => 1.0
p(Math.exp(2))                     # => 7.38905609893065
p(Math.exp(0.5r))                  # => 1.6487212707001282
p(Math.exp(1000))                  # => Infinity
p(Math.exp(-Float.INFINITY))       # => 0.0
```

## log, log2, log10

`Math.log(Integer|Float|Rational, [Integer|Float])`

`Math.log2(Integer|Float|Rational)`

`Math.log10(Integer|Float|Rational)`

The natural logarithm and the logarithms to base 2 and base 10 (Floats). `log(0)` is `-Infinity`; a negative argument is a `Math::DomainError`. `Math.log(x, base)` is the logarithm to the given base, as Ruby's: `Math.log(8, 2)` is `3.0`. The base is an Integer or a Float (a Rational is a `type` problem statically); a negative base is a `Math::DomainError`, and as in Ruby a base of 0 gives `-0.0` and a base of 1 `NaN`. A large Integer, even one too large for a Float, has a logarithm (as in Ruby).

```ruby
p(Math.log(Math.E))                # => 1.0
p(Math.log(1))                     # => 0.0
p(Math.log(0))                     # => -Infinity
p(Math.log2(8))                    # => 3.0
p(Math.log10(0.001))               # => -3.0
p(Math.log(8r))                    # => 2.0794415416798357
p(Math.log(8, 2))                  # => 3.0
p(Math.log(100, 10))               # => 2.0
p(Math.log(8r, 2.0))               # => 3.0
p(Math.log(10 ** 400))             # => 921.0340371976183
p(Math.log(10 ** 400, 10))         # => 400.0
```

```ruby error
p(Math.log(8, 2r))                 # !> Math.log: argument 2 must be Integer|Float, but is Rational
```

```ruby error
p(Math.log(8, -2))                 # !> Math::DomainError: Math.log: Numerical argument is out of domain - log
```

## erf, erfc

`Math.erf(Integer|Float|Rational)`

`Math.erfc(Integer|Float|Rational)`

The error function and the complementary error function `1 - erf(x)` (Floats).

```ruby
p(Math.erf(0))                     # => 0.0
p(Math.erf(1))                     # => 0.8427007929497149
p(Math.erfc(1))                    # => 0.15729920705028513
p(Math.erf(Float.INFINITY))        # => 1.0
```

## gamma, lgamma

`Math.gamma(Integer|Float|Rational)`

`Math.lgamma(Integer|Float|Rational)`

`gamma` is the gamma function Γ(x) (a Float; `(n-1)!` for a positive integer n). `gamma(0)` is `Infinity`, a negative integer and `-Infinity` are a `Math::DomainError`, and 172 and above give `Infinity`. `lgamma` returns the Tuple `[log|Γ(x)|, sign]`: the natural logarithm of the absolute value (a Float) and the sign of Γ(x) (the Integer `1` or `-1`). It works for large x where `gamma` overflows.

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

`frexp(x)` splits x into the Tuple `[fraction, exponent]` (`[Float, Integer]`), where the absolute value of `fraction` is at least 0.5 and below 1 and `x == fraction * 2 ** exponent`; 0 gives `[0.0, 0]`. `ldexp(fraction, exponent)` is the inverse: `fraction * 2 ** exponent` as a Float. The exponent must be an Integer; a Float is a `type` problem statically.

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
