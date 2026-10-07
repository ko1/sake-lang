# Darts: 501-style scoring

Score a game of darts with the double-out rule.

## Input

The first line (the header) is `START NAME...`: the start score, an integer from 2 to 1001 written
with digits only, then 1 to 4 player names, each 1 to 10 lowercase letters `a`-`z`, all different.
Fields are separated by whitespace. If the header is missing or breaks any of these rules, print
`invalid header` and nothing else.

Each later line is one turn: `NAME DART...`. Blank lines are skipped. A dart is one of:

- `S1`..`S20`, `D1`..`D20`, `T1`..`T20`: single, double, or treble of the number;
- `25` (25 points), `BULL` (50 points, counts as a double), `MISS` (0 points).

Anything else (`S0`, `D21`, `t20`, `50`) is invalid. At most 200 lines.

## Rules

Every player starts with START points left. The darts of a turn are applied in order. After a dart,
if the points left would be negative, exactly 1, or exactly 0 with a dart that is not a double, the
turn is a **bust**: the player's points go back to what they were at the start of the turn. If they
reach exactly 0 with a double, the player **checks out** and wins. Darts after a bust or a checkout
are ignored and not counted as thrown.

Check each turn line in this order and print one line for it:

1. if a player has already checked out: `line N: game over`
2. unknown name: `line N: unknown player NAME`
3. not 1 to 3 darts: `line N: expected 1 to 3 darts`
4. an invalid dart: `line N: bad dart TOKEN` (the first invalid one)
5. a bust: `NAME busts, L left`; a checkout: `NAME checks out with DART`; otherwise
   `NAME scores S, L left` (S is the turn's total, L the points left after the turn).

N is the 1-based line number in the input (the header is line 1). Lines with errors change nothing.

## Output

After the turns, print `STANDINGS`, then one line per player ordered by points left ascending,
ties in header order, formatted as `%d. %-10s %4d %3d %6s`: rank (1, 2, ...), name, points left,
number of turns played (busts included), and the average per three darts,
`(START - left) * 3 / darts thrown` with two decimals, or `-` if the player threw no dart.
Finally print `winner: NAME` or `no winner`.

## Example 1

Input:
```
101 ann bob
ann T20 S1 S19
bob D20 D20 S5
ann S1 D10
bob T20
```

Output:
```
ann scores 80, 21 left
bob scores 85, 16 left
ann checks out with D10
line 5: game over
STANDINGS
1. ann           0   2  60.60
2. bob          16   1  85.00
winner: ann
```

## Example 2

Input:
```
60 kim lee joe
kim T20
lee S20 S20 S19
max S1
joe X5
joe S20 S20 S10 S1

lee D10 S5
kim D15 D15
joe BULL
```

Output:
```
kim busts, 60 left
lee busts, 60 left
line 4: unknown player max
line 5: bad dart X5
line 6: expected 1 to 3 darts
lee scores 25, 35 left
kim checks out with D15
line 10: game over
STANDINGS
1. kim           0   2  60.00
2. lee          35   2  15.00
3. joe          60   0      -
winner: kim
```
