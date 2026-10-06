# Change request: exact fractions

Users want exact arithmetic. From now on the stack holds rational numbers instead of integers.

- A token of an optional `-`, digits, `/`, and digits is also a number (a fraction such as `3/4`
  or `-6/8`), unless its denominator is zero: `2/0` is not a number (so it is a word, like any
  other token).
- `/` now gives the exact quotient (`7 2 /` is `7/2`); division by zero is still an error.
- `mod` gives `a - b*q`, where `q` is the exact quotient truncated toward zero to an integer.
  For integers this is the same as before.
- `+ - *`, the comparisons and `if` work on the exact values (`2/4 1/2 =` gives `1`).
- `.` and the final `stack:` line show a number in lowest terms: an integer as before, otherwise
  numerator, `/`, denominator, with the sign on the numerator (`-7/2`).

The second example of the specification therefore now prints `-7/2` where it printed `-3`.

## Example 1

Input:

```
1 3 / .
-7 2 / . -7 2 mod .
1/2 1/3 + dup .
6/4 2 * 3 =
2/0
```

Output:

```
1/3
-7/2
-1
5/6
line 5: error: unknown word 2/0
stack: 5/6 1
```

## Example 2

Input:

```
: half 2 / ;
5 half half .
7/2 3/4 mod .
: 1/2 1 ;
-3/6 0 <
```

Output:

```
5/4
1/2
line 4: syntax error
stack: 1
```
