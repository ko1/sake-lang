# Change m06: optional chaining `?.` and `?[`

**Tokens.** `?.` and `?[` are new operator tokens (no space inside them). `?[`
opens a nesting level that the matching `]` closes, like `[`. A line ending
with `?.` continues on the next line, like `.`. A `?` not directly followed by
`.` or `[` is still the lexical error `unexpected character '?'`.

**Syntax.** Two new postfix operations at level 9, besides call, index, slice
and field: `e?.name` (the name may not be a keyword, as after `.`) and
`e?[i]`, `e?[i:j]` (with the same bound forms as `[`). There is no optional
call: `f?.(x)` is `expected name, got '('`.

A **chain** is a primary followed by its postfix operations. Parentheses end a
chain: in `(a?.b).c` the chain `a?.b` is complete before `.c`.

**Evaluation.** For `e?.name`, `e?[i]` or `e?[i:j]`, `e` is evaluated; if it is
`nil`, the rest of the chain is skipped and the whole chain's value is `nil`
(the index, the bounds, later field names, call arguments are not
evaluated). Otherwise the operation behaves exactly like `e.name`, `e[i]`,
`e[i:j]`, with the same errors, reported at the `?.` or `?[`. Only `nil`
short-circuits: `false?.x` is `cannot index bool`, and a missing key is still
a `key` error. Links after a non-nil receiver are ordinary: in `a?.b.c`, if
`a` is a map whose `b` is `nil`, `.c` fails with `cannot index nil`.
Operators outside the chain apply to its value (`-a?.b` with `a` nil is
`cannot negate nil`).

**Assignment.** A chain containing `?.` or `?[` cannot be an assignment target
(`=`, compound or multiple): syntax error `invalid assignment target` at the
assignment operator, as for other invalid targets. `(a?.b).c = 1` is an
ordinary field assignment.

**Static checks.** Unchanged: every part of a chain is checked even if it may
be skipped at run time, and a call's argument count is checked statically only
when its callee is written as a name (so `a?.f(1, 2, 3)` is never checked
statically, while `a?.f(len(1, 2))` is a static error).

## Examples

    let m = {"b": {"c": 5}}
    let n = nil
    print(m?.b.c, n?.b.c, n?[0], n?.f(1), m?["b"]?.c)
    print("{n?.x}", (n?.b) == nil)

prints

    5 nil nil nil 5
    nil true

    let m = {"b": nil}
    print(m?.b?.c)
    print(m?.b.c)

prints

    nil
    runtime error at 3:11: cannot index nil

    let m = {"b": 1}
    m?.b = 2

prints

    syntax error at 2:6: invalid assignment target
