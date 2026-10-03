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
| `Prime.each { \|p\| ... break ... }` | `Prime.each(nil) { \|p\| ... break ... }` | differs: the bound is required (pass nil for no bound) |
| `Prime.each(30)` without a block (an Enumerator), `.to_a` | `Prime.to_a(30)` | differs: Sake has no Enumerators |
| `Prime.each(n).each_with_index { \|p, i\| }` | `Prime.each_with_index(n) { \|p, i\| }` | differs (same reason) |
| `Prime.first(n)`, `Prime.take(n)` | same | same |
| `Prime.take_while { }`, `Prime.find { }` | same | same |
| `Prime.prime?(n)`, `Prime.include?(n)` | same | same |
| `n.prime?` | `Integer.prime?(n)` | same |
| `Prime.prime_division(n)`, `n.prime_division` | `Prime.prime_division(n)`, `Integer.prime_division(n)` | same: `[[p, e], ...]`, an Array of Tuples, which prints as Ruby's; negative n gives `[-1, 1]` first, and 0 raises ZeroDivisionError |
| `Prime.int_from_prime_division(pd)`, `Integer.from_prime_division(pd)` | same | same |
| `Integer.each_prime(ub) { }` | same | same |
| `Prime.prime?(n, generator)`, `prime_division(n, generator)` | | missing: no optional parameters, and no generator objects |
| `Prime::EratosthenesGenerator`, `TrialDivisionGenerator`, `Generator23`, `PseudoPrimeGenerator` (`succ`, `next`, `rewind`, `upper_bound=`) | | missing (see below) |
| `Prime.lazy`, and other Enumerable methods on `Prime` (`select`, `each_slice`, ...) | | missing: no Enumerators or lazy sequences; `each(nil)` with `break` covers most uses |
| `Prime.instance` | | missing (no singleton objects) |

## What could not be ported, and why

- **Generators as objects.** Ruby's generators are stateful iterators (`succ`, `rewind`). They could be
  Struct types with a `succ` operation, but Ruby's API passes them as optional arguments (`prime?(n,
  gen)`), and Sake has no optional parameters. Also, the only point of passing one, which is to choose the
  algorithm, does not survive without dispatch on a generator protocol. Not ported.
- **The shared sieve cache.** Ruby's `EratosthenesSieve.instance` keeps primes between calls. Sake has no
  global mutable state (no value constants or singletons), so each `Prime.each` sieves again: up to 128,
  then 256, and so on, doubling until the bound. `Prime.first(1000)` sieves 7 times, up to 8192. That is
  fine for typical uses. A caller that needs a cache can keep `Prime.to_a(n)` itself.
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
