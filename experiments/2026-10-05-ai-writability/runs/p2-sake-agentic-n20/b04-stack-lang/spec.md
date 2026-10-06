# A tiny stack language

Write an interpreter for a small stack language. The program is read from standard input, at most
500 lines; each line is parsed and run on its own, in order, sharing one stack of integers and one
dictionary of defined words.

## Tokens

A line is split into tokens at spaces. A token of an optional `-` followed by one or more digits is a
number and is pushed on the stack (`-` alone is not a number). Integers have no size limit. The
built-in words are:

| word | effect (top of stack on the right) |
|---|---|
| `+ - *` | `a b -> a+b`, `a-b`, `a*b` |
| `/ mod` | `a b -> quotient`, `remainder`; the quotient is truncated toward zero, the remainder has the sign of `a` (`-7 2 /` is `-3`, `-7 2 mod` is `-1`) |
| `= < >` | `a b -> 1` if `a=b`, `a<b`, `a>b`, else `0` |
| `dup drop swap over` | `a -> a a`; `a -> `; `a b -> b a`; `a b -> a b a` |
| `.` | pops the top and prints it on its own line |
| `if ... then`, `if ... else ... then` | pops a value; runs the first part if it is not 0, else the `else` part (if any) |
| `: NAME ... ;` | defines `NAME` as the words up to `;` |

Any other token is a user word: it runs the body of its most recent definition at the time it runs.
`if` may nest and may appear inside definitions. A definition replaces an earlier one of the same name.

## Syntax errors

Before anything on a line runs, it is checked: every `if` has a matching `then` with at most one
`else` between them; every `:` has a matching `;` on the same line; `:` is followed by a name
that is neither a number nor a built-in word; `:` does not appear inside a definition or inside an
`if`; no `else`, `then` or `;` is left unmatched. If a check fails, print `line N: syntax error`
and do nothing for that line. Lines are numbered from 1.

## Run-time errors

While running, an error stops the rest of the line, prints `line N: error: MESSAGE`, and
restores the stack to what it was before the line began. Lines printed and definitions made
before the error stay. Messages:

- `stack underflow in W`: built-in word `W` (or `if`) needs more values than the stack holds
- `division by zero`: `/` or `mod` with `b = 0`
- `unknown word W`: no definition for `W`
- `too deep`: calling a user word while 100 user-word calls are already active

After the last line print `stack: ` followed by the stack from bottom to top separated by single
spaces, or `stack: (empty)`.

## Example 1

Input:

```
2 3 + .
: sq dup * ;
7 sq .
: abs dup 0 < if -1 * then ;
-5 abs . 4 abs .
-7 2 / . -7 2 mod .
10 20
```

Output:

```
5
49
5
4
-3
-1
stack: 10 20
```

## Example 2

Input:

```
1 2 3
+ + + .
4 0 /
: fact dup 1 > if dup 1 - fact * then ;
5 fact .
: loop loop ;
loop
1 if 2 else 3
: if 1 ;
nope
. .
```

Output:

```
line 2: error: stack underflow in +
line 3: error: division by zero
120
line 7: error: too deep
line 8: syntax error
line 9: syntax error
line 10: error: unknown word nope
3
2
stack: 1
```
