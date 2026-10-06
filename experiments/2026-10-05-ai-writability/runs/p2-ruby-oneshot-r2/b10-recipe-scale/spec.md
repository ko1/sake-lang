# Recipe scaling

Scale a recipe to a different number of servings, combining repeated ingredients and choosing
readable units. All arithmetic must be exact (fractions, not floating point).

## Input

Standard input, at most 500 lines. Fields are separated by one or more spaces.

The first line is `SERVES N -> M` (four fields; `N` and `M` digits, 1-100). If it is missing or
malformed, print only `line 1: error: bad servings` and stop. The factor is `M/N`.

Every following line is an ingredient: `QUANTITY UNIT NAME...`. Blank lines and lines whose first
field starts with `#` are ignored. Line numbers count every line from 1.

- `QUANTITY` is an integer (`2`), a decimal (`0.25`: digits, `.`, digits), a fraction (`3/4`:
  digits, `/`, digits, nonzero denominator), or a mixed number written as an integer field followed
  by a fraction field (`1 1/2`). It must be more than zero.
- `UNIT` is one of `tsp`, `tbsp` (3 tsp), `cup` (48 tsp); `g`, `kg` (1000 g); `ml`, `l`
  (1000 ml); or `-` for a plain count.
- `NAME` is the remaining fields joined with single spaces.

A bad line prints `line N: error: MESSAGE` and is ignored. Checks in order: `bad quantity`,
`missing unit`, `unknown unit U`, `missing name`.

## Output

First `serves M (x F)` with the factor shown as a quantity (below). Then one line per ingredient:
amounts with the same name and the same unit group (spoons, grams, millilitres, count) are added
together after scaling. Lines are in the order in which each (name, group) first appeared, as
`QUANTITY UNIT NAME`, or `QUANTITY NAME` for counts.

Units:

- spoons: `cup` if the amount in cups is at least 1 and its reduced denominator is at most 4;
  else `tbsp` by the same test; else `tsp`.
- grams: `kg` if the amount is at least 1000 g, else `g`. Millilitres: `l` if at least 1000 ml,
  else `ml`.
- counts: rounded up to a whole number.

A quantity whose reduced denominator is at most 8 is shown as a whole number (`3`), a proper
fraction (`2/3`), or a whole number, a space, and a proper fraction (`16 2/3`). Any other quantity is
shown as a decimal with exactly two digits after the point, rounded half up (`0.14`).

## Example 1

Input:

```
SERVES 4 -> 6
2 cup flour
1 1/2 tsp salt
3 - eggs
250 g butter
1 tbsp sugar
2 tbsp sugar
0.5 l milk
```

Output:

```
serves 6 (x 1 1/2)
3 cup flour
2 1/4 tsp salt
5 eggs
375 g butter
4 1/2 tbsp sugar
750 ml milk
```

## Example 2

Input:

```
SERVES 3 -> 1
# pancakes
1 cup flour
2 tsp flour
1 - egg
100 g flour
1/0 cup water
1.5 1/2 cup water
2 pinch salt
3 tbsp
0 g yeast
1 cup water
```

Output:

```
serves 1 (x 1/3)
line 7: error: bad quantity
line 8: error: unknown unit 1/2
line 9: error: unknown unit pinch
line 10: error: missing name
line 11: error: bad quantity
16 2/3 tsp flour
1 egg
33 1/3 g flour
5 1/3 tbsp water
```
