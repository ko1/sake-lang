# Spec issues found while implementing c5-glob in the reference (Ruby)

Implementation: `large/sql/changes/c5-glob/ref/` (lexer, parser, ast, binder, expressions).
Results: stages 1-6 public 366/366, hidden 369/369; c5-glob public 8/8, hidden 24/24.

## Tests that disagree with change.md or spec 1-6

None. Every expected output of the public and hidden c5-glob tests follows from change.md 7.1-7.4
and spec 1-6 as written; the implementation did not have to bend to any test.

## Rules that are unclear, ambiguous or missing

1. 7.3 step 3, "Every occurrence of c in p starts an escape": read literally, the second `!` of
   `!!` is also an occurrence and would start an escape. The intended reading (and SQLite's) is a
   left-to-right scan where the character after an escape is consumed, so `a!!b` is `a`, literal `!`,
   `b`. The examples (`'a!b' LIKE 'a!!b' ESCAPE '!'` is 1) settle it, but the rule should say "scanning
   p from the left, a c that is not itself escaped starts an escape".
2. 7.3 step 1, "its text form is not exactly one character long": "character" is not defined for
   non-ASCII text (SQLite counts UTF-8 characters: `ESCAPE 'é'` is accepted). Tests use ASCII only.
3. 7.3: whether c is found in p case-sensitively is left open; change.md avoids it by saying tests use
   non-letter escapes (already recorded in spec-issues/c5-glob.md). The ref compares exactly.
4. Neither 2.3 nor 7.2/7.3 says what affinity the result of `LIKE`/`GLOB` has (the ref gives none,
   as for stage-2 `LIKE`). Not observable in the tests.

## "Where it applies" sites the hidden tests do not really test

- glob-numbers, "without affinity conversion": the only column case, 011 `ext GLOB 1` on a TEXT
  column, gives the same rows whether or not `=`-style affinity is applied (1 would become `'1'`
  either way). No test has a case where affinity would change the answer, e.g. an INTEGER column
  holding 5551234 with `num GLOB '05551234'` (SQLite: 0; `num = '05551234'` is 1). An implementation
  that applies comparison affinity to GLOB operands passes every test.
- like-escape, "ignoring ASCII case" for the escaped character d: no test escapes a letter
  (`'X' LIKE '!x' ESCAPE '!'`, SQLite: 1). The case-insensitive tests (`'A+B' LIKE 'a#+b'`,
  `'X_1' LIKE 'x\_%'`, public `'A%' LIKE 'a!%'`-style) only fold unescaped letters.
- glob-class, `^` not right after `[` is itself: covered by public 003 (`'^' GLOB '[a^]'`) but not
  by the hidden tests (hidden 008 has only `[^^]`, where the second `^` is a member of a negated class).
