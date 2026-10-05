# date (Ruby's `require "date"`)

`sakelib/date.sake` ports `Date` (not `DateTime`). It has about 65 operations. Test: `test/sakelib/date.sake` / `date.rb`
(identical output, `--strict`; the .sake also passes `--strict=3`).

## Representation

- `class Date` with `attr_reader year = -4712, month = 1, day = 1` and `private attr_reader start = DateCore.italy, jd = nil`: the civil date plus its Julian
  Day Number, which `initialize` computes (and checks) for every `Date.new`.
- **Calendar: Ruby's default `Date::ITALY`.** Julian before 1582-10-15 and Gregorian from then on, as
  Ruby does, so `Date.civil(1582, 10, 4) + 1` is 1582-10-15, 1582-10-10 is invalid, and 1000-02-29
  exists. The algorithms are Ruby's `c_civil_to_jd` / `c_jd_to_civil` in integer arithmetic. Other
  reform dates (`Date::ENGLAND`, `start` argument) are not supported.
- **Date - Date is a Rational** (`(29/1)`), as in Ruby, since Sake has Rational. `Rational.to_i(d2 - d1)`
  gives the day count. `Date + n` / `Date - n` take an Integer only (no fractional days).
- Day numbers are Integers; `ajd` is a Rational (`(4920681/2)`), `start` a Float, as Ruby.

## API

| Ruby | Sake | |
|---|---|---|
| `Date.new(y = -4712, m = 1, d = 1)`, `Date.civil(...)` | same | same (since 2026-10-05: field defaults + `initialize`, which raises `DateError` for an invalid date). The fourth argument is Ruby's `start` (since the second 2026-10-05 change; only `Date.ITALY`, else `ArgumentError`). A non-Integer year/month/day is a `type` report at the call (`@year => Integer` in initialize); Ruby raises `TypeError` |
| `Date.new(y, -1, -1)` (negative month/day) | same | same |
| `Date.new`, `Date.new(y)`, `Date.new(y, m)` (defaults) | same | same |
| `Date::Error` | `DateError` | differs: no nested names (`A::B`). In Ruby it is an `ArgumentError` subclass; Sake has no hierarchy, so `rescue ArgumentError` does not catch it. Message `invalid date`, same |
| `Date.valid_date?` / `valid_civil?` / `valid_ordinal?` / `valid_commercial?` / `valid_jd?` | same names | same |
| `Date.leap?(y)`, `Date.gregorian_leap?(y)`, `Date.julian_leap?(y)` | same | same |
| `d.leap?` | `Date.leap?(d)` | same (one op takes an Integer or a Date, by `case/in`) |
| `Date.jd(n)` / `d.jd` | `Date.jd(n)` / `Date.jd(d)` | same (one op, Integer → Date, Date → Integer); `Date.jd(d)` also works |
| `Date.ordinal(y = -4712, yd = 1, start)`, `Date.commercial(y = -4712, w = 1, d = 1, start)` | same | same (negative yd/w/d count from the end; defaults since phase 2; `start` must be `Date.ITALY`) |
| `Date.today` | `Date.today` | same (from `Time.now`, local) |
| `year month mon day mday wday yday mjd ajd ld start` | `Date.year(d)` ... | same |
| `cwyear cweek cwday` | same | same (ISO 8601 week) |
| `julian? gregorian? sunday? .. saturday?` | same | same |
| `d + n`, `d - n`, `d - d2` | same operators | same (`d - d2` is a Rational) |
| `d >> n`, `d << n` | same operators | same, end of month clamped (`2024-01-31 >> 1` is 02-29) |
| `next_day(n = 1) prev_day next_month prev_month next_year prev_year` | `Date.next_day(d, n = 1)` ... | same (phase 2) |
| `succ`, `next` | same | same |
| `<=> < <= > >= == !=`, `Comparable`, `sort`/`min`/`max` | same | same; `<=>` takes Dates only (Ruby also compares with Numerics as ajd) |
| `step(limit, by = 1) {}` | `Date.step(d, limit, by = 1) {}` | same, except `by == 0` raises `ArgumentError` (Ruby loops forever) |
| `upto(max) {}`, `downto(min) {}` | same | same |
| `step`, `upto`, `downto` without a block (Enumerator) | an Array of the Dates | same as the Enumerator's `to_a` (2026-10-05, as the built-in blockless `each_slice`) |
| `to_s`, `inspect` | same | same (`#<Date: 2024-01-31 ((2460341j,0s,0n),+0s,2299161j)>`) |
| `iso8601 xmlschema rfc3339 httpdate rfc2822` | same | same |
| `jisx0301`, `rfc822`, `asctime`, `ctime` | — | missing (asctime is `strftime(d, "%c")`) |
| `strftime(fmt = "%F")` | `Date.strftime(d, fmt = "%F")` | same for `Y C y m d e j H M S I l L N s Q u w U W V G g A a B b h p P z :z ::z Z n t % F D x T X R r c v +` with flags `- _ 0 ^ #` and width; `E`/`O` modifiers missing (output verbatim) |
| `Date.parse(s = "-4712-01-01", comp = true)` | same | differs: only these forms: `Y-M-D` (anywhere, so ISO date-times), `Y/M/D`, `YYYYMMDD`, `D Mon [Y]`, `Mon D[,] [Y]` (with optional weekday, ordinal suffix, two-digit year: 69-99 → 19xx, else 20xx; no year → this year). Ruby's heuristic parser accepts far more (times, `M/D/Y`, era names, ...). `comp = false` keeps two-digit years as is (phase 2) |
| `Date.parse(s, comp, limit: 128)` | `Date.parse(s, comp, limit: 128)` | same (`limit: nil` for none; `ArgumentError: string length (N) exceeds the limit L`); `start` (third positional) since 2026-10-05, `Date.ITALY` only |
| `Date._parse`, `Date._iso8601` (hashes) | — | missing |
| `Date.iso8601(s)` | same | same for `YYYY-MM-DD`, `YYYYMMDD`, ordinal `YYYY-DDD` / `YYYYDDD`, week `YYYY-Www-D` / `YYYYWwwD`, an optional trailing `T...` |
| `Date.strptime(s = "-4712-01-01", fmt = "%F", start = Date::ITALY)` | `start = Date.ITALY` | same for directives `Y y m d e j b B h a A u w F D x n t %`; missing year → this year, month/day → 1; text after the format is ignored, as Ruby. No `%G/%V/%U/%W` |
| `Date::MONTHNAMES`, `ABBR_MONTHNAMES`, `DAYNAMES`, `ABBR_DAYNAMES` | `Date.monthnames` ... | differs: functions (no value constants) whose Array is built once (`once`) and shared, as Ruby's constant; Ruby's is frozen, Sake's can be changed |
| `to_date`, `to_time` | same | same (`to_time` uses `Time.new`, proleptic Gregorian, local time) |
| `Date::ITALY` | `Date.ITALY` | differs: a function (no value constants), as `Math.PI` |
| `ENGLAND`, `JULIAN`, `GREGORIAN`, `new_start`, `italy`, `england`, `julian`, `gregorian` | — | missing (one fixed calendar; another `start` raises `ArgumentError`) |
| `DateTime`, `Time#to_date` | — | missing (`Time#to_date` would be `Date.civil(Time.year(t), Time.month(t), Time.day(t))`) |
| `hash`/`eql?`: Date as a Hash key | — | missing: see below |

## Differences and why

- **Date as a Hash key / Set element raises TypeError.** Date includes `Comparable` with `<=>`, and Sake
  rejects keys of a type with its own equality (spec §12.1). Ruby programs often group by date
  (`h[date] += 1`). Workaround: key by `Date.jd(d)` or `Date.to_s(d)`.
- **Class and instance methods with the same name** (`Date.jd`, `Date.leap?`, `Date.iso8601`) share one
  operation that branches on the argument type with `case x in Integer ... in Date ...`. The checker gives
  the precise result type per call (`Date.jd(2460341)` is a Date), and `Date.jd(1.5)` is reported before
  running (as `case/in: no in branch matches Float`, pointing into date.sake).
- **`Date.new` validates in `initialize`**, so every Date is built through the check: `Date.jd(n)` computes
  the civil date and then `Date.new` converts it back to check it (about 7% slower on `phase2/bench_date.sake`,
  1.61-1.66 s → 1.74-1.89 s user, 3 runs each, load 5.5). Ruby has a private raw constructor for this.
- **Helpers live in `module DateCore`** (module functions), since Sake has no private methods; they are
  visible to user code.

## Built-ins Sake lacks (requests)

- **Hash keys for types with `<=>`** (or a declared `hash`/key function): Dates and similar value types are
  natural keys; today every Comparable type is excluded.
- ~~A replaceable `new`~~: `initialize` (2026-10-05) does it. Still missing: a constructor that skips
  `initialize` for internal use (Ruby's `new!`/`allocate`), see above.
- **Writable Record fields** (spec §16): the strptime cursor is a one-element Tuple `[pos]` instead of `{pos: 0}`.
- **`String#[]` with a start only** / `String.slice` with a Range is there, but a `rest_from(s, i)` idiom
  needs `String.[](s, i, String.size(s) - i) || ""` each time; a non-nil substring op would cut noise.

## Friction (wrote first → message → wrote instead)

- `def new(y, m, d)` in `class Date` → `` `Date.new` is a built-in operation and cannot be redefined `` →
  `Date.civil` as the validating constructor.
- `def valid_jd?(n) = n in Integer` → `only def and include are allowed in a class/module body` (Ruby parses
  it as `(def ... = n) in Integer`) → `def valid_jd?(n) = (n in Integer)`. The message does not hint at the
  parse.
- `if x in Integer ... else ... end` in `Date.jd` → callers got `Date | Integer` (`Date.year: argument 1
  must be Date, but can be String`) → `case x in Integer ... in Date ...`, which the checker narrows per
  call. Repro: `notes/date_bug_if_in_else.sake`.
- `jd = valid(...); while jd == nil ... end; jd(jd)` → `Date.jd: argument 1 must be Date, but is nil`
  (no narrowing after `while x == nil`) → `while true; jd = ...; return jd(jd) if jd != nil; ... end`.
- `scan_format(s, fmt, {pos: 0}, ...)` then `st[:pos] = ...` → Records have no write → a Tuple `[0]`
  and `st[0] = ...`.
- `require "date"` in `test/sakelib/date.sake` loaded the test file itself (fixed in the loader during this
  port).
- At `--strict=3`, every `String.[](s, i, n)` needs `|| ""`.
- Ruby's `Date#step(d, 0) {}` loops forever; the first version of the Ruby test hung (test removed).

## Phase 2

- **Ruby's optional arguments restored** (no new names were needed, none removed): `Date.civil(y = -4712,
  m = 1, d = 1)`, `ordinal`, `commercial`, `next_day(d, n = 1)` and the other five, `step(d, limit, by = 1)`,
  `strftime(d, fmt = "%F")`, `strptime(s = "-4712-01-01", fmt = "%F")`, `parse(s = "-4712-01-01",
  comp = true)` (`comp` is new). The test covers each default.
- **Tables with `once`**: month/day names and their abbreviations, the name → number Hashes (were an
  `Array.map` + `Array.index` per lookup), and the two `Date.parse` regexps with a month name (were
  `Regexp.new` per call).
- **Position built-ins**: `strftime` walks the format with `String.index(fmt, "%", pos)` and
  `Regexp.match(re, fmt, i)` with `\G`, instead of cutting the rest of the string at each directive;
  the strptime scanner matches `\G` regexps at the cursor instead of copying the rest of the input per
  field, and compares a literal format character directly instead of building a `Regexp` for it.
- `d >> n` clamps the day by a recursive `DateCore.clamped_jd` instead of `while true ... return`: the
  checker typed the loop's fall-through as nil, so `Date.day(d >> 1)` failed `--strict` (nil).

Speed (400 days × strftime, strptime, parse, `>>`). CPU s (user+sys) of `bin/sake` on `experiments/2026-10-03-sakelib-port/phase2/bench_date.sake`, the phase-1 library (`phase2/before/`) and this one interleaved, 3 runs each, by `phase2/run_date_optparse_logger_benchmark.sh` (raw: `result_date_optparse_logger_benchmark.txt`; base commit af197cd). The machine was shared, load average about 36 on 16 CPUs. Startup with the four libraries loaded and nothing run is 0.69-0.70 s of each run.

| | run 1 | run 2 | run 3 |
|---|---|---|---|
| before | 4.81 | 4.97 | 4.98 |
| after | 4.68 | 4.87 | 4.74 |

Result: about 3% faster, at the edge of the spread: the per-directive `case` and the interpreter dominate, not the string copies.

## Keyword arguments

- `Date.parse(s = "-4712-01-01", comp = true, limit: 128)` gained Ruby's `limit:` keyword (it had no
  stand-in before; the check was missing). Test cases: `limit: 10` with `comp`, `limit: nil` on a
  140-character string, and both error messages. A misspelled keyword is a static error
  (`Date.parse(s, limt: 5)` → `error: Date.parse has no keyword parameter `limt``).
  `Date.iso8601` (also `limit:` in Ruby) is not changed: here it also formats a Date.
- Nothing else in date (or in benchmark) has a Ruby keyword.

## Review against the current language (2026-10-05)

- `Date.new(y, m, d)` is Ruby's validating constructor: fields reordered to `year = -4712, month = 1, day = 1,
  jd = nil`, and `def initialize(d)` asserts Integers (`@year => Integer`), computes `@jd` with
  `DateCore.valid_civil_jd`, raises `DateError` when invalid, and resolves negative month/day.
  `Date.civil` is now `= Date.new(y, m, d)`, as in Ruby (an alias). The test uses `Date.new` like `date.rb`.
- `DateError = Exception.new` → `class DateError < Exception`.
- Remaining frictions: `DateError` for `Date::Error` (no nested names; no `ArgumentError` parent);
  Date as a Hash key; one operation for Ruby's class and instance methods of the same name
  (`Date.jd`, `leap?`, `iso8601`, by `case x in Integer`); the strptime cursor as a Tuple `[pos]`.

## 2026-10-05 (keywords, private fields, blockless iteration)

- `start` is a field again, as Ruby's fourth argument: `private attr_reader start = DateCore.italy, jd = nil`.
  Before, a fourth argument silently filled `jd` (then overwritten by `initialize`). Now `Date.new`,
  `civil`, `ordinal`, `commercial`, `parse`, `strptime` take `start` and check it is `Date.ITALY`
  (another raises `ArgumentError`: `NotImplementedError` would not be rescuable, being a program
  error); `Date.start(d)` returns it as a Float. Both fields are private, so there is no
  `Date.set_jd`; `new` still takes them (`Date.new(y, m, d, jd: 5)` is accepted and ignored).
- `jd = nil` stays a placeholder: a field default cannot read an earlier field (`jd =
  DateCore.valid_civil_jd(year, month, day)` → `wrong number of arguments for Date.year`; `@year`
  → "`@year` needs a first argument"), unlike a Ruby parameter default `def initialize(y, m, d, jd = f(y, m, d))`.
  It also must not run before `initialize`'s `@year => Integer` check.
- `step`, `upto`, `downto` without a block return an Array (Ruby: an Enumerator; the test compares `.to_a`).
- Friction: `start = ITALY` as a default inside `class Date` → `type ITALY cannot be used as a value`
  (an uppercase bare name is a constant, as in Ruby) → `start = Date.ITALY`.
- No keyword constructor applies: Ruby's `Date.new` takes no keywords.
