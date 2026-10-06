# Change: decimal weights and scores

Weights, points and maxima may now have a fractional part.

A **number** is one or more digits, optionally followed by `.` and one or two digits: `7`, `07`,
`7.5`, `12.25` and `10.00` are numbers; `.5`, `7.`, `7.125`, `1,5`, `+5` and `-1.5` are not.

- **Weight line**: `w` must be a number with value from 1 to 100 (`12.5` and `100.00` are valid,
  `0.5` and `100.01` are not); otherwise the error is `bad weight <w>`, as before.
- **Score line**: in `P/M`, `M` must be a number with value > 0 and `P` a number with value <= M.
  In `EX/M` and `-/M`, `M` must be a number with value > 0. Anything else is `bad score <score>`.
  The order of the checks is unchanged.

All computation is exact (no intermediate rounding); `-` still counts as 0 out of M. Rounding
and output formats do not change.

## Example 1

Input:
```
weight hw 40
weight exam 60
ann hw 7.5/10
ann exam 45.25/50
bob hw -/12.5
bob hw 9.5/12.5
bob exam 41/50
cy exam 30/50
cy hw 10/10.5
```

Output:
```
Student  Score  G  Missing
ann       84.3  B        0
cy        74.1  C        0
bob       64.4  D        1
class average: 74.3
```

## Example 2

Input:
```
weight lab 12.5
weight quiz 0.5
weight quiz 7.125
weight quiz 7.
weight quiz 87.5
dana lab .5/8
dana lab 8./8
eve lab 8.01/8
eve lab 7.99/8
dana quiz 3.5/4
dana lab 6/7.5
```

Output:
```
line 2: bad weight 0.5
line 3: bad weight 7.125
line 4: bad weight 7.
line 6: bad score .5/8
line 7: bad score 8./8
line 8: bad score 8.01/8
Student  Score  G  Missing
eve       99.9  A        0
dana      86.6  B        0
class average: 93.2
```
