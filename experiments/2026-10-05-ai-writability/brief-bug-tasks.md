# Brief: plant one bug in a pair of programs (AI readability, P5)

Other AI agents will later get a buggy program (in Sake or in Ruby), its spec, and one failing input,
and must find and fix the bug **without running anything**. You plant the bugs. You are not a solver;
do not leave notes or comments that point at the bug.

## Material

Each base task `experiments/2026-10-05-ai-writability/tasks/bNN-<slug>/` has `spec.md`, `public/`,
`hidden/`, and `ref.rb` / `ref.sake` (the same program in Ruby and in Sake).

## A bug task

`experiments/2026-10-05-ai-writability/reading/fNN-<slug>/` (fNN = the base task's number):

- `base.txt`: the base task's directory name (one line).
- `bug.rb`: `ref.rb` with exactly **one line** changed.
- `bug.sake`: `ref.sake` with exactly one line changed, at the corresponding place, so that it behaves
  exactly like `bug.rb` on every test input (same output, same exit status).

The bug must be a plausible mistake a programmer could make, not a planted oddity: an off-by-one
boundary, a wrong comparison, the wrong variable or field, an inverted or missing condition, the wrong
rounding, the wrong key or index, checks in the wrong order (only if one line can do it). Do not touch
comments or names, and do not make the changed line look different in style from its neighbours.

Requirements (checked by the validator):

- each bug makes at least 1 and at most half of the hidden cases fail (not a bug that breaks everything);
- on the failing cases the program still exits normally (wrong output, not a crash or exception);
- `bug.sake` passes `bin/sake --strict=2 -c` (a bug the checker reports is not a reading task);
- `bug.rb` and `bug.sake` give identical output and exit status on every public and hidden input.

Vary the kind of bug across your tasks, and place them in the program's logic, not in its parsing
of a single field (avoid bugs that one glance at the failing input reveals).

## Validate

From `/home/ko1/app/sake`:
`ruby experiments/2026-10-05-ai-writability/harness/validate_bug.rb experiments/2026-10-05-ai-writability/reading/fNN-<slug>`
It must print `"ok":true`.

## Rules

Work only in your bug directories (read the base tasks and `docs/tutorial.md`, `docs/spec.md`,
`docs/builtins.md`; do not read `lib/`, `DESIGN.md`, `runs/`, `changes/`, or other experiments). No git.
Shell commands need `dangerouslyDisableSandbox: true`. Reply in under 150 words: ids, one line each
with the kind of bug and the number of failing hidden cases.
