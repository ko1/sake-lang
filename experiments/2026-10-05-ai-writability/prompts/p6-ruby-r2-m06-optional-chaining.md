# Brief: change an interpreter

You maintain an interpreter for the small language Mini, written in **Ruby (4.0; the standard library is allowed)**. Your work directory
(/home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p6-ruby-r2/m06-optional-chaining) holds:

- `code/`: the interpreter (several files; entry `code/main.rb`, which reads a Mini program from
  standard input and runs it);
- `SPEC.md`: the language as the interpreter implements it now;
- `change.md`: a change request; everything it does not mention stays as in `SPEC.md`;
- `tests/`: regression tests (`NNN-*.mini` with the expected output `.out`): behaviour that must not
  change.

Make the change in `code/`. Your code is graded on hidden tests that cover the change and the rest
of the language, by exact output.

**Run code only through the harness**, from `/home/ko1/app/sake/experiments/2026-10-05-ai-writability`:

- `ruby harness/try_mini.rb /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p6-ruby-r2/m06-optional-chaining [NAME_SUBSTRING...]` runs the regression tests (all, or
  those whose name contains a substring) and shows the failures. At most 10 such runs.
- `ruby harness/try_mini.rb /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p6-ruby-r2/m06-optional-chaining --run FILE.mini` runs one Mini program and shows its
  output. Write your own programs under `/home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p6-ruby-r2/m06-optional-chaining/scratch/`. At most 30 such runs.

Do not run `ruby`, `bin/sake` or the interpreter any other way. Stop when you believe the change is
complete and the regression tests pass, or the runs are used up; `code/` as you leave it is graded.

Do not open anything outside /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p6-ruby-r2/m06-optional-chaining, except the language documents named below. In particular
never look at `experiments/2026-10-05-ai-writability/large/`, `runs/` of others, `lib/`, or other
experiments. Do not search the web. Shell commands need `dangerouslyDisableSandbox: true`. Reply in
under 150 words: what you changed (files, one line each), whether you think it is complete, and the
hardest part.

