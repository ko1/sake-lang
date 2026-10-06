# Vending machine

Simulate a coin-operated vending machine driven by commands on standard input.

## Input

One command per line, fields separated by one or more spaces. Blank lines are ignored; line
numbers count every line from 1. At most 5,000 lines. Money is written as digits, `.`, and exactly
two digits (`1.20`, `0.05`). The machine knows six coins: 0.05, 0.10, 0.25, 0.50, 1.00, 2.00.

- `SLOT CODE NAME PRICE COUNT`: (re)define slot `CODE` (an uppercase letter and a digit) to sell
  product `NAME` (1-12 lowercase letters) at `PRICE`, with `COUNT` items (0-99).
- `TUBE COIN COUNT`: add `COUNT` (0-999) coins of that value to the machine's coin tubes.
- `COIN VALUE`: a customer inserts a coin.
- `SELECT CODE`: a customer asks for a product.
- `CANCEL`: a customer asks for their money back.

## Behaviour

The credit is the total of the coins inserted since the last sale or cancel; it starts at 0.

- `COIN`: a value that is not one of the six coins prints `rejected X`. A coin that would raise the
  credit above 5.00 prints `rejected X (credit limit)`. Otherwise the coin goes into its tube and
  `credit X` (the new credit) is printed.
- `SELECT`, checked in this order: no such slot, `no slot CODE`; no items left, `sold out CODE`;
  credit below the price, `insert X more` (the difference). Otherwise the change (credit minus
  price) is paid from the tubes: for each coin from the largest to the smallest, take as many as
  are needed and available. If that does not reach the change exactly, print `exact change needed`
  and change nothing. Otherwise the coins leave the tubes, one item leaves the slot, the credit
  becomes 0, and `vend NAME, change X` is printed, followed by ` [C1 C2 ...]` (the coins paid,
  largest first) when the change is not zero.
- `CANCEL`: prints `nothing to return` when the credit is 0. Otherwise the coins inserted are taken
  back out of the tubes and `returned X [C1 C2 ...]` lists them in the order they were inserted;
  the credit becomes 0.

A malformed line prints `line N: error: MESSAGE`, changes nothing, and uses the first failing check:
`unknown command` (case-sensitive), `wrong field count`, then the fields from left to right:
`bad slot` (SLOT's code), `bad name`, `bad money`, `bad coin` (TUBE given a value that is not a
coin), `bad count`. `SELECT` with any code just looks it up.

## Final output

If the credit is not 0, print `credit X kept`. Then `sales:` and, per product name (slots
selling the same name are added together), `format("  %-12s %3d %8s", name, items sold, revenue)`,
ordered by revenue, highest first, then name; or `  none`. Last,
`tubes: 0.05xN 0.10xN 0.25xN 0.50xN 1.00xN 2.00xN` with the coins in each tube.

## Example 1

Input:

```
SLOT A1 cola 1.20 2
SLOT B2 chips 0.85 1
TUBE 0.25 2
TUBE 0.05 1
COIN 1.00
SELECT A1
COIN 0.50
SELECT A1
COIN 1.00
SELECT B2
TUBE 0.10 3
TUBE 0.05 1
SELECT B2
SELECT B2
CANCEL
```

Output:

```
credit 1.00
insert 0.20 more
credit 1.50
vend cola, change 0.30 [0.25 0.05]
credit 1.00
exact change needed
vend chips, change 0.15 [0.10 0.05]
sold out B2
nothing to return
sales:
  cola           1     1.20
  chips          1     0.85
tubes: 0.05x0 0.10x2 0.25x1 0.50x1 1.00x2 2.00x0
```

## Example 2

Input:

```
SLOT A1 water 0.65 3
COIN 0.03
COIN 2.00
COIN 2.00
COIN 2.00
COIN 1.00
COIN 1.0
SELECT A1
CANCEL
CANCEL
COIN 1.00
SELECT C9
SELECT A1
TUBE 0.20 5
SLOT a1 water 0.65 3
```

Output:

```
rejected 0.03
credit 2.00
credit 4.00
rejected 2.00 (credit limit)
credit 5.00
line 7: error: bad money
exact change needed
returned 5.00 [2.00 2.00 1.00]
nothing to return
credit 1.00
no slot C9
exact change needed
line 14: error: bad coin
line 15: error: bad slot
credit 1.00 kept
sales:
  none
tubes: 0.05x0 0.10x0 0.25x0 0.50x0 1.00x1 2.00x0
```
