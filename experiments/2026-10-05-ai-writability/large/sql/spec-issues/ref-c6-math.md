# Spec issues found by the reference implementation: c6-math

Implementation: `large/sql/changes/c6-math/ref/functions.rb` (+39 lines; no other file changed).
Results: stages 1-6 public 366/366, hidden 369/369; change public 8/8, change hidden 18/18.

No test's expected output disagrees with change.md or spec 1-6. The items below are unclear or
missing rules, and sites the hidden tests do not exercise.

## 1. `mod` is "C's fmod", but a naive implementation is not (unclear, no test)

7.2 defines `mod` as `x - n*y` with n = x/y truncated, and also as C's `fmod`. These differ in
floating point when |y| is much larger than |x|: `mod(-7, 1e308)` is -7.0 by fmod (SQLite agrees),
but 0.0 by Ruby's `Float#remainder` (which computes `x % y` then subtracts y). The ref uses an exact
fmod (`|x| % |y|` with x's sign). Judgement: spec is right but "x - n*y" invites the lossy formula;
no test reaches it (all tests have small operands).

## 2. Non-finite inputs from text are not covered (missing rule)

7.2 says tests produce no infinities, but 7.1 lets text like `'1e400'` become REAL infinity.
SQLite: `mod('1e400', 2)` is NULL (fmod gives NaN), `sqrt('-1e400')` NULL, `pow('1e400', 0)` 1.0.
The spec says nothing about a NaN result. The ref maps any NaN result to NULL (matching SQLite).
Judgement: add "a NaN result is NULL" or exclude infinite text arguments explicitly.

## 3. Integer-looking text out of 64-bit range (unclear, inherited from 1.5)

7.1 says text without `.` or exponent becomes an INTEGER; `'99999999999999999999'` cannot.
SQLite makes it REAL (`ceil(...)` = 1.0e+20, `real`); the ref does the same. 1.5 step 2 has the
same gap. Judgement: say "an INTEGER if it fits in 64 bits, otherwise a REAL".

## 4. Whitespace set (minor)

7.1 lists space, tab, newline and CR. SQLite also trims form feed and vertical tab
(`ceil(char(12)||'5')` = 5). The engine cannot build those characters in tests without `char`
(not in this change), so it is unobservable here; noted only for consistency with 1.5.

## 5. Sites of the intro list not tested by the hidden tests

The per-function bullets of "Where it applies" (ceil, floor, trunc, mod, pow, sqrt, pi) are each
covered by the hidden tests (REAL/INTEGER/text arguments, NULL cases, arity errors). Of the generic
site list in the intro, the hidden tests cover result columns, WHERE, ORDER BY, GROUP BY, aggregate
arguments, window arguments and window ORDER BY, SET, a view, a CTE and a correlated subquery. Not
covered by hidden tests:
- `HAVING` (no test, public or hidden);
- `CASE` (no test, public or hidden);
- `VALUES` (only public `003-ceil-arguments` uses `INSERT ... VALUES (ceil(0.1))`);
- `ON` of a join (017 joins, but the new functions are not in the ON condition).
- The "no affinity" rule (`ceil(s) = '3'` is false) has no test at all. SQLite agrees with the
  spec (`ceil(s) = '3'` 0, `ceil(s) = 3` 1 for a TEXT column s = '3').
