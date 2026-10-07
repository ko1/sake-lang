# Runtime errors name the user function they were raised in

Every runtime error (SPEC section 9: all kinds, including `assert`, `name` and
`stack`) now records the **user function that was running when it was raised**.
Lexical, syntax and static errors, and throws, are unchanged.

## Which function

- A user-function call is *running* from the moment its parameters start being
  bound (so errors in parameter defaults belong to the called function) until it
  returns or an error leaves it. The recorded function is the innermost running
  one; if none is running, there is none (the top level).
- Errors about a call itself (arity, `call depth exceeded 150`,
  `cannot call <type>`) are raised before the callee runs, so they belong to the
  function containing the call. For `map`/`filter`, an arity error of the
  callback belongs to the function containing the `map`/`filter` call; errors in
  the callback's body belong to the callback.
- Errors raised by built-ins belong to the user function that is running
  (the built-in itself is never named).
- The function is fixed when the error is raised: it does not change as the
  error propagates or where it is caught.
- A function is named by the name in its declaration `fn name(...)`, whatever
  variable or map entry it is called through; an anonymous function
  (`fn (...) ... end`) is named `<fn>`.

## Output

An uncaught runtime error raised while a function is running prints

    runtime error at <line>:<col>: <message> (in function <name>)

At the top level the line is as before (no suffix). `uncaught throw ...` lines
never get a suffix.

## The error map

The map a `catch` receives for a runtime error has a fifth entry, after `col`:

    {"kind": ..., "message": ..., "line": ..., "col": ..., "function": <name or nil>}

`"function"` is the name as a string (`"<fn>"` for an anonymous function), or
`nil` at the top level. `"message"` never contains the suffix. Re-throwing the
map is an ordinary throw of a map (with its `"function"` entry).

## Examples

    fn inner(a) return a[3] end
    fn outer() return inner([0]) end
    outer()

prints `runtime error at 1:21: index 3 out of range for array of length 1 (in function inner)`.

    fn one(a) return a end
    let f = one
    let g = fn() return f(1, 2) end
    try g() catch e print(e) end
    try let z = 1 % 0 catch e print(e.function) end

prints

    {"kind": "arity", "message": "one expects 1 argument, got 2", "line": 3, "col": 22, "function": "<fn>"}
    nil

    fn half(n) return n / 0 end
    try half(1) catch e throw e end

prints `runtime error at 2:21: uncaught throw {"kind": "zero", "message": "division by zero", "line": 1, "col": 21, "function": "half"}`.
