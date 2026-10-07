# Change: integer division and remainder round toward zero

## What changes

Section 7.1 of `SPEC.md` says that `/` and `%` round toward negative infinity.
From now on they round toward zero, as in C:

- `a / b` is the quotient of `a` and `b` with any fractional part dropped
  (rounded toward zero, never toward negative infinity). Its magnitude is
  `|a|` integer-divided by `|b|`; it is negative when exactly one of `a` and
  `b` is negative and the result is not 0.
- `a % b` is `a - (a / b) * b` with the new `/`. So the remainder is 0 or has
  the sign of the dividend `a` (the sign of `b` does not matter), and its
  magnitude is less than `|b|`.
- The identity `(a / b) * b + a % b == a` still always holds.

So `-7 / 2` is `-3`, `-7 % 2` is `-1`, `7 / -2` is `-3`, `7 % -2` is `1`,
`-7 / -2` is `3`, `-7 % -2` is `-1`, `-1 / 3` is `0` and `-1 % 3` is `-1`.
For two operands of the same sign, or a dividend of 0, nothing changes. A zero
result is always plain `0` (there is no negative zero).

The new rule applies everywhere ints are divided by the program:

- the `/` and `%` operators, on ints of any size;
- the compound assignments `/=` and `%=`, on any target (variable, array
  element, map entry, field).

Unchanged: division or remainder by zero is still a `zero` error
`division by zero`, at the operator (at the `/=` or `%=` token for a compound
assignment); operand type errors keep their wording and positions
(`cannot apply '/' to int and string`); precedence is unchanged, so `-7 / 2`
is `(-7) / 2`, which is the same as `-(7 / 2)` now. The integer division in the
"did you mean" rule of section 5.2 is on non-negative numbers and is not
affected.

## Examples

    print(-7 / 2, -7 % 2, 7 / -2, 7 % -2, -7 / -2, -7 % -2)

prints

    -3 -1 -3 1 3 -1

---

    let n = -17
    n /= 5
    let xs = [-10, 9]
    xs[0] %= 3
    xs[1] %= -4
    print(n, xs)

prints

    -3 [-1, 1]

---

    print(map(range(-4, 5), fn(n) return n % 3 end))
    print(-(10 ** 30) / 7, -(10 ** 30) % 7)
    print(-5 % 0)

prints

    [-1, 0, -2, -1, 0, 1, 2, 0, 1]
    -142857142857142857142857142857 -1
    runtime error at 3:10: division by zero
