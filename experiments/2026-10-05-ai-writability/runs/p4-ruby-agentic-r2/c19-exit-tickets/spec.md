# Parking garage billing

A garage records cars entering and leaving. Compute the fee for every exit, then a summary.

## Input (standard input)

Line 1 is the rate header, always well formed:

    RATE <first> <step> <cap> <grace>

four non-negative integers: `first` is the price in cents of the first hour (or part of it), `step`
the price of each further started 30 minutes, `cap` the most charged for any 24 hours, `grace` a
number of minutes. Every following line is an event:

    HH:MM IN <plate>
    HH:MM OUT <plate>

Fields are separated by one or more spaces. `HH` is `00`-`23` and `MM` is `00`-`59`, exactly two
digits each. A plate is 1 to 8 characters, each `A`-`Z` or `0`-`9`. Blank lines (empty or only
spaces) are skipped. Any other line is invalid. At most 500 lines.

Events are in time order. The log covers several days: when a valid event's time is earlier than
the previous valid event's time, a new day has begun (equal times stay on the same day).

## Fees

A stay lasts from its IN to its OUT, in minutes. A stay of at most `grace` minutes is free.
Otherwise split it into `d` whole days of 1440 minutes and a remainder `r`. The fee is
`d * cap + min(cap, part(r))`, where `part(0) = 0` and, for `r > 0`,
`part(r) = first + step * (number of started 30-minute periods after the first 60 minutes)`.

## Output

Process lines in order and print, as they happen (line numbers count the header as line 1):

- for an invalid line: `line N: invalid`
- for IN of a plate already inside: `line N: PLATE already inside` (the earlier entry stays)
- for OUT of a plate not inside: `line N: PLATE not inside`
- for a valid OUT: `PLATE H:MM FEE`, the stay as hours (no padding, may exceed 23) and two-digit minutes.

Then `--- summary`, one line `PLATE EXITS REVENUE` for each plate with at least one valid OUT,
sorted by revenue descending, then plate ascending (byte order); then `total EXITS REVENUE`; then
`inside: ` followed by the plates still inside sorted ascending and joined by `, `, or `none`.

Money is printed in units with two decimals: 1250 cents is `12.50`, 5 cents `0.05`.

## Example 1

Input:

    RATE 300 150 2000 10
    08:00 IN KX100
    08:05 IN B7
    08:12 OUT B7
    09:40 OUT KX100
    10:00 IN B7
    13:31 OUT B7
    14:00 OUT ZZ9

Output:

    B7 0:07 0.00
    KX100 1:40 6.00
    B7 3:31 12.00
    line 8: ZZ9 not inside
    --- summary
    B7 2 12.00
    KX100 1 6.00
    total 3 18.00
    inside: none

## Example 2

Input:

    RATE 250 100 1800 15
    22:30 IN CAR1
    23:10 IN CAR2
    23:10 IN CAR1
    01:20 OUT CAR1
    07:5 OUT CAR2

    21:00 OUT CAR2
    22:00 IN NIGHT7

Output:

    line 4: CAR1 already inside
    CAR1 2:50 6.50
    line 6: invalid
    CAR2 21:50 18.00
    --- summary
    CAR2 1 18.00
    CAR1 1 6.50
    total 2 24.50
    inside: NIGHT7
