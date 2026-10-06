# Brief: write change requests for existing programs (AI modifiability, P4)

Other AI agents will later be given an existing working program (in Sake or in Ruby) and a change
request, and must modify the program. You write the change requests and their tests. You are not a
solver; do not leave notes on how to make the change.

## Material

Each base task `experiments/2026-10-05-ai-writability/tasks/bNN-<slug>/` has `spec.md`, `public/`,
`hidden/`, and two reference programs `ref.rb` and `ref.sake` (the same program in Ruby and in Sake).
The solvers will get `spec.md`, your change, and one of the two references as their starting point.

## A change task

`experiments/2026-10-05-ai-writability/changes/cNN-<slug>/` (cNN = the base task's number, e.g. c04 for b04):

- `base.txt`: the base task's directory name (one line, e.g. `b04-stack-lang`).
- `change.md`: a change request as a work ticket would give it, 80-300 words, language-neutral: what is
  different from `spec.md` from now on (input format, rules, output format), stated precisely enough to
  decide every output, and 1-2 worked examples of the new behaviour. Everything not mentioned stays as
  in `spec.md`. No hints about implementation, about where in a program to change things, or about any
  language.
- `public/01.in` `01.out`, `public/02.in` `02.out`: the change's examples, byte-identical to change.md.
- `hidden/01.in` ... at least 12 cases (`.in` and `.out`) under the changed spec: at least 6 that
  exercise the change (including its edge cases), and at least 4 that do not involve the change and
  check that old behaviour is kept (reuse base hidden inputs where their output is unchanged).
- `ref.rb` and `ref.sake`: the base references modified to implement the change. Start from the base
  `ref.rb` / `ref.sake` and change only what the change needs, in the style of the existing code (this is
  what a careful maintainer would produce). `ref.sake` must pass `bin/sake --strict=2`.

## What kind of change

The point is to see whether a language helps a maintainer find every place a change must reach. So
each change must alter the type or shape of data that flows through several parts of the program,
for example:

- a quantity that was a whole number may now have a fractional part (e.g. cents, halves);
- a value that was always present may now be missing, and the output must say so;
- an identifier changes kind (a number becomes a code with letters, or the reverse);
- a single value becomes a list of values (an item gets several tags, a booking several rooms);
- a record gets a new attribute that affects validation, ordering and output.

The base reference must need edits in at least 3 separate places (functions or blocks) to implement
the change, and the base references must fail at least 2 of your hidden cases (otherwise the change
does not matter). Keep it medium-sized: a competent maintainer needs 10-25 minutes. Choose a different
kind of change across your tasks; do not make every change a fractional number.

## Validate

From `/home/ko1/app/sake`:
`ruby experiments/2026-10-05-ai-writability/harness/validate_change.rb experiments/2026-10-05-ai-writability/changes/cNN-<slug>`
It must print `"ok":true`: both new references pass every public and hidden case (Sake at
`--strict=2`), both base references fail at least 2 hidden cases, at least 4 hidden cases are passed by
the base references (kept behaviour), and mutants of the new references are killed. It also prints the
size of each reference's diff from its base (`diff_rb`, `diff_sake`: changed lines).

## Rules

Work only in your change directories (read the base tasks, `docs/tutorial.md`, `docs/spec.md`,
`docs/builtins.md`; do not read `lib/`, `DESIGN.md`, `runs/`, or other experiments). No git. Shell
commands need `dangerouslyDisableSandbox: true`. Reply in under 150 words: ids, one line each with the
kind of change, the validate result (diff sizes, mutants killed / tried), and any Sake friction you hit.
