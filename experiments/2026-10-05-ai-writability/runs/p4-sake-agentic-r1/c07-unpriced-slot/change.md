# Change request: slots without a price

Slots are often filled before head office sets the price. From now on the `PRICE` field of
`SLOT` may be `-`, meaning the slot has no price yet. Any other text that is not money is still
`bad money`. A later `SLOT` line for the same code replaces the slot as before, with or without a
price.

- `SELECT` checks, in this order: `no slot CODE`, `sold out CODE`, then `no price CODE` when the
  slot has no price (nothing changes and the credit stays), then the checks as before.
- At the end, after the sales and before the `tubes:` line, print `unpriced: C1 C2 ...` with the
  codes of all slots that have no price, in byte order, separated by single spaces (whether or
  not they have items left). Print nothing there if every slot has a price.

## Example 1

Input:

```
SLOT A1 cola - 5
SLOT B2 chips - 0
COIN 1.00
SELECT A1
SELECT B2
SLOT A1 cola 1.00 5
SELECT A1
```

Output:

```
credit 1.00
no price A1
sold out B2
vend cola, change 0.00
sales:
  cola           1     1.00
unpriced: B2
tubes: 0.05x0 0.10x0 0.25x0 0.50x0 1.00x1 2.00x0
```

## Example 2

Input:

```
SLOT C3 gum - 1
SLOT C4 mint -- 1
SLOT C5 tea - 100
SELECT C3
```

Output:

```
line 2: error: bad money
line 3: error: bad count
no price C3
sales:
  none
unpriced: C3
tubes: 0.05x0 0.10x0 0.25x0 0.50x0 1.00x0 2.00x0
```
