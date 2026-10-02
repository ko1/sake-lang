# Notes (12-parsers, v2)

What still had to be worked around with today's Sake:

- **`==` across types is a TypeError at the top level, but `false` inside collections.** `1 == :a` raises
  ("Kernel.==: no implementation for (Integer, Symbol)"), while `Array[1, 2] == Array[1, :a]` and
  `[1, 2] == [1, :a]` give `false`. Programs that compare dynamically typed values (lisp_interp's
  `head == :quote`, pratt_parser's `==` on Integer/bool/list values, query_engine's column vs literal)
  still guard with `in` patterns or explicit type checks. `==` is also asymmetric between a Struct and a
  String: `A.new(1) == "*"` is `false`, `"*" == A.new(1)` raises (query_engine relies on the order).
- **No array patterns.** type_checker dispatches on `e[0]` and then destructures each branch with
  `_, op, lhs, rhs = e`; Ruby does both at once with `in [:bin, op, lhs, rhs]`. Multiple assignment made
  this much closer than before, but the tag is still read by index.
- **No splat in multiple assignment.** `first, *rest = String.split(name, ".")` is rejected
  ("only `a, b = tuple` ... no splat"); template_engine keeps `parts[0]` and `Array.drop(parts, 1)`.
- **Missing optional arguments of String operations:** `String.index(s, t, from)` (markdown's
  `find_from`, template_engine's `src[pos..]` + offset), `String.split(s, sep, limit)` (assembler now
  uses `String.partition`, which is fine), `String.chomp(s, suffix)` (forth uses `delete_suffix`).
- **No first-class functions / `send`.** Operator tables (rpn_calc, shunting_yard, query_engine,
  type_checker, lisp_interp primitives) remain `case`/if chains over the operator name.
- **No value constants / `Array.new(n, v)`** — unchanged from v1 (functions returning the table;
  `Integer.times` to fill the tape).

No interpreter bugs found in this round. The v1 `Array.join` crash without a separator is fixed, and
`v = h[k] += x` now works as an expression.
