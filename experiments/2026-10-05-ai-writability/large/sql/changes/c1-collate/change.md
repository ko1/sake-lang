# Change: collating sequences

This change adds **collations**: rules for comparing two TEXT values. Everything in stages 1-6 that
compares, sorts, groups or deduplicates TEXT values now does so under a collation, chosen as below.
Without any `COLLATE` in a script, every collation is `BINARY` and every result is as before.

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
equal and which comes first.

## 7.2 Syntax

`COLLATE` becomes a keyword (add it to the list in 1.2). A collation name is an identifier, matched
case-insensitively (`nocase`, `NoCase`, `NOCASE` are the same collation); tests write it unquoted.

```
column-constraint := ... | COLLATE collation-name          (stage 2, 2.1; also in ALTER TABLE ADD COLUMN)
expr := ... | expr COLLATE collation-name                    (postfix)
indexed-column := column [COLLATE collation-name]            (CREATE [UNIQUE] INDEX ... ON t (indexed-column [, ...]))
```

- **Column collation.** `COLLATE n` may appear among a column's constraints, in any position
  (`name TEXT COLLATE NOCASE NOT NULL`, `name TEXT UNIQUE COLLATE NOCASE`). The column then has
  collation n; a column without it has `BINARY`. Tests give a column at most one `COLLATE`, and give
  `COLLATE` only to TEXT columns.
- **`e COLLATE n`** is a postfix operator that binds tighter than every binary operator: in
  `a || b COLLATE NOCASE` it applies to `b`, and `a = b COLLATE NOCASE` is `a = (b COLLATE NOCASE)`.
  Tests do not write it directly after a unary operator expression (`-x COLLATE ...`, `NOT x COLLATE
  ...`), nor two in a row. Its value is e's value, and it has e's affinity (1.9): with `i` an INTEGER
  column, `i COLLATE NOCASE = '12'` is true when `i` is 12.
- **Unknown name.** A collation name other than the three is the error
  `no such collation sequence: <name>` (spelled as written). In a column definition (`CREATE TABLE`,
  `ALTER TABLE ... ADD COLUMN`) or an index column, the statement fails and creates nothing. In an
  expression, tests write an unknown name only as the `COLLATE` of a direct operand of a comparison
  or of an `ORDER BY` term; the statement then fails before reading any row (also on an empty table).

## 7.3 The collation of an expression

Every expression has either an **explicit** collation, an **implicit** collation, or none:

- `e COLLATE n`: explicit n.
- A column reference (possibly qualified, possibly in parentheses): implicit, the column's collation
  (`BINARY` if it declares none). This includes the columns of views, ctes and subquery sources
  (7.5).
- `( e )`, `+e` and `CAST(e AS type)`: the same as e (explicit stays explicit, implicit stays
  implicit). So `+name = 'X'` and `CAST(name AS TEXT) = 'X'` use the column collation of `name`,
  although `+name` has no affinity.
- A scalar subquery `( select )`: none, whatever its result column is.
- Every other expression (literals, `||` and other operators, function calls, `CASE`, aggregates):
  none. Tests do not compare such an expression when it contains a `COLLATE` inside it (as in
  `'x' || 'A' COLLATE NOCASE` or `lower(b COLLATE NOCASE)`); `upper(name)`, `name || ''` and
  `lower(b)` simply have no collation.

## 7.4 Which collation an operation uses

**Comparisons.** For `a op b` with op one of `= == != <> < <= > >= IS IS NOT`:

1. if a has an explicit collation, that one; else if b has an explicit collation, that one;
2. else if a has an implicit collation, that one; else if b has one, that one;
3. else `BINARY`.

So with `name TEXT COLLATE NOCASE` and `code TEXT` (BINARY): `name = 'ABC'` and `'ABC' = name` use
NOCASE; `name = code` uses NOCASE but `code = name` uses BINARY; `code = name COLLATE RTRIM` uses
RTRIM; `name COLLATE BINARY = 'ABC'` uses BINARY.

The other operations, in terms of this rule:

- **`x [NOT] BETWEEN a AND b`** is `x >= a AND x <= b`: each of the two comparisons chooses its
  collation by the rule above (`code BETWEEN 'a' COLLATE NOCASE AND 'C'` uses NOCASE for the lower
  bound and BINARY for the upper).
- **`x [NOT] IN (e1, e2, ...)`**: only x counts, as for affinity in 2.3: x's collation (explicit or
  implicit), else `BINARY`, whatever the ei are. So `'ABC' IN (name)` is 0 for a NOCASE column
  holding `'abc'`, while `name IN ('ABC')` is 1. Tests do not write `COLLATE` on an ei.
- **`x [NOT] IN (select)`**: each comparison is as `x = e`, where e is the subquery's result column
  expression as written in the subquery (with its explicit or implicit collation there).
  So `'ABC' IN (SELECT name FROM t)` uses NOCASE, `code IN (SELECT name FROM t)` uses BINARY, and
  `code IN (SELECT upper(code) COLLATE NOCASE FROM t)` uses NOCASE.
- **`CASE x WHEN v ...`**: each `WHEN` compares as `x = v`.
- **Ordering terms** (the `ORDER BY` of a select, of a compound select, of `group_concat`, and a
  window's `ORDER BY`): a term sorts its TEXT values under its collation (explicit or implicit), else
  `BINARY`. A term that stands for a result column (an integer literal k, or a result column's
  alias, 1.7) has the collation of that result column's expression; such a term may also be followed
  by `COLLATE n` (`ORDER BY 2 COLLATE NOCASE`, `ORDER BY k COLLATE NOCASE`) and then means that result
  column sorted under n. Values equal under the collation tie (`ASC`/`DESC` and later terms decide as
  before; rows that tie on every term still come out in any order).
- **Grouping** (`GROUP BY` terms, window `PARTITION BY` terms, peers of a window's `ORDER BY`): two
  values are equal if they are equal under the term's collation, chosen as for an ordering term
  (`GROUP BY 1` and a `GROUP BY` alias have the result column's collation; `GROUP BY 1 COLLATE
  NOCASE` is allowed). A group's rows may differ in TEXT that is equal under the collation (`'Ann'`,
  `'ANN'`); which of them a bare column, including the `GROUP BY` column itself, takes is any row's,
  as in 3.3, so tests print such a column only through something that does not depend on the row
  (`lower(name)`, `count(*)`).
- **`SELECT DISTINCT`**: two rows are equal if each pair of values is equal under the collation of
  that result column's expression. Which of the equal rows is kept is unspecified.
- **`count(DISTINCT x)`**: values are distinct under x's
  collation (`count(DISTINCT name)` counts `'Ann'` and `'ANN'` once for a NOCASE column, and
  `count(DISTINCT code COLLATE NOCASE)` likewise). Tests use `DISTINCT` inside an aggregate together
  with a collation only in `count`.
- **`min(x)`, `max(x)`** (aggregate, and as window functions): the smallest / largest under x's
  collation. Tests do not depend on which of two values equal under it is returned.
- **Compound selects** (5.1): the k-th column of the compound has the collation of the k-th result
  column of the first simple-select, left to right, whose k-th result column has a collation
  (explicit or implicit), else `BINARY`. `UNION`, `INTERSECT` and `EXCEPT` compare rows under these
  column collations, and the trailing `ORDER BY` sorts under them unless a term has its own
  `COLLATE` (in a compound select, an `ORDER BY` term may be an integer literal or a name followed by
  `COLLATE n`). So `SELECT code FROM t UNION SELECT name FROM t` uses BINARY (`code` is a column),
  `SELECT 'X' UNION SELECT name FROM t` uses NOCASE. Which of two equal rows is kept is unspecified.
- **`UNIQUE` and `PRIMARY KEY`** (2.1): two values of a column are equal if they are equal under that
  column's collation: with `email TEXT UNIQUE COLLATE NOCASE`, storing `'A@x'` next to `'a@x'` is
  `UNIQUE constraint failed: t.email`. For a constraint on several columns, each column uses its own
  collation. This holds for `INSERT`, `UPDATE` and `INSERT ... SELECT`. (An INTEGER PRIMARY KEY holds
  integers and is not affected.)
- **Indexes** (5.7): a `UNIQUE` index compares each of its columns under the column's collation, or
  under n for `column COLLATE n` in the index (`CREATE UNIQUE INDEX i ON t (code COLLATE NOCASE)`
  makes `'ab'` and `'AB'` conflict even though `code` is BINARY; `name COLLATE BINARY` lets them
  coexist although `name` is NOCASE). Creating it on rows that already conflict under that collation
  is the constraint's error. A non-unique index changes no result.
- **Joins** (4.1): an `ON` expression is made of ordinary comparisons (so `p.name = q.name` and
  `q.name = p.name` may differ). `A JOIN B USING (c)` is `ON A.c = B.c` (4.1), and since `A.c` is a
  column it always uses the collation of the left side's column c.

## 7.5 Collations that travel with columns

- **Views, ctes and subquery sources** (4.1, 5.2, 5.3): a column of such a source has, as an
  implicit collation, the collation (explicit or implicit) of its result column expression in the
  select that defines it. So with `CREATE VIEW v AS SELECT code COLLATE NOCASE AS k, name FROM t`,
  `v.k = 'ABC'` and `v.name = 'ABC'` use NOCASE; and since `k` is now implicit,
  `code = v.k` uses BINARY (the left column wins) while `v.k = code` uses NOCASE. A result column
  with no collation (`name || ''`, `upper(code)`) gives a column whose collation is `BINARY`. A cte
  column renamed by a column list keeps its
  collation. Tests do not depend on the collation of a column of a compound select used as a source.
- **Scalar subqueries** have no collation (7.3): `(SELECT name FROM t WHERE id = 1) = 'ABC'` uses
  BINARY even though `name` is NOCASE, and so does `code = (SELECT name FROM t ...)`.
- **`ALTER TABLE ... ADD COLUMN`** (5.6) accepts `COLLATE n` among the new column's constraints;
  the new column has collation n from then on (existing rows get its `DEFAULT` as before). An unknown
  name is the error of 7.2 and adds nothing.

## 7.6 What does not change

`LIKE` ignores collations (it is already case-insensitive for ASCII; `'a ' LIKE 'a'` is still 0).
Functions other than the aggregates above (`length`, `upper`, `instr`, `replace`, `substr`, `trim`,
...) are unaffected. Tests do not pass a value with a collation to `nullif` or to the scalar `min`
and `max` of two or more arguments, nor use `COLLATE` in `DEFAULT` values. Storage (1.5) and
printing are unchanged.

## 7.7 Errors added by this change

`no such collation sequence: <name>`.

## Where it applies

- syntax: `COLLATE` in column definitions and as a postfix operator (case-insensitive names, value and affinity unchanged, `no such collation sequence` for an unknown name) (public)
- compare: comparison operators and `IS`/`IS NOT` compare TEXT under the collation chosen by 7.3 and 7.4 (explicit left, explicit right, implicit left, implicit right, BINARY), with NOCASE and RTRIM as in 7.1; `LIKE` and other functions are unaffected (7.6) (public)
- between: `BETWEEN` chooses the collation separately for its lower and upper comparison
- in-list: `x IN (list)` compares under x's collation only
- in-subquery: `x IN (select)` compares as `x = e` with e the subquery's result expression
- case: `CASE x WHEN v` compares as `x = v`
- order-by: `ORDER BY` terms (and `group_concat`'s `ORDER BY`) sort under the term's or the result column's collation, or a `COLLATE` written on the term (public)
- group-by: `GROUP BY` puts values equal under the term's collation in one group (public)
- distinct: `SELECT DISTINCT` removes rows equal under the result columns' collations (public)
- agg-distinct: `count(DISTINCT x)` counts values distinct under x's collation
- min-max: aggregate `min`/`max` pick the extreme under the argument's collation
- compound: `UNION`/`INTERSECT`/`EXCEPT` and the compound's `ORDER BY` use the collation of the first simple-select that gives the column one
- unique: `UNIQUE` and `PRIMARY KEY` constraints compare under each column's collation (public)
- index: a `UNIQUE` index compares under the column's collation or the index column's `COLLATE`, and an unknown name there is an error
- sources: columns of views, ctes and subquery sources carry the collation of their defining expression as an implicit one
- scalar-subquery: a scalar subquery has no collation
- join: `ON` comparisons follow 7.4 and `USING (c)` uses the left side's column collation
- window: window `PARTITION BY` and `ORDER BY` (partitions, order, peers) use the term's collation
- alter: `ALTER TABLE ADD COLUMN` takes `COLLATE`, and the new column compares under it
