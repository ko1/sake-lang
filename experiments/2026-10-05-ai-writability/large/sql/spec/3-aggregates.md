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
  toward "exactly one"); otherwise any row of the group. In the single group of a query without
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
