# Notes (03-numtheory, corpus-v2)

Still worked around in today's Sake:

- **Swapping Array elements** (check_digits): `cs[i], cs[i + 1] = cs[i + 1], cs[i]` is rejected
  ("only `a, b = tuple` (local variables, no splat) is supported"); a temporary is used.
- **`s[start, len]`** (check_digits) takes one index only; written `s[0...9]`. **String `[]=`** does not
  exist, so a one-character change goes through `String.chars` + Array write + `Array.join`.
- **No `Array + Array`** (integer_partitions, egyptian_fractions, pollard_rho): `Array.push(Array.dup(a), x)`,
  `Array.concat(Array.dup(a), b)`, `Array.unshift(rest, 2)`.
- **No `Array.new(n, v)`** (sieve_primes, linear_sieve, integer_partitions, perfect_amicable): filled
  with `Integer.times` + `Array.push`.
- **No `break` in blocks / no `loop`** (linear_sieve, farey_stern_brocot, integer_partitions): `while`
  loops with `break` instead of `each` / `loop do`.
- **No `min`/`max` on a Tuple**: Ruby's `[n, m].min` is a ternary (integer_partitions,
  quadratic_residues) or `Array.minmax(Array[b, c])`.
- **Nested block parameters** `|acc, (p, e)|` are rejected (factor_functions); the pair is taken
  apart in the body with `p, e = pe`. Works, but one extra statement per block.
- **An Array cannot be a Hash key** (happy_cycles): variable-length cycles are keyed by
  `Array.join(cycle, ",")` and split back. A Tuple does not fit because the length varies.
- **No Enumerator chains** (fibonacci_numbers): `idx.each_cons(2).all? { |x, y| }` is a flag set
  inside `Array.each_cons`.
- **No constants**: `Math::PI` is the literal `3.141592653589793`.

Possible interpreter issue (hint text only):

- `Array.new(3, 0)` reports `hint: did you mean \`Array.new[]\`?` — that suggestion is not valid
  Sake; `Array[]` is probably meant. Repro: `p(Array.new(3, 0))`.
