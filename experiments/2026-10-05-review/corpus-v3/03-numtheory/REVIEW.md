# Review (03-numtheory, corpus-v3, 2026-10-05)

All 25 programs give `.out` exactly under `bin/sake --strict=0` (exit 0).
The `.rb` files here are broken symlinks (`../../corpus/...`); the Ruby versions were read from
`experiments/2026-10-01-inference-500/corpus/03-numtheory/`.

## Per program

- base_conversion: exception type `class InvalidDigit < Exception` + `attr_reader char, base` (was `Exception.new(:char, :base)`), as Ruby's `class InvalidDigit < StandardError`.
- calendar_congruences: unchanged.
- check_digits: `s[0, 9]` (was `s[0...9]`); adjacent swap `cs[i], cs[i + 1] = cs[i + 1], cs[i]` (was a temporary).
- collatz_stats: `class Chain` + `attr_reader start, length, peak` (was `Struct.new`); `Array.sum(chains) { ... }` with a block (was `sum(map)`).
- continued_fractions: `if (sol = pell(n))` assignment in the condition, as Ruby.
- digit_curiosities: modifier `n = digit_sum(n) while n >= 10`; `Integer.times(limit) { |i| ... return ... }` (was a counting `while`); `Array.sum(ds) { |d| d ** k }`; `if (r = ...)`.
- egyptian_fractions: `while (dup = Array.find(...))` (was a `changed` flag); `Array.sum(units, 0r) { ... }`; `Range.each` blocks with `next`/`return` in `erdos_straus` (was nested `while` loops); `Array.max(Array[..., x])`; `prefix + greedy(rest)` (was `Array.concat(Array.dup(...))`); `if (sol = ...)`.
- factor_functions: nested block parameters `|acc, (p, e)|` (was `p, e = pe` in the body); `Array.sum(divs) { ... }`.
- farey_stern_brocot: unchanged.
- fibonacci_numbers: unchanged.
- goldbach: `Array[false, false] + Array.new(limit - 1, true)` (was a push loop); `partitions` as `Range.select ... .Array.map` (Ruby's select.map); `lo_n, lo_c = Array.min_by(...)` and `Array.first(block)[0]` (were extra temporaries).
- happy_cycles: Array as Hash key `cycles[cycle_from(n, k)]` (was keyed by `Array.join(..., ",")` and split back); `Range.select` for consecutive pairs; modifier `while` for the trail.
- integer_partitions: `def each_partition(n, max_part, prefix, &block)` passing `&block` on (was `{ |p| yield(p) }`); `Integer.downto(Array.min(...), 1)` (was `while`); `prefix + Array[part]`; `Array[1] + Array[0] * limit` (was a push loop); `Range.select` for odd parts; `pn == pent` inline.
- linear_diophantine: `class NoSolution < Exception` + `attr_reader a, b, c`; `class Step` + `attr_reader q, r, s, t` (was `Struct.new`); `g = Integer.gcd(a, b)` once, as Ruby.
- linear_sieve: `class Tables` + `attr_reader`; `Array.new(n + 1, 0)` (was a push loop); `Array.each(primes) { break if ... }` (was an index `while`); `Range.sum(1..m) { ... }`; `Array.push(inverse[v] ||= Array[], k)` (Ruby's `(h[k] ||= []) << k`; was an if/else); `Range.select`/`Range.reject` (were `Array.select(Range.to_a(...))`).
- miller_rabin: `Integer.times(s - 1) { ... return true ... }` (was a counting `while`); `Integer.step(3, 5000, 2)` with `next` (was a `while` with `n += 2`).
- modular_crt: `class NotInvertible < Exception` + `attr_reader value, modulus`; `class ModulusMismatch < Exception`; `Range.map(0..10)`; `if (res = crt(sys))`.
- perfect_amicable: `Array.new(limit + 1, 0)` and `Integer.step(d * 2, limit, d)` (was a push loop and `while`); `if (start = pos[nxt])`; `aliquot(n, 20) => {kind:, seq:, cycle:}` directly; `Range.select`; modifier `if` on the amicable push.
- pollard_rho: `class Result` + `attr_reader factor, iterations, method`; local `bases` shared by both loops, as Ruby; `next true if ...` in `Array.all?`; `Range.each(1...20)` with `return` (was `while`); `Integer[2] + factorize(n / 2)`, `Array.sort(half + half)`, `Array.sort(a + b)` (were `unshift`/`concat(dup)`).
- primitive_roots: `class NoPrimitiveRoot < Exception` + `attr_reader n`; chain `Range.select ... .Array.map ... .Array.sort`; `Integer.times(m)` and `table[e] ||= j` in `bsgs` (was `Hash.key?` + `Range.each(0..(m - 1))`); `Range.select`; `if (x = bsgs(...))`.
- pythagorean_triples: `Range.each(1...m)` with `next unless` (was an inner `while`); `Array.push(by_p[k] ||= Triple[], ...)`; `a, b, c = Triple.get_a(t), ...`; Berggren levels with `Integer.times(3)` + `Array.flat_map` (was a `while` + concat loop).
- quadratic_residues: `class NoSquareRoot < Exception` + `attr_reader a, p`; modifier `a, b = b, a % b while b > limit`; `Range.select`/`Range.map`; `lo = Array.min(Array[r, (pr - r) % pr])` (Ruby's `[r, x].min`; was a ternary with a temporary); `Array.select(...).Array.map do`.
- repeating_decimals: `expand(1, d) => {cycle:}` directly (was `e = expand(...)` then `e => {cycle:}`), four places.
- rsa_toy: `class BadExponent < Exception` + `attr_reader e`; `class Key` + `attr_reader n, e, d, p, q` with its functions in the same body (was `Struct.new` + a reopened `class Key`); `if (pq = factor_modulus(n))`.
- sieve_primes: `Array.new(limit + 1, true)` and `Integer.step(i * i, limit, i)` (was a push loop and `while`); `if (last_twin = Array.last(twins))`.

Changed 22, unchanged 3 (calendar_congruences, farey_stern_brocot, fibonacci_numbers: nothing in the new language makes them closer to the Ruby). Features used most: `class C < Exception`/`class C` + `attr_reader` (11 programs), built-ins now accepted (`Array.new(n, v)`, `Array + Array`, `Integer.step`, `sum` with a block; 10), `return`/`break`/`next` in blocks replacing counting `while` loops (8), assignment in a condition (8), `h[k] ||= v` (3), `&block` pass-on (1), Array Hash keys (1). No program had a Ruby `CONSTANT` table, optional/keyword parameters, `is_a?` checks or an `initialize` that did more than store fields, so `once`, `x => Integer`, keywords and `def initialize(c)` found no use here.

## Friction

- **No `loop do`** (farey_stern_brocot.sake:71, fibonacci_numbers.sake:51, integer_partitions.sake:35): wanted Ruby's `loop do ... break if ... end` → `loop` is an undefined function → wrote `while true`.
- **No Enumerator from a block-less call** (farey_stern_brocot.sake:15-22, fibonacci_numbers.sake:97-99, collatz_stats.sake:71-74, sieve_primes.sake:36,42, rsa_toy.sake:36-39): wanted `seq.each_cons(2).all? { |x, y| ... }`, `each_cons(2).count`, `each_cons(2).select`, `bytes.each_slice(w).map` → `each_cons`/`each_slice` only take a block → a flag or accumulator set inside the block (or `return false` from a helper).
- **`@x` only for the first parameter** (fibonacci_numbers.sake:9-10, modular_crt.sake:24-41, pythagorean_triples.sake:16): Ruby's binary operators read the other operand's fields as `y.a`, `b.v`, `other.c` → `Mat2.get_a(y)` etc.; in `Mat2#*` that is eight `Mat2.get_*` calls on one line pair where Ruby has `y.a`.
- **No `Math::PI`** (farey_stern_brocot.sake:110-111, linear_sieve.sake:65,73, integer_partitions.sake:83): the literal is repeated; `def pi = 3.141592653589793` would be the documented replacement, but the corpus inlined it (and integer_partitions uses a shorter literal than the others).
- **String has no `[]=`** (check_digits.sake:107-110): Ruby's `typo = base.dup; typo[i] = d.to_s` → `String.chars` + Array write + `Array.join`.
- **`Array.last(a, n)` not available** (sieve_primes.sake:67): `primes.last(5)` → `Array.drop(primes, Array.size(primes) - 5)`.
- **Tuple has no `first`** (fibonacci_numbers.sake:43): `fib_pair(n).first` → `f, x = fib_pair(n)` (or `[0]`).
- **No `Hash#default=` / `tally` with a default** (egyptian_fractions.sake:16-17): `counts = units.tally; counts.default = 0` → `Hash.new(0)` filled by `Array.each`.
- **No Symbol-to-proc** (`&:size`, `&:to_s`, `reduce(1, :*)`, everywhere; e.g. pollard_rho.sake:110, collatz_stats.sake:48): every one becomes an explicit block naming the type (`{ |c| Chain.get_length(c) }`).

## Ruby comparison

- **Every call names its type**: `Integer.pow(a, d, n)`, `Rational.numerator(r)`, `Mod.get_v(b)` instead of `a.pow(d, n)`, `r.numerator`, `b.v`. The arithmetic-heavy bodies (pollard_rho.sake:35-68, quadratic_residues.sake:27-58) still read like the Ruby, because operators dispatch; the difference shows in field reads and method chains.
- **Operator definitions take the subject explicitly**: `def *(x, y)` and `def <=>(a, b)` in place of `def *(y)` / `def <=>(other)`, and `include Arithmetic` / `include Comparable` to join the operator (fibonacci_numbers.sake:4-13, modular_crt.sake:10-41).
- **Class-level constructors are plain functions of the type**: Ruby's `def self.make`/`def self.build`/`def self.identity` are `def make(v, m)`, `def build(a, b, c)`, `def identity` (modular_crt.sake:15, pythagorean_triples.sake:8, fibonacci_numbers.sake:15), called as `Mod.make(...)`.
- **Exception types need no `initialize`**: Ruby's `def initialize(message, a, b, c); super(message); @a = a ...` collapses to `attr_reader a, b, c` (message first), and readers are `NoSolution.get_a(e)` instead of `e.a` (linear_diophantine.sake:72).
- **Records where Ruby returns Hashes**: `{g:, x:, y:, steps:}` and `{kind:, seq:, cycle:}` are taken apart with `=> {...}`; Ruby's `r[:steps]` / `e[:cycle]` reads become a pattern line (linear_diophantine.sake:57, repeating_decimals.sake:25).
- **Typed array constructors**: `Integer[]`, `Triple[]`, `String[...]` where Ruby writes `[]`; a bare `[a, b]` is a fixed Tuple, so growable lists start with `Array[]`.
