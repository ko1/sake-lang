# Change m05: range operators `..` and `..<`

Mini gets two new binary operators that build arrays of consecutive integers:
`a..b` (inclusive: from `a` up to and including `b`) and `a..<b` (exclusive:
from `a` up to `b - 1`).

## Lexing

`..` and `..<` are new operator tokens. The longest match still wins: `..<`
rather than `..` followed by `<`, and `..` rather than two `.` (so `...` is `..`
then `.`, and `a .. <b` is a syntax error `expected expression, got '<'`).
A line that ends with `..` or `..<` continues on the next line, like after `+`.
`x..y` is now a range, where it used to be a syntax error.

## Precedence

The two operators form a new level between comparison (level 4) and `+ -`
(level 5):

| Level | Operators | Associativity |
|---|---|---|
| 4 | `== != < <= > >= in` | none |
| 4.5 | `..` `..<` | none |
| 5 | `+ -` | left |

So `1 + 1..2 * 3` is `(1 + 1)..(2 * 3)`, `-2..2` is `(-2)..2`, and
`x in 1..10` is `x in (1..10)`. A second range operator directly after a range,
as in `1..2..3` or `1..<5..9`, is a syntax error
`range operators cannot be chained`, at the second operator. Comparison
binds more loosely, so `1..3 == [1, 2, 3]` is `true`.

## Evaluation

The left operand is evaluated, then the right one. Both must be ints;
otherwise it is a runtime `type` error at the operator, worded as for the
other operators with the operator as written:
`cannot apply '..' to int and string`, `cannot apply '..<' to nil and int`.

The result is a new array:

- `a..b`: `a, a+1, ..., b`; empty when `b < a` (`5..5` is `[5]`, `5..4` is `[]`);
- `a..<b`: `a, a+1, ..., b-1`; empty when `b <= a` (`5..<5` is `[]`).

Ranges never count down. Negative bounds are ordinary integers (`-3..<0` is
`[-3, -2, -1]`).

**Size limit**: a range may have at most 10000 elements. If it would have more,
it is a runtime `value` error at the operator:
`range of 10001 elements exceeds the limit of 10000`, where the number is the
exact count the range would have had (`b - a + 1` for `..`, `b - a` for `..<`;
it may be any size). The type check comes before the size check; an empty
range is never an error.

## Examples

    print(1..5, 0..<3, 3..1)
    for i in 2..<4 do print(i) end
    print(len(1..10000), 1 + 1..2 * 3)

prints

    [1, 2, 3, 4, 5] [0, 1, 2] []
    2
    3
    10000 [2, 3, 4, 5, 6]

    try 0..10000 catch e print(e.message) end
    print(1.."2")

prints

    range of 10001 elements exceeds the limit of 10000
    runtime error at 2:8: cannot apply '..' to int and string
