# abbrev

`require "abbrev"` → `sakelib/abbrev.sake`. Test: `test/sakelib/abbrev.{sake,rb}` (identical output).
Ruby's algorithm, line for line.

## API

| Ruby | Sake | |
|---|---|---|
| `Abbrev.abbrev(words)` | `Abbrev.abbrev(words)` | same |
| `Abbrev.abbrev(words, pattern)` (Regexp, or String prefix) | `Abbrev.abbrev(words, pattern)` | same (pattern may be nil, a Regexp, or a String) |
| `words.abbrev` (Array#abbrev) | `Array.abbrev(words)` | same (added to the built-in Array, as Ruby does) |
| `words.abbrev(pattern)` | `Array.abbrev(words, pattern)` | same |

2 operations ported; nothing missing, nothing differs.

## What differs and why

- ~~Optional argument~~ (phase 1: `abbrev_matching(words, pattern)`): restored in phase 2 as
  `abbrev(words, pattern = nil)`.
- **Pattern dispatch.** Ruby converts a String pattern to `/\A#{Regexp.quote(pattern)}/` and uses
  `!~`; the port tests `case pattern in nil / in Regexp / in String` (`String.start_with?` for a
  String), which needs no Regexp building.

## Built-ins Sake lacks

None needed.

## Friction

None: the first draft ran under `--strict` and matched Ruby's output. `seen[abbrev] += 1` on
`Hash.new(0)`, `break` out of `Integer.downto`, and `next` all behaved as Ruby's. Ruby's `case
(seen[abbrev] += 1) when 1 ... when 2` became `if n == 1 ... elsif n == 2` (no `case`/`when`).

## Phase 2

- `abbrev_matching` removed; `Abbrev.abbrev(words, pattern = nil)` and `Array.abbrev(words, pattern =
  nil)` as in Ruby. The test calls `abbrev` with patterns and adds `Array.abbrev` with a String and a
  Regexp pattern.
- No tables to build and no scans to replace: the prefixes are Ruby's `word[0, len]` loop.
- **Speed** (`experiments/2026-10-03-sakelib-port/phase2/bench_abbrev.sake`: 300 words; `bin/sake
  --strict`, CPU user+sys, 3 runs, shared machine at load ~35 on 16 cores): before 0.82 / 0.85 / 0.78 s,
  after 0.83 / 0.82 / 0.85 s. Mostly startup (~0.7 s); no change expected.

## Review 2026-10-05

No change: `abbrev(words, pattern = nil)` is Ruby's signature. `pattern` is `nil | Regexp | String` by Ruby's API, taken apart with `case`/`in` (`abbrev.sake:35`). `--strict=1`/`2`: 0 reports before and after.

## 2026-10-05

Checked against the new features; nothing applies. `abbrev(words, pattern = nil)` is Ruby's signature, there is no type with state, and no `*rest`/keywords in Ruby's API. No change to the library or the test.
