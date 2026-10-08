# c3 rowid (wide)

Every table row has a 64-bit integer key, the rowid, readable as `rowid`, `_rowid_` or `oid` unless a column
of the table has that name. A column declared `INTEGER PRIMARY KEY` is the rowid under another name (both names
work). New rows get max(rowid)+1 (1 in an empty table) unless the INSERT gives one; INSERT may name `rowid` as a
column; UPDATE may set it; a duplicate is SQLite's UNIQUE error.

It changes the shape of a stored row and of name resolution. Candidate sites (verify each with SQLite, keep the
clear ones, give each an id): SELECT rowid / _rowid_ / oid, a column named rowid hiding it, `SELECT *` and
`t.*` not including it, qualified t.rowid in joins and ambiguity, WHERE/ORDER BY rowid, INSERT with explicit
rowid, auto numbering after DELETE and after an explicit large rowid, UPDATE of rowid, INTEGER PRIMARY KEY
aliasing, INSERT ... SELECT, views / subqueries / CTEs / compound selects have no rowid (`no such column`),
correlated subqueries using the outer rowid, window ORDER BY rowid, ALTER TABLE (RENAME, ADD COLUMN) keeping
rowids, transactions rolling back rowid assignment, typeof(rowid).
