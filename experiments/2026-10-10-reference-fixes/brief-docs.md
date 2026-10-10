# Brief: bring the built-in reference up to date after the 2026-10-10 fixes

The interpreter and checker were changed today to fix the findings recorded while the reference was written
(`TODO.md`, section "実装課題（組み込みリファレンスの執筆で見つかったもの、2026-10-10）"). The chapters
`docs/manual/ja/ref/NS.md` and `docs/manual/en/ref/NS.md` still describe the old behaviour in places, and
`ruby tools/check_reference.rb` now reports problems. Your job: for your namespaces, make both chapters true
again — prose and examples — and get `ruby tools/check_reference.rb NS...` to `0 problems`.

Read `docs/manual/ref-brief.md` first (structure, style, the checker's rules). Do not change `lib/`, tests, or
chapters outside your namespaces. Do not commit.

## How to work

1. `ruby tools/check_reference.rb NS` for each of your namespaces: fix every reported problem (a signature line
   that changed, an example whose output changed, a `ruby error` example that no longer fails, a missing section
   for a new operation).
2. Then read both chapters once, looking for prose that the changes below make false: "a Ruby error with a
   backtrace", "cannot be rescued", "raises TypeError" where it is now false, "level 2" where it is now level 3,
   "returns a new String" for force_encoding, "returns nil" for casecmp?, and so on. Fix the Japanese and the
   English together (same facts, same examples).
3. **Run `bin/sake` to confirm every claim you write**; never write an output you have not seen. The checker runs
   examples under `--strict=2` from an empty temp dir with stdin `"3\n1 2\n"` (a pipe, not a terminal).
4. Finish with `ruby tools/check_reference.rb NS...` at `0 problems` and `--coverage` showing ja = en = total.

## What changed (everything below is verified; the message texts are exact unless marked ~)

### For every namespace

- **Ruby exceptions no longer escape built-ins as raw backtraces.** A Ruby error inside an operation becomes the
  Sake exception of the same kind, rescuable: RangeError, RegexpError, FloatDomainError, Math::DomainError,
  ZeroDivisionError, TypeError, ArgumentError, IndexError, KeyError, IOError (also Ruby's EOFError and Errno::*),
  ThreadError, EncodingError, RuntimeError (Ruby's own, e.g. `String.undump` of a bad string). The message is
  Ruby's text (with `Tuple` instead of `Sake::Tuple`). Where a chapter said "a raw Ruby error" / "dies with a
  backtrace" / "cannot be rescued", say the kind and show a `ruby error` example with its message.
- In the table-driven operations, a Ruby TypeError or NoMethodError is now a **TypeError** (it was reported as
  ArgumentError), e.g. `Array.pack(Array["a"], "C")` → `TypeError: Array.pack: no implicit conversion of String into Integer`.
- **The function forms of `==` and `!=`** (`Integer.==(1, "a")`, `String.==("a", 1)`, `Symbol.==(:a, "a")`,
  `Hash.==(h, nil)`, `Float.==(1.0, "1")`, `Range.==(1..5, 5)`, `Time.==(t, 100)`, `Rational.==`, `Complex.==`, ...)
  give **false / true for a value of another type**, as the operator does. They no longer raise TypeError.
- **Sorting a union is a static error.** `Array.sort/sort!/min/max/minmax/sort_by/min_by/max_by/minmax_by`,
  `Set.sort/sort_by/min/max/min_by/max_by/minmax/minmax_by`, `Tuple.max/min/minmax` are rejected statically when
  the element types (or the block's result types, for `*_by`) are not all comparable with each other:
  `Array.sort(Array[1, "a"])` → `error: Array.sort: elements compared in order may be (Integer, String), which cannot be compared [type]`.
  With a nil element the report is `Array.sort: argument elements may be nil ([Integer | nil, Integer | nil]) [nil]`.
  The old runtime `ArgumentError: cannot compare elements of types Integer, String` is now reachable only when the
  checker cannot see the problem (e.g. `Array.sort(Array[1.0, Float.NAN])` → `ArgumentError: Array.sort: cannot compare elements of types Float, Float`).
  Rewrite those examples as `ruby error` blocks with the static message (first line of stderr).
- **The nil of a miss, level 3** (reported as `index-nil` only with `--strict=3`): `Array.slice`, `slice!`,
  `dig`, `minmax`, `Set.first`, `min`, `max`, `min_by`, `max_by`, `minmax`, `Hash.dig`, `MatchData.begin`, `end`
  now join `x[k]`, `Array.first/last/pop/shift/min/max/at`. A `ruby error` example that relied on level 2
  rejecting such a nil no longer fails; show instead that the value is used after a check, or drop the block.
- **flat_map blocks may return a Tuple**: `Array.flat_map(Array[1]) { |x| [x, x] }` → `[1, 1]`;
  `Hash.flat_map(h) { |k, v| [k, v] }` works. The error message for a wrong result is now
  `the block must return an Array or a Tuple, got Integer`.
- The frozen-String message: `TypeError: cannot change this String in place: it is a Hash key, a Set element, a Symbol's name, or a program argument`.

### Integer
- `Integer.chr(256)` → RangeError `256 out of char range`; `Integer.sqrt(-1)` → Math::DomainError;
  `Integer.digits(-1)` → Math::DomainError `out of domain`; `Integer.pow(2, -1, 7)` → RangeError.
- `Integer.digits` returns a typed `Integer[]` (a push of a String is a type error).
- `Integer.==(1, "a")` → false.

### Float, Rational, Complex, Arithmetic, Math
- `x ** y` with a negative Float base and a fractional exponent → `Math::DomainError: Arithmetic.**: -8.0 ** 0.5 is not a real number (a negative base with a fractional exponent)` (Ruby gives a Complex).
- `Float.numerator`, `denominator`, `to_int` of NaN or infinity → FloatDomainError. `Float.divmod(x, 0.0)` and
  `7.5 % 0` → ZeroDivisionError. `Float.clamp(x, lo, hi)` with lo > hi → ArgumentError.
- `Float.round(x, [Integer], [half: Symbol])`: new keyword `half:` (`:up` default, `:even`, `:down`);
  `Float.round(2.5, 0, half: :even)` → `2.0`.
- `Arithmetic.round(Integer|Float|Rational, [Integer], [half: Symbol])`; **with digits the result keeps x's type**:
  `Arithmetic.round(1234.5, -2)` → `1200.0` (Ruby: 1200), `Arithmetic.round(5r/2, -1)` → `(0/1)`;
  `Arithmetic.round(25, -1, half: :even)` → `20`. Same for floor/ceil/truncate with digits. NaN → FloatDomainError.
- `Rational ** Rational` and `Integer ** Rational` are typed `Rational | Float`: `4r ** 2r` → `(16/1)`,
  `4r ** (1r/2)` → `2.0`.
- `Complex.abs(Complex(3r, 0))` → `3.0` (a Rational magnitude becomes a Float; the result is Integer | Float).
- `Math.log(Integer|Float|Rational, [Integer|Float])`: `Math.log(8, 2)` → `3.0`.
- `Kernel.Rational(Integer|Float|Rational|String, [Integer|Rational])`: `Rational(0.5)` → `(1/2)`.
- `Kernel.Integer(Float.NAN)` → FloatDomainError `NaN`.
- `Kernel.rand(n)`: n must be Integer or Float; `rand(0)` and a negative n → `ArgumentError: Kernel.rand: invalid argument - 0`;
  `rand(2.5)` → a Float in 0.0...2.5.

### String, Symbol, Regexp, MatchData
- `"ab" * -1` → ArgumentError `negative argument` (the operator form, like `String.*`).
- `String.ljust/rjust/center` with `""` as the pad → ArgumentError `zero width padding`; `tr`/`delete`/`squeeze`/`count`
  with a reversed range `"z-a"` → ArgumentError `invalid range "z-a" in string transliteration`;
  `String.undump` of a bad string → RuntimeError (Ruby's message); `String.byteindex("héllo", "l", 2)` → IndexError
  `offset 2 does not land on character boundary`; `String.match?("a+c", "+")` → RegexpError.
- **`String.force_encoding(s, enc)` now changes s in place and returns s** (as Ruby's).
- `String.casecmp?` and `Symbol.casecmp?` return **false** (not nil) for incompatible encodings; the type is Boolean.
- `Regexp.new(src, flags)` accepts `"n"` among the flags (`"imxn"`); `Regexp.new("(")` → RegexpError, rescuable.
- `Regexp.union(*String|Regexp|Array)`: one Array of patterns is accepted: `Regexp.union(Array["a", "b"])` → `/a|b/`.
- `MatchData.begin(m, i)` / `end` → `Integer | nil` (nil for a group that did not take part; a miss, level 3);
  an index out of range → IndexError `index 5 out of matches`.

### Array, Tuple
- `Array.insert(a, i, x)` past the end → `IndexError: Array.insert: index 3 is past the end of the Array (length 1); the gap would be nil`
  (Ruby fills the gap with nil). A negative i below `-size - 1` is also an IndexError.
- `Array.fill` on a typed Array is checked statically (`Array.fill: an element must be Integer, but is String [type]`);
  `Array.replace` is checked statically and at run time.
- `Array.transpose` accepts rows that are Tuples: `Array.transpose(Array[[1, 2], [3, 4]])` → `[[1, 3], [2, 4]]`
  (the result's rows are Arrays). Rows of different lengths → IndexError `element size differs (1 should be 2)`.
- `Array.dig(x, Integer, *Any)`: several keys step into nested Arrays / Hashes / Tuples; nil is a miss (level 3).
- `Array.each_slice(a, 0)` / `each_cons(a, 0)` → ArgumentError `invalid slice size`.
- `Array.rfind` is implemented directly (no behaviour change).
- `Tuple.max([1, "a"])` is now a static `type` problem (see "Sorting a union").

### Hash, Set, Range
- `Hash.dig(x, Any, *Any)`: several keys; nil is a miss (level 3). `Hash.==(h, nil)` → false.
- `Set.subtract(s, 1)` → `TypeError: Set.subtract: argument 2 must be Set, Array, Tuple, or Range, got Integer`.
- `Range.include?` and `member?` **walk a String Range** as Ruby's do: `Range.include?("a".."z", "mm")` → false,
  `Range.cover?("a".."z", "mm")` → true (cover? compares with the ends only).
- `Range.minmax` accepts a Float Range: `Range.minmax(1.0..2.5)` → `[1.0, 2.5]`; an exclusive non-Integer end →
  TypeError `cannot exclude non Integer end value` (also `Range.max(1.0...2.5)`).
- `Range.first(1.0..2.0, 2)` → TypeError `can't iterate from Float`; `Range.first(..5)` → RangeError
  `cannot get the first element of beginless range`; `Range.step(r, 0) { }` → ArgumentError `step can't be 0`;
  `Range.sum(1..3, Complex(1, 2))` → RangeError `can't convert 1+2i into Float`; `Range.==(1..5, 5)` → false.

### Kernel, Exceptions, Time, ENV, Process
- Exceptions: RuntimeError is also what Ruby's own RuntimeError becomes (`String.undump`). The example that showed
  `Array.sort(Array[1, "a"])` raising at run time must change (it is static now; use `Array.sort(Array[1.0, Float.NAN])`
  for a runtime ArgumentError, or another operation).
- `Time.to_a(t)`: the last element (the zone) is `String | nil` (nil for a fixed offset such as `in: "+09:00"`).
  `Time.==(t, 100)` → false.
- `ENV.set("", "v")` → `ArgumentError: ENV.set: Invalid argument - setenv()`.
- **New** `ENV.replace(Hash)` → nil: replaces the whole environment with the Hash's String keys and values (a
  non-String → TypeError). Document it; an example can set and read a variable, then restore `ENV.to_h`.
- `Process.clock_gettime(Integer, [Symbol])`: the result is a Float without a unit or with `:float_second`,
  `:float_millisecond`, `:float_microsecond`, and an **Integer** with `:second`, `:millisecond`, `:microsecond`,
  `:nanosecond` (the checker reads a literal unit; a non-literal unit is `Integer | Float`). An unknown clock
  (`Process.clock_gettime(999)`) → `ArgumentError: Process.clock_gettime: Invalid argument - clock_gettime(999)`.

### IO, File, Dir, Thread, Mutex, Queue, Socket, TCPServer, Open3, Zlib
- `IO.size` on a stream that is not a file → `IOError: IO.size: not a file`. `IO.seek(f, n, :FOO)` →
  `ArgumentError: IO.seek: unknown whence: :FOO (0/1/2 or :SET/:CUR/:END)`. `puts` after `IO.close(IO.stdout)` → IOError.
- **New** terminal operations (io/console): `IO.winsize(x)` → the Tuple `[rows, columns]`; `IO.raw(x) { }` and
  `IO.noecho(x) { }` run the block with the terminal in that mode and give its value; `IO.getch(x)` → one key
  (`String | nil`). Each is `IOError: not a terminal` when the IO is not a tty — under the checker stdin is a pipe,
  so `IO.winsize(IO.stdin)` in a `begin ... rescue IOError => e` example prints `not a terminal`; a real use
  needs a plain ``` fence and a sentence saying it needs a terminal.
- `Thread.value(t)` / `Thread.join(t)` after `Thread.raise(t, msg)`: `rescue RuntimeError => e` is accepted by the
  checker (it counts value / join as raising RuntimeError when the program calls Thread.raise).
  `Thread.join(Thread.current)` → ThreadError `Target thread must not be current thread`.
- **A thread that ended with an error that no Thread.value / Thread.join read is reported on stderr when the
  program ends**: `PATH: a thread ended with an error that no Thread.value / Thread.join read:` followed by the
  error's report, indented. The checker requires empty stderr, so an example whose thread raises must read the
  thread with value / join (and rescue).
- `Mutex.synchronize(m) { Mutex.synchronize(m) { } }` → ThreadError `deadlock; recursive locking`.
- **New** `Socket.==(x, Any)`, `Socket.!=(x, Any)`, `TCPServer.==`, `TCPServer.!=`: true for the same socket
  (identity), false for anything else. Add a `## ==, !=` section to both chapters.
- `Socket.connect` to a name that does not resolve → IOError (Ruby's Socket::ResolutionError, folded);
  `TCPServer.port` of a closed server → IOError `closed stream`.
- The TCPServer chapter's long example sorts `Thread.value(t)` results that may be nil: now a static `[nil]`
  report; use `Array.compact` (or check each) before sorting.

## Errata (what the writers found after this brief was written; fixed in lib the same day)

- Ruby's own RuntimeError inside a built-in (`String.undump`) is folded into **ArgumentError**, not RuntimeError.
- `Array.dig` / `Hash.dig` step into Tuples (the first version raised `Tuple does not have #dig method`).
- The runtime NaN sort message names each type once: `cannot compare elements of types Float`.
- `Array.each_cons(a, 0)` says `invalid size`; `each_slice` says `invalid slice size`.
- `Array.min_by` / `max_by`, `Hash.min_by` / `max_by` nil is level 3 too; `Hash.sort_by/min_by/max_by` get the static check.
- `MatchData.bytebegin/byteend/offset/byteoffset/match/match_length` nil is level 3, as `begin`/`end`.
- `Complex.polar` folds a Rational magnitude to a Float, as `abs`.
- `ENV.replace` is checked statically (String keys and values) and before anything changes.
- `IO.close(IO.stdout)` no longer crashes the CLI's own flush; `"fmt" % Hash[...]` works besides a Record.

## Report (your final message)

- The namespaces finished and the checker's line (`N chapters, 0 problems`).
- Every behaviour you found that this brief does not describe correctly, or that still looks like a bug (with
  the exact `bin/sake` output).
- **Usage notes**: what was awkward or pleasant while writing and running Sake code for the examples today
  (three to ten bullet points; honest, specific, with the snippet). These go into the project's usage report.
