# Mini language specification

Mini is a small, dynamically typed scripting language. This document is the
complete definition of the language and of its reference implementation's
observable behaviour (`ruby/main.rb`).

## 1. Running

    ruby ruby/main.rb < program.mini

The program text is read from standard input (UTF-8) and processed in four
phases, each of which completes before the next one starts:

1. **lexing** (section 2) turns the text into tokens;
2. **parsing** (section 3) builds a syntax tree;
3. the **static checks** (section 5) look at the whole tree;
4. **evaluation** (sections 6 to 9) runs it.

Everything the program prints, and every error report, goes to standard
output. The exit status is always 0.

An error in any phase prints exactly one line and stops the run:

    <kind> error at <line>:<col>: <message>

`<kind>` is `lexical`, `syntax`, `static` or `runtime`. `<line>` and `<col>`
are 1-based; columns count characters (a tab is one column). Only the first
error is reported. A lexical, syntax or static error is reported before
anything runs, so such a program prints nothing else.

Two options print intermediate results instead of running the program
(intended for debugging the implementation; their exact format is not part of
the language):

- `--tokens` prints one line per token, `line:col type text`; the tokens of an
  interpolation are indented under their string. Lexical errors are reported
  as usual.
- `--ast` prints the syntax tree after the static checks, as S-expressions,
  one statement per line, nested statements indented by two spaces; a name is
  shown as `(name x @d)` where `d` is its scope depth (section 5.1). Lexical,
  syntax and static errors are reported as usual.

Any other argument prints a usage line and does nothing else.

## 2. Lexical structure

### 2.1 Characters, white space, comments

Spaces, tabs and carriage returns separate tokens and are otherwise ignored.
`#` starts a comment that runs to the end of the line (except inside a string).

### 2.2 Newlines

A newline ends a statement, so it is a token (shown as "end of line" in
messages), except:

- inside parentheses, brackets or braces: `(`, `[`, `{` open a nesting level
  and `)`, `]`, `}` close one; while the level is above 0 newlines are ignored;
- right after a token that cannot end an expression: one of the operators
  `+ - * / % ** == != < <= > >= = += -= *= /= %= , .` or one of the keywords
  `and or not in`; the expression continues on the next line;
- several newlines in a row (with blank or comment-only lines between) count
  as one, and newlines before the first token are ignored.

### 2.3 Tokens

- **Integer literals**: one or more decimal digits; a single `_` may appear
  between two digits and is ignored (`1_000_000`). Leading zeros are allowed
  (`007` is 7). There are no negative literals: `-5` is unary minus applied
  to 5. Integers have no size limit.
- **Names**: a letter (`a`-`z`, `A`-`Z`) or `_`, followed by letters, digits and
  `_`. Names are case-sensitive.
- **Keywords** (cannot be used as names):
  `and assert break catch const continue do elif else end false finally fn for
  if in let match nil not or return then throw true try when while`.
- **Operators and punctuation**:
  `+ - * / % ** == != < <= > >= = += -= *= /= %= ( ) [ ] { } , : ; .`
  The longest match wins (`**` rather than `*`, `<=` rather than `<`).
- **Strings**: see 2.4.

Any other character (for example `@`, `!` not followed by `=`, `&`, `'`) is a
lexical error: `unexpected character '@'`, at that character.

### 2.4 Strings and interpolation

A string literal is written between double quotes and must end on the same
line. Inside it:

| Escape | Meaning |
|---|---|
| `\n` | newline |
| `\t` | tab |
| `\\` | backslash |
| `\"` | double quote |
| `\{` | `{` |
| `\}` | `}` |

Any other character after a backslash is a lexical error
`invalid escape '\q'` at the backslash. A literal `}` may also be written
directly; a literal `{` must be escaped, because `{` starts an interpolation.

`{expr}` inside a string is an **interpolation**: the expression is evaluated
when the string is evaluated, converted to text as `str` does (section 8.1),
and inserted. The expression is lexed like ordinary code (it may contain
strings, which may contain interpolations, and brackets including map
literals); it ends at the first `}` that does not close a `{` opened inside
it. Within an interpolation, newlines and `#` are not allowed (`#` is an
unexpected character).

Errors:

- reaching the end of the line or of the input before the closing quote
  (also inside an interpolation): `unterminated string`, at the opening quote
  of the string that is not terminated;
- an empty interpolation `"{}"`: syntax error `expected expression, got '}'`
  at the `}`;
- more than one expression `"{1 2}"`: syntax error `expected '}', got '2'`.

## 3. Syntax

### 3.1 Programs and statements

A program is a sequence of statements. Statements are separated by newlines or
`;`. Empty statements (extra separators) are allowed. A statement may also end
right before `end`, `elif`, `else`, `catch`, `finally` or `when`, so
`if x then print(1) end` fits on one line. Two statements on one line need a
`;` between them: `if a then b() end; c()`.

    statement :=
        "let" NAME ["=" expr]
      | "let" "[" NAME {"," NAME} "]" "=" expr
      | "const" NAME "=" expr
      | "fn" NAME "(" params ")" block "end"
      | "if" expr "then" block {"elif" expr "then" block} ["else" block] "end"
      | "match" expr {sep} when_arm {when_arm} ["else" block] "end"
      | "while" expr "do" block "end"
      | "for" NAME ["," NAME] "in" expr "do" block "end"
      | "break" | "continue"
      | "return" [expr]
      | "throw" expr
      | "assert" expr ["," expr]
      | "try" block ["catch" NAME block] ["finally" block] "end"
      | target assign_op expr
      | target {"," target} "=" expr {"," expr}
      | expr

    when_arm  := "when" expr {"," expr} "then" block
    block     := statements up to the next end / elif / else / catch / finally / when
    params    := [param {"," param} [","]]
    param     := NAME ["=" expr]
    target    := NAME | expr "[" expr "]" | expr "." NAME
    assign_op := "=" | "+=" | "-=" | "*=" | "/=" | "%="

- `return` without a value: the value is omitted when `return` is followed by
  a separator or by a block-ending keyword.
- A `try` needs a `catch`, a `finally`, or both, in that order; otherwise:
  `expected 'catch' or 'finally', got ...`.
- A `match` needs at least one `when` arm: `expected 'when', got ...`.
- Parameters with a default must come after those without one: a parameter
  without a default after one with a default is
  `parameter 'b' needs a default value` (at that parameter).
- `fn` followed by a name at the start of a statement is a function
  declaration; `fn (` starts an anonymous function expression.

### 3.2 Expressions

From loosest to tightest binding:

| Level | Operators | Associativity |
|---|---|---|
| 1 | `or` | left |
| 2 | `and` | left |
| 3 | `not` (prefix) | - |
| 4 | `== != < <= > >= in` | none: `a < b < c` is an error |
| 5 | `+ -` | left |
| 6 | `* / %` | left |
| 7 | `-` (prefix) | - |
| 8 | `**` | right |
| 9 | call `f(args)`, index `a[i]`, slice `a[i:j]`, field `m.name` | left (postfix) |

So `not a == b` is `not (a == b)`, `-2 ** 2` is `-(2 ** 2)`, `2 ** 3 ** 2`
is `2 ** 9`, and `2 ** -1` is allowed syntactically (the exponent may be a
negation). Parentheses group.

    primary := INT | STRING | "true" | "false" | "nil" | NAME
             | "(" expr ")"
             | "[" [expr {"," expr} [","]] "]"
             | "{" [expr ":" expr {"," expr ":" expr} [","]] "}"
             | "fn" "(" params ")" block "end"

- `m.name` means `m["name"]` (the name is used as a string key). The name may
  not be a keyword.
- `a[i:j]`, `a[i:]`, `a[:j]`, `a[:]` are slices (section 7.6).
- Trailing commas are allowed in argument lists, array and map literals, and
  parameter lists.

### 3.3 Syntax errors

Syntax errors are reported at the token where the problem is found, with these
messages:

- `expected <what>, got <token>` where `<what>` is a quoted token (`')'`,
  `'then'`, `'end'`, `'='`, ...), `expression`, `name`, `end of statement` or
  `end of input`;
- `invalid assignment target` (at the assignment operator) when the left side
  of an assignment is not a name, index or field;
- `comparison operators cannot be chained` (at the second comparison operator);
- `parameter 'x' needs a default value`;
- `<n> targets but <m> values` (at the `=`) in a multiple assignment;
  `1 target`/`1 value` are singular.

`<token>` is written as follows: a keyword, name, integer or operator in single
quotes (`'end'`, `'x'`, `'12'`, `'+'`); a string literal as `string`; a newline
as `end of line`; the end of the input as `end of input`; the `}` that closes an
interpolation as `'}'`.

A statement left unfinished at the end of the input reports
`expected 'end', got end of input` (or another expected token). An `end` with
nothing to close reports `expected end of input, got 'end'`.

## 4. Values

| Type (`type(v)`) | Values |
|---|---|
| `int` | integers of any size |
| `string` | immutable sequences of characters |
| `bool` | `true`, `false` |
| `nil` | `nil` |
| `array` | mutable, ordered lists of values |
| `map` | mutable maps from keys (strings or ints) to values, in insertion order |
| `function` | user functions (closures) and built-in functions |

Arrays and maps are **references**: assigning one or passing it to a function
does not copy it; changes through one reference are visible through all.

**Truthiness**: `nil` and `false` are falsy; every other value is truthy,
including `0`, `""`, `[]` and `{}`.

**Map keys** must be strings or ints. `1` and `"1"` are different keys. Using
any other value as a key is a runtime `type` error
`map key must be a string or int, got <type>`.

**Equality** (`==`, `!=`, and wherever values are compared: `in`, `contains`,
`match`):

- values of different types are never equal (`1 == "1"` and `0 == false` are
  false, `nil == false` is false);
- ints, strings and bools compare by value; `nil == nil`;
- arrays are equal when they have the same length and equal elements in order;
- maps are equal when they have the same keys, each with equal values (the
  order of the entries does not matter);
- a user function is equal only to itself (the same closure value); two
  built-ins are equal when they are the same built-in;
- the comparison descends into nested arrays and maps level by level, the
  compared values themselves being level 0; reaching a pair of values at
  level 101 is a runtime `value` error `values nested too deeply to compare`
  (at the operator, at the `match` keyword, or at the `(` of a built-in call).

## 5. Static checks

After parsing, and before anything runs, the program is checked as a whole.
The checks walk the program in source order and stop at the first error.

### 5.1 Scopes

A **scope** holds declared names. Scopes nest:

- the built-in scope (the 25 built-in functions) is outermost;
- the program has a scope;
- each block of an `if`/`elif`/`else`, `match` arm or `else`, `while` body,
  `try` body and `finally` body has its own scope;
- a function has one scope holding its parameters and its body's declarations;
- a `for` statement's variables and its body's declarations share one scope;
- a `catch` variable and its handler's declarations share one scope.

Declarations:

- `let x`, `let [a, b]`, function parameters, `for` variables and `catch`
  variables declare **variables**;
- `const x = e` declares a **constant**;
- `fn f(...)` declares a **function**;
- built-ins are **built-ins**.

A name declared by `let`, `const` or `let [...]` is visible from the end of its
declaration statement to the end of its scope (so in `let x = x + 1` the `x` on
the right refers to an outer `x`). A **function declaration** is visible
throughout the whole statement list it appears in, including before it; this
allows mutual recursion. A parameter is visible in the defaults of later
parameters and in the body.

A name refers to the innermost visible declaration. A declaration in an inner
scope may shadow an outer one, including a built-in.

### 5.2 Errors

All are reported as `static error at <line>:<col>: <message>`:

| Message | Where |
|---|---|
| `undefined name 'x'` | the use of `x` |
| `'x' is already declared in this scope` | the second declaration's name |
| `cannot assign to constant 'x'` / `function 'x'` / `built-in 'x'` | the name being assigned |
| `'break' outside a loop`, `'continue' outside a loop` | the keyword |
| `'return' outside a function` | the keyword |
| `code after 'return' is unreachable` (also `'break'`, `'continue'`, `'throw'`) | the jump keyword |
| `f expects 2 arguments, got 3` | the `(` of the call |

Details:

- **Duplicates**: within one scope a name may be declared once. Function
  declarations of a statement list are entered when the list is entered, so a
  duplicate between two `fn` declarations is reported before anything else in
  that list; a `let` of a name that a `fn` in the same list declares is
  reported at the `let`. Parameter names must be distinct; `for a, a` is a
  duplicate.
- **Undefined names** may come with a suggestion:
  `undefined name 'pirnt'; did you mean 'print'?`. A visible name is
  suggested when its edit distance (insertions, deletions, substitutions and
  swaps of two adjacent characters, each counting 1) from the undefined name
  is at most `min(2, (length - 1) / 2)` (integer division) where `length` is
  the undefined name's length. The smallest distance wins; among equal ones,
  the name in the innermost scope; within a scope, the alphabetically first.
- **Loops**: `break` and `continue` must be inside a `while` or `for` body of
  the same function; a function body starts outside any loop.
- **Unreachable code**: a `break`, `continue`, `return` or `throw` followed by
  another statement in the same statement list. Only the list directly
  containing the jump is checked. The error is reported after checking the
  jump statement itself.
- **Argument counts**: a call whose callee is written as a name that refers to
  a function declaration or to a built-in has its number of arguments checked
  (section 6.6 for the wording). Calls through variables, constants,
  expressions or parameters are only checked when they run.
- An assignment `x = ...` (also compound and multiple assignment) to a
  constant, a function declaration or a built-in is an error; `let`
  variables, parameters, loop variables and catch variables can be assigned.

Within a statement, the parts are checked in source order: e.g. for a call,
the callee, then the arguments left to right, then the argument count; for
`let x = e`, `e` before the declaration of `x`; for a `return`, the
"outside a function" check before its value.

## 6. Evaluation

### 6.1 Order

Expressions are evaluated left to right: operands of binary operators, callee
then arguments, elements of literals, and in a map literal each key then its
value. `and`/`or` evaluate their right operand only when needed.

### 6.2 Statements

- `let x = e` evaluates `e` and declares `x` with its value; `let x` alone gives
  `nil`.
- `let [a, b, c] = e`: `e` must be an array (else `type` error
  `cannot destructure <type>`) with exactly as many elements as names (else
  `value` error `expected 3 elements, got 2`; `1 element` singular); the
  elements are bound in order. Errors are at the `[`.
- `const x = e` is like `let`, but `x` cannot be assigned.
- An expression statement evaluates the expression and discards its value.
- `if`: the conditions are evaluated in order until one is truthy; its block
  runs. Otherwise the `else` block runs, if any.
- `match e when v1, v2 then ... when ... else ... end`: `e` is evaluated once.
  The arms are tried in order; within an arm, the values are evaluated left to
  right, each compared with `==` to `e`, stopping at the first equal one, whose
  arm's block runs. No arm matching runs the `else` block, if any. Values after
  the matching one are not evaluated.
- `while c do ... end`: evaluates `c`; while it is truthy, runs the body (in a
  new scope each time) and evaluates `c` again.
- `for x in e do ... end`: `e` must be an array or a map; otherwise `type`
  error `cannot iterate over <type>` at the `for`. The loop iterates over a
  snapshot taken before the first iteration: the array's elements, or the
  map's keys in insertion order. Changing the collection inside the loop does
  not change which values the loop visits. With two variables, `for i, v in
  array` gives each index and element, and `for k, v in map` each key and
  value. Each iteration has a fresh scope with fresh loop variables, so
  closures created in different iterations capture different variables.
- `break` ends the innermost loop; `continue` goes on with its next iteration
  (for `while`, evaluating the condition again).
- `return e` ends the current function call with the value of `e`; `return`
  alone returns `nil`. A function whose body ends without `return` returns
  `nil`.
- `throw e` evaluates `e` and throws it (section 9).
- `assert c` evaluates `c`; if it is falsy, a runtime `assert` error
  `assertion failed` at the `assert`. With `assert c, m`, `m` is evaluated
  only when `c` is falsy, and the message is `assertion failed: <str(m)>`.
- `try` / `catch` / `finally`: section 9.

### 6.3 Assignment

- `x = e`: `e` is evaluated, then stored into the variable `x`.
- `a[i] = e`: `a` is evaluated, then `i`, then `e`; then the element is stored
  (section 7.5). `m.name = e` is `m["name"] = e`.
- **Compound** `t op= e` (`+= -= *= /= %=`): the target's parts are evaluated
  as for `=`, then `e`, then the current value of the target is read, then the
  operator is applied as `current op value` (errors are reported at the
  `op=` token, with the plain operator in the message, e.g. `'+'`), and the
  result is stored.
- **Multiple** `t1, t2 = e1, e2`: first the parts of all targets (left to right),
  then all values (left to right), then the stores (left to right). So
  `a, b = b, a` swaps.

### 6.4 Variables

Variables are stored in scopes created at run time that correspond one to one
with the scopes of section 5.1; each name refers to the declaration the static
checks found. A function declaration's closure is created when its statement
list starts running, so it can be called before its declaration statement.

Because of that, a function can be called before a `let` in the same scope has
run, while the function refers to that variable:

    f()
    let y = 1
    fn f() print(y) end

Reading or assigning such a variable before its `let` has run is a runtime
`name` error `'y' is used before its declaration`, at the use of `y`.

### 6.5 Functions and closures

`fn (params) ... end` and `fn name(params) ... end` create a function value
that captures the scope it is created in. Variables are captured by reference:
the function sees later assignments to them, and its assignments are seen
outside.

### 6.6 Calls

`f(a1, ..., an)`: `f` is evaluated, then the arguments left to right, then:

- calling a value that is not a function is a `type` error
  `cannot call <type>`;
- the number of arguments must be at least the number of parameters without a
  default and at most the number of parameters; otherwise an `arity` error:
  `f expects 2 arguments, got 3`, `f expects 1 to 2 arguments, got 0`
  (`1 argument` singular). For an anonymous function the name is `function`.
  Built-ins use the same wording, with `at least` when there is no maximum
  (`min expects at least 1 argument, got 0`);
- a call to a user function when 150 user-function calls are already in
  progress is a `stack` error `call depth exceeded 150`. (So recursion 150
  levels deep works.)

The parameters are bound in a new scope; a missing argument takes its
parameter's default, evaluated in that scope at call time (it sees the
earlier parameters). Then the body runs.

Errors about the call itself (arity, depth, non-function) are reported at the
`(` of the call; errors inside the function at their own positions.

## 7. Operators

### 7.1 Arithmetic

`+ - * / % **` on two ints give an int. `/` and `%` round toward negative
infinity: `-7 / 2` is `-4`, `-7 % 2` is `1`, `7 / -2` is `-4`, `7 % -2` is
`-1`; always `(a / b) * b + a % b == a`. Division or remainder by zero is a
`zero` error `division by zero` at the operator. A negative exponent is a
`value` error `negative exponent`; `0 ** 0` is 1.

`+` also concatenates two strings, and two arrays (giving a new array).

Any other operand types are a `type` error at the operator:
`cannot apply '+' to int and string` (left operand's type first).

Unary `-` needs an int: else `type` error `cannot negate <type>`.

### 7.2 Comparison

`< <= > >=` compare two ints numerically or two strings by character code
points (so `"B" < "a"`, `"ab" < "abc"`). Other operand types:
`cannot apply '<' to int and string`.

### 7.3 Equality

`==` and `!=` accept any two values (section 4).

### 7.4 Membership: `in`

`x in c` is true when `c` is an array with an element equal to `x`, a map with
key `x` (false when `x` is not a string or int), or a string containing the
string `x` as a substring (`"" in s` is true). Otherwise (other `c`, or a
string `c` with a non-string `x`): `cannot apply 'in' to <type of x> and <type of c>`.

### 7.5 Logic

`not x` gives `true` when `x` is falsy, else `false`. `a and b` gives `a` if `a`
is falsy, else `b`; `a or b` gives `a` if `a` is truthy, else `b`. (So
`nil or 5` is `5` and `1 and "x"` is `"x"`.)

### 7.6 Indexing, fields and slices

**Reading** `a[i]`:

- array: `i` must be an int (else `type` error `array index must be an int,
  got <type>`); negative `i` counts from the end (`-1` is the last element); an
  index outside the array is an `index` error
  `index 5 out of range for array of length 3` (showing `i` as written);
- string: the same with `string` in the messages; gives a one-character string;
- map: `i` must be a valid key (see section 4); a missing key is a `key` error
  `key "b" not found` (the key shown as by `repr`: strings quoted, ints bare);
- anything else: `type` error `cannot index <type>`.

**Writing** `a[i] = v`: arrays as for reading (the element must already exist:
writing does not grow an array); maps add the key (at the end) or replace its
value (keeping its place); strings are a `type` error `strings are immutable`;
anything else `cannot index <type>`.

Index errors are reported at the `[` (or at the `.` for `m.name`).

**Slices** `a[i:j]` on an array or string give a new array or string with the
elements at positions `i` to `j - 1`. A missing `i` is 0 and a missing `j` the
length. Negative bounds count from the end (length is added once); then each
bound is clamped to `0 .. length`; if `j <= i` the result is empty. Slices
never fail on bounds. Slicing anything else is a `type` error
`cannot slice <type>`; a bound that is not an int is a `type` error
`slice bound must be an int, got <type>`. Errors are at the `[`. Slices
cannot be assigned to.

## 8. Text

### 8.1 `str` and `repr`

**`str(v)`** is the text `print`, `join` and interpolation use: a string is
itself; every other value is `repr(v)`.

**`repr(v)`**:

| Value | Text |
|---|---|
| int | decimal, with `-` if negative |
| string | in double quotes, with `\` `"` `{` newline tab written as `\\` `\"` `\{` `\n` `\t` |
| bool, nil | `true`, `false`, `nil` |
| array | `[` elements' `repr` separated by `, ` `]`, e.g. `[1, "a", [nil]]` |
| map | `{` entries `repr(key): repr(value)` separated by `, ` `}`, in insertion order, e.g. `{"a": 1, 2: [3]}` |
| user function | `<fn name>`, or `<fn>` for an anonymous function |
| built-in | `<builtin name>` |

Counting the value being written as level 0 and each array element or map
key/value as one level deeper than its container, a value at level 101 is
written as `...` (and nothing deeper is written).

### 8.2 Printing

`print(a, b, ...)` writes `str` of each argument, separated by single spaces,
followed by a newline. `print()` writes an empty line.

## 9. Errors and exceptions

`throw v` throws any value. The innermost enclosing `try` (in the current
function or in a caller) with a `catch` receives it.

A **runtime error** is thrown in the same way; the value a `catch` receives is
a new map:

    {"kind": <kind>, "message": <message>, "line": <line>, "col": <col>}

`kind` is one of:

| kind | raised by |
|---|---|
| `type` | an operand or argument of the wrong type, calling a non-function, a bad map key |
| `index` | an array or string index out of range |
| `key` | a missing map key (`m[k]`, `m.k`, `del`) |
| `zero` | division or remainder by zero |
| `arity` | a call with the wrong number of arguments |
| `value` | a right type but a bad value (e.g. `int("x")`, `pop([])`, a negative exponent) |
| `name` | a variable used before its declaration ran (6.4) |
| `stack` | too deep a call |
| `assert` | a failed `assert` |

`try B catch e H end`: runs `B` in a new scope. If a throw or runtime error
escapes `B`, `H` runs in a new scope where `e` is the thrown value (or the
error map). Errors in `H` propagate normally. `break`, `continue` and `return`
pass through `try` normally.

`finally F`: `F` runs after `B` (and `H`, if it ran) whatever happened: normal
completion, `break`, `continue`, `return`, or an error or throw escaping them.
If `F` completes normally, what happened before goes on (the return happens,
the error keeps propagating, ...). If `F` itself does a `break`, `continue`,
`return`, `throw` or has an error, that replaces what happened before.

A throw that no `try` catches stops the program with

    runtime error at <line>:<col>: uncaught throw <repr(v)>

at the `throw` keyword. A runtime error that no `try` catches stops it with
`runtime error at <line>:<col>: <message>`. Re-throwing a caught error map
(`catch e throw e`) is an ordinary throw of a map.

## 10. Built-in functions

There are 25 built-ins. Each checks, in order: the number of arguments
(`arity` error, section 6.6), then each argument in order (type, then value).
The first failure is reported, at the `(` of the call.

A wrong argument type gives a `type` error worded
`<name>: argument <n> must be <expected>, got <type>`, where `<expected>` is
the phrase given below (`an int`, `a string`, `an array`, `a map`,
`a function`, `a string or int`, ...).

| Built-in | Arguments | Result |
|---|---|---|
| `print(v...)` | any number | prints (8.2); `nil` |
| `len(x)` | `a string, array or map` | number of characters / elements / entries |
| `push(a, v)` | `an array`, any | appends `v` to `a`; `nil` |
| `pop(a)` | `an array` | removes and returns the last element; empty: `value` error `pop: array is empty` |
| `keys(m)` | `a map` | new array of keys, in order |
| `values(m)` | `a map` | new array of values, in order |
| `has(m, k)` | `a map`, `a string or int` | whether `m` has key `k` |
| `get(m, k, d)` | `a map`, `a string or int`, any (optional) | `m[k]` if present, else `d` (default `nil`) |
| `del(m, k)` | `a map`, `a string or int` | removes key `k`, returns its value; missing: `key` error `key "x" not found` |
| `str(v)` | any | `str` (8.1) |
| `int(v)` | `an int or string` | an int unchanged; a string of an optional `-` then one or more digits (nothing else, no spaces, no `_`) converted; other strings: `value` error `int: cannot convert "x" to int` (string shown by `repr`) |
| `type(v)` | any | `"int"`, `"string"`, `"bool"`, `"nil"`, `"array"`, `"map"` or `"function"` |
| `range(n)`, `range(a, b)`, `range(a, b, s)` | `an int` each | array `a, a+s, ...` while `< b` (for `s > 0`) or `> b` (for `s < 0`); `a` defaults to 0, `s` to 1; `s == 0`: `value` error `range: step must not be zero` |
| `join(a, sep)` | `an array`, `a string` | `str` of the elements joined with `sep` |
| `split(s, sep)` | `a string`, `a string` | array of the pieces between occurrences of `sep`, left to right, keeping empty pieces (`split(",a,", ",")` is `["", "a", ""]`, `split("", ",")` is `[""]`); empty `sep`: `value` error `split: separator must not be empty` |
| `slice(x, i, j)` | `an array or string`, `an int`, `an int` (optional) | `x[i:j]`, or `x[i:]` without `j` (7.6) |
| `sort(a)` | `an array` | new array sorted ascending; the elements must be all ints or all strings: each element after the first is checked against the first, the first mismatch giving `type` error `sort: cannot compare int and string` (types of the first element and the mismatching one). An array of 0 or 1 elements of any type is returned as a copy. |
| `contains(c, x)` | `an array, map or string`, any | same as `x in c`; for a string `c`, argument 2 must be `a string` |
| `min(n...)`, `max(n...)` | at least one, each `an int` | the smallest / largest |
| `upper(s)`, `lower(s)` | `a string` | letters converted to upper / lower case |
| `reverse(x)` | `an array or string` | a new array / string in reverse order |
| `map(a, f)` | `an array`, `a function` | new array of `f(e)` for each element, over a snapshot of `a` |
| `filter(a, f)` | `an array`, `a function` | new array of the elements `e` (of a snapshot of `a`) for which `f(e)` is truthy |

`map` and `filter` call `f` with one argument; errors in those calls (including
arity errors, reported at the `(` of the `map`/`filter` call) propagate.
Built-ins are values: they can be stored, passed and compared.
