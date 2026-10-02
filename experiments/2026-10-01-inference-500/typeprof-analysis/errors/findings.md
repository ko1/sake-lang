# TypeProf 0.31.1 false positives on the inference-500 corpus: root causes

Date: 2026-10-01/02. TypeProf 0.31.1, Ruby 4.0.2, rbs 3.10.0 (the only rbs installed).
Input: ../../results-head/typeprof.jsonl.gz (`typeprof --show-errors FILE.rb`, 120 s / 3 GB per program).
451 programs finished, 391 of them have errors, 3,331 errors in all. Every program runs with `ruby`
and exits 0, so every error is a false positive.

All numbers below come from the cumulative counterfactual runs runs/V0..V11.jsonl, plus the hand
classification (hand.tsv) and hand checks (handcheck.tsv). The single-factor ablation (runs/S-*.jsonl)
was NOT completed: it was stopped after 6 of 11 switches (to save time). Its partial results are shown separately.

(Written by the analysis agent; saved here by the coordinator because the agent could not write report files.)

## Summary

About 60 % of the errors come from TypeProf bugs or missing features. Each is reproduced by a program
of a few lines below. About 30 % are TypeProf being conservative about nil (a library method typed T?,
or a field initialized to nil) where the program knows the value is present.

| | errors | kind |
|---|---:|---|
| library return typed T? (find, min_by, max_by, index, match, MatchData#[], pop, ...) | ≤559 | by design (upper bound) |
| `x.nil?` / `x == nil` guards do not narrow (`!x`, `unless x` do) | 425 | missing narrowing |
| nil set by the program (fields of linked structures, sentinels) | 289 | by design |
| an argument with no type at all fails every overload (a cascade) | 258 | design question |
| RBS interfaces (`_ToS`, `Math::double`, `_Each`, `_Inspect`) checked nominally: `puts 42` fails | 252 | bug |
| `a, b = ary` with ary : Array[T] binds the whole array to `a`, nothing to `b` | 231 | bug |
| block parameter named like a local assigned later in the same scope is typed nil | 204 | bug |
| all matching overloads are unioned: `2026 % 100 : Integer \| Numeric` | 137 | bug |
| `module_function` not supported | 119 | missing feature |
| sort_by/min_by/max_by with an Array key: the key's types leak into the elements | 100 | bug |

## Method

The message alone does not say why an error is false. `undefined method: nil#+` can come from an
unguarded `find`, from a `.nil?` guard that does not narrow, from a parameter left nil by a destructuring
bug, or from a caller several calls away. So the errors are classified by **counterfactual**:

* For each suspected cause there is a switch that removes only that cause. A switch is either a
  TypeProf monkey patch (patches/*.rb) or a source rewrite applied to a scratch copy of the program
  (rewrite.rb). The corpus is not modified.
* Rewrites keep every line and column. So an error is identified by its full text
  `(l,c)-(l,c):msg`, as a multiset per program.
* Switches are applied cumulatively in the order V1..V11 below. Each error is attributed to the first
  Vn in which it is gone (attribute.rb).
* driver.rb loads TypeProf, the patches and the core RBS once, then forks one child per program
  (120 s CPU, 3 GB address space). The child does what `typeprof --show-errors FILE` does:
  `update_file` followed by `diagnostics`. One analysis runs at a time, under a lock shared with probes.
* **Harness check:** V0 (no switch, same driver) reproduces results-head exactly for all 391 programs.
* Each repro below was run under its own switch alone, and the switch removed its error
  (repro/counterfactual-check.txt).

| variant | switch added | kind | file |
|---|---|---|---|
| V1 | check interfaces structurally: a class satisfies `_ToS` if it has `to_s` | patch | patches/interface.rb |
| V2 | skip a trailing `(Numeric) -> Numeric` overload when an earlier one matched | patch | patches/numeric_catchall.rb |
| V3 | `a, b = ary` (ary : Array[T]) gives T to each target | patch | patches/masgn.rb |
| V4 | memoize RBS-node vertices per receiver type arguments in `get_instance_type` | patch | patches/sigvertex.rb |
| V5 | `module_function` -> `class << self` | rewrite | rewrite.rb modfunc |
| V6 | rename a block parameter that shadows an outer local | rewrite | rewrite.rb shadow |
| V7 | `x.nil?` / `x == nil` -> `!x`; `x != nil` -> `!!x` | rewrite | rewrite.rb nilq |
| V8 | `if (m = E)` -> `if (m = E) && m` | rewrite | rewrite.rb acond |
| V9 | drop nil from RBS return types (`T?`, `T \| nil`) | patch | patches/rbs_nonnil.rb |
| V10 | the literal `nil` in the program has no type | patch | patches/nil_literal.rb |
| V11 | an argument with no type passes every RBS parameter type | patch | patches/empty_arg.rb |

V9 and V10 are not fixes: they measure how much is due to nil that is really there. V11 measures the
cascade of errors on values that have no type.

Errors that no switch removes were classified in two more steps:
* Static Prism detectors on the source at the error (static.rb): nested destructuring parameter,
  `case x in Const`, block-parameter shadowing.
* The rest by hand, on a random sample.

**How much was automatic:** 2,645 errors (79 %) by counterfactual; 139 (4 %) by static detectors;
98 (3 %) are in programs where a counterfactual run did not finish (`counterfactual-run-failed`);
449 (13 %) are left, and a random sample of 50 of them (seed 5) was classified by hand (hand.tsv).

**Hand check of the automatic attribution** (handcheck.tsv): 116 errors sampled across the automatic
categories and read in their source: 104 confirmed, 2 plausible but not traced (V3), 6 unclear and
2 wrong, all 8 in lib-nilable-return. The 2 wrong ones are `String#scan`: the nil-dropping patch also
changes its RBS type `Array[String | Array[String?]]`, which is not a nil issue. So lib-nilable-return
is an upper bound (12 of 20 sampled confirmed). Every sampled error in the other categories was
confirmed, but the samples are small (4 to 20 per category).

## Results (cumulative runs V0..V11)

| root cause | errors | programs | example | code |
|---|---:|---:|---|---|
| lib-nilable-return | 559 | 150 | 04-numeric/linear_regression.rb:82 nil#temp | `worst = obs.max_by {...}`; `worst.temp` |
| nil?-no-narrow | 425 | 88 | 07-trees/traversals.rb:36 nil#left | `next if n.nil?` (l.34); `stack.push(n.right, n.left)` |
| user-nil | 289 | 60 | 06-linked/lru_cache.rb:79 nil#prev= | `if e.next` / `e.next.prev = e.prev` |
| empty-arg | 258 | 107 | 08-graphs/kruskal_network.rb:12 failed to resolve overloads | `root = @parent[root] while @parent[root] != root` |
| interface-nominal | 252 | 84 | 10-grids/game_of_life.rb:53 wrong type of arguments | `puts board` |
| masgn-from-Array | 231 | 42 | 18-collections/sensor_merge.rb:6 Array[String]#to_i | `t, v = pair.strip.split("=")`; `t.to_i` |
| block-param-shadow | 204 | 44 | 09-dp/house_robber.rb:28 nil#>= | `loot.each_with_index do \|v, i\|` ... `i >= 1` |
| numeric-catchall-overload | 137 | 55 | 17-encodings/caesar_cracker.rb:14 Numeric#chr | `((o - 65 + k) % 26 + 65).chr` |
| module_function | 119 | 12 | 06-linked/list_toolkit.rb:150 singleton(L)#show | `L.show(low)` |
| sig-vertex-sharing | 100 | 12 | 11-simulation/elevator_scan.rb:91 Integer#id | `cars.min_by { \|c\| [c.cost(rider.from, dir), c.id] }` |
| counterfactual-run-failed | 98 | 17 | 07-trees/spanning_tree.rb:71 | `parent[v] = u` |
| case-in-no-narrow | 90 | 15 | 19-statemachines/event_sourcing.rb:88 Transferred#account | `in Deposited` ... `ev.account` |
| assign-in-cond-no-narrow | 76 | 19 | 12-parsers/assembler.rb:51 nil#[] | `if (m = src.match(...))`; `labels[m[1]] = ...` |
| nested-destructure-param | 47 | 21 | 04-numeric/bezier_curves.rb:1 nil#- | `def lerp((px, py), (qx, qy), t) = ...` |
| not classified | 449 | ~96 | (hand sample below) | |
| total | 3,331 | 391 | | |

The 449 not classified, from the hand sample of 50 (rough: with n = 50, a 26 % share has a 95 %
interval of about 14–40 %):

| hand label | of 50 | est. of 449 |
|---|---:|---:|
| nil arrives through user methods, origin not isolated | 13 | ~115 |
| shared-field-union: one type per parameter or field for all callers (e.g. `Matrix#-(b)`, b : Matrix\|Float\|Rational) — by design | 9 | ~80 |
| heterogeneous container (JSON-like values) — by design | 8 | ~70 |
| `while x.is_a?(C)` / `while (x = E)` (even with `&& x`) do not narrow the body | 4 | ~35 |
| `Integer#**` is `(Integer) -> Numeric` in RBS | 3 | ~25 |

Each of these appeared once or twice in the sample: `yield` into an `&:sym` block calls `Symbol#call`
(bug); `args[0].is_a?(Array)` does not narrow `args[0]`; case/in reached through a call; a method
defined only in subclasses; `x in String` pattern tests do not narrow; an implicit nil branch; a
top-level self-call resolving to an unrelated class's method; one unclear.

By message:

| cause | wrong type | overloads | nil#m | T#m | other |
|---|---:|---:|---:|---:|---:|
| lib-nilable-return | 0 | 0 | 524 | 28 | 7 |
| nil?-no-narrow | 0 | 0 | 421 | 4 | 0 |
| not classified (incl. 52 hand-labelled lines) | 16 | 17 | 163 | 229 | 16 |
| user-nil | 0 | 0 | 283 | 0 | 6 |
| empty-arg | 59 | 191 | 0 | 8 | 0 |
| interface-nominal | 239 | 7 | 2 | 4 | 0 |
| masgn-from-Array | 59 | 25 | 0 | 141 | 6 |
| block-param-shadow | 5 | 63 | 129 | 1 | 6 |
| numeric-catchall-overload | 2 | 0 | 0 | 135 | 0 |
| module_function | 8 | 29 | 0 | 82 | 0 |
| sig-vertex-sharing | 1 | 5 | 3 | 91 | 0 |
| counterfactual-run-failed | 5 | 38 | 31 | 12 | 12 |
| case-in-no-narrow | 0 | 1 | 0 | 86 | 3 |
| assign-in-cond-no-narrow | 0 | 0 | 76 | 0 | 0 |
| nested-destructure-param | 9 | 9 | 29 | 0 | 0 |
| total | 403 | 386 | 1,662 | 823 | 57 |

Most of the 403 "wrong type of arguments" errors are interface checks: puts 61, Math.sqrt 35,
Math.exp 25, Set#& 22, Math.sin 17, Math.cos 14, Set#| 11, ... Most of the 386 "failed to resolve
overloads" errors are on arguments that have no type (191).

### Single-factor ablation (NOT completed)

| switch | errors removed | new errors | runs that did not finish |
|---|---:|---:|---:|
| interface | 252 | 31 | 0 |
| numeric_catchall | 137 | 0 | 0 |
| masgn | 237 | 38 | 2 |
| sigvertex | 110 | 0 | 0 |
| modfunc | 119 | 26 | 0 |

S-shadow was stopped partway; nilq, acond, rbs_nonnil, nil_literal and empty_arg were not run. Where
they exist, these agree with the cumulative numbers, so the order matters little for these five.

### Unmasked errors and failed runs

A counterfactual run also reports errors that were not in results-head, because values now flow where
they did not before. These are not counted above. Cumulative counts: V1 31, V3 68, V5 92, V7 83, V9 98,
V10 85, V11 435. When a program's run did not finish, its remaining errors are counted as
counterfactual-run-failed: 2 programs at V3 (todo_list, vendor_quotes), 11 more at V6, 4 more at V11.
All 13 that fail at V6 contain two-parameter blocks over a Hash (consistent with the SplatBox loop in
../timeout/findings.md, not proven).

## Minimal repros (repro/; exact TypeProf output in repro/outputs.txt; each runs with ruby, exit 0)

1. **Interface checked nominally — bug, 252.** `puts 42` / `p 1, 2` / `Math.sqrt(2.0)`:
   `wrong type of arguments`, `failed to resolve overloads`, `wrong type of arguments`.
   `SigTyInterfaceNode#typecheck` calls `typecheck_for_module`; only String, Array and Hash pass, via the
   built-in shim that declares them to include `_ToS`, `_ToStr`, `_ToAry` and `_Each`.
2. **Overload union — bug, 137.** `r = 2026 % 100; p r / 4` gives `undefined method: Numeric#/`.
   `Integer#%` ends with a `(Numeric) -> Numeric` overload; `resolve_overloads` adds the return type of
   every matching overload, whereas RBS picks the first match.
3. **`.nil?` does not narrow — missing feature, 425.** `return 0 if x.nil?; x + 1` gives `nil#+`.
   Also not: `x.nil? ? :`, `x.nil? ||`, `until x.nil?`, `case x when nil`, `== nil`. Narrow: `!x`, `unless x`, `x &&`.
4. **masgn from Array[T] — bug, 231.** `h, m = s.split(":").map(&:to_i); h * 60 + m` gives
   `wrong type of arguments` (h : Array[Integer], m untyped). `MAsgnBox#run0` handles only tuples ("TODO: call to_ary?").
5. **`if (m = E)` — missing feature, 76.** `undefined method: nil#[]`. `if (m = E) && m` narrows;
   `while (m = E)` does not narrow the body even with `&& m`.
6. **Library T? — by design, ≤559.** `best = xs.min_by { |x| -x }; p best + 1` gives `nil#+`.
7. **ivar nil sentinel — by design, 289.** `@n = nil` in initialize, later `@n += 1` gives `nil#+`.
   Related (r12): `return 0 unless @v; @v + 1` gives `nil#+`; an ivar guard narrows only inside `if`.
8. **Block param shadowing a later local — bug, 204.** `[1, 2].each { |v| p v + 1 }; v = "done"` gives `nil#+`.
9. **module_function — missing feature, 119.** `undefined method: singleton(Geo)#area`. `extend self`
   is not supported either; `class << self` is.
10. **sort_by with an Array key — bug, 100.** `pts.sort_by { |pt| [pt.x, pt.y] }` gives
    `undefined method: Integer#x` etc. Two lookups instantiate the same RBS node `Elem` of Array's
    `include Enumerable[Elem]` through `GlobalEnv#get_instance_type` (finding `sort_by` in Enumerable,
    and checking the block value against `Comparable | Array[untyped]`); `ChangeSet#new_covariant_vertex`
    memoizes the vertex per RBS node only, so both share one vertex and the key's element types flow into
    `Elem`. patches/sigvertex.rb removes the errors. 14-errors/job_queue.rb has 66 errors, most from one
    `min_by { |j| [j.run_at, j.id] }`.
11. **No-type argument — design question, 258.** `failed to resolve overloads` on an argument with an
    empty vertex (`typecheck_for_module` returns false). Errors are already suppressed for a receiver with no type.
12. **case/in Const — missing feature, 90.** `in Integer` does not narrow (`when Integer`, `is_a?`,
    `in Integer => w` do).
13. **Nested destructuring params — missing feature, 47+.** `def sum_pair((a, b)) = a + b`, `{ |(x, y), i| ... }`.
14. **Top-level self-call — bug.** At the top level, `distance(3, 1)` resolves to an unrelated class's
    `attr_reader :distance` (r15).
15. **`Hash#max_by { |_, n| n }` runs out of memory** (r16). See ../crash and ../timeout.

## By design or bug

* **Likely bugs (about 970 errors):** interface checking (252), overload union (137), masgn (231),
  block-param scoping (204), vertex sharing (100), nested destructuring (47+), `&:sym` + `yield`,
  top-level self-call.
* **Missing narrowing or features (about 710):** `.nil?` / `== nil` (425), `if (m = E)` (76), case/in (90),
  `module_function` (119), while conditions, `x in Pat`, ivar guard with an early return.
* **Design question:** errors on arguments that have no type (258), mostly cascades of the above.
* **By design (about 850–1,000):** nilable library returns (≤559), program-set nil (289), one type per
  field or parameter, heterogeneous containers, `Integer#**` typed as Numeric in RBS.

## Files

driver.rb (runs a variant); patches/*.rb, rewrite.rb (the switches); attribute.rb, classify.rb, static.rb,
locate.rb (attribution and classification); summary.rb, single.rb, sample.rb, typeinfo.rb, hover.rb,
tp (one typeprof under the lock); classified.tsv, hand.tsv, handcheck.tsv; repro/ (with outputs.txt and
counterfactual-check.txt), probe/; runs/old-* (superseded runs).

Note: runs/src-V*/ (the rewritten scratch copies of the programs, ~1.8 MB each) were deleted before committing; rewrite.rb regenerates them.
