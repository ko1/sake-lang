# Library loans

Simulate the loan desk of a small library from a log of events on standard input.

## Input

One event per line, fields separated by one or more spaces; blank lines are ignored and line
numbers count every line from 1 (at most 5,000 lines). Each line starts with a day number:

- `DAY CHECKOUT MEMBER BOOK`
- `DAY RETURN BOOK`
- `DAY RESERVE MEMBER BOOK`
- `DAY PAY MEMBER AMOUNT`

`DAY` is digits, at most 100000. `MEMBER` is 1-12 lowercase letters. `BOOK` is an uppercase letter
followed by 0-7 characters from `A-Z0-9`. `AMOUNT` is digits, optionally `.` and one or two digits,
more than zero. The current day starts at 0. A line whose day is valid and not before the current
day makes it the current day, even if the rest of the line fails.

## Errors

A malformed line prints `line N: error: MESSAGE`; the first failing check wins: `bad day`,
`day goes backwards`, `unknown command`, `wrong field count`, then the fields left to right
(`bad member`, `bad book`, `bad amount`).

An event that breaks a rule prints `line N: refused: MESSAGE` and changes nothing.

## Rules

- **CHECKOUT.** Refused, checking in this order: `BOOK is on loan`; `BOOK is held for M` (held for
  another member); `MEMBER has overdue books` (a loan whose due day is before today); `MEMBER has 3
  loans`; `MEMBER owes X` (owing 10.00 or more). Otherwise the book is lent, due 14 days after
  today, a hold on it for this member ends, and `MEMBER borrowed BOOK, due day D` is printed.
- **RETURN.** Refused with `BOOK is not on loan`. Days late = today minus the due day. If positive,
  the borrower owes a fine of 0.25 per day late, at most 5.00, and `MEMBER returned BOOK, L days
  late, fine X` is printed; otherwise `MEMBER returned BOOK`. Then, if members are waiting for the
  book, the first in line gets a hold on it (`BOOK held for M`) and leaves the line.
- **RESERVE.** Refused with `MEMBER already has BOOK` (they borrowed it), `MEMBER already reserved
  BOOK` (they hold it or are in line), or `BOOK is available` (neither on loan nor held). Otherwise
  the member joins the end of the line: `reserved BOOK for MEMBER (position P)`, P counted from 1.
- **PAY.** Refused with `MEMBER owes only X` if the amount is more than owed. Otherwise prints
  `MEMBER paid X, owes Y`.

## Final report

```
format("%-12s %5s %8s", "member", "loans", "owes")
format("%-12s %5d %8s", member, books on loan, owed)
```

one row per member who ever borrowed or reserved successfully, in byte order. Then
`overdue on day D:` (the current day) and one line `  BOOK MEMBER due D (L days)` per loan whose due
day is before the current day, ordered by due day then book, or `  none`. Money is printed with
two decimals (`0.75`, `15.00`).

## Example 1

Input:

```
1 CHECKOUT ann DUNE
2 RESERVE bob DUNE
3 RESERVE cy DUNE
3 CHECKOUT bob DUNE
20 RETURN DUNE
21 CHECKOUT cy DUNE
21 CHECKOUT bob DUNE
21 PAY ann 0.50
21 PAY ann 1
```

Output:

```
ann borrowed DUNE, due day 15
reserved DUNE for bob (position 1)
reserved DUNE for cy (position 2)
line 4: refused: DUNE is on loan
ann returned DUNE, 5 days late, fine 1.25
DUNE held for bob
line 6: refused: DUNE is held for bob
bob borrowed DUNE, due day 35
ann paid 0.50, owes 0.75
line 9: refused: ann owes only 0.75
member       loans     owes
ann              0     0.75
bob              1     0.00
cy               0     0.00
overdue on day 21:
  none
```

## Example 2

Input:

```
0 CHECKOUT dee A1
0 CHECKOUT dee A2
0 CHECKOUT dee A3
1 CHECKOUT dee A4
1 RESERVE dee A1
1 RESERVE eve A4
40 CHECKOUT dee A4
40 RETURN A1
40 RETURN A2
41 RETURN A3
39 RETURN A3
41 CHECKOUT dee A4
x CHECKOUT dee A4
41 RENEW dee A4
41 CHECKOUT Dee A4
41 CHECKOUT dee a4
```

Output:

```
dee borrowed A1, due day 14
dee borrowed A2, due day 14
dee borrowed A3, due day 14
line 4: refused: dee has 3 loans
line 5: refused: dee already has A1
line 6: refused: A4 is available
line 7: refused: dee has overdue books
dee returned A1, 26 days late, fine 5.00
dee returned A2, 26 days late, fine 5.00
dee returned A3, 27 days late, fine 5.00
line 11: error: day goes backwards
line 12: refused: dee owes 15.00
line 13: error: bad day
line 14: error: unknown command
line 15: error: bad member
line 16: error: bad book
member       loans     owes
dee              0    15.00
overdue on day 41:
  none
```
