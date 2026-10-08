# Spec issues: c6-math

No disagreement between SQLite 3.46.1 and spec files 1-6 was found while writing these tests.

Rules dropped or fenced off in change.md (SQLite's behaviour exists but is left out of the tests):

- Infinite results: `pow(0, -1)` and `pow(10, 400)` give an infinity in SQLite, which spec 1.3 has no
  printed form for. change.md says tests do not produce infinities.
- Very large REAL arguments of `ceil`/`floor`/`trunc` (at or above 1e15 in magnitude, where every
  double is already whole or the %.15g form hides the fraction): kept out of tests.
- Other SQLite 3.46 math functions (`log`, `ln`, `exp`, `sign`, `degrees`, trigonometric ones, ...)
  are not part of the change; tests do not call them, and they cannot serve as "no such function"
  names.
- Negative zero: `ceil(-0.5)`, `trunc(-0.3)`, `mod(-6, 3)` give -0.0 in SQLite; it prints `0.0`
  under 1.3 and as text, so it is kept (stated in change.md).
