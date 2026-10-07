# Change m01: floating-point numbers

New type `float`: finite IEEE 754 doubles.

**Literals.** An integer literal directly followed by `.` and a digit continues as a float: `1.5`, `007.50`, `1_000.000_1` (`_` as in ints). `1.` and `.5` are not floats. The value is the nearest float; infinite is a lexical error `float literal out of range` at the literal. Syntax errors quote a float token as written without underscores (`'1.50'`).

**Arithmetic.** `+ - * / % **` on two numbers, at least one a float, give a float (the int rounded to a float, infinite if too large). `/` divides exactly. `%` takes the sign of the right operand (`-7.5 % 2` is `0.5`); a zero result keeps the left operand's sign (`-4.0 % 2` is `-0.0`). `/` or `%` by zero (`0`, `0.0`, `-0.0`): `zero` error `division by zero`. With a float operand, `**` allows negative exponents (`2 ** -1.0` is `0.5`). A result that is infinite or not real (`10.0 ** 400`, `(-8.0) ** 0.5`): `value` error `float result out of range`. Errors are at the operator. Unary `-` accepts floats.

**Comparison and equality.** `< <= > >=` accept any two numbers, comparing exact values (`2 ** 53 + 1 > 9007199254740992.0` is true). An int equals a float of the same exact value (`1 == 1.0`, `0 == -0.0`, `[1] == [1.0]`), also for `in`, `contains`, `match`. Floats are not map keys (`map key must be a string or int, got float`; `1.0 in m` is false).

**Text.** `repr` (so also `str`, `print`, interpolation) writes the fewest significant digits that read back as the same float, after `-` if negative (`-0.0` too). Plain form: at least one digit after the `.` (`3.0`, `0.30000000000000004`, `0.0001`). Exponent form `<digit>.<digits>e<sign><2+ digits>`, with at least one digit after the `.`, when the absolute value is nonzero and below 0.0001, at least 10^16, or an integer value at least 10^15: `1.0e+15`, `9.9e-05`, `1.2345678901234568e+16`.

**Built-ins** (now 26):

- `float(x)`, `an int, float or string`: a float unchanged; an int converted to the nearest float; a string of optional `-`, digits, then optionally `.` and digits, nothing else (`"-0"` gives `-0.0`). Other strings, or an infinite result: `value` error `float: cannot convert <repr(x)> to float`.
- `int(x)` truncates a float toward zero (`int(-2.7)` is `-2`); phrase `an int, float or string`.
- `type(x)` gives `"float"`.
- `min`, `max`: arguments `an int or float`; the first smallest / largest wins (`min(1, 1.0)` is `1`).
- `sort`: all numbers (mixed allowed) or all strings; equal numbers keep their order.

Indexes, slice bounds, `range`, `slice` still require ints.

**Examples**

    print(7 / 2, 7 / 2.0, 0.1 + 0.2, 1 == 1.0, -0.5 * 0)
    print("{1.0e}")

prints just `syntax error at 2:12: expected '}', got 'e'`. Without line 2: `3 3.5 0.30000000000000004 true -0.0`.

    print(int(-2.7), float("2"), min(3, 2.5), sort([2, 1.0, 1]), 2.5 > 2)
    let x = 1.0 / 0

prints `-2 2.0 2.5 [1.0, 1, 2] true`, then `runtime error at 2:13: division by zero`.
