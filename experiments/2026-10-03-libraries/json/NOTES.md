# json library: notes

Sake at commit `909cd19`. Every program was run with `bin/sake --strict out/X.sake` and exits 0;
their outputs are in `out/*.txt`. Work took about 75 minutes.

## API sketch

JSON values are **plain Sake values**: object -> `Hash` (String keys), array -> `Array`, string ->
`String`, number -> `Integer` or `Float`, `true`/`false`, null -> `nil`.

- `Json.parse(s)` -> value; raises `JsonError` (`message`, `pos`).
- `Json.generate(v)` (compact) and `Json.pretty(v)` (2-space indent) -> String. `JsonRaw.new(text)`
  is emitted as is. NaN/Infinity and non-String keys raise `JsonError`.
- `Json.dig(v, path)`: `path` is an Array of String keys and Integer indexes; nil when missing.
- Typed getters, which raise `JsonError` with the path (`"timeouts.connect: expected integer, got 1.5"`):
  `Json.str / int / num (Integer becomes Float) / bool / arr / obj (v, path)`,
  `Json.strs / ints (v, path)` -> `String[]` / `Integer[]`,
  `Json.str_or / int_or / bool_or (v, path, default)` for a missing value.

Clients: `client_config` (typical: read a config, typed values, decode into a `class Upstream`),
`client_transform` (recursive key renaming, sum numbers, count kinds, add fields),
`client_records` (unusual: Struct values <-> JSON), `client_roundtrip` (stress: 17 round-trips,
11 bad inputs, 200-deep nesting, a 228 KB document).

## How heterogeneous values felt

The checker infers the JSON type by itself, with no annotation:
`Hash@L54[String => true|false | Float | Integer | nil | String | Array@L77[...] | Hash@L54]`.
That is accurate and is the main reason the library works without its own value type. The
consequence is that **every value that comes out of `parse` or `dig` is the full union**, so a
client cannot do anything with it except pattern-match it or pass it through a typed getter. That
pushed me to the right design (decode at the boundary into Strings/Integers/Structs, see
`client_config` and `client_records`), and inside the library `case v in Hash ... in Array ...` read
naturally. Recursive walkers (`rename_keys`, `sum_numbers`, `count_kinds`) passed `--strict` on the
first try. The cost is in the messages (entry 6) and in two narrowing gaps (entries 3 and 4).

## Friction log

1. [type-check-false-report] `def string(ps)` looped with `while true ... return Array.join(out, "") ... end`
   → in the client, `String.split: argument 1 may be nil (nil | String) [nil]` with
   `hint: reached by the call at line 378 → line 325` (a Hash key from `parse`, typed `nil | String`)
   → partly: the message pointed at the client, not at the library function whose fall-through
   `while` gives nil → rewrote the loop as `while @pos < @len ... end; fail(ps, "unterminated string")`
   → 2 attempts. (`--types` showed the key type `nil | String`, which is how I found it.)
2. [type-check-caught-bug] `Json.generate(Hash["p" => Point.new(1, 2)])` (a Struct into the encoder)
   → `case/in: no \`in\` branch matches Point [type]`, `hint: reached by the call at line 342 → line 192 → line 215`
   → yes → convert with `Point.to_json_value` first → 1. Caught before running, inside the library.
3. [bug] To let user Structs encode themselves, I added a mixin hook: `module JsonEncodable` with
   `def to_json_value(x) = raise(NotImplementedError)`, and in `emit`
   `else emit(JsonEncodable.to_json_value(v), ...)` after `in true then` / `in false then`
   → `JsonEncodable.to_json_value dispatches on its first argument, which is true|false; the types that include JsonEncodable are JsonRaw [type]`
   → no: `true` and `false` were matched by earlier branches. Literal patterns `true`/`false` (even
   `in true | false`, or `if v != true && v != false`) do not remove `true|false` from what the
   `else` sees, and there is no `Boolean` type to name in a pattern → dropped the hook; clients call
   their own `T.to_json_value` → 4 attempts. Repro: `bug_bool_else_narrowing.sake`. The same gap gives
   a level-3 `[exhaustive]` report on `emit`'s case (`no in branch matches some values of true|false`)
   although both values have a branch.
4. [type-check-false-report] `type_error(path, "string", x) unless x in String; Array.push(out, x)`
   into `String[]` (`type_error` always raises) → `Array.push: an element must be String, but can be true|false | Float | ...`
   → partly: nothing says the helper is not counted as an exit → `if x in String then push else type_error`
   → 2 attempts. An inline `raise ... unless x in String` narrows; a helper that only raises does not.
   Repro: `bug_noreturn_helper_no_narrowing.sake`. The parser's `fail(ps, msg) unless h` has the same
   gap (5 `[index-nil]` reports at `--strict=3`, none at level 2).
5. [language-limit] A library hook that no program uses breaks every program: with
   `JsonEncodable` in lib.sake and no including type, any client gets
   `JsonEncodable.to_json_value is a mixin function, and no type includes JsonEncodable` →
   yes → made `JsonRaw` include it (a real feature, raw JSON text) → 1. Moot after entry 3.
6. [message] Any mistake on a parsed value prints the whole recursive type, 400-900 characters per
   line, sometimes twice (`Array@L77[true|false | Float | Integer | nil | String | Array@L77 | Hash@L54[String => ...]]`).
   The hint `the value has several types here; make each of them fit` does not say how (a
   `case`/`in`, or a typed getter). `@L54`/`@L77` are lines in the concatenated file, inside the library.
7. [ruby-habit] `cfg["server"]["port"] + 1` on a parsed document →
   `Indexable.[]: the index must be Integer, but is String [type]` (plus a receiver report) → partly
   (the receiver may be an Array, so a String index is wrong; true, but it reads oddly for a Hash
   lookup) → `Json.int(cfg, Array["server", "port"])` → 1 (probe, not in a client).
8. [ruby-habit] `Json.int(cfg, ["server", "port"])` (a Tuple as path) →
   `Array.each: argument 1 must be Array, but is [String, String]`, with the hint to write `Array[...]`,
   reported at a library line with `reached by the call at line 313 → line 262` → yes → `Array[...]`
   → 1. Every path is spelled `Array["a", "b"]`: 34 times in the clients.
9. [missing-builtin] `Integer.chr(0x3042)` → `RangeError: Integer.chr: 12354 out of char range`
   (no encoding argument) → no hint → `format("%c", cp)` → 2.
10. [tooling] `build.sh` concatenation: all messages give `out/` line numbers; the client starts at
    line 347, so I subtract by hand. Hint chains mix library and client lines. No name clash
    happened, but I named the parser `JsonParser` (not `Json::Parser`: namespaces cannot nest) to
    keep clear of client names. build.sh prints the offset to help.
11. [tooling] Speed: parsing the 228 KB document takes 12-15 s, generating it 2.5-3 s. A bare
    `s[i]` loop runs about 80k iterations/s and scales linearly, so this is the interpreter's
    general speed, not a quadratic path in the library.

## What felt good

- The parser and generator (300 lines) passed `--strict` on the first run, as did
  `client_config`. `case c in "{" then object(ps) ...` is exactly how I would write it in Ruby.
- Entry 2: passing a Struct to `generate` was reported before running, from inside the library,
  with the call chain back to the client line.
- `--types` printed the recursive JSON type it inferred (no annotation anywhere) and the field
  types of `Upstream` (`name: String, weight: Integer`): the typed getters fix the types at the
  boundary, and everything after that is proven.
- `Json.strs` / `Json.ints` returning `String[]` / `Integer[]` made the typed Array a natural API:
  the caller gets elements it can use with no check.
- `class Upstream < {reader: [name, url, weight]}` and `class JsonParser < {reader: [src, len], accessor: [pos]}`
  read well; `@pos += 1` inside the parser kept it short. Reader-only fields cost nothing here.

## What felt bad (top 3)

1. Booleans cannot be narrowed away (entry 3). It cost a library feature (a `JsonEncodable` hook
   for user Structs) and ~15 minutes. Every client now writes its own `to_json_value` and calls it
   before `generate`.
2. The size of messages about the JSON union (entry 6): readable only by searching for the first
   type name. Every probe that misused a parsed value produced several such lines.
3. Helpers that always raise do not narrow (entries 1 and 4): ~10 minutes, and the library code
   is less direct than in Ruby (`if x in String ... else type_error ... end` instead of a guard).

## Library design under Sake

- **Representation.** Plain Hash/Array/... worked, because the inferred recursive union is precise.
  I did not need a `JsonValue` wrapper; one would have added a `get_` on every access and gained
  nothing the union does not already give.
- **Access.** In Ruby, `cfg.dig("server", "port")` and `cfg["server"]["port"]` are enough, and the
  type is checked (or not) when used. In Sake that union cannot be used directly, so the API is a
  set of typed getters (`str/int/num/bool/arr/obj`, `strs/ints`, `*_or`). No `dig(*keys)` (no rest
  parameters), so the path is an `Array[...]`. No keyword/default arguments, so the defaulting
  getters are separate functions.
- **Extensibility.** Ruby's `to_json` protocol (any object can define it) could not be offered
  (entries 3 and 5); a user type converts itself to plain values first. A raw-text escape hatch
  (`JsonRaw`) could be offered because the library owns that type.
- **No `Hash.new { }`, no symbolize_names, no `JSON.parse(s, object_class:)`**: options would need
  keyword arguments or blocks as values; I left them out.
- **Errors.** One exception type with a `pos` field (`class JsonError < {exception: true, reader: [pos]}`)
  was easy; the rescue is checked to be reachable.

## Numbers

- Lines (non-blank, non-comment): lib 293; clients 58 (config) + 71 (transform) + 30 (records)
  + 52 (roundtrip) = 211.
- Static errors before each program ran clean (as written for the clients):
  - lib + first smoke test: 0.
  - client_config: 0; after adding `strs`/`ints`: 2, both false reports (entry 4).
  - client_transform: 1, a false report (entry 1).
  - client_roundtrip: 0.
  - client_records: 1 my mistake (entry 2, a deliberate probe), then 4 false reports, the same one
    in each program, from the hook (entry 3).
  - Total: 1 my mistake, 7 false reports (3 distinct causes). Probes outside the clients (entries
    7, 8) produced 10 more reports, all correct.
- Level-2 reports that could not be removed: none, but only after dropping the hook of entry 3,
  which is a level-1 (`type`) report and so fails at the default level too.
- `--strict=3`: 6-7 reports per program, all from entries 3 and 4 (`[index-nil]` after
  `fail(...) unless h`, and `[exhaustive]` on true|false).

## Suggestions

1. Make `in true` / `in false` (and `x == true`) narrow, or allow `Boolean` as a pattern, so a
   `case` over JSON values leaves true|false out of `else` (entry 3).
2. Treat a call to a function whose every path raises as an exit for narrowing, like an inline
   `raise` (entries 1, 4); at least, say so in the hint.
3. Abbreviate recursive types in messages: print each `Array@L77[...]` / `Hash@L54[...]` once, later
   occurrences by name only, and give a "use `case x in T` to narrow" hint (entry 6).
4. Let a module that no type includes go unreported when its mixin call is unreachable, or let a
   pattern name a module (`in JsonEncodable`) so a library can offer a protocol hook (entries 3, 5).
5. `Integer.chr(cp, "UTF-8")` or a hint to `format("%c", cp)` on the RangeError (entry 9); and
   `require` or a `# line` directive so concatenated programs report their own line numbers
   (entry 10).
