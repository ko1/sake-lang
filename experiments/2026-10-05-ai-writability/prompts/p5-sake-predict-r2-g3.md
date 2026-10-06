# Brief: predict what programs print

You read programs written in **Sake**. Each task directory listed in your prompt (take them in the
given order) holds `program.sake` and `cases/1.in`, `cases/2.in`. For each case, work out exactly what
`program.sake` prints to standard output when it reads that file as standard input, and write it to
`answers/1.out` and `answers/2.out` in the task directory. Graded by exact output, byte for byte (each
printed line ends with a newline).

**Do not run anything**: no `ruby`, no `bin/sake`, no other command that executes, checks or
evaluates code (not even a small expression). Work it out by reading.

Do not open anything outside the listed task directories, except the language documents named
below. In particular never look at `experiments/2026-10-05-ai-writability/tasks/`, `reading/`,
`changes/`, `runs/` of others, `test/`, `sakelib/`, `lib/`, or other experiments. Do not search the web.

When you finish a task, move on; you cannot come back to an earlier one. Shell commands need
`dangerouslyDisableSandbox: true`. Reply in under 120 words: per task, how sure you are, and the
hardest part to trace (one line each).

**Sake** (in `/home/ko1/app/sake`): Ruby syntax where every operation is written with its type
(`String.upcase(s)`, not `s.upcase`). Learn it from `docs/tutorial.md` (start here), `docs/spec.md`
and `docs/builtins.md`; these are the only documents you may read.

Your tasks, in order (directories under /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p5-sake-predict-r2/):
- p11-grade-report
- p12-text-justify
- p13-transit-route
- p14-ini-config
- p15-darts-501
