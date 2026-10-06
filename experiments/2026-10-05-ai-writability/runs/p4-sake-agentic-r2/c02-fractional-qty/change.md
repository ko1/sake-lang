# Change request: fractional quantities

The warehouse now also stocks goods sold by weight. From now on a `QTY` may have a fractional
part.

- `QTY` is digits, optionally followed by `.` and exactly one digit (`3`, `2.5`, `0.1`, `4.0`),
  with a value from 0.1 to 1,000,000. Anything else (`1.25`, `.5`, `1.`, `0.0`) is `bad quantity`.
- All amounts of money (a shipment's revenue and cost, a report value, the final totals and the
  gross profit) are computed exactly and only rounded when printed: to the cent, halves away
  from zero (`0.025` prints `0.03`, `-0.005` prints `-0.01`). Totals are the rounded exact sums,
  not sums of rounded amounts.
- A quantity is printed as a whole number when it is whole (`5`, also for `5.0`), otherwise with
  one decimal (`2.5`). This applies to the report's `QTY` column, the shipped message, and the
  `have`/`need` numbers.

## Example 1

Input:

```
RECEIVE FLOUR 10.5 0.80
RECEIVE FLOUR 4 0.95
SHIP FLOUR 12.5 1.25
REPORT
```

Output:

```
line 3: shipped 12.5 FLOUR: revenue 15.63, cost 10.30
SKU            QTY      VALUE
FLOUR            2       1.90
TOTAL            2       1.90
== final ==
SKU            QTY      VALUE
FLOUR            2       1.90
TOTAL            2       1.90
revenue: 15.63
cost of goods sold: 10.30
gross profit: 5.33
```

## Example 2

Input:

```
RECEIVE SALT 0.5 0.05
SHIP SALT 0.3 0.05
SHIP SALT 0.25 0.05
SHIP SALT 1 0.05
```

Output:

```
line 2: shipped 0.3 SALT: revenue 0.02, cost 0.02
line 3: error: bad quantity
line 4: error: insufficient stock for SALT (have 0.2, need 1)
== final ==
SKU            QTY      VALUE
SALT           0.2       0.01
TOTAL          0.2       0.01
revenue: 0.02
cost of goods sold: 0.02
gross profit: 0.00
```
