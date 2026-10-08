# Change: BLOB values

This change adds a fifth value type, BLOB (a string of bytes), with a literal, a column type, a `CAST`
target and one new function, `hex`. Everything not stated here stays as in stages 1-6; where those
stages list the types (NULL, INTEGER, REAL, TEXT), BLOB is now one more.

## 7.1 The BLOB literal and printing

```
literal := ... | blob-literal
blob-literal := X'<hex digits>' | x'<hex digits>'
```

A blob literal is the letter `X` or `x` immediately followed by a single-quoted run of hexadecimal
digits (`0-9`, `a-f`, `A-F`; case does not matter), an even number of them, two per byte:
`X'4142'` is the two bytes 0x41 0x42, `x'ff00'` = `X'FF00'`, and `X''` is the empty blob (zero bytes).
A blob literal with an odd number of digits, or with any other character between the quotes
(`X'414'`, `X'4G'`, `X'41 42'`), is the error `syntax error` (for the whole statement, as in 1.2). In
tests the `X` is always directly followed by the quote. Like a string literal, a blob literal is
skipped when looking for the `;` that ends a statement.

A BLOB prints (1.3) as `X'`, then two uppercase hexadecimal digits per byte, then `'`:
`SELECT x'0aff', X'';` prints `X'0AFF'|X''`.

**Text form of a BLOB.** Where a value is turned into text (concatenation, text functions,
`CAST ... AS TEXT`, numeric prefix), a BLOB's text form is its bytes read as characters: `X'414243'`
is `'ABC'`. Tests turn a BLOB into text only when all its bytes are printable ASCII (0x20 to 0x7E),
so its number of bytes and its number of characters agree.

## 7.2 typeof

`typeof(x)` of a BLOB is `'blob'` (also for `X''`).

## 7.3 Order of values and comparison

The order of values (1.9) becomes: NULL < every number < every TEXT < every BLOB. Two BLOBs compare
byte by byte as unsigned bytes; when one is a prefix of the other, the shorter comes first
(`X'' < X'00'`, `X'01' < X'0100'`, `X'0001' < X'01'`, `X'7F' < X'80'`). Two BLOBs are equal only
when they have the same bytes; a BLOB never equals a TEXT or a number, even with the same bytes
(`X'41' = 'A'` is 0, `X'41' > 'zz'` is 1, `99 < X'00'` is 1).

Affinity (1.9) never converts a BLOB: in rules 1 and 2 only TEXT and numbers are converted, so
`i = X'3132'` is 0 for an INTEGER column `i` holding 12, and `s = X'41'` is 0 for a TEXT column `s`
holding `'A'`. A BLOB column and a `CAST(x AS BLOB)` expression have no affinity.

This applies everywhere values are compared: `= == != <> < <= > >=`, `IS`, `IS NOT`, `BETWEEN`
(`X'05' BETWEEN 1 AND 'z'` is 0), join conditions, and everything listed in 7.4 to 7.7. NULL rules
are unchanged (`NULL < X'00'` is NULL, `X'' IS NULL` is 0).

## 7.4 Sorting, grouping, distinct rows

`ORDER BY` sorts BLOBs by 7.3 (after every TEXT under `ASC`, before every TEXT under `DESC`; NULL
placement unchanged). `GROUP BY`, `SELECT DISTINCT`, `count(DISTINCT x)`, `PARTITION BY` and the
compound operators `UNION`, `INTERSECT`, `EXCEPT` treat two BLOBs as equal exactly when they have
the same bytes; a BLOB and a TEXT with the same bytes (`X'41'`, `'A'`) are different values.

## 7.5 IN, CASE, coalesce, ifnull, nullif

- `x IN (...)` and `x IN (select)` compare by 7.3: `X'01' IN (X'02', X'01')` is 1,
  `X'41' IN ('A')` is 0, `X'01' IN (NULL, X'02')` is NULL. Affinity conversion of the list (2.3)
  never changes a BLOB.
- `CASE x WHEN v ...` matches a BLOB x only with a BLOB v of the same bytes.
- `coalesce`, `ifnull` and `nullif` return a BLOB argument unchanged; `nullif(x, y)` gives NULL only
  when x and y are equal by 7.3 (`nullif(X'41', 'A')` is `X'41'`).

## 7.6 Storage: the BLOB column type

```
type := INTEGER | REAL | TEXT | BLOB
default-value := [+ | -] numeric-literal | string-literal | blob-literal | NULL
```

`BLOB` is a column type (in `CREATE TABLE` and `ALTER TABLE ... ADD COLUMN`). Storing a value (1.5,
by `INSERT`, `INSERT ... SELECT` and `UPDATE`) now goes:

- BLOB column: NULL and a BLOB are stored unchanged. Nothing is converted: TEXT is not parsed as a
  number (step 2 of 1.5 does not apply), and every INTEGER, REAL or TEXT is rejected.
- INTEGER, REAL or TEXT column: a BLOB is rejected (it is never converted).

The rejection message is `cannot store <T> value in <C> column <table>.<column>` as in 1.5, where
`<C>` may now be `BLOB` and `<T>` is `BLOB` for a BLOB, `TEXT`, `REAL`, and, for an INTEGER value,
**`INT`** (not `INTEGER`): `INSERT INTO t (b) VALUES (1);` with `b BLOB` is
`cannot store INT value in BLOB column t.b`; `INSERT INTO t (b) VALUES ('12');` is
`cannot store TEXT value in BLOB column t.b`; `INSERT INTO t (s) VALUES (X'41');` with `s TEXT` is
`cannot store BLOB value in TEXT column t.s`. A BLOB stored into an INTEGER PRIMARY KEY is
`datatype mismatch` (2.1, "any other value"). The order of checks of 2.1 is unchanged (the BLOB rule
is part of "storage conversion").

`NOT NULL`, `UNIQUE`, `PRIMARY KEY` and `UNIQUE` indexes work on BLOB columns with BLOB equality
(7.3): `X'AA'` and `x'aa'` conflict; `X'01'` and `X'0100'` do not.

**DEFAULT.** A default may be a blob literal (`b BLOB DEFAULT X'CAFE'`). The default is stored by the
rules above when an `INSERT` uses it, so a default the column cannot store is reported then, not by
`CREATE TABLE` (`c BLOB DEFAULT 'x'`: an `INSERT` that leaves out c is
`cannot store TEXT value in BLOB column t.c`; `e TEXT DEFAULT X'41'` likewise gives
`cannot store BLOB value in TEXT column t.e`). `ALTER TABLE ... ADD COLUMN b BLOB DEFAULT X'00'`
gives existing rows that BLOB. Tests do not use `ALTER TABLE ... ADD COLUMN` with a default the new
column cannot store.

## 7.7 Aggregates and window functions

- `count(x)` counts BLOBs like any non-NULL value. `min(x)` and `max(x)`, as aggregates and as the
  scalar functions of 2.4, use the order of 7.3: a BLOB is larger than every number and TEXT
  (`max(X'41', 'zz', 5)` is `X'41'`, `min(X'41', 'zz', 5)` is 5).
- Window functions (stage 6) pass BLOBs through like other values: `PARTITION BY` and the window's
  `ORDER BY` use 7.3 and 7.4; `lag`, `lead`, `first_value`, `last_value`, `nth_value` and `min`/`max`
  over a frame return the BLOB itself.
- `group_concat` joins the text forms (7.1) of BLOB values (and of a BLOB separator); the result is
  TEXT.
- `sum`, `total` and `avg`: see 7.8.

## 7.8 BLOBs as numbers

Wherever TEXT is read as a number by numeric prefix (1.8: arithmetic, unary minus, truth values of
1.10, `abs`, `round`), a BLOB is read the same way from its text form: `X'3132' * 2` is 24 (INTEGER),
`-X'3132'` is -12, `X'41' + 1` is 1, `abs(X'3132')` is 12.0, `round(X'3132')` is 12.0. As a truth
value, `X'31'` is true and `X'30'`, `X'41'` and `X''` are false.

In `sum`, `total` and `avg` (3.2), a BLOB always counts as a non-INTEGER value, read by numeric
prefix of its text form, so `sum` is REAL as soon as one BLOB is summed: `sum` over the single value
`X'3132'` is `12.0`. (Unlike TEXT, a BLOB holding the bytes of an integer literal is not counted as
an INTEGER.)

## 7.9 CAST

```
CAST(x AS type)    type := INTEGER | REAL | TEXT | BLOB
```

- **From a BLOB** (to INTEGER, REAL, TEXT): exactly as from the TEXT that is its text form (2.3):
  `CAST(X'3132' AS INTEGER)` = 12, `CAST(X'2D33' AS INTEGER)` = -3, `CAST(X'7A' AS INTEGER)` = 0,
  `CAST(X'312E35' AS REAL)` = 1.5, `CAST(X'' AS REAL)` = 0.0, `CAST(X'414243' AS TEXT)` = `'ABC'`
  (TEXT).
- **To BLOB**: NULL stays NULL; a BLOB is unchanged; TEXT becomes the BLOB of its bytes
  (`CAST('abc' AS BLOB)` = `X'616263'`, `CAST(' 7 ' AS BLOB)` = `X'203720'`); an INTEGER or REAL
  becomes the BLOB of the bytes of its text form (`CAST(12 AS BLOB)` = `X'3132'`,
  `CAST(-2 AS BLOB)` = `X'2D32'`, `CAST(1.5 AS BLOB)` = `X'312E35'`). The result has no affinity.

## 7.10 Functions on BLOBs

| function | with a BLOB argument |
|---|---|
| `length(x)` | INTEGER: the number of bytes of the BLOB (`length(X'00FF')` = 2, `length(X'')` = 0) |
| `hex(x)` | **new**, see below |
| `substr(x, start)`, `substr(x, start, len)` | if x is a BLOB: a BLOB, the bytes selected by 2.4's rules with L = the number of bytes (`substr(X'41424344', 2, 2)` = `X'4243'`, `substr(X'41424344', -1)` = `X'44'`, `substr(X'4142', 5)` = `X''`) |
| `instr(x, y)` | if x and y are both BLOBs: the 1-based byte position of the first occurrence of y's bytes in x's, or 0 (`instr(X'41424344', X'4243')` = 2); otherwise as in 2.4 on text forms (`instr(X'414243', 'B')` = 2) |
| `upper(x)`, `lower(x)`, `trim`, `ltrim`, `rtrim`, `replace` | as in 1.11 / 2.4 on the text form of each BLOB argument; the result is TEXT (`upper(X'616263')` = `'ABC'`, `replace(X'41424142', X'42', X'5A')` = `'AZAZ'`) |
| `x \|\| y` | as in 1.8 on text forms; the result is TEXT, also for two BLOBs (`X'41' \|\| X'42'` = `'AB'`, `1 \|\| X'41'` = `'1A'`); NULL if either is NULL |

**hex(x)** (exactly one argument, else `wrong number of arguments to function hex()`): TEXT, two
uppercase hexadecimal digits for each byte. For a BLOB, its bytes: `hex(X'0aff')` = `'0AFF'`,
`hex(X'')` = `''`. For any other value, the bytes of its text form: `hex('abc')` = `'616263'`,
`hex(12)` = `'3132'`, `hex(-5)` = `'2D35'`, `hex(1.5)` = `'312E35'`. Unlike other functions, a NULL
argument does not give NULL: `hex(NULL)` is the empty TEXT `''`.

`LIKE` with a BLOB operand does not occur in tests.

## 7.11 Errors

The only new message is the storage error with the new names: `cannot store <T> value in <C> column
<table>.<column>` with `<T>` one of `INT`, `REAL`, `TEXT`, `BLOB` and `<C>` one of `INTEGER`, `REAL`,
`TEXT`, `BLOB` (7.6). A malformed blob literal is `syntax error`.

## Where it applies

- literal: `X'..'` / `x'..'` is a BLOB literal (even number of hex digits, else `syntax error`), and a BLOB prints as `X'` + uppercase hex + `'` (7.1). (public)
- typeof: `typeof` of a BLOB is `'blob'` (7.2). (public)
- compare: comparison operators, `IS` and `BETWEEN` order NULL < numbers < TEXT < BLOB, compare BLOBs bytewise, and never convert a BLOB by affinity (7.3). (public)
- order-by: `ORDER BY` sorts BLOBs after TEXT, bytewise among themselves (7.4). (public)
- distinct: `GROUP BY`, `SELECT DISTINCT` and `count(DISTINCT x)` treat BLOBs as equal only to BLOBs of the same bytes (7.4).
- compound: `UNION`, `INTERSECT` and `EXCEPT` treat BLOBs as equal only to BLOBs of the same bytes (7.4).
- in: `IN` lists and `IN (select)` match a BLOB only with a BLOB of the same bytes (7.5).
- case: `CASE x WHEN v` matches a BLOB x only with a BLOB v of the same bytes (7.5).
- coalesce: `coalesce`, `ifnull` and `nullif` pass BLOBs through and `nullif` compares by 7.3 (7.5).
- store: a BLOB column stores only BLOBs and NULL, other columns reject BLOBs, with `cannot store <T> value in <C> column` and `INT` for integers (7.6). (public)
- unique: `UNIQUE`, `PRIMARY KEY`, `NOT NULL` and unique indexes on BLOB columns use BLOB equality (7.6).
- default: `DEFAULT X'..'` supplies a BLOB, and a default the column cannot store fails at `INSERT` (7.6).
- min-max: `count`, aggregate and scalar `min`/`max` treat a BLOB as larger than every number and TEXT (7.7).
- window: window functions partition, order and return BLOBs like other values (7.7).
- numbers: arithmetic, truth values, `abs`, `round`, `sum`, `total` and `avg` read a BLOB by numeric prefix of its text form, and `sum` treats it as non-INTEGER (7.8).
- cast-to-blob: `CAST(x AS BLOB)` gives the bytes of a TEXT or of a number's text form (7.9). (public)
- cast-from-blob: `CAST` of a BLOB to INTEGER, REAL or TEXT works as on its text form (7.9).
- length: `length` of a BLOB is its number of bytes (7.10).
- hex: `hex(x)` is the uppercase hex of a BLOB's bytes or of another value's text form, and `''` for NULL (7.10). (public)
- substr: `substr` of a BLOB is a BLOB selected by byte positions (7.10).
- instr: `instr` of two BLOBs searches bytes (7.10).
- text-functions: `||`, `upper`, `lower`, `trim`, `replace` and `group_concat` use a BLOB's text form and give TEXT (7.1, 7.7, 7.10).
