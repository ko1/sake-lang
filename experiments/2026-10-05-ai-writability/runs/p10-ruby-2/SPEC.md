# A small SQL engine: specification, stages 1..6

# Stage 1: the core

## 1.1 What the program does

The program reads a script of SQL statements from standard input and runs them in order against one
in-memory database that starts empty. A `SELECT` prints its result rows. An error prints one line
`Error: <message>`; the statement that failed has no effect at all (a multi-row `INSERT` that fails on
its third row inserts nothing), and the script continues with the next statement. Everything goes to
standard output; the exit status is always 0. The program uses no database library and starts no other
program.

## 1.2 Lexical structure

- Whitespace (space, tab, newline, carriage return) separates tokens. `--` starts a comment that runs
  to the end of the line; `/* ... */` is a comment (not nested).
- Every statement ends with `;`. An empty statement (`;` alone) does nothing. Scripts never have text
  other than whitespace and comments after the last `;`.
- Keywords and identifiers are case-insensitive (ASCII letters only): `select`, `Select` and `SELECT`
  are the same keyword; `Name`, `NAME` and `name` are the same identifier.
- An identifier is a letter or `_` followed by letters, digits and `_`, and not a keyword; or any text
  in double quotes, with `""` standing for one `"` (a quoted identifier may be a keyword).
  The keywords (all stages): `ADD ALL ALTER AND AS ASC BEGIN BETWEEN BY CASE CAST COLUMN COMMIT CREATE
  CROSS CURRENT DEFAULT DELETE DESC DISTINCT DROP ELSE END EXCEPT EXISTS FIRST FOLLOWING FROM GROUP
  HAVING IF IN INDEX INNER INSERT INTERSECT INTO IS JOIN KEY LAST LEFT LIKE LIMIT NOT NULL NULLS OFFSET
  ON OR ORDER OUTER OVER PARTITION PRECEDING PRIMARY RANGE RECURSIVE RENAME ROLLBACK ROW ROWS SELECT
  SET TABLE THEN TO TRANSACTION UNBOUNDED UNION UNIQUE UPDATE USING VALUES VIEW WHEN WHERE WINDOW
  WITH`. Type names (`INTEGER`, `REAL`, `TEXT`) and function names (`count`, `upper`) are identifiers;
  tests do not use keywords or type names as table, column or alias names, nor words that SQLite does
  not accept as names (such as `nothing`). A double-quoted name in tests always names
  something that exists (or is being created); error messages spell it without the quotes.
- A string literal is text in single quotes, with `''` standing for one `'`. It may span lines.
- A numeric literal is digits with an optional fraction and exponent: `42`, `3.5`, `.5`, `5.`, `1e3`,
  `2.5E-3`. Without `.` and exponent it is an INTEGER (tests keep integers within 64 bits); with
  either it is a REAL. A sign is not part of the literal: `-3` is unary minus applied to `3`.
- Operators and punctuation: `+ - * / % || = == != <> < <= > >= ( ) , ; .` and `*` in `SELECT *`.
- Scripts use no other characters outside literals and comments (no `&`, `|` alone, `~`, `<<`,
  hexadecimal literals). Tokens in an order the grammar does not allow are a syntax error: the statement
  prints `Error: syntax error`. A syntax error ends at the statement's `;`; the next statement runs.
  (Find the end of a statement by scanning for `;` outside string literals, quoted identifiers and
  comments before parsing it.)

## 1.3 Values

Every value has one of four types:

| type | values | printed as |
|---|---|---|
| NULL | `NULL` | `NULL` |
| INTEGER | 64-bit signed integers | decimal digits, `-` if negative: `-12` |
| REAL | IEEE 754 doubles | see below |
| TEXT | strings (tests use ASCII only) | the characters, unquoted |

A REAL prints as C's `printf("%.15g", x)` (15 significant digits, shortest of fixed or exponent form),
then: if the result has no `.` and no `e`, append `.0` (`1.0`, `100.0`); if it has an `e` but no `.`
before it, insert `.0` before the `e` (`1e+20` becomes `1.0e+20`). Negative zero prints `0.0`.
Examples: `0.1 + 0.2` prints `0.3`; `2.0 / 3` prints `0.666666666666667`; `1e15` prints `1.0e+15`;
`1.5e-7` prints `1.5e-07`. Tests never produce infinities or NaN.

This printed form is also the value's **text form**, used wherever a number turns into text.

## 1.4 Tables

```
CREATE TABLE [IF NOT EXISTS] name ( column-def [, column-def]... );
column-def := name type
type := INTEGER | REAL | TEXT          (exactly one of these words; tests always give a type)
DROP TABLE [IF EXISTS] name;
```

A table has columns in declaration order and rows in insertion order. Errors:
`table <name> already exists` (with `IF NOT EXISTS`: nothing happens), `duplicate column name: <name>`
(the second occurrence), `no such table: <name>` for `DROP TABLE` (with `IF EXISTS`: nothing happens).

In error messages, a name the statement wrote is spelled as the statement wrote it; `<table>.<column>`
in storage and constraint errors uses the spelling of the `CREATE TABLE`.

## 1.5 Storing a value: the column's type is enforced

When a value is stored into a column (by `INSERT`, and later `UPDATE`), it is converted to the
column's type or rejected:

1. NULL is stored as NULL.
2. A TEXT value is first parsed as a number if, after removing leading and trailing whitespace (space, tab, newline, carriage return), it is a
   numeric literal with an optional leading `+` or `-` (`' 12 '`, `'-3.5'`, `'1e3'`, `'.5'`; not
   `'12abc'`, `'0x10'`, `''`): it becomes an INTEGER if the literal has no `.` and no exponent,
   otherwise a REAL. This applies only when the column is INTEGER or REAL; a TEXT column keeps the text.
3. Then, by column type:
   - INTEGER column: an INTEGER is stored; a REAL whose value is a whole number within 64 bits is
     stored as that INTEGER (`1.0`, `'12.0'`, `'1e3'` store 1, 12, 1000); any other REAL is rejected;
     TEXT that did not parse is rejected.
   - REAL column: an INTEGER is stored as the equal REAL; a REAL is stored; TEXT that did not parse is
     rejected.
   - TEXT column: TEXT is stored; an INTEGER or REAL is stored as its text form (`1.5` stores `'1.5'`,
     `1e20` stores `'1.0e+20'`).

A rejection is the error `cannot store <T> value in <C> column <table>.<column>`, where `<C>` is the
column's type and `<T>` is the type of the value at the point of rejection: `TEXT` for text that did
not parse, `REAL` for a REAL, including one parsed from text (`'12.5'` into an INTEGER column gives
`cannot store REAL value in INTEGER column t.i`).

## 1.6 INSERT

```
INSERT INTO table [ ( column [, column]... ) ] VALUES ( expr [, expr]... ) [, ( ... )]... ;
```

All rows of one `VALUES` list must have the same number of values, else the error is
`all VALUES must have the same number of terms`. Without a column list, each row gives a value for
every column in order; a different count is the error `table <table> has <n> columns but <m> values were supplied`. With a list, each row
gives one value per listed column (otherwise `<m> values for <n> columns`); unlisted columns get NULL.
A listed column the table does not have is `table <table> has no column named <column>`. The
expressions are evaluated with no row in scope (a column name in them is `no such column: <name>`).
Rows are stored in order; if any row fails, the statement inserts nothing.

## 1.7 SELECT

```
SELECT result-column [, result-column]... [FROM table]
  [WHERE expr] [ORDER BY ordering-term [, ordering-term]...] [LIMIT expr [OFFSET expr]] ;
result-column := * | expr [ [AS] alias ]
ordering-term := expr [ASC | DESC] [NULLS FIRST | NULLS LAST]
```

Evaluation: take the rows of the table (one empty row when there is no `FROM`); keep those for which
`WHERE` is true (1.10); compute the result columns for each; sort by `ORDER BY`; skip `OFFSET` rows;
keep at most `LIMIT` rows; print each row as its values printed (1.3) and joined with `|`, one line per
row. A query with no result rows prints nothing.

- `*` stands for every column of the table, in order. `SELECT *` without `FROM` is the error
  `no tables specified`.
- **Names.** In the result columns, a name is a column of the table. In `WHERE`, a name is a column of
  the table, or else a result column's alias (standing for that result column's expression). In
  `ORDER BY`, a term that is just a name, and that name is a result column's alias, means that
  result column; a name anywhere else in an `ORDER BY` term (inside a larger expression) is a column of
  the table, or else a result column's alias. A name that matches nothing is `no such column: <name>`; this error, like
  every name error, happens before any row is read, so it occurs on an empty table too.
- **ORDER BY.** A term that is an integer literal `k`, or the token `-` followed by one (`-1`), means
  the k-th result column; outside 1..n (n result columns) it is the error
  `<i-th> ORDER BY term out of range - should be between 1 and <n>`, where `<i-th>` is the position of
  the term in the `ORDER BY` list (not k), written `1st`, `2nd`, `3rd`, `4th`, ... (`11th`, `12th`,
  `13th`, `21st`, `22nd`): `ORDER BY a, 5` with one result column is `2nd ORDER BY term out of range -
  should be between 1 and 1`. Any other term is an expression evaluated on the row.
  Tests do not write an `ORDER BY` or `GROUP BY` term as `+k` or `(k)`, put one in parentheses, list a column twice in an `INSERT`, or give two
  result columns the same alias. Rows are compared term by term in the order of
  values (1.9); `DESC` reverses it. NULLs come first under `ASC` and last under `DESC`, unless
  `NULLS FIRST` or `NULLS LAST` says otherwise. Rows that tie on every term may come out in any order;
  tests never depend on that order, nor on the order of rows without `ORDER BY`.
- **LIMIT and OFFSET** are integers (tests use integer literals, possibly negative). A negative `LIMIT` means
  no limit; a negative `OFFSET` counts as 0.

## 1.8 Expressions

```
expr := literal | NULL | name | ( expr ) | function-call
      | unary-op expr | expr binary-op expr | expr IS [NOT] expr
function-call := name ( [expr [, expr]...] )
```

Operators, from tightest to loosest binding; binary operators of one level associate to the left:

| level | operators |
|---|---|
| 1 | unary `-`, unary `+` |
| 2 | `\|\|` |
| 3 | `*` `/` `%` |
| 4 | `+` `-` |
| 5 | `<` `<=` `>` `>=` |
| 6 | `=` `==` `!=` `<>` `IS` `IS NOT` |
| 7 | `NOT` (prefix) |
| 8 | `AND` |
| 9 | `OR` |

Tests use prefix `NOT` only where an operand of `AND`, `OR` or `NOT`, or at the start of a condition.
So `2 * 3 || 4` is `2 * (3 || 4)` = 68, `'a' || 1 + 2` is `('a' || 1) + 2` = 2, `1 < 2 = 1` is
`(1 < 2) = 1`, and `NOT a = b` is `NOT (a = b)`.

**Turning text into a number (numeric prefix).** Arithmetic, unary minus, truth tests and some
functions read a TEXT value as a number this way: skip leading whitespace; take the longest prefix that is
an optional sign followed by a numeric literal (digits with optional fraction and exponent, or `.`
digits; an exponent counts only if it has digits: `'1e'` reads as `1`); if there is none, the number
is INTEGER 0; otherwise it is an INTEGER if the prefix has no `.` and no exponent, else a REAL.
`'3abc'` → 3, `' -2.5e1x'` → -25.0, `'5.'` → 5.0, `'abc'` → 0, `'-'` → 0.

**Arithmetic** `+ - * / %`. If either operand is NULL, the result is NULL. TEXT operands are read by
numeric prefix. If both are INTEGER, the operation is on integers: `/` truncates toward zero
(`-7 / 2` = -3) and `%` takes the sign of the left operand (`-7 % 2` = -1, `7 % -2` = 1). Otherwise
both are taken as REAL and the result is REAL, except `%`, which truncates both operands to integers
and gives the integer remainder as a REAL (`7.5 % 2` = 1.0). Division or `%` by zero (integer or
real) gives NULL. Unary `-` negates (NULL stays NULL; TEXT is read by numeric prefix). Unary `+`
returns its operand unchanged, even TEXT. Tests never overflow 64-bit integers.

**Concatenation** `a || b`: NULL if either is NULL; otherwise the text forms of both, joined
(`1 || 2` = `'12'`, `1.5 || ''` = `'1.5'`).

**Comparison** `= == != <> < <= > >=` (`==` is `=`, `<>` is `!=`): NULL if either operand is NULL.
Otherwise the operands are first converted by affinity (1.9), then compared in the order of values;
the result is INTEGER 1 or 0.

**`a IS b`** is like `a = b` (with affinity) except that it is never NULL: `NULL IS NULL` is 1 and
`NULL IS 1` is 0. `a IS NOT b` is its negation. `x IS NULL` and `x IS NOT NULL` are cases of these.

**Logic** `NOT`, `AND`, `OR` use three-valued logic on truth values (1.10): `NOT` of unknown is
unknown; `AND` is false if either side is false, else unknown if either is unknown, else true; `OR`
is true if either side is true, else unknown if either is unknown, else false. The result is INTEGER
1 (true), 0 (false) or NULL (unknown).

## 1.9 Order of values, and affinity

**Order of values** (used by comparison and sorting): NULL < every number < every TEXT. Two numbers
compare by numeric value whatever their types (`1 = 1.0` is true). Two TEXT values compare
byte by byte (`'B' < 'a'`, `'abc' < 'abd'`, `'ab' < 'abc'`). Comparisons by `=` on the result
(DISTINCT, GROUP BY in later stages) use this order too.

**Affinity.** An expression that is a column reference, possibly in parentheses (`(s)`), has the
affinity of its column's type (INTEGER, REAL or TEXT); any other expression, including `+s`, has no
affinity (stage 2 adds `CAST`). Before comparing
`a op b`:

1. If one operand has INTEGER or REAL affinity and the other has TEXT affinity or none, then the other
   operand, if it is TEXT that is a numeric literal after trimming spaces (the test of 1.5 step 2), is
   converted to that number. (`i = '12'` with `i` an INTEGER column is true when `i` is 12;
   `i < 'abc'` compares a number with text and is true.)
2. Otherwise, if one operand has TEXT affinity and the other has none, the other operand, if it is a
   number, is converted to its text form. (`s = 12` with `s` a TEXT column is true when `s` is `'12'`;
   `s = 3` is false when `s` is `'3.0'`, and `s = 3.0` is true.)
3. Otherwise nothing is converted (`12 = '12'` between two literals is false).

## 1.10 Truth values

Where a condition is needed (`WHERE`, `NOT`, `AND`, `OR`, and later `CASE WHEN`, `HAVING`, `ON`), a
value is unknown if NULL; a number is true if nonzero; TEXT is read by numeric prefix and is true if
that number is nonzero (`'1x'` true, `'abc'` false, `'0.0'` false). Rows whose `WHERE` is false or
unknown are dropped.

## 1.11 Functions

A function call names a function case-insensitively. An unknown name is `no such function: <name>`
(tests use names that are not functions in SQLite either);
a wrong number of arguments is `wrong number of arguments to function <name>()` (`<name>` as written).
Unless stated otherwise, a NULL argument gives NULL.

| function | result |
|---|---|
| `length(x)` | INTEGER: the number of characters of x's text form (`length(1.5)` = 3) |
| `upper(x)`, `lower(x)` | TEXT: x's text form with ASCII letters changed |
| `abs(x)` | INTEGER x → its absolute value; REAL → absolute value; TEXT → read by numeric prefix, result always REAL (`abs('-3')` = 3.0) |
| `typeof(x)` | TEXT: `'null'`, `'integer'`, `'real'` or `'text'` (never NULL) |
| `coalesce(x, y, ...)` | two or more arguments: the first that is not NULL, else NULL |
| `ifnull(x, y)` | `coalesce(x, y)` |
| `nullif(x, y)` | NULL if `x = y` (compared without affinity), else x |

## 1.12 Errors in this stage

`syntax error`; `no such table: <name>`; `no such column: <name>`; `table <name> already exists`;
`duplicate column name: <name>`; `table <table> has no column named <column>`;
`cannot store <T> value in <C> column <table>.<column>`;
`table <table> has <n> columns but <m> values were supplied`; `<m> values for <n> columns`;
`all VALUES must have the same number of terms`;
`no such function: <name>`; `wrong number of arguments to function <name>()`;
`<i-th> ORDER BY term out of range - should be between 1 and <n>`; `no tables specified`.
Tests have at most one error per statement.

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

# Stage 3: aggregates, GROUP BY, DISTINCT

## 3.1 Syntax

```
SELECT [DISTINCT | ALL] result-column [, result-column]... [FROM table] [WHERE expr]
  [GROUP BY expr [, expr]... [HAVING expr]]
  [ORDER BY ...] [LIMIT ...] ;
aggregate-call := count(*) | name ( [DISTINCT] expr [, expr] [ORDER BY ordering-term [, ...]] )
```

`HAVING` is allowed without `GROUP BY` only in an aggregate query (3.3).

## 3.2 Aggregate functions

A call of one of these names with the argument count shown is an aggregate; `max` and `min` with two
or more arguments stay the scalar functions of 2.4. Each aggregate works on the rows of a group.

| aggregate | result |
|---|---|
| `count(*)` | INTEGER: the number of rows |
| `count(x)` | INTEGER: the number of rows where x is not NULL |
| `sum(x)` | NULL if no non-NULL x; INTEGER if every non-NULL x is an INTEGER; otherwise REAL (below) |
| `total(x)` | like `sum`, but always REAL, and 0.0 when there is no non-NULL x |
| `avg(x)` | NULL if no non-NULL x; else REAL: the sum (as REAL, below) divided by the count of non-NULL x |
| `min(x)`, `max(x)` | the smallest / largest non-NULL x in the order of values (1.9), or NULL |
| `group_concat(x)`, `group_concat(x, sep)` | TEXT: the text forms of the non-NULL x joined by sep's text form (default `','`; a NULL sep joins with nothing); NULL if no non-NULL x |

**Sums.** A TEXT x that is a numeric literal after trimming spaces (the test of 1.5 step 2) counts as
that INTEGER or REAL (`sum('3')` is the INTEGER 3 per row); any other TEXT is a non-INTEGER, read by
numeric prefix. The INTEGER sum is exact; if it leaves 64 bits, the statement fails with
`integer overflow` (tests do not reach this). When some value is not an INTEGER, the sum is computed
in REAL with compensation: start with s = (the INTEGER sum of the values before it, as REAL) and
c = 0.0, then for each remaining non-NULL value v in row order (an INTEGER taken as REAL, TEXT read by
numeric prefix as REAL):

```
t = s + v
if |s| > |v| then c = c + ((s - t) + v) else c = c + ((v - t) + s)
s = t
```

The result is s + c. (So `0.1 + 0.2 + 1e16 + 1.0` sums to `1.0e+16` printed, and `0.1`, `0.2`,
`0.3` sum exactly to the double nearest 0.6.) `total` and `avg` use the same REAL sum (for all-INTEGER
input, the exact sum as REAL).

**DISTINCT** inside a call (`count(DISTINCT x)`, `sum(DISTINCT x)`, `group_concat(DISTINCT x)`, ...)
uses each distinct non-NULL value once (equality as in 1.9; tests do not mix `1` and `1.0` in one
DISTINCT). `group_concat(DISTINCT x, sep)` is the error `DISTINCT aggregates must have exactly one
argument`; the other aggregates take one argument anyway (a second is `wrong number of arguments to
function <name>()`), and tests do not write `min`/`max` with `DISTINCT` and two arguments.

**ORDER BY** inside `group_concat` (`group_concat(name, ';' ORDER BY id DESC)`) joins the values in
that order; its terms are evaluated on the rows of the group. Without it, values are joined in row
order, which tests do not depend on unless every value is the same or the input has one row.

## 3.3 Grouping

A query is an **aggregate query** if it has `GROUP BY`, or an aggregate call in its result columns.
(An aggregate call only in `HAVING` or `ORDER BY` does not make one; see the errors below.)

- After `WHERE`, rows are partitioned into groups: rows whose `GROUP BY` values are all equal
  (1.9; NULLs are equal to each other here) form one group. Without `GROUP BY`, all rows form one
  group, which exists even when there are no rows (`SELECT count(*) FROM t WHERE 0` prints `0`).
  With `GROUP BY` and no rows, there are no groups.
- `HAVING` keeps the groups for which it is true. Then each group gives one result row; `ORDER BY`,
  `LIMIT` and `OFFSET` apply to these rows.
- In result columns, `HAVING` and `ORDER BY` of an aggregate query, an aggregate call computes over
  the group. A column reference outside an aggregate call (a **bare column**) takes its value from one
  row of the group: if the query has exactly one aggregate call and it is `min(x)` or `max(x)`, the row
  that gave that minimum or maximum (calls in result columns, `HAVING` and `ORDER BY` all count
  toward "exactly one"; calls written identically count once); otherwise any row of the group. In the single group of a query without
  `GROUP BY` over no rows, a bare column is NULL. Tests use a bare column only when
  every row of the group has the same value there (for example, a `GROUP BY` column), or with that
  single `min`/`max` (and no ties).
- A `GROUP BY` term that is an integer literal k, or `-` directly followed by one, means the k-th
  result column (outside 1..n: `<i-th> GROUP BY term out of range - should be between 1 and <n>`,
  `<i-th>` being the term's position as in 1.7). A name in `GROUP BY` or
  `HAVING` is a column of the table, or else a result column's alias.
- Errors: an aggregate call in `WHERE` is `misuse of aggregate function <name>()`, and a name in
  `WHERE` that is the alias of a result column containing an aggregate call is `misuse of aggregate:
  <name>()` (the aggregate's name); an aggregate call in `GROUP BY` is `aggregate functions are not
  allowed in the GROUP BY clause`; `HAVING` in a query that is not an aggregate query is `HAVING
  clause on a non-aggregate query`; an aggregate call in the `ORDER BY` of a query that is not an
  aggregate query is `misuse of aggregate: <name>()`. An aggregate call inside another
  aggregate call's argument does not occur in tests.

## 3.4 SELECT DISTINCT

`SELECT DISTINCT` removes duplicate result rows (rows whose values are pairwise equal by 1.9, NULLs
equal to each other), keeping one of each, before `ORDER BY`, `LIMIT` and `OFFSET`. `SELECT ALL` is
the default. With `DISTINCT`, `ORDER BY` terms are evaluated as for the result rows (tests order by
result columns).

## 3.5 Errors added in this stage

`misuse of aggregate function <name>()`; `aggregate functions are not allowed in the GROUP BY clause`;
`HAVING clause on a non-aggregate query`; `misuse of aggregate: <name>()`; `DISTINCT aggregates must have exactly one argument`;
`<i-th> GROUP BY term out of range - should be between 1 and
<n>`; `integer overflow`.

# Stage 4: joins and subqueries

## 4.1 FROM with several sources

```
FROM from-item [join-op from-item [join-constraint]]...
from-item := table [[AS] alias] | ( select ) [AS] alias | ( select )
join-op := , | [INNER] JOIN | CROSS JOIN | LEFT [OUTER] JOIN
join-constraint := ON expr | USING ( column [, column]... )
```

Every `FROM` (in `SELECT`, and in subqueries) now takes this form. An `ON` expression may use
the columns of the sources joined so far (not result column aliases, nor aggregate calls); a
subquery in `FROM` is not correlated with the queries around it; `,` and `CROSS JOIN` take no
constraint, and a `LEFT JOIN` always has one. A **source** is one from-item; its name is its alias,
or the table's name if it has none (a `( select )` without an alias has no name). Two sources with
the same name in one `FROM` do not occur in tests.

**Rows.** Joins associate to the left. `A , B`, `A CROSS JOIN B` and `A JOIN B` without a constraint
pair every row of A with every row of B. `A [INNER] JOIN B ON e` keeps the pairs where e is true.
`A LEFT JOIN B ON e` keeps those pairs, plus, for each row of A that is in no such pair, that row
with every column of B NULL. `USING (c1, ...)` means `ON A.c1 = B.c1 AND ...`, where `A.c` is the
column `c` of the sources joined so far (the first one that has it) and `B.c` is B's; a column
missing on either side is the error `cannot join using column <c> - column not present in both
tables`. `WHERE` then filters the joined rows (so a condition on B's columns in `WHERE` drops the
NULL-extended rows of a `LEFT JOIN`, while the same condition in `ON` does not).

**Subquery sources.** `( select )` runs once and is a source whose columns are the select's result
columns, named by alias, else by the column's name if the result column is a plain column reference
(tests give every other result column an alias when it is referenced). A column that is a plain
column reference keeps that column's affinity (1.9) when compared outside.

## 4.2 Names

- `q.c` (qualified): the column c of the source named q (in the innermost query that has a source
  named q). If no source is named q, or it has no column c, the error is `no such column: q.c`
  (spelled as written). Tests do not use a name q for sources at two levels of nesting. A table that has an alias is
  known only by its alias.
- `c` (unqualified): the sources of the innermost query that have a column c. If exactly one does,
  that column. If several do, `ambiguous column name: c`, except that a column named in `USING` is
  one column (its value is the left side's; tests do not mix a `USING` merge with another copy of the
  name joined by `ON`). If none does, the result column aliases where 1.7 and 3.3 allow them; then
  each enclosing query (4.3), innermost first, the same way: its sources, then its aliases where 1.7
  and 3.3 allow them in the clause that contains the subquery; else `no such column: c`.
- In `UPDATE` and `DELETE`, the target table is an enclosing source, named by its table name, for
  subqueries in `SET` and `WHERE` (`SET qty = (SELECT sum(n) FROM moves WHERE moves.pno = stock.pno)`).
  Tests do not depend on what such a subquery sees of rows the same statement changes.
- `*` expands to the columns of every source in order, leaving out the right side's copy of each
  `USING` column. `q.*` expands to the columns of source q (`no such table: q` if there is none).

## 4.3 Subqueries in expressions

```
( select )                          a scalar subquery
expr [NOT] IN ( select )
[NOT] EXISTS ( select )
```

A subquery is a full `SELECT` (stage 5 adds compound selects) and may refer to columns of the
queries that enclose it; such a **correlated** subquery is evaluated again for each row of the
enclosing query. Precedence: `EXISTS (...)` and `( select )` are primary expressions; `NOT EXISTS
(...)` is the prefix `NOT` (1.8) applied to `EXISTS (...)`. An aggregate call inside a subquery always
refers to that subquery's own sources in tests.

- **Scalar subquery**: the value of the first column of its first row, or NULL if it has no rows.
  It must have exactly one result column, else `sub-select returns <n> columns - expected 1` —
  except that as a direct operand of a comparison (`=`, `!=`, `<`, ..., `IS`, `IS NOT`), of
  `BETWEEN`, or as the x of `CASE x`, a scalar subquery with more than one column is `row value
  misused`. (`IS NULL` and `IS NOT NULL` with the literal `NULL` do not count as comparisons here:
  they give the `sub-select` error. Tests do not compare two multi-column subqueries.) If its result column is a plain column reference, the subquery has that column's affinity
  (1.9). Tests make "first" well defined (one row, or `ORDER BY` that orders the rows fully, or
  `LIMIT 1` on such).
- **`x IN ( select )`**: as `x IN (v1, v2, ...)` (2.3) with the values of the subquery's single
  column (the same error if it has more columns), except for affinity: each comparison of x with a
  value v follows 1.9 as for `x = v`, where v has its column's affinity if the subquery's result
  column is a plain column reference (so, unlike the list form, `12 IN (SELECT s FROM texts)` is 1
  when the TEXT column s holds `'12'`). If the subquery has no rows, the
  result is 0 even when x is NULL (`NOT IN` gives 1). `NOT IN` is the negation.
- **`EXISTS ( select )`**: 1 if the subquery has at least one row, else 0. `NOT EXISTS` is the
  negation.

## 4.4 Errors added in this stage

`ambiguous column name: <name>`; `sub-select returns <n> columns - expected 1`; `row value misused`;
`cannot join using column <c> - column not present in both tables`; `no such table: <q>` for `q.*`.

# Stage 5: compound selects, WITH, views, transactions, schema changes

## 5.1 Compound selects

```
select := [WITH ...] simple-select [compound-op simple-select]... [ORDER BY ...] [LIMIT ... [OFFSET ...]]
compound-op := UNION | UNION ALL | INTERSECT | EXCEPT
```

Each simple-select is a `SELECT` without its own `ORDER BY`/`LIMIT`. The operators have equal
precedence and associate to the left. All simple-selects must have the same number of result
columns, else `SELECTs to the left and right of <op> do not have the same number of result columns`
(`<op>` being the operator where the mismatch is found, left to right). `UNION ALL` concatenates;
`UNION` keeps one of each distinct row of both sides; `INTERSECT` keeps the distinct rows that are in
both; `EXCEPT` keeps the distinct rows of the left side that are not in the right. Rows are equal as
in `SELECT DISTINCT` (3.4); tests do not rely on which of two equal rows of different types (`1`,
`1.0`) is kept.

The trailing `ORDER BY`/`LIMIT`/`OFFSET` apply to the whole result. In a compound select, an
`ORDER BY` term must be an integer literal (the k-th column) or a name that is an alias or column
name of a result column (looked up in the first simple-select, then the next, and so on; tests use
names of the first); a name that matches none is `<i-th> ORDER BY term does not match any column in
the result set`. Tests use no other expressions as `ORDER BY` terms of a compound select. The result's column names are those of the first
simple-select. A compound select may appear wherever a select may (subqueries, `FROM`, views, `WITH`,
`INSERT ... SELECT`).

## 5.2 WITH

```
WITH [RECURSIVE] cte [, cte]... select
cte := name [( column [, column]... )] AS ( select )
```

Each cte is a temporary named source, visible in the ctes after it and anywhere in the statement's
select (including its subqueries); it hides a table of the same name. Tests do not refer to a later
cte, nor mention a cte's own name inside it except in a recursive cte. Its columns are named by the
list, else as for a subquery source (4.1). Two ctes of one name are `duplicate WITH table name:
<name>`.

**Recursive cte** (only after `WITH RECURSIVE`): a cte whose select is `initial UNION [ALL]
recursive`, where initial is one simple-select that does not mention the cte and recursive is one
simple-select whose `FROM` mentions the cte exactly once (not inside a subquery). It is computed
with a queue: run initial and put its rows in the queue; then, while the queue is not empty, take
its first row, add it to the result, and run recursive with the cte standing for that single row,
putting its rows at the end of the queue. With `UNION` (not `ALL`), a row equal to a row already put
in the queue earlier is not put in again. The cte's rows are in the order they were added to the
result (so `group_concat` over a recursive cte without `ORDER BY` is well defined); for every other
source the order stays unspecified. Tests always terminate.

## 5.3 Views

```
CREATE VIEW [IF NOT EXISTS] name [( column [, column]... )] AS select ;
DROP VIEW [IF EXISTS] name ;
```

A view is a named select, run anew wherever the view is used as a source (it sees the tables as they
are then). Its column names are the list, else as for a subquery source. Tables and views share one
name space: creating a table or view whose name is taken is `table <name> already exists` if a
table has it and `view <name> already exists` if a view has it. A view cannot be changed:
`INSERT`/`UPDATE`/`DELETE` on it is `cannot modify <name> because it is a view`. `DROP TABLE` of a
view is `use DROP VIEW to delete view <name>`; `DROP VIEW` of a table is `use DROP TABLE to delete
table <name>`; in these three messages `<name>` is spelled as created, not as written. `DROP VIEW` of
nothing is `no such view: <name>`. `CREATE VIEW` does not check its select: an error in it (an
unknown column, a compound with mismatched counts) is reported by each statement that uses the view.
A table or view may not take an index's name: `there is already an index named <name>`.
A column of a view, cte or subquery source that is a plain column reference keeps that column's
affinity (1.9), so `v.a = '5'` is true for a view column `a` over an INTEGER column holding 5; tests do
not depend on the affinity of a compound select's columns. Tests do not drop, rename or change a
table that a view still uses.

## 5.4 INSERT ... SELECT

```
INSERT INTO table [( column [, column]... )] select ;
```

Inserts the select's rows, exactly as if they had been written as `VALUES` rows (same count errors,
storage, constraints and all-or-nothing). The select is fully computed before any row is inserted.
`WITH` may also start an `INSERT` (`WITH c AS (...) INSERT INTO t SELECT ... FROM c`).

## 5.5 Transactions

```
BEGIN [TRANSACTION] ;     COMMIT [TRANSACTION] ;     END [TRANSACTION] ;     ROLLBACK [TRANSACTION] ;
```

`BEGIN` starts a transaction (inside one: `cannot start a transaction within a transaction`).
`COMMIT` (or `END`) ends it, keeping its changes (with none open: `cannot commit - no transaction is
active`). `ROLLBACK` ends it and undoes every change made since `BEGIN`, including tables, views and
indexes created, dropped or altered (with none open: `cannot rollback - no transaction is active`).
A statement that fails inside a transaction has no effect, and the transaction stays open. A
transaction still open at the end of the script is simply left; it prints nothing.

## 5.6 ALTER TABLE

```
ALTER TABLE table ADD [COLUMN] column-def ;
ALTER TABLE table RENAME TO new-name ;
ALTER TABLE table RENAME [COLUMN] column TO new-name ;
```

- `ADD COLUMN` appends a column; existing rows get its `DEFAULT` value converted to the column's type
  as by 1.5 (`TEXT DEFAULT 7` gives `'7'`), or NULL. `NOT NULL` without a non-NULL `DEFAULT` is
  `Cannot add a NOT NULL column with default value NULL` if the table has rows (on an empty table it
  is allowed); `UNIQUE` is `Cannot
  add a UNIQUE column`; `PRIMARY KEY` is `Cannot add a PRIMARY KEY column`; an existing name is
  `duplicate column name: <name>`.
- `RENAME TO` renames the table (a taken name: `there is already another table or index with this
  name: <new-name>`); its constraints and indexes follow it.
- `RENAME COLUMN` renames a column (one the table does not have: `no such column: "<column>"`, with the
  double quotes); constraints and indexes follow it. Tests do not rename a column to a name the table
  already has.
- An unknown table is `no such table: <name>`. Error messages name tables and columns by their current
  names.

## 5.7 Indexes

```
CREATE [UNIQUE] INDEX [IF NOT EXISTS] name ON table ( column [, column]... ) ;
DROP INDEX [IF EXISTS] name ;
```

An index changes no result. A `UNIQUE` index is a uniqueness constraint (2.1) on its columns, declared
after every constraint that exists when it is created (so it is checked before them); creating it
on rows that already conflict is the constraint's error (`UNIQUE constraint failed: t.a, t.b` with the
index's columns) and creates nothing. Index names have their own name space, except that an index may
not take a table's name: `index <name> already exists`, `there is already a table named <name>`,
`no such index: <name>`. `IF NOT EXISTS` suppresses only `index <name> already exists`; the
other errors still occur. Dropping a table drops its indexes.

## 5.8 Errors added in this stage

`SELECTs to the left and right of <op> do not have the same number of result columns`;
`<i-th> ORDER BY term does not match any column in the result set`; `duplicate WITH table name: <name>`;
`view <name> already exists`; `cannot modify <name> because it is a view`;
`use DROP VIEW to delete view <name>`; `use DROP TABLE to delete table <name>`; `no such view: <name>`;
`cannot start a transaction within a transaction`; `cannot commit - no transaction is active`;
`cannot rollback - no transaction is active`; `Cannot add a NOT NULL column with default value NULL`;
`Cannot add a UNIQUE column`; `Cannot add a PRIMARY KEY column`;
`there is already another table or index with this name: <name>`; `no such column: "<column>"`;
`index <name> already exists`; `there is already a table named <name>`; `no such index: <name>`;
`there is already an index named <name>`.

# Stage 6: window functions

## 6.1 Syntax

```
window-call := name ( [expr [, expr]...] | * ) OVER ( window-spec ) | name ( ... ) OVER window-name
window-spec := [base-window-name] [PARTITION BY expr [, expr]...] [ORDER BY ordering-term [, ...]] [frame]
frame := (ROWS | RANGE) frame-start | (ROWS | RANGE) BETWEEN frame-start AND frame-end
frame-start, frame-end := UNBOUNDED PRECEDING | n PRECEDING | CURRENT ROW | n FOLLOWING | UNBOUNDED FOLLOWING
SELECT ... [HAVING ...] [WINDOW window-name AS ( window-spec ) [, ...]] [ORDER BY ...] [LIMIT ...]
```

`frame-start` alone means `BETWEEN frame-start AND CURRENT ROW`. n is an integer literal (a
negative one only appears in tests as `-n`, for the errors in 6.2).
A named window (`WINDOW w AS (...)`) can be used as `OVER w`, or as the base of a window-spec
(`OVER (w ORDER BY x)`), which adds to it the parts it does not have (tests add only `ORDER BY` and
a frame to a base that has neither); an unknown name is `no such window: <name>`. Window names are
unquoted identifiers, distinct within one `WINDOW` clause. In a compound select (5.1) each
simple-select has its own `WINDOW` clause, visible only in that simple-select.

Inside a window-spec, `PARTITION BY` and `ORDER BY` terms are plain expressions over the query's
sources: an integer literal there is a constant (not a result column number) and a result column's
alias is not visible.

## 6.2 Where they run

Window calls may appear only in the result columns and the `ORDER BY` of a `SELECT` (also inside
other expressions there, such as `abs(row_number() OVER (...))` or `rank() OVER (...) * 10`). In
`WHERE`, `GROUP BY` or `HAVING`, or inside the arguments of an aggregate or window call, a window
call is `misuse of window function <name>()`. A name in `WHERE` that is the alias of a result column
containing a window call is `misuse of aliased window function <alias>`. They are computed after `WHERE`, `GROUP BY` and `HAVING`, over the rows that the query
would otherwise produce (one per group in an aggregate query, where a window's expressions may use
aggregate calls, e.g. `rank() OVER (ORDER BY sum(x) DESC)`), and before `DISTINCT`, the final
`ORDER BY`, `LIMIT` and `OFFSET`.

For each window call: the rows are divided into **partitions** by the `PARTITION BY` values (equal
as in `GROUP BY`; one partition without it), and each partition is sorted by the window's `ORDER BY`
(rows that tie are **peers**; without `ORDER BY`, all rows of the partition are peers and their order
is unspecified: tests then use only functions that do not depend on it). Each row's result depends on
its partition, its position, and its **frame**, a range of rows of the partition:

- Without a frame clause: with `ORDER BY`, from the partition's first row to the current row's last
  peer; without `ORDER BY`, the whole partition.
- `ROWS`: positions. `n PRECEDING`/`n FOLLOWING` are the row n positions before/after the current
  row (clipped to the partition), `CURRENT ROW` is the current row, `UNBOUNDED` the partition's
  first/last row.
- `RANGE`: peers and values. `CURRENT ROW` as a start means the current row's first peer, as an end
  its last peer. `n PRECEDING`/`n FOLLOWING` require exactly one `ORDER BY` term (else `RANGE with
  offset PRECEDING/FOLLOWING requires one ORDER BY expression`) and mean the first/last row whose
  value of that term is within n below/above the current row's value (with `DESC`, above/below);
  rows whose term is NULL are within any range of a NULL current value only. Tests use numeric terms.
- A frame whose start is `CURRENT ROW` and end is `n PRECEDING`, or whose start is `n FOLLOWING` and
  end is `CURRENT ROW` or `n PRECEDING`, is `unsupported frame specification` (this includes a
  start alone of `n FOLLOWING`). Otherwise a frame whose start comes after its end (`ROWS BETWEEN 1
  PRECEDING AND 2 PRECEDING`, `ROWS BETWEEN 2 FOLLOWING AND 1 FOLLOWING`) is empty.
- A negative offset is, under `ROWS`, `frame starting offset must be a non-negative integer` or
  `frame ending offset must be a non-negative integer`; under `RANGE`, the same with `number` in
  place of `integer`. A start of `UNBOUNDED FOLLOWING` or an end of `UNBOUNDED PRECEDING` does not
  occur in tests.

## 6.3 Window functions

The aggregates of 3.2 (`count`, `sum`, `total`, `avg`, `min`, `max`, `group_concat`, without
`DISTINCT` or an inner `ORDER BY`) used with `OVER` compute over the frame, adding the frame's rows
in partition order. In addition:

| function | result for the current row (positions are 1-based within the partition) |
|---|---|
| `row_number()` | its position |
| `rank()` | the position of its first peer (1 without `ORDER BY`) |
| `dense_rank()` | the number of distinct peer groups up to and including its own |
| `percent_rank()` | (rank - 1) / (rows in partition - 1) as REAL; 0.0 for a one-row partition |
| `cume_dist()` | (position of its last peer) / (rows in partition) as REAL |
| `ntile(n)` | the bucket 1..n of the row when the partition's rows, in order, are split into n buckets whose sizes differ by at most 1, larger buckets first; n NULL, zero or negative is `argument of ntile must be a positive integer` (tests use integer n) |
| `lag(x)`, `lag(x, k)`, `lag(x, k, d)` | x evaluated on the row k positions earlier in the partition (k defaults to 1; a negative k means -k positions later; a NULL k gives NULL), or else d (default NULL) evaluated on the current row |
| `lead(x)`, `lead(x, k)`, `lead(x, k, d)` | the same, k positions later |
| `first_value(x)`, `last_value(x)` | x on the frame's first / last row; NULL if the frame is empty |
| `nth_value(x, n)` | x on the frame's n-th row; NULL if it has fewer rows; n not a positive integer is `second argument to nth_value must be a positive integer` |

`rank`, `dense_rank`, `percent_rank`, `cume_dist`, `ntile`, `row_number`, `lag` and `lead` ignore the
frame. Calling one of these names without `OVER` is `misuse of window function <name>()` (for the
names that are not also aggregates). Tests do not use `OVER` with other functions, `DISTINCT` in a
window aggregate, or a window-spec that overrides its base's `PARTITION BY` or `ORDER BY`.

## 6.4 Errors added in this stage

`misuse of window function <name>()`; `misuse of aliased window function <alias>`; `no such window: <name>`;
`unsupported frame specification`; `frame starting offset must be a non-negative number`;
`frame ending offset must be a non-negative number`; `second argument to nth_value must be a positive integer`;
`RANGE with offset PRECEDING/FOLLOWING requires one ORDER BY expression`;
`frame starting offset must be a non-negative integer`; `frame ending offset must be a non-negative
integer`; `argument of ntile must be a positive integer`.
