# semver

`sakelib/semver.sake` implements Semantic Versioning 2.0.0: parsing, precedence (`<=>` with the
prerelease rules of semver.org §11), bumping, and requirements in the style of `Gem::Requirement`
(`~> 1.2`, `>= 1.0, < 2`, `!=`, `=`) plus npm's caret (`^1.2.3`). Ruby has no semver in its standard
library, so the reference is `test/sakelib/ref/semver.rb` (plain Ruby, a `Comparable` class). The test
prints 60 lines, identical to `semver.rb`; 18 functions (public API: 15).

## API

| Ruby (ref) | Sake | |
|---|---|---|
| `SemVer.parse(s)`, `SemVer.valid?(s)` | same | same |
| `SemVer.new(1, 2, 3, ["rc", "1"], [])` | `SemVer.new(1, 2, 3, String["rc", "1"])` | same (pre and build default to empty) |
| `v.major`, `minor`, `patch`, `pre`, `build`, `prerelease?` | `SemVer.major(v)` ... | same |
| `v <=> w`, `<`, `==`, `sort`, `max` | same operators; `Array.sort`, `Array.max` | same (`include Comparable`; build metadata ignored, so `1.0.0+a == 1.0.0+b`) |
| `v.bump(:major / :minor / :patch / :pre)` | `SemVer.bump(v, :major)` | same |
| `v.to_s`, `v.inspect` (`#<SemVer 1.2.3>`) | `to_s`, `inspect` of the type | same |
| `v.satisfies?("~> 1.2")`, `SemVer.max_satisfying(vs, req)` | `SemVer.satisfies?(v, req)`, `SemVer.max_satisfying(vs, req)` | same |
| `SemVer::Requirement.parse(s)` | `SemVer::Requirement.parse(s)` | same (nested since 2026-10-10; was `SemVerRequirement`) |
| `req.satisfied_by?(v)`, `req.to_s` | `SemVer::Requirement.satisfied_by?(r, v)`, `to_s` | same |
| `SemVerError` (a StandardError) | `class SemVerError < Exception` | same name; no hierarchy |

## What differs from Ruby, and why

- `SemVer::Requirement` is written `class SemVer::Requirement` (Ruby's spelling; `SemVerRequirement` before 2026-10-10).
- `<=>` with a non-SemVer returns nil in Ruby. In Sake, `==` with another type is false without calling
  `<=>`, and `<` with another type is a type report before running, so `<=>` assumes a SemVer.
- Requirements compare by precedence only, as `Gem::Requirement` does: `2.0.0-alpha` satisfies `~> 1.2`
  (it is below 2.0.0). npm's rule that excludes prereleases is not implemented (in the ref either).

## Friction

1. `if !last ... elsif String.match?(last, ...)` (last from `Array.last`) → `--strict=2`:
   `String.match?: argument 1 may be nil (nil | String) [nil]` → `if last == nil`. `if !x` does not narrow
   x in the else branch, while `unless x` does: `sakelib/notes/semver_bug_not_narrowing.sake`.
2. Without value constants, the version regexp is `def pattern = /.../` (a regexp literal is cheap, so no
   `once`).
3. `[@major, @minor, @patch] <=> [...]` gives a Tuple comparison directly, as Ruby's Array: no friction.
4. A wrong-typed `SemVer.parse(123)` is not a static error: `raise ... unless s in String` checks it, and the
   checker accepts the call (the raise is a legal outcome).

## Language features used

- `initialize` for validation (non-negative Integers, prerelease identifiers): helped; `SemVer.new(1, -1, 0)`
  raises as in Ruby.
- Field defaults `pre = String[], build = String[]`: `SemVer.new(2, 0, 0)` as Ruby's optional arguments.
- `include Comparable` + `<=>`: `Array.sort`, `Array.max`, `==` all work (`Array.sort(shuffled)` sorts the
  semver.org example).
- `Array[*Array.take(@pre, n - 1), "x"]` (splat into a built-in) for `pre[0...-1] + [x]`.
- Chain after a `do ... end` block: `Array.map(...) do ... end.Array.join(", ")` works.

## Checker findings before the test passed

- `--strict=1`: none. `--strict=2`: the `if !last` report above (worked around).
- `--strict=3` (not required): `[index-nil]` for `|a, b|` of `Array.each_cons` and in `<=>` reached from it.

## Types (`bin/sake --types test/sakelib/semver.sake`)

- `SemVer.pre` and `SemVer.build`: a union of a dozen Array allocation sites, all of String elements
  (`String[]`, `String.split`, `Array.take`, `Array[*...]`). Harmless: one element type.
- partial: `Comparable.<` and `SemVer.major` get `nil | SemVer` from `|a, b|` of `Array.each_cons(vs, 2)`
  (a destructured block parameter may be nil). No unknowns.
