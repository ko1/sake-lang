# Change request: bookings with several rooms

From now on the `ROOM` field of `BOOK` may list 1 to 4 rooms joined by `+` (`R1+R2`).

- Each listed room must be valid and listed only once; otherwise `bad room`.
- The booking occupies every listed room for its time, and conflicts if any of them conflicts.
  `CONFLICT` then names the first listed room that has a conflict, and the earliest-starting
  conflicting booking in that room.
- It is still one booking with one id: it counts once toward the limit of 3, `CANCEL` removes it
  from all its rooms, and `OK` shows the rooms as listed (`OK #4 R2+R1 ...`).
- `FREE` still takes a single room (`+` there is `bad room`).
- The final schedule shows the booking once per room, on that room's line, and each room's usage
  includes it.

## Example 1

Input:

```
BOOK R1 Mon 09:00-10:00 alice
BOOK R2+R3 Mon 09:30-11:00 bob
BOOK R3+R1 Mon 09:45-10:15 carol
FREE R3 Mon 30
BOOK R1+R2 Mon 11:00-12:00 carol
```

Output:

```
OK #1 R1 Mon 09:00-10:00 alice
OK #2 R2+R3 Mon 09:30-11:00 bob
CONFLICT R3 Mon with #2 (bob 09:30-11:00)
FREE R3 Mon 08:00-08:30
OK #3 R1+R2 Mon 11:00-12:00 carol
== schedule ==
Mon R1       09:00-10:00 #1 alice
Mon R1       11:00-12:00 #3 carol
Mon R2       09:30-11:00 #2 bob
Mon R2       11:00-12:00 #3 carol
Mon R3       09:30-11:00 #2 bob
== usage ==
R1       2h00m
R2       2h30m
R3       1h30m
```

## Example 2

Input:

```
BOOK A+B Tue 08:00-09:00 dan
BOOK A+A Tue 10:00-11:00 dan
FREE A+B Tue 15
CANCEL 1
```

Output:

```
OK #1 A+B Tue 08:00-09:00 dan
line 2: error: bad room
line 3: error: bad room
CANCELLED #1
== schedule ==
(none)
== usage ==
(none)
```
