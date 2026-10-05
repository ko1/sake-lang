# Notes for 04-numeric (revision round)

The main win was unary minus: almost every `0.0 - x` / `0 - x` / `** (0 - k)` workaround is gone.
`(A|B).f(x)` removed the forwarding functions in curve_fitting, and Array destructuring removed the index reads.

Still worked around with today's Sake:

- **Swapping elements:** `m[c], m[p] = m[p], m[c]` is rejected ("only `a, b = tuple` (local variables, no splat) is supported").
  Each swap still takes three statements with a temporary (gaussian_elimination, lu_decomposition, eigenvalues). This is
  the most common remaining workaround in numeric code.
- **Two-index `[]`:** `m[i, j]` is rejected ("takes one index"). matrix_ops still indexes with a Tuple, `m[[i, j]]`.
- **`Range.sum` with a block** is rejected ("Range.sum does not take a block"), so `(0...n).sum { ... }` is still
  `Range.reduce(0...n, 0.0) { ... }`.
- **Destructuring parameters** (`def dist((px, py), (qx, qy))`, `|(px, py), i|`) are still rejected. bezier_curves keeps
  `px, py = p` at the top of each function.
- **Blocks are not values:** recursive or dispatching integrators (numeric_integration, ode_solver) still rewrap the block
  with `{ |x| yield(x) }` at each level or in each `case` branch.
- No `loop do`, no `Array.new(n, v)`, no `Array.fetch(a, i, default)`, no Enumerator chains (`each_cons(w).map`). These are
  unchanged from the first round.

Possible problem in a message (not an interpreter bug):

- `Array.each_with_index(Array[[1, 2]]) { |(a, b), i| ... }` is rejected with the hint "`|a, b|` already destructures a
  Tuple". For `each_with_index` that hint is wrong: `|a, b|` gets the element and the index, so the element cannot be
  taken apart in the block parameters at all.
