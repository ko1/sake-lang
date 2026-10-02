# Brief for the revision round (corpus-v2)

The 500 Sake programs in `corpus/` were written with an earlier Sake. Since then the language gained:

- Tuples, Arrays, Sets, Hashes and Records compare by contents with `==`; Tuples and Arrays are ordered
  (`<`, `<=>`, `sort_by { [a, b] }`, `Array.max` of Tuples).
- Unary operators: `-x`, `+x`, `~x`, and `!x` (which means `x ? false : true`).
- Multiple assignment and block parameters take an Array apart too: `k, v = String.split(s, "=")`,
  `Array.each_cons(xs, 2) { |a, b| }` (the lengths must match).
- `(A|B).f(x)`: list the types on the operation; `x`'s type picks which `f` runs
  (e.g. `(Leaf|Node).get_weight(t)`, `(String|Array).size(x)`).
- Chains `x.T.f(args)` = `T.f(x, args)`, and `_` = the value of the previous statement, so that a
  sequence of operations can read in order.
- Symbol literals are tracked by the checker, so `case op in :add ... in :sub` without `else` is fine.

Read `docs/tutorial.md`, `docs/spec.md`, and `docs/builtins.md` in `/home/ko1/app/sake` again for the
details (do not read `lib/`, `DESIGN.md`, other `experiments/` directories, or `test/`).

## Your job

Revise the Sake programs of your domain in `corpus-v2/<NN-domain>/` (copies of `corpus/<NN-domain>/`)
into the way you would naturally write them in today's Sake:

- Remove workarounds that are no longer needed (packed sort keys, `0 - x`, `x == false`, index access
  instead of destructuring, hand-written comparison helpers, case/in on types to call same-named
  operations, ...). The `NOTES.md` in `corpus/<NN-domain>/` lists the workarounds the original writer used.
- Use a new feature only where it makes the code clearer; do not force it. Do not reshape the program
  otherwise: keep the algorithm, the data, and the output exactly the same (`<slug>.out`).
- Do not touch the Ruby versions (`corpus/<NN-domain>/<slug>.rb`); they stay as they are.
- Run with `bin/sake --strict=0` (never `--types` or other `--strict` levels), from `/home/ko1/app/sake`.
  Run Bash commands with `dangerouslyDisableSandbox: true`. Use a private scratch directory (e.g.
  `<scratchpad>/<NN>/`), not shared file names, for helper scripts.
- If a program needs no change, leave it unchanged.

## Output

- The revised `<slug>.sake` files in `corpus-v2/<NN-domain>/`, each exiting 0 and printing exactly `<slug>.out`.
- `corpus-v2/<NN-domain>/CHANGES.md`: one line per program: `- <slug>: <what changed>` or
  `- <slug>: unchanged`, naming the features used and the workarounds removed.
- `corpus-v2/<NN-domain>/NOTES.md`: difficulties that remain with today's Sake (what you still had to
  work around, and anything that looks like an interpreter bug, with a minimal repro). Keep it short.

Finish by checking every program: `bin/sake --strict=0 corpus-v2/<NN-domain>/<slug>.sake` must exit 0
and its output must be byte-identical to `corpus-v2/<NN-domain>/<slug>.out`.
