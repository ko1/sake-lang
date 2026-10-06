# Change request: parts with unknown cost

Some parts are waiting for a supplier quote. From now on the `COST` of a `PART` may be `?`,
meaning the cost is unknown. (`LABOR` of an `ASSY` is still always money; `?` there is `bad cost`.)

- The unit cost of an assembly is unknown when the unit cost of any of its components is unknown;
  a part with unknown cost makes every assembly above it unknown.
- In the tree, a line whose item has an unknown unit cost is printed as `QTY x NAME = ?`.
- In the `parts:` list, a part with unknown cost is printed as `  NAME xTOTAL = ?` (still ordered
  by total quantity, then name).
- After the `parts:` list of a build, if the tree contains parts with unknown cost, print
  `unknown cost: P1, P2, ...` with their names in byte order, separated by `, `.

## Example 1

Input:

```
PART wheel ?
PART tube 3.10
PART bolt 0.05
ASSY frame 40.00 tube:4 bolt:6
ASSY bike 15.50 frame:1 wheel:2 bolt:4
BUILD bike 2
```

Output:

```
2 x bike = ?
  2 x frame = 105.40
    8 x tube = 24.80
    12 x bolt = 0.60
  4 x wheel = ?
  8 x bolt = 0.40
parts:
  bolt x20 = 1.00
  tube x8 = 24.80
  wheel x4 = ?
unknown cost: wheel
```

## Example 2

Input:

```
PART gear ?
PART cog ??
ASSY box ? gear:1
BUILD gear 3
```

Output:

```
line 2: error: bad cost
line 3: error: bad cost
3 x gear = ?
parts:
  gear x3 = ?
unknown cost: gear
```
