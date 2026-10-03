# strscan (StringScanner)

`require "strscan"` → `sakelib/strscan.sake`. Test: `test/sakelib/strscan.{sake,rb}` (identical output).

`StringScanner` is a Struct type (`class StringScanner < {reader: [...]}`); every Ruby instance method
is an operation with the scanner first. It includes `Indexable` (for `ss[1]`) and `Bitwise` (for
`ss << "x"`). Ruby's `StringScanner::Error` is `ScanError` (Ruby's old top-level alias, still
defined): Sake has no nested names.

## API

| Ruby | Sake | |
|---|---|---|
| `StringScanner.new(s)` | `StringScanner.new(s)` | same |
| `StringScanner.new(s, fixed_anchor: true)` | — | missing (no keyword arguments) |
| `ss.scan(re_or_str)` | `StringScanner.scan(ss, p)` | same |
| `ss.scan_until(p)` | `StringScanner.scan_until(ss, p)` | same |
| `ss.skip(p)` / `ss.skip_until(p)` | `StringScanner.skip(ss, p)` / `skip_until` | same (byte lengths) |
| `ss.match?(p)` | `StringScanner.match?(ss, p)` | same |
| `ss.check(p)` / `ss.check_until(p)` | `StringScanner.check(ss, p)` / `check_until` | same |
| `ss.exist?(p)` | `StringScanner.exist?(ss, p)` | same |
| `ss.scan_full(p, adv, str)` / `search_full` | `StringScanner.scan_full(ss, p, adv, str)` / `search_full` | same (result type is `String \| Integer \| nil`) |
| `ss.getch` | `StringScanner.getch(ss)` | same |
| `ss.get_byte` / `ss.scan_byte` | — | missing (see below) |
| `ss.scan_integer` | `StringScanner.scan_integer(ss)` | same (base 10 only) |
| `ss.scan_integer(base: 16)` | — | missing (no keyword arguments) |
| `ss.peek(n)` | `StringScanner.peek(ss, n)` | same (n bytes, may cut a character, as Ruby) |
| `ss.peek_byte` | `StringScanner.peek_byte(ss)` | same |
| `ss.unscan` | `StringScanner.unscan(ss)` | same (raises `ScanError`) |
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
| `ss.values_at(*is)` | — | missing (a user function cannot take a rest parameter) |
| `ss.fixed_anchor?` | `StringScanner.fixed_anchor?(ss)` | same (always false) |
| `ss.inspect` / `p(ss)` | `p(ss)` | same for ASCII; differs for non-ASCII (see below) |
| `getbyte`, `peep`, `clear`, `empty?`, `restsize` (obsolete), `must_C_version` | — | missing (obsolete) |

43 operations ported.

## How it works, and what differs

- **Matching at the pointer.** Sake has no "match at position" (`Regexp#match(s, pos)` with `\G`, or
  Onigmo's `onig_match`). Each scan slices the rest of the String and matches it unanchored; for
  `scan`/`skip`/`check`/`match?` the match is accepted only if it starts at 0. This is exact
  (the leftmost match starts at 0 whenever any match there exists, and the engine tries position 0
  first, so it is the same match), and `\A` and `^` match at the pointer as in Ruby's default
  (`fixed_anchor: false`). Look-behind cannot see before the pointer, also as Ruby's default.
  Cost: each call copies the rest (O(n)), and a failed anchored scan searches the whole rest.
  Single runs of a two-token-per-"ab " loop, on a machine at load ~38 (so noisy): 2000 / 4000 / 8000 /
  16000 repetitions took 6.4 / 8.4 / 15.6 / 26.8 s (startup ~1.8 s). That is about linear at this
  size: interpreter overhead per call (~0.8 ms) hides the copy. Not measured further.
- **Bytes vs characters.** Ruby's `pos`, `skip`'s result, `matched_size`, `rest_size` count bytes.
  Sake's String slicing counts characters, and there is no `byteslice`. The scanner keeps both a
  character position (for slicing) and a byte position (to report), updated together. So:
  - `set_pos` must land on a character boundary (Ruby allows a position inside a character and then
    scans broken bytes); otherwise `ArgumentError`.
  - `get_byte` and `scan_byte` are not ported: they move the pointer inside a character.
  - `peek(n)` is built from `String.bytes` + `Array.pack("C*")` + `String.force_encoding("UTF-8")`,
    which gives Ruby's result, including a cut character.
- **inspect.** Shows 5 characters on each side with `Kernel.inspect`; Ruby shows 5 bytes with
  `String#dump`. Same for ASCII text, differs for multibyte text.
- **Setters.** `ss.pos = n` cannot be written: there are no calls on values, and an operation named
  `pos=` cannot be called (`StringScanner.pos=(ss, n)` is a syntax error). They are `set_pos`,
  `set_string`, following the Struct accessor convention (`set_x`).

## Built-ins Sake lacks (requests)

- `Regexp.match(re, s, pos)` (or `match_at`, anchored at `pos`): scanning without copying the rest
  and without searching past the pointer. This is the one strscan is built around.
- `String.byteslice(s, start, len)` (and `String.byteindex`): byte positions as Ruby defines them;
  would allow `set_pos` inside a character, `get_byte`, `scan_byte`, and a simpler `peek`.
- `MatchData.byteoffset(m, i)`: byte offsets of a match without re-measuring the matched text.
- (Language) optional and keyword parameters: `new(s, fixed_anchor:)`, `scan_integer(base:)`.

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
