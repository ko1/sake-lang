# Spec issues found by the reference implementation: c1-collate

Implementation: `large/sql/changes/c1-collate/ref/` (copy of `large/sql/ref/`, Ruby). Probes ran on
SQLite 3.46.1 (python3 `sqlite3`).
Results: stages 1-6 public 366/366, hidden 369/369; change public 8/8, change hidden 48/48.
`ruby -wc` is clean on every file.

Changed files (lines added/removed): values.rb +52/-6 (module `Collation`: names, lookup, compare key,
the choice rule of 7.4; `compare`/`compare_ordered`/`equality_key` take a collation), expressions.rb
+67/-21 (every bound expression answers `collation`; new `Collate`; comparisons, BETWEEN, IN, IN
(select), CASE x use it), query.rb +55/-27 (compound collations, collated row keys and compound
ORDER BY), select_query.rb +27/-13, parser.rb +16/-3, aggregates.rb +14/-12, schema.rb +14/-6,
table.rb +11/-10, binder.rb +10/-3, from_clause.rb +8/-7, scope.rb +8/-7, ast.rb +5/-3,
windows.rb +5/-4, lexer.rb +1/-1, database.rb +1/-1, catalog.rb +1/-0.

## A. Tests that disagree with the specification

None. Every expected output of the 8 public and 48 hidden tests follows from change.md and spec 1-6;
the implementation follows change.md's words and passes all of them.

## B. "Where it applies" sites the hidden tests do not really test

Checked by mutation: for each site, a copy of the implementation with that site's collation removed
(or chosen wrongly) was run against the hidden tests. Every site's mutant failed at least one hidden
test except one:

1. **min-max, as window functions** (7.4: "`min(x)`, `max(x)` (aggregate, and as window
   functions)"). Hidden `7/027-min-max-window` passes when window `min`/`max` compare under BINARY:
   its data (`'m','B','z','A','Q'` in a NOCASE column) has the same running min and max under
   BINARY and NOCASE, and its second query writes `COLLATE BINARY` explicitly. A distinguishing
   case, e.g. `INSERT INTO q VALUES (1, 'b'), (2, 'C'), (3, 'a')` with
   `SELECT id, max(v) OVER (ORDER BY id), min(v) OVER (ORDER BY id)`, gives `1|b|b`, `2|C|b`,
   `3|C|a` in SQLite (and here) but `2|b|C`, `3|b|C` under BINARY. The aggregate form is tested
   (025, 026). Suggest replacing 027's data with such values.

Weak but real: compound ORDER BY (only 029 catches a compound ORDER BY that ignores the column
collation), `GROUP BY 1` taking the result column's collation (only 020), `USING` taking the left
column's collation (only 041), the group_concat ORDER BY (only 018) and window ORDER BY peers
(only 043) are each caught by one test.

## C. Rules found unclear, ambiguous or missing

1. **`x IN (select)` when the select is a compound.** 7.4 says e is "the subquery's result column
   expression as written in the subquery", which is undefined for a compound. SQLite takes the
   *last* simple-select's expression: with `t.name TEXT COLLATE NOCASE` holding `'abc'`,
   `'ABC' IN (SELECT 'x' UNION SELECT name FROM t)` is 1 but
   `'ABC' IN (SELECT name FROM t UNION SELECT 'x')` is 0. The implementation uses the compound's
   column collation (the 7.4 compound rule, first part that has one), which gives 1 for both. No
   test depends on it (hidden 046 has a compound in `IN`, but a column is on the left, so it wins).
   Suggest: "Tests do not use a compound select on the right of IN unless x has a collation."
2. **Column of a compound select used as a source.** 7.5 excludes it from tests, so it is fine, but
   `spec-issues/c1-collate.md` item 7 describes SQLite as giving "the compound's collation (7.4)".
   SQLite actually uses the *first* simple-select only: `SELECT x FROM (SELECT 'zzz' AS x UNION ALL
   SELECT name FROM t) WHERE x = 'ABC'` returns nothing (BINARY), although the 7.4 rule would pick
   the second part's NOCASE. (Its example has the column in the first part, so it does not show the
   difference.) The implementation uses the 7.4 rule. Only the note needs correcting.
3. **An unknown name where no comparison uses it.** 7.2 says any name other than the three "is the
   error", and the implementation raises it wherever `COLLATE` is bound (also `SELECT 'a' COLLATE
   Foo`). SQLite raises it only where the collation is used (`SELECT 'a' COLLATE Foo` prints `a`).
   The test restriction in 7.2 avoids the difference; the sentence "A collation name other than
   the three is the error" could say "where it is used (tests: ...)" to match.
4. **Dedupe of a compound with an ORDER BY term's own COLLATE.** 7.4 says UNION/INTERSECT/EXCEPT
   compare under the column collations and the ORDER BY term's COLLATE only sorts. SQLite agrees
   (`SELECT 'a' COLLATE NOCASE UNION SELECT 'A' ORDER BY 1 COLLATE BINARY` is one row;
   `SELECT 'a' UNION SELECT 'A' ORDER BY 1 COLLATE NOCASE` is two). Not unclear, but untested:
   no hidden test combines UNION (not ALL) with a COLLATE on the ORDER BY term.
5. **Recursive ctes.** 7.4's compound rule is not said to apply to `WITH RECURSIVE ... UNION` (its
   dedupe and its ORDER BY). The implementation applies it (initial part first, then the recursive
   part; inside the recursive part the cte's columns have the initial part's collations). Untested.
6. **Error order in a column definition.** 7.2 says the statement "fails and creates nothing" but
   not which error comes first when a statement has another error too. Tests have one error per
   statement (1.12), so this is only a note: the implementation checks a column's duplicate name
   before its collation, and in `ALTER TABLE ADD COLUMN` the collation before "Cannot add a
   PRIMARY KEY/UNIQUE column", as SQLite's parser does.
7. **Implicit BINARY counts as "has a collation" in the compound rule.** 7.3 makes every column
   reference implicit (BINARY when undeclared), so in `SELECT code FROM t UNION SELECT name FROM t`
   the first part decides (BINARY). 7.4 states this with its example, but the phrase "whose k-th
   result column has a collation" reads as if BINARY columns might be skipped; the example is
   what makes it clear.
