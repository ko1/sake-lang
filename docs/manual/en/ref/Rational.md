# Rational

A Rational is a rational number with an Integer numerator and denominator, always kept in lowest terms. The literals are Ruby's: `2r`, `1/3r` (the division `1 / 3r`), `0.5r` (`1/2`); `Rational(1, 3)` and `Rational("1/3")` are Kernel operations (they do not take a Float as `Rational(0.5)` would in Ruby; from a Float use `Float.to_r` or `Float.rationalize`, see [Values and types](../03-values.md)). `p` shows a Rational as `(1/3)`.

The operators on Rationals are `+`, `-`, `*`, `/`, `%`, `**` and `==`, `!=`, `<`, `<=`, `>`, `>=`, `<=>`. The right operand may be an Integer, a Float, a Rational or a Complex, and the result type follows the closed table: with an Integer the result is a Rational, with a Float a Float, with a Complex a Complex ([Operators and indexing](../05-operators.md)). `1 + 1r/2`, with the Integer on the left, is a Rational too. An Integer raised to a negative Integer, `2 ** -1`, is a Rational in Ruby but an `ArgumentError` in Sake: write `2r ** -1`. The entries `Rational.+(x, y)` and so on below are the function forms of those operators.

As in Ruby, dividing a Rational by zero is a `ZeroDivisionError` (unlike a Float, it does not become infinite). The differences from Ruby: `round`, `floor`, `ceil` and `truncate` take no digit count (use `Arithmetic.round(r, n)`, see [Arithmetic](Arithmetic.md)), and the arguments of `quo` and `rationalize` do not accept a Float.

## Rational[]

`Rational[*Any]`

Makes an **Array of Rationals** (not a Rational). Every element must be a Rational, and every write (`Array.push`, ...) is checked. An Integer is not converted: it is a `type` problem statically and a `TypeError` at run time. The empty Array of Rationals is `Rational[]`.

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

The function forms of `x + y` and the others with a Rational on the left. The right operand `y` is an Integer, a Float, a Rational or a Complex. With an Integer or a Rational the result is a Rational, with a Float a Float, with a Complex a Complex. Any other type is a `type` problem statically and a `TypeError` at run time. A right operand of zero (`0`, `0r`) in `/` or `%` is a `ZeroDivisionError` (`0.0` follows the Float rules and gives `Infinity`). `%` is Ruby's `Rational#%`: the result takes the sign of the right operand. `**` is Ruby's: an integral power stays a Rational, but a fractional or Float power gives a Float (a Complex for a negative base). The checker decides on the right operand's type alone and takes the result to be a Rational, so using the `2.0` of `4r ** (1r/2)` as a Rational is a `TypeError` at run time.

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
p(Rational.**(2r, 1r/2))         # => 1.4142135623730951
```

```ruby error
p(Rational./(1r, 0))             # !> ZeroDivisionError: Rational./: divided by 0
```

## ==, !=

`Rational.==(x, Any)`

`Rational.!=(x, Any)`

The function form of `x == y`. A Rational compares by value with an Integer, a Float and a Complex: `1r/2 == 0.5` and `2r == 2` are true. The operator `==` accepts any two values and is false when the types differ, but the function form `Rational.==(x, y)` raises a `TypeError` at run time unless the right operand is a number (nil included); the checker does not catch this statically.

```ruby
p(Rational.==(1r/2, 0.5))        # => true
p(Rational.==(2r, 2))            # => true
p(Rational.!=(1r/2, 1r/3))       # => true
p(1r == nil)                     # => false
```

```ruby error
p(Rational.==(1r/2, "x"))        # !> TypeError: Rational.==: no implementation for (Rational, String)
```

## <, <=, >, >=

`Rational.<(x, Any)`

`Rational.<=(x, Any)`

`Rational.>(x, Any)`

`Rational.>=(x, Any)`

The function forms of `x < y` and the others. The right operand is an Integer, a Float or a Rational (a Complex has no order; it is a `type` problem statically). Comparisons with a Rational or an Integer are exact; with a Float the Float's value is used.

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

The function form of `x <=> y`: -1, 0 or 1. With an Integer or a Rational on the right the result is always an Integer. With a Float on the right it is **nil** for a NaN, so the type is `Integer | nil`, and `--strict` (the `nil` item of level 2) reports using it in arithmetic unchecked.

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

The absolute value (a Rational). The two are the same operation.

```ruby
p(Rational.abs(-1r/3))           # => (1/3)
p(Rational.magnitude(-1r/3))     # => (1/3)
p(Rational.abs(-5r/2))           # => (5/2)
```

## negative?, positive?, zero?

`Rational.negative?(x)`

`Rational.positive?(x)`

`Rational.zero?(x)`

`x < 0`, `x > 0` and `x == 0` as true/false.

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

The numerator and denominator in lowest terms (Integers). The numerator carries the sign; the denominator is always positive, and 1 for an integral value.

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

Convert to an Integer: `to_i` and `truncate` toward zero, `floor` downward, `ceil` upward, `round` to the nearest Integer (an exact half goes away from zero: `Rational.round(5r/2)` is 3 and `-5r/2` gives -3). Ruby's digit count, `round(digits)` and the like, does not exist on these; to round to a number of digits use `Arithmetic.round(x, n)`, whose result is a Rational.

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

The floating-point division `x / y` as a **Float**. Dividing by zero gives `Infinity`, without an exception.

```ruby
p(Rational.fdiv(1r/3, 2))        # => 0.16666666666666666
p(Rational.fdiv(2r/3, 1r/3))     # => 2.0
p(Rational.fdiv(1r, 0))          # => Infinity
```

## quo

`Rational.quo(x, Integer|Rational)`

The exact division `x / y` (a Rational). `y` is an Integer or a Rational; a Float is a `type` problem statically (to divide by a Float use `/`). Dividing by zero is a `ZeroDivisionError`.

```ruby
p(Rational.quo(1r/3, 2))         # => (1/6)
p(Rational.quo(1r/3, 2r/3))      # => (1/2)
```

```ruby error
p(Rational.quo(1r/3, 0))         # !> ZeroDivisionError: Rational.quo: divided by 0
```

## rationalize

`Rational.rationalize(x, [Rational])`

The simplest fraction within the tolerance `eps` (a Rational), that is, in `x - eps .. x + eps` (Ruby's `Rational#rationalize`). Without `eps` it returns x itself. `eps` must be a Rational; a Float is a `type` problem statically.

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

The nearest Float.

```ruby
p(Rational.to_f(1r/4))           # => 0.25
p(Rational.to_f(2r/3))           # => 0.6666666666666666
```

## to_r

`Rational.to_r(x)`

Returns x itself (for uniform handling of a value of type `Integer | Rational`).

```ruby
p(Rational.to_r(1r/3))           # => (1/3)
```

## to_s

`Rational.to_s(x)`

The String `"numerator/denominator"` (as Ruby's). An integral value keeps its denominator: `"2/1"`. It differs from `p`'s `(1/3)` only by the parentheses.

```ruby
p(Rational.to_s(1r/3))           # => "1/3"
p(Rational.to_s(2r))             # => "2/1"
p(Rational.to_s(-6r/4))          # => "-3/2"
```
