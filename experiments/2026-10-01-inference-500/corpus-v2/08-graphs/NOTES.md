# 08-graphs notes (corpus-v2)

Remaining workarounds with today's Sake:

- **Multiple assignment from a split of varying length.** Ruby's `a, b = s.split(x)` gives `nil` for
  a missing part; Sake requires the lengths to match (`ArgumentError`). Where a part may be absent
  the code still indexes: course_schedule (`" 4 |".split("|")` drops the trailing empty field, so
  1 element), org_chart_lca (`"founder"` has no `<` boss).
- **No value patterns inside Record patterns** (rival_teams): `case r in {ok: true, side:} ... in {ok: false, cycle:}`
  is still rejected (`only Record patterns that bind fields are supported`); kept `r => {ok:, side:, cycle:}` and `if ok`.
- **No Array `+`** (currency_paths, rival_teams): `path + [nb]` stays `Array.push(Array.dup(path), nb)`,
  `left + [common] + right.reverse` stays `Array.concat(Array.push(...), ...)`.
  `Array[1] + Array[2]` -> `TypeError: Arithmetic.+: no implementation for (Array, Array)`.
- **No nested destructuring in block parameters** (dot_stats, pipeline_flow): Ruby's
  `pairs.count { |(a, b), c| ... }` over a Hash keyed by Tuples needs `|k, c| a, b = k`.
- **No built-in constants** (prim_cables): `def pi = 3.141592653589793` for `Math::PI`.
- **No `Hash.new { }`** (several): `h[k] ||= Array[]` instead of a block default.

The interpreter bugs from the first round (`Array.join` without a separator crashing; Tuple `==`;
Tuple sort keys) are fixed. No new interpreter bug found.
