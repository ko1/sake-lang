# Requests from the sakelib port (18 libraries)

Source: `sakelib/notes/*.md`. "Asking" counts libraries whose notes request the item (in "Built-ins
requested / lacks / would help", or as an explicit wish in Friction). "+ cite" lists libraries that
name the missing item as the reason for a lost or changed form without requesting it. The effort
column is the compiler of this table's estimate, not the authors'.

Kinds: built-in (a new operation in the standard namespaces), language (spec change), interpreter
bug, checker bug, checker message (a correct report whose message or hint misleads).

## Requests, by number of libraries asking

| Request | Libraries asking | What it enables | Kind | Effort |
|---|---|---|---|---|
| Optional parameters, or arity overloading for user functions | 5: date, digest, zlib, strscan, tsort (+ cite: abbrev, benchmark, cgi, csv, matrix, prime, uri, optparse) | Keeps Ruby's `crc32(s, crc = 0)`, `next_day(n = 1)`, `strptime(s, fmt = "%F")` under one name, with no `_with`/`_matching` names | language | large |
| `String.index(s, t, start)` (start offset) | 4: cgi, csv, json, erb | Scanning left to right without copying the rest or walking `String.chars` | built-in | small |
| `String.gsub(s, re) { \|m\| }` / `String.gsub(s, re, Hash)` | 3: benchmark, cgi, uri | Table-driven escapers and `Tms#format` as one call each (the block is not stored) | built-in | small |
| Nil hint names the source of the nil, not an unrelated field | 3 observed: strscan (repro), erb (`ERB.trim_mode may be nil`), uri (all eight URI fields) | Hints that point at the cause | checker message | medium |
| `Regexp.match(re, s, pos)` / `String.match(s, re, pos)` anchored at pos (`\G`) | 2: shellwords, strscan | StringScanner and `\G` scanners without an O(n) copy per step | built-in | small |
| Value constants, or a function evaluated once | 2: digest, zlib (+ cite: benchmark, logger, date, prime) | Round-constant and CRC tables built once, not per block or call | language | medium |
| List a Record's fields (`Record.to_h`), or a checked "Record of these optional fields" type | 2: csv, json | Rejecting misspelled options (`{colsep: ";"}` is ignored today), and `JSON.generate({a: 1})` | language | medium |
| `String.unpack(s, fmt)` / `String.unpack1` | 2: base64, digest | base64 as one-line wrappers; reading 32-bit words in digests | built-in | small |
| `String.byteslice(s, i, n)` (+ `String.byteindex`) | 2: digest, strscan | Byte positions as in Ruby (`set_pos` inside a char, `get_byte`), pending bytes without rebuilding | built-in | small |
| `String.b(s)` | 2: base64, json | A binary copy without `Array.pack(String.bytes(s), "C*")` | built-in | small |
| `$stderr` / `warn` | 2: logger, optparse | Logging to and printing usage errors on stderr | built-in | small |
| `File.delete` | 2: csv, logger | Tests and programs can remove temporary files | built-in | small |
| Digest / Zlib checksums as built-ins | 2: digest, zlib | Hashing more than a few hundred KB (now about 5-90 KB/s) | built-in | medium |
| Replaceable or private `new` (a constructor hook) | 2: date, optparse | `Date.new(y, m, d)` that validates; per-instance setup | language | medium |
| Non-literal field defaults (a fresh `Array[]`/`Integer[...]` per instance) | 2: digest, optparse | State as one `Integer[]` field (not `h0..h7`); no lazily created nil lists | language | medium |
| Built-in error messages without the `Op: ` prefix (`Hash.fetch: key not found`) | 2: strscan, tsort | Messages identical to Ruby's | interpreter | small |
| Keyword arguments | 1: strscan (+ cite: csv, json, base64, logger, matrix, uri, erb) | `new(s, fixed_anchor:)`, `scan_integer(base:)`; the Record + `_with` convention covers most cases | language | large |
| Record patterns with literal values (`in {symbolize_names: true}`) | 1: json (csv hit the same message) | Reading options without `(o in {k: x}) ? x == true : d` | language | small |
| First-class blocks (callables) | 1: tsort (+ cite: benchmark, csv, logger, optparse, prime) | `TSort.tsort(each_node, each_child)`, stored formatters/converters, `bmbm` | language | large |
| Enumerators (block-less iteration) | 1: tsort (+ cite: prime, date, csv, base64, matrix) | `tsort_each` / `Prime.each(n)` without a block | language | large |
| `Process.clock_gettime(CLOCK_MONOTONIC)` | 1: benchmark | Intervals that do not jump with the wall clock | built-in | small |
| `Process.times` | 1: benchmark | user/system columns in `Benchmark.measure` | built-in | small |
| `GC.start` | 1: benchmark | Isolation between `bmbm` items | built-in | small |
| `Process.pid` | 1: logger | Ruby's default log line (`#pid`) | built-in | small |
| Appending to a file (`File.append` / mode `"a"`) | 1: logger | O(1) log writes (now O(n²) read-and-rewrite) | built-in | small |
| `ARGV` / `Kernel.argv` | 1: optparse | A command-line parser that can read the command line | built-in | small |
| `exit(status)` | 1: optparse | `--help`/`--version` handling and `op.abort` | built-in | small |
| `$0` / program name | 1: optparse | Ruby's default banner | built-in | small |
| `Float::NAN` / `INFINITY` (or `Float.nan`) | 1: json | `allow_nan` without `0.0 / 0.0` | built-in | small |
| `Integer.chr(cp, "UTF-8")` | 1: json | Code point to String without `format("%c", cp)` | built-in | small |
| Hash keys for types with `<=>` (or a declared key function) | 1: date | `h[date] += 1`, Sets of Dates | language | medium |
| Writable Record fields | 1: date | A parse cursor `{pos: 0}` instead of a one-element Tuple | language | medium |
| A non-nil "substring from i" op | 1: date | No `\|\| ""` after every `String.[](s, i, n)` at `--strict=3` | built-in | small |
| A separate namespace for class methods (vs instance methods) | 1: digest | `MD5.hexdigest(s)` and `MD5.hexdigest(md)` as two definitions without a type `case` | language | large |
| `(String \| nil)[]` (typed Arrays with a union element type) | 1: csv | Typed CSV rows (now untyped Arrays) | language | medium |
| `Math.acos` / `Math.asin` | 1: matrix | Bit-exact `Vector#angle_with` | built-in | small |
| `Integer.quo` / `Numeric#quo` | 1: matrix | Ruby's `inverse` as written | built-in | small |
| `Rational.round(r, digits)` | 1: matrix | `Matrix#round(n)` on Rationals | built-in | small |
| `Complex.abs2` | 1: matrix | `Vector#magnitude` as written | built-in | small |
| `Math::PI` / `Math.pi` | 1: matrix | No `Math.atan(1) * 4` | built-in | small |
| Right-operand dispatch or `coerce` | 1: matrix | `2 * m` | language | large |
| `String.dump(s)` | 1: uri | Ruby's error message for a non-ASCII URI (written by hand now) | built-in | small |
| `String.scrub(s)` | 1: uri | `decode_www_form` scrubbing invalid bytes as Ruby | built-in | small |
| `MatchData.byteoffset(m, i)` | 1: strscan | Byte offsets of a match without re-measuring | built-in | small |
| A check (or named fields at `new`) when a field receives unrelated types | 1: uri | Reports field-order mistakes at the `new` call, not in `to_s` | checker message | medium |
| Narrowing after `while x == nil ... end` | 1: date | Loop-until-found without restructuring | checker | medium |
| Narrowing through `\|\|` of `in` tests | 1: erb | `unless (a in Integer) \|\| (a in Float)` guards | checker | medium |
| Narrowing an index read guarded by a field comparison | 1: json | `@src[@pos]` after `@pos >= @len` without `[index-nil]` | checker | medium |
| Narrowing a local reassigned under `if x in T` | 1: uri | `rel = parse(other) if other in String` | checker | medium |
| Setter hint suggests `set_x` (not `Type.pos=(...)`) | 1: strscan (repro) | A hint that compiles | checker message | small |
| `def M.f` inside `module M` hint mentions `module_function :f` | 1: tsort (digest hit the same message) | Following the hint no longer turns f into a mixin function | checker message | small |
| Hint for `Prime.each(10).to_a` should not suggest `Prime.to_a(Prime.each(10))` | 1: prime | No misleading hint | checker message | small |
| A dedicated message for `x in T ? a : b` / `def f = x in T` | 1 asking: date (6 hit it: benchmark, csv, date, json, logger, optparse) | Points at the precedence instead of a bare syntax error | checker message | small |
| Adjacent string literals with interpolation (`"#{a}" "b"`) | 1: uri | Ruby's implicit concatenation across lines | interpreter | small |
| Document that `Array.pack` passes `"m"`/`"m0"` through | 1: base64 (digest uses `"m0"`) | Users find base64 packing (the docs list only `C*`, `U*`) | docs | small |

## Interpreter and checker bugs (with repros)

All six repros were run with `bin/sake --strict` on 2026-10-03 and still reproduce.

| Bug | Kind | Repro | Found by |
|---|---|---|---|
| `a[start, length]` (`Array.[](a, i, n)`) is typed as the element, not as an Array | checker bug | `sakelib/notes/benchmark_bug_array_slice_type.sake` | benchmark |
| `if x in T ... else ... end` keeps the dead else branch's result type (`case x in T ... in U` does not) | checker bug | `sakelib/notes/date_bug_if_in_else.sake` | date |
| `p` of a Hash with a non-identifier Symbol key prints `{:"dry-run" => true}` (Ruby 3.4+: `{"dry-run": true}`) | interpreter bug | `sakelib/notes/optparse_bug_symbol_key_inspect.sake` | optparse |
| `ss.pos = 1` hint suggests `Type.pos=(ss, ...)`, which is not valid syntax | checker message | `sakelib/notes/strscan_bug_setter_hint.sake` | strscan |
| Nil hint blames a field (`Box.v may be nil`) when the nil comes from `return nil` | checker message | `sakelib/notes/strscan_bug_nil_hint_blames_field.sake` | strscan |
| Absolute `require "/path/x"` is joined to the requiring file's directory | interpreter bug | `sakelib/notes/uri_bug_absolute_require.sake` | uri |

Already fixed during the port (no repro kept): `require "x"` loaded the requiring file itself when
it was named `x.sake` (hit by csv, cgi, date, matrix, prime, optparse, strscan). Fixed in commit
ea484f6.
