# Stored blocks (Procs): what they cost the type checker

Date: 2026-10-04. Question (ko1): "ブロックを受け取るノーテーションは作れそう？ 型推論が爆発するかな".
Prototype: branch `procs` (worktree `../sake-wt-procs`), commits 57ff752..f7523fa on top of main
3fb287e (merged). Main (not the prototype) has IO values, `block_given?` and `&b` passed on (4dffda5,
e19b60b).

## What the prototype adds

- `proc { |x| ... }` (Kernel.proc), `&b` used as a value, and `Proc.call(p, args...)`. A Proc is
  `#<Proc>`; a `break` from a stored block, or a `return` after its function returned, raises
  LocalJumpError.
- **Escape**: a block literal escapes when it is given to `proc`, to a function that uses `&b` as a
  value, or to one that passes `&b` on to such a function (fixpoint over the program; `Lower#escaping_functions`).
- **Shared variables**: every enclosing variable an escaping block uses (read or written) is "shared":
  the typer reads it as the union of its flow-sensitive type and every type it is ever assigned in that
  instantiation of its function, including the arguments of a shared parameter (`Lower#slot`,
  `Typer#shared_key`). Narrowing does not survive on such variables.
- **Proc atoms**: one atom per (block, instantiation that made it), so two `compose(f, g)` calls give two
  Procs (1-CFA-like). A block made where an argument is already a Proc of the same block, or made in more
  than 8 instantiations, gets one merged atom whose variables read the union over all instantiations.
- `Proc.call` analyzes each block the value may be, once per argument types (memoized like functions).

## Method

- `progs/`: three hand-written pairs, the same program with stored blocks (`*_proc`) and in current Sake
  style (`*_plain`): an option parser, an event emitter, closures (counters, a logger formatter); plus
  `compose_unsound.sake`, a soundness probe (two compositions of different types; line 7 is a real error).
- `stress/` (`gen_stress.rb`): `stress_handlers_N`, N blocks in one Array each called with 3 payload
  types; `stress_compose_N`, N procs composed by a function (`compose(f, g) = proc { ... }`).
- `measure.rb`: typer CPU time (median and min..max of 5 runs in one process), passes, instantiations
  (functions; Procs = memoized `Proc.call` analyses), check verdicts, findings at strict levels 1 and 2.
  Local machine (shared, load average 1–3 at the final run), Ruby 3.4, not sp4: the numbers are relative.
- Soundness: `crosscheck.rb` (the procs branch copy, which knows Proc atoms) on progs + stress:
  0 violations. Negative control `--sabotage` on `stress_compose_*` (Float): violations in all 5, so the
  harness sees the Proc paths. The 500-program corpus gives a crosscheck table identical to main's
  (0 lines differ): programs without Procs are unaffected.

## Results (`results.md`)

| program | typer ms | Proc analyses | L1 findings | L2 findings |
|---|---|---|---|---|
| closures plain / proc | 1.5 / 2.6 | 0 / 4 | 0 / 0 | 0 / 0 |
| events plain / proc | 2.8 / 8.8 | 0 / 12 | 0 / **4** | 0 / 4 |
| optparse plain / proc | 13.7 / 12.4 | 0 / 10 | 0 / **4** | 0 / 4 |
| compose_unsound | 2.4 | 6 | 1 (the real error) | 1 |
| stress_handlers 5 / 20 / 80 | 8.3 / 34.2 / 160.8 | 15 / 60 / 240 | 0 | 0 |
| stress_compose 5 / 20 / 80 | 5.0 / 15.6 / 64.9 | 14 / 44 / 164 | 0 | 0 |

**Cost: no explosion.** Time and Proc analyses grow linearly with the number of blocks and call sites
(handlers: 3 payload types × N blocks = 3N analyses; compose: 2N + 4). The plain/proc pairs are within
a few milliseconds of each other.

**Precision: blocks stored together are mixed, as predicted.**
- events_proc: the handlers of all events live in one Hash, so each is analyzed with every payload type:
  4 false reports, all with verdict `error` (surely fails *on the path analyzed*).
- optparse_proc: each handler gets `String | true | nil` (flags pass true, options pass `argv[i]`): 4
  reports, verdict `partial`. The nil part is a real gap (an option given last has no value; Ruby's
  OptionParser raises MissingArgument); the `true` part is mixing.
- The plain versions of both have 0 findings.

**Correction of a prediction.** I had said the pending "level 1 = surely fails only" split would absorb
most of these. It would not: the events reports are `error` verdicts, because each block is analyzed as
if it were the one called. Only the optparse reports (partial) would move to level 2.

**Found and fixed during the experiment.**
- 0-CFA first version: arguments of a function were not recorded as shared, so the body of
  `compose`'s block saw only the latest call's `f`; compose_unsound's real error at line 7 was missed.
  Fixed (shared parameters) and refined (atoms per instantiation), which also removed 3 false reports.
- A merged block read `nil` for its variables (no path of its own); fixed.
- My first check of a corpus violation used `ruby -I<other tree>/lib crosscheck.rb`, but crosscheck
  `require_relative`s its own tree's lib, so "HEAD also violates" and the bisection were measuring the
  working tree. Retracted; re-measured with each tree's own crosscheck: HEAD had 0 violations, the
  violation came from the uncommitted Seq change and was fixed by the rescue-modifier change (e19b60b).

## Conclusion

Stored blocks are feasible at this cost, and sound with shared variables. The price is precision where
blocks of different argument types share a container (an event table, an option table). Options:
1. Ship as is: such programs get false reports at level 1 (events) or level 1/2 (optparse).
2. Keep blocks second-class (current main) and give libraries other shapes (optparse returns a Hash;
   events dispatch with case/in on a tagged Tuple), which check with 0 findings here.
3. Separate containers per key in the typer (Hash value types per literal key, like Records), which
   would fix the events case but not optparse's flag/option mixing.
