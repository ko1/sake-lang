# Change: math functions

This change adds seven scalar functions (eleven names): `ceil`/`ceiling`, `floor`, `trunc`, `mod`,
`pow`/`power`, `sqrt` and `pi`. They are ordinary functions in the sense of 1.11: names are
case-insensitive, they may appear wherever an expression may (result columns, `WHERE`, `ORDER BY`,
`GROUP BY`, `HAVING`, inside aggregate and window calls, `SET`, `VALUES`, `CASE`, ...), and a call
with any other number of arguments than shown below is `wrong number of arguments to function
<name>()`, with `<name>` as written (`CEILING()` gives `wrong number of arguments to function
CEILING()`). No new error messages are added, and no new keywords: the names are identifiers.

## 7.1 Arguments

Every argument of these functions is first turned into a number, or the call gives NULL:

1. NULL: the result is NULL.
2. INTEGER and REAL are used as they are.
3. TEXT is converted only if, after removing leading and trailing whitespace (space, tab, newline,
   carriage return), it is a numeric literal with an optional leading `+` or `-` (exactly the test
   of 1.5 step 2: `' 12 '`, `'-3.5'`, `'1e3'`, `'.5'`, `'5.'`). It becomes an INTEGER if the literal has no
   `.` and no exponent, otherwise a REAL (`'7'` is INTEGER 7, `'7.0'` is REAL 7.0, `'1e2'` is REAL
   100.0). Any other TEXT (`'abc'`, `'12abc'`, `'1e'`, `'0x10'`, `''`) makes the result NULL. Note
   that this is **not** the numeric prefix of 1.8: `ceil('3x')` is NULL, while `'3x' + 0` is 3.

If any argument gives NULL by these rules, the result is NULL (for two-argument functions, whatever
the other argument is).

## 7.2 The functions

| function | result |
|---|---|
| `ceil(x)`, `ceiling(x)` | INTEGER x: x unchanged (INTEGER). REAL x: the smallest whole number not below x, as a REAL |
| `floor(x)` | INTEGER x: x unchanged (INTEGER). REAL x: the largest whole number not above x, as a REAL |
| `trunc(x)` | INTEGER x: x unchanged (INTEGER). REAL x: x with its fraction removed (rounded toward zero), as a REAL |
| `mod(x, y)` | REAL: the remainder of x / y, computed on both as REAL (C's `fmod`): x - n*y where n is x/y truncated toward zero; the sign is x's. NULL if y is zero |
| `pow(x, y)`, `power(x, y)` | REAL: x raised to the power y (C's `pow`, both as REAL). NULL when the result is not a real number (a negative x with a y that is not a whole number) |
| `sqrt(x)` | REAL: the square root of x. NULL if x is negative |
| `pi()` | REAL: the double nearest to pi (prints `3.14159265358979`) |

Details:

- `ceil`, `floor` and `trunc` keep the type: an INTEGER argument (including one converted from text,
  `ceil('7')` = 7) gives that INTEGER back, never a REAL; a REAL gives a REAL even when it is already
  whole (`floor(2.0)` = 2.0, `typeof(trunc(2.0))` = `'real'`). `ceil(1.2)` = 2.0, `ceil(-1.2)` =
  -1.0, `floor(-1.7)` = -2.0, `trunc(-1.7)` = -1.0, `trunc(1.7)` = 1.0.
- A result that is negative zero (`ceil(-0.5)`, `trunc(-0.3)`, `mod(-6, 3)`) prints `0.0` (1.3), and
  its text form is `'0.0'`.
- `mod` and `pow` always give a REAL, even for two INTEGER arguments: `mod(7, 3)` = 1.0, `mod(-7, 3)`
  = -1.0, `mod(7, -3)` = 1.0, `mod(7.5, 2)` = 1.5, `mod(5.5, 2.5)` = 0.5, `mod(7, 0)` and `mod(7,
  0.0)` are NULL. Unlike `%` (1.8), `mod` does not truncate its operands: `7.5 % 2` is 1.0 but
  `mod(7.5, 2)` is 1.5.
- `pow(2, 10)` = 1024.0, `pow(2, -1)` = 0.5, `pow(-2, 3)` = -8.0, `pow(0, 0)` = 1.0, `pow(9, 0.5)` =
  3.0, `pow(-8, 0.5)` is NULL.
- `sqrt(16)` = 4.0, `sqrt(2)` prints `1.4142135623731`, `sqrt(0)` = 0.0, `sqrt(-1)` is NULL.
- Results print by the rule of 1.3, like any REAL. Tests do not produce infinities (`pow(0, -1)`,
  `pow(10, 400)`), and keep REAL arguments of `ceil`, `floor`, `trunc` below 1e15 in magnitude.
- A call of these functions has no affinity (1.9): `ceil(s) = '3'` compares a number with text and
  is false.
- Tests do not call other SQLite math functions (`log`, `exp`, `sign`, ...); they are not part of
  this change.

## Where it applies

- ceil (public): `ceil(x)` and `ceiling(x)` round a REAL up to a whole REAL, give an INTEGER back unchanged, convert text by 7.1, and take exactly one argument.
- floor: `floor(x)` rounds a REAL down to a whole REAL, gives an INTEGER back unchanged, converts text by 7.1, and takes exactly one argument.
- trunc: `trunc(x)` drops the fraction of a REAL (toward zero) giving a REAL, gives an INTEGER back unchanged, converts text by 7.1, and takes exactly one argument.
- mod (public): `mod(x, y)` is the REAL remainder of x / y with x's sign, NULL for a zero y, with text converted by 7.1, and takes exactly two arguments.
- pow (public): `pow(x, y)` and `power(x, y)` give x to the power y as a REAL, NULL when that is not a real number, with text converted by 7.1, and take exactly two arguments.
- sqrt (public): `sqrt(x)` is the REAL square root, NULL for a negative x, with text converted by 7.1, and takes exactly one argument.
- pi: `pi()` takes no arguments and gives the REAL nearest pi, printed `3.14159265358979`.
