# Change: every row has a rowid

This change applies on top of stages 1-6. Every row of every table now has a **rowid**: an INTEGER
key, unique within its table, that every stored row carries besides its columns. It can be read,
given and changed through three reserved names, and a column declared `INTEGER PRIMARY KEY` is the
rowid itself under another name. Nothing else changes; in particular, the order of rows without
`ORDER BY` stays unspecified (tests never depend on it).

## 7.1 The rowid names

`rowid`, `_rowid_` and `oid` (case-insensitive like every identifier: `ROWID`, `Oid`; also in double
quotes, `"rowid"`) are the **rowid names**. They are not keywords; a table may still have a column
with one of these names (below).

In a query, a rowid name refers to the rowid of a **table** source (a table in `FROM`, with or without
an alias). It is looked up exactly where a column name is, as one more column of the table, after the
real columns (4.2):

- **A real column wins.** A rowid name that some source (of the innermost query that has one, as in
  4.2) has as a real column means that column, by the rules of 4.2. Only when no source of that query
  has a column of that name does the name mean a rowid. So in `CREATE TABLE h (rowid TEXT, v
  INTEGER)`, `rowid` is the TEXT column of h, while `_rowid_` and `oid` are still h's rowid. A column
  added by `ALTER TABLE ... ADD COLUMN` with a rowid name hides that name the same way from then on.
- **Unqualified.** If the query's `FROM` has exactly one source and it is a table, the name is that
  table's rowid. If the `FROM` has two or more sources (none with a real column of that name), the
  name is `ambiguous column name: <name>` (spelled as written), even when only one of the sources is
  a table. If the query has no `FROM`, the name is looked up in the enclosing queries as a column
  would be (4.2), innermost first.
- **Qualified.** `q.rowid` (or `q._rowid_`, `q.oid`) is the rowid of the table source named q. As
  for any column, a table with an alias is known only by its alias (`a.rowid` with `FROM a AS p` is
  `no such column: a.rowid`). On the NULL-extended side of a `LEFT JOIN`, `q.rowid` is NULL.
- **As a column of the table** (1.7, 3.3): in `WHERE`, `GROUP BY` and `HAVING`, and in an `ORDER BY`
  term that is part of a larger expression, a rowid name means the rowid before a result column alias
  of the same name is considered; an `ORDER BY` term that is just a name that is a result alias still
  means that result column. So with `SELECT x, 10 - rowid AS rowid FROM t`, `WHERE rowid = 1` tests
  the real rowid, `ORDER BY rowid` sorts by the result column, and `ORDER BY rowid + 0` sorts by the
  real rowid.
- **No row in scope.** In the `VALUES` of an `INSERT` there is no row (1.6): a rowid name there is
  `no such column: <name>`.
- **Value and affinity.** The rowid is an INTEGER (`typeof(rowid)` is `'integer'`) and the
  expression is a column reference with INTEGER affinity (1.9): `rowid = '11'` is true for rowid 11,
  and `rowid IN ('11', 13)` converts `'11'`.
- **Not part of `*`.** `SELECT *` and `q.*` expand to the real columns only, exactly as before; the
  rowid appears only where a rowid name is written. A rowid name is not a column for `USING`:
  `JOIN b USING (rowid)` between tables without a real column `rowid` is `cannot join using column
  rowid - column not present in both tables`.
- **Sources that are not tables.** A subquery, cte or view source has no rowid of its own. Its select
  may list `rowid` as a plain column reference (`SELECT rowid, name FROM t`); then the source has a
  real column named `rowid`, carrying those values, like any other column (4.1, 5.2, 5.3), and that
  column wins over the rowid of a table joined with it. Tests write such a result column as `rowid`
  (not `_rowid_` or `oid`), and do not use a rowid name on a source that is not a table unless the
  source has a column of that name.

Rowid names work everywhere column names do: in result columns, aggregates (`max(rowid)`), `GROUP
BY`, `DISTINCT`, window `PARTITION BY`/`ORDER BY` and arguments (`lag(rowid) OVER (ORDER BY rowid)`),
subqueries (a correlated subquery may use `outer.rowid` of an enclosing table source), compound
selects (each simple-select resolves its own names), and in the `SET` expressions and `WHERE` of
`UPDATE` and `DELETE`.

## 7.2 INTEGER PRIMARY KEY is the rowid

A column that is an INTEGER PRIMARY KEY (2.1: a single INTEGER column declared `PRIMARY KEY`, as a
column constraint or as `PRIMARY KEY (c)` alone) **is** the rowid: its value and the rowid are the
same value under two names. Reading, storing or updating either name reads, stores or changes both.
`SELECT *` includes it as the ordinary column it is. Every other kind of primary key (on a REAL or
TEXT column, or on several columns), and `UNIQUE`, are ordinary constraints, and such a table has a
separate rowid like any other.

The rules of 2.1 for an INTEGER PRIMARY KEY now hold for the rowid of every table; in error messages,
the rowid is named by its INTEGER PRIMARY KEY column's name as in the `CREATE TABLE` if the table has
one, and otherwise as `rowid` (lowercase, whichever rowid name the statement wrote).

## 7.3 Giving and assigning rowids

**INSERT.** The column list of an `INSERT` (1.6, 5.4) may name the rowid by any rowid name that is
not a real column of the table (`INSERT INTO t (rowid, a) VALUES (10, 'x')`, `INSERT INTO t (oid, a)
SELECT ...`). Without a column list, each row gives values for the real columns only, as before.
Tests do not name the rowid twice in one column list (for example both `rowid` and the INTEGER
PRIMARY KEY column).

When a row is stored, its rowid is:

- the value given for it, if not NULL. The value must be an INTEGER after the conversion of 1.5 for
  an INTEGER column (`' 20 '` stores 20, `21.0` stores 21); anything else (`2.5`, `'abc'`) is the
  error `datatype mismatch`;
- otherwise (NULL given, or no value given): one more than the largest rowid in the table at that
  moment, or 1 if the table has no rows. The largest rowid counts the rows present now: after
  `DELETE`, numbers of deleted rows at the top are given out again; after an explicit rowid of 1000,
  the next is 1001; if every rowid is negative (say -5 is the largest), the next is -4. Tests keep
  rowids far from the 64-bit limits.

Rows of one statement are stored one at a time in order (1.6), so each NULL row of a multi-row
`VALUES` gets one more than the largest rowid so far, including the rows stored before it by the same
statement: into an empty table, `VALUES (NULL, 'q'), (NULL, 'r'), (7, 's'), (NULL, 'u')` gives rowids
1, 2, 7, 8. `INSERT ... SELECT` stores the select's rows in the select's order, so with an
`ORDER BY` that orders them fully the rowids follow that order (tests do not depend on the rowids of
an `INSERT ... SELECT` without such an `ORDER BY`).

**UPDATE.** `SET rowid = expr` (any rowid name that is not a real column, or the INTEGER PRIMARY KEY
column) changes the row's rowid. The new value is checked as for `INSERT`, except that NULL is also
`datatype mismatch`. As for every column (2.2), all `SET` expressions see the row as it was before
the statement: `SET rowid = rowid + 10, x = x || rowid` appends the old rowid. Tests do not depend on
the order in which rows are updated (they avoid updates that collide only temporarily).

**Uniqueness.** Two rows of a table never share a rowid. Storing a rowid that another row of the
table already has is the error `UNIQUE constraint failed: <table>.rowid`, or
`UNIQUE constraint failed: <table>.<column>` with the INTEGER PRIMARY KEY's column name if the table
has one. The checks on a row (2.1) are in this order: the rowid's value (`datatype mismatch`);
`NOT NULL` of each column in column order; the rowid's uniqueness; storage conversion of the other
columns (1.5); the other uniqueness constraints. As before, the first failure is the statement's
error and the statement has no effect at all: rows it would have numbered take no numbers.

## 7.4 Rowids and the rest of the schema

- `DELETE` removes rows with their rowids; the rowids of the remaining rows do not change.
- `ALTER TABLE` (5.6) keeps every row's rowid: `RENAME TO`, `ADD COLUMN` and `RENAME COLUMN` do
  not change rowids, and numbering continues from the largest rowid present.
- `ROLLBACK` (5.5) undoes rowid assignments with everything else: the rows and their rowids are as at
  `BEGIN`, so the next new row is numbered from the largest rowid present after the rollback.

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
not an INTEGER, or NULL in `UPDATE`); `UNIQUE constraint failed: <table>.rowid` (a duplicate rowid of
a table without an INTEGER PRIMARY KEY); `ambiguous column name: <name>` (an unqualified rowid name
with several sources); `no such column: <name>` (a rowid name in `INSERT ... VALUES`, or `q.rowid`
naming no source q); `cannot join using column <name> - column not present in both tables` (a rowid
name in `USING`).

## Where it applies

- names: `rowid`, `_rowid_` and `oid`, in any case, read a table's INTEGER rowid with INTEGER affinity, in result columns, `WHERE`, `ORDER BY`, aggregates and `GROUP BY`, but not in `INSERT ... VALUES`. (public)
- star: `SELECT *` and `q.*` list only the real columns, never the rowid.
- hidden: a real column (declared or added) named `rowid`, `_rowid_` or `oid` takes that name, and the other rowid names still reach the rowid.
- alias: a rowid name counts as a column of the table, so it beats a result alias of the same name in `WHERE` and inside `ORDER BY` expressions, but a bare `ORDER BY` alias still wins.
- qualified: `q.rowid` names the rowid of the table source q (by its alias if it has one), and is NULL on the NULL-extended side of a `LEFT JOIN`.
- join-names: an unqualified rowid name with two or more sources is `ambiguous column name`, and a rowid name in `USING` is not a column.
- insert-explicit: an `INSERT` column list may name the rowid; the value must be an INTEGER after conversion (else `datatype mismatch`) and NULL means "assign one". (public)
- auto-number: a new row without a rowid gets one more than the largest rowid present (1 in an empty table), counted row by row within a statement and after `DELETE`. (public)
- unique: a duplicate rowid is `UNIQUE constraint failed: <table>.rowid`, checked after `NOT NULL` and before storage conversion, and the whole statement fails.
- update: `UPDATE ... SET rowid = e` changes the rowid, NULL or a non-INTEGER is `datatype mismatch`, and every `SET` expression sees the old rowid. (public)
- integer-primary-key: an INTEGER PRIMARY KEY column is the rowid under another name, and errors name that column. (public)
- insert-select: `INSERT ... SELECT` numbers rows in the select's order and may supply rowids from the select.
- derived: a subquery, cte or view source has a `rowid` column only when its select lists `rowid`, and that column wins over a joined table's rowid.
- correlated: a subquery may use an enclosing table source's rowid (`outer.rowid`, or an unqualified rowid name in a subquery without `FROM`).
- window: rowid names work in window `PARTITION BY`, `ORDER BY` and arguments.
- alter: `ALTER TABLE` `RENAME TO`, `ADD COLUMN` and `RENAME COLUMN` keep every row's rowid and numbering continues from the largest.
- transaction: `ROLLBACK` restores the rows with their rowids, and numbering continues from the largest rowid present after it.
