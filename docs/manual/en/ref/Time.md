# Time

A Time is one instant: the seconds since 1970-01-01 00:00:00 UTC (to rational precision) and the UTC offset it is shown in. There is no literal; `Time.now`, `Time.at(seconds)` and `Time.new(year, month, day, ...)` make one ([Values and types](../03-values.md)). The values are Ruby's Times, but where Ruby's `t.utc` and `t.localtime` change t itself, every operation in Sake returns a new Time and leaves its subject alone. Time has no typed Array `Time[]`; a sequence of Times is an `Array[...]`.

**Zones.** The `in:` keyword and the zone argument of `getlocal` and `new` are fixed UTC offsets: `"+09:00"`, `"-05:00"`, `"UTC"` or `"Z"`, a military letter `"A".."I"`, `"K".."Z"`, or an Integer number of seconds. A region name such as `"Asia/Tokyo"` is not accepted (`ArgumentError`). Without `in:` the local zone of the machine applies, so every example whose output must not depend on the machine passes `in:`. A Time made with `"UTC"` or `"Z"` is in UTC mode (`utc?` is true and `to_s` ends in `UTC`); one made with `"+00:00"` is an ordinary Time at offset 0 (`utc?` is false, `to_s` ends in `+0000`).

The operators on Times are `+` and `-` (with a number of seconds on the right, Integer, Float or Rational; `Time - Time` is the difference in seconds as a Float), `==`, `!=`, `<`, `<=`, `>`, `>=` and `<=>` (with a Time on the right). The entries `Time.+(x, y)` and so on below are their function forms ([Operators and indexing](../05-operators.md)). `Time.strftime(t, fmt)` and `Time.iso8601(t)` make Strings. Reading a Time from a String (Ruby's `Time.parse`, `Time.iso8601(s)`) is not built in.

## now

`Time.now([in: String|Integer])`

The current time (a Time). With `in:` it is shown at that offset, without it in the local zone. A bad zone is an `ArgumentError`.

```ruby
t = Time.now(in: "UTC")
p(Time.utc?(t))                        # => true
p(Time.year(t) >= 2026)                # => true
p(Time.utc_offset(Time.now(in: "+09:00")))   # => 32400
```

## at

`Time.at(Integer|Float|Rational|Time, [in: String|Integer])`

The Time `seconds` after 1970-01-01 00:00:00 UTC (Ruby's `Time.at`). An Integer, a Float or a Rational; a Rational keeps its precision. Given a Time, a Time of the same instant (and the same zone when `in:` is absent). `in:` picks the zone; a bad one is an `ArgumentError`.

```ruby
t = Time.at(0, in: "UTC")
p(t)                                   # => 1970-01-01 00:00:00 UTC
p(Time.at(1.5, in: "UTC"))             # => 1970-01-01 00:00:01.5 UTC
p(Time.subsec(Time.at(1r/3, in: "UTC")))   # => (1/3)
p(Time.at(t, in: "+09:00"))            # => 1970-01-01 09:00:00 +0900
p(Time.at(t) == t)                     # => true
```

```ruby error
Time.at(0, in: "Asia/Tokyo")           # !> ArgumentError: Time.at: "+HH:MM", "-HH:MM", "UTC" or "A".."I","K".."Z" expected for utc_offset: Asia/Tokyo
```

## new

`Time.new(Integer, [Integer], [Integer], [Integer], [Integer], [Integer|Float|Rational], [String|Integer], [in: String|Integer])`

A Time from year, month, day, hour, minute, second and zone (Ruby's `Time.new(y, m, d, h, min, s, zone)`). The year is required, the rest may be left out (month and day default to 1, hour, minute and second to 0). The second may be a Float or a Rational with a fraction. The zone is either the seventh argument or `in:`, not both (`ArgumentError`), and the local zone when neither is given. A month outside 1..12, an hour outside 0..23 and so on are an `ArgumentError` (`mon out of range`). Ruby's `Time.new` without arguments (the current time) does not exist here: use `Time.now`.

```ruby
t = Time.new(2024, 2, 29, 12, 30, 45, "+09:00")
puts(Time.to_s(t))                     # => 2024-02-29 12:30:45 +0900
puts(Time.to_s(Time.new(2024, in: "UTC")))         # => 2024-01-01 00:00:00 UTC
puts(Time.to_s(Time.new(2024, 3, 4, 5, in: "UTC")))   # => 2024-03-04 05:00:00 UTC
p(Time.subsec(Time.new(2024, 1, 1, 0, 0, 7.5, in: "Z")))   # => (1/2)
puts(Time.to_s(Time.new(2024, 3, 4, 5, 6, 7, 3600)))      # => 2024-03-04 05:06:07 +0100
```

```ruby error
Time.new(2024, 13, 1, in: "UTC")       # !> ArgumentError: Time.new: mon out of range
```

## year, month, mon, day, mday, hour, min, sec

`Time.year(x)`

`Time.month(x)`

`Time.mon(x)`

`Time.day(x)`

`Time.mday(x)`

`Time.hour(x)`

`Time.min(x)`

`Time.sec(x)`

The parts of the time (Integers), read at the Time's own offset: the year, the month (1..12; `mon` is an alias), the day of the month (1..31; `mday` is an alias), the hour (0..23), the minute (0..59), the second (0..60, without its fraction, see `subsec`).

```ruby
t = Time.new(2024, 2, 29, 12, 30, 45.5, in: "+09:00")
p([Time.year(t), Time.month(t), Time.day(t)])      # => [2024, 2, 29]
p([Time.hour(t), Time.min(t), Time.sec(t)])        # => [12, 30, 45]
p(Time.mon(t) == Time.month(t))                    # => true
p(Time.hour(Time.utc(t)))                          # => 3
```

## wday, yday

`Time.wday(x)`

`Time.yday(x)`

The day of the week (an Integer, Sunday 0 to Saturday 6) and the day of the year (January 1 is 1, December 31 of a leap year 366).

```ruby
t = Time.new(2024, 2, 29, in: "UTC")
p(Time.wday(t))                        # => 4
p(Time.yday(t))                        # => 60
p(Time.wday(Time.at(0, in: "UTC")))    # => 4
```

## sunday?, monday?, tuesday?, wednesday?, thursday?, friday?, saturday?

`Time.sunday?(x)`

`Time.monday?(x)`

`Time.tuesday?(x)`

`Time.wednesday?(x)`

`Time.thursday?(x)`

`Time.friday?(x)`

`Time.saturday?(x)`

True on that day of the week. `Time.wday(t) == 4` and `Time.thursday?(t)` say the same.

```ruby
t = Time.new(2024, 2, 29, in: "UTC")
p(Time.thursday?(t))                   # => true
p(Time.friday?(t))                     # => false
p(Time.sunday?(t + 3 * 86400))         # => true
```

## nsec, usec, subsec, tv_sec, tv_nsec, tv_usec

`Time.nsec(x)`

`Time.usec(x)`

`Time.subsec(x)`

`Time.tv_sec(x)`

`Time.tv_nsec(x)`

`Time.tv_usec(x)`

The part finer than a second. `nsec` (alias `tv_nsec`) is the nanoseconds (an Integer, 0..999999999), `usec` (alias `tv_usec`) the microseconds (an Integer, 0..999999), `subsec` the fraction of the second as it is (the Integer 0, or a Rational). `tv_sec` is `to_i`, the whole seconds since 1970.

```ruby
t = Time.at(1700000000.123456789r, in: "UTC")
p(Time.nsec(t))                        # => 123456789
p(Time.usec(t))                        # => 123456
p(Time.subsec(Time.at(1.5, in: "UTC")))    # => (1/2)
p(Time.subsec(Time.at(2, in: "UTC")))      # => 0
p(Time.tv_sec(t))                      # => 1700000000
p(Time.tv_nsec(t) == Time.nsec(t))     # => true
```

## to_i, to_f, to_r

`Time.to_i(x)`

`Time.to_f(x)`

`Time.to_r(x)`

The seconds since 1970-01-01 00:00:00 UTC as an Integer (the fraction dropped), a Float, or an exact Rational. The zone plays no part. They invert `Time.at`.

```ruby
t = Time.at(1.5, in: "UTC")
p(Time.to_i(t))                        # => 1
p(Time.to_f(t))                        # => 1.5
p(Time.to_r(t))                        # => (3/2)
p(Time.to_i(Time.at(100, in: "+09:00")))   # => 100
```

## to_a

`Time.to_a(x)`

Ruby's `t.to_a`: the ten-element Tuple `[sec, min, hour, day, month, year, wday, yday, isdst, zone]`. The last element is `Time.zone`: `"UTC"` for a UTC Time, nil for a Time at a fixed offset such as `in: "+09:00"`. Its type is `String | nil`, so using it unchecked as a String is a `nil` problem under `--strict` (level 2); the other nine are Integers and a Boolean.

```ruby
p(Time.to_a(Time.at(0, in: "UTC")))        # => [0, 0, 0, 1, 1, 1970, 4, 1, false, "UTC"]
p(Time.to_a(Time.at(0, in: "+09:00")))     # => [0, 0, 9, 1, 1, 1970, 4, 1, false, nil]
sec, min, hour, day, month, year, wday, yday, isdst, zone = Time.to_a(Time.at(0, in: "UTC"))
p(zone ? String.size(zone) : 0)            # => 3
```

```ruby error
zone = Time.to_a(Time.at(0, in: "+09:00"))[9]
p(String.size(zone))                       # !> String.size: argument 1 may be nil
```

## to_s

`Time.to_s(x)`

The String `"2024-02-29 12:30:45 +0900"` (Ruby's `t.to_s`). A Time in UTC mode ends in `UTC`. The fraction of the second is not written (`p(t)` and `inspect` write it). `puts(t)` and `"#{t}"` use this form.

```ruby
t = Time.new(2024, 2, 29, 12, 30, 45.5, in: "+09:00")
puts(Time.to_s(t))                     # => 2024-02-29 12:30:45 +0900
puts(Time.utc(t))                      # => 2024-02-29 03:30:45 UTC
p(Time.at(0, in: "+00:00"))            # => 1970-01-01 00:00:00 +0000
```

## strftime

`Time.strftime(x, String)`

A String in the format of Ruby's `strftime`: `%Y` year, `%m` month, `%d` day, `%H`, `%M`, `%S` hour, minute, second, `%F` (`%Y-%m-%d`), `%T` (`%H:%M:%S`), `%z` (`+0900`), `%:z` (`+09:00`), `%Z` (the zone name, empty for a Time at a fixed offset), `%A`, `%a` weekday names, `%B`, `%b` month names, `%j` day of the year, `%s` seconds since 1970, `%L` milliseconds, `%N` nanoseconds (`%3N` for a digit count), `-` as in `%-d` for no zero padding, `%%` for `%`. An unknown directive is left as it is.

```ruby
t = Time.new(2024, 2, 29, 12, 30, 45, in: "+09:00")
puts(Time.strftime(t, "%Y-%m-%d %H:%M:%S %z"))   # => 2024-02-29 12:30:45 +0900
puts(Time.strftime(t, "%F %T %:z"))             # => 2024-02-29 12:30:45 +09:00
puts(Time.strftime(t, "%A %-d %B, day %j"))     # => Thursday 29 February, day 060
puts(Time.strftime(t, "%s|%L|%Z|%%"))           # => 1709177445|000||%
puts(Time.strftime(Time.utc(t), "%Z %z"))       # => UTC +0000
```

## iso8601

`Time.iso8601(x, [Integer])`

The ISO 8601 String `2024-02-29T12:30:45+09:00` (Ruby's `t.iso8601`, `xmlschema`). A Time in UTC mode ends in `Z`. With `n`, the fraction of the second is written with `n` digits (default 0). It does not parse (Ruby's class method `Time.iso8601(s)`).

```ruby
t = Time.new(2024, 2, 29, 12, 30, 45.5, in: "+09:00")
puts(Time.iso8601(t))                  # => 2024-02-29T12:30:45+09:00
puts(Time.iso8601(t, 3))               # => 2024-02-29T12:30:45.500+09:00
puts(Time.iso8601(Time.utc(t)))        # => 2024-02-29T03:30:45Z
```

## asctime, ctime

`Time.asctime(x)`

`Time.ctime(x)`

The form of C's `asctime`, `"Thu Feb 29 12:30:45 2024"` (Ruby's `t.asctime` and `t.ctime`, which are the same). The zone is not written.

```ruby
t = Time.new(2024, 2, 29, 12, 30, 45, in: "+09:00")
puts(Time.asctime(t))                  # => Thu Feb 29 12:30:45 2024
p(Time.ctime(t) == Time.asctime(t))    # => true
```

## utc, getutc, gmtime, getgm

`Time.utc(x)`

`Time.getutc(x)`

`Time.gmtime(x)`

`Time.getgm(x)`

A new Time showing the same instant in UTC mode (Ruby's `t.getutc`). The four are the same operation, and none changes its subject as Ruby's `t.utc` and `t.gmtime` do. The result has `utc?` true, `zone` `"UTC"`, and is `==` to the original.

```ruby
t = Time.new(2024, 2, 29, 12, 30, 45, in: "+09:00")
u = Time.utc(t)
puts(Time.to_s(u))                     # => 2024-02-29 03:30:45 UTC
puts(Time.to_s(t))                     # => 2024-02-29 12:30:45 +0900
p(Time.utc?(u))                        # => true
p(u == t)                              # => true
p(Time.getutc(t) == Time.gmtime(t) && Time.getgm(t) == u)   # => true
```

## localtime, getlocal

`Time.localtime(x, [String|Integer])`

`Time.getlocal(x, [String|Integer])`

A new Time showing the same instant at another offset (Ruby's `t.getlocal(zone)`). The zone is `"+09:00"`, `"UTC"`, an Integer of seconds and so on (see above); without it, the machine's local zone. The two are the same operation, and neither changes its subject as Ruby's `t.localtime` does. With `"UTC"` the result is in UTC mode.

```ruby
t = Time.at(1700000000, in: "+09:00")
puts(Time.to_s(Time.getlocal(t, "-05:00")))   # => 2023-11-14 17:13:20 -0500
puts(Time.to_s(Time.localtime(t, 3600)))      # => 2023-11-14 23:13:20 +0100
p(Time.utc?(Time.getlocal(t, "UTC")))         # => true
p(Time.getlocal(t) == t)                      # => true
puts(Time.to_s(t))                            # => 2023-11-15 07:13:20 +0900
```

## utc?, gmt?

`Time.utc?(x)`

`Time.gmt?(x)`

True for a Time in UTC mode (made with `"UTC"` or `"Z"`, or by `Time.utc`). A Time made with `"+00:00"` is at offset 0 but gives false. `gmt?` is an alias.

```ruby
p(Time.utc?(Time.at(0, in: "UTC")))    # => true
p(Time.utc?(Time.at(0, in: "+00:00"))) # => false
p(Time.gmt?(Time.utc(Time.at(0, in: "+09:00"))))   # => true
```

## zone

`Time.zone(x)`

The zone's name (a String) or nil: `"UTC"` in UTC mode, the abbreviation of the local zone for a local Time (`"JST"` and the like, depending on the machine), and nil for a Time made with a fixed offset such as `"+09:00"`, which has no name. The result is `String | nil`, so passing it unchecked to a String operation is stopped by `--strict` (level 2). For the offset itself use `utc_offset`.

```ruby
p(Time.zone(Time.at(0, in: "UTC")))    # => "UTC"
p(Time.zone(Time.at(0, in: "+09:00"))) # => nil
```

## utc_offset, gmt_offset, gmtoff

`Time.utc_offset(x)`

`Time.gmt_offset(x)`

`Time.gmtoff(x)`

The offset from UTC in seconds (an Integer: 32400 for `+09:00`, 0 for UTC). The three are aliases.

```ruby
t = Time.at(0, in: "+09:00")
p(Time.utc_offset(t))                  # => 32400
p(Time.gmt_offset(Time.at(0, in: "-05:00")))   # => -18000
p(Time.gmtoff(Time.utc(t)))            # => 0
```

## dst?, isdst

`Time.dst?(x)`

`Time.isdst(x)`

True during daylight saving time (Ruby's `t.dst?`). Always false for a Time at a fixed offset or in UTC; only a Time in the local zone can give true. `isdst` is an alias.

```ruby
p(Time.dst?(Time.at(0, in: "UTC")))    # => false
p(Time.isdst(Time.at(0, in: "+09:00")))    # => false
```

## round, floor, ceil

`Time.round(x, [Integer])`

`Time.floor(x, [Integer])`

`Time.ceil(x, [Integer])`

A new Time with the fraction of the second rounded to `n` digits (default 0), Ruby's `t.round(n)`: `round` to the nearest, `floor` down, `ceil` up. A negative `n` is an `ArgumentError`.

```ruby
t = Time.at(1700000000.123456789r, in: "UTC")
puts(Time.iso8601(Time.round(t, 2), 9))    # => 2023-11-14T22:13:20.120000000Z
puts(Time.iso8601(Time.floor(t, 1), 9))    # => 2023-11-14T22:13:20.100000000Z
puts(Time.iso8601(Time.ceil(t), 9))        # => 2023-11-14T22:13:21.000000000Z
p(Time.round(Time.at(1.5, in: "UTC")) == Time.at(2, in: "UTC"))   # => true
```

## +, -

`Time.+(x, Any)`

`Time.-(x, Any)`

`t + seconds` and `t - seconds` are new Times that many seconds (an Integer, Float or Rational) later or earlier, in t's zone. `t1 - t2` is the difference of two Times in seconds, a Float. `Time + Time` and a right operand that is not a number of seconds are `type` problems statically. There are no day or month units: a day is written `86400`.

```ruby
a = Time.at(100, in: "UTC")
p(a + 5)                               # => 1970-01-01 00:01:45 UTC
p(a - 1.5)                             # => 1970-01-01 00:01:38.5 UTC
p((a + 5) - a)                         # => 5.0
p(a - (a + 5))                         # => -5.0
p(Time.-(a, 1r/4) == Time.at(99.75, in: "UTC"))   # => true
d = Time.new(2024, 3, 10, in: "UTC") - Time.new(2024, 1, 1, in: "UTC")
p(Integer(d / 86400))                  # => 69
```

```ruby error
a = Time.at(0, in: "UTC")
p(a + a)                               # !> the operands are (Time, Time), which the left operand's type does not support
```

## ==, !=

`Time.==(x, Any)`

`Time.!=(x, Any)`

True for the same instant (`!=` is the negation). The zone is not compared: `Time.at(100, in: "UTC")` and `Time.at(100, in: "+09:00")` are equal. A right operand that is not a Time (nil, an Integer, ...) gives false for `==` and true for `!=`, in the operator form `t == v` and in the function form `Time.==(t, v)` alike: the function forms accept any value and never raise.

```ruby
a = Time.at(100, in: "UTC")
p(a == Time.at(100, in: "+09:00"))     # => true
p(a != a + 1)                          # => true
p(a == nil)                            # => false
p(Time.==(a, Time.at(100.0, in: "UTC")))   # => true
p(Time.==(a, 100))                     # => false
p(Time.!=(a, 100))                     # => true
```

## <, <=, >, >=

`Time.<(x, Any)`

`Time.<=(x, Any)`

`Time.>(x, Any)`

`Time.>=(x, Any)`

Compare two instants (the earlier is smaller). The right operand must be a Time; an Integer or the like is a `type` problem statically, in the function form `Time.<(t, 100)` too (unlike `==`, which just gives false).

```ruby
a = Time.at(100, in: "UTC")
b = a + 5
p(a < b)                               # => true
p(a <= a)                              # => true
p(b > a && b >= a)                     # => true
p(Time.<(b, a))                        # => false
```

```ruby error
a = Time.at(100, in: "UTC")
p(a < 100)                             # !> the operands are (Time, Integer), which the left operand's type does not support
```

## <=>

`Time.<=>(x, Any)`

The result of the comparison as -1, 0 or 1 (an Integer; two Times can always be compared, so it is never nil). A Time as the key of `Array.sort` or `Array.sort_by` sorts in time order.

```ruby
a = Time.at(100, in: "UTC")
p(a <=> a + 1)                         # => -1
p(a <=> a)                             # => 0
p(Time.<=>(a + 1, a))                  # => 1
xs = Array.sort(Array[a + 9, a, a + 3])
p(Array.map(xs) { |t| Time.to_i(t) })  # => [100, 103, 109]
```
