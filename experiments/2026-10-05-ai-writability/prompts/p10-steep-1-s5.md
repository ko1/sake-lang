# Brief: a SQL engine in **Ruby (4.0) type-checked with Steep**, stage 5 of 6

A program that runs SQL scripts (a small subset of SQLite) is being built in stages, each stage adding
to the specification. You do stage 5.

## Material

In `/home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p10-steep-1/`:
- `SPEC.md`: the specification of stages 1..5. Stage 5 (the last part, "Stage 5: ...") is new in this task; stages 1..4 are what the program already does.
- `tests/N/NNN-*.sql` with the expected standard output `.out`: the tests of stages 1..5.
- `run_tests.rb`: `ruby /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p10-steep-1/run_tests.rb /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p10-steep-1/code/main.rb --steep --stage 5` runs them all
  (8 at a time) and reports each failure; add name substrings (`3/012`, `group`) to run a subset.
  With `--steep` it first type-checks the program with Steep (a program it rejects does not run): every `.rb` file under `code/` against the RBS signatures in `code/sig/`, with Steep's strict diagnostics, and any problem reported (warnings included) fails; so does `untyped` in a signature or a `steep:ignore` comment. Then each test runs with `ruby`.
- `code/`: the program so far, entry `main.rb`, written by the previous stages; it passes every test of stages 1..4.

## Your job

Extend the program in `code/` to stage 5, keeping stages 1..4 working. Restructure what the new stage calls for. Organise the program in several files, each a clear part of a database engine, written as
a careful maintainer would want to inherit it: the next stages will be done by others who start from
your code.

Done means every test of stages 1..5 passes. The tests do not cover everything: the program will
also be judged by tests you do not see, so implement what SPEC.md says, not only what the tests show.

## Rules

Work only in `/home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p10-steep-1/code/`. Do not change SPEC.md, the tests or run_tests.rb. Use no database
library and start no other program from the engine; do not look for other SQL implementations or
other runs of this task (do not read anything under `/home/ko1/app/sake/experiments/` outside your directory), and do not search the web. No git. Shell commands need
`dangerouslyDisableSandbox: true`. Do not wait for processes by matching their names (`pgrep -f`
matches your own command); run the tests in the foreground. Reply in under 150 words: the file list
with line counts, the test result, and the hardest part of this stage (one line each).

**Steep** (2.1.0, RBS 4.2.0): write an RBS signature for every class, module, method, instance variable and constant in `code/sig/*.rbs`, without `untyped`. Run the check alone with `ruby /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p10-steep-1/run_tests.rb /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p10-steep-1/code/main.rb --steep no-such-test` (it prints the check's result, then finds no test). Documents you may read: the README and `guides/`, `manual/`, `doc/` of the steep gem (`gem contents steep`) and `docs/` of the rbs gem, and the RBS signatures of the core library in the rbs gem's `core/`.
