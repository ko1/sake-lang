# Spec issues: c4-functions

No disagreement between SQLite 3.46.1 and spec files 1-6 was found while writing this change.

Dropped or left unspecified (tests avoid them):

- **DEFAULT site** (outline: "constraints' DEFAULT if allowed"): not allowed. Spec 2.1 restricts
  `default-value` to a signed numeric literal, a string literal or `NULL`, so `DEFAULT concat(...)` is a
  syntax error by the spec. (SQLite accepts `DEFAULT (expr)` with parentheses; the spec does not.)
- **char with non-INTEGER arguments**: SQLite turns NULL into code point 0 (`char(NULL)` is a one-character
  string holding NUL, which the spec cannot print as ASCII text), truncates a REAL (`char(65.9)` is `'A'`) and
  reads TEXT as an integer (`char('66')` is `'B'`, `char('abc')` is NUL). change.md states only INTEGER
  arguments 32..126.
- **char/unicode outside ASCII** (`char(-1)` gives U+FFFD; multi-byte characters): outside the spec's
  ASCII-only text.
