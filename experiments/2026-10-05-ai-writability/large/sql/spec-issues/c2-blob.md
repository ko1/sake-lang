# Change c2 (BLOB values): specification issues

Found while writing `changes/c2-blob/change.md` and its tests, checked with SQLite 3.46.1 (STRICT
tables, via `harness/sql_oracle.py`). No test depends on any point below.

## Disagreements between SQLite and specification files 1-6

None found. (Where SQLite's behaviour with BLOBs looked surprising, change.md states it as the rule;
see "Rules worth noticing".)

## Candidate sites dropped as unclear

1. **LIKE with a BLOB operand.** `X'41' LIKE 'A'`, `'A' LIKE X'41'` and even `X'41' LIKE X'41'` are 0
   in SQLite, while `CAST(X'41' AS TEXT) LIKE 'a'` is 1. Not explainable as "text form" or as
   byte matching in a sentence; change.md says tests do not use LIKE with a BLOB.
2. **ALTER TABLE ... ADD COLUMN with a DEFAULT the column cannot store.** On a table with rows,
   `ALTER TABLE t ADD COLUMN y BLOB DEFAULT 7` (and `INTEGER DEFAULT X'31'`) is
   `Error: type mismatch on DEFAULT`, a message not in the catalogue; on an empty table it succeeds
   and the later `INSERT` fails with the storage error. Stage 5 does not cover the analogous TEXT /
   INTEGER case either. change.md says tests do not do this.
3. **A blob literal with a space between `X` and the quote** (`X 'AB'`) is the name `X` followed by a
   string (`no such column: X`), not a literal. Tests always write `X'..'` without a space.

## Rules worth noticing (kept, stated in change.md)

- Storing an INTEGER into a BLOB column is `cannot store INT value in BLOB column t.b` — `INT`, not
  `INTEGER` (stage 1 never rejects an INTEGER, so this spelling is new). catalogue.txt allows `INT`.
- `hex(NULL)` is the empty TEXT `''`, not NULL.
- In `sum`/`total`/`avg` a BLOB is always a non-INTEGER: `sum(X'3132')` is `12.0`, whereas
  `sum('12')` is the INTEGER 12 (3.2).
- `substr` of a BLOB is a BLOB; `upper`, `lower`, `trim`, `replace`, `||` and `group_concat` of
  BLOBs are TEXT; `instr` searches bytes only when both arguments are BLOBs.

## Oracle limitation

`round()` of a BLOB (SQLite: `round(X'3132')` = 12.0) cannot be checked: the oracle replaces `round`
with a Python function that fails on bytes (`user-defined function raised exception`). change.md keeps
the rule (7.8, BLOB read by numeric prefix like TEXT); no test calls `round` on a BLOB.
