# Error positions become ranges

Every error report now gives a source range instead of a single position:

    <kind> error at <line>:<col>-<end line>:<end col>: <message>

The range runs from the first to the **last** character (inclusive) of what it
covers: a one-character token at 2:11 is `2:11-2:11`.
The map a `catch` receives for a runtime error gets two more entries after
`"col"`: `"end_line"` and `"end_col"`; `line`/`col` are the range's start.

## Ranges of tokens and expressions

- A token covers its characters (a string: quote to quote, interpolations
  included). An end of line covers the newline character; the end of the
  input, and the `}` closing an interpolation, the single position where they are.
- An expression or statement covers its tokens from first to last; ranges may
  span lines. Parentheses around an expression belong to the enclosing
  expression: `(1 + "a")` gives `1 + "a"`, `(1) + "a"` gives `(1) + "a"`.

## What each error covers

| Error | Range |
|---|---|
| unexpected character | that character |
| invalid escape | the backslash and the character after it |
| unterminated string | opening quote to the last character before the line or input ends |
| syntax `expected ..., got X` | the token X |
| chained comparison | the second operator |
| parameter needs a default | the parameter name |
| invalid assignment target | the (first) invalid target expression |
| `n targets but m values` | the whole assignment statement |
| undefined name, already declared, cannot assign, used before its declaration | the name |
| `'break'`/`'continue'` outside a loop | the keyword |
| `'return'` outside a function, unreachable code | the whole jump statement (keyword and value) |
| arity (static or runtime), stack, cannot call, built-in errors (including those `map`/`filter` report at their call) | the whole call expression |
| binary operator errors (also nested too deeply in `==`, `!=`, `in`) | the binary expression |
| compound assignment operator error | the whole assignment statement |
| `cannot negate` | the unary expression |
| index, field and slice errors (reading or writing) | the index/field/slice expression |
| bad map key in a literal | the key expression |
| nested too deeply in `match` | the `when` value being compared |
| `cannot iterate over` | the iterable expression |
| destructuring errors | `[` to `]` of the name list |
| assertion failed | the whole `assert` statement |
| uncaught throw | the whole `throw` statement |

## Examples

    print(10 / (5 - 5))
    → runtime error at 1:7-1:18: division by zero

    let s = "abc {1}
    → lexical error at 1:9-1:16: unterminated string

    try [1][5] catch e print(e) end
    → {"kind": "index", "message": "index 5 out of range for array of length 1", "line": 1, "col": 5, "end_line": 1, "end_col": 10}

    for x in len(
      "ab") do end
    → runtime error at 1:10-2:7: cannot iterate over int
