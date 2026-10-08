# Brief: check change CHANGE of a small SQL engine by implementing it (AI writability, P11)

A change request for a SQL engine has been written (its specification and tests). Before other agents are
asked to make the change, the request must be right. You make the change in the reference implementation
(Ruby). Your main product is not the code but the list of places where the tests and the change's
specification disagree, or where the specification is unclear.

## Material

In `/home/ko1/app/sake/experiments/2026-10-05-ai-writability/`:
- `large/sql/spec/1-core.md` ... `6-windows.md`: the specification the engine implements.
- `large/sql/changes/CHANGE/change.md`: the change.
- `large/sql/ref/`: the reference engine (Ruby), passing every test of stages 1-6. Do not change it.
- Tests (each `.sql` with its expected `.out`, computed by SQLite through `harness/sql_oracle.py`):
  stages 1-6 public `large/sql/tests/`, hidden `tasks/sql-hidden/`; the change's public
  `large/sql/changes/CHANGE/tests/` and hidden `tasks/sql-change-hidden/CHANGE/` (both in a directory `7/`).
- `large/sql/run_tests.rb MAIN`: runs the tests; `SQL_TESTS=<dir>` picks the test directory.

## Your job

1. Copy `large/sql/ref/` to `large/sql/changes/CHANGE/ref/` and make the change there, as a careful
   maintainer would, until it passes all four test sets:
   `SQL_TESTS=<dir> ruby large/sql/run_tests.rb large/sql/changes/CHANGE/ref/main.rb` for each `<dir>`.
2. Whenever a test's expected output disagrees with change.md (or with spec files 1-6), decide which is
   wrong. Do not make the program follow a test against the specification's words: record the case in
   `large/sql/spec-issues/ref-CHANGE.md` (the test, expected and specified output, the section, your
   judgement) and continue. Record also rules you found unclear, ambiguous or missing, and any site in
   change.md's "Where it applies" whose hidden tests do not really test it. Do not edit change.md or the
   tests.

## Rules

Work only in `large/sql/changes/CHANGE/ref/` and `large/sql/spec-issues/ref-CHANGE.md`. You may run
`python3`'s `sqlite3` module to explore SQLite's behaviour; the engine must not use it. Do not read
`runs/`. No git. Shell commands need `dangerouslyDisableSandbox: true`. Do not wait for processes by
matching their names. Reply in under 200 words: the files you changed with lines added, the four test
results, and each disagreement you recorded (one line each).
