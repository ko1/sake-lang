# TypeProf 0.31.1: the 38 TIMEOUT programs of the inference-500 corpus

**Setup.**
- TypeProf 0.31.1, rbs 3.10.0, ruby 4.0.2 (x86_64-linux), run as `typeprof --show-errors FILE.rb`.
- The corpus run (`../../results-head/typeprof.jsonl.gz`) used `timeout 120` and `ulimit -v 3000000` (about 3 GB), with 5 programs running in parallel.
- Here every TypeProf run goes through `tools/tp`. It takes a lock so that only one of these runs is active at a time, applies `timeout` and `ulimit -v`, and prints wall time, max RSS and user+sys CPU time.
- The machine is shared. Its load average was between 3 and 30 during this work: `p 1` took 0.85 s when the machine was quiet and about 5 s at load 30.
- The scaling tables therefore use CPU seconds taken while the machine was quiet. No conclusion depends on small time differences: a run either finishes in about 1 s or does not finish at all.

## Summary

All 38 timeouts come from **two distinct bugs**. For each bug, an in-process diagnostic monkeypatch makes the affected programs finish in 1-3 s. These patches are diagnostics only, not proposed fixes.

| | bug | programs | minimal repro | verified by |
|---|---|---|---|---|
| A | **SplatBox livelock.** A block with 2 or more params on a method that yields ONE value (auto-splat), e.g. `{"a" => 1}.max_by { \|k, v\| v }`. Each re-run of the enclosing MethodCallBox destroys and re-creates the SplatBox, which brings a fresh `ret` vertex, which triggers the MethodCallBox again. This never terminates. Dead SplatBoxes are also never unlinked, so the run either keeps slowing down or runs out of memory. | **36** | `repros/r1_max_by_pair.rb`, `r2_filter_map_tuple.rb`, `r3_custom_rbs.rb` + `.rbs` | (1) patch `tools/reuse_splat.rb`: 36/36 finish in about 1 s. (2) Rewriting only the trigger blocks as `{ \|e\| k, v = e; ... }`, with byte-identical Ruby output: 36/36 finish. |
| B | **Exponential `Vertex#show`.** The analysis converges after about 1000 box runs. Printing the signatures then unfolds a *cyclic* type graph into a tree with no memoization and no size limit. The cyclic graph comes from a recursive AST built from tuples such as `[:add, node, term]`. | **2** (`14-errors/expr_calculator.rb`, `12-parsers/type_checker.rb`) | `repros/b1_tuple_ast_levels6.rb`, `b2_tuple_ast_kinds5.rb` | patch `tools/cap_show.rb` (print `untyped` below nesting depth 4): both finish in about 2 s. |

Bug A is the same bug as root cause B in the crash/OOM analysis (`../crash/findings.md`). The 9 OOM programs are bug A runs that reached the 3 GB limit before the 120 s limit.

More time does not help (section 4):
- At 600 s / 8 GB, 2 of 3 bug A programs die of OOM (at 7.3 GB, after 215 s and 285 s), and the third is still running at 600 s.
- Both bug B programs are still printing at 600 s.

---

## 1. Characterization

### 1.1 Per program

`results/per-program-table.md` has one row per program, with these columns:
- LOC;
- the bug;
- the MethodCallBox that re-ran most often during a 10 s sample of the unpatched run (`results/churn-unpatched.txt`);
- the number of trigger blocks;
- the result with the patch and with the source rewrite;
- static features.

LOC (non-blank, non-comment lines) of the 38: from 57 to 197, median 102. The finished programs have median 103, so **size does not explain the timeouts**.

Looping call sites reported by the churn sampler, by method:

| method | `max_by` | `sort_by` | `min_by` | `filter_map` | `flat_map` | `map` |
|---|---|---|---|---|---|---|
| sites | 15 | 9 | 7 | 2 | 2 | 1 (doc_pretty, section 2.3) |

For the 2 bug B programs the sampler finds no churn: no box ran more than 3 times.

### 1.2 What is over-represented

Static features come from a Prism walk: `tools/features.rb` produces `features.tsv`, and `tools/compare.rb` produces `results/feature-comparison.md`. The trigger count comes from `tools/rewrite.rb` and is in `results/trigger-count-all.txt`. The 38 timeouts are compared with the 451 programs that finished. The 11 crash/OOM programs are left out; 9 of them have a trigger block.

A **trigger block** has all of the following:
- 2 or more block params;
- the call is one of `max_by`/`min_by`/`sort_by`/`filter_map`/`flat_map`/`to_h`/`map`/`min`/`max`/`sum`/`group_by`;
- the block result is a bare read of one of the params, possibly through `if`/`case`/ternary.

| feature | timeouts (38) | finished (451) |
|---|---|---|
| has a **trigger block** | **35 (92%)** | 58 (13%) |
| any block with 2 or more params: share of programs, median count | 95%, 5 | 87%, 2 |
| `max_by` with a block of 2 or more params | 19 (50%) | 34 (8%) |
| `min_by` with a block of 2 or more params | 7 (18%) | 9 (2%) |
| `sort_by`/`min_by`/`max_by` whose block returns an array literal | 29% | 12% |
| uses `Set` / `to_set` | 32% | 19% |
| has a Hash literal | 82% | 58% |
| LOC median | 102 | 103 |
| `def` count median | 8 | 9 |
| direct recursion (self-call) | 11% | 17% |
| Hash literal with mixed value kinds | 3% | 11% |
| literal nesting depth, median | 2 | 2 |

**Features that do not matter:**
- Struct and Data never occur in the corpus. Comparable is rare.
- Deep literals, mixed-value Hashes and recursion are *not* over-represented.

**Features that only correlate:** Set, Hash literals and array-key `sort_by` are over-represented, but only because they go with the "tally into a Hash, then `max_by { |k, v| v }`" style. Evidence: the source rewrite (section 2.2) leaves all of them in place, and all 35 trigger-block programs still finish.

**The 3 timeouts without a trigger block:** doc_pretty is a bug A variant (section 2.3). The other 2 are bug B.

---

## 2. Bug A: SplatBox livelock (36 programs)

### 2.1 Minimal repros

```ruby
p({"a" => 1, "b" => 2}.max_by { |k, v| v })   # repros/r1_max_by_pair.rb  (Ruby prints ["b", 2])
p [[1, 2]].filter_map { |a, b| a }            # repros/r2_filter_map_tuple.rb  (Ruby prints [1])
```

Neither finishes. r1 dies at 3 GB after about 75 s (timeline in section 2.2).

**No core method is needed.** A user signature is enough (`repros/r3_custom_rbs.rb` plus `r3_custom_rbs.rbs`; run as `typeprof r3_custom_rbs.rb r3_custom_rbs.rbs`):

```rbs
class Object
  def yield_pair: () { ([Integer, Integer]) -> Integer } -> Integer   # TIMEOUT
end
```
```ruby
x = yield_pair { |a, b| b }
```

With `[U] () { ([Integer, Integer]) -> U }` (`r3_custom_rbs_ok.rbs`) the same Ruby code finishes in 0.8 s (`results/receiver-matrix.txt`, "repro checks").

Other RBS variants, tested with `{ |a, b| a }` and a yielded `Array[Integer]` or `[Integer, Integer]`:

| block return type | result |
|---|---|
| `Integer` | livelocks |
| `bool` | livelocks |
| `(nil \| U)` | livelocks |
| `U` | finishes in about 1 s |
| `untyped` | finishes in about 1 s |
| `(U \| nil)` | finishes in about 1 s |

**Core methods** (`results/method-matrix.txt`; `x = RECV.m { |a, b| b }`, 10 s cap):

| method | `[[1, "a"]]` | `{1 => "a"}` | RBS block return type |
|---|---|---|---|
| `max_by`, `min_by`, `sort_by` | TIMEOUT | TIMEOUT | `Comparable \| Array[untyped]` |
| `filter_map` | TIMEOUT | TIMEOUT | `nil \| false \| U` |
| `flat_map` | TIMEOUT | TIMEOUT | `Array[U] \| U` |
| `to_h` | TIMEOUT | ok | `[K, V]` |
| `map`, `select`, `reject`, `partition`, `group_by`, `sum`, `count`, `find`, `any?`, `all?`, `each`, `each_with_index` | ok | ok | type variable, `boolish` or `untyped` |

**Block results** (`results/body-matrix.txt`; `{"a" => 1}.sort_by { |k, v| BODY }`):

| result | `BODY` |
|---|---|
| livelocks | `v`, `k`, `(v)`, `k if v` |
| finishes in about 1 s | `-v`, `[-v, k]`, `[v, k]`, `v.size`, `v \|\| 0` |

**Param list** (with `ret_int { |a, b| b }`):

| param list | result |
|---|---|
| `\|a, b\|` | livelocks |
| `\|(a, b)\|`, `\|a, *b\|`, `\|kv\|` | finish |

**Receiver** (`results/receiver-matrix.txt`, `results/receiver-matrix2.txt`). Every form below livelocks:
- literal Hash or Array;
- `{}` / `Hash.new(0)` filled with `[]=` / `+=` (also inside an `each`);
- `[]` filled with `<<`;
- a receiver passed as a method argument;
- values of type `nil`, Symbol, Object, or an attr_reader result.

### 2.2 Mechanism

Source: `lib/typeprof/core/...` of typeprof-0.31.1.

1. `Block#accept_args` (env/method.rb:95-104): when one value is yielded to a block with 2 or more params, it calls `changes.add_splat_box(genv, single_arg, i)` for each param. It then adds an edge from the SplatBox `ret` to the param.

2. `ChangeSet#add_splat_box` (graph/change_set.rb:80-83) memoizes only in `@new_boxes`, which is empty at the start of every run. `reinstall` (lines 171-175) then **destroys every box from the previous run**. So each re-run of the MethodCallBox creates new SplatBoxes, each with a new `ret` Vertex.
   - *Observed:* `tools/churn.rb` counts SplatBox creations per `(vertex, index)` key. Within 10 s it finds between 256 and 31 804 re-creations for one key in every one of the 36 programs, and 0 in the 2 bug B programs (`results/churn-unpatched.txt`). The re-run box is the `max_by`/`sort_by`/... MethodCallBox in all 36.

3. The new `ret` replaces the old one, so the param vertex sees its types removed and then added again. The block result is that param (or one branch of a conditional). `resolve_overload` (graph/box.rb:224-229) type-checks it against the RBS block return type. For a class type, that check adds an edge from the checked vertex to `changes.target`, i.e. the MethodCallBox itself (`SigTyBaseBoolNode#typecheck`, `AST.typecheck_for_module`). So the remove/add on the param queues the MethodCallBox again, and the cycle restarts at step 2.
   - *Status: inferred from the code, not instrumented.* What supports it is the RBS matrix: a type variable or `untyped` return type, which adds no such edge, does not loop. I did not trace the edge itself.
   - Section 2.3 shows a second path back to the MethodCallBox.

4. **Leak.** `SplatBox#initialize` runs `@ary.add_edge(genv, self)`, and `destroy` never removes that edge. Every dead SplatBox therefore stays in `@next_vtxs` of the splatted vertex, and every type change on that vertex walks all of them. *Observed* with `tools/livelock_timeline.rb` (`results/long-runs.txt`):

   | t | survey_venn: SplatBoxes created / dead edges kept / RSS | r1_max_by_pair: SplatBoxes created / RSS |
   |---|---|---|
   | 10 s | 8 512 / 8 484 / 172 MB | 83 942 / 382 MB |
   | 30 s | 14 836 / 14 808 / 197 MB | 265 806 / 980 MB |
   | 60 s | 20 731 / 20 703 / 219 MB | 544 434 / 1870 MB |
   | 120 s | 29 509 / 29 481 / 255 MB | (died at about 75 s: `[FATAL] failed to allocate memory` at 3 GB) |

   - In survey_venn the iteration count grows like sqrt(t) (8.5k x sqrt(12) = 29.4k). That matches a per-iteration cost proportional to the number of dead edges, i.e. quadratic total time.
   - In r1 the iteration rate stays at about 9k/s and memory grows by about 3.4 KB per iteration until OOM.
   - Which of the two failure modes appears (slow-down or OOM) presumably depends on how many other vertices hang off the loop. *This is not investigated.*

**Verification.**

| check | how | result |
|---|---|---|
| Patch | `tools/reuse_splat.rb` changes only `add_splat_box`: it takes the SplatBox from `@boxes` when the key is the same, instead of making a new one. | **36/36 finish in 1.0-3.4 s** (`results/patched-reuse_splat.txt`; the 2-3 s values were measured under load). Unchanged results: 8 randomly chosen programs that already finished produce byte-identical TypeProf output with and without the patch (`results/patched-vs-unpatched-finished.txt`). |
| Source rewrite, narrow | `tools/rewrite.rb` turns each trigger block `{ \|a, b\| body }` into `{ \|e__0\| a, b = e__0; body }`. This is the same Ruby for a method that yields one value. The Ruby output of every rewritten program is byte-identical to the original (`results/rewrite-ruby-check.txt`). | **35/38 finish** in about 1.1 s (`results/rewritten-narrow.txt`). |
| Source rewrite, `--all` | Rewrites every block with 2 or more params on those methods, whatever its result. | Also fixes doc_pretty, so **36/38** (`results/rewritten-all.txt`). |

The 2 programs left after the rewrite are the bug B ones.

**Fix direction** (a suggestion, tested only as the diagnostic patch):
- Reuse sub-boxes across re-runs when their key is unchanged, as `tools/reuse_splat.rb` does for SplatBox. The other `add_*_box` helpers use the same `@new_boxes[key] ||=` pattern.
- Independently of that, `Box#destroy` should unlink the box from the vertices it subscribed to with `add_edge`.

### 2.3 Variant: the param flows back through a recursive call (doc_pretty)

`01-text/doc_pretty.rb:89` is `value.map { |k, v| group(... to_doc(v)) }` inside `to_doc(value)`. The block return type of `Hash#map` is a type variable, so the typecheck edge from step 3 does not apply. Instead, the splatted `v` flows back into `value` (the receiver) through the recursion.

Reduced form, `scratch/rx/d1.rb` (`results/recursive-map.txt`):

```ruby
def to_doc(value)
  case value
  when Hash then value.map { |k, v| to_doc(v) }
  else value.to_s
  end
end
p to_doc({"a" => {"b" => 1}})
```

| version | unpatched | `reuse_splat` patch |
|---|---|---|
| `\|k, v\|` (d1) | TIMEOUT at 30 s | 0.9 s |
| `\|kv\|` with `kv[1]` (d2) | 0.8 s | 0.7 s |

### 2.4 Open question: why 58 finished programs contain a trigger block

Two of them were checked with a SplatBox-site counter (`scratch/splatsites.rb`): `10-grids/n_queens.rb:68` and `02-analytics/email_domains.rb:83`, both of the form `h.max_by { |_, n| n }`.
- In both, the SplatBox at that site is created exactly once per distinct argument vertex: 2 vertices and 2 creations each. The loop never starts.
- In both, the splatted element type contains `untyped`: `[nil, untyped]` and `[untyped, Integer]`.
- TypeProf also reports `expected: Comparable | Array[...]; actual: nil` there.

**Hypothesis, NOT confirmed:** I tried to rebuild the condition in small files: an `untyped`-ish key, a `nil` value, and filling via `[]=` inside `each` (`results/receiver-matrix2.txt`). All of them still livelock, so what stops the loop in these programs is not identified.

---

## 3. Bug B: exponential `Vertex#show` on cyclic tuple types (2 programs)

### 3.1 Observation

- **The analysis has converged.** `tools/boxcount.rb` shows the total box-run count stops at about 1070 within the first 15 s for both programs and does not grow by 45 s.
- **The time goes into printing.** A backtrace sampled at 30 s (`tools/btdump.rb`) is a deep `BasicVertex#show` → `Type::Array#show` → `BasicVertex#show` → ... recursion (vertex.rb:23-62, type.rb:145-151), i.e. signature printing.
- **The type graph is small but cyclic.** `tools/typesize.rb` finds only 12-21 `Type::Array` objects alive, and the largest vertex holds 15-18 types. Both numbers are stable over time.
- **Cause.** `BasicVertex#show` guards recursion only along the current path (`Fiber[:show_rec]`). A cyclic graph is therefore printed as a tree in which each vertex can appear once per path, with no memoization and no limit on output size.

**Verified:** `tools/cap_show.rb` prints `untyped` for vertices nested deeper than 4. With it, expr_calculator finishes in 1.9 s and type_checker in 2.2 s, and `b1_tuple_ast_levels6.rb` finishes in 1.1 s.

### 3.2 Minimal repros and scaling

Both programs are recursive-descent parsers that build `[:add, node, term]` / `[:bin, op, l, r]` tuples. Two generator knobs reproduce the blow-up. CPU seconds are user+sys; `p 1` takes 0.85 s. Rows with several times come from repeated runs (3 repeats plus the first run).

**Knob L.** `tools/gen_levels.sh L` makes L precedence levels. `level_i` builds `[:op_i, node, level_{i+1}]` in a `while` loop, and the last level returns `[:num, 1]` or recurses to `level1`. Repro: `repros/b1_tuple_ast_levels6.rb` (L = 6).

| L | CPU s | max RSS | TypeProf output size |
|---|---|---|---|
| 2 | 0.86 | 119 MB | 459 B |
| 3 | 0.86 | 119 MB | 12 KB |
| 4 | 1.16 / 1.15 / 1.22 | 138 MB | 697 KB |
| 5 | 19.5 / 19.3 / 19.2 / 19.7 | 485-538 MB | **64 MB** |
| 6 | > 120 (TIMEOUT) | 1.4 GB at kill | – |

**Knob K.** `tools/gen_kinds.sh K` makes one recursive `expr` that returns `[:num, 1]` or one of K binary `[:op_i, expr, expr]`. Repro: `repros/b2_tuple_ast_kinds5.rb` (K = 5).

| K | CPU s | max RSS | TypeProf output size |
|---|---|---|---|
| 1 | 0.86 | 119 MB | 268 B |
| 2 | 0.86 | 119 MB | 4.3 KB |
| 3 | 0.90 | 123 MB | 180 KB |
| 4 | 4.97 / 4.95 / 4.92 / 5.14 | 267-272 MB | **13 MB** |
| 5 | > 300 (TIMEOUT; wall time, measured under load) | 1.4 GB at kill | – |

Output size grows 40-90x per step, and time grows with it. expr_calculator has 3 levels and 6 tuple kinds; type_checker has 5 levels and 8 kinds.

**Fix direction** (a suggestion): memoize `show` per vertex while printing one signature, or limit the depth and width of what is printed. The analysis result itself is fine.

---

## 4. Do the timeouts finish with more time? (600 s, 8 GB)

`results/long-runs.txt`, unpatched, one run at a time:

| program | bug | result | wall | max RSS |
|---|---|---|---|---|
| 18-collections/survey_venn.rb | A | TIMEOUT (still looping) | 600 s | 388 MB |
| 02-analytics/markov_text.rb | A | exit 1 (OOM, same as the 3 GB OOM runs) | 215 s | 7.3 GB |
| 20-business/grade_book.rb | A | exit 1 (OOM) | 285 s | 7.3 GB |
| 14-errors/expr_calculator.rb | B | TIMEOUT (still printing) | 600 s | 2.9 GB |
| 12-parsers/type_checker.rb | B | TIMEOUT (still printing) | 600 s | 494 MB |

The "OOM" label comes from 7.3 GB RSS against an 8 GB limit plus exit status 1. `tools/tp` did not keep stderr for these runs; the crash analysis saw `[FATAL] failed to allocate memory` for the same signature. For bug A, more time cannot help: there is no fixed point.

---

## Files

**Repros**
- `repros/`: minimal repros. All of them run correctly with `ruby`.

**Runner**
- `tools/tp`: runs one TypeProf at a time under lock, `timeout` and `ulimit`, and reports wall time, RSS and CPU. `TP_PATCH=name` loads `tools/name.rb` before TypeProf.

**Diagnostic patches** (verification only)
- `tools/reuse_splat.rb`
- `tools/cap_show.rb`

**Observers** (they do not change behavior; they print to stderr after N seconds)
- `tools/churn.rb`
- `tools/boxcount.rb`
- `tools/btdump.rb`
- `tools/typesize.rb`
- `tools/livelock_timeline.rb`

**Static features**
- `tools/features.rb` and `tools/compare.rb` produce `features.tsv` and `results/feature-comparison.md`.
- `results/trigger-count-all.txt`: trigger blocks for the whole corpus.

**Rewrite and generators**
- `tools/rewrite.rb`: the trigger-block rewrite. Output goes to `rewritten/` and `rewritten-all/`.
- `tools/gen_levels.sh`, `tools/gen_kinds.sh`: scaling generators for bug B.

**Delta debugging**
- `tools/ddmin.rb`: line-based delta debugger. On expr_calculator it was too slow, because every "still slow" check costs 15 s. Its partial result is `scratch/ex/min.rb`; the bug B repros were finished by hand.

**Inputs**
- `failures.tsv`, `timeouts.txt`, `crashed.txt`: lists taken from the corpus results.
