# Brief: change a SQL engine written in **Scheme (Chez Scheme 10, R6RS)**

`/home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p11-h-scheme-2-c3/code/` holds a SQL engine (a small subset of SQLite), entry `main.ss`. Other agents wrote it
from a specification in six stages; it passes every test of those stages. You are its maintainer now,
and a change has been requested.

## Material

In `/home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p11-h-scheme-2-c3/`:
- `SPEC.md`: the specification the engine implements (stages 1-6).
- `CHANGE.md`: the change request. It states the change's rules; finding every place in the engine where they apply is part of the job.
- `code/`: the engine.
- The check: `ruby /home/ko1/app/sake/experiments/2026-10-05-ai-writability/harness/check_sql.rb /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p11-h-scheme-2-c3` reads every form of every `.ss` and `.sls` file (a syntax check: it finds unbalanced parentheses and the like, and runs nothing). You may use it at most 10 times.

## Your job

Make the change described in CHANGE.md, everywhere it applies, keeping everything else working as
SPEC.md says. Write it as a careful maintainer would; others will continue from your code.

In this task you cannot run anything: there are no tests, and running the engine or any part of it (or loading its code into an interpreter or a REPL) is not allowed. Your only tool besides reading and editing files is the check above, at most 10 times. A program that fails the check cannot run, so it fails every test. Done means you are confident the change is complete and correct; the program will be judged by tests you do not see, on every place the change reaches and on stages 1-6.

## Rules

Work only in `/home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p11-h-scheme-2-c3/code/`. Do not change SPEC.md, CHANGE.md or anything outside `code/`. Use no
database library and start no other program from the engine; do not look for other SQL
implementations or other copies of this engine (do not read anything under
`/home/ko1/app/sake/experiments/` outside your directory), and do not search the web. No git. Shell
commands need `dangerouslyDisableSandbox: true`. Do not wait for processes by matching their names
(`pgrep -f` matches your own command); run commands in the foreground. Reply in under 150 words: the
files you changed (lines added and removed), the last check's result, and the hardest part (one line each).

**Scheme**: Chez Scheme 10; Chez's own libraries (`(chezscheme)`) are allowed.
