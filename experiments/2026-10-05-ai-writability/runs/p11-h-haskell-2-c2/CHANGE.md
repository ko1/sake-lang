# Change: BLOB values

This change adds a fifth value type, BLOB (a string of bytes), with a literal, a column type, a `CAST`
target and one new function, `hex`. Everything not stated here stays as in stages 1-6. Wherever
stages 1-6 list the value types (NULL, INTEGER, REAL, TEXT) or the type names (`INTEGER`, `REAL`,
`TEXT`), BLOB is now one more, and every rule of stages 1-6 that handles a value must handle a BLOB
by the rules below.

## 7.1 The BLOB value, its literal and its printed form

```
literal := ... | blob-literal
blob-literal := X'<hex digits>' | x'<hex digits>'
type := INTEGER | REAL | TEXT | BLOB
default-value := [+ | -] numeric-literal | string-literal | blob-literal | NULL
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

`typeof(x)` of a BLOB is `'blob'` (also for `X''`).

`BLOB` is a type name wherever a type name is written (a column's type, a `CAST` target).

**Text form of a BLOB.** The text form (1.3) of a BLOB is its bytes read as characters: `X'414243'`
is `'ABC'`. Tests turn a BLOB into text only when all its bytes are printable ASCII (0x20 to 0x7E),
so its number of bytes and its number of characters agree. Wherever a value is used through its
text form, a BLOB is used through this text form and the result is TEXT, never BLOB, even when
every input is a BLOB (`X'41' || X'42'` is the TEXT `'AB'`; `upper(X'616263')` is `'ABC'`). The
exceptions are only those of 7.6.

**A BLOB passes through.** Wherever a value is returned, stored, copied or carried along without
being converted, a BLOB stays the same BLOB (its type, `typeof` and printing are kept).

## 7.2 Order and equality of values

The order of values (1.9) becomes: NULL < every number < every TEXT < every BLOB. Two BLOBs compare
byte by byte as unsigned bytes; when one is a prefix of the other, the shorter comes first
(`X'' < X'00'`, `X'01' < X'0100'`, `X'0001' < X'01'`, `X'7F' < X'80'`). Two BLOBs are equal only
when they have the same bytes (`X'AA'` equals `x'aa'`; `X'01'` and `X'0100'` differ); a BLOB never
equals a TEXT or a number, even with the same bytes (`X'41' = 'A'` is 0, `X'41' > 'zz'` is 1,
`99 < X'00'` is 1).

This order and this equality are the only ones: every comparison of values, every test of two
values for equality (with or without affinity), every sort (ascending or descending; NULL
placement unchanged) and every choice of a smallest or largest value uses them. So a BLOB and a
TEXT with the same bytes are always two different values, and two BLOBs are the same value
exactly when their bytes are the same. NULL rules are unchanged (`NULL < X'00'` is NULL,
`X'' IS NULL` is 0).

## 7.3 A BLOB is never converted to fit a type

The conversions of stages 1-6 that turn a value into a number or into text so that it fits a
column's type or an affinity never apply to a BLOB, and nothing is ever converted into a BLOB by
them:

- **Affinity** (1.9 and every rule that applies it): only TEXT and numbers are converted; a BLOB is
  left as it is. So `i = X'3132'` is 0 for an INTEGER column `i` holding 12, and `s = X'41'` is 0 for
  a TEXT column `s` holding `'A'`. An expression of BLOB type (a BLOB column, `CAST(x AS BLOB)`) has
  no affinity.
- **The numeric-literal test** of 1.5 step 2 (is this TEXT, after trimming, a numeric literal?) is
  never applied to a BLOB: a BLOB holding the bytes of `12` is not the number 12 for any rule that
  uses that test. In particular, in the sums of 3.2 (`sum`, `total`, `avg`) a BLOB always counts as a
  non-INTEGER value, read by numeric prefix of its text form, so a `sum` is REAL as soon as one BLOB
  is summed: the `sum` of the single value `X'3132'` is `12.0`.

## 7.4 Storing a value (1.5)

Storing a value into a column now goes:

- BLOB column: NULL and a BLOB are stored unchanged. Nothing is converted: TEXT is not parsed as a
  number (step 2 of 1.5 does not apply), and every INTEGER, REAL or TEXT is rejected.
- INTEGER, REAL or TEXT column: a BLOB is rejected (it is never converted).

The rejection message is `cannot store <T> value in <C> column <table>.<column>` as in 1.5, where
`<C>` may now be `BLOB` and `<T>` is `BLOB` for a BLOB, `TEXT`, `REAL`, and, for an INTEGER value,
**`INT`** (not `INTEGER`): storing 1 into `b BLOB` is `cannot store INT value in BLOB column t.b`;
storing `'12'` there is `cannot store TEXT value in BLOB column t.b`; storing `X'41'` into `s TEXT`
is `cannot store BLOB value in TEXT column t.s`. A BLOB stored into an INTEGER PRIMARY KEY is
`datatype mismatch` (2.1, "any other value"). The order of checks of 2.1 is unchanged (the BLOB rule
is part of "storage conversion"), and so is the rule that a failing statement has no effect.

**Defaults.** A default may be a blob literal (`b BLOB DEFAULT X'CAFE'`). A default is stored by the
rules above each time it is used, so a default the column cannot store is reported when a row needs
it, not when the table is created (`c BLOB DEFAULT 'x'`: a row stored without c is
`cannot store TEXT value in BLOB column t.c`; `e TEXT DEFAULT X'41'` likewise gives
`cannot store BLOB value in TEXT column t.e`). Tests do not add a column, to a table that has rows,
with a default the new column cannot store.

## 7.5 BLOBs as numbers

Wherever TEXT is read as a number by numeric prefix (1.8), a BLOB is read the same way from its
text form, and the result is what that TEXT would give: `X'3132' * 2` is 24 (INTEGER), `-X'3132'` is
-12, `X'41' + 1` is 1, `abs(X'3132')` is 12.0, `round(X'3132')` is 12.0. As a truth value (1.10),
`X'31'` is true and `X'30'`, `X'41'` and `X''` are false. (The one exception, sums, is in 7.3.)

## 7.6 CAST and functions

```
CAST(x AS type)    type := INTEGER | REAL | TEXT | BLOB
```

- **CAST from a BLOB** (to INTEGER, REAL, TEXT): exactly as from the TEXT that is its text form
  (2.3): `CAST(X'3132' AS INTEGER)` = 12, `CAST(X'2D33' AS INTEGER)` = -3, `CAST(X'7A' AS INTEGER)`
  = 0, `CAST(X'312E35' AS REAL)` = 1.5, `CAST(X'' AS REAL)` = 0.0, `CAST(X'414243' AS TEXT)` =
  `'ABC'` (TEXT).
- **CAST to BLOB**: NULL stays NULL; a BLOB is unchanged; TEXT becomes the BLOB of its bytes
  (`CAST('abc' AS BLOB)` = `X'616263'`, `CAST(' 7 ' AS BLOB)` = `X'203720'`); an INTEGER or REAL
  becomes the BLOB of the bytes of its text form (`CAST(12 AS BLOB)` = `X'3132'`,
  `CAST(-2 AS BLOB)` = `X'2D32'`, `CAST(1.5 AS BLOB)` = `X'312E35'`). The result has no affinity.

Functions that work on an argument's text form follow 7.1 (they use a BLOB's text form and give
TEXT), and functions that read a number follow 7.5, except these three, which work on a BLOB's bytes:

| function | with a BLOB argument |
|---|---|
| `length(x)` | INTEGER: the number of bytes of the BLOB (`length(X'00FF')` = 2, `length(X'')` = 0) |
| `substr(x, start)`, `substr(x, start, len)` | if x is a BLOB: a BLOB, the bytes selected by 2.4's rules with L = the number of bytes (`substr(X'41424344', 2, 2)` = `X'4243'`, `substr(X'41424344', -1)` = `X'44'`, `substr(X'4142', 5)` = `X''`) |
| `instr(x, y)` | if x and y are both BLOBs: the 1-based byte position of the first occurrence of y's bytes in x's, or 0 (`instr(X'41424344', X'4243')` = 2); otherwise on text forms (`instr(X'414243', 'B')` = 2) |

**hex(x)** is new (exactly one argument, else `wrong number of arguments to function hex()`): TEXT,
two uppercase hexadecimal digits for each byte. For a BLOB, its bytes: `hex(X'0aff')` = `'0AFF'`,
`hex(X'')` = `''`. For any other value, the bytes of its text form: `hex('abc')` = `'616263'`,
`hex(12)` = `'3132'`, `hex(-5)` = `'2D35'`, `hex(1.5)` = `'312E35'`. Unlike other functions, a NULL
argument does not give NULL: `hex(NULL)` is the empty TEXT `''`.

`LIKE` with a BLOB operand does not occur in tests.

## 7.7 Errors

The only new message is the storage error with the new names: `cannot store <T> value in <C> column
<table>.<column>` with `<T>` one of `INT`, `REAL`, `TEXT`, `BLOB` and `<C>` one of `INTEGER`, `REAL`,
`TEXT`, `BLOB` (7.4). A malformed blob literal is `syntax error`.
