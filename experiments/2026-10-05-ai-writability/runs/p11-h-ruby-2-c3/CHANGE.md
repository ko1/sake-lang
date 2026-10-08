# Change: every row has a rowid

This change applies on top of stages 1-6. Every row of every table now has a **rowid**: an INTEGER
key, unique within its table, that every stored row carries besides its columns. It can be read,
given and changed through three reserved names, and a column declared `INTEGER PRIMARY KEY` is the
rowid itself under another name. Nothing else changes; in particular, the order of rows without
`ORDER BY` stays unspecified (tests never depend on it).

## 7.1 The rowid is a hidden column of every table

`rowid`, `_rowid_` and `oid` (case-insensitive like every identifier: `ROWID`, `Oid`; also in double
quotes, `"rowid"`) are the **rowid names**. They are not keywords; a table may still have a real
column with one of these names (below).

**A column of the table, after the real ones.** For name lookup, a table's rowid is one more column
of that table, reachable by each rowid name, and looked up after the table's real columns. A rowid
name can be used wherever a name of a column of the table can be, means the rowid there, and obeys
every rule that stages 1-6 give for column names, qualified or not: the order in which columns,
result column aliases and enclosing queries are tried (1.7, 3.3, 4.2, 4.3), the use of a source's
alias, NULL for a row that a join extends with NULLs, correlation, and `no such column: <name>`
where no row is in scope. Because a rowid name is a column of the table, it is tried before a result
column alias of the same name exactly as a real column would be: with `SELECT x, 10 - rowid AS rowid
FROM t`, `WHERE rowid = 1` tests the real rowid, `ORDER BY rowid` (a bare alias) sorts by the result
column, and `ORDER BY rowid + 0` sorts by the real rowid. `q.rowid` (or `q._rowid_`, `q.oid`) is
the rowid of the table source named q; `a.rowid` with `FROM a AS p` is `no such column: a.rowid`.

The rowid differs from a real column in these rules only:

- **A real column wins.** A rowid name that some source (of the innermost query that has one, as in
  4.2) has as a real column means that column, by the rules of 4.2. Only when no source of that
  query has a real column of that name does the name mean a rowid. So in `CREATE TABLE h (rowid
  TEXT, v INTEGER)`, `rowid` is the TEXT column of h, while `_rowid_` and `oid` are still h's rowid.
  This holds for a real column of that name whenever it came to exist, also one added to the table
  later: from then on it hides that rowid name.
- **Unqualified with several sources.** An unqualified rowid name (no source having a real column of
  that name) means a rowid only when the query's `FROM` has exactly one source and it is a table. If
  the `FROM` has two or more sources, it is `ambiguous column name: <name>` (spelled as written), even
  when only one of the sources is a table. If the query has no `FROM`, the name is looked up in the
  enclosing queries as a column would be (4.2), innermost first.
- **Hidden.** The rowid is reached only by writing a rowid name. Whatever stands for, counts, or
  matches by name "the columns of a table" sees the real columns only, exactly as before this change:
  `*` and `q.*` expand to the real columns; a row given without a column list gives values for the
  real columns only (`table <table> has <n> columns but <m> values were supplied` counts real
  columns); and a column matched by name between two sources must be a real column of both (a rowid
  name there is `cannot join using column <name> - column not present in both tables` when it is not
  a real column of both).
- **Value and affinity.** The rowid is an INTEGER (`typeof(rowid)` is `'integer'`), and a rowid name
  is a column reference with INTEGER affinity (1.9): `rowid = '11'` is true for rowid 11, and
  `rowid IN ('11', 13)` converts `'11'`.
- **Only tables have rowids.** A source that is the result of a select (a subquery, cte or view) has
  no rowid of its own. Its select may list `rowid` as a plain column reference (`SELECT rowid, name
  FROM t`); then the source has a real column named `rowid`, carrying those values, like any other
  column named after a plain column reference (4.1, 5.2, 5.3), and as a real column it wins over the
  rowid of a table joined with it. Tests write such a result column as `rowid` (not `_rowid_` or
  `oid`), and do not use a rowid name on a source that is not a table unless the source has a column
  of that name.

## 7.2 INTEGER PRIMARY KEY is the rowid

A column that is an INTEGER PRIMARY KEY (2.1: a single INTEGER column declared `PRIMARY KEY`, as a
column constraint or as `PRIMARY KEY (c)` alone) **is** the rowid: its value and the rowid are the
same value under two names. Reading, storing or changing either name reads, stores or changes both.
It is a real column: it is among "the columns of the table" like any other. Every other kind of
primary key (on a REAL or TEXT column, or on several columns), and `UNIQUE`, are ordinary
constraints, and such a table has a separate rowid like any other.

The rules of 2.1 for an INTEGER PRIMARY KEY now hold for the rowid of every table. In error
messages, the rowid is named by the table's INTEGER PRIMARY KEY column if it has one (by its current
name, 5.6), and otherwise as `rowid` (lowercase, whichever rowid name the statement wrote).

## 7.3 Giving and changing rowids

**Storing into the rowid.** Wherever a statement names columns of a table to store values into, a
rowid name that is not a real column of the table names the rowid, and the value stored there
becomes the row's rowid (`INSERT INTO t (rowid, a) VALUES (10, 'x')`, `UPDATE t SET oid = oid + 1`).
It counts as one listed column for the counts of 1.6. Tests do not name the rowid twice among the
columns of one statement (for example both `rowid` and the INTEGER PRIMARY KEY column).

**A new row's rowid** is:

- the value given for it, if not NULL. The value must be an INTEGER after the conversion of 1.5 for
  an INTEGER column (`' 20 '` stores 20, `21.0` and `1e1` store 21 and 10); anything else (`2.5`,
  `'abc'`, `'15x'`) is the error `datatype mismatch`;
- otherwise (NULL given, or no value given): one more than the largest rowid in the table at that
  moment, or 1 if the table has no rows. The largest rowid counts the rows present now: numbers of
  rows no longer present at the top are given out again; after an explicit rowid of 1000, the next
  is 1001; if every rowid is negative (say -5 is the largest), the next is -4. Tests keep rowids far
  from the 64-bit limits.

A statement that stores several new rows stores them one at a time in the order it produces them
(1.6), so each row numbered automatically gets one more than the largest rowid so far, including the
rows stored before it by the same statement: into an empty table, `VALUES (NULL, 'q'), (NULL, 'r'),
(7, 's'), (NULL, 'u')` gives rowids 1, 2, 7, 8. Rows that come from a select are produced in the
select's order, so when an `ORDER BY` orders them fully the rowids follow that order (tests do not
depend on the rowids of rows from a select without such an `ORDER BY`).

**Changing an existing row's rowid.** The new value is checked as for a new row, except that NULL is
also `datatype mismatch` (NULL means "assign a number" only for a new row). As for every column
(2.2), all new values are computed from the row as it was before the statement: `SET rowid = rowid +
10, x = x || rowid` appends the old rowid. Tests do not depend on the order in which rows are changed
(they avoid changes that collide only temporarily).

**Uniqueness.** Two rows of a table never share a rowid. Storing a rowid that another row of the
table already has is the error `UNIQUE constraint failed: <table>.rowid`, or
`UNIQUE constraint failed: <table>.<column>` with the INTEGER PRIMARY KEY's column name if the table
has one. The checks on a row (2.1) are in this order: the rowid's value (`datatype mismatch`);
`NOT NULL` of each column in column order; the rowid's uniqueness; storage conversion of the other
columns (1.5); the other uniqueness constraints. As before, the first failure is the statement's
error and the statement has no effect at all: rows it would have numbered take no numbers.

## 7.4 A rowid belongs to its row

A row's rowid is part of the row. It changes only when a statement stores a new value into it
(7.3); nothing else ever renumbers rows. Whatever removes a row removes its rowid with it (the other
rows keep theirs); whatever keeps a row, including any change to its table's name or columns, keeps
its rowid; whatever restores rows (undoing a transaction, 5.5) restores them with their rowids. New
numbers always follow the largest rowid present at the moment the row is stored (7.3).

## Examples

```
CREATE TABLE notes (body TEXT);
INSERT INTO notes VALUES ('a'), ('b');
INSERT INTO notes (rowid, body) VALUES (10, 'c');
INSERT INTO notes VALUES ('d');
SELECT rowid, oid, body FROM notes ORDER BY rowid;     -- 1|1|a  2|2|b  10|10|c  11|11|d
SELECT * FROM notes WHERE _rowid_ = 2;                  -- b
INSERT INTO notes (rowid, body) VALUES (2, 'e');        -- Error: UNIQUE constraint failed: notes.rowid
UPDATE notes SET rowid = NULL WHERE body = 'a';         -- Error: datatype mismatch
DELETE FROM notes WHERE rowid > 9;
INSERT INTO notes VALUES ('f');
SELECT rowid, body FROM notes ORDER BY 1;               -- 1|a  2|b  3|f

CREATE TABLE items (id INTEGER PRIMARY KEY, name TEXT);
INSERT INTO items (name) VALUES ('x');
INSERT INTO items (rowid, name) VALUES (5, 'y');
UPDATE items SET id = 9 WHERE name = 'x';
SELECT rowid, id, name FROM items ORDER BY id;          -- 5|5|y  9|9|x
INSERT INTO items (oid, name) VALUES (9, 'z');          -- Error: UNIQUE constraint failed: items.id

CREATE TABLE tags (rowid TEXT, n INTEGER);
INSERT INTO tags VALUES ('red', 1);
SELECT rowid, oid FROM tags;                            -- red|1
SELECT rowid FROM notes, items;                         -- Error: ambiguous column name: rowid
```

## Errors

No new messages. Existing messages now also arise as follows: `datatype mismatch` (a rowid that is
not an INTEGER, or NULL stored into an existing row's rowid); `UNIQUE constraint failed:
<table>.rowid` (a duplicate rowid of a table without an INTEGER PRIMARY KEY); `ambiguous column name:
<name>` (an unqualified rowid name with several sources); `no such column: <name>` (a rowid name
where no row is in scope, or `q.rowid` naming no table source q); `cannot join using column <name> -
column not present in both tables` (a rowid name matched by name between sources).
