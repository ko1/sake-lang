# Change: per-player start scores (handicaps)

A player in the header may now have a start score of their own.

## Header

Each player field is either `NAME` or `NAME:S`. NAME follows the existing rules (1 to 10 lowercase
letters, all names different; the names are compared without the `:S` part). S follows the same
rules as START: digits only, value from 2 to 1001. A field with an empty S, more than one `:`, or an
S that breaks these rules makes the header invalid (`invalid header`). Turn lines name
the player by NAME alone.

## Rules

A player with `:S` starts with S points left; a player without it starts with START points left.

## Output

- The standings are ordered by points left ascending, then by the player's start score descending,
  then header order.
- The average per three darts is `(player's start score - left) * 3 / darts thrown`.
- The standings line of a player who has `:S` in the header is followed by a space and `(start S)`,
  S written without leading zeros.

## Example 1

Input:
```
301 ann:101 bob
ann T20 S1
bob T20 T20 T20
ann D20
```

Output:
```
ann scores 61, 40 left
bob scores 180, 121 left
ann checks out with D20
STANDINGS
1. ann           0   2 101.00 (start 101)
2. bob         121   1 180.00
winner: ann
```

## Example 2

Input:
```
50 lee kim:80 jo:120
lee S20 S10
kim T20
jo T20 T20
kim S10 S5 S5
```

Output:
```
lee scores 30, 20 left
kim scores 60, 20 left
jo busts, 120 left
kim busts, 20 left
STANDINGS
1. kim          20   2  45.00 (start 80)
2. lee          20   1  45.00
3. jo          120   1   0.00 (start 120)
no winner
```
