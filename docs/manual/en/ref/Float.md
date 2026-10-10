# Float

A Float is an IEEE 754 double-precision floating-point number. The literals are `1.5`, `2.0`, `1e-3` ([Values and types](../03-values.md)). The conversion from a String, `Float("1.5")`, is a Kernel operation, and from an Integer it is `Integer.to_f(n)`. There is no implicit conversion of an Integer where a Float is expected: `Float[1]` and `Float.clamp(x, 1, 2)` are `type` problems statically.

The operators on Floats are `+`, `-`, `*`, `/`, `%`, `**` and `==`, `!=`, `<`, `<=`, `>`, `>=`, `<=>`. The right operand may be an Integer, a Float, a Rational or a Complex, and the result type follows the closed table: with an Integer or a Rational the result is a Float, with a Complex it is a Complex ([Operators and indexing](../05-operators.md)). The entries `Float.+(x, y)` and so on below are the function forms of those operators; since the left operand is known to be a Float, the checker is stricter about the right one.

As in Ruby, dividing by zero gives `Infinity`, `-Infinity` or `NaN` rather than an exception (`%` and `divmod` are the exceptions), and the operations that turn a NaN or an Infinity into an Integer (`to_i`, `floor`, `ceil`, `round`, `truncate`, `to_r`) raise `FloatDomainError`. Ruby's constants `Float::INFINITY` and so on are read in Sake as operations without arguments, `Float.INFINITY` (Sake has no value constants). The main differences from Ruby: `round(f, 2)` with a digit count always returns a Float, `divmod` returns a Tuple, and the checker follows the nil of `<=>` and `infinite?`.

## Float[]

`Float[*Any]`

Makes an **Array of Floats** (not a Float). It is a typed Array like `Integer[]`: every element must be a Float, and every write (`Array.push`, ...) is checked. An Integer is not converted: `Float[1.5, 2]` is a `type` problem statically and a `TypeError` at run time. The empty Array of Floats is `Float[]`.

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

Operations without arguments that return the values of Ruby's `Float::INFINITY` and so on (Sake has no value constants, so they are written `Float.INFINITY` or `Float.INFINITY()`). `INFINITY` is positive infinity (the negative one is `-Float.INFINITY`), `NAN` is not-a-number, `EPSILON` is the difference between 1.0 and the smallest Float above it, `MAX` is the largest finite value, and `MIN` is the smallest positive normalized value. All are Floats. A NaN is `==` to nothing, not even itself.

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

The function forms of `x + y` and the others with a Float on the left. The right operand `y` is an Integer, a Float, a Rational or a Complex. With an Integer or a Rational the result is a Float, with a Complex a Complex. Any other type (a String, nil) is a `type` problem statically (`the operands are (Float, String), which the left operand's type does not support`) and a `TypeError` at run time.

Division follows IEEE: `1.0 / 0` is `Infinity` and `0.0 / 0` is `NaN`, without an exception. `%` is Ruby's `Float#%` (the result takes the sign of the right operand); `7.5 % 0.0` is `NaN`, but dividing by the **Integer** 0, `7.5 % 0`, is a `ZeroDivisionError`. That exception is currently not turned into a Sake exception: it stops the program as a Ruby error and cannot be rescued. `**` is Ruby's: a negative Float raised to a non-integer power gives a Complex (the checker takes the result to be a Float).

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
```

```ruby error
p(Float.+(1.5, "a"))           # !> the operands are (Float, String), which the left operand's type does not support
```

## ==, !=

`Float.==(x, Any)`

`Float.!=(x, Any)`

The function form of `x == y`. A Float compares by value with an Integer, a Rational and a Complex: `1.0 == 1` is true. A NaN equals nothing, itself included. The operator `==` accepts any two values and is false when the types differ (`1.0 == "1"` is false), but the function form `Float.==(x, y)` raises a `TypeError` at run time unless the right operand is a number or nil (the checker does not catch this statically).

```ruby
p(Float.==(1.0, 1))            # => true
p(Float.==(1.0, 1r))           # => true
p(1.5 != 1.5)                  # => false
p(Float.!=(1.0, Float.NAN))    # => true
p(1.0 == "1")                  # => false
```

```ruby error
p(Float.==(1.0, "1"))          # !> TypeError: Float.==: no implementation for (Float, String)
```

## <, <=, >, >=

`Float.<(x, Any)`

`Float.<=(x, Any)`

`Float.>(x, Any)`

`Float.>=(x, Any)`

The function forms of `x < y` and the others. The right operand is an Integer, a Float or a Rational (a Complex has no order; it is a `type` problem statically). Every comparison with a NaN is false.

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

The function form of `x <=> y`: -1, 0 or 1. The right operand is an Integer, a Float or a Rational. When either side is a NaN the result is **nil**, so its type is `Integer | nil`, and `--strict` (the `nil` item of level 2) reports using it in arithmetic unchecked as `the operands may be nil`. Test it first with `if c`.

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

The absolute value (a Float). `-0.0` gives `0.0` and `-Infinity` gives `Infinity`.

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

`x < 0`, `x > 0` and `x == 0` as true/false. For `-0.0`, `zero?` is true and both `negative?` and `positive?` are false. All three are false for a NaN.

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

`nan?` is true for a NaN. `finite?` is true when x is neither a NaN nor infinite. `infinite?` returns, as Ruby's does, `1` for positive infinity, `-1` for negative infinity and **nil** otherwise (a NaN included), so its type is `Integer | nil`. It is usually used as a condition, `if Float.infinite?(x)`; to use the value in arithmetic, check it for nil first (`--strict`'s `nil` item reports the unchecked use).

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

Drop the fraction, giving the Integer nearest to zero (Ruby's `Float#to_i`). The three give the same result. A NaN or an Infinity cannot become an Integer: `FloatDomainError`, whose message is the value (`NaN`, `Infinity`). Ruby's digit-count argument of `truncate(digits)` does not exist on Float; use `Arithmetic.truncate(x, n)` ([Arithmetic](Arithmetic.md)).

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

`floor` is the largest Integer not above x, `ceil` the smallest Integer not below it. A NaN or an Infinity is a `FloatDomainError`. There is no digit-count argument; `Arithmetic.floor(x, n)` and `Arithmetic.ceil(x, n)` take one.

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

`Float.round(x, [Integer])`

Rounds. Without a digit count it returns the nearest Integer, rounding halves away from zero (`Float.round(2.5)` is 3 and `-2.5` gives -3, as Ruby's `round`; not banker's rounding). With a digit count `n` it returns a **Float** rounded to n decimal places. A negative count rounds to a power of ten, but the result is still a Float (Ruby's `1234.5.round(-2)` is the Integer 1200; Sake gives `1200.0`). The result type depends on whether a count is given because the checker looks at the number of arguments. A NaN or an Infinity without a count is a `FloatDomainError`; with a count it is returned unchanged.

```ruby
p(Float.round(1.5))            # => 2
p(Float.round(2.5))            # => 3
p(Float.round(-2.5))           # => -3
p(Float.round(1.2345, 2))      # => 1.23
p(Float.round(3.14159, 3))     # => 3.142
p(Float.round(1234.5, -2))     # => 1200.0
p(Float.round(1.5, 0))         # => 2.0
p(Float.round(Float.NAN, 2))   # => NaN
```

```ruby error
p(Float.round(-Float.INFINITY))  # !> FloatDomainError: Float.round: -Infinity
```

## divmod

`Float.divmod(x, Any)`

The Tuple `[q, r]` of quotient and remainder: `q` is `x / y` floored, an **Integer**, and `r` is `x - q * y`, a Float with the sign of `y` (as Ruby's `7.5.divmod(2)` is `[3, 1.5]`). `y` is a Float or an Integer; any other type, a Rational included, is a `type` problem statically. Dividing by the Integer 0 is a `ZeroDivisionError`. Dividing by the Float `0.0`, or an `x` that is a NaN or an Infinity, is Ruby's `ZeroDivisionError` / `FloatDomainError` too, but these are currently not turned into Sake exceptions and stop the program as Ruby errors.

```ruby
p(Float.divmod(7.5, 2))        # => [3, 1.5]
p(Float.divmod(-7.5, 2.0))     # => [-4, 0.5]
q, r = Float.divmod(7.5, 2)
p(q + 1)                       # => 4
p(r + 0.5)                     # => 2.0
```

```ruby error
p(Float.divmod(7.5, 0))        # !> ZeroDivisionError: Float.divmod: divided by 0
```

## fdiv, quo

`Float.fdiv(x, Integer|Float|Rational)`

`Float.quo(x, Integer|Float|Rational)`

Floating-point division `x / y` (a Float). The result is that of `/`: dividing by zero gives `Infinity` or `NaN`, without an exception. The two are the same operation.

```ruby
p(Float.fdiv(7.5, 2))          # => 3.75
p(Float.quo(1.0, 4r))          # => 0.25
p(Float.fdiv(1.0, 0))          # => Infinity
```

## modulo

`Float.modulo(x, Integer|Float|Rational)`

The remainder of `x % y` (a Float with the sign of `y`). Unlike the operator, dividing by zero (the Integer 0 or `0.0`) raises Sake's `ZeroDivisionError` (the operator's `7.5 % 0.0` is NaN).

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

True when `lo <= x <= hi`. `lo` and `hi` must be Floats; an Integer is a `type` problem statically (`argument 2 must be Float, but is Integer`).

```ruby
p(Float.between?(1.5, 1.0, 2.0))   # => true
p(Float.between?(2.5, 1.0, 2.0))   # => false
```

```ruby error
p(Float.between?(1.5, 1, 2))       # !> Float.between?: argument 2 must be Float, but is Integer
```

## clamp

`Float.clamp(x, Float, Float)`

The Float `x` confined to `lo..hi` (`lo` when x is below it, `hi` when above). `lo` and `hi` are Floats only. `lo > hi` is Ruby's `ArgumentError`, which is currently not turned into a Sake exception and stops the program as a Ruby error.

```ruby
p(Float.clamp(2.5, 1.0, 2.0))  # => 2.0
p(Float.clamp(0.5, 1.0, 2.0))  # => 1.0
p(Float.clamp(1.5, 1.0, 2.0))  # => 1.5
```

```ruby error
p(Float.clamp(1.5, 1, 2))      # !> Float.clamp: argument 2 must be Float, but is Integer
```

## next_float, prev_float

`Float.next_float(x)`

`Float.prev_float(x)`

The next representable Float above or below x. `next_float(1.0) - 1.0` is `Float.EPSILON`. The Float after `Float.MAX` is `Infinity`; the one after a NaN is a NaN.

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

Convert to a Rational. `to_r` takes the binary value as it is, so `0.1` becomes `3602879701896397/36028797018963968`. `rationalize` picks the simplest fraction that rounds back to the same Float, so `0.1` becomes `1/10`. A NaN or an Infinity is a `FloatDomainError`. Ruby's tolerance argument `rationalize(eps)` does not exist on Float; `Rational.rationalize(r, eps)` takes one ([Rational](Rational.md)).

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

The numerator and denominator of `Float.to_r(x)` (Integers). The denominator of `0.1` is `36028797018963968`, the value of the binary representation. As in Ruby, a NaN or an Infinity is not an error: `numerator` returns the NaN or Infinity itself (still a Float) and `denominator` returns 1. The checker takes the result to be an Integer, so using the `numerator` of a NaN as an Integer is a `TypeError` at run time.

```ruby
p(Float.numerator(0.75))       # => 3
p(Float.denominator(0.75))     # => 4
p(Float.numerator(1.5))        # => 3
p(Float.denominator(0.1))      # => 36028797018963968
```

## angle, arg, phase

`Float.angle(x)`

`Float.arg(x)`

`Float.phase(x)`

The argument in the complex plane: the Integer `0` for a positive number (and `0.0`), the Float `π` for a negative one (and `-0.0`), so the type is `Integer | Float`. A NaN gives a NaN. The three are the same operation.

```ruby
p(Float.angle(1.5))            # => 0
p(Float.arg(-1.5))             # => 3.141592653589793
p(Float.phase(-0.0))           # => 3.141592653589793
p(Float.angle(Float.NAN))      # => NaN
```

## to_f, to_s

`Float.to_f(x)`

`Float.to_s(x)`

`to_f` returns x itself (to turn a value of type `Integer | Float` into a Float, use `Arithmetic.to_f(x)`). `to_s` is Ruby's notation: an integral value keeps its `.0`, and values from about 1e16 up or below 1e-4 use the exponent form `1.0e+20`. `Infinity`, `-Infinity` and `NaN` are spelled out. `puts(1.5)` prints the same notation.

```ruby
p(Float.to_f(1.5))             # => 1.5
p(Float.to_s(1.0))             # => "1.0"
p(Float.to_s(0.1 + 0.2))       # => "0.30000000000000004"
p(Float.to_s(1e20))            # => "1.0e+20"
p(Float.to_s(1e-5))            # => "1.0e-05"
p(Float.to_s(Float.INFINITY))  # => "Infinity"
p(Float.to_s(-0.0))            # => "-0.0"
```
