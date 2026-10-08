# Reference implementation, stage 4: where the tests and the specification disagree

Implementation: `large/sql/ref/` (Ruby 4.0.2). Probes ran on SQLite 3.46.1 (python3 `sqlite3`).
Result (stages 1-4): public 257/257, hidden 258/260. The two hidden failures are items 1 and 2:
there the reference follows the specification, not the test.

New files: `scope.rb` (the sources of a FROM as names see them: columns, their place in the joined
row, USING merges), `from_clause.rb` (binding of FROM: sources, ON/USING conditions, the joined rows).
Expressions now evaluate on a `Frame` (the row plus the enclosing query's Frame), and a name of an
enclosing query is bound in that query and wrapped in `Expressions::Outer`; a subquery is a
`SelectQuery` whose outer Binder is the enclosing clause's.

## A. Tests that disagree with the specification

1. **`tasks/sql-hidden/4/029-scalar-columns-error`, statement 7: `IS NOT NULL` on a two-column
   subquery.**
   ```sql
   SELECT s FROM solo WHERE (SELECT b, c FROM trio) IS NOT NULL;
   ```
   Expected: `Error: sub-select returns 2 columns - expected 1`. Spec 4.3: "as a direct operand of a
   comparison (`=`, `!=`, `<`, ..., `IS`, `IS NOT`) ... a scalar subquery with more than one column is
   `row value misused`", and 1.8's grammar has no separate `IS NULL` (it is `expr IS [NOT] expr` with
   the literal NULL), so the specified output is `Error: row value misused`. SQLite parses
   `x IS [NOT] NULL` with a literal NULL as its own postfix operator, which is not a comparison
   (`(SELECT a, b ...) IS 1` is `row value misused`, `... IS NULL` is the sub-select error).
   Judgement: the spec is incomplete, the test shows SQLite. Either add to 4.3 "except `IS NULL` and
   `IS NOT NULL` with the literal NULL, where it is `sub-select returns ...`", or drop the statement.
   The reference prints `row value misused`.

2. **`tasks/sql-hidden/4/014-using-errors`, statement 5: two errors in one statement.**
   ```sql
   SELECT title FROM emp WHERE id IN (SELECT 1 FROM dep JOIN emp USING (id));
   ```
   Expected: `Error: cannot join using column id - column not present in both tables`. But `title`
   is not a column of `emp` (the only source of the outer query), so the statement also has
   `no such column: title`. Spec 1.12: "Tests have at most one error per statement", and nothing says
   which error comes first (SQLite expands every FROM, subqueries included, before it resolves any
   name). The reference binds the result columns first and prints `Error: no such column: title`.
   Judgement: the test is wrong (it breaks 1.12's promise); it was probably meant as `SELECT id ...`
   or `SELECT dept ...`.

3. **`tests/4/033-in-subquery-affinity` (public) and `tasks/sql-hidden/4/033-in-affinity-mixed`:
   which side `x IN (select)` converts.**
   ```sql
   SELECT '12' IN (SELECT i FROM ints);   -- i INTEGER holding 12; expected 1
   SELECT 12 IN (SELECT s FROM texts);    -- s TEXT holding '12'; expected 1
   ```
   Spec 4.3: "as `x IN (v1, v2, ...)` (2.3) ...; if that column is a plain column reference, its values
   carry its column's affinity in the comparisons with x". 2.3 says for the list form "Only x's
   affinity counts ... whatever ei's own affinity; if x has none, nothing is converted". Read
   literally, x (a literal, no affinity) converts nothing and both results are 0; then the column's
   affinity that 4.3 makes the values "carry" would never matter, so 4.3 must mean the comparisons of
   1.9 (either operand converted by the other's affinity), which is what SQLite does and what both tests
   expect (every value in the two tests agrees with that reading).
   Judgement: the spec is self-contradictory; the tests are right. The reference uses the full 1.9
   rules for `IN ( select )` and 2.3's one-sided rule for the list form. 4.3 should say so in
   words: "each comparison of x with a value follows 1.9, the value having the column's affinity (not
   2.3's rule that only x's affinity counts)".

## B. Places where SQLite and the specification differ (no test depends on them)

The reference follows the specification.

4. **`q.c` when the innermost source named q lacks c (4.2).** Spec: "the column c of the source named
   q. If no source is named q, or it has no column c, the error is `no such column: q.c`". SQLite
   then goes on outward: `SELECT (SELECT t.b FROM u t) FROM t` (inner `t` is `u`, which has no `b`)
   gives the outer `t.b`. The reference finds the innermost source named q (looking outward only when
   a query has no source of that name) and then reports the error.
5. **Two multi-column subqueries compared (4.3).** `(SELECT a, b ...) = (SELECT a, b ...)` is a row
   value comparison in SQLite (gives 1 or 0); the spec makes it `row value misused`.

## C. Rules that are unclear or missing (tests do not decide them)

6. **Result-column aliases in `ON`.** 4.2 says aliases are seen "where 1.7 and 3.3 allow them", which
   do not mention `ON`. SQLite resolves `ON` like `WHERE`: `SELECT a + 1 AS z, c FROM t JOIN u ON z = 2`
   is `ambiguous column name: a` (z stands for `a + 1`). The reference does the same.
7. **An aggregate call in `ON`.** Not in 3.3's list. SQLite: `misuse of aggregate: count()` (not the
   `misuse of aggregate function` of `WHERE`). The reference does the same.
8. **`ON` naming a source joined later.** 4.1 says a later `ON` may use the sources before it; it does
   not say what a reference to a later source is. SQLite accepts it for inner joins
   (`FROM t JOIN u ON t.a = w.a JOIN u w ON 1` runs) and rejects it for `LEFT JOIN` with
   `ON clause references tables to its right`. The reference reports `no such column: w.a`: the
   condition is evaluated as the join is built, on the sources joined so far.
9. **A subquery source inside a correlated subquery.** 4.1: "`( select )` runs once"; 4.2 lets names
   reach "each enclosing query". Can a FROM subquery see the queries enclosing its own query (not its
   own FROM, which hidden 045 settles)? SQLite allows it:
   `SELECT (SELECT count(*) FROM (SELECT c FROM u WHERE u.a = t.a)) FROM t` is correlated with `t`.
   The reference does the same (such a source then runs once per run of its query).
10. **Affinity of a subquery column that is not a plain column reference.** 4.1/4.3 give a plain
    column reference's affinity; 2.3 gives `CAST` an affinity too. SQLite carries any result
    expression's affinity, so `x` in `(SELECT CAST(a AS INTEGER) AS x FROM t)` compares with `'12'`
    numerically. The reference does the same (the bound expression's affinity). Say "a result column
    with an affinity (1.9) keeps it".
11. **Two result columns of one name in a subquery source** (`SELECT * FROM (SELECT * FROM a JOIN b
    ON ...)` with `id` in both): SQLite renames the second (`id:1`), so `s.id` and an unqualified `id`
    are the first. The reference takes the first column of that name in the source. Tests avoid it;
    the spec might say so.
