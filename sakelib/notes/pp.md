# pp (PP)

`require "pp"` → `sakelib/pp.sake` (requires `prettyprint`). Test: `test/sakelib/pp.{sake,rb}` (identical output:
nested Hash/Array at widths 79, 40, 20, 1; a 30-element Array; scalars; empty containers; Sets; multi-line
Strings; odd Symbol keys; Struct values; String and IO outputs; `singleline_pp`; `pretty_inspect`; a type's
own `pretty_print`; `seplist`/`pp_hash` directly; an error raised inside the block).

Ruby's `PP` is a subclass of `PrettyPrint` whose instance methods (`q.pp(v)`, `q.comma_breakable`, `q.seplist`,
`q.pp_hash`) walk a value, and whose class methods (`PP.pp(obj, out, width)`) run such a walk. Sake cannot
give `PP.pp` both meanings, so the walk is added to the type `PrettyPrint` (`class PrettyPrint` reopened in
pp.sake) and `module PP` has the class methods. A block given to `PrettyPrint.format` can call
`PrettyPrint.pp(q, v)` on any built-in value.

## API

| Ruby | Sake | |
|---|---|---|
| `PP.pp(obj, out = $stdout, width = PP.width_for(out))` → out | `PP.pp(obj, out = IO.stdout, width = 79)` → out | same; `out` is a String (appended) or an IO (written at the end) |
| `PP.singleline_pp(obj, out = $stdout)` | `PP.singleline_pp(obj, out = IO.stdout)` | same |
| `obj.pretty_inspect` | `PP.pretty_inspect(obj, width = 79)` | same (Ruby's width is fixed at 79; here optional) |
| — | `PP.pp_to_s(obj, width = 79)` | the brief's name for `pretty_inspect` |
| `PP.width_for(out)` | `PP.width_for(out)` | differs: always 79 (no `winsize`, no `ENV`) |
| `PP.sharing_detection`, `=` | — | missing: needs object identity (below) |
| `q.pp(v)` | `PrettyPrint.pp(q, v)` | same for Array, Tuple, Hash, Set, String; everything else is `Kernel.inspect` in one piece (below) |
| `q.comma_breakable` | `PrettyPrint.comma_breakable(q)` | same |
| `q.seplist(list, sep_proc = comma_breakable, iter = :each) { \|v\| }` | `PrettyPrint.seplist(q, list, sep = ",") { \|v\| }` | differs: `sep` is the text before a breakable (a proc in Ruby); `list` is an Array (`Hash.to_a(h)` for a Hash, the block takes `\|k, v\|`) |
| `q.pp_hash(h)` | `PrettyPrint.pp_hash(q, h)` | same (Ruby 3.4 style: `k: v`, `"k" => v`) |
| `q.pp_hash_pair(k, v)` | `PrettyPrint.pp_hash_pair(q, k, v)` | same, including the quoting rule for Symbol keys |
| `q.group_sub`, `q.nest`, ... | from prettyprint | same |
| `q.object_group(obj) { }`, `q.pp_object(obj)`, `object_address_group` | — | missing: need the class name / instance variables of any value (no reflection); write `group(q, 1, "#<Point", ">")` |
| `q.guard_inspect_key`, `check_inspect_key`, `pop_inspect_key`, `pretty_print_cycle` | — | missing: cycle detection (below) |
| `obj.pretty_print(q)` as a protocol | `Point.pretty_print(pt, q)` called by name | differs (below) |
| `Struct#pretty_print`, `Data#pretty_print`, `Range#pretty_print`, `MatchData`, `Object` ... | `Kernel.inspect` | differs when the value does not fit the width (below) |
| `Kernel#pp(*objs)` | `pp(x)` (built-in, one line) | not this library |

12 operations: 5 of `PP` (`pp`, `singleline_pp`, `pretty_inspect`, `pp_to_s`, `width_for`), 7 added to
`PrettyPrint` (`pp`, `pp_array`, `pp_string`, `comma_breakable`, `seplist`, `pp_hash`, `pp_hash_pair`;
`pp_array`/`pp_string` are Ruby's `Array#pretty_print`/`String#pretty_print`).

## What differs from Ruby and why

- **Dispatch is by type tag, closed.** `PrettyPrint.pp(q, v)` is `case v in Array ... in Tuple ... in Hash ...
  in Set ... in String ... else text(q, Kernel.inspect(v))`. Ruby calls `v.pretty_print(q)`, which any class can
  define. Sake has no open protocol a library can call on a value of a type it does not know (a mixin
  dispatches only to types that include it, and the `else` branch holds Integers, nil, ... which do not), so a
  user's type is printed by calling its own function: `PrettyPrint.format(out, w) { |q| Point.pretty_print(pt, q) }`.
  A Point inside an Array still prints as `Kernel.inspect`.
- **Struct values, Records, Ranges are one piece.** Ruby breaks `#<struct S x=1, y=[...]>` across lines when it
  does not fit; here `Kernel.inspect` gives the same text in one line. Same text when it fits (tested); differs
  when it does not. Records cannot be iterated (no `Record.to_h`/`each`), so `{x: 1, y: [1, 2]}` is printed in
  one piece too; a Hash with Symbol keys breaks as Ruby's.
- **No cycle detection.** Ruby prints `[...]` for an Array that contains itself (by `object_id`). Sake has no
  identity test, and a cyclic Array would recurse until `SystemStackError`. Not reproducible in the test (it
  cannot be rescued).
- **`seplist`'s separator is a String.** Ruby takes a proc (`lambda { q.text ","; q.breakable }`); blocks are
  not values and `seplist` already takes the element block, so `sep` is the text written before the breakable.
  Ruby's `Struct#pretty_print` idiom (`text ","` with the breakable at the start of each element) is written
  by hand (see `Point.pretty_print` in the test).
- **`PP.pp(obj, out)` with an IO writes the finished String** (Ruby writes as it goes). Same output.
- **Width.** Ruby's default is the terminal width - 1 for a tty, else 79; here 79 always.

## Built-ins Sake lacks (requests)

- `Record.to_h(r)` (or `Record.each(r) { |k, v| }`, `Record.keys`): to walk a Record generically. pp's dispatch
  reaches `in Record` and has nothing to do with it but `Kernel.inspect`.
- An identity test, `Kernel.equal?(a, b)` or `Kernel.object_id(x)`: cycle detection (`[...]`) and Ruby's
  `sharing_detection` need "the same object", which `==` on containers is not.
- `Symbol.inspect` is `Kernel.inspect`; fine. Nothing else was missing: `String.lines`, `Hash.to_a`, `Set.to_a`,
  `Tuple.to_a`, `IO.write` covered the rest.

## Friction

- Ruby's `PP#pp(obj)` (instance) and `PP.pp(obj, out, width)` (class) → in Sake both would be `PP.pp`, and a
  namespace holds one `pp` → the walk became `PrettyPrint.pp(q, v)` (a reopened `class PrettyPrint` in
  pp.sake, which Sake allows across files). A reader coming from Ruby looks for it under `PP`.
- A user's `PP.pp(Hash[a: 1], 40)` (the width where `out` goes; Ruby would fail at run time with
  `undefined method '<<' for an instance of Integer`) → `pp.sake:117:5: error: case/in: no `in` branch matches
  Integer [type] / hint: reached by the call at line 2 → pp.sake:96`: caught before running, but the error is at
  the library's `case out`, and the user's line is only in the hint chain. The report lands where the type is
  consumed; a `case` at the top of `PP.pp` would move it only one hop closer.
- `seplist(q, Hash.to_a(h)) { |k, v| ... }`: the block's `|k, v|` takes the `[k, v]` Tuple apart through
  `yield(v)`, as in Ruby. Worked at once; worth knowing that destructuring survives a `yield` of one Tuple.
- Wanted Ruby's `obj.pretty_print(q)` protocol → no way to express "call `pretty_print` on whatever type `v`
  has" in a library that does not know the type (spec §5.6: a mixin's first argument must include the module,
  and the fallback branch's types do not) → documented the direct call. This is the one real loss against Ruby's
  pp: a user's type cannot take part in the generic walk.
- What felt good: `case v in Array ... in Tuple ... in Hash ... in Set ... in Record ... in String` is the whole
  dispatch, and the Ruby 3.4 Symbol-key rule ported as a one-line regexp over `Kernel.inspect(k)`. The first
  run of the nested Hash at widths 40 and 20, the odd Symbol keys and the multi-line String matched Ruby
  byte for byte.

## Later the same day (2026-10-09)

Kernel.equal?(a, b) is built in (an identity test for cycle detection); Record.to_h is still missing.
