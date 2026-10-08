# Change: more scalar functions

This change adds five scalar functions: `concat`, `concat_ws`, `char`, `unicode` and `sign`. They
are ordinary function calls (1.8, 1.11) and may appear wherever an expression may: result columns,
`WHERE`, `ORDER BY`, `GROUP BY`, `HAVING`, `SET`, `VALUES`, `ON`, subqueries, and the arguments and
window-specs of aggregate and window calls. Like every function, a name is case-insensitive
(`CONCAT`, `Sign`), and none of them is an aggregate or window function.

The general rule of 1.11 "a NULL argument gives NULL" does **not** apply to `concat`, `concat_ws`
and `char`; their NULL handling is given below. It applies to `unicode` and `sign`.

## C.1 The functions

| function | arguments | result |
|---|---|---|
| `concat(x1, x2, ...)` | one or more | TEXT: the text forms (1.3) of the arguments that are not NULL, joined in order with nothing between them. NULL arguments are skipped; if every argument is NULL the result is `''` (empty TEXT, never NULL). |
| `concat_ws(sep, x1, ...)` | two or more | NULL if sep is NULL. Otherwise TEXT: the text forms of the x arguments that are not NULL, joined in order with sep's text form between consecutive ones. NULL x arguments are skipped entirely (no separator is written for them); if every x is NULL the result is `''`. |
| `char(c1, c2, ...)` | zero or more | TEXT: the string whose characters have the code points c1, c2, ... in order; `char()` is `''`. |
| `unicode(x)` | exactly one | INTEGER: the code point of the first character of x's text form; NULL if x is NULL or its text form is `''`. |
| `sign(x)` | exactly one | INTEGER `-1`, `0` or `1` for a negative, zero or positive number, or NULL (below). |

Calling one of them with an argument count outside the one shown is the existing error
`wrong number of arguments to function <name>()` (1.11, `<name>` as written): `concat()`,
`concat_ws()`, `concat_ws(',')`, `unicode()`, `unicode('a', 'b')`, `sign()`, `sign(1, 2)`.
`char` accepts any number of arguments, including none. No other error is added.

**Text forms.** `concat` and `concat_ws` use the text form of 1.3 for numbers, as `||` does:
`concat(1, 2.0, 1e20)` is `'12.01.0e+20'`; `concat_ws(2.5, 'a', 'b')` is `'a2.5b'`. Unlike `||`,
a NULL operand does not make the result NULL: `concat('a', NULL, 'b')` is `'ab'` while
`'a' || NULL || 'b'` is NULL. `unicode` also reads its argument's text form: `unicode(5)` is 53
(the character `5`), `unicode(-3)` is 45 (`-`), `unicode(0.5)` is 48 (`0`).

**char.** Each argument is a code point (an INTEGER). Tests pass only INTEGER values from 32 to 126
(printable ASCII), never NULL, a REAL or TEXT: `char(72, 105)` is `'Hi'`, `char(unicode('a') + 1)`
is `'b'`.

**unicode.** Tests use ASCII text only, so the result is the ASCII code of the first character:
`unicode('abc')` is 97, `unicode(' x')` is 32, `unicode('')` is NULL.

**sign.** NULL gives NULL. An INTEGER or REAL gives `-1` if it is below zero, `0` if it equals zero,
`1` if above zero; the result is always INTEGER (`sign(-2.5)` is -1, `sign(0.0)` is 0). A TEXT x is
converted only if, after removing leading and trailing whitespace, it is a numeric literal with an
optional leading `+` or `-` (the test of 1.5 step 2): then its sign is that number's
(`sign(' -7.5 ')` is -1, `sign('1e3')` is 1, `sign('+0')` is 0). Any other TEXT gives NULL — not 0,
and not read by numeric prefix as arithmetic would: `sign('3x')`, `sign('abc')`, `sign('')`,
`sign('1e')` are all NULL.

**Results have no affinity** (1.9), as for every function call: `concat(1, 2) = 12` is 0 (TEXT
against INTEGER, nothing converted) and `concat(1, 2) = '12'` is 1. When such a result is compared
with a column, the column's affinity applies as usual (`i = concat(1, 2)` with `i` an INTEGER column
holding 12 is 1).

## C.2 Examples

```
SELECT concat('ab', NULL, 3, 'c');            -- ab3c
SELECT concat(NULL, NULL), typeof(concat(NULL));   -- |text
SELECT concat_ws('-', 2026, NULL, 'x');       -- 2026-x
SELECT concat_ws(NULL, 'a', 'b');             -- NULL
SELECT concat_ws(', ', NULL);                 -- (an empty line)
SELECT char(83, 81, 76), char();              -- SQL|
SELECT unicode('Zed'), unicode(''), unicode(7);   -- 90|NULL|55
SELECT sign(-4), sign(0), sign(0.25), sign('12'), sign('12abc');   -- -1|0|1|1|NULL
SELECT concat_ws('x');                        -- Error: wrong number of arguments to function concat_ws()
```

## Where it applies

- concat (public): `concat(x, ...)` joins the text forms of its non-NULL arguments, giving `''` when all are NULL; it needs at least one argument.
- concat_ws (public): `concat_ws(sep, x, ...)` joins the non-NULL x with sep between them, gives NULL for a NULL sep and `''` when all x are NULL; it needs at least two arguments.
- char: `char(c, ...)` builds TEXT from code points (`char()` is `''`), with any number of arguments.
- unicode: `unicode(x)` is the code point of the first character of x's text form, NULL for NULL or `''`; exactly one argument.
- sign (public): `sign(x)` is INTEGER -1, 0 or 1 for a number or for TEXT that is a numeric literal after trimming, NULL for NULL and other TEXT; exactly one argument.
