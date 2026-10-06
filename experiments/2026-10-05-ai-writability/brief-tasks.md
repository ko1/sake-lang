# Brief: write programming tasks with hidden tests (AI writability pilot)

You write tasks that other AI agents will later solve, in Sake and in Ruby. Your tasks are the
held-out set: do not copy tasks from well-known benchmarks or from this repository's corpora.

## A task

`experiments/2026-10-05-ai-writability/tasks/<id>/` (id: `b<NN>-<slug>`, numbers given below):

- `spec.md`: a precise, language-neutral statement, as a programming contest or a work ticket would
  give it: what the program reads from standard input (format, limits), what it prints (exact format,
  including spacing, ordering, number formatting, and what to print for invalid or edge input), and 2
  worked examples. No hints about implementation or about any language. 150-500 words.
- `public/01.in` `public/01.out`, `public/02.in` `02.out`: the spec's two examples, byte-identical.
- `hidden/01.in` ... `hidden/12.in` (and `.out`), at least 12: ordinary cases, edge cases (empty input,
  one item, ties, maximum sizes within the stated limits, invalid lines the spec says how to handle),
  and cases that catch typical mistakes (off-by-one, sorting stability, rounding, nil/missing keys).
  Generate them with a script if useful, outputs from your Ruby reference; keep inputs small enough that
  the Sake reference runs each case in under 3 seconds.
- `ref.rb`: an idiomatic Ruby reference solution (Ruby 4.0, standard library allowed).
- `ref.sake`: the same program in Sake. Learn Sake from /home/ko1/app/sake/docs/tutorial.md, docs/spec.md
  and docs/builtins.md (do not read lib/, DESIGN.md, or other experiments). It must pass
  `bin/sake --strict=2` (run from /home/ko1/app/sake).
- Validate: `ruby experiments/2026-10-05-ai-writability/harness/validate.rb experiments/2026-10-05-ai-writability/tasks/<id>`
  must print `"sake_ref_ok":true` and `"rb_ref_ok":true`, and kill at least one mutant per reference
  (if none is killed, your hidden tests are too weak: add cases).

## The set

Programs of 40-150 lines of Ruby, each needing several of: a small class or record type with state,
Hash grouping/counting, sorting with tie-breaks, parsing lines with validation and error messages,
values that may be missing (nil), Integer/Float formatting, a small state machine or simulation,
recursion or a tree, string formatting of tables. Realistic, each a different domain (log analysis,
inventory, scheduling, a tiny interpreter, bank ledger, grade report, text layout, graph route,
config parser, game scoring, ...). Medium difficulty: a competent programmer needs 15-40 minutes.

## Rules

Work only in your task directories. No git. Shell commands need `dangerouslyDisableSandbox: true`.
Do not write any solution other than ref.rb and ref.sake, and do not leave notes on how to solve.
Reply in under 150 words: ids, one line each, the validate results (mutants killed / tried), and any
Sake friction you hit writing ref.sake (one line each).
