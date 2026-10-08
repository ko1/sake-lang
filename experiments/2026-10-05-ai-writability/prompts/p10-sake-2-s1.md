# Brief: a SQL engine in **Sake**, stage 1 of 6

A program that runs SQL scripts (a small subset of SQLite) is being built in stages, each stage adding
to the specification. You do stage 1.

## Material

In `/home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p10-sake-2/`:
- `SPEC.md`: the specification of stages 1..1. 
- `tests/N/NNN-*.sql` with the expected standard output `.out`: the tests of stages 1..1.
- `run_tests.rb`: `ruby /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p10-sake-2/run_tests.rb /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p10-sake-2/code/main.sake --stage 1` runs them all
  (8 at a time) and reports each failure; add name substrings (`3/012`, `group`) to run a subset.
  For Sake it first checks the program with `/home/ko1/app/sake/bin/sake --strict=2 -c` (this can take minutes on a large program; a program it rejects does not run), then runs each test at `--strict=0`.
- `code/`: empty: the program goes here, entry `main.sake`.

## Your job

Write the program in `code/`, entry `main.sake`: it reads a SQL script from standard input and runs it, as SPEC.md says. Organise the program in several files, each a clear part of a database engine, written as
a careful maintainer would want to inherit it: the next stages will be done by others who start from
your code.

Done means every test of stages 1..1 passes. The tests do not cover everything: the program will
also be judged by tests you do not see, so implement what SPEC.md says, not only what the tests show.

## Rules

Work only in `/home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p10-sake-2/code/`. Do not change SPEC.md, the tests or run_tests.rb. Use no database
library and start no other program from the engine; do not look for other SQL implementations or
other runs of this task (do not read anything under `/home/ko1/app/sake/experiments/` outside your directory), and do not search the web. No git. Shell commands need
`dangerouslyDisableSandbox: true`. Do not wait for processes by matching their names (`pgrep -f`
matches your own command); run the tests in the foreground. Reply in under 150 words: the file list
with line counts, the test result, and the hardest part of this stage (one line each).

**Sake** (in `/home/ko1/app/sake`): Ruby syntax where every operation is written with its type (`String.upcase(s)`, not `s.upcase`). Learn it from `docs/tutorial.md` (start here), `docs/spec.md` and `docs/builtins.md`; these are the only documents you may read. Run a program with `/home/ko1/app/sake/bin/sake --strict=2 main.sake`.
