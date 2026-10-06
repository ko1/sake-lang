# FIFO inventory

A small warehouse tracks stock in lots. Process the commands on standard input and report stock,
revenue and cost, valuing shipments first-in, first-out.

## Input

One command per line, fields separated by one or more spaces. Blank lines are ignored. Line
numbers count every input line from 1. At most 5,000 lines.

- `RECEIVE SKU QTY COST`: a new lot of `QTY` units bought at unit cost `COST`.
- `SHIP SKU QTY PRICE`: sell `QTY` units at unit price `PRICE`. Units are taken from the oldest
  lots of that SKU first; a lot that is used up disappears, a partly used lot keeps its cost.
- `REPORT`: print the stock report (below).

Field rules: `SKU` is 1-12 characters from `A-Z`, `0-9`, `-`. `QTY` is digits only, value 1 to
1,000,000. `COST` and `PRICE` are digits, optionally followed by `.` and one or two digits
(`5`, `5.5`, `0.05`); they are amounts of money, exact to the cent.

## Errors

A line that fails prints `line N: error: MESSAGE` and changes nothing. Checks, in this order:

1. first field not a command (names are case-sensitive): `unknown command WORD`
2. wrong number of fields (4, or 1 for `REPORT`): `wrong field count`
3. `bad sku`, then `bad quantity`, then `bad price`
4. `SHIP` of a SKU never received: `unknown sku SKU`
5. `SHIP` of more units than on hand: `insufficient stock for SKU (have H, need Q)`

## Output

A successful `SHIP` prints `line N: shipped Q SKU: revenue R, cost C`, where `R` is Q times the
price and `C` the cost of the units taken from the lots.

The report is:

```
format("%-12s %5s %10s", "SKU", "QTY", "VALUE")
format("%-12s %5d %10s", sku, qty, value)      one row per SKU ever received, in byte order
format("%-12s %5d %10s", "TOTAL", qty, value)
```

`value` is the cost of the units on hand. A SKU with nothing left stays in the report with `0`.

After the last line, print `== final ==`, the report, then `revenue: R`, `cost of goods sold: C` and
`gross profit: P` (revenue minus cost) for all shipments.

Money is printed with two decimals and a leading `-` when negative: `0.05`, `12.30`, `-0.40`.

## Example 1

Input:

```
RECEIVE BOLT-M4 100 0.05
RECEIVE NUT-M4 50 0.02
RECEIVE BOLT-M4 100 0.07
SHIP BOLT-M4 150 0.10
REPORT
SHIP NUT-M4 10 0.015
SHIP NUT-M4 10 0.01
```

Output:

```
line 4: shipped 150 BOLT-M4: revenue 15.00, cost 8.50
SKU            QTY      VALUE
BOLT-M4         50       3.50
NUT-M4          50       1.00
TOTAL          100       4.50
line 6: error: bad price
line 7: shipped 10 NUT-M4: revenue 0.10, cost 0.20
== final ==
SKU            QTY      VALUE
BOLT-M4         50       3.50
NUT-M4          40       0.80
TOTAL           90       4.30
revenue: 15.10
cost of goods sold: 8.70
gross profit: 6.40
```

## Example 2

Input:

```
SHIP GEAR 1 5
RECEIVE gear 1 5
RECEIVE GEAR 0 5
RECEIVE GEAR 2 4.5
RECEIVE GEAR 2 4.5 extra

SHIP GEAR 3 9.99
COUNT GEAR
SHIP GEAR 2 3
```

Output:

```
line 1: error: unknown sku GEAR
line 2: error: bad sku
line 3: error: bad quantity
line 5: error: wrong field count
line 7: error: insufficient stock for GEAR (have 2, need 3)
line 8: error: unknown command COUNT
line 9: shipped 2 GEAR: revenue 6.00, cost 9.00
== final ==
SKU            QTY      VALUE
GEAR             0       0.00
TOTAL            0       0.00
revenue: 6.00
cost of goods sold: 9.00
gross profit: -3.00
```
