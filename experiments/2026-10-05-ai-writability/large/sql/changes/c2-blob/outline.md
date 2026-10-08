# c2 BLOB values (wide)

A fourth storage class BLOB (byte strings). Literal `X'4142'` / `x'..'` (an even number of hex digits; anything
else is SQLite's error). A STRICT column type `BLOB` holds only blobs (and NULL); storing a blob into INTEGER,
REAL or TEXT columns and other values into BLOB columns follow STRICT's rules and error messages. Output prints a
blob as `X'` + uppercase hex + `'` (the oracle does this).

It affects everything that handles values. Candidate sites (verify each with SQLite, keep the clear ones, give
each an id): typeof, printing, order of values (NULL < numbers < TEXT < BLOB; blobs compare bytewise), = and <
with other classes, ORDER BY, GROUP BY / DISTINCT / UNION of blobs, min/max, count, length (bytes), hex()
(new: uppercase hex of a blob, or of the text of any other value), CAST to and from BLOB, `||` with a blob,
upper/lower/substr/instr on blobs, the column-type checks of INSERT and UPDATE, DEFAULT X'..', IN, CASE,
coalesce/ifnull/nullif, window functions over blobs. Keep text ASCII so byte and character counts agree.
