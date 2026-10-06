# Change request: several books per line

From now on the `BOOK` field of `CHECKOUT` and `RETURN` may list 1 to 3 books separated by `,`
(`DUNE,EMMA`). Each must be a valid book, listed once; otherwise `bad book`.

- **CHECKOUT** is refused or done as a whole. Checks: for each book in listed order,
  `BOOK is on loan` and `BOOK is held for M`; then `MEMBER has overdue books`; then
  `MEMBER has K loans` (K: the member's current loans) if K plus the number of listed books is
  more than 3; then `MEMBER owes X`. On success all books are lent with the same due day and one
  line is printed: `MEMBER borrowed B1, B2, due day D` (books in listed order).
- **RETURN** is refused as a whole with `BOOK is not on loan` for the first listed book not on
  loan. Otherwise the books are returned in listed order, each printing its lines exactly as a
  one-book `RETURN` would.

## Example 1

Input:

```
1 CHECKOUT ann DUNE,EMMA
2 RESERVE bob EMMA
2 CHECKOUT ann HOBBIT,IT
20 RETURN EMMA,DUNE
```

Output:

```
ann borrowed DUNE, EMMA, due day 15
reserved EMMA for bob (position 1)
line 3: refused: ann has 2 loans
ann returned EMMA, 5 days late, fine 1.25
EMMA held for bob
ann returned DUNE, 5 days late, fine 1.25
member       loans     owes
ann              0     2.50
bob              0     0.00
overdue on day 20:
  none
```

## Example 2

Input:

```
1 CHECKOUT cy A1,A1
1 CHECKOUT cy A1
2 RETURN A1,B2
```

Output:

```
line 1: error: bad book
cy borrowed A1, due day 15
line 3: refused: B2 is not on loan
member       loans     owes
cy               1     0.00
overdue on day 2:
  none
```
