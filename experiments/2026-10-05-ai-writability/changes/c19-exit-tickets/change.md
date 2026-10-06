# Change: exit by ticket number

Every car let in now gets a ticket, and a car may leave by naming its plate (as before) or its ticket.

## Tickets

Each accepted IN (valid, plate not already inside) issues the next ticket number: 1, 2, ... over the
whole log. A ticket is **open** from its IN until that stay ends, by plate or by ticket.

## Input

An OUT event may name a ticket instead of a plate: `HH:MM OUT #<number>`, digits with no leading
`0` (`#12`; not `#0`, `#01`, `#`, `#1a`). IN still takes a plate only (`IN #3` is invalid).

## Output

- OUT of a ticket that is not open: `line N: ticket #K not open`.
- A valid OUT by ticket prints the usual `PLATE H:MM FEE` line with the plate of the car holding it.
  The summary and the `inside:` line still use plates.

## Example 1

Input:

    RATE 300 150 2000 10
    08:00 IN KX100
    08:05 IN B7
    08:12 OUT #2
    09:40 OUT #1
    10:00 IN B7
    13:31 OUT B7
    14:00 OUT #3

Output:

    B7 0:07 0.00
    KX100 1:40 6.00
    B7 3:31 12.00
    line 8: ticket #3 not open
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
    01:20 OUT #01
    01:20 OUT #1
    21:00 OUT #2
    22:00 IN NIGHT7
    22:05 IN CAR3
    22:10 OUT #4

Output:

    line 4: CAR1 already inside
    line 5: invalid
    CAR1 2:50 6.50
    CAR2 21:50 18.00
    CAR3 0:05 0.00
    --- summary
    CAR2 1 18.00
    CAR1 1 6.50
    CAR3 1 0.00
    total 3 24.50
    inside: NIGHT7
