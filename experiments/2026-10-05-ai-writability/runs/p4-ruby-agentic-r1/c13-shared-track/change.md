# Change: shared track

Several lines may now run over the same track. The first field of a segment line is a **list of
lines** separated by `/`, e.g. `Red/Blue A B 3`; a single name is a list of one.

**Validation.** A segment line is also invalid (`invalid segment at line N`) when its list has an
empty name (`Red//Blue`, `/Red`, `Red/`), repeats a name (`Red/Red`), or shares a line with an
earlier valid segment joining the same two stations, in either direction.

**Routing.** A segment can be travelled on any one of its lines. Times, transfers and the choice
among equal trips are as before, as if the segment were one segment per listed line. A leg is still
a run of consecutive segments travelled on the same line.

**Output.** A leg's label lists **every** line that runs over all segments of the leg, sorted in
byte order and joined by `/`. Everything else is unchanged.

## Example 1

Input:
```
5
Red/Blue A B 3
Blue B C 3
Red C D 2
Red/Green D E 4
QUERIES
A C
A B
A E
```
Output:
```
A -> C: 6 min, 0 transfers
  Blue: A > B > C
A -> B: 3 min, 0 transfers
  Blue/Red: A > B
A -> E: 17 min, 1 transfer
  Blue: A > B > C; Red: C > D > E
```

## Example 2

Input:
```
2
Red A B 3
Red/Red B C 1
Green/Red B A 5
Blue/Green A B 4
QUERIES
A B
```
Output:
```
invalid segment at line 3
invalid segment at line 4
A -> B: 3 min, 0 transfers
  Red: A > B
```
