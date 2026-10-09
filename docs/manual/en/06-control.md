# Control flow and patterns

- `if` / `elsif` / `else`, `unless` / `else`, and the ternary `c ? a : b`. A missing branch yields `nil`.
- `while` and `until`, which yield `nil`. Inside a loop, `break` leaves the loop and `next` starts the next iteration. `begin ... end while` is not supported.
- The modifier forms `stmt if c`, `stmt unless c`, `stmt while c`, and `stmt until c`.
- `for` is not supported. Iterate with an operation such as `Range.each(1..3) { |i| ... }`.
- `case`/`when` is not supported (there is no `===`). Use `case`/`in`.

## Pattern matching

`x in P` is true when `x` matches the pattern `P`. `x => P` asserts it: it raises `NoMatchingPatternError` when `x` does not match, and binds a Record pattern's fields. `case x` followed by `in P then ...` branches runs the first branch whose pattern matches. If no branch matches and there is no `else`, it raises `NoMatchingPatternError`.

| Pattern | Matches |
|---|---|
| a type name: `Integer`, `String`, `Tuple`, `Hash`, `Point`, `Record`, `IO`, ... | a value of that type (its type tag) |
| `nil`, `true`, `false`, `1`, `"s"`, `:ok` | an equal value of the same type |
| `P \| Q` | either |
| `{x:, y: name}` | a Record with those fields; binds the locals `x` and `name` |
| `[P, Q]` | a Tuple of that length whose positions match `P` and `Q` (nested patterns allowed) |
| `x` (a bare name inside `[...]`, or alone) | anything; binds the local `x` |

- **No dispatch.** Matching compares type tags and values. There is no `===`, so `case`/`when` is not supported.
- **Narrowing.** In `if x in Integer`, and in each `in` branch of `case x`, a local `x` is narrowed to the matching types. The `else` branch, and each later branch, sees the types that are left. This is how a union such as `Integer | String` is used without a `type` report.
- **Exhaustiveness.** A `case` without `else` that may leave a **type** unmatched is reported as `type`: the set of types is closed, so this can be checked. Symbol literals are tracked as values, so `case op in :add ... in :sub` is complete when `op` only ever holds those literals. When literal branches may leave some **values** of an open type (some String, Integer, or a Symbol made at run time), the report is the `exhaustive` item (level 3): the program may well be correct, and `NoMatchingPatternError` still stops it if not.
- **Assertion.** After `x => P`, a local `x` (and, inside `initialize`, a field `@x` of the new instance) is narrowed to the matching types, as in an `in` branch. A value that surely does not match is reported as `type` (level 1); one that may not match (another type may come) is checked when it runs, and reported only as `exhaustive` (level 3). The failure is `NoMatchingPatternError`, which can be rescued, as in Ruby. `x => P` is itself a check for nil, like `Array.fetch` for a missing index, so a value that may be nil is not reported. It is how a fact such as "a port is an Integer" is written where the value is stored: `p => Integer`, then `@port = p`.
- **Parentheses.** As in Ruby, `x in P` must be in parentheses when it is an argument: `p((x in Integer))`. `x in T ? a : b` and `cond && x in T` also parse differently from what they look like; write `(x in T)`.
