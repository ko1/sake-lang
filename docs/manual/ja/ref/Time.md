# Time

Time は 1 つの時刻です: 1970-01-01 00:00:00 UTC からの秒数（有理数の精度）と、表示に使う UTC からのオフセットを持ちます。リテラルは無く、`Time.now`、`Time.at(秒)`、`Time.new(年, 月, 日, ...)` で作ります（[値と型](../03-values.md)）。Ruby の Time と同じ値ですが、Ruby の `t.utc`、`t.localtime` が t 自身を書き換えるのに対し、Sake の操作はすべて新しい Time を返し、主語を変えません。Time に型付き Array `Time[]` は無く、Time の並びには `Array[...]` を使います。

**ゾーン。** `in:` キーワードと `getlocal`・`new` のゾーン引数は固定の UTC オフセットです: `"+09:00"`・`"-05:00"`、`"UTC"`・`"Z"`、軍用の 1 文字 `"A".."I"`, `"K".."Z"`、または秒数の Integer。`"Asia/Tokyo"` のような地域名は受け付けません（`ArgumentError`）。`in:` を省くと実行環境のローカルゾーンになるので、出力が環境に依らない例はすべて `in:` を付けています。`"UTC"`・`"Z"` で作った Time は UTC モード（`utc?` が true、`to_s` の末尾が `UTC`）で、`"+00:00"` はオフセット 0 の普通の Time です（`utc?` は false、末尾は `+0000`）。

Time に使える演算子は `+`、`-`（右が秒数の Integer・Float・Rational。`Time - Time` は秒数の Float）、`==`、`!=`、`<`、`<=`、`>`、`>=`、`<=>`（右は Time）です。下の `Time.+(x, y)` などはその関数形です（[演算子と添字](../05-operators.md)）。`Time.strftime(t, fmt)` と `Time.iso8601(t)` が文字列にします。String からの読み取り（Ruby の `Time.parse`、`Time.iso8601(s)`）は組み込みにはありません。

## now

`Time.now([in: String|Integer])`

今の時刻（Time）。`in:` を与えるとそのオフセットで表示される Time、省くとローカルゾーンです。不正なゾーンは `ArgumentError`。

```ruby
t = Time.now(in: "UTC")
p(Time.utc?(t))                        # => true
p(Time.year(t) >= 2026)                # => true
p(Time.utc_offset(Time.now(in: "+09:00")))   # => 32400
```

## at

`Time.at(Integer|Float|Rational|Time, [in: String|Integer])`

1970-01-01 00:00:00 UTC から `秒` 後の Time（Ruby の `Time.at`）。Integer、Float、Rational のどれでもよく、Rational なら精度が保たれます。Time を渡すと同じ時刻の Time です（`in:` が無ければゾーンも同じ）。`in:` でゾーンを選びます。不正なゾーンは `ArgumentError`。

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

年・月・日・時・分・秒・ゾーンから Time を作ります（Ruby の `Time.new(y, m, d, h, min, s, zone)`）。年は必須で、残りは省けます（月と日は 1、時・分・秒は 0 が既定）。秒は Float か Rational で小数部を持てます。ゾーンは 7 番目の引数か `in:` のどちらか一方で（両方は `ArgumentError`）、無ければローカルゾーンです。月が 1..12、時が 0..23 などの範囲を外れると `ArgumentError`（`mon out of range`）。Ruby の引数無しの `Time.new`（今の時刻）はありません。`Time.now` を使います。

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

時刻の各部分（Integer）を、その Time のオフソットで読みます: 年、月（1..12。`mon` は別名）、日（1..31。`mday` は別名）、時（0..23）、分（0..59）、秒（0..60。小数部は含みません。`subsec`）。

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

曜日（Integer。日曜が 0、土曜が 6）と、年の中の日（1 月 1 日が 1、閏年の 12 月 31 日が 366）。

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

その曜日なら true。`Time.wday(t) == 4` と `Time.thursday?(t)` は同じです。

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

秒より細かい部分。`nsec`（`tv_nsec` は別名）はナノ秒（Integer、0..999999999）、`usec`（`tv_usec` は別名）はマイクロ秒（Integer、0..999999）、`subsec` は秒の小数部をそのまま（Integer の 0、または Rational）。`tv_sec` は `to_i` と同じ、1970 年からの整数秒です。

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

1970-01-01 00:00:00 UTC からの秒数を、Integer（小数部は切り捨て）、Float、Rational（正確）で返します。ゾーンには依りません。`Time.at` の逆です。

```ruby
t = Time.at(1.5, in: "UTC")
p(Time.to_i(t))                        # => 1
p(Time.to_f(t))                        # => 1.5
p(Time.to_r(t))                        # => (3/2)
p(Time.to_i(Time.at(100, in: "+09:00")))   # => 100
```

## to_a

`Time.to_a(x)`

Ruby の `t.to_a`: `[sec, min, hour, day, month, year, wday, yday, isdst, zone]` の 10 要素の Tuple。最後の `zone` は `Time.zone` と同じで、UTC なら `"UTC"`、固定オフセットの Time では nil です（検査器はこの位置を String と見るので、nil になりうることに注意してください）。

```ruby
p(Time.to_a(Time.at(0, in: "UTC")))        # => [0, 0, 0, 1, 1, 1970, 4, 1, false, "UTC"]
p(Time.to_a(Time.at(0, in: "+09:00")))     # => [0, 0, 9, 1, 1, 1970, 4, 1, false, nil]
```

## to_s

`Time.to_s(x)`

`"2024-02-29 12:30:45 +0900"` の形の String（Ruby の `t.to_s`）。UTC モードの Time は末尾が `UTC`。小数部は書きません（`p(t)` と `inspect` は書きます）。`puts(t)` と `"#{t}"` もこの形です。

```ruby
t = Time.new(2024, 2, 29, 12, 30, 45.5, in: "+09:00")
puts(Time.to_s(t))                     # => 2024-02-29 12:30:45 +0900
puts(Time.utc(t))                      # => 2024-02-29 03:30:45 UTC
p(Time.at(0, in: "+00:00"))            # => 1970-01-01 00:00:00 +0000
```

## strftime

`Time.strftime(x, String)`

Ruby の `strftime` の書式で String を作ります: `%Y` 年、`%m` 月、`%d` 日、`%H`・`%M`・`%S` 時分秒、`%F`（`%Y-%m-%d`）、`%T`（`%H:%M:%S`）、`%z`（`+0900`）、`%:z`（`+09:00`）、`%Z`（ゾーン名。固定オフセットの Time では空）、`%A`・`%a` 曜日名、`%B`・`%b` 月名、`%j` 年の中の日、`%s` 1970 年からの秒、`%L` ミリ秒、`%N` ナノ秒（`%3N` で桁数）、`%-d` などの `-` は 0 埋めなし、`%%` は `%`。未知の指示子はそのまま残ります。

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

ISO 8601 の形 `2024-02-29T12:30:45+09:00` の String（Ruby の `t.iso8601`、`xmlschema`）。UTC モードの Time は末尾が `Z`。引数 `n` を与えると小数部を `n` 桁書きます（既定 0）。読み取り（Ruby のクラスメソッド `Time.iso8601(s)`）ではありません。

```ruby
t = Time.new(2024, 2, 29, 12, 30, 45.5, in: "+09:00")
puts(Time.iso8601(t))                  # => 2024-02-29T12:30:45+09:00
puts(Time.iso8601(t, 3))               # => 2024-02-29T12:30:45.500+09:00
puts(Time.iso8601(Time.utc(t)))        # => 2024-02-29T03:30:45Z
```

## asctime, ctime

`Time.asctime(x)`

`Time.ctime(x)`

C の `asctime` の形 `"Thu Feb 29 12:30:45 2024"`（Ruby の `t.asctime`、`t.ctime`。同じもの）。ゾーンは書きません。

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

同じ時刻を UTC モードで表す新しい Time（Ruby の `t.getutc`）。4 つは同じもので、Ruby の `t.utc`・`t.gmtime` のように主語を書き換えることはありません。結果は `utc?` が true、`zone` が `"UTC"`、元の Time と `==` です。

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

同じ時刻を別のオフセットで表す新しい Time（Ruby の `t.getlocal(zone)`）。ゾーンは `"+09:00"`、`"UTC"`、秒数の Integer など（上記）。省くと実行環境のローカルゾーンです。2 つは同じもので、Ruby の `t.localtime` のように主語を書き換えることはありません。`"UTC"` を渡すと UTC モードになります。

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

UTC モードの Time なら true（`"UTC"`・`"Z"` で作ったもの、`Time.utc` の結果）。オフセット 0 でも `"+00:00"` で作った Time は false です。`gmt?` は別名。

```ruby
p(Time.utc?(Time.at(0, in: "UTC")))    # => true
p(Time.utc?(Time.at(0, in: "+00:00"))) # => false
p(Time.gmt?(Time.utc(Time.at(0, in: "+09:00"))))   # => true
```

## zone

`Time.zone(x)`

ゾーンの名前（String）か nil。UTC モードなら `"UTC"`、ローカルゾーンの Time ならその略称（`"JST"` など、環境による）、`"+09:00"` のような固定オフセットで作った Time には名前が無いので nil です。戻り値は `String | nil` で、検査なしに String の操作に渡すと `--strict`（レベル 2）が止めます。オフセットが要るなら `utc_offset` を使います。

```ruby
p(Time.zone(Time.at(0, in: "UTC")))    # => "UTC"
p(Time.zone(Time.at(0, in: "+09:00"))) # => nil
```

## utc_offset, gmt_offset, gmtoff

`Time.utc_offset(x)`

`Time.gmt_offset(x)`

`Time.gmtoff(x)`

UTC からのオフセット（秒数の Integer。`+09:00` なら 32400、UTC なら 0）。3 つは別名です。

```ruby
t = Time.at(0, in: "+09:00")
p(Time.utc_offset(t))                  # => 32400
p(Time.gmt_offset(Time.at(0, in: "-05:00")))   # => -18000
p(Time.gmtoff(Time.utc(t)))            # => 0
```

## dst?, isdst

`Time.dst?(x)`

`Time.isdst(x)`

夏時間の中なら true（Ruby の `t.dst?`）。固定オフセットと UTC の Time では常に false で、true になりうるのはローカルゾーンの Time だけです。`isdst` は別名。

```ruby
p(Time.dst?(Time.at(0, in: "UTC")))    # => false
p(Time.isdst(Time.at(0, in: "+09:00")))    # => false
```

## round, floor, ceil

`Time.round(x, [Integer])`

`Time.floor(x, [Integer])`

`Time.ceil(x, [Integer])`

秒の小数部を `n` 桁（既定 0）に丸めた新しい Time（Ruby の `t.round(n)`）。`round` は四捨五入、`floor` は切り捨て、`ceil` は切り上げ。負の `n` は `ArgumentError`。

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

`t + 秒` と `t - 秒` は秒数（Integer、Float、Rational）だけ後・前の新しい Time で、ゾーンは t のものです。`t1 - t2` は 2 つの Time の差の秒数を Float で返します。`Time + Time` と、秒数でない右辺は静的に `type` の問題です。日や月の単位は無いので、1 日は `86400` と書きます。

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

同じ時刻なら true（`!=` はその否定）。ゾーンは比べないので、`Time.at(100, in: "UTC")` と `Time.at(100, in: "+09:00")` は等しいです。演算子の形 `t == v` で右が Time でない値（nil など）なら false。関数の形 `Time.==(t, v)` は右も Time でなければならず、他の型は実行時に `TypeError` です。

```ruby
a = Time.at(100, in: "UTC")
p(a == Time.at(100, in: "+09:00"))     # => true
p(a != a + 1)                          # => true
p(a == nil)                            # => false
p(Time.==(a, Time.at(100.0, in: "UTC")))   # => true
```

## <, <=, >, >=

`Time.<(x, Any)`

`Time.<=(x, Any)`

`Time.>(x, Any)`

`Time.>=(x, Any)`

時刻の前後で比べます（早い方が小さい）。右は Time でなければならず、Integer などは静的に `type` の問題です。

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

前後の比較の結果を -1、0、1 で返します（Integer。Time どうしは常に比べられるので nil にはなりません）。`Array.sort` と `Array.sort_by` のキーに Time を使うと時刻順に並びます。

```ruby
a = Time.at(100, in: "UTC")
p(a <=> a + 1)                         # => -1
p(a <=> a)                             # => 0
p(Time.<=>(a + 1, a))                  # => 1
xs = Array.sort(Array[a + 9, a, a + 3])
p(Array.map(xs) { |t| Time.to_i(t) })  # => [100, 103, 109]
```
