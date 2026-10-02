# TypeProf 0.31.1: crashes and out-of-memory runs on the inference-500 corpus

Setup: TypeProf 0.31.1, rbs 3.10.0, ruby 4.0.2 (x86_64-linux), `typeprof --show-errors FILE.rb`,
`ulimit -v 3000000` (about 3 GB of address space), `timeout 120`. The corpus run is
`../../results-head/typeprof.jsonl.gz`. Every repro below runs correctly with `ruby X.rb`.
Times and RSS come from `/usr/bin/time -v` via `tp.sh` (one TypeProf at a time). The machine is
shared with other analyses, so wall times are only approximate.

There are 11 failing programs and **two root causes**:

| # | Symptom | Minimal repro | Corpus programs |
|---|---------|---------------|-----------------|
| A | `RuntimeError: unknown type variable: Return` | `[1].chunk_while { true }.each { }` | 2 |
| B | endless re-analysis plus a leak, ending in `[FATAL] failed to allocate memory` | `[[4, 1]].max_by { \|_, c\| c }` | 9 |

---

## A. `unknown type variable: Return`: the default type argument of `Enumerator` is ignored

Repro: `a1_enumerator_default_return.rb`

```ruby
[1].chunk_while { true }.each { }
```

Output (full text in `a1_enumerator_default_return.out`):

```
.../typeprof-0.31.1/lib/typeprof/core/ast/sig_type.rb:819:in 'TypeProf::Core::AST::SigTyVarNode#covariant_vertex0': unknown type variable: Return (RuntimeError)
	from .../core/ast/sig_type.rb:162:in 'TypeProf::Core::AST::SigTyNode#covariant_vertex'
	from .../core/graph/box.rb:242:in 'TypeProf::Core::MethodDeclBox#resolve_overload'
	from .../core/graph/box.rb:256:in 'block in TypeProf::Core::MethodDeclBox#resolve_overloads'
	from .../core/graph/box.rb:746:in 'block (2 levels) in TypeProf::Core::MethodCallBox#run0'
	...
	from .../core/service.rb:73:in 'TypeProf::Core::Service#update_rb_file'
```

TypeProf aborts, so it prints nothing for the rest of the file.

Variants (each run separately):
- `[1].slice_when { true }.each { }` and `[1].slice_before(1).each { }` crash the same way.
- `[1].chunk_while { true }.map { }` and `.to_a` do not crash.

**Explanation (verified by reading the source):**
- rbs declares `class Enumerator[unchecked out Elem, out Return = void]`. `Return` has a default.
- `chunk_while`, `slice_when`, `slice_before` and `slice_after` (core/enumerable.rbs:2236-2491) return `::Enumerator[::Array[Elem]]`, which gives only one type argument.
- `SigTyInstanceNode#covariant_vertex0` (sig_type.rb:642-648) builds `Type::Instance.new(genv, mod, args)` with only the type arguments that were written. It does not fill in defaults, so the instance has 1 argument for 2 type parameters.
- `MethodCallBox#run0` (box.rb:740-744) builds the substitution with `ty.mod.type_params.zip(ty.args)`, which maps `Return => nil`.
- `Enumerator#each: () { (Elem) -> untyped } -> Return` then reaches `SigTyVarNode#covariant_vertex0`, which raises because `subst[:Return]` is nil.
- `map` and `to_a` come from `Enumerable` and never mention `Return`, which is why they are safe.

Fix direction: fill in `type_param.default_type` (or `untyped`) for missing arguments when an instance type is built from RBS. A softer fallback is to treat an unbound type variable as untyped instead of raising.

Corpus programs (both call `.each` on the result of `chunk_while`):
- `corpus/05-sorting/triage_partition.rb`: `sorted.chunk_while { |a, b| a == b }.each { ... }`
- `corpus/18-collections/access_log.rb`: `bursts = errors.chunk_while do ... end; bursts.each do |run| ... end`

Seven corpus files use one of these four methods. The other five never call `.each` on the result, so they do not crash.

---

## B. Memory blow-up: a block with 2+ parameters returns a parameter directly to a `Comparable`-typed block return

Repros: `b1_destructuring_block_to_comparable.rb` and `b2_hash_sort_by.rb`

```ruby
[[4, 1]].max_by { |_, c| c }          # b1
{"a" => 1}.sort_by { |k, v| v }       # b2
```

### Numbers

Runs of b1 (one line of Ruby):

| limit | result | wall | max RSS |
|-------|--------|------|---------|
| 3 GB, 120 s / 600 s | `[FATAL] failed to allocate memory` | 1:59 | 2482 MB |
| 8 GB, 600 s | `[FATAL] failed to allocate memory` | 5:29 | 7308 MB |
| 3 GB, `timeout 30` | still running | 30 s | 844 MB |

So it never finishes; it grows until it hits any limit. A normal run on a program this size takes about 1.2 s and 113 MB. The 9 corpus programs reach 3 GB in 54-80 s (max RSS 2479-2482 MB).

### What does and does not trigger it

Each row is one run with `timeout 10`. Ruby output is identical for every variant.

| block | TypeProf |
|-------|----------|
| `[[4,1]].max_by { \|_, c\| c }` / `min_by` / `sort_by { \|a, _\| a }` | blows up |
| `{4=>1}.max_by { \|a, c\| c }`, `[["a",1]].max_by { \|_, c\| c }` | blows up |
| `[[4,1]].max_by { \|_, c\| x = c; x }` (local variable in between) | blows up |
| `[[4,1]].max_by { \|_, c\| -c }` / `c.to_s` / `[c]` | ok (1.3 s) |
| `[[4,1]].max_by { \|a, c\| 0 }` (return value does not depend on the parameters) | ok |
| `[[4,1]].max_by { \|a\| a[1] }` (one parameter, no auto-splat) | ok |
| `[[4,1]].max_by { \|(_, c)\| c }` (explicit destructuring) | ok |
| `[[4,1]].group_by { \|a, c\| c }` (block return type is the type variable `U`) | ok |
| `[[4,1]].sum { \|_, c\| c }`, `find { \|_, c\| c }` | ok |

Three conditions are needed together:
1. The block has 2 or more parameters and gets one argument, so it is auto-splatted (`SplatBox`).
2. The block's return value comes straight from one of those parameters, possibly through a local variable.
3. The RBS block return type is a nominal type that is typechecked. `max_by`, `min_by` and `sort_by` use `(Comparable | ::Array[untyped])`.

### Instrumented observation of b1

`instrument/probe.rb` and `instrument/trigger.rb` are loaded with `-r` and only observe; the gem is not modified.

```
PROBE t=2.0s MethodCallBox runs=3267   SplatBox created=6534  live=6534 (6530 destroyed) array-vertex fan-out=6534  rss=153MB
PROBE t=4.0s MethodCallBox runs=11287  SplatBox created=22574 live=22574                  fan-out=22574            rss=195MB
PROBE t=6.0s MethodCallBox runs=19121  SplatBox created=38242 live=38242                  fan-out=38242            rss=247MB
(the most re-run box is always MethodCallBox(max_by))

TRIG on_type_added   from block-arg vertex          types=["<Proc>"]
TRIG on_type_added   from block-return-vertex vertex types=["Integer"]
TRIG on_type_removed from block-return-vertex vertex types=["Integer"]
TRIG on_type_added   from block-return-vertex vertex types=["Integer"]
TRIG on_type_removed from block-return-vertex vertex types=["Integer"]
... (alternates forever)
```

### Mechanism

**Verified parts** (by the probes above and by reading the source):

1. **The call keeps re-running itself.** `MethodDeclBox#resolve_overload` (box.rb:213-227) calls `Block#accept_args`. Because the block has at least 2 formal parameters and gets 1 actual, `accept_args` (env/method.rb:96-102) calls `changes.add_splat_box(genv, single_arg, i)` and adds an edge from the new box's `ret` to each formal parameter.
   - `add_splat_box` (change_set.rb:80) looks only in `@new_boxes`. So every run of the `max_by` MethodCallBox creates fresh SplatBoxes with fresh `ret` vertices, and `reinstall` destroys the previous ones.
   - Next, the block return is typechecked against `Comparable | Array[untyped]`. `typecheck_for_module` (sig_type.rb, `self.typecheck_for_module`) runs `changes.add_edge(genv, a_vtx, changes.target)`, which makes the block-return vertex an input of the `max_by` box.
   - `reinstall` then removes the old SplatBox's edges, so `Integer` leaves `c` and the block return: `on_type_removed`, and the box is queued again.
   - The new SplatBox runs and adds `Integer` back: `on_type_added`, and the box is queued again. This repeats forever. `trigger.rb` shows exactly this alternation, always coming from the block-return vertex.
2. **Destroyed SplatBoxes are never freed.**
   - `SplatBox#initialize` (box.rb:338) subscribes directly with `@ary.add_edge(genv, self)`, and `Box#destroy` never undoes it. The probe shows the element vertex's fan-out equals the total number of SplatBoxes ever created.
   - Every type change on that vertex therefore walks a list that keeps growing, which explains why memory grows steadily and the runs slow down.
   - After `GC.start`, `ObjectSpace` still counts all of them as live.

**Partly verified / open:**
- Adding a `SplatBox#destroy` that also calls `@ary.remove_edge` (`instrument/patch_splat_destroy.rb`, loaded with `-r` only) brings the fan-out back to 2-4.
- With that change, the re-run cycle continues at the same rate, and the SplatBoxes still count as live and memory still grows (246 MB at 6 s, against 247 MB without it).
- So something else also keeps destroyed boxes alive. I have not identified it.
- Fixing the leak alone would turn the out-of-memory failure into a timeout. The cycle (point 1) is the root cause.

**Hypothesis (not verified):** a method call between the parameter and the block return (`-c`, `c.to_s`) hides the problem. The call's return vertex is fed from the RBS return type, so it does not empty out when `c` briefly loses `Integer`. Then the block return never changes and the `max_by` box is not woken up again.

Fix directions:
- reuse the SplatBox when `[:splat, arg, idx]` was already in `@boxes` of the previous run,
- or remove the `@ary -> box` edge on destroy,
- or do not make the call box depend on the block return when only the typecheck reads it.

### Corpus programs: all 9 out-of-memory cases have this pattern

The trigger lines in each program:

| program | trigger lines |
|---------|---------------|
| `05-sorting/staff_multikey_sort.rb` | `payroll.max_by { \|_, v\| v }` |
| `11-simulation/cpu_scheduler.rb` | `results.sort_by { \|_name, w\| w }` |
| `04-numeric/descriptive_stats.rb` | `counts.max_by { \|k, v\| v }`, `cv.sort_by { \|name, c\| c }` |
| `20-business/payroll.rb` | `ytd.max_by { \|_n, g\| g }` (and `sort_by { \|_n, g\| -g }`) |
| `18-collections/room_bookings.rb` | `hours.max_by { \|h, n\| n }` |
| `14-errors/password_policy.rb` | `reasons.sort_by { \|k, _\| k }` |
| `17-encodings/xor_breaker.rb` | `scores.sort_by { \|_, s\| s }` |
| `14-errors/nested_schema.rb` | `totals.sort_by { \|w, _\| w }` |
| `03-numtheory/goldbach.rb` | `block.min_by { \|_, c\| c }`, `block.max_by { \|_, c\| c }` |

**Confirmation:**
- `rewrite/rewrite.rb` rewrites only these blocks, from `{ |a, b| body }` to `{ |e__| a, b = e__; body }`. The Ruby output stays byte-identical.
- After that change, all 9 programs finish normally in 1.5-2.2 s with 116-119 MB (`rewrite/results.txt`).
- Before it, all 9 died with OOM at about 2.48 GB after 54-80 s.

So no second cause is hiding in these programs. Separately, the automatic reducer (`reduce/reduce.rb`, Prism statement deletion) shrank goldbach to `reduce/goldbach.min.rb`, and that file still contains `block.max_by { |_, c| c }`.

**Note for the timeout analysis:**
- 137 corpus files use a `sort_by`/`min_by`/`max_by` block with 2+ parameters: 95 ok, 9 OOM, 32 timeout, 1 crash (case A).
- Many of those 32 timeouts could be the same cycle growing more slowly. I did not check them.

---

## Files

- `a1_enumerator_default_return.rb`, `.out`: repro and full backtrace for A.
- `b1_destructuring_block_to_comparable.rb`, `b2_hash_sort_by.rb`: repros for B.
- `tp.sh`: runs one TypeProf under `ulimit -v` and `timeout`, and reports exit code, wall time and max RSS. It serializes on `.tp.lock`.
- `instrument/`:
  - `probe.rb`: counts box runs, SplatBox creations, live and destroyed boxes, and fan-out.
  - `trigger.rb`: records what wakes the `max_by` box.
  - `patch_splat_destroy.rb`: the experimental unsubscribe, loaded with `-r`; the installed gem is unchanged.
- `rewrite/`: semantics-preserving rewrites of the 9 OOM programs, plus `results.txt`.
- `reduce/`: the statement-level reducer and its logs. The first attempt used an RSS threshold inside a 10 s window, which was too noisy on the shared machine (`run_all.1.log`). The second attempt used only "still running at 10 s".
- `try/`: the one-line variants used for the trigger table.
