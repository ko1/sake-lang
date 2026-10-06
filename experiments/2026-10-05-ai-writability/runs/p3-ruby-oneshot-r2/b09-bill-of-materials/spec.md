# Bill of materials

A factory describes its products as purchased parts and assemblies built from other items. Read
the definitions and build requests from standard input and print, for each request, the exploded
bill of materials and its cost.

## Input

One line per record, fields separated by one or more spaces. Blank lines are ignored; line numbers
count every line from 1. At most 1,000 lines.

- `PART NAME COST`: a purchased part with unit cost `COST`.
- `ASSY NAME LABOR COMP:QTY [COMP:QTY ...]`: an assembly; one unit needs `LABOR` plus `QTY` units
  of each listed component (a part or an assembly), in the order listed.
- `BUILD NAME QTY`: a request to build `QTY` units of an item.

A name is a lowercase letter followed by up to 15 characters from `a-z`, `0-9`, `_`. Money is
digits, `.`, two digits. `QTY` in a component is 1-999; in `BUILD`, 1-1000. Components may name
items defined later in the input; a `BUILD` uses the definitions read so far.

## Errors

A malformed line prints `line N: error: MESSAGE` and is ignored. The first failing check wins:
`unknown command`, `wrong field count` (PART 3, ASSY at least 4, BUILD 3), `bad name`, `bad cost`,
`bad component TEXT` (the first malformed `COMP:QTY` text), `repeated component NAME` (a name
listed twice in one assembly), `duplicate NAME` (the name is already defined), `bad quantity`.

A `BUILD` first walks the structure depth first, starting at the requested item and visiting
components in their listed order. The first problem met stops it with
`line N: cannot build: REASON`:

- an item that is not defined: `unknown item X` for the requested item, otherwise
  `unknown item X in PARENT`;
- an item that is already on the path from the requested item to it:
  `cycle A > B > ... > A`, the path from that earlier occurrence back to it.

## Output of a build

The unit cost of a part is its cost; of an assembly, its labor plus each component's quantity times
its unit cost. Print the tree: the requested item first, then each component below its parent,
indented two more spaces per level, in listed order; an item used in several places is printed in
each. A line is `QTY x NAME = COST`, where `QTY` is the total number of units needed at that place
and `COST` is `QTY` times the unit cost. Then print `parts:` and, for each purchased part in the tree,
`  NAME xTOTAL = COST` with its total quantity over the whole tree, ordered by total quantity,
highest first, then name. Money is printed with two decimals.

## Example 1

Input:

```
PART wheel 25.00
PART tube 3.10
PART bolt 0.05
ASSY frame 40.00 tube:4 bolt:6
ASSY bike 15.50 frame:1 wheel:2 bolt:4
BUILD bike 2
BUILD bolt 10
```

Output:

```
2 x bike = 236.80
  2 x frame = 105.40
    8 x tube = 24.80
    12 x bolt = 0.60
  4 x wheel = 100.00
  8 x bolt = 0.40
parts:
  bolt x20 = 1.00
  tube x8 = 24.80
  wheel x4 = 100.00
10 x bolt = 0.50
parts:
  bolt x10 = 0.50
```

## Example 2

Input:

```
ASSY gadget 1.00 widget:2 spring:1
ASSY widget 0.50 gear:3 gadget:1
PART gear 0.20
BUILD gadget 1
BUILD widget 1
BUILD thing 1
PART spring 0.10
PART spring 0.15
PART Spring 0.15
PART gear2 1.5
ASSY box 1.00 gear:2 gear:1
ASSY box 1.00 gear:0
ASSY box 1.00
BUILD gear 0
```

Output:

```
line 4: cannot build: cycle gadget > widget > gadget
line 5: cannot build: cycle widget > gadget > widget
line 6: cannot build: unknown item thing
line 8: error: duplicate spring
line 9: error: bad name
line 10: error: bad cost
line 11: error: repeated component gear
line 12: error: bad component gear:0
line 13: error: wrong field count
line 14: error: bad quantity
```
