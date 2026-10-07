# Transit route planner

A small rail network is given as a list of track segments, each belonging to a named line. Find the
fastest trip between pairs of stations, where changing lines costs extra time.

## Input (standard input)

- Line 1: the transfer penalty P, an integer (0 <= P <= 60), in minutes.
- Then segment lines, up to a line that is exactly `QUERIES`: `LINE A B MINUTES`, fields separated by
  one or more spaces. The segment can be travelled in both directions on line `LINE`, taking
  `MINUTES`. Names consist of letters, digits and `_`. A segment line is invalid unless it has exactly
  4 fields, `MINUTES` is an integer from 1 to 999 written without a sign or leading zeros, and A differs
  from B. For an invalid line print `invalid segment at line N` (N is the 1-based line number in the
  whole input) and ignore it. Several segments may join the same pair of stations.
- After `QUERIES`: query lines `FROM TO`. A query line without exactly 2 fields prints
  `invalid query at line N`. If there is no `QUERIES` line, there are no queries.
- Blank lines are ignored everywhere. At most 15 stations, 40 segments, 30 queries.

A station is known if it appears in a valid segment.

## Output

Messages are printed in input order. For each query:

- If FROM is unknown: `FROM -> TO: unknown station FROM`; else if TO is unknown, the same with TO.
- If FROM equals TO: `FROM -> TO: 0 min, 0 transfers` (no route line).
- If TO cannot be reached: `FROM -> TO: no route`.
- Otherwise `FROM -> TO: T min, K transfers` (`1 transfer` when K is 1), followed by a route line:
  two spaces, then the legs, one per run of consecutive segments on the same line, joined by `; `.
  A leg is `LINE: S1 > S2 > ... > Sn`.

A trip is a sequence of segments; boarding the first one is free, and each time two consecutive
segments are on different lines, that is one transfer and costs P minutes. T is the total of segment
minutes plus penalties. Choose the trip with the smallest T; among those, the fewest transfers; then
the smallest sequence of station names (compared name by name in byte order, a sequence that is a
prefix of another comes first); then the smallest sequence of line names, compared the same way.

## Example 1

Input:
```
5
Red A B 3
Red B C 3
Blue A D 3
Blue D C 3
Green C E 2
QUERIES
A E
E A
A A
```
Output:
```
A -> E: 13 min, 1 transfer
  Red: A > B > C; Green: C > E
E -> A: 13 min, 1 transfer
  Green: E > C; Red: C > B > A
A -> A: 0 min, 0 transfers
```

## Example 2

Input:
```
10
Red X Y 5
Red Y Z 05
Blue Y Q 1
Red Q Q 3
QUERIES
X Q
X W
Q
Z X
```
Output:
```
invalid segment at line 3
invalid segment at line 5
X -> Q: 16 min, 1 transfer
  Red: X > Y; Blue: Y > Q
X -> W: unknown station W
invalid query at line 9
Z -> X: unknown station Z
```
