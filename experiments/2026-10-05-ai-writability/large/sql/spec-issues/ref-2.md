# Reference implementation, stage 2: where the tests and the specification disagree

Implementation: `large/sql/ref/` (Ruby 4.0.2). SQLite 3.x through `harness/sql_oracle.py` (STRICT
tables) for the probes below. Result (stages 1-2): public 144/144, hidden 147/147.

## A. Tests whose expected output contradicts the specification

None. Every public and hidden test of stages 1-2 agrees with the specification as the reference
reads it. The stage 1 cases of `ref-1.md` (keywords as names, the oracle's comment stripping) are
fixed in the current tests and spec.

## B. Places where SQLite and the specification differ (no test depends on them)

The reference follows the specification in each case.

1. **The INTEGER PRIMARY KEY's datatype check comes before NOT NULL in SQLite (2.1).**
   ```sql
   CREATE TABLE k (id INTEGER PRIMARY KEY, a TEXT NOT NULL);
   INSERT INTO k VALUES ('abc', NULL);
   ```
   SQLite: `Error: datatype mismatch`. Spec 2.1 ("`NOT NULL` of each column in column order; then
   the INTEGER PRIMARY KEY's value"): `Error: NOT NULL constraint failed: k.a`. Same with `2.5` as the
   key. Judgement: the spec's order is clear; if a test ever has both errors in one row, its oracle
   output will be wrong. Either the spec should move the key's datatype check first, or the tests
   must keep avoiding it.

2. **UPDATE that sets an INTEGER PRIMARY KEY declared `NOT NULL` to NULL (2.1).**
   ```sql
   CREATE TABLE p (id INTEGER PRIMARY KEY NOT NULL, v TEXT);
   INSERT INTO p VALUES (1, 'a');
   UPDATE p SET id = NULL;
   ```
   SQLite: `Error: datatype mismatch`. Spec: NOT NULL is checked first, so
   `NOT NULL constraint failed: p.id`; the exemption ("this holds even if it is also declared
   NOT NULL") is stated only for the INSERT case that assigns a key. Judgement: unclear in the spec;
   the reference applies NOT NULL (the stated order). Say which error wins.

3. **`x IN (...)` when x has TEXT affinity and an ei has numeric affinity (2.3).**
   ```sql
   CREATE TABLE t (s TEXT, r REAL);
   INSERT INTO t VALUES ('12.5', 12.5);
   SELECT s IN (r), s = r FROM t;
   ```
   SQLite: `1|1` (it converts every ei by x's affinity: r becomes `'12.5'`). Spec 2.3: "each ei is
   converted as rule 1 or 2 of 1.9 would convert it against x"; against x (TEXT) and r (REAL), rule 1
   converts x, not r, and rule 2 does not apply (r has an affinity), so nothing is converted and the
   result is `0|1`. The reference gives `0|1`. Judgement: the spec's wording probably means "converted
   to x's affinity" (SQLite); reword as "if x has INTEGER or REAL affinity, each ei that is numeric
   text is converted to the number; if x has TEXT affinity, each ei that is a number is converted to
   its text form".

4. **`CAST(text AS INTEGER)` skips only spaces in the spec (2.3).**
   `SELECT CAST('<tab>12' AS INTEGER), CAST('<newline>5' AS INTEGER);` SQLite: `12|5`. Spec: "the
   longest prefix (after leading spaces)" gives `0|0` (the reference). Spec 1.5 and the numeric prefix
   of 1.8 now say "whitespace (space, tab, newline, carriage return)"; 2.3 should say the same.
   (`trim(x)` removes only spaces in SQLite too, so "spaces" is right there.)

## C. Rules that are unclear or missing (tests do not decide them)

5. **`max(x)` / `min(x)` with one argument (2.4).** The reference reports
   `wrong number of arguments to function max()` ("two or more arguments"); SQLite treats it as the
   stage 3 aggregate. Stage 3 changes the answer, so stage 2 tests should keep avoiding it.
6. **Grammar narrower than SQLite, as intended?** SQLite accepts `DEFAULT -'3'`, `DEFAULT (3)` and
   `x IN ()` (an empty list, always 0); the spec's grammar makes them syntax errors (the reference
   does so). Fine as long as tests do not use them.
7. **A table constraint naming an unknown column** (`PRIMARY KEY (zz)`): SQLite says
   `no such column: zz` (a catalogue message); the spec does not mention it. The reference does the same.
