# abbrev

`require "abbrev"` → `sakelib/abbrev.sake`. Test: `test/sakelib/abbrev.{sake,rb}` (identical output).
Ruby's algorithm, line for line.

## API

| Ruby | Sake | |
|---|---|---|
| `Abbrev.abbrev(words)` | `Abbrev.abbrev(words)` | same |
| `Abbrev.abbrev(words, pattern)` (Regexp, or String prefix) | `Abbrev.abbrev_matching(words, pattern)` | differs: name (pattern may be nil, a Regexp, or a String) |
| `words.abbrev` (Array#abbrev) | `Array.abbrev(words)` | same (added to the built-in Array, as Ruby does) |
| `words.abbrev(pattern)` | `Abbrev.abbrev_matching(words, pattern)` | differs: name |

3 operations ported; nothing missing.

## What differs and why

- **Optional argument.** Sake functions take only required parameters, and one name has one arity,
  so `abbrev(words, pattern = nil)` became two names. `abbrev_matching` takes `nil` for "no pattern",
  so `abbrev(words)` is `abbrev_matching(words, nil)`.
- **Pattern dispatch.** Ruby converts a String pattern to `/\A#{Regexp.quote(pattern)}/` and uses
  `!~`; the port tests `case pattern in nil / in Regexp / in String` (`String.start_with?` for a
  String), which needs no Regexp building.

## Built-ins Sake lacks

None needed.

## Friction

None: the first draft ran under `--strict` and matched Ruby's output. `seen[abbrev] += 1` on
`Hash.new(0)`, `break` out of `Integer.downto`, and `next` all behaved as Ruby's. Ruby's `case
(seen[abbrev] += 1) when 1 ... when 2` became `if n == 1 ... elsif n == 2` (no `case`/`when`).
