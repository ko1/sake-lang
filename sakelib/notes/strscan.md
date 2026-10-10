# strscan (StringScanner)

`require "strscan"` → `sakelib/strscan.sake`. Test: `test/sakelib/strscan.{sake,rb}` (identical output).

`StringScanner` is a Struct type (`class StringScanner` with `attr_reader ...`); every Ruby instance method
is an operation with the scanner first. It includes `Indexable` (for `ss[1]`) and `Bitwise` (for
`ss << "x"`). Ruby's `StringScanner::Error` is `StringScanner::Error` (nested since 2026-10-10; it was
`ScanError`, Ruby's old top-level alias, while Sake had no nested names; the alias is not provided).

## API

| Ruby | Sake | |
|---|---|---|
| `StringScanner.new(s)` | `StringScanner.new(s)` | same |
| `StringScanner.new(s, fixed_anchor: true)` | `StringScanner.new(s, fixed_anchor: true)` | same (2026-10-05: a keyword to `new`; `\A`, `^`, look-behind see the whole String) |
| `ss.scan(re_or_str)` | `StringScanner.scan(ss, p)` | same |
| `ss.scan_until(p)` | `StringScanner.scan_until(ss, p)` | same |
| `ss.skip(p)` / `ss.skip_until(p)` | `StringScanner.skip(ss, p)` / `skip_until` | same (byte lengths) |
| `ss.match?(p)` | `StringScanner.match?(ss, p)` | same |
| `ss.check(p)` / `ss.check_until(p)` | `StringScanner.check(ss, p)` / `check_until` | same |
| `ss.exist?(p)` | `StringScanner.exist?(ss, p)` | same |
| `ss.scan_full(p, adv, str)` / `search_full` | `StringScanner.scan_full(ss, p, adv, str)` / `search_full` | same (result type is `String \| Integer \| nil`) |
| `ss.getch` | `StringScanner.getch(ss)` | same |
| `ss.get_byte` / `ss.scan_byte` | — | missing (see below) |
| `ss.scan_integer` | `StringScanner.scan_integer(ss)` | same |
| `ss.scan_integer(base: 16)` | `StringScanner.scan_integer(ss, base: 16)` | same (optional `0x`; other bases raise Ruby's ArgumentError) |
| `ss.peek(n)` | `StringScanner.peek(ss, n)` | same (n bytes, may cut a character, as Ruby) |
| `ss.peek_byte` | `StringScanner.peek_byte(ss)` | same |
| `ss.unscan` | `StringScanner.unscan(ss)` | same (raises `StringScanner::Error`) |
| `ss.pos` / `ss.pointer` | `StringScanner.pos(ss)` / `pointer` | same (bytes) |
| `ss.pos = n` / `ss.pointer = n` | `StringScanner.set_pos(ss, n)` | differs: name; `n` inside a multibyte character raises `ArgumentError` |
| `ss.charpos` | `StringScanner.charpos(ss)` | same |
| `ss.eos?` / `ss.rest?` | `StringScanner.eos?(ss)` / `rest?` | same |
| `ss.beginning_of_line?` / `ss.bol?` | `StringScanner.beginning_of_line?(ss)` / `bol?` | same |
| `ss.reset` / `ss.terminate` | `StringScanner.reset(ss)` / `terminate` | same |
| `ss.string` | `StringScanner.string(ss)` | same |
| `ss.string = s` | `StringScanner.set_string(ss, s)` | differs: name |
| `ss.concat(s)` / `ss << s` | `StringScanner.concat(ss, s)` / `ss << s` | differs: Ruby appends to the same String object, Sake replaces the field with a new String |
| `ss.rest` / `ss.rest_size` | `StringScanner.rest(ss)` / `rest_size` | same |
| `ss.matched?` / `ss.matched` / `ss.matched_size` | `StringScanner.matched?(ss)` / … | same |
| `ss.pre_match` / `ss.post_match` | `StringScanner.pre_match(ss)` / `post_match` | same |
| `ss[i]`, `ss["name"]`, `ss[:name]` | `ss[i]` or `StringScanner.[](ss, i)` | same (unknown name: `IndexError`, message prefixed by Sake for regexp matches) |
| `ss.captures` / `ss.size` / `ss.named_captures` | `StringScanner.captures(ss)` / … | same |
| `ss.values_at(*is)` | `StringScanner.values_at(ss, *is)` | same (2026-10-05) |
| `ss.fixed_anchor?` | `StringScanner.fixed_anchor?(ss)` | same |
| `ss.inspect` / `p(ss)` | `p(ss)` | same for ASCII; differs for non-ASCII (see below) |
| `getbyte`, `peep`, `clear`, `empty?`, `restsize` (obsolete), `must_C_version` | — | missing (obsolete) |

43 operations ported.

## How it works, and what differs

- **Matching at the pointer** (phase 2). `scan`/`skip`/`check`/`match?` match
  `\G(?flags:source)` with `Regexp.match(re, string, charpos)`; the `_until` forms match the pattern
  itself from charpos. The wrapped Regexp is built once per pattern (a table made by `once`, keyed by
  `Kernel.inspect(pattern)`, since a Regexp cannot be a Hash key; flags are rebuilt from the inspect,
  and `x` gets a newline before the `)` so a trailing comment does not swallow it). No copy, and a
  failing anchored scan stops at the pointer instead of searching the rest.
  A pattern that looks before the pointer (`\A`, `^`, `\b`, `\B`, `\G`, look-behind; found by a
  conservative test of its source) must see the String as starting at the pointer, as in Ruby's
  default (`fixed_anchor: false`); `Regexp.match` with a position sees the whole String, so those
  patterns still go the phase 1 way: match a copy of the rest, accept a match starting at 0.
- **Bytes vs characters.** Ruby's `pos`, `skip`'s result, `matched_size`, `rest_size` count bytes.
  Sake's String slicing and `Regexp.match` positions count characters. The scanner keeps both a
  character position (for matching) and a byte position (to report), updated together. So:
  - `set_pos` must land on a character boundary (Ruby allows a position inside a character and then
    scans broken bytes); otherwise `ArgumentError`.
  - `get_byte` and `scan_byte` are not ported: they move the pointer inside a character.
  - `peek(n)` is `String.byteslice` (phase 1: `String.bytes` + `Array.pack` + `force_encoding`), which
    gives Ruby's result, including a cut character. `rest` is a byteslice too, and `eos?`/`rest_size`
    compare byte counts instead of measuring the String in characters.
- **inspect.** Shows 5 characters on each side with `Kernel.inspect`; Ruby shows 5 bytes with
  `String#dump`. Same for ASCII text, differs for multibyte text.
- **Setters.** `ss.pos = n` cannot be written: there are no calls on values, and an operation named
  `pos=` cannot be called (`StringScanner.pos=(ss, n)` is a syntax error). They are `set_pos`,
  `set_string`, following the Struct accessor convention (`set_x`).

## Built-ins Sake lacks (requests)

- ~~`Regexp.match(re, s, pos)`~~ and ~~`String.byteslice`~~: added, used in phase 2.
- A byte-position `Regexp.match` (or MatchData byte offsets): would let the scanner keep only the
  byte position, allow `set_pos` inside a character, `get_byte`, and `scan_byte`.
- A Regexp usable as a Hash key (or `Regexp.to_s`, Ruby's `(?flags:source)`): the `\G` table is keyed
  by `Kernel.inspect`, and the flags are parsed out of it.
- `MatchData.byteoffset(m, i)`: byte offsets of a match without re-measuring the matched text.
- (Language) ~~keyword parameters~~: `scan_integer(base:)` now takes one. `new(s, fixed_anchor:)`
  remains: `T.new` is the constructor generated from the fields and cannot take keywords.

## Friction

- Wrote one `do_scan(ss, pattern, succptr, getstr, headonly)` returning the String or its byte
  length depending on `getstr`, as Ruby's C does → `strscan.sake:111: String.to_i: argument 1 must
  be String, but can be Integer [type]` in `scan_integer`, which only calls with `getstr = true` →
  made `do_scan` always return the String and convert in the wrappers (`skip(ss, p) =
  len(do_scan(...))`). A flag argument does not specialize the result type; a function per result
  type does. Only `scan_full`/`search_full` keep Ruby's flag, and their results are a union.
- A user's `ss.pos = 1` → `hint: ... call an operation with its type: Type.pos=(ss, ...)`, which is not
  valid syntax (Prism: "unexpected write target") → named the setter `set_pos`. The hint could
  suggest `set_pos`, as it does for Struct fields. Repro: `strscan_bug_setter_hint.sake`.
- A user's `String.upcase(StringScanner.scan(ss, /a/))` under `--strict` is rightly rejected, but
  the hint says `StringScanner.mstr may be nil (nil is stored at line 2, 20)`: an internal field
  unrelated to the value (the nil comes from `return nil` in `do_scan`). Repro:
  `strscan_bug_nil_hint_blames_field.sake`.
- Built-in errors carry a prefix Ruby does not have: `MatchData.[]: undefined group name reference: x`
  (Ruby: `undefined group name reference: x`). The test compares the suffix there.
- `require "strscan"` in `test/sakelib/strscan.sake` used to find the test file itself; fixed in
  the loader during this work (the test now uses the plain form).
- What felt good: `include Indexable` / `include Bitwise` made `ss[1]` and `ss << "x"` read as in Ruby;
  `case pattern in String ... in Regexp` covers both pattern kinds, and a user passing an Integer
  pattern gets `case/in: no in branch matches Integer [type]` before running (at the library line,
  with the user's line in the hint chain). The first draft ran under `--strict` with only the
  `getstr` problem above.

## Phase 2

- **No names to restore**: Ruby's strscan has no optional positional arguments in use (`new`'s `dup`
  is obsolete; `fixed_anchor:` and `scan_integer(base:)` are keywords).
- **Scans** use `Regexp.match(re, s, pos)` with `\G`-wrapped patterns built once (`once` table), as
  above; `String` patterns compare a `byteslice` at the pointer (anchored) or use
  `String.index(s, t, charpos)`. `set_pos` finds the character index with `byteslice` + `length`
  (phase 1 walked `each_char`). `peek` and `rest` are byteslices. `matched_ok` and `mbeg` fields are
  gone (derived from `mstr` and `mend`).
- **Tests added**: flags `i`, `x` (with a comment), `m`; a negated class (anchored path);
  `\b`, `^`, `\A`, look-behind at a pointer > 0 (copy path); `scan_until` with a String over
  multibyte text.
- **Speed** (`bin/sake --strict`, CPU user+sys, 3 runs, shared machine at load ~35 on 16 cores):
  - `phase2/bench_strscan.sake` (tokenize `"ab 12 "` x 4000, 24 KB, ~36,000 scan calls): before
    11.84 / 11.78 / 11.86 s, after 11.72 / 11.37 / 11.72 s. **No gain**: each call costs ~0.3 ms of interpreter
    work (user calls, built-in calls and field writes at ~10 µs each), and the copy of at most 24 KB
    is noise beside that. At 4x the size (`bench_strscan_16k.sake`, 1 run each) both are linear:
    44.7 s before, 46.2 s after.
  - `phase2/bench_strscan_long.sake` (the copy-sensitive case: 3000 steps at the head of a 1 MB
    String, each a failing `check(/b/)` and a `scan(/a/)`): before 5.60 / 5.41 / 5.64 s, after
    2.43 / 2.49 / 2.46 s.

## Keyword arguments

- `scan_integer(ss, base: 10)` takes Ruby's keyword; `base: 16` scans `[+-]?(0x)?\h+` and converts
  with `String.hex` (`String.to_i` has no base argument). New test cases: hex with and without
  `0x`, a sign, `"+0x"` backing off to `"+0"`, and `base: 8` → `Unsupported integer base: 8,
  expected 10 or 16`. A misspelled keyword is a static error:
  `StringScanner.scan_integer(ss, bas: 16)` → `error: StringScanner.scan_integer has no keyword
  parameter `bas`` / `hint: did you mean `base:`?`.

## Review 2026-10-05 (initialize, `=>`, exception class)

- `def initialize(ss)`: `@string => String` (Ruby raises TypeError for `StringScanner.new(1)`; Sake
  raises NoMatchingPatternError) and resets the pointer, so the internal fields given to `new` by
  mistake cannot start the scanner elsewhere. `set_string` asserts `s => String` likewise.
- `ScanError` is `class ScanError < Exception` (was `ScanError = Exception.new`). 2026-10-10: it is now `StringScanner::Error`, nested as Ruby's; the top-level alias `ScanError` is not provided.

## 2026-10-05

- `StringScanner.new(s, fixed_anchor: true)`: a field `fixed_anchor = false`, given by keyword as
  Ruby's. With it every Regexp is matched in place (`\G`-wrapped for the anchored scans), so `\A`,
  `^`, `\b`, look-behind see the String before the pointer; without it, the copy-of-the-rest path as
  before. The `\G` table is keyed by `[inspect, fixed]`.
- `values_at(ss, *is)` with a rest parameter.
- Internal state is `private attr_reader` (`fixed_anchor`, `cpos`, `bpos`, `prev_*`, `mend`, `md`,
  `mstr`): no `StringScanner.mstr` outside; `string` stays a reader (the duplicate `def string` is gone).
  `@bpos += n` where it was `@bpos = @bpos + n`.
- Tests: fixed_anchor (`\Ab` and `^b` fail at pointer 1, look-behind sees the `a`, `^c` after a
  newline), `fixed_anchor: false`, `values_at` before a match, with negative/out-of-range indexes, and
  with none.
- Still not Ruby's: `pos=`/`string=` are `set_pos`/`set_string` (not fields); `StringScanner.new(1)`
  raises `NoMatchingPatternError`, not `TypeError` (no class name of a value to build Ruby's message);
  `get_byte`/`scan_byte` (byte pointer inside a character).
