# Change: collating sequences

This change adds **collations**: rules for comparing two TEXT values. From now on, every comparison of
two TEXT values that the engine makes, whatever it makes it for (deciding a condition, putting values in
order, deciding which values are the same, picking the smallest or largest), is made under a collation,
chosen as below. Without any `COLLATE` in a script, every collation is `BINARY` and every result is as
before.

## 7.1 The three collations

| name | two TEXT values compare as |
|---|---|
| `BINARY` | byte by byte, as in 1.9 (the default) |
| `NOCASE` | byte by byte after changing the ASCII letters `A`-`Z` of both to lower case (`a`-`z`) |
| `RTRIM` | byte by byte after removing trailing spaces (only the character space) from both |

So under `NOCASE`, `'abc' = 'ABC'` and `'_' < 'A'` (since `'A'` compares as `'a'`, and `_` is below
`a`; under `BINARY` `'A' < '_'`). Under `RTRIM`, `'x  ' = 'x'`, `'' = '   '`, `'ab' < 'ab  c'`,
while `'x' = ' x'` is still false (leading spaces count, and so does any trailing character other
than space, such as a tab).

A collation affects only the comparison of two TEXT values. A comparison where either side is NULL or
a number is exactly as in 1.9 (NULL < numbers < TEXT, numbers by value), and affinity conversions
(1.9) happen first, as before. Values are never changed: a collation decides only which values are
equal and which comes first. Wherever values that are equal under a collation but differ in their
text are treated as the same (one of them is kept, or they fall together), which of them is kept or
shown is unspecified, as for equal values before; tests print such values only through something that
does not depend on the choice (`lower(name)`, `count(*)`).

## 7.2 Syntax

`COLLATE` becomes a keyword (add it to the list in 1.2). A collation name is an identifier, matched
case-insensitively (`nocase`, `NoCase`, `NOCASE` are the same collation); tests write it unquoted.

```
column-constraint := ... | COLLATE collation-name          (2.1; wherever a column is defined)
expr := ... | expr COLLATE collation-name                    (postfix)
indexed-column := column [COLLATE collation-name]            (CREATE [UNIQUE] INDEX ... ON t (indexed-column [, ...]))
```

- **Column collation.** `COLLATE n` may appear among a column's constraints, in any position, in every
  statement that defines a column (`name TEXT COLLATE NOCASE NOT NULL`, `name TEXT UNIQUE COLLATE
  NOCASE`, `tag TEXT COLLATE NOCASE DEFAULT 'x'`). The column then has collation n from then on; a
  column without it has `BINARY`. Tests give a column at most one `COLLATE`, and give `COLLATE` only
  to TEXT columns.
- **`e COLLATE n`** is a postfix operator that binds tighter than every binary operator: in
  `a || b COLLATE NOCASE` it applies to `b`, and `a = b COLLATE NOCASE` is `a = (b COLLATE NOCASE)`.
  Tests do not write it directly after a unary operator expression (`-x COLLATE ...`, `NOT x COLLATE
  ...`), nor two in a row. Its value is e's value, and it has e's affinity (1.9): with `i` an INTEGER
  column, `i COLLATE NOCASE = '12'` is true when `i` is 12. Anywhere an expression is accepted, and
  wherever a term may name a result column by number or alias (1.7), the term may be followed by
  `COLLATE n` (see 7.4).
- **Unknown name.** A collation name other than the three is the error
  `no such collation sequence: <name>` (spelled as written). In a column definition or an index
  column, the statement fails and creates or adds nothing. In an expression, tests write an unknown
  name only as the `COLLATE` of a direct operand of a comparison or of a sort term; the statement then
  fails before reading any row (also on an empty table).

## 7.3 The collation of an expression

Every expression has either an **explicit** collation, an **implicit** collation, or none:

- `e COLLATE n`: explicit n.
- A column reference (possibly qualified, possibly in parentheses), to a column of any source:
  implicit, the column's collation (`BINARY` if it declares none). For a column of a source that is
  defined by a select (7.5), that is the collation given to it there.
- `( e )`, `+e` and `CAST(e AS type)`: the same as e (explicit stays explicit, implicit stays
  implicit). So `+name = 'X'` and `CAST(name AS TEXT) = 'X'` use the column collation of `name`,
  although `+name` has no affinity.
- A scalar subquery `( select )`: none, whatever its result column is, even when that result column
  has an explicit `COLLATE`. (So `(SELECT name FROM t WHERE id = 1) = 'ABC'` uses BINARY even though
  `name` is NOCASE.)
- Every other expression (literals, `||` and other operators, function calls, `CASE`, aggregates):
  none. Tests do not compare such an expression when it contains a `COLLATE` inside it (as in
  `'x' || 'A' COLLATE NOCASE` or `lower(b COLLATE NOCASE)`); `upper(name)`, `name || ''` and
  `lower(b)` simply have no collation.

## 7.4 Which collation is used

**Two expressions compared with each other.** When two expressions a and b are compared, by a
comparison operator `= == != <> < <= > >= IS IS NOT` or by any construct that the earlier stages
define as such a comparison `a op b` (the definition fixes which side is a and which is b):

1. if a has an explicit collation, that one; else if b has an explicit collation, that one;
2. else if a has an implicit collation, that one; else if b has one, that one;
3. else `BINARY`.

So with `name TEXT COLLATE NOCASE` and `code TEXT` (BINARY): `name = 'ABC'` and `'ABC' = name` use
NOCASE; `name = code` uses NOCASE but `code = name` uses BINARY; `code = name COLLATE RTRIM` uses
RTRIM; `name COLLATE BINARY = 'ABC'` uses BINARY. Since `x BETWEEN a AND b` is `x >= a AND x <= b`
(2.3), each half chooses separately: `code BETWEEN 'a' COLLATE NOCASE AND 'C'` uses NOCASE for the
lower bound and BINARY for the upper.

Two membership tests are exceptions to "as `x = e`":

- **`x [NOT] IN (e1, e2, ...)`**: only x counts, as for affinity in 2.3: x's collation (explicit or
  implicit), else `BINARY`, whatever the ei are. So `'ABC' IN (name)` is 0 for a NOCASE column
  holding `'abc'`, while `name IN ('ABC')` is 1. Tests do not write `COLLATE` on an ei.
- **`x [NOT] IN (select)`**: each comparison is as `x = e`, where e is the subquery's result column
  expression as written in the subquery (with its explicit or implicit collation there, not as a
  scalar subquery). So `'ABC' IN (SELECT name FROM t)` uses NOCASE, `code IN (SELECT name FROM t)`
  uses BINARY, and `code IN (SELECT upper(code) COLLATE NOCASE FROM t)` uses NOCASE.

**The values of one expression compared among themselves.** Whenever the values of a single
expression (a term, an argument) are compared with each other (to put them in order, to decide which
are the same, or to find the smallest or largest), TEXT values are compared under that expression's
collation (explicit or implicit), else `BINARY`. Values equal under it are the same value for that
purpose: they tie in an order (direction and later terms decide as before; rows that tie on everything
still come out in any order), fall together where same values are put together, and count once where
distinct values are counted. So `count(DISTINCT name)` counts `'Ann'` and `'ANN'` once for a NOCASE
column, as does `count(DISTINCT code COLLATE NOCASE)`, and `max(name)` over `'delta'`, `'Echo'` is
`'Echo'`. Tests use `DISTINCT` inside an aggregate together with a collation only in `count`, and do
not depend on which of two values equal under the collation a smallest/largest returns.

A term that stands for a result column (an integer literal k, or a result column's alias, 1.7) has
the collation of that result column's expression; followed by `COLLATE n` (`2 COLLATE NOCASE`,
`k COLLATE NOCASE`) it means that result column under n.

**Whole rows compared.** When two result rows are compared to decide whether they are the same, each
pair of values is compared under the collation of that result column.

- For a simple select, a result column's collation is that of its expression.
- For a compound select (5.1), the k-th column has the collation of the k-th result column of the
  first simple-select, left to right, whose k-th result column has a collation (explicit or implicit),
  else `BINARY`. This collation is used both when the compound compares rows and when the compound's
  rows are sorted by that column, unless the sort term has its own `COLLATE` (a sort term of a compound
  may be an integer literal or a name followed by `COLLATE n`). So `SELECT code FROM t UNION SELECT
  name FROM t` uses BINARY (`code` is a column), `SELECT 'X' UNION SELECT name FROM t` uses NOCASE.

**Stored values compared for uniqueness.** Whenever two stored values of a column are compared to
decide whether they violate uniqueness, they are compared under that column's collation; with
`email TEXT UNIQUE COLLATE NOCASE`, storing `'A@x'` next to `'a@x'` is `UNIQUE constraint failed:
t.email`. When uniqueness covers several columns, each column uses its own collation. This holds for
every way a row is stored or changed. A `UNIQUE` index uses, for each of its columns, the index
column's `COLLATE n` if it has one, else the column's collation (`CREATE UNIQUE INDEX i ON t (code
COLLATE NOCASE)` makes `'ab'` and `'AB'` conflict even though `code` is BINARY; `name COLLATE BINARY`
lets them coexist although `name` is NOCASE). Creating it on rows that already conflict under that
collation is the constraint's error. A non-unique index changes no result. (An INTEGER PRIMARY KEY
holds integers and is not affected.)

## 7.5 Collations that travel with columns

A column of a source defined by a select (5.2 view, 5.3 cte, 4.1 subquery in `FROM`) has, as an
implicit collation, the collation (explicit or implicit) of its result column expression in the select
that defines it, just as such a column keeps a plain column's affinity (4.1). So with `CREATE VIEW v AS
SELECT code COLLATE NOCASE AS k, name FROM t`, `v.k = 'ABC'` and `v.name = 'ABC'` use NOCASE; and
since `k` is now implicit, `code = v.k` uses BINARY (the left column wins) while `v.k = code` uses
NOCASE. A result column with no collation (`name || ''`, `upper(code)`) gives a column whose collation
is `BINARY` (implicit, so it wins as a left operand: `v.up = v.k` uses BINARY). A column renamed by a
column list keeps its collation. Tests do not depend on the collation of a column of a compound select
used as a source.

## 7.6 What does not change

`LIKE` ignores collations (it is already case-insensitive for ASCII; `'a ' LIKE 'a'` is still 0).
Functions other than the aggregates that compare their argument's values among themselves (`length`,
`upper`, `instr`, `replace`, `substr`, `trim`, ...) are unaffected. Tests do not pass a value with a
collation to `nullif` or to the scalar `min` and `max` of two or more arguments, nor use `COLLATE` in
`DEFAULT` values. Storage (1.5) and printing are unchanged.

## 7.7 Errors added by this change

`no such collation sequence: <name>`.
