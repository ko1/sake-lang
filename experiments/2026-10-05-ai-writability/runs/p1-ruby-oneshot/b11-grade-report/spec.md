# Weighted grade report

Print a grade table from weights and scores.

## Input

Lines are numbered from 1 and stripped; blank lines and lines starting with `#` are skipped. Fields are separated by whitespace.

- **Weight line**: exactly three fields `weight <category> <w>`. `w` must be digits only with value 1..100, otherwise the error is `bad weight <w>`. A category declared earlier gives `duplicate category <category>`.
- **Score line**: any other line; must have exactly three fields `<student> <category> <score>` (else `bad format`). The category must be declared on an earlier line (else `unknown category <category>`). `<score>` is `P/M`, where `M` is digits with value > 0 and `P` is digits with value <= M, or `EX` (excused), or `-` (missing); otherwise `bad score <score>`. Checks are made in this order, one error per line. At most 200 lines.

## Computation

A valid score line makes its student known. `EX` entries are ignored; `-` counts as 0 out of M. For each category with at least one counted entry, the student's fraction is (sum of points) / (sum of maxima). The percentage is 100 times the weighted mean of those fractions over these categories only (weights renormalised). A student with no counted category has no percentage.

Percentages are shown rounded **half up** to one decimal. Grades use the rounded value: A >= 90.0, B >= 80.0, C >= 70.0, D >= 60.0, else F.

## Output

1. One line `line N: <error>` per invalid line, in input order.
2. A header `Student` left-justified to width W (W = max(7, longest known student name)), then `  Score  G  Missing`.
3. One row per known student: name left-justified to W, two spaces, the percentage right-justified in 5 columns (`  n/a` if none), two spaces, the grade (`-` if none), two spaces, the number of missing entries right-justified in 7 columns. Rows with a percentage come first, by rounded percentage descending, then name ascending; then the rest by name.
4. `class average: X`: the mean of the unrounded percentages, rounded half up to one decimal, or `n/a` if no student has one.

## Example 1

Input:
```
weight hw 40
weight exam 60
ann hw 8/10
ann hw 10/10
ann exam 45/50
bob hw -/10
bob hw 9/10
bob exam EX/50
cy exam 30/50
```

Output:
```
Student  Score  G  Missing
ann       90.0  A        0
cy        60.0  D        0
bob       45.0  F        1
class average: 65.0
```

## Example 2

Input:
```
# midterm data
weight lab 30
weight quiz 20

weight lab 50
weight final abc
dana lab 7/8
eve quiz EX/10
dana quiz 19/20
fred final 10/10
dana lab -/8
eve lab 3/4 extra
gus quiz 11/10
alexander quiz 3/4
alexander lab 9/12
```

Output:
```
line 5: duplicate category lab
line 6: bad weight abc
line 10: unknown category final
line 12: bad format
line 13: bad score 11/10
Student    Score  G  Missing
alexander   75.0  C        0
dana        64.3  D        1
eve          n/a  -        0
class average: 69.6
```
