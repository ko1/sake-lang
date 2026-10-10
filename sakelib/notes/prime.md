# prime

`sakelib/prime.sake` ports Ruby's `prime` gem (0.1.4). It has 11 operations in the `Prime` module and 4
added to `Integer`. Test: `test/sakelib/prime.sake` and `.rb`, whose outputs match at `--strict`. The test
also passes at `--strict=3`.

`Prime` is a `module` with `module_function`. Ruby's `Prime` is a singleton instance whose state is only a
cache, so module functions are enough. `Integer#prime?` and its relatives become operations added to the
built-in type, as in `class Integer; def prime?(n) ...`. `Integer.prime?` uses Ruby's algorithm: trial
division by the wheel of 30, then deterministic Miller-Rabin with Ruby's base table for n ≥ 0xffff.
`Prime.prime_division` uses Ruby's Generator23 sequence (2, 3, then steps of 2 and 4).

## API

| Ruby | Sake | |
|---|---|---|
| `Prime.each(30) { \|p\| }` | `Prime.each(30) { \|p\| }` | same (returns the last block value, as in Ruby) |
| `Prime.each { \|p\| ... break ... }` | `Prime.each { \|p\| ... break ... }` | same (phase 2; the bound was required) |
| `Prime.each(30)` without a block (an Enumerator), `.to_a` | `Prime.each(30)` (an Array), or `Prime.to_a(30)` | differs: an Array, not an Enumerator; `Prime.each` without a block and without a bound raises ArgumentError |
| `Prime.each(n).each_with_index { \|p, i\| }` | `Prime.each_with_index(n) { \|p, i\| }` | differs (same reason) |
| `Prime.each_with_index { \|p, i\| ... break ... }` | same | same (phase 2) |
| `Prime.first(n)`, `Prime.take(n)` | same | same |
| `Prime.take_while { }`, `Prime.find { }` | same | same |
| `Prime.prime?(n)`, `Prime.include?(n)` | same | same (a non-Integer raises `ArgumentError`, as Ruby, since 2026-10-05) |
| `n.prime?` | `Integer.prime?(n)` | same |
| `Prime.prime_division(n)`, `n.prime_division` | `Prime.prime_division(n)`, `Integer.prime_division(n)` | same: `[[p, e], ...]`, an Array of Tuples, which prints as Ruby's; negative n gives `[-1, 1]` first, and 0 raises ZeroDivisionError |
| `Prime.int_from_prime_division(pd)`, `Integer.from_prime_division(pd)` | same | same |
| `Integer.each_prime(ub) { }`, without a block | same; without a block an Array | same / differs (Array, not an Enumerator) |
| `Prime.prime?(n, generator)`, `prime_division(n, generator)` | | missing: no generator objects |
| `Prime::EratosthenesGenerator`, `TrialDivisionGenerator`, `Generator23`, `PseudoPrimeGenerator` (`succ`, `next`, `rewind`, `upper_bound=`) | | missing (see below) |
| `Prime.lazy`, and other Enumerable methods on `Prime` (`select`, `each_slice`, ...) | | missing: no Enumerators or lazy sequences; `each(nil)` with `break` covers most uses |
| `Prime.instance` | | missing (no singleton objects) |

## What could not be ported, and why

- **Generators as objects.** Ruby's generators are stateful iterators (`succ`, `rewind`). They could be
  Struct types with a `succ` operation passed as the (now possible) optional argument, but the only
  point of passing one, which is to choose the algorithm, does not survive without dispatch on a
  generator protocol. Not ported.
- **The shared sieve cache** (phase 2). As Ruby's `Prime::EratosthenesSieve.instance` (the same nested name since 2026-10-10; `EratosthenesSieve` before), the primes found so far
  are kept for the whole program: `Prime.primes = once { Integer[] }` and the bound sieved to,
  `Prime.sieved_to = once { Integer[0] }` (a one-element Array, since `once` keeps a value, not a
  variable). `Prime.extend_primes` sieves again up to twice the bound (128 first) and appends the new
  primes, so the list only grows and `each` can walk it by index while it grows. Ruby's sieve
  extends by segments; this one sieves from 2 again, which costs at most as much as all the sieves
  before it. Also visible (Ruby keeps them private): `Prime.sieve`. Since 2026-10-05 the cache is
  `Prime::EratosthenesSieve.instance` (see below).
- **Enumerators.** `Prime.each(30).to_a`, `Prime.lazy.select { }.first(5)`, and `Prime.each_with_index`
  need first-class iterators, which Sake does not have (blocks are not values). The common cases have
  their own operations (`to_a`, `each_with_index`, `take_while`, `find`).

## Built-ins Sake lacks (requests)

- None were needed. `Integer.pow(a, b, mod)`, `Integer.sqrt`, `Integer.divmod`, and `Integer.gcd` are all
  there.

## Friction

- `test/sakelib/prime.sake` with `require "prime"` gave `undefined type or module Prime` for every line.
  The test file had required itself. I used `require "../../sakelib/prime"` until the coordinator's
  loader fix, and the test is back to `require "prime"`.
- `raise ZeroDivisionError, "divided by 0"` gave a different message from Ruby (`ZeroDivisionError`).
  Ruby's prime.rb uses a bare `raise ZeroDivisionError`, whose message is the class name, and Sake's bare
  `raise T` gives the type's name too, so I wrote `raise ZeroDivisionError`.
- In Ruby, Miller-Rabin's inner loop is `return false if r.times do ... break if x == n1 end`, which uses
  the value of `times` (r, which is truthy) against `break` (nil). I rewrote it with an explicit
  `composite` flag. It is clearer, but it shows that Ruby's value-of-break idioms do not carry over
  literally.
- `Prime.each(10).to_a` (Ruby habit) gives `Prime.each uses yield but no block is given`, and
  `method call on a value`. One of the hints is `Prime.to_a(Prime.each(10))`, which is wrong: it is
  found by name, but `Prime.to_a` takes a bound. The right form is `Prime.to_a(10)`.
- `97.prime?` gives the hint `Integer.prime?(97)`, which already finds the library's addition to Integer.
  This works well.
- `--strict=4` reports the `raise ZeroDivisionError` in `prime_division` as `unrescued`, because some
  call sites do not rescue it. That is expected for a library.

## Phase 2

- `Prime.each(ubound = nil)` and `Prime.each_with_index(ubound = nil)`: Ruby's unbounded form
  `Prime.each { ... break ... }` works; internal callers no longer pass `nil`.
- The sieve cache above, with `once`. `Prime.first(n)` takes from the cache directly, and
  `Prime.to_a(ubound)` walks it.
- No string scans in this library, so no position built-ins apply.

Speed (`experiments/2026-10-03-sakelib-port/phase2/bench_prime.sake 50`: 50 calls of
`Prime.first(1000)` and the sum of `Prime.each(100000)`; run by `run_digest_zlib_prime_matrix.sh`;
CPU s user+sys of one `bin/sake --strict` process, 3 runs; local 16-core machine shared with other
sessions, load average 33-38 throughout; "before" is commit af197cd):

| CPU s, 3 runs | before (af197cd) | after |
|---|---|---|
| 0 (start-up, checking) | 0.65 0.65 0.67 | 0.65 0.68 0.67 |
| 50 x `first(1000)` + `each(100000)` | 61.37 61.75 60.54 | 16.77 16.39 16.48 |

3.7x faster: before, each `first(1000)` sieved 7 times (up to 8192) and `each(100000)` sieved 11
times; now the sieve runs once per doubling for the whole program.

Raw: `experiments/2026-10-03-sakelib-port/phase2/results_digest_zlib_prime_matrix.txt`.

## IO and optional blocks

`Prime.each(ub)` and `Integer.each_prime(ub)` check `block_given?`: with a block they are as
before; without one they give the Array of primes <= ub, which is what Ruby's Enumerator gives with
`.to_a`. `Integer.each_prime` passes its block on with `&b` (written as
`block_given? ? Prime.each(ub, &b) : Prime.each(ub)`, because `&b` alone makes the block required:
[logger_bug_pass_on_optional_block.sake](logger_bug_pass_on_optional_block.sake)).

Bug found: a `yield` inside a `while` loop is reported as "no block is given" even after
`return ... unless block_given?`; the same guard without the loop passes
([prime_bug_yield_in_loop_after_guard.sake](prime_bug_yield_in_loop_after_guard.sake)).
`Prime.each` puts the loop in the `if block_given?` branch instead.

## Phase 4 (2026-10-05 review)

- `Prime.prime?(n)` asserts `n => Integer`, where Ruby raises `ArgumentError` ("Expected an integer");
  a Float argument is now a `type` report before running (`NoMatchingPatternError` while running,
  which cannot be rescued, unlike Ruby's `ArgumentError`).
- Both bugs above are fixed: `Prime.each` has Ruby's shape again (`return Prime.to_a(ub) unless
  block_given?`, then the loop), and `Integer.each_prime(ub, &b) = Prime.each(ub, &b)`.

## 2026-10-05

- The cache is now a type, as Ruby's: `Prime::EratosthenesSieve` with `private attr_reader primes =
  Integer[], max_checked = 0`, `Prime::EratosthenesSieve.instance = once { Prime::EratosthenesSieve.new }`, and
  `get_nth_prime(sieve, i)` / `compute_primes(sieve)` (Ruby's names). It replaces
  `once { Integer[] }` plus a one-element Array standing for the bound (`Prime.primes`,
  `sieved_to`, `extend_primes` are gone).
- `Prime.prime?(1.5)` raises `ArgumentError` "Expected an integer, got 1.5", as Ruby (was
  `n => Integer`); the test rescues it in both languages.
- `while true` loops in `each` and `prime_division` are `loop do`.
- Still not Ruby's: no Enumerators (`each(n)` without a block is an Array), no generator objects,
  no `Prime.lazy`. No bugs found.
