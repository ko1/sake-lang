# chronic (natural-language dates)

`require "chronic"` → `sakelib/chronic.sake`. Test: `test/sakelib/chronic.{sake,rb}` (identical output); the gem
is **not installed**, so `test/sakelib/ref/chronic.rb` is a plain-Ruby reference with the same algorithm. Its
values follow the gem's test suite as remembered (now = 2006-08-16 14:00: "tomorrow" is 17th 12:00, "today"
19:00, "this week" Fri 07:30, "next month" the 16th, "5" 17:00, "13:00" tomorrow, "12 pm" today noon,
"aug 24" this year, "3 days ago" 13th 14:00); they are not verified against the gem.

Shape: `Chronic.parse(text, now: Time, context: :future, ambiguous_time_range: 6)` → `Time` (in `now`'s zone)
or nil. `Chronic.parse_span(...)` → `ChronicSpan` (the gem's `guess: false`). Types: `ChronicToken` (word,
kind, num, sym, parts) and `ChronicSpan` (from, to).

## API

| Ruby | Sake | |
|---|---|---|
| `Chronic.parse(text)` / `parse(text, now: t)` | `Chronic.parse(text, now: t)` | same (`now:` defaults to `Time.now`) |
| `Chronic.parse(text, context: :past)` | `Chronic.parse(text, context: :past)` | same for "this day/week/month/year", day names; the gem applies it more widely |
| `Chronic.parse(text, guess: false)` | `Chronic.parse_span(text, now: t)` | differs: a second function, so `parse` always returns `Time \| nil` |
| `Chronic.parse(text, ambiguous_time_range: :none)` / `n` | `Chronic.parse(text, ambiguous_time_range: :none)` | same |
| `Chronic.parse(text, endian_precedence: :little)` | — | missing: `7/1/2024` is always month/day/year |
| `Chronic.parse(text, hours24:, week_start:, guess: :begin)` | — | missing |
| `Chronic.time_class = ...`, `Chronic.debug` | — | missing (no module state) |
| `Chronic::Span#begin/end/width` | `ChronicSpan.from(s)` / `to` / `width` | differs: `begin`/`end` are reserved words |
| `Chronic.pre_normalize`, `Chronic::Parser#tokenize` | `Chronic.pre_normalize(text)`, `Chronic.tokenize(text)` | same idea; tokens have one kind, not a list of tags |
| `Chronic.guess(span)` | `Chronic.guess(span)` | same |
| `Chronic.numerize("twenty one")` | — | missing (number words) |

Understood: today/tomorrow/yesterday/now/tonight, this|next|last + second|minute|hour|day|week|fortnight|
month|year|day name|month name|morning|afternoon|evening|night, bare day/month/portion names, "N units
ago|from now|hence", "in N units", offsets with an anchor ("3 days from tomorrow", "2 weeks ago at 7pm"),
"may 27", "27 may 1979", "may 27th 1979", "2024-07-01", "7/1/2024", "7/1", "7/1/24", times "7pm" "7:30 pm"
"13:45" "17:30:15" "7.30" "noon" "midnight" "4:00 in the morning" "11 at night", and day + time in either
order ("7:30pm tomorrow", "friday 13:00", "january 5 at 7pm", "27 oct 2006 7:30pm", "next week 7pm").
Not understood (nil): unknown words, two times, two days, a lone number over 24, dates that do not exist.

5 public module functions (`parse`, `parse_span`, `guess`, `pre_normalize`, `tokenize`) and the two types; the handlers are internal.

## できたこと / できなかったこと

- **The gem's structure survived.** Normalize (the gem's list of `gsub`s: "tomorrow" → "next day", "noon" →
  "12:00 pm", "ago" → "past", "from" → "future", "an" → "1"), tokenize (one regexp: dates and `h:mm[:ss]`
  stay one token), tag (`ChronicToken.kind`), then handlers. The gem dispatches on the *sequence of tag
  classes* with ~40 handler patterns (`[Scalar, Repeater, Pointer]`, `[RepeaterMonthName, ScalarDay,
  SeparatorAt?, 'time?']`); here the sequence is an Array of Symbols compared with `==` (`ks == Array[:month,
  :scalar, :scalar]`) after splitting off the time-of-day tokens, which removes the `'time?'` suffix of every
  pattern. The gem's Repeater classes (`RepeaterDay#this/next`, width ordering, `find_within`) became one
  `grabber_unit(g, unit, now, context)` with a `case unit`, plus `dayname_span`, `month_span`, `portion_span`,
  `month_day`, `resolve_time`. The quirks were kept where known: "this week" starts an hour after now, "this
  month" tomorrow, weeks start on Sunday, "this wednesday" on a Wednesday is next week's, "last august" in
  August is this August, "next november" in August is this November.
- **Not ported**: multiple tags per token (the gem keeps "5" as Scalar+ScalarDay+ScalarHour+RepeaterTime and
  lets the handler pick); here a lone number becomes a time unless it sits next to a month name, decided in
  `handle`. `endian_precedence`, `week_start`, `hours24`, number words, "next 5" style, ordinals as days of
  the week ("3rd thursday"), ranges ("from 9 to 5"), "this past tuesday" beyond "last tuesday", seasons.
  `guess: false` is a separate function rather than a return-type switch (see 書き心地).
- Month offsets clamp the day ("1 month from january 31" is Feb 28); the gem lets `Time.local` overflow.

## 書き心地

- **The token-based parser.** The design question was how to hold a token that is "a number, or a month, or a
  time of day" without the gem's list of tag objects. Wrote one Struct type `ChronicToken` with a `kind`
  Symbol and three payload fields (`num`, `sym`, `parts`), each nil unless the kind uses it. Reading them
  needed `num(t) = ChronicToken.num(t) || 0`, `sym(t) = ... || :none`: two one-liners, after which `--strict`
  never complained about a nil payload. The dispatch on the kind sequence is `ks == Array[:grabber, :unit]`
  in an `if`/`elsif` ladder in `day_span`; it is the gem's handler table written out, and shorter.
  Alternatives considered: a signature String joined by spaces and matched with Regexps (would carry the gem's
  `'time?'` suffixes), or one Struct type per tag with `(Scalar|Month|Time).value(t)`; the single type won
  because every handler reads two or three tokens and `num(a)`, `sym(b)` is all it needs.
- **The checker had almost nothing to say on 300 lines.** First run of `chronic.sake` under `--strict`: one
  syntax error (`(atr in Integer ? atr : 6)` → `x in T needs its own parentheses: (x in T)`, fixed as the hint
  said) and then it ran. The reason is structural: every handler returns `ChronicSpan | nil` and `handle` checks
  `return nil if span == nil` before using it, and `Time` arithmetic (`t + 86400`, `t - t`) is closed over one
  type. The nils in the Array destructuring `h, m, s = ChronicToken.parts(time)` needed `h ||= 0` lines, which
  is also what the Ruby reference needs.
- **Return type as a function, not a flag.** The gem's `guess: false` makes `parse` return a `Span` instead of a
  `Time`; a user doing `Time.strftime(Chronic.parse(s, guess: false))` would be a type error only at that call.
  Rather than make `parse`'s result `Time | ChronicSpan | nil` for every caller, `parse_span` is its own
  function and `parse` is `guess(parse_span(...))`. The same decision as strscan's `do_scan` note: a flag does
  not specialize the result type, a function does.
- **A field cannot be named `begin` or `end`.** `attr_reader begin, end` for the gem's `Span#begin/#end` does
  not parse; the spec's `attr_reader :begin` form would read as `ChronicSpan.begin(s)`, which is still odd next
  to `begin ... end` blocks, so the fields are `from`/`to`.
- **Hash literals for tables.** The month/day/unit tables are `def months = once { Hash["jan" => 1, ...] }`;
  reading one gives `Integer | nil`, so `months[String.[](w, 0, 3)] || 0` where Ruby writes `MONTHS[w[0, 3]]`.
  Fine, but the `|| 0` is a lie the type forces (the regexp before it guarantees a hit); `Hash.fetch` would be
  honest and raise, at the price of a longer line.
- **Where Sake helped**: the twin is a transliteration (`Array.find(cands) { |c| c >= lower }` ↔
  `cands.find { ... }`, `Time.wday(d)` ↔ `d.wday`), and their outputs matched on the first diff after the Sake
  side was debugged, over 130 inputs. The Sake code carries the types of every step (`Time.year(now)`,
  `ChronicSpan.from(span)`), which made the hour-arithmetic bugs (a `+ 1` hour on "this week") easy to find by
  reading. Modifier `while` (`d += step while Time.wday(d) != wd`) and `case portion in :morning then [6, 12]`
  returning a Tuple to `lo, hi = ...` read as well as Ruby.

## Built-ins requested

- `Time.new` from a Hash or with keyword fields (`Time.new(2006, 8, 16, hour: 14)`): `mk(now, y, m, d, h, mi, s)`
  exists only to pass `Time.utc_offset(now)` as the zone every time.
- `Time.to_date` / `Date.to_time` round trips with `sakelib/date.sake` (a parser of dates would like to return
  a Date for day spans).
- `Hash.fetch` with a block, or a `Hash[...]` whose misses are a static error for literal keys: the `|| 0` after
  every table lookup is noise in a parser full of tables.
- `String.scan` with named groups as Records (`{h:, m:}`) instead of Tuples of Strings: the time/date token
  splitting does `Array.map(String.split(w, ":")) { |x| String.to_i(x) }` then `h, m, s = ...` with `||= 0`.
