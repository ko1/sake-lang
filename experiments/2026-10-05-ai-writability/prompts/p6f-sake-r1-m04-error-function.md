# Brief: change an interpreter

You maintain an interpreter for the small language Mini, written in **Sake**. Your work directory
(/home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p6f-sake-r1/m04-error-function) holds:

- `code/`: the interpreter (several files; entry `code/main.sake`, which reads a Mini program from
  standard input and runs it);
- `SPEC.md`: the language as the interpreter implements it now;
- `change.md`: a change request; everything it does not mention stays as in `SPEC.md`;
- `tests/`: regression tests (`NNN-*.mini` with the expected output `.out`): behaviour that must not
  change.

Make the change in `code/`. Your code is graded on hidden tests that cover the change and the rest
of the language, by exact output.

**Run code only through the harness**, from `/home/ko1/app/sake/experiments/2026-10-05-ai-writability`:

- `ruby harness/try_mini.rb /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p6f-sake-r1/m04-error-function [NAME_SUBSTRING...]` checks the program with `bin/sake --strict=2 -c` (this can take a minute or more; a program it rejects does not run), then runs the regression tests (all, or
  those whose name contains a substring) and shows the failures. At most 10 such runs.
- `ruby harness/try_mini.rb /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p6f-sake-r1/m04-error-function --run FILE.mini` checks the program with `bin/sake --strict=2 -c` (this can take a minute or more; a program it rejects does not run), then runs one Mini program and shows its
  output. Write your own programs under `/home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p6f-sake-r1/m04-error-function/scratch/`. At most 30 such runs.

Do not run `ruby`, `bin/sake` or the interpreter any other way. Stop when you believe the change is
complete and the regression tests pass, or the runs are used up; `code/` as you leave it is graded.

Do not open anything outside /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p6f-sake-r1/m04-error-function, except the language documents named below. In particular
never look at `experiments/2026-10-05-ai-writability/large/`, `runs/` of others, `lib/`, or other
experiments. Do not search the web. Do not wait for processes by matching their names (`pgrep -f`
matches your own command); just run the harness in the foreground. Shell commands need
`dangerouslyDisableSandbox: true`. Reply in
under 150 words: what you changed (files, one line each), whether you think it is complete, and the
hardest part.

**Sake** (in `/home/ko1/app/sake`): Ruby syntax where every operation is written with its type (`String.upcase(s)`, not `s.upcase`). Learn it from `docs/tutorial.md` (start here), `docs/spec.md` and `docs/builtins.md`; these are the only documents you may read.
