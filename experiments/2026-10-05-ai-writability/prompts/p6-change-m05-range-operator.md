# Brief: write one change request for the Mini interpreter, with reference changes (P6)

`large/mini/` holds the language Mini (`SPEC.md`, 298 tests in `tests/`, `run_tests.rb`) and three
implementations of it: `ruby/` (Ruby), `sake/` (a one-to-one Sake port of the Ruby) and `sake-scratch/`
(Sake written independently). Other AI agents will later be given one of these codebases, `SPEC.md`
and your change request, and must change the code. You write the change request, its tests, and a
reference change in each of the three codebases. You are not a solver: do not leave notes about how
to make the change.

## Your change

Add range operators: a..b (inclusive) and a..<b (exclusive) produce an array of the integers from a to b. Decide their precedence (between comparison and addition), what happens when b < a, the errors for non-integer operands, and a size limit with its error.

Decide every detail the description leaves open, and write all of it down in `change.md`.

## What to write, in `large/mini/changes/m05-range-operator/`

- `change.md`: the change as a work ticket would state it, 150-500 words: what is different from
  `SPEC.md` from now on, precisely enough to decide every output (exact error messages and
  positions, formatting, edge cases), with 2-4 short examples (program and output). Everything it
  does not mention stays as in `SPEC.md`. No hints about implementation or about any of the codebases.
- `tests/`: the **complete** test suite under the changed language: start from a copy of every
  `large/mini/tests/*.mini` and `.out`; update the `.out` (and, if the change makes a test invalid,
  the `.mini`) of the tests the change affects; add at least 12 new tests `9NN-<topic>.mini` that
  exercise the change and its edge cases. Expected outputs come from your Ruby reference and must be
  checked by you against `change.md`.
- `ref/ruby/`, `ref/sake/`, `ref/sake-scratch/`: a copy of each codebase with the change made, as a
  careful maintainer of *that* codebase would make it: in its style, touching what the change needs
  and nothing else (no refactoring, no renaming, no reformatting). The Sake references must pass
  `/home/ko1/app/sake/bin/sake --strict=2 -c`. Learn Sake from `/home/ko1/app/sake/docs/` if needed.

## Validate

From `/home/ko1/app/sake/experiments/2026-10-05-ai-writability`:
`ruby harness/validate_mini_change.rb large/mini/changes/m05-range-operator` (slow: about 10-20 minutes; run it
in the background). It must print `"ok":true`: each reference passes every test in your suite, each
original codebase fails at least 2 of them, and at least 100 tests pass with all three originals. It
also lists the functions each reference touched. To iterate faster, use
`MINI_TESTS=large/mini/changes/m05-range-operator/tests ruby large/mini/run_tests.rb large/mini/changes/m05-range-operator/ref/ruby/main.rb`
(and `.../ref/sake/main.sake`, `.../ref/sake-scratch/main.sake`).

## Rules

Do not modify anything outside `large/mini/changes/m05-range-operator/` (the originals, `SPEC.md`, the tests and
the runner are shared). Do not read `large/mini/build/`, `lib/`, `runs/` or other experiments. No git.
Shell commands need `dangerouslyDisableSandbox: true`. Reply in under 150 words: the number of new
and updated tests, the validator's diff size and number of touched functions per codebase, and
anything in a codebase that made the change harder (one line each).
