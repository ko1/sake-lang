# Reference implementation, stage 5: where the tests and the specification disagree

Implementation: `large/sql/ref/` (Ruby 4.0.2). Probes ran on SQLite 3.46.1 (python3 `sqlite3`, and
`harness/sql_oracle.py` where the messages are in the catalogue).
Result (stages 1-5): public 326/326, hidden 329/329.

New files: `query.rb` (`Query.build`, `CompoundQuery`, `RecursiveQuery`, the ORDER BY / LIMIT
helpers shared with `SelectQuery`), `catalog.rb` (the named sources a FROM sees: ctes, innermost
WITH first, then the database's views and tables; a view or cte is bound anew at each use),
`schema.rb` (tables, views and indexes with their DDL; a copy of it is what BEGIN keeps and
ROLLBACK restores). `Database` now runs statements and transactions only; the parser reads every
stage 5 statement, and every select (subqueries, FROM, views, ctes, INSERT) may be a compound with
WITH.

## A. Tests that disagree with the specification

None in stage 5. Every stage 5 test, public and hidden, agrees with the spec's words where they
speak (where they are silent, see C).

The two stage 4 disagreements of `ref-4.md` are settled: `tasks/sql-hidden/4/014-using-errors` was
changed (it no longer has two errors), and spec 4.3 now says that `IS [NOT] NULL` with the literal
NULL is no comparison, so `tasks/sql-hidden/4/029-scalar-columns-error` statement 7
(`sub-select returns 2 columns - expected 1`) follows the spec; the reference was changed to match.

## B. Places where SQLite and the specification differ (no test depends on them)

The reference follows the specification. (Items 1-7 of `5.md` are not repeated here: the
reference follows the spec on 3, 4 and 6; the spec now covers 1, 2, 5 and 7.)

1. **A duplicate cte name inside a view's select.** 5.3: "`CREATE VIEW` does not check its select".
   SQLite reports `duplicate WITH table name: x` at `CREATE VIEW v AS WITH x AS (...), x AS (...) ...`.
   The reference creates the view and reports the error where the view is used.
2. **A DEFAULT that cannot be stored, in ADD COLUMN.** 5.6 converts the default "as by 1.5" for the
   existing rows; it does not say what a failed conversion is. With rows, SQLite (STRICT) says
   `type mismatch on DEFAULT` (not in the catalogue); on an empty table it accepts the column and the
   next INSERT fails with `cannot store TEXT value in INTEGER column e.c`. The reference reports
   1.5's `cannot store ...` at the ALTER when there are rows, and at the INSERT otherwise.

## C. Rules that are unclear or missing

Where a test decides the rule (read off SQLite):

3. **`IF NOT EXISTS` on `CREATE INDEX` does not cover a table's name.**
   `tasks/sql-hidden/5/055-index-name-space`: `CREATE INDEX IF NOT EXISTS alpha ON alpha (a);` with a
   table `alpha` expects `Error: there is already a table named alpha`. 5.7 shows `IF NOT EXISTS` in
   the grammar but does not say what it suppresses. Say: "`IF NOT EXISTS` does nothing only when an
   index has the name; a table's or view's name is still the error." (Likewise SQLite gives
   `there is already an index named i` for `CREATE TABLE IF NOT EXISTS i` / `CREATE VIEW IF NOT
   EXISTS i`; the reference does the same; no test.)

Not decided by tests (the reference does what SQLite does unless noted):

4. **`DROP TABLE IF EXISTS <a view>`** (and `DROP VIEW IF EXISTS <a table>`): still the
   `use DROP ...` error. 5.3 does not say whether IF EXISTS covers the wrong kind.
5. **Order of checks in CREATE INDEX:** the table first (`no such table: <name>`; SQLite writes
   `main.<name>`), then the index's name, then the columns (`no such column: <c>`, not in 5.7), then
   existing conflicts. An index on a view: `views may not be indexed` (not in the catalogue).
6. **ALTER TABLE on a view:** SQLite says `Cannot add a column to a view`, `view v may not be
   altered`, `cannot rename columns of view "v"` (none in the catalogue); 5.6 defines only an unknown
   table.
7. **Order of ADD COLUMN errors** when several apply (SQLite: duplicate name, then PRIMARY KEY, then
   UNIQUE, then NOT NULL): tests have one per statement, but `b INTEGER UNIQUE NOT NULL` on a table with
   rows is both; the spec could list the order.
8. **Column-list count mismatch** of a cte (`table c has 1 values for 2 columns`) or a view
   (`expected 2 columns for 'v' but got 1`, at use): neither message is in the catalogue.
9. **A correlated cte.** 4.1 says a FROM subquery is not correlated (and SQLite, and the reference,
   allow it anyway, ref-4 item 9); 5.2 does not say whether a cte in a subquery may use the enclosing
   query's columns. SQLite allows it:
   `SELECT a, (WITH c AS (SELECT c FROM u WHERE u.a = t.a) SELECT count(*) FROM c) FROM t` is
   correlated. The reference binds a cte's select where the cte is defined and runs it on the
   enclosing row of that place.
10. **Recursive cte forms beyond 5.2's:** several initial simple-selects
    (`SELECT 5 UNION ALL SELECT 1 UNION ALL SELECT n + 1 FROM r ...`), and ORDER BY / LIMIT on the
    cte's own select (SQLite: ORDER BY picks the next queue row, LIMIT stops the recursion, so
    `WITH RECURSIVE r(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM r LIMIT 5)` terminates). The
    reference does both. A self-reference that is not `... UNION [ALL] recursive` is
    `circular reference: <name>` (SQLite's message for some of these cases; none is in the
    catalogue).
11. **A view used inside itself** (`CREATE VIEW w AS SELECT * FROM w`): SQLite `view w is circularly
    defined` at use (not in the catalogue). 5.3 does not exclude it.
12. **RENAME TO an index's name, or the table's own name in another case:** both are SQLite's
    `there is already another table or index with this name: <new-name>` (`5.md` items 8-9); 5.7's
    "index names have their own name space" suggests otherwise for the first.
13. **Affinity of a compound's columns** (5.3: "tests do not depend"): the reference takes the first
    simple-select's; SQLite keeps an underlying column's affinity even when the first gives a literal there (`5.md` item 15).
