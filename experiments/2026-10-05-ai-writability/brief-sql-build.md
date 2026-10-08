# Brief: a SQL engine in **LANG**, stage STAGE of 6

A program that runs SQL scripts (a small subset of SQLite) is being built in stages, each stage adding
to the specification. You do stage STAGE.

## Material

In `WORK_DIR/`:
- `SPEC.md`: the specification of stages 1..STAGE. NEW_NOTE
- `tests/N/NNN-*.sql` with the expected standard output `.out`: the tests of stages 1..STAGE.
- `run_tests.rb`: `ruby WORK_DIR/run_tests.rb WORK_DIR/code/main.EXT --stage STAGE` runs them all
  (8 at a time) and reports each failure; add name substrings (`3/012`, `group`) to run a subset.
  CHECK_NOTE
- `code/`: CODE_NOTE

## Your job

JOB_NOTE Organise the program in several files, each a clear part of a database engine, written as
a careful maintainer would want to inherit it: the next stages will be done by others who start from
your code.

Done means every test of stages 1..STAGE passes. The tests do not cover everything: the program will
also be judged by tests you do not see, so implement what SPEC.md says, not only what the tests show.

## Rules

Work only in `WORK_DIR/code/`. Do not change SPEC.md, the tests or run_tests.rb. Use no database
library and start no other program from the engine; do not look for other SQL implementations or
other runs of this task (do not read anything under `/home/ko1/app/sake/experiments/` outside your directory), and do not search the web. No git. Shell commands need
`dangerouslyDisableSandbox: true`. Do not wait for processes by matching their names (`pgrep -f`
matches your own command); run the tests in the foreground. Reply in under 150 words: the file list
with line counts, the test result, and the hardest part of this stage (one line each).

LANG_NOTE
