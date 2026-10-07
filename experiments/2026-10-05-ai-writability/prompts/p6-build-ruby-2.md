# Brief: implement an interpreter for a small language

You are a programmer writing, in **Ruby (4.0; the standard library is allowed)**, an interpreter for the small language Mini.

## Material

`/home/ko1/app/sake/experiments/2026-10-05-ai-writability/large/mini/`: `SPEC.md` (the language:
values, statements, operators, built-ins, the static pass, exact error output), `tests/NNN-*.mini`
with the expected standard output `.out` (298 tests), and `run_tests.rb`.

**Do not open `large/mini/ruby/`, `large/mini/sake/`, `large/mini/sake-scratch/`, or any other
directory under `large/mini/build/` than your own** (other implementations), and do not look for other
Mini implementations anywhere. Work from SPEC.md and the tests. Do not search the web.

## Your job

Write the interpreter in `large/mini/build/ruby-2/`, entry `main.rb`. It reads a Mini program
from standard input and runs it. Organise it in several files (about 10-15), each a clear part of an
interpreter, written as a careful maintainer would want to inherit it.

Done means every test passes: from `/home/ko1/app/sake/experiments/2026-10-05-ai-writability`, run
`ruby large/mini/run_tests.rb large/mini/build/ruby-2/main.rb` (optionally with name substrings to
run a subset) until it reports no failures. You may run `ruby` directly as well. Do not change SPEC.md, the tests, or
run_tests.rb.

## Rules

Work only under `large/mini/build/ruby-2/`. Do not read `lib/`, `sakelib/`, `test/`, `runs/`,
`tasks/`, `changes/`, `reading/` or other experiments. No git. Shell commands need
`dangerouslyDisableSandbox: true`. Reply in under 150 words: the file list with line counts, the test
result, and the hardest part (one line each).
