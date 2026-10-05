# diff

`sakelib/diff.sake` is an LCS diff after the diff-lcs gem (`Diff::LCS`). The gem is not installed here,
so the reference is `test/sakelib/ref/diff.rb`; its output for the gem README's `seq1`/`seq2` example
(`lcs`, `diff`, `sdiff`) is the one the README shows. `test/sakelib/diff.sake` prints the same 64 lines as
`diff.rb`. 257 lines, 24 functions.

## API

| Ruby (diff-lcs) | Sake | |
|---|---|---|
| `Diff::LCS.lcs(a, b)` | `DiffLCS.lcs(a, b)` | same (Arrays or Strings by character) |
| `Diff::LCS.diff(a, b)` | `DiffLCS.diff(a, b)` | same: hunks of `DiffChange` |
| `Diff::LCS.sdiff(a, b)` | `DiffLCS.sdiff(a, b)` | same: `DiffContextChange`s |
| `Diff::LCS.patch(src, diffs)`, `unpatch(src, diffs)` | `DiffLCS.patch`, `unpatch` | same (diff or sdiff output; a String gives a String) |
| `Diff::LCS.traverse_sequences(a, b, callbacks)` | `DiffLCS.traverse_sequences(a, b) { \|event, i, j\| }` | differs: a block with `:match` / `:discard_a` / `:discard_b` instead of a callbacks object |
| `Diff::LCS.traverse_balanced(a, b, callbacks)` | `DiffLCS.traverse_balanced(a, b) { \|event, i, j\| }` | differs (same way, plus `:change`) |
| `Change#action`, `position`, `element`, `to_a`, `adding?`, `deleting?`, `unchanged?`, `inspect` | `DiffChange.action(c)`, ... | same; `inspect` prints the gem's `#<Diff::LCS::Change: ["-", 0, "a"]>` |
| `ContextChange#old_position`, `old_element`, `new_position`, `new_element`, `changed?`, `to_a` | `DiffContextChange....` | same |
| `a.diff(b)` (the `diff/lcs/array` mixin), `patch!`, `patch(src, diffs, :patch)` direction, `Diff::LCS::Hunk`, `ldiff` | | missing |

## What differs, and why

- Names: `Diff::LCS` → `DiffLCS`, `Diff::LCS::Change` → `DiffChange` (no nested names).
- Callbacks: the gem takes an object with `match`/`discard_a`/`discard_b` methods. Sake has no receiver
  dispatch and blocks are not values, so the traversals yield an event Symbol.
- The LCS is dynamic programming, O(n*m). Among several common subsequences of the same length, the one
  chosen may differ from the gem's Hunt-Szymanski choice (the reference shares the algorithm, so the
  test cannot show it).

## Frictions

1. The test's `DiffChange.new(:bad, 0, "x")` (to show `initialize`'s `@action => String`) was reported
   before running: `` `=> String`: the value is :bad, which does not match [type] ``. Correct; to
   exercise the run-time failure the test takes the action from an Array.
2. `traverse_sequences` yields three values to a `case kind in :match ...` block: easy, and the checker
   knew the Symbols, so the `case` needed no `else`.

## New language features used

- `initialize` for validation: `DiffChange` checks `@action => String`, `@position => Integer` (the
  gem raises on a bad action). Helped: the bad call in the test was found before running.
- `x => T` in `initialize`; typed arrays `DiffChange[]`, `DiffContextChange[]`, `Tuple[]` for the
  matches.
- Multiple assignment swap `op, np = np, op` in `unpatch`.
- Keywords, `*rest`, `**opts`, `once`, `private attr_*`: not needed (the change types are Ruby's
  read-only Structs).

## Checker findings

- `--strict=1`: the `=> String` report above (in the test, fixed by taking the value from data).
- `--strict=2`: none.

## Types (`--types`)

- `DiffChange.action`: `nil | String | :bad`, from the test's bad value (taken from `Array[:bad, "-"]`).
- `DiffChange.element`, `DiffContextChange.old_element`/`new_element`: `nil | Integer | String` — the
  elements of the sequences the test diffs (nil: sdiff's missing side), as in the gem.
