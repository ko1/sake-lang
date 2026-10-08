# Change c3-rowid: specification issues (found while writing its tests)

SQLite 3.46.1 through `harness/sql_oracle.py` (STRICT tables). No test depends on any point below.

## Disagreements between SQLite and spec files 1-6

None found. Everything the c3 tests use agrees with stages 1-6 (the INTEGER PRIMARY KEY rules of 2.1
are exactly SQLite's rowid rules, and its check order holds for the rowid of every table).

## Candidate sites dropped as unclear

1. **Rowid of a subquery, view or cte that does not list it** (outline: "views / subqueries / CTEs /
   compound selects have no rowid (`no such column`)"). SQLite is inconsistent:
   `CREATE TABLE a (x TEXT); INSERT INTO a VALUES ('p'), ('q');`
   - `SELECT rowid FROM (SELECT x FROM a);` prints `NULL` twice (no error); so does `s.rowid` with
     `(SELECT x FROM a) AS s`.
   - `CREATE VIEW v AS SELECT x FROM a; SELECT rowid FROM v;` prints `NULL` twice; so does `oid`.
   - `WITH c AS (SELECT x FROM a) SELECT rowid FROM c;` is `Error: no such column: rowid`.
   The outline's `no such column` holds only for the cte. change.md keeps only the case where the
   select lists `rowid` (site `derived`) and says tests do not use a rowid name on such a source
   otherwise.
2. **Naming of a listed `oid`/`_rowid_` in a derived source.** `CREATE VIEW v AS SELECT oid, x FROM a;`
   names the view's column `rowid` (not `oid`), and then `SELECT v.oid FROM v` is NULL while
   `SELECT rowid FROM v` is the column; a subquery `(SELECT _rowid_, x FROM a)` names its column
   `_rowid_`. Not stated; tests list only `rowid`.
3. **Compound selects** "have no rowid": a compound used as a source is a subquery source (point 1).
   As a statement, each simple-select resolves its own rowid (`SELECT rowid FROM a UNION SELECT rowid
   FROM b` works); covered by the general text, no separate site.
4. **`RENAME COLUMN x TO rowid`** is accepted and then hides `rowid` (like an added column). Left out:
   5.6 says tests do not rename to a name the table already has, and whether `rowid` counts is a
   judgement call.
5. **Duplicate rowid in a table that has a real column named `rowid`**: the message is
   `UNIQUE constraint failed: h.rowid`, naming the hidden rowid with the same spelling as the real
   column. change.md's rule (`<table>.rowid`) covers it, but no test uses it because the message is
   misleading.
6. **Rowids near the 64-bit limit**: once the largest rowid is 9223372036854775807, SQLite picks a
   random unused rowid. Excluded ("Tests keep rowids far from the 64-bit limits").
7. **Subqueries in `UPDATE`/`DELETE` that read the table being changed** (e.g. requeue with
   `SET rowid = (SELECT max(rowid) + 1 FROM job) WHERE rowid = (SELECT min(rowid) FROM job)`): what
   they see is left open by 4.2; one draft hidden test depended on it and was rewritten.
