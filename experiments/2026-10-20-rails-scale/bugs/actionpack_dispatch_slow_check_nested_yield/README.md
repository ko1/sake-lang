# Slow check: a yielding function that reaches itself again with `{ yield }` (ActionDispatch's Mapper)

`bin/sake -c --strict` of the Rails-shaped Mapper takes 30x longer than the restructured one, for the same
routes and the same output. Running either takes about a second. Machine shared, load average about 2.3 (2026-10-20, UTC).

```
slow/actionpack/   a copy of sakelib/rails/actionpack with the Mapper as first written (block-taking scope helpers)
fast/actionpack/   the same copy with the Mapper as it is in sakelib (enter/leave functions, see the diff)
{slow,fast}/routes30.sake  31 routes (root, resources with nested resources/member/collection, resource, namespace,
                           get, a glob, an optional scope); prints 31 in both
{slow,fast}/routes1.sake   one `resources :posts`
slow_vs_fast.diff          diff -u fast slow of routing/mapper.sake
variants/mk.py             builds the slow tree with chosen functions swapped for the fast form's
shrink/                    the synthetic generators and the smallest file found
```

## The two forms

| `/usr/bin/time -f "%es %MKB" bin/sake -c --strict ...` | slow | fast |
|---|---|---|
| routes1.sake (one `resources`) | 10.80 s, 143 MB | 2.47 s, 92 MB |
| routes30.sake (31 routes) | **81.87 s, 732 MB** (82.25 s on a rerun) | **2.70 s, 104 MB** |

(While I was first writing it, the Mapper took 2 min 5 s on the same 31 routes. That version also differed in
smaller ways that I did not keep.)

The slow form, as in Rails:
- the helpers `with_scope_level`, `path_scope`, `shallow_scope`, `resource_scope`, `scope_with`, `collection`,
  `member`, `new_` and `nested` yield inside `begin/ensure`;
- `resources_` calls `apply_common_behavior_for(...) { yield }`, which has four branches like
  `nested(m) { public_send_resource(m, ...) { yield } }`;
- `public_send_resource` has four call sites `resources_(m, ...) { yield }` / `resource_(...)`;
- `decomposed_match` recurses through `nested(m) { decomposed_match(...) }`.

The fast form has `_enter_*` functions that push a frame and return the old scope (the caller restores it in an
`ensure`). Only the public DSL functions yield, and `_resources` enters the shallow/nested/scope frames one after
the other instead of calling `resources` again.

## Which part is slow (routes30, swapping one part of the slow form for the fast one: variants/mk.py)

| variant | check |
|---|---|
| slow | 82 s |
| decomposed_match fast (no recursion through `nested { }`) | 75 s |
| set_member_mappings fast (`member(m) do ... end` → enter/leave) | 77 s |
| resources_ body flattened (enter/leave), recursion through apply_common_behavior_for kept | 56 s |
| apply_common_behavior_for never calls back into resource(s) (recursion removed, everything else slow) | **2.4 s** |
| resource/resources fast (no recursion) | 3.0 s |
| decomposed_match + resources fast | 2.6 s |

So the cost is the recursion: `resources_` → `apply_common_behavior_for { yield }` → `public_send_resource { yield }`
→ `resources_ { yield }`, with several call sites at each step. The yielding wrappers around it add to the cost
(56 s once flattened), but they are not the cause.

## Shrinking (shrink/)

`gen4.rb S D` writes a `resources(m, kind)` that yields to its block. It also reaches itself again through a
chain of D functions, each passing `{ yield }` on, and the first step has S call sites:

| S call sites | D=1 (resources calls itself) | D=2 (resources → hop1 → resources) | D=3 |
|---:|---:|---:|---:|
| 16 | 0.67 s | 0.71 s | 0.76 s |
| 32 | 1.65 s | 1.76 s | 2.17 s |
| 64 | 9.14 s, 105 MB | 10.45 s | 13.46 s, 174 MB |

- **Control (`shrink/minimal_control.sake`):** the same 64 sites calling a non-recursive yielding `other(m) { yield }` check in **0.98 s**.
- **Nesting:** how deep the routes nest (U in gen2.rb, 1–3) makes no difference.
- **Wrappers:** a yielding wrapper around the recursive call (WRAP in gen3.rb) adds a little: 20.2 s against 17.7 s at B=8, K=8.
- **Recursion:** removing the recursion takes the same gen3 file from 20.2 s to 0.84 s.
- **B×K** (gen2.rb: B branches times K sites): 16 → 1.1 s, 36 → 4.7 s, 64 → 19.2 s.

**Smallest shape** (`shrink/minimal.sake`, 64 sites: 8.2–9.1 s against 0.98 s without the recursion). A yielding
function calls itself, at several call sites, with a block that only yields to its own block:

```ruby
def resources(m, kind)
  return resources(m, 0) { yield } if kind == 1
  return resources(m, 0) { yield } if kind == 2
  # ... 64 such lines
  yield
  ...
end
```

The check time grows roughly as S^2.5 with the number of such recursive `{ yield }` call sites (16 → 32 → 64:
0.67 → 1.65 → 9.1 s). A longer recursion chain multiplies it a little more. This is a measurement of the
checker; I have not looked into lib/ for the mechanism.

## Fixed in the checker (2026-10-20, the lead)

`Typer#call_user` ran the body of a function that yields once per call, with the block, and let a yielding
function recurse three levels deep: S call sites of `resources(m, 0) { yield }` inside `resources` ran the body
about 2·S² times per pass, each body S lines long (the S^2.5 above). It also left calls without a block out of any
sharing, and `resources :posts` has none: one `resources` ran `resources_` 916 times.

Now (`yield_memo_key`, `call_yielding_memo` in lib/sake/typer.rb) a block whose body only passes its arguments on
(`{ yield }`, `{ |a| yield(a) }`) stands for the block it passes to, and calls of one yielding function with the same
argument types and the same (resolved) block, or no block, in one instantiation run the body once per pass; a call
that recurses with the same key reads the result so far, and the body runs again until that result stops growing
(at most 4 rounds). Same output for all four programs. Local machine, one run each (`bin/sake --strict`, which also
runs them):

| | before | after |
|---|---|---|
| slow/routes1.sake | 8.39 s, 152 MB | 2.69 s, 107 MB |
| slow/routes30.sake | 91.71 s, 878 MB | 3.68 s, 130 MB |
| fast/routes1.sake | 2.18 s, 101 MB | 2.41 s, 104 MB |
| fast/routes30.sake | 2.53 s, 117 MB | 2.69 s, 116 MB |
| shrink/minimal.sake with S = 32 (`-c --strict`) | 2.92 s, 2,244 bodies | 0.21 s, 12 bodies |
