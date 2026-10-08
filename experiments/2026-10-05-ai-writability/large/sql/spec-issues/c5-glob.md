# Spec issues: c5-glob

No disagreement between SQLite (3.46.1) and spec files 1-6 was found while writing this change.

Rules dropped as unclear (change.md says tests do not use these):

- `x GLOB p ESCAPE e`: SQLite parses it but fails with `wrong number of arguments to function glob()`,
  a message that does not describe the construct. Dropped; change.md says GLOB has no ESCAPE clause.
- Whether an invalid `ESCAPE` behind `AND`/`OR`/an untaken `CASE` branch is evaluated: SQLite
  short-circuits (`SELECT 0 AND 'a' LIKE 'a' ESCAPE 'ab'` prints 0; `... AND id < 3` skipped the
  failing row), but the spec never defines evaluation order of `AND`/`OR`. Tests do not depend on it.
- A letter as the escape character: SQLite compares the escape character case-sensitively while
  the rest of LIKE ignores case. Tests use non-letter escape characters only.
- GLOB class corner cases: ranges whose ends are `]` or `-`, a `-` directly after a range
  (`[a-c-e]`), and the empty class `[]` / `[^]` (which SQLite treats as unclosed). Not specified.
- The function forms `glob(p, x)` and `like(p, x[, e])` (arguments in reverse order). Not part of
  this change.
