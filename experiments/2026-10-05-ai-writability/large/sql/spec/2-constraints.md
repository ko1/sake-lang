# Stage 2: constraints, changing rows, more expressions

## 2.1 Column constraints and table constraints

```
column-def := name type [column-constraint]...
column-constraint := PRIMARY KEY | NOT NULL | UNIQUE | DEFAULT default-value
default-value := [+ | -] numeric-literal | string-literal | NULL
table-constraint := PRIMARY KEY ( column [, column]... ) | UNIQUE ( column [, column]... )
CREATE TABLE [IF NOT EXISTS] name ( column-def [, column-def]... [, table-constraint]... );
```

Table constraints come after all column definitions. A table has at most one `PRIMARY KEY` (tests
respect this).

- `NOT NULL`: storing NULL is `NOT NULL constraint failed: <table>.<column>`.
- `UNIQUE` (a column, or a list of columns): no two rows may have equal values in all the listed
  columns (equal as in 1.9, comparing values of the same column). A row with NULL in any listed
  column never conflicts. A conflict is `UNIQUE constraint failed: <table>.<c1>[, <table>.<c2>]...`
  with the columns of that constraint in its order.
- `PRIMARY KEY` is `UNIQUE` plus `NOT NULL` on each of its columns, with the same messages; except
  the next rule.
- **INTEGER PRIMARY KEY.** A single column of type INTEGER declared `PRIMARY KEY` (as a column
  constraint, or `PRIMARY KEY (c)` alone) is the row's key: when a row is stored with NULL there (or
  without a value for it), it gets one more than the largest value in the column, or 1 if the table
  has no rows (this holds even if it is also declared `NOT NULL`; a `DEFAULT` on it is ignored). A
  value stored there must be an INTEGER after the conversion of 1.5 (`' 40 '` and `5.0` store 40 and
  5); any other value, and NULL stored by an `UPDATE`, is the error `datatype mismatch`. A conflict
  is `UNIQUE constraint failed: <table>.<column>`.
- `DEFAULT v`: a column not given a value by an `INSERT` gets v (converted by 1.5) instead of NULL.

Checks on one row happen in this order, and the first failure is reported: the INTEGER PRIMARY KEY's
value (`datatype mismatch`); `NOT NULL` of each column in column order; the INTEGER PRIMARY KEY's
uniqueness; then storage conversion of each other column in column order (1.5); then the other uniqueness constraints (`UNIQUE`, and a `PRIMARY KEY` that
is not an INTEGER PRIMARY KEY) from the last declared to the first, where declaration order is the
column constraints in column order followed by the table constraints in order. Rows of one statement are
checked one at a time, each against the table as it is after the previous rows; the first failure
is the statement's error and the statement has no effect.

## 2.2 UPDATE and DELETE

```
UPDATE table SET column = expr [, column = expr]... [WHERE expr] ;
DELETE FROM table [WHERE expr] ;
```

`UPDATE` changes each row for which `WHERE` is true (every row without `WHERE`): all the
expressions are evaluated on the row as it was before this statement changed it, then stored with
1.5 and checked with 2.1. Rows are updated one at a time in table order and each updated row is
checked against the table at that moment; tests never depend on that order (they avoid updates that
conflict only temporarily). A column named twice in `SET` uses the last assignment. An unknown column
is `no such column: <name>`. `DELETE` removes the rows for which `WHERE` is true, or all rows.
Neither prints anything. On any error, the table is left as it was.

## 2.3 More expressions

Precedence additions: `IN`, `LIKE` and `BETWEEN` (and their `NOT` forms) bind like `=` (level 6).

- **`CASE`**:
  `CASE WHEN c1 THEN r1 [WHEN c2 THEN r2]... [ELSE e] END`: the r of the first condition that is true
  (1.10); else e, or NULL without `ELSE`.
  `CASE x WHEN v1 THEN r1 ... [ELSE e] END`: the r of the first v with `x = v` true (with affinity,
  as for `=`: `CASE s WHEN 12` matches a TEXT column s holding `'12'`), so a NULL x matches nothing.
  x is evaluated once.
- **`x [NOT] BETWEEN a AND b`** is `x >= a AND x <= b` (with affinity, and three-valued), with x
  evaluated once. The `AND` inside `BETWEEN` belongs to it: `a BETWEEN 1 AND 2 AND c` is
  `(a BETWEEN 1 AND 2) AND c`. `NOT BETWEEN` is the negation.
- **`x [NOT] IN ( e1 [, e2]... )`**: 1 if x equals some ei; else NULL if x is NULL or some ei is
  NULL; else 0. `NOT IN` is the negation (NULL stays NULL). Only x's affinity counts: if x has an
  affinity, each ei is converted to that affinity (INTEGER or REAL: TEXT that is a numeric literal
after trimming becomes that number; TEXT: a number becomes its text form), whatever ei's own
affinity; if x has none,
  nothing is converted (`12 IN (s)` is 0 even when the TEXT column s holds `'12'`, while `12 = s` is 1).
- The bounds a and b of `BETWEEN` are parsed at the level just tighter than 6 (so they cannot contain
  a comparison without parentheses).
- **`x [NOT] LIKE p`**: NULL if either is NULL. Otherwise both are taken as text forms; p matches the
  whole of x, where `%` in p matches any sequence of characters (including none), `_` matches exactly
  one character, and any other character matches itself ignoring ASCII case (`'a' LIKE 'A'` is 1).
  1 or 0. `NOT LIKE` is the negation.
- **`CAST(x AS type)`** with type `INTEGER`, `REAL` or `TEXT`: NULL stays NULL. To INTEGER: a REAL is
  truncated toward zero; TEXT takes the longest prefix (after leading whitespace) that is an optional sign
  and digits, else 0 (`'12abc'` → 12, `'1e3'` → 1, `'1.9'` → 1, `'abc'` → 0). To REAL: an INTEGER
  becomes REAL; TEXT is read by numeric prefix as a REAL. To TEXT: the text form. A `CAST` expression
  has the affinity of its type (1.9).

## 2.4 More functions

| function | result |
|---|---|
| `substr(x, start)`, `substr(x, start, len)` | TEXT: part of x's text form (below) |
| `trim(x)`, `ltrim(x)`, `rtrim(x)` | x's text form without leading and trailing / leading / trailing spaces |
| `trim(x, chars)`, `ltrim(x, chars)`, `rtrim(x, chars)` | the same, removing any of the characters in chars' text form |
| `replace(x, from, to)` | x's text form with every non-overlapping occurrence of from, left to right, replaced by to; if from is `''`, x's text form unchanged |
| `instr(x, y)` | INTEGER: the 1-based position of the first occurrence of y's text form in x's, or 0 |
| `round(x)`, `round(x, n)` | REAL (below) |
| `max(x, y, ...)`, `min(x, y, ...)` | two or more arguments (tests of this stage never call them with one): NULL if any is NULL, else the largest / smallest in the order of values (no affinity); of equal values, the first |

**substr.** Let L be the length of the text, p = start, q = len (absent: infinite). Positions count
from 1; then:
1. if p < 0: p = p + L; if still p < 0: q = q + p, p = 0, and q = 0 if q < 0.
   else if p > 0: p = p - 1.
   else (p = 0): if q > 0, q = q - 1.
2. if q < 0 (a negative len counts backwards): q = -q; p = p - q; if p < 0: q = q + p, p = 0.
3. the result is the characters at 0-based positions p .. p+q-1 that exist (none if q ≤ 0).
`substr('hello', 2)` = `'ello'`, `substr('hello', 0, 2)` = `'h'`, `substr('hello', -3, 2)` = `'ll'`,
`substr('hello', 2, -1)` = `'h'`, `substr(12345, 2, 2)` = `'23'`. start and len are integers in tests.

**round.** TEXT x is read by numeric prefix. A negative n counts as 0. Take x's decimal form with 17
significant digits (C's `printf("%.17g", x)`), round that decimal number to n digits after the point
with halves away from zero, and give the result as a REAL: `round(2.5)` = 3.0, `round(-2.5)` = -3.0,
`round(2.345, 2)` = 2.35, `round(1.005, 2)` = 1.0 (its 17-digit form is 1.0049999999999999),
`round(5)` = 5.0.

## 2.5 Errors added in this stage

`NOT NULL constraint failed: <table>.<column>`; `UNIQUE constraint failed: <table>.<column>[, ...]`;
`datatype mismatch`.
