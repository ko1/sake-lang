# hana (JSON Pointer, JSON Patch)

`require "hana"` → `sakelib/hana.sake` (ported from the hana gem 1.3.7: RFC 6901 and RFC 6902). Test: `test/sakelib/hana.{sake,rb}`
(the RFCs' examples, more operations, and every error; identical output).

Documents are plain JSON values as `JSON.parse` returns them; a patch changes the document in place,
as Ruby's does.

## API

| Ruby | Sake | |
|---|---|---|
| `Hana::Pointer.new(path)` | `Hana::Pointer.new(path)` | same (parses at once; `FormatError`) |
| `ptr.eval(doc)` | `Hana::Pointer.eval(ptr, doc)` | same |
| `Hana::Pointer.eval(list, doc)` | `Hana::Pointer.eval(list, doc)` | same (one operation for both, see below) |
| `Hana::Pointer.parse(path)` | `Hana::Pointer.parse(path)` | same |
| `ptr.each` / `ptr.to_a` / `ptr.map` (Enumerable) | `Enum.to_a(ptr)`, `Enum.map(ptr) { }` | same (`include Enum`) |
| `Hana::Patch.new(ops).apply(doc)` | `Hana::Patch.apply(Hana::Patch.new(ops), doc)` | same |
| `Hana::Patch::FailedTestException#path / #value` | `Hana::Patch::FailedTestException.path(e)` / `.value(e)` | same |
| the 7 `Hana::Patch::*Exception` / `IndexError` / `InvalidPath`, `Hana::Pointer::FormatError` | same names | same, without the hierarchy |
| `Hana::VERSION` | `Hana.version` | differs: no value constants |

13 operations (7 public, the 6 patch operations private in Ruby but callable here).

## What differs and why

- **One `eval`.** Ruby has `Pointer#eval(object)` and `Pointer.eval(list, object)`. In Sake one name
  is one function, so `Pointer.eval(x, object)` takes either a Pointer or a parsed list (a `case`).
- **`send(op, ins, doc)`** is a `case` on the operation's name.
- **Exception hierarchy.** In Ruby every patch error is a `Hana::Patch::Exception` (and FormatError a
  `Hana::Pointer::Exception`); `rescue Hana::Patch::Exception` catches them all. Sake's exceptions have no
  hierarchy: rescue each class. The nested names `Exception` and `IndexError` (which shadow the built-in
  names inside `Hana`) work.
- **NoMethodError.** Ruby relies on NoMethodError in places (`src.fetch` on a non-Hash in `copy`,
  `obj.key?` on a non-Hash in `remove`, `dest.replace` on a number) and rescues it; here the types are
  tested with `case` and the same Hana errors are raised. `dest.replace(obj)` on a number, true or false
  (Ruby: NoMethodError) raises TypeError.
- **Pointer.eval on a scalar.** Ruby indexes whatever it reaches: a String gives a substring
  (`"abc"["b"]`), an Integer raises TypeError. Ported the same (a String through `String.slice`; see the
  bug below).

## Bugs found

- `notes/hana_bug_string_index_string.sake`: `s["b"]` (String#[] with a String) is rejected —
  `Indexable.[]: the index must be Integer, but is String` — although the cheat sheet lists
  `String.[](x, Any, [Integer])`. `String.slice(s, "b")` works and is used instead.

## Friction

- `o[part]` with `o` narrowed to String → the bug above → `String.slice(o, part)`.
- `Array.each(@is)` → `Array.each: argument 1 must be Array, but can be true|false | Float | ... | Hash`
  (the patch list is a JSON value) → `list = @is; list => Array`. A clear message: it says which field
  holds what, and where it was written.
- `case dest in Hash ... in Array ... end` for Ruby's `dest.replace(obj)` → `case/in: no in branch
  matches true|false | Float | Integer | String` → added `in String` (String#replace) and `else`.
  The checker found Ruby's NoMethodError path.
- I first read the String-index error above as coming from `esc[m]` (a `once` Hash in a `gsub` block)
  and rewrote that line; the message's column pointed at `o[part]`, and `esc[m]` is fine (reverted).

## Size

The gem's Ruby: 196 lines (without comments and blank lines). Sake: 223 lines (287 with comments); the
growth is the `case`s that replace NoMethodError and the narrowing of JSON values (`ins => Hash`).
