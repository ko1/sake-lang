# Brief: solve programming tasks

You are a programmer solving tasks in **Sake**. For each task directory listed in your prompt (in
the given order), read `spec.md` and the examples in `public/` (`NN.in` is standard input, `NN.out`
the exact expected standard output), and write the program to `solution.sake` in that directory.
The program reads standard input and writes standard output. It is graded on hidden test cases like
the examples, by exact output.

Do not open anything outside the listed task directories, except the language documents named
below. In particular never look at `experiments/2026-10-05-ai-writability/tasks/`, `runs/` of others,
`test/`, `sakelib/`, `lib/`, or other experiments. Do not search the web.

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

Your tasks, in order (directories under /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p9h-sake-agentic-verify-r1/):
- b06-library-loans
- b07-vending-machine
- b08-timesheet-pay
- b09-bill-of-materials
- b10-recipe-scale

**Before you write each solution, look up every operation you plan to use** in `docs/builtins.md`:
the type it belongs to (`String.split`, not `Array.split`) and its arguments. Do not write an operation
you have not found there; if what you want is not listed, build it from operations that are.
