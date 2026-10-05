# text

`sakelib/text.sake`: string metrics and formatting from popular gems. Ruby's standard library has none
of them, so `test/sakelib/ref/text.rb` is a plain-Ruby reference: the text gem's
`Text::Levenshtein.distance` and `Text::Soundex.soundex`, the jaro_winkler gem's `JaroWinkler.distance`
/ `jaro_distance`, and ActionView's `word_wrap`. 5 operations; the test prints 60 lines, identical to
`text.rb`.

## API

| Ruby | Sake | |
|---|---|---|
| `Text::Levenshtein.distance(a, b, max_distance = nil)` | `Levenshtein.distance(a, b, max = nil)` | differs: top-level module (no nested names); same otherwise |
| `Text::Soundex.soundex(s)` | `Soundex.soundex(s)` | same (nil for a String without letters) |
| `Text::Metaphone`, `Text::PorterStemming`, `Text::WhiteSimilarity` | | missing |
| `JaroWinkler.distance(a, b, ignore_case:, weight:, threshold:)` | same | same (ArgumentError for weight > 0.25, as the gem) |
| `JaroWinkler.jaro_distance(a, b, ignore_case:)` | same | same |
| `word_wrap(text, line_width: 80, break_sequence: "\n")` (ActionView helper) | `WordWrap.word_wrap(...)` | same, in a module |

The Ruby reference uses the same top-level module names, so both tests read the same.

## What differs from Ruby, and why

- No `Text::` prefix: Sake has no nested names.
- A non-String argument to `Levenshtein.distance` raises `NoMatchingPatternError` (`a => String`); the
  reference does the same (the text gem would fail later with NoMethodError).
- Lengths are in characters (`String.chars`, `String.length`), as in Ruby.

## Friction

1. `Levenshtein.distance("a", 1)` in the test (to show the error) → `=> String: the value is Integer,
   which does not match [type]` before running, twice (once per analysis pass). The checker is right; to
   test the run-time error, the test passes `Array.fetch(Array["a", 1], 1)`, whose type is a union.
2. A constant Hash (`CODES`) → `def codes = once do ... end`.
3. `[a, b].min` → `Tuple.min([a, b])` (Ruby's `[x, y].max` idiom reads well with Tuple.max).
4. `a.select.with_index { }` (an Enumerator) → `Array.each_with_index(a)` without a block gives the
   `[x, i]` Tuples, then `Array.select`/`Array.map` in a chain.
5. Passing a keyword on: `jaro_distance(s1, s2, ignore_case:)` (Ruby's shorthand) works.

## Language features used

- Keyword parameters with defaults (`ignore_case: false, weight: 0.1, threshold: 0.7`,
  `line_width: 80, break_sequence: "\n"`): helped; the calls are Ruby's.
- Optional positional parameter `max_distance = nil`.
- `x => String` for the argument check.
- `once` for the Soundex table.
- `/(.{1,#{line_width}})(\s+|$)/` with `String.gsub` and `"\\1..."`: ActionView's implementation ran
  unchanged.

## Checker findings before the test passed

- `--strict=1`: the deliberate `Levenshtein.distance("a", 1)` (above). `--strict=2`: none.

## Types

- No fields. partial: the `=> String` in `distance`, which gets `Integer | String` from the error test.
  No unknowns.
