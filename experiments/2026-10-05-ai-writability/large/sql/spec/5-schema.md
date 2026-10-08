# Stage 5: compound selects, WITH, views, transactions, schema changes

## 5.1 Compound selects

```
select := [WITH ...] simple-select [compound-op simple-select]... [ORDER BY ...] [LIMIT ... [OFFSET ...]]
compound-op := UNION | UNION ALL | INTERSECT | EXCEPT
```

Each simple-select is a `SELECT` without its own `ORDER BY`/`LIMIT`. The operators have equal
precedence and associate to the left. All simple-selects must have the same number of result
columns, else `SELECTs to the left and right of <op> do not have the same number of result columns`
(`<op>` being the operator where the mismatch is found, left to right). `UNION ALL` concatenates;
`UNION` keeps one of each distinct row of both sides; `INTERSECT` keeps the distinct rows that are in
both; `EXCEPT` keeps the distinct rows of the left side that are not in the right. Rows are equal as
in `SELECT DISTINCT` (3.4); tests do not rely on which of two equal rows of different types (`1`,
`1.0`) is kept.

The trailing `ORDER BY`/`LIMIT`/`OFFSET` apply to the whole result. In a compound select, an
`ORDER BY` term must be an integer literal (the k-th column) or a name that is an alias or column
name of a result column (looked up in the first simple-select, then the next, and so on; tests use
names of the first); a name that matches none is `<i-th> ORDER BY term does not match any column in
the result set`. Tests use no other expressions as `ORDER BY` terms of a compound select. The result's column names are those of the first
simple-select. A compound select may appear wherever a select may (subqueries, `FROM`, views, `WITH`,
`INSERT ... SELECT`).

## 5.2 WITH

```
WITH [RECURSIVE] cte [, cte]... select
cte := name [( column [, column]... )] AS ( select )
```

Each cte is a temporary named source, visible in the ctes after it and anywhere in the statement's
select (including its subqueries); it hides a table of the same name. Tests do not refer to a later
cte, nor mention a cte's own name inside it except in a recursive cte. Its columns are named by the
list, else as for a subquery source (4.1). Two ctes of one name are `duplicate WITH table name:
<name>`.

**Recursive cte** (only after `WITH RECURSIVE`): a cte whose select is `initial UNION [ALL]
recursive`, where initial is one simple-select that does not mention the cte and recursive is one
simple-select whose `FROM` mentions the cte exactly once (not inside a subquery). It is computed
with a queue: run initial and put its rows in the queue; then, while the queue is not empty, take
its first row, add it to the result, and run recursive with the cte standing for that single row,
putting its rows at the end of the queue. With `UNION` (not `ALL`), a row equal to a row already put
in the queue earlier is not put in again. The cte's rows are in the order they were added to the
result (so `group_concat` over a recursive cte without `ORDER BY` is well defined); for every other
source the order stays unspecified. Tests always terminate.

## 5.3 Views

```
CREATE VIEW [IF NOT EXISTS] name [( column [, column]... )] AS select ;
DROP VIEW [IF EXISTS] name ;
```

A view is a named select, run anew wherever the view is used as a source (it sees the tables as they
are then). Its column names are the list, else as for a subquery source. Tables and views share one
name space: creating a table or view whose name is taken is `table <name> already exists` if a
table has it and `view <name> already exists` if a view has it. A view cannot be changed:
`INSERT`/`UPDATE`/`DELETE` on it is `cannot modify <name> because it is a view`. `DROP TABLE` of a
view is `use DROP VIEW to delete view <name>`; `DROP VIEW` of a table is `use DROP TABLE to delete
table <name>`; in these three messages `<name>` is spelled as created, not as written. `DROP VIEW` of
nothing is `no such view: <name>`. `CREATE VIEW` does not check its select: an error in it (an
unknown column, a compound with mismatched counts) is reported by each statement that uses the view.
A table or view may not take an index's name: `there is already an index named <name>`.
A column of a view, cte or subquery source that is a plain column reference keeps that column's
affinity (1.9), so `v.a = '5'` is true for a view column `a` over an INTEGER column holding 5; tests do
not depend on the affinity of a compound select's columns. Tests do not drop, rename or change a
table that a view still uses.

## 5.4 INSERT ... SELECT

```
INSERT INTO table [( column [, column]... )] select ;
```

Inserts the select's rows, exactly as if they had been written as `VALUES` rows (same count errors,
storage, constraints and all-or-nothing). The select is fully computed before any row is inserted.
`WITH` may also start an `INSERT` (`WITH c AS (...) INSERT INTO t SELECT ... FROM c`).

## 5.5 Transactions

```
BEGIN [TRANSACTION] ;     COMMIT [TRANSACTION] ;     END [TRANSACTION] ;     ROLLBACK [TRANSACTION] ;
```

`BEGIN` starts a transaction (inside one: `cannot start a transaction within a transaction`).
`COMMIT` (or `END`) ends it, keeping its changes (with none open: `cannot commit - no transaction is
active`). `ROLLBACK` ends it and undoes every change made since `BEGIN`, including tables, views and
indexes created, dropped or altered (with none open: `cannot rollback - no transaction is active`).
A statement that fails inside a transaction has no effect, and the transaction stays open. A
transaction still open at the end of the script is simply left; it prints nothing.

## 5.6 ALTER TABLE

```
ALTER TABLE table ADD [COLUMN] column-def ;
ALTER TABLE table RENAME TO new-name ;
ALTER TABLE table RENAME [COLUMN] column TO new-name ;
```

- `ADD COLUMN` appends a column; existing rows get its `DEFAULT` value converted to the column's type
  as by 1.5 (`TEXT DEFAULT 7` gives `'7'`), or NULL. `NOT NULL` without a non-NULL `DEFAULT` is
  `Cannot add a NOT NULL column with default value NULL` if the table has rows (on an empty table it
  is allowed); `UNIQUE` is `Cannot
  add a UNIQUE column`; `PRIMARY KEY` is `Cannot add a PRIMARY KEY column`; an existing name is
  `duplicate column name: <name>`.
- `RENAME TO` renames the table (a taken name: `there is already another table or index with this
  name: <new-name>`); its constraints and indexes follow it.
- `RENAME COLUMN` renames a column (one the table does not have: `no such column: "<column>"`, with the
  double quotes); constraints and indexes follow it. Tests do not rename a column to a name the table
  already has.
- An unknown table is `no such table: <name>`. Error messages name tables and columns by their current
  names.

## 5.7 Indexes

```
CREATE [UNIQUE] INDEX [IF NOT EXISTS] name ON table ( column [, column]... ) ;
DROP INDEX [IF EXISTS] name ;
```

An index changes no result. A `UNIQUE` index is a uniqueness constraint (2.1) on its columns, declared
after every constraint that exists when it is created (so it is checked before them); creating it
on rows that already conflict is the constraint's error (`UNIQUE constraint failed: t.a, t.b` with the
index's columns) and creates nothing. Index names have their own name space, except that an index may
not take a table's name: `index <name> already exists`, `there is already a table named <name>`,
`no such index: <name>`. Dropping a table drops its indexes.

## 5.8 Errors added in this stage

`SELECTs to the left and right of <op> do not have the same number of result columns`;
`<i-th> ORDER BY term does not match any column in the result set`; `duplicate WITH table name: <name>`;
`view <name> already exists`; `cannot modify <name> because it is a view`;
`use DROP VIEW to delete view <name>`; `use DROP TABLE to delete table <name>`; `no such view: <name>`;
`cannot start a transaction within a transaction`; `cannot commit - no transaction is active`;
`cannot rollback - no transaction is active`; `Cannot add a NOT NULL column with default value NULL`;
`Cannot add a UNIQUE column`; `Cannot add a PRIMARY KEY column`;
`there is already another table or index with this name: <name>`; `no such column: "<column>"`;
`index <name> already exists`; `there is already a table named <name>`; `no such index: <name>`;
`there is already an index named <name>`.
