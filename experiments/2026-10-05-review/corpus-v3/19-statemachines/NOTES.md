# Notes: 19-statemachines (corpus-v2)

13 of 25 programs changed. Fixed since the first round: Tuple keys in `sort_by`/`min_by`, multiple
assignment from an Array, `!x`/`-x`, and `S.call(x)` on a user function named `call` (now runs).

Still worked around:

- **Array patterns** (turnstile): `case [@state, event] in [:locked, :coin]` is still rejected
  ("unsupported pattern"), so the dispatch on (state, event) stays a `case` on the state with `if`s inside.
- **Nested block destructuring** (tcp_states): `Hash.each(h) { |(from, ev), (to, reply)| }` is still
  rejected; destructure the key/value Tuples inside the block.
- **Index targets in multiple assignment** (bank_queue_sim): `a[i], a[j] = a[j], a[i]` is still
  "only `a, b = tuple` (local variables, no splat) is supported"; swap through `tmp`.
- **No `Array + Array` / `Array + Tuple`** (regex_nfa, csv_parser, job_pipeline): `Array.concat`,
  `Array.push(Array.dup(path), name)`.
- **Max/min of two values** (csv_parser, enemy_ai): `[a, b].max` has no counterpart (a Tuple has no
  `max`, and there is no `Integer.max`); `Array.min(Array[a, b])` or an `if`.
- **`Integer.to_s(n, base)`** (divisibility_dfa) still takes one argument; hand-written `to_base`.
- **No value constants** (tcp_states, machine_mixin, morse_decoder, traffic_light): tables are
  functions that rebuild a Hash on each call.
- **`break` in blocks** (bank_queue_sim, job_pipeline): `loop do ... break` stays `while true`.

Possible inconsistency: `Array.sort(Array[:b, :a])` sorts Symbols, while `:a < :b` is a `type` error
(and a TypeError at run time: "Comparable.<: no implementation for (Symbol, Symbol)"). The programs
keep `sort_by { Symbol.to_s(it) }`, as the Ruby versions do.
