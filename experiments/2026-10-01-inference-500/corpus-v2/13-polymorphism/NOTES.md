# Notes (v2): 13-polymorphism

Difficulties that remain with today's Sake (all programs run with `--strict=0`).

## Still worked around
- **Mixin dispatch needs a stub in the module.** `Shape.area(s)` is a static error unless `Shape`
  itself defines `area` (`undefined function Shape.area`, hint: defined in `Circle.area`, ...). So
  shapes_area, expr_tree, notify_channels, payroll and stack_vm keep `def f(x) = raise("...")`
  "abstract" stubs. `(Circle|Rect|...).area(s)` would work but has to repeat the whole type list at
  every call, which is worse than the stub for an open family of shapes.
- **One index only.** `m[r, c]` is still rejected ("takes one index"); matrix_ops and life_grid keep
  `m[[r, c]]` with `r, c = rc` inside `[]`/`[]=`.
- **Swap of elements.** `a[i], a[j] = a[j], a[i]` is still rejected ("only `a, b = tuple` (local
  variables, ...)"); matrix_ops and task_heap swap through a temporary. (Parallel assignment of
  locals works and is now used in modint_combinatorics.)
- **No `break` in blocks.** payroll leaves the bracket loop with `return` from the enclosing
  function instead; version_constraints uses `next if y == nil` on the rest of the zipped pairs.
- **Destructuring needs the exact length.** `name, pow = String.split("m", "^")` raises
  `ArgumentError: multiple assignment of 2 variables from Array of size 1`, where Ruby gives
  `pow = nil`. physical_quantities (`tok.split("^")`) and stack_vm (`op, arg = l.split(" ")`, `arg`
  optional) keep indexing.
- **Comparable does not give `==`.** temperature_units still defines
  `def ==(a, b) = (b in Temp) && (a <=> b) == 0` so that 20°C == 68°F, as in Ruby.
- Missing built-ins, unchanged: `Array.new(n, x)` (`Range.map(0...n) { x }`), `Hash#dup`
  (`Hash.merge(Hash[], h)`), `Math.acos`, `Math::PI`, `NotImplementedError`, `String.chomp(s, x)`.

## Fixed since v1
- `Array.uniq` now deduplicates equal Struct values (vector_polygon's `dedup` helper is gone).
- Tuples compare with `==` and `<=>` (physical_quantities, sparse_vector, task_heap,
  version_constraints, vector_polygon).
- `Array.combination(xs, 2)` pairs destructure in `{ |a, b| }`.

No interpreter bugs found in this round.
