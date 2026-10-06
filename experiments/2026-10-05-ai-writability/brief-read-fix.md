# Brief: find and fix a bug by reading

You maintain programs written in **LANG**. Each task directory listed in your prompt (take them in
the given order) holds:

- `solution.EXT`: a program meant to implement `spec.md`; it has one bug;
- `spec.md`: what the program should do;
- `example/input.txt`: an input on which it goes wrong, with `example/expected.txt` (the correct
  standard output) and `example/actual.txt` (what the program prints now).

Fix the bug by editing `solution.EXT` in place, changing only what the fix needs. It is graded on hidden
test cases by exact output.

**Do not run anything**: no `ruby`, no `bin/sake`, no other command that executes, checks or
evaluates code. Find the bug by reading.

Do not open anything outside the listed task directories, except the language documents named
below. In particular never look at `experiments/2026-10-05-ai-writability/tasks/`, `reading/`,
`changes/`, `runs/` of others, `test/`, `sakelib/`, `lib/`, or other experiments. Do not search the web.

When you finish a task, move on; you cannot come back to an earlier one. Shell commands need
`dangerouslyDisableSandbox: true`. Reply in under 120 words: per task, the bug you found and how sure
you are (one line each).
