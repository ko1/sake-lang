# Rails 8.1.3 activesupport, part A (2026-10-20)

The port of ActiveSupport's value-level half: the inflector, `core_ext/` (String, Array, Hash, Object,
Enumerable, Integer, Numeric, Time, Date, DateAndTime, ERB::Util, Module#delegate), Duration, TimeZone and
TimeWithZone (with a TZInfo reader over the system zoneinfo), NumberHelper, `ActiveSupport::JSON`, SafeBuffer /
`html_safe`, StringInquirer, ArrayInquirer, OrderedOptions / InheritableOptions, HashWithIndifferentAccess.
Part B (callbacks, concern, notifications, cache, ...) is another agent's.

```
require "rails/activesupport/active_support/core_ext"   # String/Array/Hash/Object/... extensions, ERB::Util
require "rails/activesupport/active_support/time"       # Duration, TimeZone, TimeWithZone, Time/Date calculations
require "rails/activesupport/active_support/json"       # ActiveSupport::JSON.encode / decode, Object.as_json
```

Tests (`ruby -Ilib test/test_sakelib.rb -n /rails_activesupport_/`; each `.sake` beside a `.rb` on the real gem,
written line by line in parallel): `test/sakelib/rails/activesupport/` inflector, core_ext, time_with_zone,
output_safety, json, string_inquirer, ordered_options, hash_with_indifferent_access, number_helper, delegation
(10 pairs, all identical). The three flat tests `test/sakelib/active_support_{inflector,core_ext,number_helper}`
still pass: the flat files are now a `require` of the tree plus aliases (`StringExt = String`, `Blank = Object`,
`IntegerExt = Integer`, `NumericExt = Numeric`, `SoleItemExpectedError = Enumerable::SoleItemExpectedError`,
and `ActiveSupport::Inflector.acronym(w)` & co. on the :en table).

## What is ported

Code lines = lines that are not blank or comments. The Ruby column counts the whole Ruby file(s) the Sake file
names in its header (a `partial:` file ports less than that).

| Ruby (activesupport-8.1.3/lib/active_support/) | Sake | Ruby lines | Sake lines |
|---|---|---:|---:|
| inflector.rb, inflector/{inflections,methods,transliterate}.rb, inflections.rb | inflector.sake, inflector/*.sake, inflections.sake | 375 | 328 |
| core_ext/string/{filters,access,indent,starts_ends_with,exclude,strip,inflections}.rb | core_ext/string/*.sake | 164 | 117 |
| core_ext/string/output_safety.rb, core_ext/erb/util.rb | core_ext/string/{output_safety,safe_buffer}.sake (+ generator), core_ext/erb/util.sake | 293 | 196 |
| core_ext/array/{access,grouping,conversions,wrap,extract_options,extract}.rb, core_ext/enumerable.rb | core_ext/array/*.sake, core_ext/enumerable.sake | 311 | 180 |
| core_ext/hash/{deep_merge,deep_mergeable,keys,deep_transform_values,reverse_merge,indifferent_access}.rb | core_ext/hash/*.sake | ~110 | 72 |
| core_ext/object/{blank,deep_dup,duplicable,inclusion,to_query,to_param,json}.rb | core_ext/object/*.sake | 393 | 154 |
| core_ext/integer/{inflections,multiple,time}.rb, core_ext/numeric/{time,bytes,conversions}.rb | core_ext/integer/*.sake, core_ext/numeric/*.sake | 131 | 70 |
| core_ext/date_and_time/calculations.rb, core_ext/time/{calculations,conversions,zones}.rb, date_and_time/zones.rb, core_ext/date/{calculations,conversions}.rb | core_ext/date_and_time, time, date | 652 | 331 |
| duration.rb, duration/iso8601_{parser,serializer}.rb | duration.sake (one file, see friction) | 498 | 218 |
| values/time_zone.rb, time_with_zone.rb, time.rb | values/time_zone.sake, time_with_zone.sake, time.sake | 700 | 407 |
| number_helper.rb, number_helper/*.rb (10 files) | number_helper.sake (moved from the flat port) | 491 | 207 |
| json.rb, json/{encoding,decoding}.rb | json.sake, json/*.sake | 217 | 61 |
| string_inquirer.rb, array_inquirer.rb, core_ext/{string,array}/inquiry.rb | string_inquirer.sake, array_inquirer.sake | 52 | 48 |
| ordered_options.rb | ordered_options.sake | 81 | 83 |
| hash_with_indifferent_access.rb | hash_with_indifferent_access.sake | 228 | 141 |
| delegation.rb, core_ext/module/delegation.rb | delegation.sake, core_ext/module/delegation.sake | 164 | 39 |
| (Sake only) | as_json.sake, generate/{inquirers,ordered_options,delegation}.sake, core_ext/string/safe_buffer_unsafe_methods.sake | — | 61 |
| aggregators: core_ext.rb, core_ext/{string,array,hash,object,integer,numeric,time,date}.rb | the same names | 63 | 41 |
| **activesupport total** | 68 Sake files | **≈4,900** | **2,735** |
| tzinfo-2.0.6 timezone, timezone_offset, timezone_period, data_sources/zoneinfo_reader | `sakelib/tzinfo.sake` | 603 | 151 |

Largest check: `core_ext.sake` test, `bin/sake -c --strict` **1.41 s, 67 MB**; time_with_zone 1.12 s, json 1.15 s,
HashWithIndifferentAccess 1.25 s; all of part A required together (`core_ext` + `time` + `json` + number_helper +
ordered_options + delegation) 1.18 s / 57 MB (machine load ≈3.5 while measuring; single runs, not repeated).

## Rails' metaprogramming, given a Sake shape

**Monkey patches → operations added to the built-in class.** Sake lets a library add operations to `String`,
`Array`, `Hash`, `Integer`, `Float`, `Time`, `Date`, so the extension keeps Rails' receiver; the receiver becomes
the first argument.

```ruby
"  a  b ".squish            # Ruby                     String.squish("  a  b ")      # Sake
[1, 2, 3].in_groups_of(2)                              Array.in_groups_of(Any[1, 2, 3], 2)
2.hours.ago(t)                                         ActiveSupport::Duration.ago(Integer.hours(2), t)
1.5.days                                               Float.days(1.5)
nil.blank? / x.blank? (any object)                     Object.blank?(x)    # `module Object`: Sake has no Object type
```

`Numeric` is Ruby's class; here `module Numeric` (a mixin with the time and byte methods) that `class Integer` and
`class Float` include, so `Integer.hours(2)`, `Float.hours(1.5)` and `Numeric.hours(x)` all exist — the same
structure as Ruby's.

**A module included by several classes → a Sake mixin.** `DateAndTime::Calculations` is included by Time, Date and
(new here) TimeWithZone. A bare `month(x)` in the mixin calls the includer's own (`Time.month`, `Date.month`); the
`acts_like?(:time) ? x.beginning_of_day : x` checks became small functions each includer defines
(`first_hour`, `last_hour`, `midnight_if_time`, `copy_time_to`). Ruby reaches TimeWithZone's calculations
through `method_missing` to the wall-clock Time; including the same module gives the same answers (the test
checks `next_week`, `beginning_of_month`, `end_of_month`, `next_occurring`... against Ruby).

**`method_missing` → a function taking the method's name, plus generated predicates.**

```ruby
Rails.env.production?                     # Ruby: method_missing compares "production"
StringInquirer.inquire(env, :production?) # Sake: the body of method_missing, the name as a Symbol
generate "rails/activesupport/active_support/generate/inquirers", "production", "development"
StringInquirer.production?(env)           # generated: def production?(x) = inquire(x, :production?)

config.log_level = :debug                 # Ruby (OrderedOptions#method_missing)
OrderedOptions.option(config, :log_level=, :debug)
generate ".../generate/ordered_options", "log_level"   # writes log_level(o), set_log_level(o, v), log_level!(o)
```

The name `method_missing` itself is rejected by Sake even as an ordinary function, so the bodies are named
`inquire` / `option`.

**`class_eval` over a list of names → `generate`.** SafeBuffer's 39 unsafe String methods (`upcase` gives a String,
`upcase!` marks the buffer unsafe) are written by `core_ext/string/safe_buffer_unsafe_methods.sake`, the same loop
as Ruby's `UNSAFE_STRING_METHODS.each { class_eval ... }`.

**`delegate :name, to: :author` → Rails' own `Delegation.generate`.** Ruby's delegation.rb already builds source
strings and evals them; the port keeps that function (it returns Sake source) and a generator calls it:

```ruby
class Post                                         # Sake
  delegate :name, to: :author                      generate ".../generate/delegation", "Post", "to=author:User", "name"
  delegate :email, to: :author, prefix: true,      generate ".../generate/delegation", "Post", "to=author:User", "prefix=true", "allow_nil=true", "email"
           allow_nil: true                         # → def Post.author_email(obj)
end                                                #     target = @author
                                                   #     target ? User.email(target) : nil
                                                   #   end
```

Sake needs the target's type (`User.email(target)`), so `to:` is `"author:User"`; arguments are counted
(`"greet/1"`), since Sake cannot forward `...` to an unknown function. The nil-target message is Rails'.

**Per-class `as_json` → `module ActiveSupport::AsJson`.** Ruby defines `as_json` in some twenty classes;
`Object.as_json(x)` is one `case` over the built-in types, and every type that includes `ActiveSupport::AsJson`
(Duration, TimeWithZone, SafeBuffer, HashWithIndifferentAccess, OrderedOptions, StringInquirer, and a program's
own classes) answers with its own. Ruby's fallback (`instance_values`) has no Sake form.

**`Inflector.inflections(:en) do |inflect| inflect.plural ... end`** stays a block: `inflections` yields the
`Inflections` object (a real class now, with `Uncountables`), and inflections.rb's default rules are that block at
the top level of inflections.sake. Ruby's gsub blocks that read `$1`/`$2` (camelize, underscore) go through
`Inflector.gsub_match`, which yields the MatchData.

**Subclasses of String / Hash → classes holding one.** SafeBuffer holds the String and the `@html_unsafe` flag;
HashWithIndifferentAccess holds a Hash with String keys (`include Indexable`, so `params[:page]` reads as Ruby);
OrderedOptions holds a Hash of Symbol keys and an optional parent (InheritableOptions is OrderedOptions with a
parent: `ActiveSupport::InheritableOptions.new(parent)` is a module function, as no class can be a Hash and an
OrderedOptions at once).

## What is not ported, and why

- `constantize` / `safe_constantize`, `Object#try`, `with_options`, `instance_values`-based `as_json`,
  `delegate_missing_to`, `Module#attr_internal`, `mattr_accessor` (part B has class_attribute): reflection or
  `send`.
- Locales other than :en in the inflector and NumberHelper; `transliterate(locale:)`; I18n connectors in
  `to_sentence`.
- `Array#to_xml`, `Hash#to_xml`/`from_xml` (XmlMini, Builder), `Date#to_time`/`xmlschema` redefinition,
  `Time.===`, `Time.at` with a TimeWithZone, `Time.rfc3339`, `TimeZone#strptime`/`rfc3339`/`us_zones`/
  `country_zones`, `all_day`/`all_week` (Ranges of times), Multibyte/`mb_chars`, `Range#sum`, `SafeBuffer#[]=`/
  `bytesplice`, YAML coders.
- TZInfo: no POSIX-TZ footer rule (times after a fat zoneinfo's last transition, 2037, keep its offset); a DST
  offset's base offset is the previous standard offset (tzinfo's heuristic is longer); no leap seconds.
- `Date#inspect` is not replaced by `readable_inspect` (sakelib/date's `Date.inspect` cannot be redefined), so
  `p(date)` differs from Rails; the test prints `Date.readable_inspect(d)`.

## Built-ins Sake lacks (none blocking)

- Time zones: `Time.new(..., in: "America/New_York")` accepts only fixed offsets. `sakelib/tzinfo.sake` reads
  `/usr/share/zoneinfo` (TZif v2) in Sake, as the tzinfo gem does without tzinfo-data, so no built-in was needed;
  a built-in IANA zone (`Time.getlocal(t, "Asia/Tokyo")`) would make it unnecessary.
- `NoMethodError` as a built-in exception (StringInquirer raises `ActiveSupport::NoMethodError`;
  `ActiveSupport::DelegationError < StandardError`, Ruby's `< NoMethodError`).

## Bugs (repro in experiments/2026-10-20-rails-scale/bugs/)

- `activesupport_a_string_percent_array.sake`: `"%s-%s" % xs` with `xs = String[...]` is rejected
  (`Arithmetic.%: the operands are (String, String[])`); Ruby prints `a-b`. A Tuple works. SafeBuffer#% uses
  `format(@str, *xs)` instead.

## 書き心地 (friction: what I wrote first → the message → what I wrote instead)

- Split Duration as Rails does (duration.rb + duration/iso8601_parser.rb reopening `class Duration`) →
  `error: the fields of ActiveSupport::Duration are declared in its first class ActiveSupport::Duration (line 4)`.
  A file's `require`s are read before its own classes, even a `require` written at the end of the file, so a
  sub-file that reopens the class always comes first. → One file for the three. The same rule broke two more
  layouts: SafeBuffer's generated methods (the `generate` output is joined before the class it extends → the
  class moved to safe_buffer.sake and output_safety.sake joins the two), and delegation (`class Post` printed by
  the generator came before the test's own `class Post` → the generator prints `def Post.name(obj)`, which may
  come first). This is the most surprising rule I met: Ruby's "reopen the class later" is the normal way to split
  a big class across files, and here order of loading, not order of text, decides.
- `class Time; def zone = ...` (Rails' `Time.zone`) → `error: Time.zone is a built-in operation and cannot be
  redefined`: Ruby's class method and instance method share the name, Sake's one namespace cannot. → `Time.current_zone`,
  `Time.set_zone(z)`, `Time.zone_now`. Same for `Date.yesterday` (class) vs `Date.yesterday(d)` (DateAndTime) →
  `Date.yesterday_date`, and `ActiveSupport::TimeZone["Tokyo"]` (in Sake `T[...]` is an Array literal) →
  `TimeZone.lookup("Tokyo")` (or Rails' `Time.find_zone!`).
- `def method_missing(si, name)` as a plain function, called from generated code → `error: method_missing is not
  allowed in Sake (it defeats static analysis)` at the *call*; the definition was accepted. → renamed `inquire`/`option`.
- `ARGV[0]` in a generator → `undefined type or module ARGV` (hint: `Array.first(ARGV)`). Good hint.
- `_ = @author` in generated code → `` `_` is the previous statement's value ``. → `target`.
- `Hash.dig(v, *rest)` → `the first 2 argument(s) of Hash.dig are written out; a splat fills only the rest`. → write
  the first key out, or walk the keys (HashWithIndifferentAccess#dig now steps through its own values, which is
  also needed because `Array.dig` cannot enter a HashWithIndifferentAccess).
- Inside `class SafeBuffer`, `dup(@str)` called SafeBuffer.dup (the class's own `dup`) → `SafeBuffer.str: argument 1
  must be SafeBuffer, but is String`. → `Kernel.dup(@str)`. Reasonable, but easy to fall into when porting a
  method that shares a Kernel name.
- `Time.change(t, Hash.of(hour: 0))`: Rails' options Hash has values of several types (Integer, Rational sec,
  offset String), so every `options.fetch(:year, year)` is `Integer|String|...` → `Time.new` rejects it. →
  `opt_int` / `opt_num` helpers that narrow (and raise on a wrong type). Rails' code read better; the Sake version
  states what each option may be.
- `Array.minimum(people) { |x| x[:age] }` over `Any[Hash.of(name: "ann", age: 30), ...]` → `Array.min: elements
  ... (nil, Integer), (Integer, String)` — correct: `x[:age]` may be the name. → the test uses a typed Array. A
  Record would type it, but Records have no `[]`, so `pluck(:name)` would not work on them.
- Writing `'>'` in a tool call: the JSON layer turned it into `>` before the file was written; the checker was
  right and the escapes silently vanished. (Not Sake's fault; worth knowing for agents.)
- Good: the checker accepted `module Object`, `class Integer; include Numeric; end`, type aliases of built-in
  types (`StringExt = String`), mixins whose bare calls reach built-in operations, and TimeWithZone's full
  arithmetic with Durations at the first try; most files ran identical to Rails on the first run (time_with_zone's
  130 lines of output differed only in `Date#inspect`).
