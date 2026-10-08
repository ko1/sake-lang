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
