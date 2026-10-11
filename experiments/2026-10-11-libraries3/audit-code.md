# Audit: code written in Sake (2026-10-11)

Scope: tracked `sakelib/*.sake`, `test/sakelib/*.sake`, `examples/**/*.sake`, `test/sake/*_test.sake`,
`test/samples/*.sake` (comments only). Output of every test is unchanged; no `.expected` file changed.
Tests run after the changes: `test_sakelib.rb` (90 runs), `test_examples.rb` (59), `test_samples.rb` (167),
`test_sake_suite.rb` (7), all passing.

## Flattened names → nested

| file | old | new |
|---|---|---|
| sakelib/kramdown.sake | top-level `KNode`, `KBlocks`, `KSpans`, `KHtml` | `Kramdown::Element`, `Blocks`, `Spans`, `Html` (moved into `module Kramdown`) |
| sakelib/erb.sake | `ERBError`, `ERBNode`, `ERBFrame` | `ERB::Error`, `ERB::Node`, `ERB::Frame` (nested in `class ERB`); test/sakelib/erb.sake rescues `ERB::Error` |
| sakelib/date.sake | `module DateCore` | `module Date::Core` |
| sakelib/time.sake | `class TimeParts`, `module TimeCore` | `Time::Parts`, `Time::Core` |
| sakelib/find.sake | `FindPrune` | `Find::Prune` |
| sakelib/httparty.sake | `HTTPartyClient` | `HTTParty::Client`; test/sakelib/httparty.sake updated |

The API rows of `sakelib/notes/{kramdown,erb,date,time,find,httparty}.md` name the new types and say
when they changed; the dated writing-feel sections are left as written.

## Enum

- examples/data-structures/ring_buffer_metrics.sake: `Ring` has `include Enum`; its hand-written
  `to_a` is gone, `mean` is `sum(r, 0.0) / @count`, `to_s` uses `map(r)`.
- Tried and reverted: `include Enum` on `CSV::Table` (to drop its hand-written `map`/`select`/`find`).
  `Enum.sort_by` is written as `Array.sort_by(to_a(x))`, and a class's own `to_a` wins, so
  `CSV::Table.sort_by` would have sorted `[headers, fields...]` instead of the rows. Prelude issue, see below.

## Long `def f = expr` → `def ... end`

httparty `HTTParty::Client._url/get/head/delete/post/put/patch`, money `Currency.decimal_places`,
`Currency.inspect`, `exchange_to`, liquid `empty?` (a `case`), yaml `fold`, units `power_list`
(the `.Array.join` chain is gone too), matrix `Vector.round`, csv `inspect`, rspec `indent_lines`, xml
`start_tag`, active_support_inflector `upcase_first`/`downcase_first`, kramdown `Html.inner`,
examples sql/ast `type_affinity` (nested ternaries → `case`), minesweeper `won?`, undo_redo_editor
`status`, test/sakelib/redis `glob_to_re`. Left as endless: long but single-step bodies (data tables,
regexps, a call that forwards keywords).

## Operator function forms

`String.*("ab", 600)` → `"ab" * 600` (examples/parsers-and-codecs/lzw, test/sake/io_thread_test,
test/sakelib/digest, rack, zlib); pathname `String.<=>(a, b)` → `a <=> b`.

## examples/first.sake ("the smallest tour")

Was `Point = Struct.new(:x, :y)` + reopening `class Point`, `x(p)`, `set_x(p, ...)`, `def Point.move`,
`String.+(name, "!")`. Now `class Point` with `attr_accessor x, y`, `@x`, `move` inside the class,
`total += x`, `name + "!"`. Same output (checked against the old file). test/samples/first.sake keeps
the old forms (it tests them).

## Comments that described old rules or missing built-ins

- "Struct type" / "Struct value" for a program's class: awesome_print, event_emitter, pp, units,
  rack, webrick, semver, rspec, pqueue, trie, state_machine, observer, prettyprint,
  test/sakelib/{pp,awesome_print}, test/samples/{field_shorthand,field_or_assign}.
- webrick header: "Ruby's nested names are flattened: WEBrick::HTTPServer -> HTTPServer ..." was
  false (the code nests them since 2026-10-10); the header and its usage example now say `WEBrick::...`.
- event_emitter: "a user function cannot be called with `*args`" (false: splat into a `*rest` works).
- getoptlong "Sake has no ENV", logger "no Process.pid", pp "no winsize", monitor / mutex_m /
  test/sakelib/monitor "no Thread.current" and "Mutex has only synchronize": all exist now
  (`ENV`, `Process.pid`, `IO.winsize`, `Thread.current`, `Mutex.lock/unlock/owned?`, added
  2026-10-09/10 after those ports). The comments now say the port predates them; behavior unchanged.
- test/sake/language_test.sake: "array patterns (`in [a, b]`) are not supported" (false now).
- test/samples/include.sake: "include borrows" → "include copies".

## Left as they are

- examples/apps/sql: ~40 top-level modules (`Ast`, `Parser`, `WindowParser`, ...). Nesting them under
  one namespace would touch every file of the app; not a small fix.
- semver `SemVerError`, text `JaroWinkler`/`WordWrap`: the Ruby twins (test/sakelib/*.rb, ref/*.rb)
  use the same names. rspec `To`/`NotTo`/`Expectation`: read as `x.To.eq(...)` in the chain syntax.
  active_support_core_ext `StringExt` & co.: named in the manual. event_emitter `Listener`: public API.
- `X = Struct.new(...)` followed by `class X` in many test/samples: they test the shorthand or field
  rules, and error samples' expected outputs carry line numbers.
- benchmark "no Process.times", logger/rack "no value constants": still true.

## Looked wrong in the language

1. Prelude `Enum.sort_by` goes through `to_a(x)`, which an includer may define with another meaning
   (CSV::Table's `to_a` puts the headers first). The other Enum functions use `each`.
2. The error for `DEBUG = 0` in a module says "only a class made with Struct.new can be assigned to a
   constant" (also inaccurate now that `class` exists).
3. Ports that could use the new built-ins (logger pid, monitor's `Thread.current` instead of `me`,
   pp's `IO.winsize`, getoptlong's POSIXLY_CORRECT) still do without them; that would change behavior.
