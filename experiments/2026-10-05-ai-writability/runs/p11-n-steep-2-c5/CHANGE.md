# Change: GLOB, and LIKE with ESCAPE

This change adds a second pattern-matching operator, `GLOB`, and an `ESCAPE` clause for `LIKE`
(2.3). Everything else stays as in stages 1-6.

## 7.1 Syntax

```
expr := ... | expr [NOT] GLOB expr | expr [NOT] LIKE expr [ESCAPE expr]
```

`GLOB` and `ESCAPE` are new keywords (tests do not use them as names). The pattern characters
`*`, `?`, `[`, `]`, `^` appear in tests only inside string literals.

**Precedence.** `GLOB` and `NOT GLOB` bind like `=` and `LIKE` (level 6 of 1.8) and associate to the
left with the other operators of that level: `'a' GLOB 'a' = 1` is `('a' GLOB 'a') = 1`. Operators
of tighter levels group first: `'ab' GLOB 'a' || '*'` is `'ab' GLOB ('a' || '*')`, and
`2 GLOB 1 + 1` is `'2' GLOB '2'`, true. `NOT x GLOB p` is `NOT (x GLOB p)`.

`ESCAPE e` belongs to the `LIKE` (or `NOT LIKE`) before it: `x LIKE p ESCAPE e = 1` is
`(x LIKE p ESCAPE e) = 1`. Tests write p and e without comparison operators (no `<`, `=`, ...
inside them unless in parentheses).

## 7.2 GLOB

`x GLOB p` is NULL if x or p is NULL. Otherwise both are taken as their text forms (1.3; no affinity
conversion: `123 GLOB '1*'` is 1, `1.5 GLOB '1.?'` is 1, `2.0 GLOB '2'` is 0 because the text form of
`2.0` is `'2.0'`), and the result is 1 if p matches the whole of x, else 0. `x NOT GLOB p` is the
negation (NULL stays NULL).

Unlike `LIKE`, `GLOB` is **case-sensitive**: an ordinary character of p matches only exactly the same
character (`'abc' GLOB 'abc'` is 1, `'ABC' GLOB 'abc'` is 0). In p:

- `*` matches any sequence of characters, including none (`'' GLOB '*'` is 1; `'abc' GLOB '*c*'` is 1).
- `?` matches exactly one character (`'abc' GLOB 'a?c'` is 1, `'ac' GLOB 'a?c'` is 0, `'' GLOB '?'`
  is 0).
- `[...]` (a **class**) matches exactly one character that is in the set the class lists:
  - The class starts at `[` and ends at the first `]` after it, except that a `]` right after the
    `[` (or right after `[^`) is a member of the set, not the end: `'a]' GLOB 'a[]]'` is 1.
  - `x-y` between two characters is a **range**: every character whose code is from x to y
    inclusive (`'m' GLOB '[a-z]'` is 1, `'M' GLOB '[a-z]'` is 0, `'5' GLOB '[0-9]'` is 1). A range
    with x after y contains nothing (`'c' GLOB '[z-a]'` is 0).
  - A `-` that is the first member or the last one (right before the closing `]`) is the character
    `-` itself: `'-' GLOB '[a-]'` and `'-' GLOB '[-a]'` are 1.
  - Every other character inside the class, including `*`, `?`, `[` and a `^` that is not right
    after the `[`, is itself: `'*' GLOB '[*]'`, `'?' GLOB '[?]'`, `'[' GLOB '[[]'` and
    `'^' GLOB '[a^]'` are 1. (This is how a pattern matches a literal `*`, `?` or `[`.)
  - A `[` with no `]` after it to close it makes the whole pattern match nothing
    (`'a' GLOB '[a'` is 0, `'[' GLOB '['` is 0).
  - Tests do not write a range whose ends are `]` or `-`, a `-` directly after a range, or an empty
    class `[]`.
- `[^...]` (a **negated class**) matches exactly one character that is **not** in the set listed
  after the `^` (same rules as above): `'d' GLOB '[^a-c]'` is 1, `'a' GLOB '[^a-c]'` is 0,
  `'x' GLOB '[^]a]'` is 1, `']' GLOB '[^]a]'` is 0. It never matches the empty string
  (`'' GLOB '[^a]'` is 0).
- `]` outside a class is an ordinary character.

Examples: `'report.txt' GLOB '*.txt'` is 1; `'Report.TXT' GLOB '*.txt'` is 0;
`'b12' GLOB '[a-c][0-9]*'` is 1; `'x' GLOB 'X'` is 0 while `'x' LIKE 'X'` is 1.

`GLOB` has no `ESCAPE` clause (tests do not write one after `GLOB`), and tests do not call `glob` or
`like` as functions.

## 7.3 LIKE ... ESCAPE

`x LIKE p ESCAPE e` and `x NOT LIKE p ESCAPE e` are `LIKE` (2.3) in which one character, the
**escape character**, removes the special meaning of the character after it:

1. e is evaluated, as are x and p. If e is not NULL and its text form is not exactly one character
   long (`''`, `'ab'`, `12`, `1.5`), the statement fails with
   `ESCAPE expression must be a single character`. This check comes before the NULL checks: it
   fails even when x or p is NULL.
2. Otherwise the result is NULL if x, p or e is NULL.
3. Otherwise, let c be the text form of e. Every occurrence of c in p (the text form of p) starts an
   escape: c followed by any character d matches the one character d as an ordinary character
   (ignoring ASCII case, as all ordinary characters of `LIKE` do), even when d is `%`, `_` or c
   itself. So `'a%b' LIKE 'a!%b' ESCAPE '!'` is 1 and `'axb' LIKE 'a!%b' ESCAPE '!'` is 0;
   `'a_b' LIKE 'a!_b' ESCAPE '!'` is 1 and `'axb' LIKE 'a!_b' ESCAPE '!'` is 0;
   `'a!b' LIKE 'a!!b' ESCAPE '!'` is 1; `'A%' LIKE 'a!%' ESCAPE '!'` is 1; `'x' LIKE '!x' ESCAPE '!'`
   is 1.
4. If c is itself `%` or `_`, that character is only an escape character in p, never a wildcard:
   `'a%' LIKE 'a%%' ESCAPE '%'` is 1, `'ab' LIKE 'a%%' ESCAPE '%'` is 0.
5. A c at the very end of p (with no character after it to escape) makes p match nothing:
   `'a' LIKE 'a!' ESCAPE '!'` and `'a!' LIKE 'a!' ESCAPE '!'` are both 0.
6. All other characters of p mean what they mean in 2.3. `NOT LIKE ... ESCAPE` is the negation of
   the result (NULL stays NULL). Without `ESCAPE`, `LIKE` is unchanged.

Tests use an escape character that is not a letter. e may be any expression, for example a column.

**When the error happens.** Like other per-row computations, the escape check happens each time the
operator is evaluated on a row, not when the statement is parsed: `SELECT s FROM t WHERE s LIKE 'a'
ESCAPE 'ab'` prints nothing (and no error) when t has no rows, and fails when t has a row (whatever
s holds, NULL included). With an escape taken from a column, the statement fails if any row it
evaluates has a non-NULL escape that is not one character. As with every error, a statement that
fails has no effect (an `UPDATE` changes no row). Tests do not depend on whether an operand of
`AND`, `OR` or a `CASE` branch that does not decide the result is evaluated.

## 7.4 Errors added by this change

`ESCAPE expression must be a single character`.

## Where it applies

- glob-star (public): `GLOB` matches the whole text, ordinary characters match case-sensitively, and `*` matches any sequence including none.
- glob-question: `?` in a `GLOB` pattern matches exactly one character.
- glob-class (public): `[...]` matches one character of a set with ranges, a leading `]`, a first or last `-` and literal `*`, `?`, `[`; an unclosed `[` or a reversed range matches nothing.
- glob-negated-class: `[^...]` matches one character not in the set, and never the empty string.
- glob-numbers: `GLOB` compares the text forms of numbers, without affinity conversion.
- glob-not (public): `NOT GLOB` is the negation, and `GLOB`/`NOT GLOB` bind at level 6 with tighter operators grouping first.
- glob-null: `GLOB` and `NOT GLOB` are NULL when either operand is NULL.
- like-escape (public): `LIKE ... ESCAPE e` (and `NOT LIKE`) makes the character after e ordinary, including `%`, `_`, e itself and a wildcard used as e; a trailing e matches nothing; a NULL e gives NULL.
- like-escape-error: an escape whose text form is not one character fails with `ESCAPE expression must be a single character`, per evaluated row, even when x is NULL.
