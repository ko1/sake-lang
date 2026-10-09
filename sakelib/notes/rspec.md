# rspec (rspec-core / rspec-expectations, the DSL and the documentation format)

`require "rspec"` → `sakelib/rspec.sake`. Test: `test/sakelib/rspec.{sake,rb}`; the gem is not installed, and
its output has colours and timings, so `test/sakelib/ref/rspec.rb` is a plain-Ruby reference implementing
RSpec's DSL (`describe`, `context`, `it`, `xit`, `pending`, `expect(x).to eq(y)`, `expect { }.to
raise_error`) with the same documentation format; `rspec.rb` is the spec in real RSpec syntax, run by it.
Identical output (24 examples, 13 failures, 3 pending). 88 functions: `RSpec` 16, `Expectation` 40 matchers,
`To` 26 and `NotTo` 8 chain forms.

In the shape of `sakelib/minitest.sake`: a test is a block given to a call, and every expectation names its
example (the block's parameter):

```ruby
RSpec.describe("Array") do |g|
  RSpec.it(g, "pushes") do |ex|
    RSpec.expect(ex, a).To.eq(Array[1, 2])           # expect(a).to eq([1, 2])
    RSpec.expect(ex, a).NotTo.be_empty               # expect(a).not_to be_empty
    RSpec.expect(ex).To.raise_error(/boom/) { ... }  # expect { ... }.to raise_error(/boom/)
  end
  RSpec.context(g, "when empty") { |g2| RSpec.it(g2, "...") { |ex| ... } }
end
RSpec.run      # documentation format, Pending:, Failures:, "N examples, M failures, K pending"; exit 1 on failure
```

## API

| RSpec | Sake | |
|---|---|---|
| `RSpec.describe("X") { ... }` | `RSpec.describe("X") { \|g\| ... }` | same (the block gets the group) |
| `context "when" { }`, `describe` nested | `RSpec.context(g, "when") { \|g2\| }` | same (indents one level) |
| `it "does" { }`, `specify`, `example` | `RSpec.it(g, "does") { \|ex\| }`, `specify`, `example` | same; runs when defined |
| `it "does"` (no block) | `RSpec.it(g, "does")` | same: `PENDING: Not yet implemented` |
| `xit`, `skip`, `pending "why"` | `RSpec.xit(g, "...") { }`, `RSpec.skip(ex, why)`, `RSpec.pending(ex, why)` | `pending` differs: stops the example (RSpec runs on and demands a failure) |
| `expect(x).to eq(y)` | `RSpec.expect(ex, x).To.eq(y)` or `Expectation.to_eq(RSpec.expect(ex, x), y)` | same reading; the matcher is an operation |
| `expect(x).not_to m` | `.NotTo.eq`, `be_truthy`, `be_nil`, `include`, `match`, `be_empty`, `raise_error` | same for these 8; other negations missing |
| `eq`, `eql`, `be(x)`, `be_truthy`, `be_falsey`/`be_falsy`, `be_nil` | `To.eq`, `eql` (== too), `be` (`Kernel.equal?`), `be_truthy`, `be_falsey`, `be_falsy`, `be_nil` | same |
| `include(*xs)` | `To.include(*xs)` | same on Array, String, Hash (keys), Set, Range |
| `match(re)`, `start_with`, `end_with` | same | same (Strings) |
| `be_empty`, `have_key(k)` | same | same; `have_key` is Hash only |
| `contain_exactly(*xs)`, `match_array(xs)` | same | same |
| `be_within(d).of(x)` | `To.be_within(d, x)` | differs: one call (no matcher value to chain `.of` on) |
| `be > x`, `be >= x`, `be < x`, `be <= x`, `be_between(lo, hi)` | `To.be_gt(x)`, `be_ge`, `be_lt`, `be_le`, `be_between` | differs: names (`be` cannot return a value to compare) |
| `satisfy("desc") { \|x\| }` | `To.satisfy("desc") { \|x\| }` | same |
| `all(matcher)` | `To.all { \|x\| ... }` | differs: the block is the matcher (no matcher values) |
| `expect { }.to raise_error([String \| Regexp])`, `.not_to raise_error` | `RSpec.expect(ex).To.raise_error([m]) { }`, `NotTo.raise_error { }` | differs: the block goes to the matcher; gives the message (RSpec: true) |
| `raise_error(ErrorClass)`, `be_a(T)`, `be_an_instance_of` | — | missing: types are not values |
| `expect { }.to change { }.by(n)`, `output("x").to_stdout`, `have_attributes(h)`, `respond_to`, `be_kind_of`, `cover`, `exist`, `yield_control` | — | missing: two blocks / output capture / reflection |
| composed matchers (`include(a_string_matching(..))`, `all(be_even)`), custom matchers, `define_negated_matcher`, `aggregate_failures` | — | missing: matchers are not values |
| `let`, `let!`, `subject`, `before`, `after`, `around`, `shared_examples`, `it_behaves_like`, `described_class` | — | missing: stored blocks / reflection; write a function and call it in the example |
| `have_size(n)` (not RSpec's) | `To.have_size(n)` | added, as the brief asked |
| documentation formatter | `RSpec.run` / `RSpec.report` | same text without the `Finished in` line and the `Failed examples:` list (no file:line in Sake); failures numbered across groups |
| exit status | `RSpec.run` exits 1 on failure | same |

## できたこと / できなかったこと

- **できた**: the DSL in the minitest.sake shape with the chain `RSpec.expect(ex, x).To.eq(y)`, which reads
  as RSpec; nested contexts; pending in three forms; 40 matchers including the block ones; RSpec's
  documentation output and messages (`expected: 4 / got: 3 / (compared using ==)`, `expected [] to include 1`,
  `expected an exception but nothing was raised`).
- **The design that made it type-check**: an expectation is the **Tuple `[example, actual]`**, not a Struct
  type. The first version was `class Expectation; attr_reader example, actual` and every matcher failed
  `--strict`: `String.include?: argument 2 must be String, but is Integer [mixed]` with the hint
  `Expectation.actual holds Integer (written at line 432) besides Array, String, Float, Symbol, Hash` — the
  field is one type for the program, the merge point of everything any example expects on, so
  `String.match?(@actual, re)` is wrong for the Integer another example expected on. A Tuple literal's type is
  its own at each place it is made and the typer follows a polymorphic function per call, so with
  `def expect(ex, actual = nil) = [ex, actual]` and `ex, a = e` in each matcher, `a` has the type of *that*
  `expect` call. Two things follow: no `a => String` assertions in the matchers, and
  `RSpec.expect(ex, 42).To.match(/4/)` is reported before the spec runs (`String.match?: argument 1 must be
  String, but is Integer [type]`, with the chain of calls from the `it` line). RSpec would run it and fail
  at run time (or pass, if `42.to_s` were tried).
- **できなかった**: everything that stores a block (`let`, `before`, `subject`, `shared_examples`) or
  composes matchers as values (`all(be_even)`, `include(match(..))`, `raise_error(SomeClass)`,
  `be_within(d).of(x)` as two calls, `be > x` as an operator on a matcher), and `change { }` (two blocks).
  `pending` inside an example stops it (RSpec runs on and marks it failed if it passes): no way to continue
  the block and inspect what happened without `ensure` games.

## 書き心地

1. **`RSpec.expect(ex, actual).to_eq(expected)` is a call on a value** → not even tried: `x.op()` is a
   static error (spec §5.3). The chain form `x.T.f(args)` with `T` a *module* gives
   `RSpec.expect(ex, a).To.eq(y)`: `To` and `NotTo` are modules of `module_function`s taking the expectation
   first, one line each (`def eq(e, x) = Expectation.to_eq(e, x)`). It reads better than the brief's `to_eq`
   and costs 34 one-liners. The block matcher chains too: `RSpec.expect(ex).To.raise_error(/x/) { ... }`.
2. **The Struct field as a merge point** (above): first draft `class Expectation`, 20 matchers, `--strict`
   → 4 `[mixed]`/`[nil]` reports, each listing the union of every actual in the test. Second draft added
   `a = @actual; a => String` per matcher (works, but a wrong type then fails the *example* at run time).
   Third draft: the Tuple. The hint `Expectation.actual holds Integer (written at line 432) besides Array,
   String, ...` said exactly what was happening; what it could not say is "use a Tuple".
3. **`def xit(g, description) = record(...)`** then `RSpec.xit(g, "...") { ... }` in the test →
   `RSpec.xit does not take a block (it has no yield)`. Added an unused `&b` to accept and drop it. Right
   call by the checker (a block that nothing runs is suspicious); the fix is one token.
4. **`private attr_reader lines, results` on `ExampleGroup`**, read from `module RSpec` → `field lines of
   ExampleGroup is private (private attr_*) / hint: only the functions of class ExampleGroup read or write
   it`. Private means the class's functions, not the library; made them public readers.
5. **Collateral reports.** With the mistyped `expect(42).To.match(/4/)` the checker also says `rescue
   RSpecExpectationNotMet: the begin body never raises RSpecExpectationNotMet [rescue]` at `RSpec.it`: once
   the matcher's path is a type error, the typer no longer sees its `raise`, so the rescue looks dead. Two
   reports for one mistake; the first is the real one.
6. **What read as well as Ruby**: the `report` function (`Array.select(results) { |r| r[1] == :failed }`,
   `Array.each_with_index(failed) do |r, i|`), the `case expected in nil ... in String ... in Regexp` of
   `to_raise_error`, and `(Array|String|Hash|Set|Range).include?(a, x)` for `include` across five types — the
   union call is the one Sake form that is shorter than Ruby's duck typing while saying more. `once { Array[]
   }` for the run's groups/lines/results replaced three module-level constants.
7. **Not writing `let`**: the natural Sake replacement is a function (`def square(x) = x * x` in the test)
   called inside the example; `subject`/`let` memoization is not possible without a stored block, and in
   practice was not missed in a 24-example spec.

## Built-ins requested

- A **callable value** (a stored block / `lambda`) would give `let`, `before`, `subject`, `shared_examples`,
  matcher values and composition, `change { }.by`; it is the whole of the missing column.
- **Output capture** (`output { }.to_stdout`, minitest's `assert_output`): a built-in `Kernel.capture { }`
  returning the String written by `puts` inside the block.
- **A type as a pattern value for `raise_error`**: `raise_error(ZeroDivisionError)` needs to name a type as
  an argument; with no types as values, a Symbol spelling (`raise_error(:ZeroDivisionError)`) and a
  `Kernel.type_name(e)` would do.
- **A file:line of the current call** (`__LINE__` / `caller`) for RSpec's `Failed examples: rspec ./x.rb:7`.
