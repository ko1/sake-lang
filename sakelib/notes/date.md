# date (Ruby's `require "date"`)

`sakelib/date.sake` ports `Date` (not `DateTime`). It has about 65 operations. Test: `test/sakelib/date.sake` / `date.rb`
(identical output, `--strict`; the .sake also passes `--strict=3`).

## Representation

- `class Date < {reader: [jd, year, month, day]}`: the Julian Day Number plus the civil date, cached.
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
| `Date.new(y, m, d)`, `Date.civil(y, m, d)` | `Date.civil(y, m, d)` | differs: `Date.new` is the Struct's raw constructor `(jd, year, month, day)`, which a type cannot redefine. `Date.new(2024, 1, 31)` is a static arity error (given 3, expected 4), so it is not silently wrong |
| `Date.new(y, -1, -1)` (negative month/day) | `Date.civil(y, -1, -1)` | same |
| `Date.new(y)`, `Date.new(y, m)` (defaults) | — | missing: no optional parameters; write `Date.civil(y, 1, 1)` |
| `Date::Error` | `DateError` | differs: no nested names (`A::B`). In Ruby it is an `ArgumentError` subclass; Sake has no hierarchy, so `rescue ArgumentError` does not catch it. Message `invalid date`, same |
| `Date.valid_date?` / `valid_civil?` / `valid_ordinal?` / `valid_commercial?` / `valid_jd?` | same names | same |
| `Date.leap?(y)`, `Date.gregorian_leap?(y)`, `Date.julian_leap?(y)` | same | same |
| `d.leap?` | `Date.leap?(d)` | same (one op takes an Integer or a Date, by `case/in`) |
| `Date.jd(n)` / `d.jd` | `Date.jd(n)` / `Date.jd(d)` | same (one op, Integer → Date, Date → Integer); `Date.get_jd(d)` also works |
| `Date.ordinal(y, yd)`, `Date.commercial(y, w, d)` | same | same (negative yd/w/d count from the end) |
| `Date.today` | `Date.today` | same (from `Time.now`, local) |
| `year month mon day mday wday yday mjd ajd ld start` | `Date.year(d)` ... | same |
| `cwyear cweek cwday` | same | same (ISO 8601 week) |
| `julian? gregorian? sunday? .. saturday?` | same | same |
| `d + n`, `d - n`, `d - d2` | same operators | same (`d - d2` is a Rational) |
| `d >> n`, `d << n` | same operators | same, end of month clamped (`2024-01-31 >> 1` is 02-29) |
| `next_day prev_day next_month prev_month next_year prev_year` | `Date.next_day(d)` ... | differs: no count argument (no optional parameters). `next_day(n)` → `d + n`; `next_month(n)` → `d >> n`; `next_year(n)` → `d >> 12 * n` |
| `succ`, `next` | same | same |
| `<=> < <= > >= == !=`, `Comparable`, `sort`/`min`/`max` | same | same; `<=>` takes Dates only (Ruby also compares with Numerics as ajd) |
| `step(limit, by = 1) {}` | `Date.step(d, limit, by) {}` | differs: `by` is required; `by == 0` raises `ArgumentError` (Ruby loops forever) |
| `upto(max) {}`, `downto(min) {}` | same | same; without a block (Enumerator) missing |
| `to_s`, `inspect` | same | same (`#<Date: 2024-01-31 ((2460341j,0s,0n),+0s,2299161j)>`) |
| `iso8601 xmlschema rfc3339 httpdate rfc2822` | same | same |
| `jisx0301`, `rfc822`, `asctime`, `ctime` | — | missing (asctime is `strftime(d, "%c")`) |
| `strftime(fmt)` | `Date.strftime(d, fmt)` | same for `Y C y m d e j H M S I l L N s Q u w U W V G g A a B b h p P z :z ::z Z n t % F D x T X R r c v +` with flags `- _ 0 ^ #` and width; `E`/`O` modifiers missing (output verbatim) |
| `Date.parse(s)` | same | differs: only these forms: `Y-M-D` (anywhere, so ISO date-times), `Y/M/D`, `YYYYMMDD`, `D Mon [Y]`, `Mon D[,] [Y]` (with optional weekday, ordinal suffix, two-digit year: 69-99 → 19xx, else 20xx; no year → this year). Ruby's heuristic parser accepts far more (times, `M/D/Y`, era names, ...). No `comp` argument |
| `Date._parse`, `Date._iso8601` (hashes) | — | missing |
| `Date.iso8601(s)` | same | same for `YYYY-MM-DD`, `YYYYMMDD`, ordinal `YYYY-DDD` / `YYYYDDD`, week `YYYY-Www-D` / `YYYYWwwD`, an optional trailing `T...` |
| `Date.strptime(s, fmt = "%F")` | `Date.strptime(s, fmt)` | differs: `fmt` required. Directives `Y y m d e j b B h a A u w F D x n t %`; missing year → this year, month/day → 1; text after the format is ignored, as Ruby. No `%G/%V/%U/%W` |
| `Date::MONTHNAMES`, `ABBR_MONTHNAMES`, `DAYNAMES`, `ABBR_DAYNAMES` | `Date.monthnames` ... | differs: no value constants, so functions returning a new Array |
| `to_date`, `to_time` | same | same (`to_time` uses `Time.new`, proleptic Gregorian, local time) |
| `Date::ITALY`, `ENGLAND`, `new_start`, `italy`, `england`, `julian`, `gregorian` | — | missing (one fixed calendar) |
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
- **`Date.new`** cannot validate (see the table). A Sake type cannot hide or replace its constructor.
- **Helpers live in `module DateCore`** (module functions), since Sake has no private methods; they are
  visible to user code.

## Built-ins Sake lacks (requests)

- **Hash keys for types with `<=>`** (or a declared `hash`/key function): Dates and similar value types are
  natural keys; today every Comparable type is excluded.
- **Optional parameters** (or arity overloading for user functions): `next_day(n = 1)`, `step(limit, by = 1)`,
  `strptime(s, fmt = "%F")`, `Date.new(y, m = 1, d = 1)` all lose a form.
- **A replaceable `new`** (or a way to make a Struct's raw constructor private), so `Date.new(y, m, d)` can
  validate like Ruby.
- **Writable Record fields** (spec §16): the strptime cursor is a one-element Tuple `[pos]` instead of `{pos: 0}`.
- **`String#[]` with a start only** / `String.slice` with a Range is there, but a `rest_from(s, i)` idiom
  needs `String.[](s, i, String.size(s) - i) || ""` each time; a non-nil substring op would cut noise.

## Friction (wrote first → message → wrote instead)

- `def new(y, m, d)` in `class Date` → `` `Date.new` is a built-in operation and cannot be redefined `` →
  `Date.civil` as the validating constructor.
- `def valid_jd?(n) = n in Integer` → `only def and include are allowed in a class/module body` (Ruby parses
  it as `(def ... = n) in Integer`) → `def valid_jd?(n) = (n in Integer)`. The message does not hint at the
  parse.
- `if x in Integer ... else ... end` in `Date.jd` → callers got `Date | Integer` (`Date.get_year: argument 1
  must be Date, but can be String`) → `case x in Integer ... in Date ...`, which the checker narrows per
  call. Repro: `notes/date_bug_if_in_else.sake`.
- `jd = valid(...); while jd == nil ... end; jd(jd)` → `Date.get_jd: argument 1 must be Date, but is nil`
  (no narrowing after `while x == nil`) → `while true; jd = ...; return jd(jd) if jd != nil; ... end`.
- `scan_format(s, fmt, {pos: 0}, ...)` then `st[:pos] = ...` → Records have no write → a Tuple `[0]`
  and `st[0] = ...`.
- `require "date"` in `test/sakelib/date.sake` loaded the test file itself (fixed in the loader during this
  port).
- At `--strict=3`, every `String.[](s, i, n)` needs `|| ""`.
- Ruby's `Date#step(d, 0) {}` loops forever; the first version of the Ruby test hung (test removed).
