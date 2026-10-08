# c4 more scalar functions (local)

New functions, as SQLite 3.46 defines them: concat(X, ...) (NULLs skipped, at least one argument),
concat_ws(SEP, X, ...) (NULL SEP gives NULL, NULL arguments skipped), char(X1, ...) (code points to text; ASCII
range in tests), unicode(X) (code point of the first character; NULL for empty or NULL), sign(X) (-1, 0, 1 or
NULL for numbers; text converted as SQLite does; NULL for non-numeric). Argument count errors as for the
existing functions. Each function is a site (ids: concat, concat_ws, char, unicode, sign), plus combinations
with earlier stages (in GROUP BY, ORDER BY, windows, constraints' DEFAULT if allowed).
