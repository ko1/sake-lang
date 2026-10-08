# Brief: change a SQL engine written in **Sake**

`/home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p11f-t-sake-1-c2/code/` holds a SQL engine (a small subset of SQLite), entry `main.sake`. Other agents wrote it
from a specification in six stages; it passes every test of those stages. You are its maintainer now,
and a change has been requested.

## Material

In `/home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p11f-t-sake-1-c2/`:
- `SPEC.md`: the specification the engine implements (stages 1-6).
- `CHANGE.md`: the change request. It ends with a list of where the change applies.
- `code/`: the engine.
- `tests/N/NNN-*.sql` with the expected standard output `.out`: the tests of stages 1-6 (`tests/1` ... `tests/6`)
  and the change's tests (`tests/7`).
- `run_tests.rb`: `ruby /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p11f-t-sake-1-c2/run_tests.rb /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p11f-t-sake-1-c2/code/main.sake` runs them all (8 at a time) and reports each failure; add name
  substrings (`7/`, `3/012`) to run a subset, or `--check-only` to run only the language's check. For Sake it first checks the program with `/home/ko1/app/sake/bin/sake --strict=2 -c` (a program it rejects does not run), then runs each test at `--strict=0`.

## Your job

Make the change described in CHANGE.md, everywhere it applies, keeping everything else working as
SPEC.md says. Write it as a careful maintainer would; others will continue from your code.

Done means every test passes (`tests/1` ... `tests/7`). The change's tests do not cover every place where it applies: the program will be judged by tests you do not see, on every place CHANGE.md lists and on stages 1-6, so make the change wherever CHANGE.md says it applies, not only where the tests show.

## Rules

Work only in `/home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p11f-t-sake-1-c2/code/`. Do not change SPEC.md, CHANGE.md or anything outside `code/`. Use no
database library and start no other program from the engine; do not look for other SQL
implementations or other copies of this engine (do not read anything under
`/home/ko1/app/sake/experiments/` outside your directory), and do not search the web. No git. Shell
commands need `dangerouslyDisableSandbox: true`. Do not wait for processes by matching their names
(`pgrep -f` matches your own command); run commands in the foreground. Reply in under 150 words: the
files you changed (lines added and removed), the test result, and the hardest part (one line each).

**Sake** (in `/home/ko1/app/sake`): Ruby syntax where every operation is written with its type (`String.upcase(s)`, not `s.upcase`). Learn it from `docs/tutorial.md` (start here), `docs/spec.md` and `docs/builtins.md`; these are the only documents you may read.
