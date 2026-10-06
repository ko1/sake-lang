# League table

Print league standings from match results on standard input.

## Input

At most 200 lines. Whitespace-only lines are ignored. Every other line is split on runs of
whitespace and must have exactly three tokens:

    HOME SCORE AWAY

- HOME and AWAY are different team names: an ASCII letter followed by up to 11 ASCII letters,
  digits or underscores. Names are case-sensitive.
- SCORE is `H-A` (home goals, away goals; each 1 or 2 decimal digits) or `P-P` (postponed).

For each other non-blank line, in input order, print `invalid line N: TEXT` (N: 1-based line
number counting every line; TEXT: the line without its terminator), and otherwise ignore it.

A postponed match is no game, but its teams appear in the table. Every played match counts.

## Standings

A win gives 3 points, a draw 1. GD is goals for (GF) minus goals against (GA).
Teams are ordered by:

1. points, descending;
2. GD, descending;
3. GF, descending;
4. head-to-head points, descending: within a group of teams equal on 1-3, the points each earned in
   matches between two members of that group (the whole group at once, not pairwise);
5. name, ascending in byte order.

Teams equal on 1-4 share a position: Pos is 1 + the number of teams ranked above (1, 2, 2, 4).

## Output

Then print a header and one row per team, each formatted as

    printf("%3s %-12s%3s%3s%3s%3s%4s%4s%4s%4s", ...)

with fields `Pos Team P W D L GF GA GD Pts` for the header, and position, name, played, won, drawn,
lost, GF, GA, GD, points for a row. GD has a leading `+` when positive (`0` when zero). If no valid line names a team, print `no teams` instead of the table.

## Example 1

Input:

    Tigers 2-1 Lions
    Lions 2-1 Bears
    Bears 2-1 Tigers
    Wolves 0-0 Lions
    Wolves 0-0 Tigers
    Bears 3-0 Wolves

Output:

    Pos Team          P  W  D  L  GF  GA  GD Pts
      1 Bears         3  2  0  1   6   3  +3   6
      2 Tigers        3  1  1  1   3   3   0   4
      3 Lions         3  1  1  1   3   3   0   4
      4 Wolves        3  0  2  1   0   3  -3   2

## Example 2

Input (line 2 is empty):

    Rovers 1-0 United

    City P-P Rovers
    United 2-x City
    Athletic 2-0 City
    Rovers 1-1 Rovers
    Rangers 0-0 Albion
    Albion 1 - 1 Rangers
    Rovers 0-1 Athletic
    Kickers P-P Albion

Output:

    invalid line 4: United 2-x City
    invalid line 6: Rovers 1-1 Rovers
    invalid line 8: Albion 1 - 1 Rangers
    Pos Team          P  W  D  L  GF  GA  GD Pts
      1 Athletic      2  2  0  0   3   0  +3   6
      2 Rovers        2  1  0  1   1   1   0   3
      3 Albion        1  0  1  0   0   0   0   1
      3 Rangers       1  0  1  0   0   0   0   1
      5 Kickers       0  0  0  0   0   0   0   0
      6 United        1  0  0  1   0   1  -1   0
      7 City          1  0  0  1   0   2  -2   0
