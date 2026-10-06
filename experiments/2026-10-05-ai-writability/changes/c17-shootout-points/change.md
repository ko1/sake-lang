# Change: drawn matches decided on penalties

A drawn match may be followed by a penalty
shoot-out, written directly after the score with no space: `H-A(X-Y)`, where X and Y are the home and
away shoot-out goals, each 1 or 2 decimal digits. Such a SCORE is valid only if H equals A and X
differs from Y; otherwise the line is invalid (e.g. `1-0(4-3)`, `2-2(3-3)`, `2-2(100-1)`,
`P-P(1-0)`). Postponed matches cannot have a shoot-out.

A match with a shoot-out is a played draw: it counts in P and D for both teams, and its goals
(H and A, not X and Y) count in GF and GA. The shoot-out winner gets 1 extra point, so it earns 2 and
the loser 1. A team's points are therefore 3 per win, 1 per draw, and 1 per shoot-out won.

The same points are used everywhere points are used, including the head-to-head points of rule 4.
The table layout is unchanged.

## Example 1

Input:

    Tigers 2-1 Lions
    Lions 1-1(5-4) Bears
    Bears 2-2 Tigers
    Wolves 0-0(1-0) Tigers

Output:

    Pos Team          P  W  D  L  GF  GA  GD Pts
      1 Tigers        3  1  2  0   4   3  +1   5
      2 Bears         2  0  2  0   3   3   0   2
      3 Wolves        1  0  1  0   0   0   0   2
      4 Lions         2  0  1  1   2   3  -1   2

## Example 2

Input:

    Ajax 0-0(5-4) Benfica
    Benfica 0-0(5-4) Ajax
    Ajax 1-0(4-3) Celtic
    Celtic 1-1(04-3) Dundee

Output:

    invalid line 3: Ajax 1-0(4-3) Celtic
    Pos Team          P  W  D  L  GF  GA  GD Pts
      1 Ajax          2  0  2  0   0   0   0   3
      1 Benfica       2  0  2  0   0   0   0   3
      3 Celtic        1  0  1  0   1   1   0   2
      4 Dundee        1  0  1  0   1   1   0   1
