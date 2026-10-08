# c1-collate specification issues (found while writing the change tests)

SQLite 3.46.1 through `harness/sql_oracle.py`. No disagreement with spec files 1-6 was found. Every
candidate site of the outline was kept. The points below are SQLite behaviours that change.md
leaves out on purpose (tests do not depend on them), because they are irregular or hard to state.

## Rules dropped as unclear

1. **An explicit COLLATE inside a larger expression propagates outward.** `SELECT 'x' || 'A' COLLATE NOCASE = 'xa';`
   prints `1` (the `||` expression takes NOCASE from its operand), and so does
   `(a COLLATE NOCASE || 'x') = 'ABCX'`. A column's own (implicit) collation does not propagate
   (`name || '' = 'abc'` is BINARY). change.md 7.3 says such expressions have no collation and tests
   do not compare an expression that contains a nested `COLLATE`.
2. **An unknown collation name is an error only where a comparison or ordering uses it.**
   `SELECT 'a' COLLATE Foo;` prints `a`, while `SELECT 'a' COLLATE Foo = 'b';` is
   `Error: no such collation sequence: Foo`. change.md 7.2 lets tests use an unknown name in an
   expression only on a direct comparison operand or an `ORDER BY` term.
3. **`COLLATE` on an element of an `IN` list.** A one-element list behaves like `=`:
   with a BINARY column `b` holding `'abc'`, `b IN ('ABC' COLLATE NOCASE)` is 1 but
   `b IN ('X', 'ABC' COLLATE NOCASE)` is 0. change.md 7.4 uses x's collation only and tests do not
   write `COLLATE` on a list element.
4. **Two `COLLATE` clauses on one column**: the last one wins
   (`x TEXT COLLATE NOCASE NOT NULL DEFAULT 'q' COLLATE BINARY` is BINARY). Tests give at most one.
5. **`nullif` and the scalar `min`/`max` use collations.** With `a TEXT COLLATE NOCASE` holding
   `'Abc'`, `nullif(a, 'ABC')` is NULL. Spec 1.11 defines `nullif` as `x = y` "compared without
   affinity", silent on collation; extending it would be a separate site. Tests do not pass collated
   values to these functions.
6. **Which of several rows equal under a collation is printed** (a `GROUP BY` column or bare column,
   `SELECT DISTINCT`, `UNION`/`INTERSECT`, `group_concat(DISTINCT ...)`, a tie in `min`/`max`).
   SQLite picks one by its plan. change.md leaves it unspecified; tests print `lower(...)`,
   `upper(...)` or counts instead.
7. **Collation of a compound select used as a source** (a view or subquery whose select is a
   compound): SQLite gives the column the compound's collation (7.4), e.g.
   `SELECT k = 'abc' FROM (SELECT a AS k FROM t UNION ALL SELECT 'X')` uses `a`'s NOCASE. Like the
   affinity of such columns (5.3), tests do not depend on it.
8. **`COLLATE` after a unary operator** (`-x COLLATE NOCASE`, `NOT x COLLATE ...`): the relative
   precedence was not established with a distinguishing test, so change.md keeps it out of tests.

## Noted, kept in change.md

- `+e` and `CAST(e AS ...)` keep e's collation although `+e` loses its affinity
  (`+name = 'X'` uses the column's NOCASE): stated in 7.3, tested (public 004, hidden 006).
- A scalar subquery has no collation even when its result column is a NOCASE column or carries an
  explicit `COLLATE`, although it does carry the column's affinity (4.3): stated in 7.5, tested.
- A column of a view, cte or subquery source defined as `c COLLATE n` gets n as an *implicit*
  collation, so a column on the other side of `=` wins when it is on the left: stated in 7.5, tested.
