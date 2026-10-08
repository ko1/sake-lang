# A small SQL engine: specification, stages 1..1

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
  should be between 1 and 1`. Any other term (including `+1`) is an expression evaluated on the row.
  Tests do not put an `ORDER BY` term in parentheses, list a column twice in an `INSERT`, or give two
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
