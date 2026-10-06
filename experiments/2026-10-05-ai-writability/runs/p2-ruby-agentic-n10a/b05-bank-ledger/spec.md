# Bank ledger

Keep the accounts of a small bank from a list of commands on standard input.

## Input

One command per line, fields separated by one or more spaces. Blank lines are ignored; line numbers
count every line from 1. At most 5,000 lines.

- `OPEN NAME LIMIT`: open an account with balance 0 and overdraft limit `LIMIT`.
- `DEPOSIT NAME AMOUNT`
- `WITHDRAW NAME AMOUNT`
- `TRANSFER FROM TO AMOUNT`: move money from one account to another.
- `MONTHEND`: close the month (below).

`NAME` is 1-16 lowercase letters `a-z`. `AMOUNT` and `LIMIT` are digits, optionally followed by `.`
and one or two digits, exact to the cent (`12`, `12.5`, `0.07`). `AMOUNT` must be more than zero;
`LIMIT` may be zero.

A withdrawal or transfer is allowed only if the paying account's balance afterwards is at least
minus its limit.

## Month end

Print `== month K ==` (K counts month ends from 1). Then, for each account in name order (byte order):

1. If the balance is negative, charge 1.5% of the overdrawn amount, rounded **up** to a whole cent,
   and print `NAME interest -X.XX` if the charge is not zero. If it is positive, add 0.25% of the
   balance, rounded **down** to a whole cent, and print `NAME interest +X.XX` if it is not zero.
2. If the account made more than 4 successful withdrawals and transfers out since the previous month
   end (or since it opened), take a fee of 2.00 and print `NAME fee -2.00`. The fee and charges
   are taken even when they go beyond the overdraft limit.

## Errors

A failing line prints `line N: error: MESSAGE` and changes nothing. The first failing check wins:
`unknown command` (case-sensitive), `wrong field count`, `bad name` (left to right), `bad amount`
(for the amount or limit), `account NAME exists` (OPEN), `no account NAME` (left to right), `same account`
(a transfer to itself), `insufficient funds in NAME`.

## Output at the end

If no account was opened, print `no accounts`. Otherwise print

```
format("%-16s %12s %12s %5s", "account", "balance", "lowest", "txns")
format("%-16s %12s %12s %5d", name, balance, lowest, txns)     one row per account
```

then `total: X` (the sum of all balances). Rows are ordered by balance, highest first, then by name.
`lowest` is the lowest balance the account ever had, counting 0 at opening and every change,
including interest and fees. `txns` counts successful deposits, withdrawals, transfers out and
transfers in (interest and fees are not transactions).

Money is printed with two decimals and a leading `-` when negative (`-0.40`, `1234.50`).

## Example 1

Input:

```
OPEN alice 0
OPEN bob 100
DEPOSIT alice 1000
WITHDRAW bob 40.5
TRANSFER alice bob 250.25
WITHDRAW bob 300
MONTHEND
WITHDRAW alice 0.01
```

Output:

```
== month 1 ==
alice interest +1.87
bob interest -1.36
account               balance       lowest  txns
alice                  751.61         0.00     3
bob                    -91.61       -91.61     3
total: 660.00
```

## Example 2

Input:

```
OPEN carol 50.00
OPEN carol 10
OPEN Dave 10
DEPOSIT dave 5
DEPOSIT carol 0
DEPOSIT carol 1.234
WITHDRAW carol 50.01
TRANSFER carol carol 1
PAY carol 1
WITHDRAW carol 10
WITHDRAW carol 10
WITHDRAW carol 10
WITHDRAW carol 10
WITHDRAW carol 10
MONTHEND
MONTHEND
```

Output:

```
line 2: error: account carol exists
line 3: error: bad name
line 4: error: no account dave
line 5: error: bad amount
line 6: error: bad amount
line 7: error: insufficient funds in carol
line 8: error: same account
line 9: error: unknown command
== month 1 ==
carol interest -0.75
carol fee -2.00
== month 2 ==
carol interest -0.80
account               balance       lowest  txns
carol                  -53.55       -53.55     5
total: -53.55
```
