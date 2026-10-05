# sakelib and the 2026-10-03 library programs, reviewed against the current language (2026-10-05)

Scope: the 18 libraries in `sakelib/` and the programs (lib.sake, client_*.sake) of
`experiments/2026-10-03-libraries/`, reviewed against the language at c225abf (attr_* lines, `initialize`,
`class B < A`, `class E < Exception`, optional/keyword parameters, `x => T`, `block_given?`/`&b`, `once`,
IO values, gsub with a Hash or block). Rewritten where a feature brings the code closer to Ruby's API or
the Ruby way of writing it; left alone otherwise.

## Method

- **sakelib:** `ruby -Ilib test/test_sakelib.rb` (each `test/sakelib/NAME.sake` run with `--strict` must print
  what `NAME.rb` prints): 18 runs, 0 failures, before and after.
- **Findings:** `bin/sake --strict=1 -c` and `--strict=2 -c` on `sakelib/NAME.sake` (the library alone) and on
  `test/sakelib/NAME.sake` (the library as used). A finding is a report line ending in `[item]`.
- **Ambiguous types:** a field or parameter whose type in `bin/sake --types test/sakelib/NAME.sake` (or on the
  concatenated experiment program) is a union of non-nil types or contains unknown. A `nil | T` that is the
  value's real "unset" state is listed only when it is not inherent.
- **experiments/2026-10-03-libraries:** each client concatenated with its lib.sake and run with
  `bin/sake --strict=0` from its directory, before and after. Stdout and exit status are compared with
  timing lines masked (`[0-9]+\.[0-9]+s`); two runs before the change differed only in those lines. The
  webapp apps were replayed as CGI (13 todo requests, 11 shortener requests, data/ reset first). The
  webapp-native apps were replayed against the running servers over sockets, with the data files compared
  afterwards and dates masked. The harness is `exp_run.sh` + `reqs.rb` (session scratchpad, not kept).
  Every output is identical. `out/` was rebuilt with each `build.sh`; it was already stale before for
  collections, csvtable, events and graph.
- `docs/examples/libraries.sake` (requires json and base64) prints the same as before.
  `experiments/2026-10-03-sakelib-port/phase2/bench_*.sake` all pass `-c`, except `bench_optparse.sake`. It
  calls `OptionParser.parse(op, argv, h)` with 3 arguments and fails the same way with the library from
  before this review, so the breakage predates it.

## Findings before → after

Every library: 0 → 0 at level 1 and level 2, for the library alone and for its test.

| lib | lib L1 | lib L2 | test L1 | test L2 |
|---|---|---|---|---|
| abbrev, base64, benchmark, cgi, csv, date, digest, erb, json, logger, matrix, optparse, prime, shellwords, strscan, tsort, uri, zlib | 0 → 0 | 0 → 0 | 0 → 0 | 0 → 0 |

The library alone gives 0 partly because uncalled functions are not checked; the test column is the
meaningful one. Experiment programs: every client 0/0 → 0/0, except `collections/client_shared` 9/9 → 9/9
(it exists to show these reports).

## Language and checker problems found

1. **Checker bug: a field written conditionally in `initialize` loses what `new` stored.** Found
   independently by two reviewers. `@h = A.new(1) unless @h` gives the field the type A only, though
   `M.new("a", B.new(2))` keeps a B there. The result is wrong in both directions:
   - false reports, such as a correct `B.get_x(M.get_h(m))` reported as `[type]`;
   - missed nils: `URI.scheme` and `URI.path` show `String`, but are nil for a relative or opaque URI.

   Repros: `sakelib/notes/uri_bug_initialize_conditional_write.sake` and
   `experiments/2026-10-05-review/bug_initialize_conditional_field.sake`. It blocked an optional
   `hooks = NoHooks.new` in events' `Fsm`; that change was backed out because every hook became "dead",
   and so unchecked.
2. **An Array created in an inherited `initialize` is one allocation site for every copy.** With
   `class IntHeap < Heap` and `@items ||= Array[]` in Heap's `initialize`, every copy's `items` became one
   Array of `Integer | String | Task | ...`. Findings went 0 → 3, 8, 5 and 5 in four collections clients.
   `class B < A` copies the field types per class, but not the allocation sites in A's code. The change
   was reverted, and `Heap.create` stays.
3. **`new` takes only positional fields.** Ruby's `ERB.new(t, trim_mode: "-")`, `Logger.new(dev, level: :warn)`,
   `Graph.new(directed: true)` and `CSV.new(io, **opts)` cannot be written; factory functions or positional
   arguments remain.
4. **Field defaults are literals only.** A field Ruby creates in `initialize` (an Array, a Hash, an object)
   needs a `= nil` placeholder plus an assignment in `initialize`. `--types` shows that the nil does not
   stay in the field's type when `initialize` assigns it unconditionally (erb, optparse, benchmark, linalg).
5. **No `**opts` or `*args`.** csv's `read`/`readlines`/`foreach` and json's `fast_generate`/`pretty_generate`
   repeat every keyword. `URI.join` takes at most 3 references, `OptionParser.on` at most 4 strings, and
   matrix's `diagonal`/`vstack`/`hstack` take one Array.
6. **`x => T` raises NoMatchingPatternError**, which cannot be rescued, where Ruby raises ArgumentError or
   TypeError (`Prime.prime?`, `StringScanner.new`, `Date.new`). It is reported before running, which is
   better, but a program that rescues Ruby's error does not port.
7. **Socket cannot be listed or matched:** `(Socket|IO).gets` is "not a type" and `in Socket` is not a
   pattern (webapp-native lib.sake:253,273, which branch on `io in IO`).

## sakelib, per library

### abbrev, base64, cgi, shellwords, zlib: unchanged
They already use optional/keyword parameters and `once` where Ruby does, and none has state for an
`initialize`.
- **Frictions:** `|| ""` after `unpack1` and slices (base64.sake:13,19; cgi.sake:50).
- **Types:**
  - zlib `s`: `nil | String` (Ruby accepts nil).
  - abbrev `pattern`: `nil | Regexp | String` (abbrev.sake:35, Ruby's API).
  - shellwords `shellescape(x)` takes any value (shellwords.sake:40, Ruby calls `to_s`).

### benchmark
- **Changes:**
  - `print`/`puts` instead of `IO.print(IO.stdout, …)`.
  - `bm`, `Tms.add`/`add!`, `report` and `item` pass their block with `&b`.
  - `BenchmarkReport.new(width = 0, format = nil, mode = :report)`; `initialize` starts the list empty, so
    callers no longer pass `BenchmarkTms[]`.
- **Frictions:**
  - `Benchmark::Tms` is spelled `BenchmarkTms` (benchmark.sake:5).
  - `total` is a function, where Ruby stores it (:9).
  - No `Process.times`, so CPU times are 0.0 (:111).
  - `bmbm` runs its block three times, because a block cannot be stored (:134).
- **Types:** none ambiguous.

### csv
- **Changes:**
  - `class MalformedCSVError < Exception` with `attr_reader line_number`.
  - `initialize` in CSVRow copies headers/fields and pads the shorter with nil, as Ruby's `Row.new`; `CSVRow.pad`
    and the callers' `Array.dup` are gone.
  - `k:` shorthand when passing keywords on.
  - `&b` in `foreach` and `CSVTable.each/map/select/find`.
- **Frictions:**
  - No `**opts`: `read`/`readlines`/`foreach` repeat the 11 keywords (csv.sake:199-220).
  - `CSV.new` is the 9-field constructor, so a `writer` helper stands in for `CSV.new(io, **opts)` (:273).
  - `values_at` takes one Array (:404, :514).
- **Types:**
  - `CSVRow.headers`/`fields`: Arrays of `String | nil | Integer | Float | Symbol`. This is inherent: empty
    cells are nil, converters make numbers, header converters make Symbols.
  - `CSV.headers`: `nil | Array`; `CSV.io`: `IO | nil`; `CSV.path`: `String | nil` (the writer, or `generate`
    without a file).

### date
- **Changes:**
  - `attr_reader year = -4712, month = 1, day = 1, jd = nil`.
  - `initialize` asserts `@year => Integer` (and month, day), resolves negative month/day, computes `@jd`, and
    raises DateError for an invalid date. So `Date.new` validates as Ruby's does, and `Date.new("2024", 1, 1)`
    is reported at the call.
  - `Date.civil` is `Date.new` under another name.
  - `class DateError < Exception`.
  - The test uses `Date.new` as `date.rb` does.
- **Frictions:**
  - `DateError` instead of `Date::Error`, with no ArgumentError parent (date.sake:8).
  - `Date.jd(n)` validates twice, because no constructor skips `initialize` (:46). bench_date is about 7% slower:
    user time 1.61–1.66 s → 1.74–1.89 s, 3 runs each, at load 5.5.
  - A class method and an instance method with one name are split by `case x in Integer` (:46, :72, :190).
  - The strptime cursor is a Tuple `[0]`, because Records cannot be written to (:242).
  - `String.[](…) || ""` (:211, :214).
  - A Date cannot be a Hash key.
- **Types:** fields are all Integer. `Date.jd`/`leap?`/`iso8601` take `Integer | Date` (or `String | Date`) on
  purpose, narrowed per call by `case`.

### digest
- **Changes:**
  - `def initialize(md) = reset(md)` in each class, as Ruby's `Digest::Base` resets on creation; the initial
    words appear only in `initial_state`.
  - `digest`/`hexdigest`/`base64digest`/`file` moved into the `Digest` mixin.
  - `class SHA384 < SHA512` defines only `digest_length`, `name` and `initial_state`; the `SHA2_64` module is gone.
    451 → 419 lines.
- **Frictions:**
  - The same `initialize` line is repeated in every class (digest.sake:115,187,248,324,…). It works from the
    mixin too, but the spec defines `initialize` in a class only.
  - `digest_of` splits on `case x in String`, because Ruby's class and instance methods share a name (:66).
  - `|| ""` after `byteslice`/`unpack1` (:61, :107).
- **Types:** `h0..h7` are `nil | Integer` in all five types. This is not inherent: `@h0, … = h` takes apart
  an `Integer[]` whose length is not known before running. It was the same before.

### erb
- **Changes:**
  - `ERBFrame`'s `chained`/`in_alt` default to false, so it is created as `ERBFrame.new(node)`.
  - `ERBNode` is `attr_reader kind, text, vars = nil, body = nil, alt = nil`, and its `initialize` creates the
    three Arrays. It is created as `ERBNode.new(kind, text)`, and the `_node` helper is gone (6 call sites).
- **Frictions:**
  - `ERB.new(t, trim_mode: "-")` is `ERB.new(t, "-")`, because `new` takes no keywords (erb.sake:29).
  - Helpers are `_`-prefixed (no `private`).
- **Types:** `ERB.trim_mode`: `nil | String` (inherent). `vars`/`body`/`alt` are `String[]`/`ERBNode[]`, with no nil.

### json
- **Changes:**
  - `initialize` in `JSONParserState` and `JSONGeneratorState` converts the options as Ruby's `Parser.new` /
    `State.new` do: flags to true/false, a false/nil `max_nesting` to 0, the source's byte size stored.
  - `pos`/`depth` default to 0.
  - `JSON.load` matches `in IO`; the workaround for the fixed IO bug is gone.
  - `k:` shorthand.
- **Frictions:**
  - No `**opts`: `fast_generate`/`pretty_generate` repeat every keyword (json.sake:501, :507).
  - No `nil.to_json`/`true.to_json`, because nil and true/false have no namespace (:565-583).
- **Types:** none ambiguous; `max_nesting` is now plain Integer.

### logger
- **Changes:**
  - `initialize` asserts `@logdev => IO | String | nil` (`Logger.new(42)` is reported before running) and
    coerces `@level = Logger.coerce_level(@level)`, as Ruby's `initialize` calls `level=`.
  - Fields reordered, so that `new(dev, level, progname, formatter, datetime_format)` follows Ruby's keyword order.
  - `io` and `closed` are readers.
  - `debug`…`unknown` and `log` pass their block with `&b`; the `block_given? ? … : …` workaround for the
    fixed pass-on bug is gone.
- **Frictions:**
  - `Logger.new(dev, level: :warn)` cannot be written (logger.sake:6-16).
  - The formatter is a format string, not a proc (:29).
  - The level constants are functions (:21).
  - No `Process.pid` in the line.
- **Types:**
  - `logdev`: `IO | String | nil`, inherent (Ruby accepts each).
  - `progname`/`formatter`/`datetime_format`: `nil | String`, and `fixed_time`: `nil | Time`; nil is their
    unset state.

### matrix
- **Changes:**
  - `initialize` checks that every row has `column_count` elements and raises `ErrDimensionMismatch` with
    Ruby's message. Ruby does this in `Matrix.rows` because its `new` is private; Sake's `new` is public.
    Test CPU time is unchanged.
  - `class ErrDimensionMismatch < StandardError` and the other three.
  - `Vector.elements(array, copy = true)`.
  - `&b` in `Matrix.map`, `Vector.map` and `Vector.map2`.
  - `once` for `SELECTORS`.
- **Frictions:**
  - `Matrix[...]` means an Array of Matrix in Sake.
  - `2 * m` cannot be written (no coerce).
  - No rest parameters for `diagonal`/`vstack`/`hstack` (matrix.sake:38, :61).
  - `Float.round(x, 0)` gives a Float (:507).
  - No `Math.acos` (:675).
  - No `Integer#quo` (:499).
  - `each` without a block gives an Array, not an Enumerator (:118).
  - Names are not nested (`Matrix::ErrDimensionMismatch`).
- **Types:** `Matrix.rows`/`Vector.elements` are Arrays of `Complex | Float | Integer | Rational`. A field has
  one type for the whole program, and the test uses all four kinds; this is inherent to a generic numeric
  library.

### optparse
- **Changes:**
  - Field order is banner, summary_width, summary_indent, program_name, version, list (optparse.sake:35), so
    that `OptionParser.new(banner, width, indent)` follows Ruby's order.
  - `initialize` creates `@list = Array[]` (:38), replacing a `list = nil` default and a lazy `items(op)`.
  - `getopts` drops the empty `""` arguments to `on`.
- **Frictions:**
  - `on(op, a, b = "", c = "", d = "")` takes at most 4 strings and stores no block (:45-46).
  - `OptionParser.new { |o| … }` cannot be written.
  - The exception subclasses are one type with a `kind` (:20).
  - `getopts` takes the long options as one Array (:192).
  - `program_name` defaults to "sake", because there is no `$0` (:35).
- **Types:** `OptionParserError.args` is a union of `String[]` from 12 creation sites (benign). `list` was
  `nil | Array` before and is now an Array.

### prime
- **Changes:**
  - `Prime.prime?` asserts `n => Integer`, where Ruby raises ArgumentError; a Float is reported before running.
  - `Prime.each` is back to Ruby's shape (`return … unless block_given?`, then the loop); the yield-in-loop bug
    that forced the old layout is fixed.
  - `Integer.each_prime(ub, &b) = Prime.each(ub, &b)`.
- **Frictions:**
  - `=> Integer` raises NoMatchingPatternError, which cannot be rescued (prime.sake:95).
  - `each` without a block gives an Array and needs an upper bound (:10).
- **Types:** none ambiguous.

### strscan
- **Changes:**
  - `initialize` asserts `@string => String` and calls `reset`.
  - `set_string` asserts `s => String`.
  - `class ScanError < Exception`.
- **Frictions:**
  - `<<` needs `include Bitwise` (strscan.sake:16, :231).
  - `scan_full`/`search_full` return `String | Integer` depending on `getstr` (:128).
  - `pos=` is `set_pos` (:182).
  - A wrong type raises NoMatchingPatternError, not TypeError.
- **Types:** `md`/`mstr` are `nil | …`, nil when there is no match (inherent).

### tsort
- **Changes:**
  - `class TSortCyclic < Exception`.
  - `tsort_each_node` uses `Hash.each_key(@h, &b)`; `tsort_each_hash` and `each_strongly_connected_component_hash`
    pass `&b`.
- **Frictions:**
  - Hash-graph functions stand in for Ruby's module functions over callables (tsort.sake:92-95).
  - `TSortCyclic`, not `TSort::Cyclic` (:13).
- **Types:** `TSortHashGraph.h` (:99) is the union of every caller's Hash type, since a field has one type for
  the program. It is harmless: nodes are only keys and compared with `==`.

### uri
- **Changes:**
  - `URI.new` takes Ruby's `URI::Generic.new` order (scheme, userinfo, host, port, registry, path, opaque, query,
    fragment), with a new `registry` field (always nil).
  - `initialize` does what `Generic#initialize` does: down-cases the scheme, converts a String port to an
    Integer, fills the default port, and sets path to `""` unless opaque.
  - `_new` became `_for` (Ruby's `URI.for`), keeping only FTP's leading-"/" strip; that strip stays out of
    `initialize`, because `dup` runs `initialize` again.
  - `dup`/`merge` call `URI.new`.
- **Frictions:**
  - The setters skip `initialize`'s conversions (`set_port(u, "81")`).
  - `URI(s)` cannot be a function.
  - `URI.join` takes at most 3 references (uri.sake:308).
  - The exceptions are not nested (:6).
  - `_dump` stands in for `String.dump` (:75).
- **Types:**
  - `URI.new`'s `port` parameter is `String | Integer | nil` (from `split`, from `dup`/`merge`), as Ruby's API.
  - `merge`'s `other` is `String | URI`; `encode_www_form`'s `form` is `Hash | Array`.
  - **Wrong:** `URI.scheme` and `URI.path` show `String`, but can be nil, because of checker bug 1 above.

## experiments/2026-10-03-libraries, per directory

### collections
- **Changes:**
  - `HeapOps`/`DequeOps`/`LruOps` folded into `Heap`/`Deque`/`LRU`.
  - The clients' per-element copies are `class B < A` (`TaskQueue`, `IntHeap`, `WordHeap`, `CellHeap < Heap`;
    `IntDeque`, `IndexDeque`, `LineDeque < Deque`; `ParseNode < LruNode`; `ParseCache < LRU` with its own
    `make_node`). Each copy keeps its own field types.
  - Field defaults (`seq = 0`, `start = 0, count = 0`, `head = nil, …, hits = 0, misses = 0`), so
    `with_items`/`with_buf`/`with_index` are gone.
  - `LruNodeOps` stays a module, so a copied LRU reaches its own node type's fields.
- **Frictions:**
  - Ruby has one Heap; Sake needs a copy per element type (client_scheduler.sake:12-17).
  - `create` stays because of problem 2 above.
  - Each copy also carries A's `create`, which returns an A.
- **Types:**
  - `head`/`tail`/`prev`/`nxt` are `X | nil` (the list's end).
  - client_shared's `Heap.items: Integer | String`, `LruNode.key: Integer | :ann` and `Deque.buf: Float | String`
    are intended (one container, two element types).

### csvtable
- **Changes:**
  - `class CsvError < Exception` with `attr_reader line` (lib.sake:6).
  - `sort_by_column(t, name, descending: false)`.
  - `render(t, digits = 2)`.
  - client_clean's `Issue` is a class with `attr_reader` (client_clean.sake:14).
- **Frictions:**
  - `from_csv_lenient(text, problems)` and `convert(t, cols, issues)` (client_clean.sake:28) fill an Array the
    caller passes in; Ruby would use one function with a keyword, or return both.
  - The row-width check stays in `from_csv`, not `initialize`, since internal constructions build Tables directly.
- **Types:**
  - `Table.rows` cells are `Float | Integer | nil | String`, by design.
  - `Table.headers` is a union of `String[]` and `Array[String]` from different sites (same element type).

### events
- **Changes:**
  - `initialize` replaces the factory functions: `Bus.new`, `Recorder.new`, `Fsm.new(name, initial, hooks)`
    (lib.sake:17-35, :95-99), and the clients' Audit, Mailer, Counter (`Hash.new(0)`) and Lexer.
  - `Fsm.allow(fsm, from, event, to, guard: :none, action: :none)` (:101): 26 calls drop their `:none`s.
  - `= 0` field defaults.
  - The dead `Fsm.plain` is removed.
- **Frictions:**
  - Placeholder `= nil` defaults (lib.sake:17, :30, :95; client_turnstile.sake:25).
  - An optional `hooks = NoHooks.new` is blocked by checker bug 1.
- **Types:**
  - `Summer.total: Integer | ?(operand)` (`@total += data if data in Integer` with `data` a union; same before).
  - `Once.sub: Integer | nil` (nil until subscribed).
  - `Fsm.hooks: Light | Parity`, because field types are per class, not per instance.

### graph
- **Changes:**
  - `class CycleError < StandardError` with `attr_reader cycle` (lib.sake:4).
  - `Heap.new` and `Graph.new(directed)` set up in `initialize` (:10-11, :51-52).
  - `add_edge(g, a, b, w = 1)` replaces `connect` (:61).
  - The `Implicit.each_neighbor` stub no longer needs a dead `yield`.
- **Frictions:** `Graph.new(directed: true)` cannot be written (problem 3), so the
  `directed_graph`/`undirected_graph` factories stay.
- **Types:** in client_stress, `Graph.adj` keys and `CycleError.cycle` are
  `Integer | String | Symbol | [Integer, Integer]`, because several node types share one field type.

### json (experiment)
- **Changes:**
  - `JsonParser` is `attr_reader src, len = 0`, `attr_accessor pos = 0`, and `initialize` computes `@len`, so
    `Json.parse` calls `JsonParser.new(s)` (lib.sake:10-14).
  - `JsonError`'s `pos = 0` default.
  - `emit(v, indent = nil, depth = 0)`.
  - client_transform's `count_kinds(v, counts = Hash.new(0))`.
- **Frictions:**
  - `str_or`/`int_or`/`bool_or` stay separate from `str`/`int`/`bool`. A `default:` keyword cannot mark "none",
    because nil is a valid answer, and a sentinel Symbol would widen the type.
  - `type_error` always raises but does not narrow its caller, so `strs`/`ints` need an explicit
    `if x in String … else`.
- **Types:** client_records' `Shape.label: nil | String` (intended).

### linalg
- **Changes:** `attr_reader rows, nrows = nil, ncols = nil`, and `initialize` computes both, as Ruby's Matrix
  computes `column_count` (lib.sake:61-69). `Mat.of`/`build`/`map` call `Mat.new(rows)`. The ragged-row check
  stays in `Mat.of`, as in Ruby's `Matrix.rows`.
- **Types:** `nrows`/`ncols` are Integer, with no nil left. `Mat.rows`/`Vec.elems` are `Float | Integer | Rational`,
  by design.

### validate
- **Changes:**
  - Exception classes (lib.sake:80, :83; client_config.sake:24; client_pipeline.sake:6).
  - `Checker.new(input)` and `Schema.new` via `initialize` (:96-97, :225-226) replace `Checker.start` and
    `Schema.build`.
  - `Schema.field(s, name, rules, required: true)` (:227).
- **Types:**
  - `Checker.input: Hash[nil | String => nil | String]` (client_config; MatchData captures may be nil).
  - `ConfigSyntaxError.message: nil | String` (`Array.first` after an emptiness check that does not narrow).

### webapp, webapp-native
- **Changes (both):**
  - `class HttpError` (:5).
  - `Request.param(r, name, default = nil)` replaces `param_or` (:14).
  - `Html.escape` uses `gsub` with a Hash kept by `once` (:70-71).
  - `Json.string`, `Tsv.esc`/`unesc` and `url_encode` use `gsub` with a block or Hash (:119, :151-152, :237).
- **Changes (native only):**
  - Stdin is `IO.stdin`, not `nil` (:253, :273).
  - `run(routes, &b)`.
  - `serve(routes, port, workers: 4)`.
  - `Range.each`.
- **Frictions:**
  - Problem 7 (Socket vs IO).
  - `url_decode` keeps its own UTF-8 decoder: `String.scrub` gives one U+FFFD for `%E3%81`, where the selftest
    expects two.
- **Types:** `Request.*` and `Response.headers` are unions of allocation sites with the same element types
  (benign).
