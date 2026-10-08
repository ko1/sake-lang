# Brief: change a SQL engine written in **LANG**

`WORK_DIR/code/` holds a SQL engine (a small subset of SQLite), entry `ENTRY`. Other agents wrote it
from a specification in six stages; it passes every test of those stages. You are its maintainer now,
and a change has been requested.

## Material

In `WORK_DIR/`:
- `SPEC.md`: the specification the engine implements (stages 1-6).
- `CHANGE.md`: the change request. CHANGE_NOTE
- `code/`: the engine.
MODE_MATERIAL

## Your job

Make the change described in CHANGE.md, everywhere it applies, keeping everything else working as
SPEC.md says. Write it as a careful maintainer would; others will continue from your code.

MODE_DONE

## Rules

Work only in `WORK_DIR/code/`. Do not change SPEC.md, CHANGE.md or anything outside `code/`. Use no
database library and start no other program from the engine; do not look for other SQL
implementations or other copies of this engine (do not read anything under
`/home/ko1/app/sake/experiments/` outside your directory), and do not search the web. No git. Shell
commands need `dangerouslyDisableSandbox: true`. Do not wait for processes by matching their names
(`pgrep -f` matches your own command); run commands in the foreground. Reply in under 150 words: the
files you changed (lines added and removed), MODE_REPLY, and the hardest part (one line each).

LANG_NOTE
