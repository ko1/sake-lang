# Integer

An Integer is a whole number of any size, as Ruby's: `42`, `-7`, `1_000_000`, `0x1f`, `0b101`, `0o17`, `2 ** 100` ([Values and types](../03-values.md)). The conversion `Integer("42")` and `Integer(3.9)` is an operation of Kernel, not of this namespace (`Kernel.Integer`; an `ArgumentError` on bad input). Integers are values: no operation here changes its subject, and every result is a new value.

The operators on Integers come from the modules Integer includes ([Operators and indexing](../05-operators.md)): `Arithmetic` gives `+ - * / % **` and unary `-x`, `Comparable` gives `<=> < <= > >=`, `Bitwise` gives `& | ^ << >>` and unary `~x`, and `==` and `!=` are Kernel's. `a + b` dispatches on the type of `a`, so with an Integer on the left it runs `Integer.+(a, b)`; the entries `Integer.+(x, y)` and so on below are those function forms. The right operand's type comes from a **closed table**: Integer with Integer gives an Integer, with a Float a Float, with a Rational a Rational, with a Complex a Complex; `<` and the like compare with Integer, Float, and Rational; the bit operators take an Integer only. A right operand of another type (a String, nil, a Symbol) is a `type` problem statically (`the operands are (Integer, String), which the left operand's type does not support`) and a `TypeError` at run time. The function form also requires its first argument to be an Integer (`Integer.+(1.0, 2)` is a `type` problem: use `Float.+`, or the operator).

Two things differ from Ruby: `Integer ** negative Integer` raises `ArgumentError` instead of giving a Rational, so that the type of `a ** b` never depends on the value of `b`, and no method is called on a value (`1.+(2)` is rejected; write `Integer.+(1, 2)` or `1 + 2`). `/` and `%` floor as Ruby's do (`-7 / 2` is -4), and dividing by zero raises `ZeroDivisionError`.

The rounding family `round`, `floor`, `ceil`, `truncate`, and `abs`, `to_f`, `to_i`, `zero?` also exist in the module `Arithmetic` ([Arithmetic](Arithmetic.md)), where they take any real number (`Arithmetic.round(x)` for an Integer, Float, or Rational `x`, as Ruby's `x.round`); the entries below are the Integer-only forms, which reject a Float subject with a hint to use `Arithmetic`. Operations whose result may be nil do not exist in this namespace: every result is a definite Integer, Float, Rational, String, Boolean, Tuple, or Array.

## Integer[]

`Integer[*Any]`

Makes an **Array of Integers**: a typed Array whose every element must be an Integer, checked on construction and on every write (`Array.push`, `a[i] = v`, ...). A literal element of another type is rejected before running (`element 2 must be Integer, got String`); a write of another type is a `type` problem statically and a `TypeError` at run time. The empty Array of Integers is `Integer[]`. Compare `Array[1, 2]`, whose element type is inferred and widens with what is written into it.

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

Addition, subtraction, and multiplication, exact at any size. The result's type follows the right operand: Integer with an Integer, Float with a Float, Rational with a Rational, Complex with a Complex. Any other right operand is a `type` problem. The unary minus `-x` is `Integer.-@`, written as the operator only.

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

Division and remainder. With two Integers both **floor**, as Ruby's: the quotient rounds toward minus infinity and the remainder takes the sign of the divisor (`-7 / 2` is -4, `-7 % 3` is 2, `7 % -3` is -2). An Integer divisor of 0 raises `ZeroDivisionError`. With a Float on the right the result is a Float and division by `0.0` gives `Infinity` (IEEE); with a Rational, a Rational. See also `div`, `modulo`, `remainder`, `divmod`, `fdiv`, and `ceildiv`.

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

Exponentiation. Integer with a non-negative Integer exponent is an exact Integer; a Float exponent gives a Float, a Rational one a Rational. Unlike Ruby, a **negative Integer exponent is an `ArgumentError`** (Ruby gives a Rational); the message tells how to ask for a Rational (`2r ** -1`). `**` binds tighter than unary minus, so `-2 ** 2` is -4, as in Ruby; it is right-associative (`2 ** 3 ** 2` is 512). See also `pow`.

```ruby
p(2 ** 10)                   # => 1024
p(Integer.**(2, 0))          # => 1
p(2 ** 0.5)                  # => 1.4142135623730951
p(2 ** 2r)                   # => (4/1)
p(-2 ** 2)                   # => -4
```

```ruby error
p(2 ** -1)                   # !> ArgumentError: Arithmetic.**: Integer ** negative Integer (2 ** -1) is an error; for a Rational, write 2r ** -1
```

## ==, !=

`Integer.==(x, Any)`

`Integer.!=(x, Any)`

Equality (`!=` is its negation). Numbers compare across types: `1 == 1.0`, `1 == 1r`, and `1 == Complex(1, 0)` are true. With the **operator**, a value of another type is never equal (`1 == "1"` is false, `1 == nil` is false), as in Ruby. The **function form** `Integer.==(x, y)` only has rows for a number or nil on the right: `Integer.==(1, "a")` passes the checker (the right operand is `Any`) but raises `TypeError` at run time (`no implementation for (Integer, String)`). Use the operator when the right side may be of another type.

```ruby
p(1 == 1)                    # => true
p(1 == 1.0)                  # => true
p(1 != 1)                    # => false
p(1 == "1")                  # => false
p(1 == nil)                  # => false
p(Integer.==(1, nil))        # => false
```

```ruby error
p(Integer.==(1, "a"))        # !> TypeError: Integer.==: no implementation for (Integer, String)
```

## <, <=, >, >=

`Integer.<(x, Any)`

`Integer.<=(x, Any)`

`Integer.>(x, Any)`

`Integer.>=(x, Any)`

Ordering. The right operand is an Integer, Float, or Rational; a Complex has no order, and a String or nil is a `type` problem (`Comparable.<: the operands are (Integer, String) ...`). The result is true or false.

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

-1, 0, or 1 as the left operand is smaller than, equal to, or larger than the right (an Integer, Float, or Rational). Between numbers the result is never nil, so the checker types it as an Integer. Another right operand is a `type` problem.

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

Bitwise and, or, and exclusive or on the two's-complement bits, as Ruby's; negative numbers behave as if they had infinitely many 1 bits above. Both operands must be Integers: a Float on the right is a `type` problem (`Bitwise.&: the operands are (Integer, Float) ...`). The unary complement `~x` is `Integer.~`, written as the operator only.

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

Shift left and shift right by an Integer number of bits, as Ruby's: `x << n` is `x * 2**n` (exact, growing as needed), `x >> n` floors (`-1 >> 1` is -1). A negative count shifts the other way (`1 << -1` is 0). The right operand must be an Integer.

```ruby
p(1 << 4)                    # => 16
p(256 >> 4)                  # => 16
p(-1 >> 1)                   # => -1
p(1 << 100 == 2 ** 100)      # => true
```

## bit_length

`Integer.bit_length(x)`

The number of bits needed to represent the number in two's complement, without the sign bit, as Ruby's: 255 needs 8, 256 needs 9, 0 and -1 need 0, -256 needs 8.

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

Whether all, any, or none of the bits set in the mask are set in the number: `x & mask == mask`, `x & mask != 0`, `x & mask == 0`.

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

`div` is the floored quotient as an **Integer** even for a Float or Rational divisor (`Integer.div(7, 2.0)` is 3, where `7 / 2.0` is 3.5). `modulo` is `%`: the remainder with the sign of the divisor. `remainder` is the remainder with the sign of the **dividend**, as Ruby's (`Integer.remainder(-7, 3)` is -1, where `-7 % 3` is 2). A divisor of 0 (or `0.0`) raises `ZeroDivisionError`.

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

The Tuple `[quotient, remainder]` of the floored division, so that `q * b + r == a`, with `r` taking the sign of the divisor. A divisor of 0 raises `ZeroDivisionError`. Unlike Ruby's, the divisor must be an Integer (`Float.divmod` takes a Float subject).

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

The quotient rounded toward plus infinity (Ruby's `ceildiv`): `Integer.ceildiv(7, 2)` is 4, `Integer.ceildiv(-7, 2)` is -3. A divisor of 0 raises `ZeroDivisionError`.

```ruby
p(Integer.ceildiv(7, 2))     # => 4
p(Integer.ceildiv(-7, 2))    # => -3
p(Integer.ceildiv(6, 2))     # => 3
```

## fdiv

`Integer.fdiv(x, Integer)`

The quotient as a Float, `Integer.to_f(a) / b`. A divisor of 0 does not raise: the result is `Infinity`, `-Infinity`, or `NaN` (for `0 / 0`), as Ruby's. Unlike Ruby's, the divisor must be an Integer.

```ruby
p(Integer.fdiv(7, 2))        # => 3.5
p(Integer.fdiv(1, 3))        # => 0.3333333333333333
p(Integer.fdiv(1, 0))        # => Infinity
```

## pow

`Integer.pow(x, Integer, [Integer])`

`Integer.pow(a, b)` is `a ** b` for an Integer exponent, with the same `ArgumentError` for a negative one. `Integer.pow(a, b, m)` is `a ** b` modulo `m`, computed without building the large power, as Ruby's; the result takes the sign of `m`. With a modulus, a negative exponent fails with Ruby's `RangeError` and a modulus of 0 with Ruby's `ZeroDivisionError`.

```ruby
p(Integer.pow(2, 10))        # => 1024
p(Integer.pow(2, 10, 1000))  # => 24
p(Integer.pow(3, 100, 7))    # => 4
p(Integer.pow(2, 10, -7))    # => -5
```

```ruby error
p(Integer.pow(2, -1))        # !> ArgumentError: Integer.pow: Integer ** negative Integer (2 ** -1) is an error; for a Rational, write 2r ** -1
```

## gcd, lcm

`Integer.gcd(x, Integer)`

`Integer.lcm(x, Integer)`

The greatest common divisor and the least common multiple, always non-negative, as Ruby's. `gcd(0, n)` is `|n|` and `gcd(0, 0)` is 0; `lcm(0, n)` is 0.

```ruby
p(Integer.gcd(12, 18))       # => 6
p(Integer.gcd(-12, 18))      # => 6
p(Integer.gcd(0, 0))         # => 0
p(Integer.lcm(4, 6))         # => 12
p(Integer.lcm(0, 6))         # => 0
```

## gcdlcm

`Integer.gcdlcm(x, Integer)`

The Tuple `[gcd, lcm]`.

```ruby
g, l = Integer.gcdlcm(4, 6)
p([g, l])                    # => [2, 12]
```

## sqrt

`Integer.sqrt(x)`

The integer square root: the largest Integer whose square does not exceed the number (Ruby's `Integer.sqrt`), exact at any size, where `Math.sqrt` would give a Float. A negative number fails with Ruby's `Math::DomainError`.

```ruby
p(Integer.sqrt(16))          # => 4
p(Integer.sqrt(17))          # => 4
p(Integer.sqrt(10 ** 20))    # => 10000000000
```

## abs, magnitude

`Integer.abs(x)`

`Integer.magnitude(x)`

The absolute value, an Integer. `Arithmetic.abs(x)` does the same for any real number.

```ruby
p(Integer.abs(-5))           # => 5
p(Integer.magnitude(5))      # => 5
```

## even?, odd?

`Integer.even?(x)`

`Integer.odd?(x)`

Whether the number is even or odd; 0 is even, -3 is odd.

```ruby
p(Integer.even?(4))          # => true
p(Integer.even?(-3))         # => false
p(Integer.odd?(-3))          # => true
```

## zero?, positive?, negative?

`Integer.zero?(x)`

`Integer.positive?(x)`

`Integer.negative?(x)`

Whether the number is 0, above 0, or below 0. 0 is neither positive nor negative. `Arithmetic.zero?(x)` takes any real number.

```ruby
p(Integer.zero?(0))          # => true
p(Integer.positive?(0))      # => false
p(Integer.negative?(-1))     # => true
```

## succ, next

`Integer.succ(x)`

`Integer.next(x)`

The number plus one.

```ruby
p(Integer.succ(5))           # => 6
p(Integer.next(-1))          # => 0
```

## pred

`Integer.pred(x)`

The number minus one.

```ruby
p(Integer.pred(5))           # => 4
p(Integer.pred(0))           # => -1
```

## times

`Integer.times(x) { }`

Calls the block with 0, 1, ..., n-1 and returns n (the subject), as Ruby's. For n of 0 or less the block is not called. The block is **required** (Ruby's `times` without a block gives an Enumerator); it takes one parameter. `break v` ends the loop and makes `v` the result; `next` goes to the next count; `return` inside a function returns from the function.

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

Calls the block with a, a+1, ..., b and returns a (the subject), as Ruby's `a.upto(b)`. When a is above b the block is not called. The block is required.

```ruby
p(Integer.upto(1, 3) { |i| puts(i) })  # => 1
                                       # => 2
                                       # => 3
                                       # => 1
p(Integer.upto(3, 1) { |i| puts(i) })  # => 3
```

## downto

`Integer.downto(x, Integer) { }`

Calls the block with a, a-1, ..., b and returns a, as Ruby's `a.downto(b)`. When a is below b the block is not called. The block is required.

```ruby
p(Integer.downto(3, 1) { |i| puts(i) })  # => 3
                                         # => 2
                                         # => 1
                                         # => 3
```

## step

`Integer.step(x, Integer, Integer) { }`

`Integer.step(a, limit, step)` calls the block with a, a+step, a+2·step, ... while the value does not pass the limit (in the direction of the step), and returns a, as Ruby's `a.step(limit, step)`. Both the limit and the step are required Integers (Ruby's Float steps and keyword forms do not exist); a step of 0 is an `ArgumentError`. A negative step counts down.

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

The number limited to the interval: `lo` when below it, `hi` when above it, otherwise itself. Unlike Ruby's, there is no Range form (`clamp(1..10)`). A `lo` above `hi` fails with Ruby's `ArgumentError`.

```ruby
p(Integer.clamp(5, 1, 10))   # => 5
p(Integer.clamp(-5, 1, 10))  # => 1
p(Integer.clamp(50, 1, 10))  # => 10
```

## between?

`Integer.between?(x, Integer, Integer)`

True when `lo <= x <= hi`. Both bounds are included; with `lo` above `hi` the result is false.

```ruby
p(Integer.between?(5, 1, 10))   # => true
p(Integer.between?(1, 1, 10))   # => true
p(Integer.between?(0, 1, 10))   # => false
```

## round

`Integer.round(x, [Integer])`

Without digits, the number itself. With a negative digit count -d, the number rounded to a multiple of 10^d, halves away from zero, as Ruby's (`Integer.round(1250, -2)` is 1300, `Integer.round(-1250, -2)` is -1300); a positive count leaves the number unchanged. The result is always an Integer. Only for an Integer subject: a Float is a `type` problem whose hint names `Arithmetic.round(x)`, which rounds any real number.

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

Without digits, the number itself. With a negative digit count -d, the number rounded down (`floor`, toward minus infinity) or up (`ceil`, toward plus infinity) to a multiple of 10^d, as Ruby's. Always an Integer. For a Float, use `Arithmetic.floor` or `Float.floor`.

```ruby
p(Integer.floor(1234, -2))   # => 1200
p(Integer.floor(-1234, -2))  # => -1300
p(Integer.ceil(1234, -2))    # => 1300
p(Integer.ceil(-1234, -2))   # => -1200
p(Integer.floor(5))          # => 5
```

## truncate

`Integer.truncate(x, [Integer])`

Without digits, the number itself. With a negative digit count -d, the number rounded toward zero to a multiple of 10^d. Always an Integer.

```ruby
p(Integer.truncate(1234, -2))    # => 1200
p(Integer.truncate(-1234, -2))   # => -1200
```

## digits

`Integer.digits(x)`

A new Array of the decimal digits, least significant first, as Ruby's `digits` without a base (`Integer.digits(1234)` is `[4, 3, 2, 1]`; 0 gives `[0]`). It is an ordinary Array whose element type the checker infers as Integer, not an `Integer[]`. A negative number fails with Ruby's `Math::DomainError`. Unlike Ruby's, there is no base argument: use `to_s(n, base)` and `String.chars`.

```ruby
p(Integer.digits(1234))      # => [4, 3, 2, 1]
p(Integer.digits(0))         # => [0]
p(Array.sum(Integer.digits(999)))   # => 27
```

## to_s

`Integer.to_s(x, [Integer])`

The number written in the given base (2 to 36; default 10), as a String; lowercase letters stand for digits above 9, and a negative number gets a leading `-`. A base outside 2..36 is an `ArgumentError` (`invalid radix 1`). `String.to_i(s, base)` reads it back.

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

The number as a Float (the nearest one for a number too large to be exact). `Arithmetic.to_f(x)` takes any real number.

```ruby
p(Integer.to_f(3))           # => 3.0
```

## to_i, to_int

`Integer.to_i(x)`

`Integer.to_int(x)`

The number itself. They exist for code written for any real number; `Arithmetic.to_i(x)` truncates a Float or Rational to an Integer. Note that `Integer(s)`, the conversion of a String, is Kernel's, not this operation.

```ruby
p(Integer.to_i(3))           # => 3
p(Integer.to_int(-3))        # => -3
```

## to_r

`Integer.to_r(x)`

The number as a Rational with denominator 1.

```ruby
p(Integer.to_r(3))           # => (3/1)
```

## rationalize

`Integer.rationalize(x, [Integer|Float|Rational])`

The number as a Rational, as `to_r`; the optional tolerance is accepted for symmetry with `Float.rationalize` and makes no difference for an Integer.

```ruby
p(Integer.rationalize(3))        # => (3/1)
p(Integer.rationalize(3, 0.5))   # => (3/1)
```

## numerator, denominator

`Integer.numerator(x)`

`Integer.denominator(x)`

Seen as a fraction, the number is its own numerator over 1.

```ruby
p(Integer.numerator(6))      # => 6
p(Integer.denominator(6))    # => 1
```

## integer?

`Integer.integer?(x)`

Always true for an Integer (Ruby's `Numeric#integer?`). Use `x in Integer` to test the type of a value that may be something else.

```ruby
p(Integer.integer?(6))       # => true
```

## size

`Integer.size(x)`

The number of bytes in the machine representation, as Ruby's: 8 for a number that fits a machine word, more for larger ones. For the number of significant bits use `bit_length`.

```ruby
p(Integer.size(1))           # => 8
p(Integer.size(2 ** 100))    # => 13
```

## chr

`Integer.chr(x)`

A one-character String whose byte is the number, which must be 0 to 255; outside that it fails with Ruby's `RangeError` (`256 out of char range`). As Ruby's `chr` without an encoding, 0 to 127 give an ASCII String and 128 to 255 a one-byte binary String, which raises `EncodingError` when joined with UTF-8 text. `String.ord` is the reverse. For a code point above 255 build the String another way (`format("%c", n)`).

```ruby
p(Integer.chr(65))           # => "A"
puts(Integer.chr(97))        # => a
p(Integer.chr(10))           # => "\n"
p(String.ord(Integer.chr(200)))   # => 200
```

## ord

`Integer.ord(x)`

The number itself (Ruby's `Integer#ord`), the counterpart of `String.ord`, which gives the code point of a String's first character.

```ruby
p(Integer.ord(65))           # => 65
p(String.ord("A"))           # => 65
```
