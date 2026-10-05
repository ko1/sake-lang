# lru_cache

`sakelib/lru_cache.sake`: a least-recently-used cache after the lru_redux gem (`LruRedux::Cache`), with
hit/miss/eviction counters. A Hash keeps the order, as in Ruby (re-inserting a key moves it to the end).
The reference is `test/sakelib/ref/lru_cache.rb`. 18 operations; the test prints 38 lines, identical to
`lru_cache.rb`, including memoized `fib(80)`.

## API

| Ruby (lru_redux) | Sake | |
|---|---|---|
| `LruRedux::Cache.new(max_size)` | `LRUCache.new(max_size)` | differs: no nested names |
| `c[k]`, `c[k] = v` | `c[k]`, `c[k] = v` | same (Indexable) |
| `c.getset(k) { }` | `LRUCache.getset(c, k) { \|k\| }` | same |
| `c.fetch(k) { }` | `LRUCache.fetch(c, k) { \|k\| }` | same; without a block KeyError (as Hash#fetch) |
| `c.key?(k)`, `delete(k)`, `count`, `clear`, `to_a` (most recent first), `each`, `keys` | same | same |
| `c.max_size`, `c.max_size = n` | `LRUCache.max_size(c)`, `LRUCache.set_max_size(c, n)` or `c.LRUCache.max_size = n` | same (shrinking evicts) |
| (not in the gem) | `LRUCache.stats(c)` (`{hits:, misses:, evictions:, size:}` Hash), `hit_rate` | added |
| `LruRedux::TTL::Cache`, `ThreadSafeCache` | | missing |

## What differs from Ruby, and why

- `max_size=` is `set_max_size`, Sake's writer name; `c.LRUCache.max_size = 2` calls it (the field is an
  `attr_reader`, and the class's own `set_max_size` is used by the write syntax).
- `evict` and `touch` are public: Sake has private fields, not private functions.

## Friction

1. `@max_size => Integer` in `initialize`, then `@max_size > 0` → with the test's wrong-typed
   `LRUCache.new(Array.fetch(Array[1, "big"], 1))`, `--strict=2`: `Comparable.>: the operands may be
   (String, Integer) [mixed]`, `LRUCache.max_size holds String (written at line 74)`. The assertion does not
   narrow the field, though spec §10.1 says the fields hold what initialize leaves and §2.1 recommends
   this check: `sakelib/notes/lru_cache_bug_initialize_assert_field.sake`. Workaround:
   `n = @max_size; n => Integer; ...; @max_size = n` (a checked local written back), after which
   `--types` shows `LRUCache.max_size: Integer`.
2. `v = Hash.delete(@data, key); @data[key] = v` (move to the end) → `[type]` on `fib`'s `+`, operands
   `(Integer, nil)`: `Hash.delete` is `nil | V`, so the stored values gained nil → `Hash.fetch` first, then
   `Hash.delete`.
3. `k, _ = Hash.first(@data)` → `multiple assignment: argument 1 may be nil` → `Hash.shift(@data)`, which is
   also what Ruby code would use.
4. String values in one cache and Integer values in another made `fib`'s `+` a `[type]` report (the data
   field is one Hash type for all caches) → the test stores Integers only. A program caching different
   value types would declare `class XCache < LRUCache` (but see pqueue's note: a Hash made inside the
   class is shared by its copies; here the Hash is the field default, also one site).

## Language features used

- `include Indexable` with `[]` / `[]=`: helped (`c[:a] = 1`).
- `private attr_reader data = Hash[], hits = 0, misses = 0, evictions = 0`: per-instance state with
  defaults; `LRUCache.new(3)` takes only the size.
- `initialize` for validation (with the workaround above).
- `block_given?` in `fetch`: helped; `fetch(c, k) { }` and `fetch(c, k)` (KeyError) as Hash#fetch.
- A block that recurses into the function (`getset(cache, n) { fib(cache, k - 1) + ... }`).

## Checker findings before the test passed

- `--strict=1`: the two `[mixed]` warnings (friction 1) and the `[type]` report (friction 2/4).
- `--strict=2`: those, plus the `Hash.first` nil (friction 3).

## Types

- `LRUCache.data: Hash[Integer | String | Symbol => Integer]` (keys of all caches of the test).
- partial: the `=> Integer` check, which gets `Integer | String` from the error test. No unknowns.
