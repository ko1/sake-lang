# Brief: change existing programs

You maintain programs written in **LANG**. Each task directory listed in your prompt (take them in
the given order) holds:

- `solution.EXT`: a working program that implements `spec.md`;
- `spec.md`: what the program does now;
- `change.md`: a change request; everything it does not mention stays as in `spec.md`;
- `public/`: examples of the changed behaviour (`NN.in` is standard input, `NN.out` the exact expected
  standard output).

Modify `solution.EXT` in place so that it implements `spec.md` with `change.md` applied. It is graded on
hidden test cases, by exact output; they cover both the changed behaviour and the behaviour that should
stay the same.

Do not open anything outside the listed task directories, except the language documents named
below. In particular never look at `experiments/2026-10-05-ai-writability/tasks/`, `changes/`, `runs/`
of others, `test/`, `sakelib/`, `lib/`, or other experiments. Do not search the web.

MODE_TEXT

When you finish a task, move on; you cannot come back to an earlier one. Shell commands need
`dangerouslyDisableSandbox: true`. Reply in under 120 words: per task, whether you think it is
correct, and the hardest part (one line each).
