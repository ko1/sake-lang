# Brief: a SQL engine in **Haskell (GHC 9.10.3)**, stage 1 of 6

A program that runs SQL scripts (a small subset of SQLite) is being built in stages, each stage adding
to the specification. You do stage 1.

## Material

In `/home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p10-haskell-1/`:
- `SPEC.md`: the specification of stages 1..1. 
- `tests/N/NNN-*.sql` with the expected standard output `.out`: the tests of stages 1..1.
- `run_tests.rb`: `ruby /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p10-haskell-1/run_tests.rb /home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p10-haskell-1/code/Main.hs --stage 1` runs them all
  (8 at a time) and reports each failure; add name substrings (`3/012`, `group`) to run a subset.
  For Haskell it first compiles the program with `ghc -O1 -i<code dir> code/Main.hs` (a program that does not compile does not run), then runs each test with the binary.
- `code/`: empty: the program goes here, entry `Main.hs`.

## Your job

Write the program in `code/`, entry `Main.hs`: it reads a SQL script from standard input and runs it, as SPEC.md says. Organise the program in several files, each a clear part of a database engine, written as
a careful maintainer would want to inherit it: the next stages will be done by others who start from
your code.

Done means every test of stages 1..1 passes. The tests do not cover everything: the program will
also be judged by tests you do not see, so implement what SPEC.md says, not only what the tests show.

## Rules

Work only in `/home/ko1/app/sake/experiments/2026-10-05-ai-writability/runs/p10-haskell-1/code/`. Do not change SPEC.md, the tests or run_tests.rb. Use no database
library and start no other program from the engine; do not look for other SQL implementations or
other runs of this task (do not read anything under `/home/ko1/app/sake/experiments/` outside your directory), and do not search the web. No git. Shell commands need
`dangerouslyDisableSandbox: true`. Do not wait for processes by matching their names (`pgrep -f`
matches your own command); run the tests in the foreground. Reply in under 150 words: the file list
with line counts, the test result, and the hardest part of this stage (one line each).

**Haskell**: the entry is module `Main` in `code/Main.hs`; other modules live under `code/` in files named after them (`Engine/Parser.hs` for `Engine.Parser`). Only the packages that come with GHC are available (base, containers, mtl, text, bytestring, array, ...); no cabal or stack.
