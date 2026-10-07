# Brief: change an interpreter without running it

You maintain an interpreter for the small language Mini, written in **Ruby (4.0; the standard library is allowed)**. Your work directory
(/home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p8-ruby-r1/m08-repr-style) holds:

- `code/`: the interpreter (several files; entry `code/main.rb`, which reads a Mini program from
  standard input and runs it);
- `SPEC.md`: the language as the interpreter implements it now;
- `change.md`: a change request; everything it does not mention stays as in `SPEC.md`.

Make the change in `code/`. Your code is graded on hidden tests that cover the change and the rest
of the language, by exact output.

**You cannot run the interpreter or any Mini program.** The only thing you may run is the checker,
from `/home/ko1/app/sake/experiments/2026-10-05-ai-writability`:
`ruby harness/check_mini.rb /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p8-ruby-r1/m08-repr-style`, which checks the syntax of every file with `ruby -wc` and shows its errors and warnings. At most 10 checks. Do not run `ruby`,
`bin/sake` or anything else that executes code. Stop when you believe the change is complete, or the
checks are used up; `code/` as you leave it is graded.

Do not open anything outside /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p8-ruby-r1/m08-repr-style, except the language documents named below. In particular
never look at `experiments/2026-10-05-ai-writability/large/`, `runs/` of others, `lib/`, or other
experiments. Do not search the web. Do not wait for processes by matching their names (`pgrep -f`
matches your own command); just run the checker in the foreground. Shell commands need
`dangerouslyDisableSandbox: true`. Reply in under 150 words: what you changed (files, one line each),
whether you think it is complete, and the hardest part.

