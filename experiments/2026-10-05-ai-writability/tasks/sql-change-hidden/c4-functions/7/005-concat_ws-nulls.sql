-- concat_ws: NULL separator, NULL values, all NULL
CREATE TABLE names (id INTEGER, sep TEXT, a TEXT, b TEXT);
INSERT INTO names VALUES (1, '-', 'x', 'y'), (2, NULL, 'x', 'y'), (3, '-', NULL, 'y'), (4, '-', NULL, NULL);
SELECT id, concat_ws(sep, a, b) FROM names ORDER BY id;
SELECT id, typeof(concat_ws(sep, a, b)) FROM names ORDER BY id;
SELECT count(concat_ws(sep, a, b)) FROM names;
