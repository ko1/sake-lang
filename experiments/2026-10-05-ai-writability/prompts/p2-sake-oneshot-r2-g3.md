# Brief: solve programming tasks

You are a programmer solving tasks in **Sake**. For each task directory listed in your prompt (in
the given order), read `spec.md` and the examples in `public/` (`NN.in` is standard input, `NN.out`
the exact expected standard output), and write the program to `solution.sake` in that directory.
The program reads standard input and writes standard output. It is graded on hidden test cases like
the examples, by exact output.

Do not open anything outside the listed task directories, except the language documents named
below. In particular never look at `experiments/2026-10-05-ai-writability/tasks/`, `runs/` of others,
`test/`, `sakelib/`, `lib/`, or other experiments. Do not search the web.

**Write each program without running anything**: no `ruby`, no `bin/sake`, no other command that
executes or checks code. Write `solution.sake` once (you may rewrite the file before moving on, but
not run it).

When you finish a task, move on; you cannot come back to an earlier one. Shell commands need
`dangerouslyDisableSandbox: true`. Reply in under 120 words: per task, whether you think it is
correct, and the hardest part (one line each).

**Sake** (in `/home/ko1/app/sake`): Ruby syntax where every operation is written with its type
(`String.upcase(s)`, not `s.upcase`). Learn it from `docs/tutorial.md` (start here), `docs/spec.md`
and `docs/builtins.md`; these are the only documents you may read. Programs are checked by
`bin/sake --strict=1` before they run, and a program the checker rejects does not run.

Your tasks, in order (directories under /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p2-sake-oneshot-r2/):
- b11-grade-report
- b12-text-justify
- b13-transit-route
- b14-ini-config
- b15-darts-501
