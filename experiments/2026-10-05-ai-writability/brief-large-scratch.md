# Brief: write an interpreter for a small language, in Sake (AI writability, large-program pilot)

Other AI agents will later be asked to change, extend, debug and answer questions about this program.
You write it from the language specification, in Sake, the way a careful Sake programmer would
structure it. You are not a solver: do not leave notes about future tasks.

## Material

`experiments/2026-10-05-ai-writability/large/mini/`: `SPEC.md` (the language Mini: values,
statements, operators, built-ins, the static pass, exact error output) and `tests/NNN-*.mini` with
the expected standard output `.out` (298 tests), and `run_tests.rb`.

**Do not open `large/mini/ruby/` or `large/mini/sake/`** (other implementations), and do not look for
other Mini implementations anywhere. Work from SPEC.md and the tests.

## Your job

Write `large/mini/sake-scratch/`, entry `main.sake`, run as
`/home/ko1/app/sake/bin/sake --strict=2 large/mini/sake-scratch/main.sake < prog.mini`: it reads a
Mini program from standard input and runs it.

- Several files joined with `require` (about 10-15), each a clear part of an interpreter (tokens,
  lexer, syntax tree, parser, static pass, values, environments, evaluator, built-ins, errors,
  formatting, ...). Write it as a careful maintainer would want to inherit it, and as Sake is meant to
  be written: design the data with Sake's types (Struct types, Tuples, Records, unions, `case/in`)
  where they fit. Learn Sake from `/home/ko1/app/sake/docs/tutorial.md`, `docs/spec.md` and
  `docs/builtins.md` only (do not read `lib/`, `sakelib/`, `test/`).
- It must pass `bin/sake --strict=2 -c` with no errors, and every test:
  `ruby large/mini/run_tests.rb sake-scratch` must report no failures. If a test is too slow under
  Sake (over 20 s), report it. Do not change SPEC.md, the tests, or run_tests.rb.
- `--tokens`/`--ast` debug flags are not required.

## Rules

Work only under `experiments/2026-10-05-ai-writability/large/mini/sake-scratch/`. Do not read
`lib/`, `runs/`, `tasks/`, `changes/`, `reading/` or other experiments. No git. Shell commands need
`dangerouslyDisableSandbox: true`. Reply in under 200 words: the file list with line counts, the test
result, the slowest tests and their times, and where Sake made the design easier or harder (one line
each).
