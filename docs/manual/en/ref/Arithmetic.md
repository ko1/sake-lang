# Arithmetic

Arithmetic is the module of the arithmetic operators `+`, `-`, `*`, `/`, `%`, `**` and the unary `-x`, `+x`. `a + b` is shorthand for `Arithmetic.+(a, b)`, which dispatches to the `+` of the left operand's type (Integer, Float, Rational, Complex, String, Time, Set, or a Struct type that does `include Arithmetic`), see [Operators and indexing](../05-operators.md) and [Program structure](../02-program.md).

The eight operations in this chapter are not operators: they are **rounding and conversion for any real number** (Integer, Float, Rational). A Sake operation normally names its type, `Float.round(f)`; these are for values whose type is not settled, such as `Integer | Float` (the result of `Array.sum`, a number read from JSON), and they dispatch on the value's type as Ruby's `x.round` does. The result type follows the argument's: `round`, `floor`, `ceil`, `truncate` without a digit count and `to_i` give an Integer; a rounding with a digit count and `abs` give the argument's type (a union when the argument's type is one); `to_f` gives a Float; `zero?` gives true/false. The checker applies this rule to each type of the argument.

A Complex or a String argument is a `type` problem statically (`argument 1 must be Integer|Float|Rational, but is Complex`). Turning a NaN or an Infinity into an Integer is Ruby's `FloatDomainError`, but in the Arithmetic operations it is currently not turned into a Sake exception: it stops the program as a Ruby error and `rescue FloatDomainError` does not catch it (the operations that name Float, such as `Float.round`, can be rescued).

## round, floor, ceil, truncate

`Arithmetic.round(Integer|Float|Rational, [Integer])`

`Arithmetic.floor(Integer|Float|Rational, [Integer])`

`Arithmetic.ceil(Integer|Float|Rational, [Integer])`

`Arithmetic.truncate(Integer|Float|Rational, [Integer])`

Exactly Ruby's `x.round(n)`, `x.floor(n)`, `x.ceil(n)` and `x.truncate(n)`. `round` goes to the nearest value (a half away from zero), `floor` downward, `ceil` upward, `truncate` toward zero.

- Without the digit count `n` the result is an **Integer** (an Integer argument stays one).
- With a count the result has **the argument's type**: a Float for a Float, a Rational for a Rational, an Integer for an Integer (a positive count leaves the value as it is). A negative count rounds to a power of ten.
- As in Ruby, a Float with a count of 0 or less gives an Integer, because Ruby's `Float#round` does. The checker does not look at the count's value and takes the result to be a Float, so using that value as a Float is a `TypeError` at run time. To round a Float with a count of 0 or less, use `Float.round(f, n)`, which always gives a Float.
- A NaN or an Infinity without a count is Ruby's `FloatDomainError` (not a Sake exception, see above); with a count it is returned unchanged.

```ruby
p(Arithmetic.round(1.5))           # => 2
p(Arithmetic.round(7r/2))          # => 4
p(Arithmetic.round(3))             # => 3
p(Arithmetic.round(1.2345, 2))     # => 1.23
p(Arithmetic.round(7r/3, 2))       # => (233/100)
p(Arithmetic.round(1234, -2))      # => 1200
p(Arithmetic.floor(-1.5))          # => -2
p(Arithmetic.floor(1.567, 1))      # => 1.5
p(Arithmetic.ceil(7r/2))           # => 4
p(Arithmetic.ceil(1234, -2))       # => 1300
p(Arithmetic.truncate(-7r/2))      # => -3
p(Arithmetic.truncate(1.999, 2))   # => 1.99
```

One operation serves a value whose type is not settled:

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

## abs

`Arithmetic.abs(Integer|Float|Rational)`

The absolute value, of the argument's type (Ruby's `x.abs`).

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

`to_i` is the Integer truncated toward zero; `to_f` the nearest Float. The typical use is `to_f` to settle an `Integer | Float` value on Float (when `Float.floor(x)` is given an `Integer | Float`, the checker suggests `Arithmetic.floor(x)`). `to_i` of a NaN or an Infinity is Ruby's `FloatDomainError` (not a Sake exception).

```ruby
p(Arithmetic.to_i(1.9))            # => 1
p(Arithmetic.to_i(7r/2))           # => 3
p(Arithmetic.to_i(7))              # => 7
p(Arithmetic.to_f(3))              # => 3.0
p(Arithmetic.to_f(1r/4))           # => 0.25
p(Arithmetic.to_f(1.5))            # => 1.5
```

## zero?

`Arithmetic.zero?(Integer|Float|Rational)`

True when `x == 0` (`0.0` and `-0.0` included).

```ruby
p(Arithmetic.zero?(0))             # => true
p(Arithmetic.zero?(0.0))           # => true
p(Arithmetic.zero?(0r))            # => true
p(Arithmetic.zero?(1))             # => false
```
