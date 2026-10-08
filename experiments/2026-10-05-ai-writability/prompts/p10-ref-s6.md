# Brief: the reference implementation of a small SQL engine, stage 6 (AI writability, P10)

Other AI agents will build, in stages, a program that runs SQL scripts, from a specification. Before
they do, the specification and its tests must be right. You build the reference implementation in
Ruby, stage by stage; this time, stage 6. Your main product is not the code but the list of
places where the tests and the specification disagree.

## Material

In `/home/ko1/app/sake/experiments/2026-10-05-ai-writability/`:
- `large/sql/spec/1-core.md` ... `6-windows.md`: the specification, one file per stage. Implement
  files 1..6.
- `large/sql/tests/N/*.sql` (public) and `tasks/sql-hidden/N/*.sql` (hidden), each with the expected
  output `.out`, computed by SQLite through `harness/sql_oracle.py` (read its docstring).
- `large/sql/run_tests.rb`: `ruby large/sql/run_tests.rb large/sql/ref/main.rb --stage 6` runs
  the public tests of stages 1..6; prefix `SQL_TESTS=tasks/sql-hidden` for the hidden ones.
- `large/sql/ref/`: the implementation of stages 1..5 (entry `main.rb`), which passes all their tests. Extend it; restructure where stage 6 calls for it.

## Your job

1. Make `large/sql/ref/main.rb` (and its files, loaded with `require_relative`) pass every public
   and hidden test of stages 1..6. Plain Ruby 4.0 with the standard library; no database library,
   no other programs. Write it as a clear, well-organised program (it may later serve as a fixed
   starting point for others), not a pile of special cases.
2. Whenever a test's expected output disagrees with what the specification says, decide which is
   wrong. Do not make the program follow a test against the specification's words: record the case in
   `large/sql/spec-issues/ref-6.md` (the test, the expected and the specified output, the spec's
   section, your judgement), and continue with the other tests. Also record rules you found unclear,
   ambiguous or missing (where you had to read SQLite's behaviour off the tests). Do not edit the
   specification or the tests.

## Rules

Work only in `large/sql/ref/` and `large/sql/spec-issues/ref-6.md`. You may run `python3`'s
`sqlite3` module to explore SQLite's behaviour, but the engine must not use it. Do not read `runs/`
or other `tasks/` directories than `tasks/sql-hidden/`. No git. Shell commands need
`dangerouslyDisableSandbox: true`. Do not wait for processes by matching their names (`pgrep -f`
matches your own command). Reply in under 200 words: the file list with line counts, the test
results (public and hidden), and each disagreement you recorded (one line each).
