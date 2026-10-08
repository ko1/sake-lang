# c3-rowid: issues found while making the change in the reference engine

Implementation: `large/sql/changes/c3-rowid/ref/` (copy of `large/sql/ref/`). A stored row is its
column values followed by its rowid (an INTEGER PRIMARY KEY column repeats it); a table source in a
Scope carries one hidden rowid column after its real ones. Results: public 1-6 366/366, hidden 1-6
369/369, change public 8/8, change hidden 44/44. SQLite probes below: Python `sqlite3` (STRICT tables).

## Tests that disagreed with the specification

1. **`tasks/sql-change-hidden/c3-rowid/7/042-mixed-queue.sql` used a keyword as a column name.** When
   first read it had `CREATE TABLE head (r INTEGER, last INTEGER)` and `SELECT last + 1 FROM head`.
   `LAST` is a keyword (spec 1-core, "The keywords (all stages)"), and 1-core says tests do not use
   keywords as column names. Expected `1|build` on the first SELECT; the specified output (and this
   engine's) is `Error: syntax error` at the CREATE, then `no such table: head`. Judgement: the test was
   wrong. The file was rewritten by someone else while I worked (mtime 2026-10-08 09:54:44 UTC = 18:54
   JST; the column is now `lastr`), and the new version passes unchanged. I did not change the program
   to accept `last` as a name.

No other expected output contradicts change.md or spec 1-6.

## The original reference engine against spec 2.1 (now exercised by the change's tests)

2. **Check order for an INTEGER PRIMARY KEY.** Spec 2.1 (and 7.3) puts the key's value
   (`datatype mismatch`) before `NOT NULL`. `large/sql/ref` checks NOT NULL first:
   `CREATE TABLE ipk (id INTEGER PRIMARY KEY NOT NULL, t TEXT); INSERT INTO ipk VALUES (1,'a');
   UPDATE ipk SET id = NULL;` gives `NOT NULL constraint failed: ipk.id` (spec and SQLite:
   `datatype mismatch`), and `CREATE TABLE k2 (id INTEGER PRIMARY KEY, n INTEGER NOT NULL);
   INSERT INTO k2 VALUES ('x', NULL);` gives `NOT NULL constraint failed: k2.n` (spec:
   `datatype mismatch`). No stage 1-6 test catches it; c3 hidden 022 and 028 test the rowid form of
   it. The changed engine follows the spec.

## Rules found unclear, ambiguous or missing

3. **"The innermost query that has one" (7.1, "A real column wins").** The sentence can be read as
   "an enclosing query's real column `rowid` beats an inner table's rowid". SQLite resolves query by
   query, innermost first, rowid included: with `o (rowid TEXT, a)` and `i (b)`,
   `SELECT (SELECT rowid FROM i WHERE b = 8) FROM o` is i's rowid (2). The engine does that. Untested.
4. **"Rowid names work everywhere column names do"** overstates: in SQLite a rowid name is
   `no such column` in `CREATE INDEX ... (rowid)`, in a table constraint `UNIQUE (rowid)` and in
   `RENAME COLUMN rowid TO z` (`no such column: "rowid"`). change.md does not list these schema
   places either way; the engine gives SQLite's errors. Untested.
5. **A derived source listing `rowid` from a table with an INTEGER PRIMARY KEY.** change.md says the
   source then has a real column named `rowid`. In SQLite a view `CREATE VIEW vv AS SELECT rowid, nm
   FROM it` (it.id INTEGER PRIMARY KEY) names that column `id`: `SELECT rowid FROM vv` is NULL and
   `SELECT id FROM vv` works (a subquery or cte names it `rowid`, as change.md says). The engine follows
   change.md. Tests 031-033 use tables without an INTEGER PRIMARY KEY, so nothing depends on it.
6. **Compound `ORDER BY` with a rowid name that is not a result column name.** `SELECT id FROM it
   UNION ALL SELECT 9 ORDER BY rowid` is accepted by SQLite; by 5.1 (ORDER BY of a compound matches
   result column names) it is `1st ORDER BY term does not match any column in the result set`, which
   is what the engine says. change.md does not mention compound ORDER BY. Untested.
7. **Rowid name on a source that is not a table** (`x.rowid` with `(SELECT b FROM i) AS x`): SQLite
   gives NULL, the engine `no such column: x.rowid`. change.md excludes it from tests; already noted
   in `spec-issues/c3-rowid.md` item 1.

## "Where it applies" sites and their hidden tests

Each site has hidden tests that would fail a plausible implementation that skips it (for example,
`star` 004/005 fail if `*` includes the rowid, `derived` 033 fails if a joined table's rowid makes
`rowid` ambiguous, `transaction` 040 fails with a counter kept outside the rows, `unique` 022 checks
every adjacent pair of the check order). I found no site that is not really tested.
