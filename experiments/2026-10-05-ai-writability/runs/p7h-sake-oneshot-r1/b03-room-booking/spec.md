# Meeting room bookings

Process booking requests for meeting rooms over one week and print the resulting schedule.

## Input

One command per line on standard input, fields separated by one or more spaces. Blank lines are
ignored; line numbers count every line from 1. At most 2,000 lines.

- `BOOK ROOM DAY HH:MM-HH:MM WHO`
- `CANCEL ID`
- `FREE ROOM DAY MINUTES`

`ROOM` is 1-8 characters from `A-Z` and `0-9`. `DAY` is one of `Mon Tue Wed Thu Fri Sat Sun`. A
time is two digits, `:`, two digits (minutes below 60), a multiple of 15 minutes, and between
`08:00` and `20:00` inclusive. The start must be before the end. `WHO` is 1-12 lowercase letters.
`ID` is digits. `MINUTES` is digits, positive and a multiple of 15.

## Rules and output

Each command prints one line.

- `BOOK`: a booking occupies `[start, end)`; two bookings conflict when they are for the same room
  and day and overlap (touching is fine). If the request conflicts with an existing booking, print
  `CONFLICT ROOM DAY with #ID (WHO HH:MM-HH:MM)` naming the conflicting booking that starts
  earliest. Otherwise, if the person already holds 3 bookings on that day (any rooms), print
  `LIMIT WHO DAY`. Otherwise the booking is accepted with the next id (1, 2, 3, ... counting
  accepted bookings only) and `OK #ID ROOM DAY HH:MM-HH:MM WHO` is printed.
- `CANCEL`: removes the booking and prints `CANCELLED #ID`, or `NO BOOKING #ID` if there is no
  such booking now. Ids are never reused.
- `FREE`: finds the earliest start time from 08:00 at which the room is free that day for
  `MINUTES` minutes, ending no later than 20:00. Prints `FREE ROOM DAY HH:MM-HH:MM`, or
  `FULL ROOM DAY` if there is none.

An invalid line prints `line N: error: MESSAGE`, changes nothing, and uses the first failing check:
first field not `BOOK`/`CANCEL`/`FREE` (`unknown command`), wrong number of fields (`wrong field count`),
then the fields from left to right: `bad room`, `bad day`, `bad time` (the start, then the end, then
start before end), `bad name`, `bad id`, `bad duration`.

After the last line print `== schedule ==`, then each remaining booking as

```
format("%s %-8s %s-%s #%d %s", day, room, start, end, id, who)
```

ordered by day (Mon first), then room in byte order, then start time. Then `== usage ==` and, for
each room with remaining bookings in byte order, `format("%-8s %dh%02dm", room, hours, minutes)` of
its total booked time over the week. Print `(none)` under a heading that has no lines.

## Example 1

Input:

```
BOOK R1 Mon 09:00-10:30 alice
BOOK R1 Mon 10:30-11:00 bob
BOOK R1 Mon 10:00-12:00 carol
BOOK R2 Mon 10:00-12:00 carol
FREE R1 Mon 60
CANCEL 1
FREE R1 Mon 90
BOOK R1 Tue 08:00-20:00 dave
FREE R1 Tue 15
```

Output:

```
OK #1 R1 Mon 09:00-10:30 alice
OK #2 R1 Mon 10:30-11:00 bob
CONFLICT R1 Mon with #1 (alice 09:00-10:30)
OK #3 R2 Mon 10:00-12:00 carol
FREE R1 Mon 08:00-09:00
CANCELLED #1
FREE R1 Mon 08:00-09:30
OK #4 R1 Tue 08:00-20:00 dave
FULL R1 Tue
== schedule ==
Mon R1       10:30-11:00 #2 bob
Mon R2       10:00-12:00 #3 carol
Tue R1       08:00-20:00 #4 dave
== usage ==
R1       12h30m
R2       2h00m
```

## Example 2

Input:

```
BOOK R1 Fri 07:45-09:00 erin
BOOK R1 Fri 09:10-10:00 erin
BOOK R1 Fri 10:00-10:00 erin
BOOK R1 Fri 10:00-11:00 Erin
BOOK R1 Friday 10:00-11:00 erin
BOOK R1 Fri 10:00-11:00
BOOK R1 Fri 10:00-11:00 erin
BOOK R2 Fri 11:00-12:00 erin
BOOK R3 Fri 12:00-13:00 erin
BOOK R4 Fri 13:00-14:00 erin
BOOK R4 Sat 13:00-14:00 erin
CANCEL 9
CANCEL two
MOVE 1 R2
FREE R1 Fri 20
```

Output:

```
line 1: error: bad time
line 2: error: bad time
line 3: error: bad time
line 4: error: bad name
line 5: error: bad day
line 6: error: wrong field count
OK #1 R1 Fri 10:00-11:00 erin
OK #2 R2 Fri 11:00-12:00 erin
OK #3 R3 Fri 12:00-13:00 erin
LIMIT erin Fri
OK #4 R4 Sat 13:00-14:00 erin
NO BOOKING #9
line 13: error: bad id
line 14: error: unknown command
line 15: error: bad duration
== schedule ==
Fri R1       10:00-11:00 #1 erin
Fri R2       11:00-12:00 #2 erin
Fri R3       12:00-13:00 #3 erin
Sat R4       13:00-14:00 #4 erin
== usage ==
R1       1h00m
R2       1h00m
R3       1h00m
R4       1h00m
```
