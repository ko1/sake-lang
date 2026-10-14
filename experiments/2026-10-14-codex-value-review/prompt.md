# Review request: does Sake have value?

You are asked for an independent, critical assessment of the programming language in this repository,
Sake (https://github.com/ko1/sake-lang). Not a bug hunt: the question is **whether this language has
value, for whom, and what would have to be true for it to matter.** The author (a Ruby core committer)
wants an honest answer, including "no", with reasons. Do not flatter; do not hedge everything.

## The language in one paragraph

Ruby's syntax, but the type is written on every operation (`String.upcase(s)`, never `s.upcase`), and
never on a variable, parameter or field. Whole-program type inference, strictness levels 0-4, an
interpreter in Ruby, native compilation through Rust and C for a subset. It was built (mostly by AI,
directed by the author) in about two weeks, as an experiment in "types on operations instead of
variables", motivated by making a language easy for AI to write.

## Materials (read these; judge them, do not just repeat them)

- README.md (overview, the evaluation's summary in "Status"), docs/spec.md (the language), docs/cheatsheet.md
- DESIGN.md (every decision and its reason, in Japanese), docs/comparison.md (against Elm, Crystal, Rust,
  Elixir, TypeScript, Clojure and the literature, in Japanese)
- experiments/2026-10-05-ai-writability/README.md: the evaluation (Sonnet/Haiku writing Sake vs Ruby,
  a 4,000-line SQL engine in Ruby, Java, Haskell, Scheme, Ruby+Steep and Sake). Its conclusion (2026-10-08)
  was that the hypothesis could not be separated from unfamiliarity. Check whether that conclusion and
  its numbers are sound, and what else the data does or does not show.
- other experiments/*/README.md (inference over 500 programs, TypeProf comparison, Rust backend, web
  frameworks ported: 2026-10-12-web), examples/ (59 programs), sakelib/ (ports of ~90 Ruby libraries,
  each tested against the real library: test/sakelib/*.rb vs *.sake)
- You may run things: `bin/sake FILE.sake`, `bin/sake --strict=2 FILE.sake`, `bin/sabic`, Ruby 4.0 is
  installed. Put any files you write under ./tmp-review/ only; modify nothing else.

## Questions to answer

1. **The core idea.** Is "write the type on the operation, never on the variable" a genuinely new or
   useful point in the design space? What does it buy that existing approaches (Ruby + RBS/Steep/Sorbet,
   TypeProf, Crystal, Go, OCaml/F# with inference, Elixir's set-theoretic types, Python + mypy) do not,
   and what does it cost? Be concrete: show code where it helps and where it hurts.
2. **For whom.** Evaluate each candidate audience separately: AI code generation, AI-written code
   reviewed by humans ("one line tells you which function runs"), human programmers writing by hand,
   native-code performance for Ruby-like programs, teaching/research. Where is the value real, where
   is it imagined, where is it negative?
3. **The evidence.** Is the evaluation's design able to answer its question? What would a convincing
   experiment look like (cost, participants, metrics)? Is there evidence in the repository the author
   has under-weighted, for or against?
4. **What is incidental vs essential.** Which parts of the value come from the core idea, and which
   from things any language could have (whole-program inference, good error hints, strictness levels,
   Ruby compatibility of names)? Could the valuable part be delivered without a new language (a Ruby
   linter, an RBS mode, a TypeProf feature, a style)? If so, which and how.
5. **Costs and risks.** Verbosity, the restrictions it forces (no first-class blocks, no inheritance,
   no value constants, no method calls on values), ecosystem, the "unfamiliar language" tax measured
   at 1.1-2.4x tokens. Are these intrinsic or fixable?
6. **Verdict and recommendation.** In a few sentences: does Sake have value, and what should the author
   do next (stop, narrow it to X, publish it as a research result about Y, turn part of it into a Ruby
   tool Z, run experiment W)? Rank the options.

## Output

Write in **Japanese** (the author's language), plain Markdown, about 2,000-4,000 characters per
question, with code examples where they make a point. Separate what you verified (ran, read) from what
you judge. Cite files and line numbers. End with a short list of the strongest arguments for and
against.
