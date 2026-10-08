# c3-rowid: notes on change-hard.md

## Check against the hidden tests (tasks/sql-change-hidden/c3-rowid/7/, 44 tests)

Every test's `.out` follows from spec 1-6 plus change-hard.md. Points that needed care:

- 039-alter-ipk-rename: the error after `RENAME COLUMN id TO key2` is `UNIQUE constraint failed:
  gx.key2`. change.md says the INTEGER PRIMARY KEY is named "as in the `CREATE TABLE`", which read
  literally gives `gx.id`; 5.6 ("error messages name tables and columns by their current names")
  gives the right answer. change-hard.md 7.2 now says "by its current name, 5.6" explicitly.
- 017-insert-explicit-null: `INSERT INTO pr (rowid, a, b) VALUES (9, 'x')` is `2 values for 3
  columns` and `INSERT INTO pr VALUES (20, 'y', 3)` is `table pr has 2 columns ...`. The first needs
  "a rowid name in the column list counts as one listed column" (stated in 7.3), the second the
  "hidden" rule of 7.1 (counts of the table's columns are real columns only). Both were implicit in
  change.md; change-hard.md states them generally.
- 016-insert-explicit-conversion: `1e1` stores 10 and `'15x'` is `datatype mismatch`; both follow
  from 1.5 conversion, added to the 7.3 examples for clarity only.
- 035-correlated-no-from: `UPDATE q2 SET c = (SELECT ... WHERE q3.rowid = q2.rowid)` follows from 4.2
  (the UPDATE target is an enclosing source) plus "a rowid name obeys every rule for column names".
- 014-join-names-ambiguous (`FROM l, (SELECT 5 AS z) WHERE oid = 1` is ambiguous) needs the special
  rule "unqualified with several sources", kept as a rule in 7.1.

No test required a rule that is absent from change-hard.md.

## Sites of change.md's "Where it applies" -> general rule in change-hard.md

| site | follows from |
|---|---|
| names | 7.1 "a column of the table, after the real ones" (usable wherever a column name is, all lookup rules of 1.7/3.3/4.2) + "value and affinity"; `INSERT ... VALUES` error from "no such column where no row is in scope" (1.6) |
| star | 7.1 "hidden": whatever stands for the columns of a table sees real columns only |
| hidden | 7.1 "a real column wins", incl. a column that came to exist later |
| alias | 7.1: a rowid name is a column of the table, so the column-before-alias order of 1.7/3.3 applies (worked example kept) |
| qualified | 7.1: qualified lookup, alias rule and NULL-extension are the column rules of 4.1/4.2 |
| join-names | 7.1 "unqualified with several sources" (special rule) + "hidden" (matching by name sees real columns only) |
| insert-explicit | 7.3 "storing into the rowid" + "a new row's rowid" (conversion, NULL = assign) |
| auto-number | 7.3 "a new row's rowid" (largest present + 1, row by row) + 7.4 (removed rows take their rowids) |
| unique | 7.3 "uniqueness" (message, check order, all-or-nothing) |
| update | 7.3 "storing into the rowid" + "changing an existing row's rowid" (NULL mismatch, old values) |
| integer-primary-key | 7.2 |
| insert-select | 7.3 "rows stored one at a time in the order produced; a select's rows in its ORDER BY order"; supplying rowids from a select is "storing into the rowid" + 5.4 |
| derived | 7.1 "only tables have rowids" + "a real column wins" |
| correlated | 7.1: rowid names obey the column rules of 4.2/4.3 (correlation, no-FROM lookup outward) |
| window | 7.1: usable wherever a column name is (no rowid-specific rule needed) |
| alter | 7.4: anything that keeps a row (incl. changes to the table's name or columns) keeps its rowid; 7.2 current name of a renamed INTEGER PRIMARY KEY |
| transaction | 7.4: restoring rows restores their rowids; numbering from the largest present |

## Not stated without naming a site

- The "hidden" rule names its three consequences (`*`/`q.*`, a row given without a column list,
  matching columns by name between sources) because each has its own error message or output that a
  test checks; they are stated as instances of "the columns of a table", not as a list of clauses.
- "Undoing a transaction, 5.5" is named in 7.4 as the one way rows are restored.
- The bare-`ORDER BY`-alias example is kept because it is the one case where the column-before-alias
  order gives a visibly different answer.
