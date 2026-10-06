# Brief: port the Mini interpreter from Ruby to Sake (AI writability, large-program pilot)

`experiments/2026-10-05-ai-writability/large/mini/` holds an interpreter for the small language Mini:
`SPEC.md`, the Ruby implementation `ruby/` (entry `ruby/main.rb`, reads a Mini program from standard
input), and tests `tests/NNN-*.mini` / `.out` with `run_tests.rb`. Other AI agents will later work on
both versions and be compared, so the two must be **the same program in two languages**.

## Your job

Write `large/mini/sake/`, a Sake port, entry `sake/main.sake`, run as
`/home/ko1/app/sake/bin/sake --strict=2 large/mini/sake/main.sake < prog.mini`.

- **Mirror the structure one to one**: the same files (`lexer.rb` → `lexer.sake`, ...) required the same
  way, the same types with the same fields, the same functions with the same names and parameters,
  in the same order, doing the same steps. A reader should be able to put the two side by side.
  Translate idiom by idiom; do not redesign, simplify, or merge.
- Where Ruby has no direct Sake counterpart, use the nearest Sake form and keep it local: a constant
  becomes a function, a method on a value becomes `Type.op(value)`, a class hierarchy (if any) becomes
  a union or `case/in`. Learn Sake from `/home/ko1/app/sake/docs/tutorial.md`, `docs/spec.md` and
  `docs/builtins.md` only (do not read `lib/`).
- It must pass `bin/sake --strict=2 -c` with no errors, and produce byte-identical output to the Ruby
  version on every test: `ruby large/mini/run_tests.rb sake` must report no mismatches. Do not change
  the Ruby version, the tests, or SPEC.md. If a test is too slow under Sake (over 20 s), report it
  rather than changing it.
- Do not add comments that the Ruby version does not have, except one line where a Sake form needs
  explaining.

## Rules

Work only under `experiments/2026-10-05-ai-writability/large/mini/sake/`. Do not read `lib/`,
`runs/`, `tasks/`, `changes/`, `reading/` or other experiments. No git. Shell commands need
`dangerouslyDisableSandbox: true`. Reply in under 200 words: file list with line counts (next to the
Ruby counts), the test result, the slowest tests and their times, and every place the port could not
mirror the Ruby one to one (one line each).
