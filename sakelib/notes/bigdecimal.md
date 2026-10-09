# bigdecimal (BigDecimal)

`require "bigdecimal"` → `sakelib/bigdecimal.sake`. Test: `test/sakelib/bigdecimal.{sake,rb}` (identical output;
the twin uses bigdecimal 4.1.2 on Ruby 4.0.2).

`BigDecimal` is a Struct type with private fields `kind` (`:finite`, `:nan`, `:inf`), `sgn` (1 or -1),
`sig` (a non-negative Integer) and `exp` (base 10): the value is `sgn * sig * 10**exp`. `initialize`
normalizes (no trailing zeros in `sig`; zero is `sig 0, exp 0` with its sign), so arithmetic is exact
Integer arithmetic and comparison aligns exponents. It includes `Arithmetic` (`+ - * / % **`, unary `-`)
and `Comparable` (with its own `<=>`, `==`, `<`, ... so that NaN compares as in Ruby: always false).
Ruby's `Kernel.BigDecimal(x)` is `BigDecimal.parse(s)`, `from_i(n)`, `from_f(f, prec)`, `from_r(r, prec)`;
Ruby's rounding-mode constants are Symbols; `BigDecimal::NAN` / `::INFINITY` are `BigDecimal.NAN` /
`BigDecimal.INFINITY`, as `Float.NAN` is.

## API

| Ruby | Sake | |
|---|---|---|
| `BigDecimal("1.23")` | `BigDecimal.parse("1.23")` | same (sign, `_` between digits, `.`, `e`/`E`/`d`/`D` exponent, spaces around; `Infinity`, `NaN`; Ruby's `ArgumentError: invalid value for BigDecimal(): "x"`) |
| `BigDecimal(12)` | `BigDecimal.from_i(12)` | same |
| `BigDecimal(1.5, prec)` / `BigDecimal(1.5, 0)` | `BigDecimal.from_f(1.5, prec)` / `from_f(1.5)` | differs slightly: rounds the Float's shortest decimal (`Float.to_s`), Ruby its exact binary value; `prec > 17` raises Ruby's `precision too large.` |
| `BigDecimal(1r/3, 10)` | `BigDecimal.from_r(1r/3, 10)` | same; `from_r(r)` (prec 0) is Ruby's `BigDecimal(r, 0)` (Ruby requires the argument) |
| `BigDecimal::NAN`, `::INFINITY` | `BigDecimal.NAN`, `BigDecimal.INFINITY` | same (operations) |
| `BigDecimal.double_fig` | `BigDecimal.double_fig` | same (16) |
| `a + b`, `a - b`, `a * b` | `a + b`, ... | same, exact; `b` a BigDecimal, Integer, or Float (Float via its shortest decimal) |
| `a / b`, `a.quo(b)` | `a / b`, `BigDecimal.quo(a, b)` | same: Ruby 4's default precision, `max(precision(a), precision(b)) + 16`, at least 32 significant digits, ROUND_HALF_UP; `x / 0` is ±Infinity, `0 / 0` NaN |
| `a.div(b, digits)` | `BigDecimal.div(a, b, digits)` | same (`digits` 0: the default above); `a.quo(b, prec)` likewise |
| `a.div(b)` (Integer, floor) | `BigDecimal.idiv(a, b)` | differs: name, so that `div` has one result type (`ZeroDivisionError: divided by 0`) |
| `a % b`, `a.modulo(b)`, `a.divmod(b)`, `a.remainder(b)` | `a % b`, `BigDecimal.modulo`, `divmod` (`[Integer, BigDecimal]` Tuple), `remainder` | same |
| `a.add(b, n)`, `sub`, `mult` | `BigDecimal.add(a, b, n)`, ... | same (rounded to n significant digits, half up; n = 0 exact) |
| `a ** n`, `a.power(n, prec)` | `a ** n`, `BigDecimal.power(a, n, prec)` | same for Integer n: exact for n ≥ 0 (then rounded to prec); `1 / exact` for n < 0 (prec, or `/`'s default) |
| `a ** 0.5`, `a ** Rational`, `a ** BigDecimal` | — | missing: Ruby goes through BigMath.exp/log (not ported) |
| `-a`, `+a`, `a.abs` | `-a`, `+a`, `BigDecimal.abs(a)` | same |
| `a.sqrt(n)` | `BigDecimal.sqrt(a, n)` | same (n significant digits, half up; n = 0: `n_significant_digits + 16`; Ruby's errors) |
| `a <=> b`, `==`, `<`, `<=`, `>`, `>=` | same operators | same: nil / false with NaN; `b` a BigDecimal, Integer, Float, or Rational; another type: nil / false (Ruby's `<` raises) |
| `a.round`, `a.round(n)`, `a.round(n, mode)` | `BigDecimal.round(a, n = 0, mode = :half_up)` | differs: always a BigDecimal (Ruby: an Integer without n or with n ≤ 0); modes `:up :down :truncate :half_up :default :half_down :half_even :banker :ceiling :ceil :floor`; Ruby's `invalid rounding mode (x)` |
| `a.floor`, `a.floor(n)`, `ceil`, `truncate`, `fix`, `frac` | `BigDecimal.floor(a, n = 0)`, ... | differs as `round`: always a BigDecimal (so `floor(Infinity)` is Infinity, Ruby raises) |
| `a.to_i`, `to_int`, `to_r`, `to_f`, `to_d` | `BigDecimal.to_i(a)`, ... | same (`FloatDomainError: Computation results in 'NaN' (Not a Number)` / `'Infinity'` / `'-Infinity'`; `to_f` gives ±Infinity / ±0.0 beyond Float's range) |
| `a.to_s` / `a.inspect` / `p(a)` | `BigDecimal.to_s(a)` / `p(a)` | same (`0.123e1`, `-0.0`, `Infinity`, `NaN`) |
| `a.to_s("F")`, `to_s("+")`, `to_s(" F")`, `to_s("3F")`, `to_s(3)`, `to_s("E")` | `BigDecimal.format(a, fmt)` | differs: name (Sake's `to_s` takes one argument); same output |
| `a.precision`, `scale`, `precision_scale`, `n_significant_digits`, `exponent`, `sign` | `BigDecimal.precision(a)`, ... | same |
| `a.zero?`, `nonzero?`, `nan?`, `infinite?`, `finite?`, `negative?`, `positive?` | `BigDecimal.zero?(a)`, ... | same |
| `a.hash`, `a.coerce(x)`, `a._dump`, `_load`, `dup`, `clone` | — | missing: a type with its own `==` cannot be a Hash key; coerce is dispatch on the right operand (see below) |
| `BigDecimal.mode`, `limit`, `save_rounding_mode` & co. | — | missing: global modes are the one thing a value-based port cannot carry; the default mode (NaN and Infinity results, ROUND_HALF_UP) is what is implemented |
| `BigMath` (`log`, `exp`, `sqrt`, `PI`, `E`, `sin`, ...) | — | missing (out of budget; `sqrt` is on BigDecimal) |
| `Integer#to_d`, `String#to_d`, `Float#to_d` (bigdecimal/util) | `BigDecimal.from_i`, `parse`, `from_f` | differs: constructors |

61 operations ported.

## What differs, and why

- **`round`/`floor`/`ceil`/`truncate` always give a BigDecimal.** Ruby gives an Integer when no digit
  count is given (or it is ≤ 0) and a BigDecimal otherwise. In Sake a result type that depends on an
  optional argument is a union at every call, and `Integer | BigDecimal` would need a `case` after each
  `round`. Ruby's Integer is `BigDecimal.to_i(BigDecimal.round(a))`. Same choice for `div` (`idiv` for
  Ruby's Integer `div(b)`), the lesson already noted in `strscan.md` (a flag does not specialize the result
  type; a function per result type does).
- **No coerce.** `1 + a` and `2 * a` are static errors: an operator dispatches on its left operand, and
  Integer's `+` knows no BigDecimal. Write `a + 1`, `a * 2`. Likewise `Array.sum` of BigDecimals is
  `Array.reduce(xs, BigDecimal.from_i(0)) { |s, x| s + x }` (`sum` takes the numeric built-ins only).
- **Float operands** (`a + 0.1`, `a == 0.1`, `from_f`) go through the Float's shortest decimal
  (`Float.to_s`), which is what Ruby does for `BigDecimal(f, 0)`; Ruby's operand coercion and
  `BigDecimal(f, prec)` use the Float's exact binary expansion to `prec` digits, so they can differ in
  the 16th–17th digit when prec is near 17. The test's cases agree.
- **Comparison with a non-number** (`a < "x"`): nil / false; Ruby raises `comparison of BigDecimal with
  String failed`. Sake has no class name of a value for the message, and `<=>` is nil anyway.
- **`to_s` with a format** is `format(a, fmt)`: Sake fixes `to_s` at one argument (it is the string form
  `puts` and interpolation use).
- **Division's precision** was taken from bigdecimal 4.1.2's `BigDecimal_div2`: `ix = max(prec_a, prec_b) +
  BIGDECIMAL_DOUBLE_FIGURES`, `ix = 32 if ix < 32`, where prec counts digits including the integer
  part's trailing zeros (`precision`); the quotient is rounded ROUND_HALF_UP with the remainder as a
  sticky digit. Verified against Ruby on 26 quotients in the test (1/3, 1.23456789/3 terminates,
  123456789012345678/7 → 34 digits, ...). Older bigdecimal versions (≤ 3.1) use a different rule, so
  the twin must run on bigdecimal 4.x.

## Built-ins Sake lacks (requests)

- **Right-operand dispatch (Ruby's `coerce`)**, or a way for a type to say "Integer + me is me + Integer":
  without it `1 + a` cannot work for any user numeric type, which every numeric library hits.
- `Array.sum` (and `Range.sum`, `Set.sum`) accepting elements of a type that includes `Arithmetic`.
- A Float → exact decimal conversion with a digit count (Ruby's dtoa modes), or `Float.to_r` plus
  `Rational.round(r, digits)`: to match `BigDecimal(float, prec)` exactly. (`Float.to_r` exists; only
  the rounding to significant digits was out of budget.)
- `Integer.<=>` is typed as possibly nil, as Ruby's: `(x <=> y) * s` is a `nil` report. A version typed
  Integer for two Integers (the typer knows both are Integers) would save the three-way `if`.

## Friction

- `def NAN = ...` is accepted, and `BigDecimal.NAN` works from outside (as `Float.NAN` does), but an
  unqualified `NAN` inside the class → `error: type `NAN` cannot be used as a value` → named the
  internal helpers `nan` / `infinity` and kept `NAN` / `INFINITY` as the public Ruby-shaped names.
- `def to_s(d, fmt = "")` → `error: BigDecimal.to_s takes exactly one argument (the value to show)` →
  `format(d, fmt = "")` plus `to_s(d) = format(d, "")`. The message was clear; the Ruby API has
  `to_s(fmt)` on several numeric types (`Integer#to_s(base)` too), so a port of those meets it.
- `(x <=> y) * @sgn` on two Integers → `Arithmetic.*: the operands may be nil ([Integer | nil, Integer])
  [nil]` → `x == y ? 0 : (x < y ? -@sgn : @sgn)`. Correct by the table (`<=>` may give nil), but for two
  Integers it never does.
- `p(s(Array.max(xs)))` in the test → `BigDecimal.sgn: argument 1 may be nil (BigDecimal | nil)` with the
  chain `line 142 → line 4 → bigdecimal.sake:445` → `mx = Array.max(xs); p(s(mx)) if mx != nil`. True
  (`[].max` is nil); the hint chain through the test's helper into the library was exactly what was needed.
- `Array.map(BigDecimal.divmod(a, b))` → `Array.map: argument 1 must be Array, but is [Integer,
  BigDecimal]` with the Tuple hint → `Array.map(Tuple.to_a(...))`. Ruby's `divmod` returns an Array; a
  Tuple is the right type for a pair, but every Ruby idiom that maps over the pair needs `Tuple.to_a`.
- `balance * (1 + rate)` → `Arithmetic.+: the operands are (Integer, BigDecimal), which the left operand's
  type does not support [type]` → `(rate + 1)`. The report is right and early, but this is the one
  Ruby habit a numeric type cannot support (see the coerce request).
- `Array.sum(xs, BigDecimal.from_i(0))` → `Array.sum: argument 2 must be Integer|Float|Rational|Complex`
  → `Array.reduce`.
- What felt good: the whole library is Integer arithmetic on four fields, and `initialize` normalizing
  them means `==` on fields would already be value equality; `case mode in :up ... in :half_even | :banker`
  with `else raise ArgumentError` covers Ruby's eleven mode names in ten lines; the first `--strict` run
  of the library itself reported only the `<=>` nil above. `include Comparable` with my own `<`, `<=`,
  `>`, `>=`, `==` (NaN semantics) coexisted with `Array.sort`/`max` using `<=>` without any declaration.
