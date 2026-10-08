# c6 math functions (local)

New functions, as SQLite 3.46's math functions define them: ceil/ceiling, floor, trunc (an INTEGER argument
gives it back unchanged; a REAL gives a REAL), mod(X, Y) and pow/power(X, Y) (always REAL: mod(7, 3) is 1.0),
sqrt(X), pi(). NULL in gives NULL; text arguments are converted as SQLite does (non-numeric text gives NULL);
results that are not real numbers (sqrt(-1), mod(x, 0)) give NULL. Argument count errors as for the existing
functions. Each function is a site (ids: ceil, floor, trunc, mod, pow, sqrt, pi), plus combinations with
earlier stages (GROUP BY, ORDER BY, aggregates over them, windows). Check REAL results against the spec's
printing rule; the oracle rejects values SQLite prints differently.
