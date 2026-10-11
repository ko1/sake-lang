# fugit (Fugit::Cron, Fugit::Duration)

`require "fugit"` → `sakelib/fugit.sake`. Test: `test/sakelib/fugit.{sake,rb}` (identical output; every
Time in the test is a fixed `Time.new(..., "UTC")`, never the clock). Ported from fugit 1.12.2
(`cron.rb`, `duration.rb`, `misc.rb`, part of `parse.rb`), with the pieces of et-orbi (`wday_in_month`,
`rweek`) and raabro (the grammar engine) that they rely on.

Names nest as in Ruby: `Fugit::Cron`, `Fugit::Cron::TimeCursor`, `Fugit::Cron::CronIterator`,
`Fugit::Duration`, module functions `Fugit.parse_cron(s)` etc.

## API

| Ruby | Sake | |
|---|---|---|
| `Fugit::Cron.parse(s)` / `Fugit::Cron.new(s)` / `Fugit.parse_cron(s)` | `Fugit::Cron.parse(s)` / `Fugit.parse_cron(s)` | same (nil when invalid); `Cron.new` is Sake's field constructor, so `new(s)` is not the parser |
| `Fugit::Cron.do_parse(s)` / `Fugit.do_parse_cron(s)` | same | same (ArgumentError, Ruby's message) |
| `c.original`, `c.zone`, `c.seconds`, `c.minutes`, `c.hours`, `c.monthdays`, `c.months` | `Fugit::Cron.original(c)` … | same |
| `c.weekdays` | `Fugit::Cron.weekdays(c)` | same shape (`[[1], [5, -1], [2, [2, 1]]]`); built from an internal `Weekday` class |
| `c.timezone` | `Fugit::Cron.timezone(c)` | differs: a String (`"+09:00"`, `"UTC"`), Ruby a TZInfo object |
| `c.to_cron_s`, `c.to_a`, `c.to_h`, `c == o` | `Fugit::Cron.to_cron_s(c)` …, `c == o` | same |
| `c.next_time(t)` / `c.previous_time(t)` | `Fugit::Cron.next_time(c, t)` / `previous_time` | same (returns a Time; Ruby an EtOrbi::EoTime) |
| `c.match?(t)` | `Fugit::Cron.match?(c, t)` | same for a Time; Ruby also takes a String (`Fugit::At`) |
| `c.next(t).take(3)` / `c.prev(t)` | `Enum.take(Fugit::Cron.next(c, t), 3)` / `prev` | same (an endless `include Enum` class) |
| `c.within(t0..t1)` / `c.within(t0, t1)` | `Fugit::Cron.within(c, t0, t1)` | differs: no Range form (a Range of Times cannot be made) |
| `c.rough_frequency` | `Fugit::Cron.rough_frequency(c)` | same |
| `c.brute_frequency`, `Frequency` | — | missing (a year of next_time calls; slow in the interpreter) |
| `Fugit::Duration.parse(s, opts)` / `Fugit.parse_duration(s)` / `parse_in` | `Fugit::Duration.parse(s, Hash[iso: true])` … | same (s a String, Integer, Float or Duration); opts a Hash |
| `Fugit::Duration.do_parse(s)` | same | same |
| `d.h` / `d.to_h`, `d.original`, `d.options` | `Fugit::Duration.h(d)` … | same (`original` is always a String: `"3700"` for 3700) |
| `d.to_plain_s`, `to_iso_s`, `to_long_s(oxford: false)`, `to_rufus_s`, `to_rufus_h`, `to_sec` | `Fugit::Duration.to_plain_s(d)` …, `to_long_s(d, Hash[oxford: false])` | same |
| `Fugit::Duration.to_plain_s(s)` (parse, deflate, print) | `Fugit::Duration.to_plain_s(s)` | same: one operation takes a Duration or a String |
| `d.inflate`, `d.deflate(month: true, year: 365)` | `Fugit::Duration.inflate(d)`, `deflate(d, Hash[month: true])` | same |
| `d.opposite`, `-d` | `Fugit::Duration.opposite(d)`, `-d` | same (`include Arithmetic`, `def -@`) |
| `d + 60`, `d + d2`, `d + "1d"`, `d - d2` / `add` / `subtract` | same | same |
| `d + time` / `d.add(time)` | `Fugit::Duration.add_to_time(d, t)` | differs: `+` returns a Duration, so the Time case is its own operation |
| `d - time` | `Fugit::Duration.subtract_from_time(d, t)` | differs: same reason |
| `d.next_time(t)`, `d.drop_seconds`, `d == o` | same with `Fugit::Duration.` | same |
| `Fugit.parse(s)` | `Fugit.parse(s)` | differs: cron, then duration; no `Fugit::Nat` ("every day at noon") or `Fugit::At` |
| `Fugit.time_to_plain_s(t)`, `time_to_zone_s(t)` | same | same |
| `Fugit::Nat`, `Fugit::At`, `Fugit.parse_nat`, `Fugit.isostamp` | — | missing (natural language: 750 more lines) |

About 45 operations.

## What differs and why

- **Zones.** Sake's Time has UTC and fixed offsets, no tzinfo. A cron's trailing zone may be an
  offset (`+09:00`, `+0900`, normalised to `+09:00`) or `UTC`/`GMT`/`Etc/UTC`; any other name
  (`Europe/Berlin`) makes `parse` return nil, where Ruby accepts it. The result of `next_time` is in the
  zone of its argument (UTC or that offset). Ruby's EtOrbi turns a fixed-offset Time into the machine's
  local zone, so Ruby's answer for a `+09:00` argument depends on the machine; the test uses UTC only.
  The DST branches of `TimeCursor#inc_day` (`TZInfo::PeriodNotFound`) and the "same wall time twice"
  check in `next_time` are not needed with fixed offsets and were left out.
- **The grammar.** raabro (a PEG library built on method names and `send`) is not ported. The cron
  grammar is regular, so each field is one anchored Regexp (`(?>...)` atomic groups keep the PEG's
  no-backtracking inside an atom); fields are split on blanks, second_cron (6 fields) is tried before
  classic_cron (5), each with an optional zone, as Ruby's `alt`. Ruby allows `1, ,2` (blanks between
  commas); Sake splits there. The duration grammar (`sign? elt+` joined by `sep`) is a loop of
  `Regexp.match(re, s, pos)` with `\G` regexps tried in Ruby's order.
- **Weekdays.** Ruby keeps `[[1], [5, -1], [2, [2, 1]]]`: Arrays of different shapes. A Sake Array has one
  element type, so the cron keeps a `Weekday` class (wday, hash, mod) and `weekdays(c)` builds Ruby's
  shape on demand (an `Array[Integer | Array[Integer]]`). Sorting uses a key that orders like Ruby's
  Array comparison.
- **Ruby's `false` vs `nil` in `do_determine`** (false: invalid, nil: any): returns `[valid, values]`.
- **`wday_in_month` / `rweek`** are computed (`(day - 1) / 7 + 1`, days since 2018-12-31 / 7) instead
  of et-orbi's week-by-week loop; the same numbers.
- **Constants** (`SPECIALS`, `MAXDAYS`, `KEYS`, `DAY_S`) are functions (`once { }` for the tables).
  `KEYS` (a Hash of Hashes) is an Array of Tuples `[key, plain, rufus, iso, seconds, inflatable, long]`.

## Built-ins Sake lacks (requests)

- A Range of Times (`t0..t1`): `within` takes two arguments.
- `Array.uniq` with a block (Ruby's `uniq { }`): written with a Set.
- Named time zones (tzinfo) in Time: crons with zone names are rejected.

## Friction

- `{seconds: ..., minutes: ...}` for Ruby's `to_h` → printed `{hours: ..., minutes: ..., ...seconds: ...}`
  (a Record shows its fields sorted, Ruby's Hash keeps insertion order) → `Hash[seconds: ...]`.
- `h[:sec] = s in Float ? Float.round(s, 9) : s` → `syntax error: unexpected '?'` (hint: `x in T` needs
  its own parentheses) → `(s in Float) ? ...`. The hint was exact.
- `Array.uniq(wds) { |w| key(w) }` → `Array.uniq does not take a block` → a `Set.add?` filter.
- `def keys = [[:yea, "Y", ...], ...]` → `Array.each: argument 1 must be Array, but is [[:yea, String, ...` →
  `Array[[...], ...]`. The `[...]` is a Tuple rule bites on every table literal.
- `Fugit::Cron.within(c, t0..t1)` → runtime `TypeError: a Range end must be Integer, Float, or String,
  got Time` (not a static error) → two arguments.
- `def ==(a, b) = Cron.to_a(a) == Cron.to_a(b)` → `Fugit::Cron.wdays: argument 1 must be Fugit::Cron, but
  can be Fugit::Duration` (because `Fugit.parse` returns Cron | Duration, `==` may see either) →
  `return false unless b in Cron` first, which is what Ruby's `o.is_a?(::Fugit::Cron)` does anyway.
- `Fugit::Duration.add(d, x)` with Ruby's four cases (number, Duration, String, Time) types its result
  `Duration | Time`, and every `(d + d2).h` then needs a check → the Time case became `add_to_time`, and
  `+` / `-` (`include Arithmetic`) return a Duration only.
- In the tests, Ruby's `Fugit::Cron.parse(s).to_cron_s` must become `do_parse` (or a check) in Sake,
  because `parse` may return nil: the Sake test uses `do_parse` where the Ruby one uses `parse`.
- What went well: the first full draft (about 1000 lines) ran after the six static errors above; every
  `next_time` / `previous_time` matched Ruby's on the first run. The only output difference was
  `Duration.parse("")` (Ruby's `jseq` accepts zero elements, giving `{sec: 0}`).

## Size

Ruby (non-blank, non-comment lines): cron.rb 634 + duration.rb 271 + misc.rb/parse.rb ~25 ≈ 930 (plus
raabro's engine and et-orbi, not counted). Sake: 884 lines (1056 with comments and blank lines).
Tests: 196 lines Ruby, 197 Sake.
