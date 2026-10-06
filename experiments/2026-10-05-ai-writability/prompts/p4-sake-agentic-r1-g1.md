# Brief: change existing programs

You maintain programs written in **Sake**. Each task directory listed in your prompt (take them in
the given order) holds:

- `solution.sake`: a working program that implements `spec.md`;
- `spec.md`: what the program does now;
- `change.md`: a change request; everything it does not mention stays as in `spec.md`;
- `public/`: examples of the changed behaviour (`NN.in` is standard input, `NN.out` the exact expected
  standard output).

Modify `solution.sake` in place so that it implements `spec.md` with `change.md` applied. It is graded on
hidden test cases, by exact output; they cover both the changed behaviour and the behaviour that should
stay the same.

Do not open anything outside the listed task directories, except the language documents named
below. In particular never look at `experiments/2026-10-05-ai-writability/tasks/`, `changes/`, `runs/`
of others, `test/`, `sakelib/`, `lib/`, or other experiments. Do not search the web.

**You may run your program only through the harness**, from `/home/ko1/app/sake`:
`ruby experiments/2026-10-05-ai-writability/harness/try.rb <task dir>/solution.sake`. It checks the
program, runs it on the public examples and shows the differences. You have at most 8 runs per task;
do not run the program, `ruby`, or `bin/sake` any other way. Stop when the examples pass or the runs
are used up; the last `solution.sake` is graded.

When you finish a task, move on; you cannot come back to an earlier one. Shell commands need
`dangerouslyDisableSandbox: true`. Reply in under 120 words: per task, whether you think it is
correct, and the hardest part (one line each).

**Sake** (in `/home/ko1/app/sake`): Ruby syntax where every operation is written with its type
(`String.upcase(s)`, not `s.upcase`). Learn it from `docs/tutorial.md` (start here), `docs/spec.md`
and `docs/builtins.md`; these are the only documents you may read. Programs are checked by
`bin/sake --strict=1` before they run, and a program the checker rejects does not run.

Your tasks, in order (directories under /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p4-sake-agentic-r1/):
- c01-unknown-duration
- c02-fractional-qty
- c03-multi-room
- c04-fractions
- c05-savings-kind
