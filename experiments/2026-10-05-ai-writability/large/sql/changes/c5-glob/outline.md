# c5 GLOB and LIKE ... ESCAPE (local)

`x GLOB pattern` / `x NOT GLOB pattern` (case-sensitive; `*`, `?`, `[...]` with ranges and `[^...]`), with the
precedence of LIKE; and `x LIKE pattern ESCAPE e` / NOT LIKE ... ESCAPE (e a single character, otherwise
SQLite's error). NULL operands give NULL. Sites (ids): glob-star, glob-question, glob-class, glob-negated-class,
glob-not, glob-null, like-escape, like-escape-error, plus combinations with earlier stages (WHERE, CASE, CHECK
if any, joins, HAVING).
