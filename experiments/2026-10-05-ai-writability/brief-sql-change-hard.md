# Brief: write the hard form of change CHANGE (AI writability, P11 hard variant)

A change request for a SQL engine exists: `large/sql/changes/CHANGE/change.md` (in
`/home/ko1/app/sake/experiments/2026-10-05-ai-writability/`). It describes the change site by site and ends
with a list, "Where it applies", of every place in SQL where the change shows. Agents who make the change from
that text are told where to look. In the hard form they are not: they must find, in the engine's code, every
place the change reaches.

## Your job

Write `large/sql/changes/CHANGE/change-hard.md`, the same change with the same meaning, stated by concept
instead of by site:

- Keep every rule the original states, so that each hidden test's expected output still follows from the
  text: definitions (what a collation / a BLOB / the rowid is), the new syntax, how values behave (order,
  equality, conversion, printing), precedence rules, error messages, and edge cases.
- State them as general rules about the concept ("every comparison, sort, grouping or duplicate removal of
  TEXT uses the collation chosen as follows"; "a BLOB orders after every TEXT value"; "every table row has a
  rowid"), not as a tour of the places in SQL where they show. Do not list or enumerate SQL features or
  clauses where the change applies (no "this affects ORDER BY, GROUP BY, DISTINCT, UNION, ..."), and drop the
  "Where it applies" section. A rule that only exists for one feature (an exception, a special case) stays,
  stated as that rule.
- Keep the examples that illustrate a concept; drop examples whose only point is to show that the change
  reaches some feature.
- Start with `# Change: <title>` like the original.

Then check your text: read every hidden test in `tasks/sql-change-hidden/CHANGE/7/` and, for each, confirm
that its expected output (`.out`) follows from spec files 1-6 (`large/sql/spec/`) and change-hard.md alone.
Record any test that does not in `large/sql/changes/CHANGE/hard-notes.md` with the missing rule, and add that
rule to change-hard.md in general form. Also record in hard-notes.md, for each site of the original's list, the
general rule of change-hard.md it follows from.

## Rules

Work only in `large/sql/changes/CHANGE/change-hard.md` and `hard-notes.md`. You may run `python3`'s
`sqlite3` to confirm SQLite's behaviour. Do not read `runs/`. No git. Shell commands need
`dangerouslyDisableSandbox: true`. Reply in under 150 words: the length of change.md and change-hard.md (lines),
the rules you had to add after checking the tests, and anything you could not state without naming sites.
