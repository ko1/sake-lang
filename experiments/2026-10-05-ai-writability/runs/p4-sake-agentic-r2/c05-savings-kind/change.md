# Change request: savings accounts

The bank now offers savings accounts. `OPEN` takes an optional fourth field, the kind of account:
`OPEN NAME LIMIT [KIND]`.

- `KIND` is `checking` (the default when it is left out) or `savings`; anything else is
  `bad kind`. A savings account must have `LIMIT` 0, otherwise `bad limit`. `OPEN` now has 3 or 4
  fields. Order of checks: ... `bad amount`, `bad kind`, `bad limit`, `account NAME exists`.
- At month end a savings account with a positive balance earns 0.50% (instead of 0.25%), rounded
  down as before, and pays the fee when it made more than 2 (instead of 4) withdrawals and
  transfers out. Everything else works as for checking accounts.
- In the final table all checking accounts come first, then all savings accounts, each part
  ordered as before. A savings account's name is shown with `*` appended (`bob*`). If there is
  at least one savings account, `savings total: X` (the sum of their balances) follows the
  `total:` line.

## Example 1

Input:

```
OPEN alice 0
OPEN bob 0 savings
DEPOSIT alice 100
DEPOSIT bob 1000
WITHDRAW bob 10
TRANSFER bob alice 10
WITHDRAW bob 10
MONTHEND
```

Output:

```
== month 1 ==
alice interest +0.27
bob interest +4.85
bob fee -2.00
account               balance       lowest  txns
alice                  110.27         0.00     2
bob*                   972.85         0.00     4
total: 1083.12
savings total: 972.85
```

## Example 2

Input:

```
OPEN cy 50 savings
OPEN cy 50 Savings
OPEN cy 50 checking
OPEN dee 0 savings extra
```

Output:

```
line 1: error: bad limit
line 2: error: bad kind
line 4: error: wrong field count
account               balance       lowest  txns
cy                       0.00         0.00     0
total: 0.00
```
