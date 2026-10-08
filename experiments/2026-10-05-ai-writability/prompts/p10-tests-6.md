# Brief: write the tests for stage 6 of a small SQL engine (AI writability, P10)

Other AI agents will build, in stages, a program that runs SQL scripts, from a specification. You
write the tests for stage 6, and you check the specification against SQLite while doing it.

## Material

`/home/ko1/app/sake/experiments/2026-10-05-ai-writability/large/sql/spec/`: the specification, one
file per stage (`1-core.md` ... `6-windows.md`). Stage 6's program implements files 1..6.
Read them all up to 6; stage 6's file is your subject.

`harness/sql_oracle.py` computes a test's expected output with SQLite, adapted to the specification
(read its docstring): `python3 harness/sql_oracle.py --write FILE.sql...` writes `FILE.out` next to
each file, or prints `REJECT <file>: <reason>` and writes nothing for a test it cannot use (an error
message outside the spec, an order the spec leaves open, a REAL that SQLite prints differently).
`python3 harness/sql_oracle.py FILE.sql` prints one file's output.

## Your job

Write two sets of tests for stage 6, each file a script of SQL statements (`NNN-topic.sql`,
numbered from 001, topic in a few lowercase words joined by `-`):

- `large/sql/tests/6/`: the **public** tests, about 40 files. The builders see these.
- `tasks/sql-hidden/6/`: the **hidden** tests, about 40 files. Nobody building sees them; they
  measure whether a program follows the specification beyond the public tests. They test the same
  rules as the public set with different statements and data, and more combinations of rules; they
  are not copies or renamings of public tests.

Then run the oracle with `--write` on both directories until it rejects nothing.

Coverage: between the two sets, every rule, every example, every function and every error message of
stage 6's file has at least one public and one hidden test. Combine stage 6's features with
earlier stages' features in natural ways (a stage 3 test may use constraints and `UPDATE`); never use
a feature from a later stage (stage 6 is the last). About a fifth of the tests should be longer
"scenario" scripts (a small application's tables, 20-40 statements); the rest are focused, 3-25
statements each. Each test is under 60 lines and prints at least one line.

Rules for every test:
- Use only what the specification defines, written as it describes (every statement ends with `;`;
  types `INTEGER`, `REAL`, `TEXT`; ASCII text; integers far from 64-bit limits).
- Make the output fully determined by the specification: every query whose result has more than one
  row has an `ORDER BY` that orders its rows completely (the oracle rejects most violations, but not
  all: a bare column in a group with different values, ties among rows that print the same, a
  scalar subquery's "first row"); at most one error per statement.
- Check every output you write against the specification yourself. When SQLite's output disagrees
  with what the specification says (not merely with your guess), that is a **specification issue**:
  do not keep a test that depends on the disputed point; record it in
  `large/sql/spec-issues/6.md` (create it): the statement, SQLite's output, the spec's
  section, and what the spec says. Also record any rule you found unclear or ambiguous. Do not edit the
  specification.

## Rules

Work only in `large/sql/tests/6/`, `tasks/sql-hidden/6/` and `large/sql/spec-issues/6.md`
(relative to `/home/ko1/app/sake/experiments/2026-10-05-ai-writability`); you may read the other
stages' tests for style but not change them. Do not read `runs/`, other `tasks/` or `large/mini/`.
No git. Shell commands need `dangerouslyDisableSandbox: true`. Reply in under 150 words: the counts,
the number of oracle rejections you had to fix and why, and the specification issues (one line each).
