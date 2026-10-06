# Timesheet pay

Compute pay from employee records and work shifts given on standard input.

## Input

One record per line, fields separated by one or more spaces. Blank lines are ignored; line numbers
count every line from 1. At most 3,000 lines.

- `EMP ID NAME RATE`: an employee. `ID` is `E` and three digits; `NAME` is 1-10 letters `A-Za-z`;
  `RATE` is the hourly rate, digits, `.`, two digits.
- `SHIFT ID DATE START END [BREAK]`: a shift worked by an employee defined on an earlier line.
  `DATE` is `YYYY-MM-DD`, a real calendar date with year 1970-2099. `START` and `END` are `HH:MM`
  (00-23, 00-59). If `END` is not after `START` the shift ends on the next day (equal means 24 hours).
  `BREAK` is unpaid minutes (digits, default 0) and must be less than the shift's length.

## Errors

A failing line prints `line N: error: MESSAGE` and is ignored. First failing check wins:
`unknown command`, `wrong field count` (EMP 4 fields, SHIFT 5 or 6), then for EMP `bad id`,
`bad name`, `bad rate`, `duplicate employee ID`; for SHIFT `bad id`, `unknown employee ID`,
`bad date`, `bad time` (start, then end), `bad break`, and `overlapping shift` when it overlaps in
time any accepted shift of the same employee (touching is fine).

## Pay rules

- A shift longer than 6 hours has at least 30 minutes of break: a smaller break counts as 30.
  Worked minutes = length - break.
- A whole shift belongs to its `DATE`, even if it ends the next day.
- Take each employee's shifts in time order. Of a shift's worked minutes, those that bring the
  employee's worked total for that date above 8 hours are overtime. Of the rest, those that bring the
  regular total of the week (Monday to Sunday) above 40 hours are overtime too. All others are regular.
- Pay = (regular minutes x rate + overtime minutes x rate x 1.5) / 60, rounded half up to the cent,
  computed once per employee from the totals.

## Output

```
format("%-4s %-10s %8s %8s %10s", "id", "name", "regular", "overtime", "pay")
format("%-4s %-10s %8s %8s %10s", id, name, regular, overtime, pay)
format("%-4s %-10s %8s %8s %10s", "", "total", regular, overtime, pay)
```

After reading all lines, print the table: one row per employee in id order, including employees with no shifts, then the totals. Times are
`H:MM` (hours not padded, e.g. `0:00`, `152:30`); money has two decimals.

## Example 1

Input:

```
EMP E001 Ana 20.00
EMP E002 Ben 18.50
SHIFT E001 2026-03-02 09:00 17:00 60
SHIFT E001 2026-03-03 08:00 19:00
SHIFT E002 2026-03-02 22:00 02:00
SHIFT E002 2026-03-03 01:00 05:00
SHIFT E002 2026-03-03 10:00 14:00 15
```

Output:

```
line 6: error: overlapping shift
id   name        regular overtime        pay
E001 Ana           15:00     2:30     375.00
E002 Ben            7:45     0:00     143.38
     total         22:45     2:30     518.38
```

## Example 2

Input:

```
EMP E010 Cy 15.00
SHIFT E010 2026-02-23 08:00 18:00
SHIFT E010 2026-02-24 08:00 18:00
SHIFT E010 2026-02-25 08:00 18:00
SHIFT E010 2026-02-26 08:00 18:00
SHIFT E010 2026-02-27 08:00 18:00
SHIFT E010 2026-02-28 08:00 12:00
SHIFT E010 2026-03-01 08:00 08:00
SHIFT E010 2026-02-29 08:00 12:00
SHIFT E011 2026-03-01 08:00 12:00
EMP E010 Cy 16.00
EMP E12 Dee 15.00
```

Output:

```
line 9: error: bad date
line 10: error: unknown employee E011
line 11: error: duplicate employee E010
line 12: error: bad id
id   name        regular overtime        pay
E010 Cy            40:00    35:00    1387.50
     total         40:00    35:00    1387.50
```
