# Notes (03-numtheory)

## sieve_primes
- `Array.sort_by` with a Tuple key (`[0 - size, from]`, Ruby's usual multi-key sort) fails:
  `ArgumentError: Array.sort_by: cannot compare elements of types {from: Integer, size: Integer, to: Integer}`.
  Tuples have no ordering. The message names the *element* type (a Record) rather than the key type
  (Tuple), which is misleading. Minimal: `p(Array.sort_by(Array[[2, 1], [1, 5]]) { |t| t })`.
  Workaround: fold the keys into one Integer (`(0 - size) * 1_000_000 + from`).
- No `Array.new(n, v)`: the flag array is filled with `Integer.times` + `Array.push`.
- No unary minus: `0 - size`.

## factor_functions
- Ruby's nested block parameter `|acc, (p, e)|` in `Hash#reduce` has no Sake form (destructuring
  parameters are rejected); the Sake version takes `|acc, pe|` and reads `pe[0]`, `pe[1]`.
- Ruby's `sort_by { [-c, p] }` again folded into one Integer key (see sieve_primes).

## check_digits
- `s[0, 9]` (start, length) is rejected: "`String.delete(s, "-")[0, 9]` takes one index". Used `s[0...9]`.
- Swapping two Array elements with `cs[i], cs[i + 1] = cs[i + 1], cs[i]` is rejected:
  "only `a, b = tuple` (local variables, no splat) is supported". Used a temporary.
- String has no `[]=`: Ruby's `typo = base.dup; typo[i] = d.to_s` became `String.chars` + Array write + `Array.join`.

## farey_stern_brocot
- No built-in constants: Ruby's `Math::PI` is written as the literal `3.141592653589793` in Sake.
- Ruby's `loop do ... break ... end` became `while true ... break ... end` (no `break` in blocks).

## integer_partitions
- `==` on Arrays is not defined yet, so Ruby's `pn == pent` / `distinct == odd` became
  `Range.all?(0..limit) { |i| pn[i] == pent[i] }`.
- No `Array + Array` and no `[n, m].min` on a Tuple: `prefix + [part]` became
  `Array.push(Array.dup(prefix), part)`, and the min a ternary.
- Recursive generator: Ruby passes `&block` down; Sake re-yields through a block
  (`each_partition(...) { |p| yield(p) }`).

## quadratic_residues
- Array equality again (`squares == qr`): compared `Array.join(..., " ")` strings instead.

## pollard_rho
- Ruby's `(s - 1).times.any? { ... }` (an Enumerator without a block) has no Sake form; written as a
  `while` loop with a `found` flag inside the `Array.all?` block.
- `[2] + factorize(n / 2)` (Array concatenation by `+`) became `Array.unshift(rest, 2)`;
  `(half + half)` became `Array.concat(Array.dup(half), half)`.

## linear_sieve
- The linear sieve's inner loop needs `break` out of `primes.each` (Ruby). Sake has no `break` in
  blocks; first version used `next if ...`, which keeps the algorithm correct but scans every prime
  for each i: 88 s for N=3000. Rewritten as `while j < Array.size(primes)` with `break`. N reduced
  to 1500 to stay within the time budget.
- `Array.new(n + 1, 0)` written as `Range.each(0..n) { Array.push(...) }` (no `Array.new`).

## happy_cycles
- Ruby counts cycles with `Hash.new(0)` keyed by the cycle Array. In Sake an Array cannot be a Hash
  key ("TypeError: Hash.[]=: Array cannot be a Hash key or Set element"), and the cycle has variable
  length so a Tuple does not fit; keyed by `Array.join(cycle, ",")` and split back for printing.
- Ruby's `sort_by { [-c, members.first] }` folded into an Integer key (`String.to_i(key)` reads the
  first member of the joined key).

## fibonacci_numbers
- Ruby's `idx.each_cons(2).all? { |x, y| ... }` (Enumerator chaining) has no Sake form; the Sake
  version sets a flag inside `Array.each_cons(idx, 2) { |w| ... }` (the block gets an Array, so
  `w[0]`, `w[1]` rather than `|x, y|`).
- Workload cut (Zeckendorf check 1..500 -> 1..150, gcd identity 40x40 -> 25x25) to keep the Sake run
  under ~2 s.

## General
- Recurring Sake workarounds: no unary minus (`0 - x`), no `Array.new(n, v)`, no `break` in blocks
  (`while` loops instead), Tuple keys not sortable, Arrays not comparable with `==` and not usable as
  Hash keys.
- No interpreter bugs found beyond the misleading `sort_by` message (sieve_primes).
- Several workloads were shrunk to keep the Sake run under ~3.5 s user time (collatz 3000 -> 1200,
  miller_rabin 12000 -> 5000, goldbach 2000 -> 1000, happy_cycles bounds, pollard_rho's 1e18
  semiprime replaced by a 1e12 one). The test machine was heavily loaded (load average 25-37 on
  16 cores), so wall-clock times varied ~2x.
- Sake sizes ended up 72-131 lines; there is no very short (~40) or very long (~250) program.
